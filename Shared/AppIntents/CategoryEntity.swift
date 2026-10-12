//
//  CategoryEntity.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/28/26.
//

import Foundation
import AppIntents

// A Kind, presented as "Category" as everywhere else in the UI
struct CategoryEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category", numericFormat: "\(placeholder: .int) categories")
    static let defaultQuery = CategoryQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "tag"))
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

extension CategoryEntity {
    // On the queue of the object's context: the view context's for intents, a background one for indexing
    nonisolated init?(_ kind: Kind) {
        guard let uuid = kind.uuid else {
            return nil
        }
        self.init(id: uuid, name: kind.name ?? "")
    }
}

struct CategoryQuery: EntityStringQuery {
    @Dependency private var viewModel: BelongingsViewModel

    func entities(for identifiers: [CategoryEntity.ID]) async throws -> [CategoryEntity] {
        let viewModel = self.viewModel
        return await MainActor.run {
            let kinds: [Kind] = viewModel.persistenceHelper.fetch(.kind, uuids: identifiers)
            return kinds.compactMap(CategoryEntity.init)
        }
    }

    func entities(matching string: String) async throws -> [CategoryEntity] {
        await categories(nameContaining: string)
    }

    // Few enough to offer them all
    func suggestedEntities() async throws -> [CategoryEntity] {
        await categories(nameContaining: "")
    }

    private func categories(nameContaining string: String) async -> [CategoryEntity] {
        let viewModel = self.viewModel
        return await MainActor.run {
            let kinds: [Kind] = viewModel.persistenceHelper.fetch(.kind, nameContaining: string, sortDescriptors: NamedEntitySort.byName)
            return kinds.compactMap(CategoryEntity.init)
        }
    }
}

nonisolated enum NamedEntitySort {
    static var byName: [NSSortDescriptor] {
        [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
    }
}
