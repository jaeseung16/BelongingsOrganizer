//
//  GetItemDetailsIntent.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import Foundation
import AppIntents

// Hands an item's properties to the next action in a shortcut
struct GetItemDetailsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Item Details"
    static let description = IntentDescription("Gets an item's details, such as its price, dates, category, brand, and seller.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Item")
    var item: ItemEntity

    @Dependency private var viewModel: BelongingsViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Get details of \(\.$item)")
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<ItemEntity> {
        let object: Item = try viewModel.object(.item, uuid: item.id)
        return .result(value: try await ItemEntity.fetched(object))
    }
}
