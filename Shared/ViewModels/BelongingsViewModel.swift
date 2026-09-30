//
//  BelongingsViewModel.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation
import Combine
import CoreData
import SDWebImageWebPCoder
import os
import Persistence
import SwiftUI

class BelongingsViewModel: NSObject, ObservableObject {
    let logger = Logger()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let dateFormatterWithDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var persistence: Persistence

    private var subscriptions: Set<AnyCancellable> = []
    
    @Published var showAlert = false
    @Published var stringToSearch = ""
    @Published var navigateToItems = false
    @Published var navigationRequest: NavigationRequest?
    @Published var canRefresh = false

    var message = ""
    
    let persistenceHelper: PersistenceHelper
    let itemIndexer: ItemIndexer
    let imageProcessor = ImageProcesser.shared
    
    init(persistence: Persistence) {
        self.persistence = persistence
        self.persistenceHelper = PersistenceHelper(persistence: persistence)
        self.itemIndexer = ItemIndexer(persistenceHelper: persistenceHelper, storeName: persistence.container.name)
        super.init()
        
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { self.fetchUpdates($0) }
            .store(in: &subscriptions)
        
        let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)
        
        let viewContext = self.persistence.container.viewContext
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        // Set once rather than per save: overlapping saves used to clear each other's author
        viewContext.transactionAuthor = PersistenceHelper.transactionAuthor
        
        // Remote deletions are merged into the view context automatically; drop them from the lists
        // right away instead of keeping deleted objects around until the next refresh
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.removeDeletedObjects($0) }
            .store(in: &subscriptions)
        
        if self.persistence.container.persistentStoreCoordinator.persistentStores.isEmpty {
            logger.error("No persistent store is loaded")
            message = "Unable to open the data store. Items can't be loaded or saved. Please restart the app."
            showAlert = true
        }
        
        persistenceHelper.assignMissingUUIDs { result in
            if case .failure(let error) = result {
                self.logger.error("Failed to assign missing uuids: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        // Parameterized App Shortcut phrases ("Open <item> in Belongings") follow the item
        // suggestions; refresh them once a burst of saves or merges settles
        $itemsGeneration
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { _ in BelongingsShortcuts.updateAppShortcutParameters() }
            .store(in: &subscriptions)
        
        // Spotlight follows the app's own saves here and CloudKit's in fetchUpdates(_:)
        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didSaveObjectIDsNotification, object: viewContext)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.itemIndexer.update(changedObjectIDs: Self.objectIDs(in: $0)) }
            .store(in: &subscriptions)
        
        // The lock is an @AppStorage toggle in Settings
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in IntentAccessPolicy.isAppLocked }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.itemIndexer.setLocked($0) }
            .store(in: &subscriptions)
        
        fetchEntities()
        itemIndexer.start()
    }
    
    private static func objectIDs(in notification: Notification) -> [NSManagedObjectID] {
        let keys = [NSInsertedObjectIDsKey, NSUpdatedObjectIDsKey, NSDeletedObjectIDsKey]
        return keys.flatMap { (notification.userInfo?[$0] as? Set<NSManagedObjectID>) ?? [] }
    }
    
    func fetchEntities() -> Void {
        PerformanceSignposts.measure("fetchEntities") {
            fetchItems()
            fetchKinds()
            fetchBrands()
            fetchSellers()
        }
    }
    
    // Picks up changes merged from CloudKit since the last fetch
    func refresh() -> Void {
        fetchEntities()
        canRefresh = false
    }
    
    @Published var items = [Item]()
    // Bumped on every item fetch: after an edit or a dispose the refetched array can compare
    // equal to the old one, but the list's filtering and sorting still need to rerun
    @Published private(set) var itemsGeneration = 0
    func fetchItems() -> Void {
        let fetchRequest = persistenceHelper.getFetchRequest(for: Item.self, entityName: "Item", sortDescriptors: [])
        // Faults only: an item's row carries its photo inline (blobs under ~100 KB aren't stored
        // externally), so loading every row here would load every photo
        fetchRequest.includesPropertyValues = false
        items = persistenceHelper.perform(fetchRequest)
        itemsGeneration += 1
    }

    // The item list's query: SQLite filters and sorts, and batching faults in only the rows
    // the list actually shows. `items` stays unfiltered for the stats.
    func fetchItems(_ disposition: ItemDisposition, kinds: Set<Kind>, brands: Set<Brand>, sellers: Set<Seller>, sortType: SortType, sortDirection: SortDirection) -> [Item] {
        var predicates = [NSPredicate(format: disposition == .active ? "disposed == nil" : "disposed != nil")]
        if stringToSearch.isEmpty {
            predicates.append(NSPredicate(format: "name != nil"))
        } else {
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@", stringToSearch))
        }
        // A selected category, brand, or seller may have been deleted since it was selected
        let kinds = kinds.filter(isAvailable)
        if !kinds.isEmpty {
            predicates.append(NSPredicate(format: "ANY kind IN %@", kinds))
        }
        let brands = brands.filter(isAvailable)
        if !brands.isEmpty {
            predicates.append(NSPredicate(format: "ANY brand IN %@", brands))
        }
        let sellers = sellers.filter(isAvailable)
        if !sellers.isEmpty {
            predicates.append(NSPredicate(format: "ANY seller IN %@", sellers))
        }
        
        let key: String
        switch sortType {
        case .lastupd:
            key = "lastupd"
        case .obtained:
            key = "obtained"
        case .name:
            key = "name"
        }
        let sortDescriptors = [NSSortDescriptor(key: key, ascending: sortDirection == .ascending)]
        
        let fetchRequest = persistenceHelper.getFetchRequest(for: Item.self, entityName: "Item", sortDescriptors: sortDescriptors, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
        fetchRequest.fetchBatchSize = 50
        return persistenceHelper.perform(fetchRequest)
    }
    
    @Published var kinds = [Kind]()
    var filteredKinds: [Kind] {
        kinds.filter {
            if let name = $0.name {
                return checkIfStringToSearchContainedIn(name)
            } else {
                return false
            }
        }
    }
    
    func fetchKinds() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Kind.self, entityName: "Kind", sortDescriptors: sortDescriptors)
        kinds = persistenceHelper.perform(fetchRequest)
    }
    
    @Published var brands = [Brand]()
    var filteredBrands: [Brand] {
        brands.filter {
            if let name = $0.name {
                return checkIfStringToSearchContainedIn(name)
            } else {
                return false
            }
        }
    }
    
    func fetchBrands() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Brand.self, entityName: "Brand", sortDescriptors: sortDescriptors)
        brands = persistenceHelper.perform(fetchRequest)
    }
    
    @Published var sellers = [Seller]()
    var filteredSellers: [Seller] {
        sellers.filter {
            if let name = $0.name {
                return checkIfStringToSearchContainedIn(name)
            } else {
                return false
            }
        }
    }
    
    func fetchSellers() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Seller.self, entityName: "Seller", sortDescriptors: sortDescriptors)
        sellers = persistenceHelper.perform(fetchRequest)
    }
    
    func update(_ existingEntity: Item, to dto: ItemDTO, kind: [Kind], brand: Brand?, seller: Seller?, _ isObtainedDateEdited: Bool, _ isDisposedDateEdited: Bool) -> Void {
        guard isAvailable(existingEntity) else {
            handleMissing(existingEntity, name: dto.name)
            return
        }
        
        Task {
            var dto = dto
            if let data = dto.image {
                dto.image = await resized(data) ?? data
            }
            
            // The item may have been deleted (here or by a CloudKit merge) while resizing
            guard isAvailable(existingEntity) else {
                handleMissing(existingEntity, name: dto.name)
                return
            }
            
            persistenceHelper.update(existingEntity, to: dto, kind: kind, brand: brand, seller: seller, isObtainedDateEdited, isDisposedDateEdited) { result in
                switch result {
                case .success(_):
                    self.handleSuccess(refetching: [.item])
                case .failure(let error):
                    self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                    self.message = "Cannot update name = \(String(describing: dto.name))"
                    self.handle(error: error, completionHandler: nil)
                }
            }
        }
    }
    
    func tryResize(image: Data) -> Data? {
        return imageProcessor.tryResize(image: image)
    }
    
    // Decoding and re-encoding a photo takes long enough to hitch the UI, so it runs off the main actor
    func resized(_ image: Data) async -> Data? {
        await Self.resize(image, using: imageProcessor)
    }
    
    @concurrent
    nonisolated private static func resize(_ image: Data, using imageProcessor: ImageProcesser) async -> Data? {
        PerformanceSignposts.measure("resize") {
            imageProcessor.tryResize(image: image)
        }
    }

    func updateDisposed(_ item: Item, to date: Date?) -> Void {
        persistenceHelper.updateDisposed(item, to: date) { result in
            switch result {
            case .success(_):
                self.handleSuccess(refetching: [.item])
            case .failure(let error):
                self.logger.log("Error while updating disposed date: \(error.localizedDescription, privacy: .public)")
                self.message = "Cannot update name = \(String(describing: item.name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    func update(_ existingEntity: Kind, to dto: KindDTO) -> Void {
        guard isAvailable(existingEntity) else {
            handleMissing(existingEntity, name: dto.name)
            return
        }
        persistenceHelper.update(existingEntity, to: dto) { result in
            switch result {
            case .success(_):
                self.handleSuccess(refetching: [.kind])
            case .failure(let error):
                self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                self.message = "Cannot update name = \(String(describing: dto.name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    func update(_ existingEntity: Brand, to dto: BrandDTO) -> Void {
        guard isAvailable(existingEntity) else {
            handleMissing(existingEntity, name: dto.name)
            return
        }
        persistenceHelper.update(existingEntity, to: dto) { result in
            switch result {
            case .success(_):
                self.handleSuccess(refetching: [.brand])
            case .failure(let error):
                self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                self.message = "Cannot update name = \(String(describing: dto.name)) and url = \(String(describing: dto.url))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    func update(_ existingEntity: Seller, to dto: SellerDTO) -> Void {
        guard isAvailable(existingEntity) else {
            handleMissing(existingEntity, name: dto.name)
            return
        }
        persistenceHelper.update(existingEntity, to: dto) { result in
            switch result {
            case .success(_):
                self.handleSuccess(refetching: [.seller])
            case .failure(let error):
                self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                self.message = "Cannot update name = \(String(describing: dto.name)) and url = \(String(describing: dto.url))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    func delete(_ objects: [NSManagedObject], completionHandler: @escaping (Error) -> Void) -> Void {
        let entities = Set(objects.compactMap { Entities(rawValue: $0.entity.name ?? "") })
        persistenceHelper.delete(objects) { result in
            switch result {
            case .success(_):
                self.handleSuccess(refetching: entities)
            case .failure(let error):
                self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    // The rollback restored the objects that were already pruned from the lists
                    self.fetchEntities()
                    completionHandler(error)
                }
            }
        }
    }
    
    // A save only changes the entities it touched; edits to existing objects are already live
    private func handleSuccess(refetching entities: Set<Entities>) -> Void {
        DispatchQueue.main.async {
            self.fetch(entities)
        }
    }
    
    private func fetch(_ entities: Set<Entities>) -> Void {
        for entity in entities {
            switch entity {
            case .item:
                fetchItems()
            case .kind:
                fetchKinds()
            case .brand:
                fetchBrands()
            case .seller:
                fetchSellers()
            }
        }
    }
    
    private func handle(error: Error, completionHandler: ((Error) -> Void)?) -> Void {
        DispatchQueue.main.async {
            self.showAlert.toggle()
            if let completionHandler = completionHandler {
                completionHandler(error)
            }
        }
    }
    
    // MARK: - Deleted objects
    // An object deleted here or merged in as deleted from CloudKit either reports isDeleted
    // (pending save) or has lost its context (saved)
    private func isAvailable(_ object: NSManagedObject) -> Bool {
        !object.isDeleted && object.managedObjectContext != nil
    }
    
    private func handleMissing(_ object: NSManagedObject, name: String?) -> Void {
        logger.error("Can't update a deleted object: \(object.objectID, privacy: .public)")
        message = "Cannot update \(name ?? "this record"): it has been deleted, possibly on another device"
        showAlert = true
        removeDeletedObjects()
    }
    
    private func removeDeletedObjects(_ notification: Notification) -> Void {
        let keys = [NSDeletedObjectsKey, NSInvalidatedObjectsKey, NSInvalidatedAllObjectsKey]
        guard let userInfo = notification.userInfo, keys.contains(where: { userInfo[$0] != nil }) else {
            return
        }
        removeDeletedObjects()
    }
    
    private func removeDeletedObjects() -> Void {
        // Assign only when something changed, so SwiftUI isn't invalidated for nothing
        func prune<T: NSManagedObject>(_ objects: inout [T]) {
            if objects.contains(where: { !isAvailable($0) }) {
                objects.removeAll { !isAvailable($0) }
            }
        }
        prune(&items)
        prune(&kinds)
        prune(&brands)
        prune(&sellers)
    }
    
    // MARK: - Persistence History Request
    private func fetchUpdates(_ notification: Notification) -> Void {
        Task {
            do {
                // The app's own saves are already in the view context; only other authors (CloudKit) matter
                let changedObjectIDs = try await persistence.fetchUpdates(excludingAuthors: [PersistenceHelper.transactionAuthor])
                if !changedObjectIDs.isEmpty && !canRefresh {
                    canRefresh = true
                }
                itemIndexer.update(changedObjectIDs: changedObjectIDs)
            } catch {
                self.logger.log("Error while updating history: \(error.localizedDescription, privacy: .public) \(Thread.callStackSymbols, privacy: .public)")
            }
        }
    }
    
    // MARK: - App Intents
    // Siri and Shortcuts report failures themselves, so these throw instead of raising the app's alert
    func addItem(_ dto: ItemDTO) async throws -> Item {
        if !dto.kind.allSatisfy(isAvailable) {
            throw BelongingsError.notFound(.kind)
        }
        if let brand = dto.brand, !isAvailable(brand) {
            throw BelongingsError.notFound(.brand)
        }
        if let seller = dto.seller, !isAvailable(seller) {
            throw BelongingsError.notFound(.seller)
        }
        let item = persistenceHelper.insertBelonging(name: dto.name, kind: dto.kind, brand: dto.brand, seller: dto.seller, note: dto.note,
                                                     obtained: dto.obtained, buyPrice: dto.buyPrice, quantity: Int64(dto.quantity),
                                                     buyCurrency: dto.buyCurrency, image: dto.image)
        try await persistenceHelper.save()
        handleSuccess(refetching: [.item])
        return item
    }
    
    func setDisposed(_ item: Item, on date: Date?) async throws -> Void {
        guard isAvailable(item) else {
            removeDeletedObjects()
            throw BelongingsError.notFound(.item)
        }
        try await withCheckedThrowingContinuation { continuation in
            persistenceHelper.updateDisposed(item, to: date) { continuation.resume(with: $0) }
        }
        handleSuccess(refetching: [.item])
    }
    
    func countItems(_ disposition: ItemDisposition, kind: Kind?, brand: Brand?, seller: Seller?) -> Int {
        // Unnamed items aren't listed, so they aren't counted either
        var predicates = [NSPredicate(format: disposition == .active ? "disposed == nil" : "disposed != nil"),
                          NSPredicate(format: "name != nil")]
        if let kind {
            predicates.append(NSPredicate(format: "ANY kind == %@", kind))
        }
        if let brand {
            predicates.append(NSPredicate(format: "ANY brand == %@", brand))
        }
        if let seller {
            predicates.append(NSPredicate(format: "ANY seller == %@", seller))
        }
        return persistenceHelper.count(.item, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
    }
    
    // MARK: - Navigation
    // Where a notification, Siri, or Shortcuts asked the app to go; ContentView follows it
    enum NavigationRequest: Equatable {
        case item(Item)
        case kind(Kind)
        case brand(Brand)
        case seller(Seller)
    }
    
    // Shows the item list searched for the string, as a notification tap or a Siri search does
    func showItems(matching search: String) -> Void {
        stringToSearch = search
        navigateToItems = true
    }
    
    // The object an App Intent entity refers to
    func object<Object: NSManagedObject>(_ entity: Entities, uuid: UUID) throws -> Object {
        let objects: [Object] = persistenceHelper.fetch(entity, uuids: [uuid])
        guard let object = objects.first else {
            throw BelongingsError.notFound(entity)
        }
        return object
    }
    
    func open(_ entity: Entities, uuid: UUID) throws -> Void {
        let object: NSManagedObject = try object(entity, uuid: uuid)
        switch object {
        case let item as Item:
            navigationRequest = .item(item)
        case let kind as Kind:
            navigationRequest = .kind(kind)
        case let brand as Brand:
            navigationRequest = .brand(brand)
        case let seller as Seller:
            navigationRequest = .seller(seller)
        default:
            throw BelongingsError.notFound(entity)
        }
    }
    
    // MARK: -
    public func checkIfStringToSearchContainedIn(_ input: String) -> Bool {
        if stringToSearch == "" {
            return true
        } else {
            return input.lowercased().contains(stringToSearch.lowercased())
        }
    }
    
    // MARK: - Stats
    private let maxCountForStats = 10
    private let others = "others"
    
    public func itemOverTime(type: StatsType, from start: Date, to end: Date) -> [ItemOverTime] {
        let itemsBetweenStartAndEnd = type == .obtained ? itemsObtainedBetween(from: start, to: end) : itemsDisposedBetween(from: start, to: end)

        // Bucket by day; the stored dates carry a time component
        var itemsByDate = [Date: Int]()
        for item in itemsBetweenStartAndEnd {
            if let date = type == .obtained ? item.obtained : item.disposed {
                itemsByDate[Calendar.current.startOfDay(for: date), default: 0] += 1
            }
        }

        return itemsByDate.map { ItemOverTime(date: $0, itemCount: $1) }
            .sorted(by: { $0.date > $1.date })
    }

    public func itemCountsByKind(type: StatsType, from start: Date, to end: Date) -> [KindStats] {
        var result = [KindStats]()
        let itemsBetweenStartAndEnd = type == .obtained ? itemsObtainedBetween(from: start, to: end) : itemsDisposedBetween(from: start, to: end)
        
        var itemsByKind = [String: Int]()
        for item in itemsBetweenStartAndEnd {
            for kind in item.kinds {
                if let name = kind.name {
                    itemsByKind[name, default: 0] += 1
                }
            }
        }
        
        let itemCountsByKind = itemsByKind.map { (name, itemCount) in
            return KindStats(name: name, itemCount: itemCount)
        }.sorted(by: { $0.itemCount > $1.itemCount })
        
        if (itemCountsByKind.count > maxCountForStats) {
            result.append(contentsOf: itemCountsByKind[..<maxCountForStats])
            result.append(KindStats(name: others, itemCount: itemCountsByKind[maxCountForStats...].reduce(0, { $0 + $1.itemCount })))
        } else {
            result.append(contentsOf: itemCountsByKind)
        }
        
        return result
    }
    
    private func itemsObtainedBetween(from start: Date, to end: Date) -> [Item] {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: DateComponents(day: 1), to: calendar.startOfDay(for: end))!
        return fetchItems("obtained", from: calendar.startOfDay(for: start), through: endDate)
    }
    
    private func itemsDisposedBetween(from start: Date, to end: Date) -> [Item] {
        let calendar = Calendar.current
        return fetchItems("disposed", from: calendar.startOfDay(for: start), through: calendar.startOfDay(for: end))
    }
    
    // Items whose date falls from `startDate` through the hour starting at `endDate`, the range the
    // stats used to select with hour-granularity comparisons. Fetched rather than filtered from
    // `items`, which holds faults, with the relationships the stats count prefetched.
    private func fetchItems(_ dateKey: String, from startDate: Date, through endDate: Date) -> [Item] {
        let endOfRange = Calendar.current.date(byAdding: DateComponents(hour: 1), to: endDate)!
        let predicate = NSPredicate(format: "%K >= %@ AND %K < %@", dateKey, startDate as NSDate, dateKey, endOfRange as NSDate)
        let fetchRequest = persistenceHelper.getFetchRequest(for: Item.self, entityName: "Item", predicate: predicate)
        fetchRequest.relationshipKeyPathsForPrefetching = ["kind", "brand", "seller"]
        return persistenceHelper.perform(fetchRequest)
    }
    
    public func itemCountByBrand(type: StatsType, from start: Date, to end: Date) -> [BrandStats] {
        var result = [BrandStats]()
        let itemsBetweenStartAndEnd = type == .obtained ? itemsObtainedBetween(from: start, to: end) : itemsDisposedBetween(from: start, to: end)
        
        var itemsByBrand = [String: Int]()
        for item in itemsBetweenStartAndEnd {
            if let name = item.firstBrand?.name {
                itemsByBrand[name, default: 0] += 1
            }
        }
        
        let itemCountsByBrand = itemsByBrand.map { (name, itemCount) in
            return BrandStats(name: name, itemCount: itemCount)
        }.sorted(by: { $0.itemCount > $1.itemCount })
        
        if (itemCountsByBrand.count > maxCountForStats) {
            result.append(contentsOf: itemCountsByBrand[..<maxCountForStats])
            result.append(BrandStats(name: others, itemCount: itemCountsByBrand[maxCountForStats...].reduce(0, { $0 + $1.itemCount })))
        } else {
            result.append(contentsOf: itemCountsByBrand)
        }
        
        return result
        
    }
    
    public func itemCountBySeller(type: StatsType, from start: Date, to end: Date) -> [SellerStats] {
        var result = [SellerStats]()
        let itemsBetweenStartAndEnd = type == .obtained ? itemsObtainedBetween(from: start, to: end) : itemsDisposedBetween(from: start, to: end)
        
        var itemsBySeller = [String: Int]()
        for item in itemsBetweenStartAndEnd {
            if let name = item.firstSeller?.name {
                itemsBySeller[name, default: 0] += 1
            }
        }
        
        let itemCountsBySeller =  itemsBySeller.map { (name, itemCount) in
            return SellerStats(name: name, itemCount: itemCount)
        }.sorted(by: { $0.itemCount > $1.itemCount })
        
        if (itemCountsBySeller.count > maxCountForStats) {
            result.append(contentsOf: itemCountsBySeller[..<maxCountForStats])
            result.append(SellerStats(name: others, itemCount: itemCountsBySeller[maxCountForStats...].reduce(0, { $0 + $1.itemCount })))
        } else {
            result.append(contentsOf: itemCountsBySeller)
        }
        
        return result
        
    }
    
    func getItems(_ kind: Kind) -> [Item] {
        guard let items = kind.items else {
            return [Item]()
        }
        return getSortedItems(items)
    }

    func getItemCount(_ kind: Kind) -> Int {
        guard let items = kind.items else {
            return 0
        }
        return getItemCount(items)
    }

    func getItems(_ brand: Brand) -> [Item] {
        guard let items = brand.items else {
            return [Item]()
        }
        return getSortedItems(items)
    }

    func getItemCount(_ brand: Brand) -> Int {
        guard let items = brand.items else {
            return 0
        }
        return getItemCount(items)
    }

    func getItems(_ seller: Seller) -> [Item] {
        guard let items = seller.items else {
            return [Item]()
        }
        return getSortedItems(items)
    }

    func getItemCount(_ seller: Seller) -> Int {
        guard let items = seller.items else {
            return 0
        }
        return getItemCount(items)
    }

    private func getSortedItems(_ items: NSSet) -> [Item] {
        return items.compactMap { $0 as? Item }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }

    private func getItemCount(_ items: NSSet) -> Int {
        return items.count
    }

    // MARK: - PersistenceHelper
    public var imageData: Data? {
        return persistenceHelper.imageData
    }
    
    public func updateImage(_ imageData: Data?) {
        persistenceHelper.imageData = imageData
    }
    
    public func saveBelonging(name: String, kind: [Kind], brand: Brand?, seller: Seller?, note: String, obtained: Date, buyPrice: Double, quantity: Int64, buyCurrency: String, image: Data?) -> Void {
        persistenceHelper.saveBelonging(name: name, kind: kind, brand: brand, seller: seller, note: note, obtained: obtained, buyPrice: buyPrice, quantity: quantity, buyCurrency: buyCurrency, image: image) { result in
            switch result {
            case .success(()):
                self.handleSuccess(refetching: [.item])
            case .failure(let error):
                self.logger.error("While saving a new item, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new item with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    public func saveKind(name: String) -> Void {
        persistenceHelper.saveKind(name.trimmingCharacters(in: .whitespaces)) { result in
            switch result {
            case .success(()):
                self.handleSuccess(refetching: [.kind])
            case .failure(let error):
                self.logger.error("While saving a new category, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new category with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    public func saveBrand(name: String, urlString: String) -> Void {
        persistenceHelper.saveBrand(name.trimmingCharacters(in: .whitespaces), url: URL(string: urlString)) { result in
            switch result {
            case .success(()):
                self.handleSuccess(refetching: [.brand])
            case .failure(let error):
                self.logger.error("While saving a new brand, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new brand with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    public func saveSeller(name: String, urlString: String) -> Void {
        persistenceHelper.saveSeller(name.trimmingCharacters(in: .whitespaces), url: URL(string: urlString)) { result in
            switch result {
            case .success(()):
                self.handleSuccess(refetching: [.seller])
            case .failure(let error):
                self.logger.error("While saving a new seller, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new seller with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    // MARK: - ImagePaster
    func hasImage() -> Bool {
        return imageProcessor.hasImage()
    }
    
    func paste(completionHandler: @escaping @MainActor (Data?, Error?) -> Void) ->Void {
        imageProcessor.paste(completionHandler: completionHandler)
    }

    func getData(from info: DropInfo, completionHandler: @escaping @MainActor (Data?, Error?) -> Void) ->Void {
        imageProcessor.getData(from: info, completionHandler: completionHandler)
    }
    
    // MARK: - URL Vaildation
    func validatedURL(from urlString: String) async -> URL? {
        do {
            return try await URLValidator.validatedURL(from: urlString)
        } catch {
            logger.error("Failed to validate url=\(urlString): \(error, privacy: .public)")
            return nil
        }
    }
}

