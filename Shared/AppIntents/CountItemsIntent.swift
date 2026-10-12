//
//  CountItemsIntent.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import Foundation
import AppIntents

// Counts only: a total price would mix currencies
struct CountItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Count Items"
    static let description = IntentDescription("Counts items, optionally in a category or from a brand or a seller.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Items", default: .current)
    var disposition: ItemDispositionAppEnum

    @Parameter(title: "Category")
    var category: CategoryEntity?

    @Parameter(title: "Brand")
    var brand: BrandEntity?

    @Parameter(title: "Seller")
    var seller: SellerEntity?

    @Dependency private var viewModel: BelongingsViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Count \(\.$disposition) items") {
            \.$category
            \.$brand
            \.$seller
        }
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<Int> & ProvidesDialog {
        let kind: Kind? = try category.map { try viewModel.object(.kind, uuid: $0.id) }
        let brand: Brand? = try self.brand.map { try viewModel.object(.brand, uuid: $0.id) }
        let seller: Seller? = try self.seller.map { try viewModel.object(.seller, uuid: $0.id) }
        let count = viewModel.countItems(disposition.itemDisposition, kind: kind, brand: brand, seller: seller)

        let items = count == 1 ? "1 item" : "\(count) items"
        var scope = ""
        if let kind {
            scope += " in \(kind.name ?? "")"
        }
        if let brand {
            scope += " by \(brand.name ?? "")"
        }
        if let seller {
            scope += " from \(seller.name ?? "")"
        }
        let dialog: IntentDialog = switch disposition {
        case .current: "You have \(items)\(scope)."
        case .disposed: "You have disposed of \(items)\(scope)."
        }
        return .result(value: count, dialog: dialog)
    }
}

enum ItemDispositionAppEnum: String, AppEnum {
    case current
    case disposed

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Disposition"
    static let caseDisplayRepresentations: [ItemDispositionAppEnum: DisplayRepresentation] = [
        .current: "Current",
        .disposed: "Disposed",
    ]

    var itemDisposition: ItemDisposition {
        switch self {
        case .current:
            return .active
        case .disposed:
            return .disposed
        }
    }
}
