//
//  OpenIntents.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import Foundation
import AppIntents

// Each opens the app on the entity's sidebar section with the entity selected. The app lock
// still covers the window, so these only need the policy for resolving the target.

struct OpenItemIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Item"
    static let description = IntentDescription("Opens an item in Belongings.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Item")
    var target: ItemEntity

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some IntentResult {
        try viewModel.open(.item, uuid: target.id)
        return .result()
    }
}

struct OpenCategoryIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Category"
    static let description = IntentDescription("Opens a category in Belongings.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Category")
    var target: CategoryEntity

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some IntentResult {
        try viewModel.open(.kind, uuid: target.id)
        return .result()
    }
}

struct OpenBrandIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Brand"
    static let description = IntentDescription("Opens a brand in Belongings.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Brand")
    var target: BrandEntity

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some IntentResult {
        try viewModel.open(.brand, uuid: target.id)
        return .result()
    }
}

struct OpenSellerIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Seller"
    static let description = IntentDescription("Opens a seller in Belongings.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Seller")
    var target: SellerEntity

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some IntentResult {
        try viewModel.open(.seller, uuid: target.id)
        return .result()
    }
}
