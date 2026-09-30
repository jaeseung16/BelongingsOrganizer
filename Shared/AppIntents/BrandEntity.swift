//
//  BrandEntity.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/28/26.
//

import Foundation
import AppIntents

struct BrandEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Brand", numericFormat: "\(placeholder: .int) brands")
    static let defaultQuery = BrandQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Website")
    var url: URL?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "star"))
    }

    init(id: UUID, name: String, url: URL?) {
        self.id = id
        self.name = name
        self.url = url
    }
}

extension BrandEntity {
    // On the queue of the object's context: the view context's for intents, a background one for indexing
    nonisolated init?(_ brand: Brand) {
        guard let uuid = brand.uuid else {
            return nil
        }
        self.init(id: uuid, name: brand.name ?? "", url: brand.url)
    }
}

struct BrandQuery: EntityStringQuery {
    @Dependency private var viewModel: BelongingsViewModel

    func entities(for identifiers: [BrandEntity.ID]) async throws -> [BrandEntity] {
        let viewModel = self.viewModel
        return await MainActor.run {
            let brands: [Brand] = viewModel.persistenceHelper.fetch(.brand, uuids: identifiers)
            return brands.compactMap(BrandEntity.init)
        }
    }

    func entities(matching string: String) async throws -> [BrandEntity] {
        await brands(nameContaining: string)
    }

    // Few enough to offer them all
    func suggestedEntities() async throws -> [BrandEntity] {
        await brands(nameContaining: "")
    }

    private func brands(nameContaining string: String) async -> [BrandEntity] {
        let viewModel = self.viewModel
        return await MainActor.run {
            let brands: [Brand] = viewModel.persistenceHelper.fetch(.brand, nameContaining: string, sortDescriptors: NamedEntitySort.byName)
            return brands.compactMap(BrandEntity.init)
        }
    }
}
