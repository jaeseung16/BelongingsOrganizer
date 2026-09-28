//
//  SellerEntity.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/28/26.
//

import Foundation
import AppIntents

struct SellerEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Seller", numericFormat: "\(placeholder: .int) sellers")
    static let defaultQuery = SellerQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Website")
    var url: URL?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "storefront"))
    }

    init(id: UUID, name: String, url: URL?) {
        self.id = id
        self.name = name
        self.url = url
    }
}

extension SellerEntity {
    @MainActor
    init?(_ seller: Seller) {
        guard let uuid = seller.uuid else {
            return nil
        }
        self.init(id: uuid, name: seller.name ?? "", url: seller.url)
    }
}

struct SellerQuery: EntityStringQuery {
    @Dependency private var viewModel: BelongingsViewModel

    func entities(for identifiers: [SellerEntity.ID]) async throws -> [SellerEntity] {
        let viewModel = self.viewModel
        return await MainActor.run {
            let sellers: [Seller] = viewModel.persistenceHelper.fetch(.seller, uuids: identifiers)
            return sellers.compactMap(SellerEntity.init)
        }
    }

    func entities(matching string: String) async throws -> [SellerEntity] {
        await sellers(nameContaining: string)
    }

    // Few enough to offer them all
    func suggestedEntities() async throws -> [SellerEntity] {
        await sellers(nameContaining: "")
    }

    private func sellers(nameContaining string: String) async -> [SellerEntity] {
        let viewModel = self.viewModel
        return await MainActor.run {
            let sellers: [Seller] = viewModel.persistenceHelper.fetch(.seller, nameContaining: string, sortDescriptors: NamedEntitySort.byName)
            return sellers.compactMap(SellerEntity.init)
        }
    }
}
