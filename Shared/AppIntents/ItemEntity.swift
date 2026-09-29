//
//  ItemEntity.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/28/26.
//

import Foundation
import AppIntents

struct ItemEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Item", numericFormat: "\(placeholder: .int) items")
    static let defaultQuery = ItemQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Note")
    var note: String

    @Property(title: "Quantity")
    var quantity: Int

    @Property(title: "Obtained")
    var obtained: Date?

    @Property(title: "Disposed")
    var disposed: Date?

    @Property(title: "Price")
    var buyPrice: Double

    @Property(title: "Currency")
    var buyCurrency: String

    @Property(title: "Categories")
    var categories: [CategoryEntity]

    @Property(title: "Brand")
    var brand: BrandEntity?

    @Property(title: "Seller")
    var seller: SellerEntity?

    // A small JPEG of the photo; left out while the app lock is on
    var thumbnail: Data?

    var displayRepresentation: DisplayRepresentation {
        let details = categories.map(\.name) + [brand?.name].compactMap { $0 }
        let image = thumbnail.map { DisplayRepresentation.Image(data: $0) } ?? .init(systemName: "shippingbox")
        if details.isEmpty {
            return DisplayRepresentation(title: "\(name)", image: image)
        }
        return DisplayRepresentation(title: "\(name)", subtitle: "\(details.joined(separator: ", "))", image: image)
    }
}

extension ItemEntity {
    @MainActor
    init?(_ item: Item) {
        guard let uuid = item.uuid else {
            return nil
        }
        self.id = uuid
        self.name = item.name ?? ""
        self.note = item.note ?? ""
        self.quantity = Int(item.quantity)
        self.obtained = item.obtained
        self.disposed = item.disposed
        self.buyPrice = item.buyPrice
        self.buyCurrency = item.buyCurrency ?? ""
        self.categories = item.kinds.compactMap(CategoryEntity.init)
        self.brand = item.firstBrand.flatMap(BrandEntity.init)
        self.seller = item.firstSeller.flatMap(SellerEntity.init)
    }

    // Built on the main actor, where the view context's objects live; the photos are only
    // copied here and downsampled afterwards, off the main actor
    @MainActor
    static func snapshots(of items: [Item]) -> [(entity: ItemEntity, photo: Data?)] {
        let showsPhotos = IntentAccessPolicy.showsPhotos
        return items.compactMap { item in
            ItemEntity(item).map { ($0, showsPhotos ? item.image : nil) }
        }
    }

    @concurrent
    static func withThumbnails(_ snapshots: [(entity: ItemEntity, photo: Data?)]) async -> [ItemEntity] {
        PerformanceSignposts.measure("itemEntityThumbnails") {
            snapshots.map { snapshot in
                var entity = snapshot.entity
                if let photo = snapshot.photo {
                    entity.thumbnail = ThumbnailCache.jpegThumbnail(from: photo, maxPixelSize: thumbnailPixelSize)
                }
                return entity
            }
        }
    }

    // An item just changed by an intent, with its thumbnail
    @MainActor
    static func fetched(_ item: Item) async throws -> ItemEntity {
        guard let entity = await withThumbnails(snapshots(of: [item])).first else {
            throw BelongingsError.notFound(.item)
        }
        return entity
    }

    private static let thumbnailPixelSize: CGFloat = 120
}

struct ItemQuery: EntityStringQuery {
    // Siri and Shortcuts show a short list; the in-app search is the place for long results
    private static let resultLimit = 20

    @Dependency private var viewModel: BelongingsViewModel

    func entities(for identifiers: [ItemEntity.ID]) async throws -> [ItemEntity] {
        let viewModel = self.viewModel
        let snapshots = await MainActor.run {
            let items: [Item] = viewModel.persistenceHelper.fetch(.item, uuids: identifiers)
            return ItemEntity.snapshots(of: items)
        }
        return await ItemEntity.withThumbnails(snapshots)
    }

    func entities(matching string: String) async throws -> [ItemEntity] {
        await items(nameContaining: string, ownedOnly: false)
    }

    // The most recently updated items still owned
    func suggestedEntities() async throws -> [ItemEntity] {
        await items(nameContaining: "", ownedOnly: true)
    }

    private func items(nameContaining string: String, ownedOnly: Bool) async -> [ItemEntity] {
        let viewModel = self.viewModel
        let snapshots = await MainActor.run {
            let predicate = ownedOnly ? NSPredicate(format: "disposed == nil") : nil
            let items: [Item] = viewModel.persistenceHelper.fetch(.item, nameContaining: string, predicate: predicate,
                                                                  sortDescriptors: [NSSortDescriptor(key: "lastupd", ascending: false)],
                                                                  limit: Self.resultLimit)
            return ItemEntity.snapshots(of: items)
        }
        return await ItemEntity.withThumbnails(snapshots)
    }
}
