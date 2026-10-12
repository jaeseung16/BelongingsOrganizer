//
//  SearchItemsIntent.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import Foundation
import AppIntents

// "Search Belongings for headphones": opens the item list with the search filled in
@AppIntent(schema: .system.searchInApp)
struct SearchItemsIntent: ShowInAppSearchResultsIntent {
    static let searchScopes: [StringSearchScope] = [.general]

    var criteria: StringSearchCriteria

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some IntentResult {
        viewModel.showItems(matching: criteria.term)
        return .result()
    }
}
