//
//  ItemIndexer.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/30/26.
//

import Foundation
import AppIntents
import CoreData
import CoreSpotlight
import os

// Keeps items in Spotlight's semantic index, so Spotlight and Siri find them by meaning. Nothing is
// indexed while the app lock is on: turning it on removes every item, turning it off rebuilds.
//
// Spotlight can't list what it holds, and an item deleted on another device reaches this one
// without its uuid, so the uuids indexed so far are kept in a file next to the store. Whenever
// an item has been deleted, the ones no longer in the store are removed from the index.
final class ItemIndexer {
    private static let logger = Logger()
    // Bump when what goes into an ItemEntity changes, to rebuild the index once after the update
    private static let version = 1
    // The item list's batch size
    private static let batchSize = 50

    private let persistenceHelper: PersistenceHelper
    // Thread-safe outside batch mode, which isn't used, but not marked Sendable
    private nonisolated(unsafe) let searchableIndex: CSSearchableIndex
    private let versionKey: String
    private let registryURL: URL
    private let rebuildsOnLaunch: Bool

    private var indexedUUIDs: Set<UUID>
    private var isLocked = IntentAccessPolicy.isAppLocked
    // Operations run one at a time, in the order they were asked for
    private var lastOperation: Task<Void, Never>?

    init(persistenceHelper: PersistenceHelper, storeName: String) {
        self.persistenceHelper = persistenceHelper
        self.versionKey = "\(storeName).spotlightIndexVersion"
        self.registryURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("\(storeName).spotlight")
        #if DEBUG
        // The stress store is recreated with new uuids on every launch; its own index keeps
        // those items away from the real ones
        if StressTestData.itemCount != nil {
            self.searchableIndex = CSSearchableIndex(name: storeName)
            self.rebuildsOnLaunch = true
            self.indexedUUIDs = []
            return
        }
        #endif
        self.searchableIndex = CSSearchableIndex.default()
        self.rebuildsOnLaunch = false
        self.indexedUUIDs = Self.readRegistry(at: registryURL)
    }

    // At launch: builds the index once after an update, or empties it if the lock is on
    func start() -> Void {
        enqueue { [self] in
            if isLocked {
                await removeAll()
            } else if rebuildsOnLaunch || UserDefaults.standard.integer(forKey: versionKey) != Self.version {
                await rebuildAll()
            }
        }
    }

    func setLocked(_ locked: Bool) -> Void {
        guard locked != isLocked else {
            return
        }
        isLocked = locked
        enqueue { [self] in
            if locked {
                await removeAll()
            } else {
                await rebuildAll()
            }
        }
    }

    // After a local save or a merge of CloudKit changes
    func update(changedObjectIDs objectIDs: [NSManagedObjectID]) -> Void {
        guard !objectIDs.isEmpty else {
            return
        }
        enqueue { [self] in
            guard !isLocked else {
                return
            }
            let (uuids, hasDeletions) = await persistenceHelper.itemUUIDs(affectedBy: objectIDs)
            await index(uuids)
            if hasDeletions {
                await removeDeleted()
            }
        }
    }

    // When Spotlight asks: indexes those still in the store and removes the rest
    func reindex(_ uuids: [UUID]) async -> Void {
        await enqueue { [self] in
            guard !isLocked else {
                return
            }
            let indexed = await index(Set(uuids))
            await remove(Set(uuids).subtracting(indexed))
        }.value
    }

    func reindexAll() async -> Void {
        await enqueue { [self] in
            if isLocked {
                await removeAll()
            } else {
                await rebuildAll()
            }
        }.value
    }

    @discardableResult
    private func enqueue(_ operation: @escaping () async -> Void) -> Task<Void, Never> {
        let previous = lastOperation
        // Background work: it shouldn't compete with the UI
        let task = Task(priority: .utility) {
            await previous?.value
            await operation()
        }
        lastOperation = task
        return task
    }

    // MARK: - Index
    private func rebuildAll() async -> Void {
        let signpostState = PerformanceSignposts.signposter.beginInterval("indexAllItems")
        defer { PerformanceSignposts.signposter.endInterval("indexAllItems", signpostState) }

        let start = ContinuousClock.now
        await removeAll()
        let uuids = await persistenceHelper.itemUUIDs()
        await index(uuids)
        UserDefaults.standard.set(Self.version, forKey: versionKey)
        Self.logger.log("Indexed \(self.indexedUUIDs.count, privacy: .public) of \(uuids.count, privacy: .public) items in Spotlight in \(ContinuousClock.now - start, privacy: .public)")
    }

    // Returns the uuids of the items found and indexed
    @discardableResult
    private func index(_ uuids: Set<UUID>) async -> Set<UUID> {
        var indexed = Set<UUID>()
        let uuids = Array(uuids)
        for start in stride(from: 0, to: uuids.count, by: Self.batchSize) {
            let batch = Array(uuids[start..<min(start + Self.batchSize, uuids.count)])
            let entities = await persistenceHelper.transformItems(uuids: batch, ItemEntity.indexed)
            // The lock may have been turned on meanwhile; removeAll() follows in the queue
            guard !isLocked, !entities.isEmpty else {
                continue
            }
            do {
                try await searchableIndex.indexAppEntities(entities)
                indexed.formUnion(entities.map(\.id))
            } catch {
                Self.logger.error("Failed to index items: \(error.localizedDescription, privacy: .public)")
            }
        }
        if !indexed.isSubset(of: indexedUUIDs) {
            indexedUUIDs.formUnion(indexed)
            writeRegistry()
        }
        return indexed
    }

    // MARK: - Remove
    private func removeDeleted() async -> Void {
        let existing = await persistenceHelper.itemUUIDs()
        await remove(indexedUUIDs.subtracting(existing))
    }

    private func remove(_ uuids: Set<UUID>) async -> Void {
        guard !uuids.isEmpty else {
            return
        }
        do {
            try await searchableIndex.deleteAppEntities(identifiedBy: Array(uuids), ofType: ItemEntity.self)
            indexedUUIDs.subtract(uuids)
            writeRegistry()
        } catch {
            Self.logger.error("Failed to remove items from Spotlight: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func removeAll() async -> Void {
        do {
            try await searchableIndex.deleteAppEntities(ofType: ItemEntity.self)
            indexedUUIDs.removeAll()
            writeRegistry()
            // Rebuilt when the lock is turned off
            UserDefaults.standard.removeObject(forKey: versionKey)
        } catch {
            Self.logger.error("Failed to remove all items from Spotlight: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Registry
    // 16 bytes per uuid
    private static func readRegistry(at url: URL) -> Set<UUID> {
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        return Set(stride(from: 0, to: data.count - 15, by: 16).map { offset in
            data.withUnsafeBytes { UUID(uuid: $0.loadUnaligned(fromByteOffset: offset, as: uuid_t.self)) }
        })
    }

    private func writeRegistry() -> Void {
        var data = Data(capacity: indexedUUIDs.count * 16)
        for uuid in indexedUUIDs {
            withUnsafeBytes(of: uuid.uuid) { data.append(contentsOf: $0) }
        }
        do {
            try data.write(to: registryURL, options: .atomic)
        } catch {
            Self.logger.error("Failed to save the Spotlight registry: \(error.localizedDescription, privacy: .public)")
        }
    }
}

#if DEBUG
// For UI tests: the uuids of the items Spotlight holds for the app. AppIntentsTesting's
// spotlightQuery resolves its results through ItemQuery, which drops items no longer in the
// store, so it can't show items left behind in the index.
struct IndexedItemIdentifiersIntent: AppIntent {
    static let title: LocalizedStringResource = "Indexed Item Identifiers"
    static let isDiscoverable = false

    func perform() async throws -> some ReturnsValue<[String]> {
        // Every item has a display name, its name
        let query = CSSearchQuery(queryString: "displayName == \"*\"", queryContext: CSSearchQueryContext())
        var identifiers = [String]()
        for try await result in query.results {
            // "ItemEntity/<uuid>"
            identifiers.append(String(result.item.uniqueIdentifier.split(separator: "/").last ?? ""))
        }
        return .result(value: identifiers)
    }
}
#endif
