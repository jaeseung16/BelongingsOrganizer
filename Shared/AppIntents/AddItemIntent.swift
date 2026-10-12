//
//  AddItemIntent.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import Foundation
import AppIntents
import SwiftUI
import UniformTypeIdentifiers

// Categories, brands, and sellers have to exist already; the app is where new ones are made
struct AddItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Item"
    static let description = IntentDescription("Adds an item to Belongings.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Name", requestValueDialog: "What's the item called?")
    var name: String

    @Parameter(title: "Categories")
    var categories: [CategoryEntity]?

    @Parameter(title: "Brand")
    var brand: BrandEntity?

    @Parameter(title: "Seller")
    var seller: SellerEntity?

    @Parameter(title: "Obtained", description: "Today if not given")
    var obtained: Date?

    @Parameter(title: "Price")
    var buyPrice: Double?

    @Parameter(title: "Currency", optionsProvider: CurrencyOptionsProvider())
    var buyCurrency: String?

    @Parameter(title: "Quantity", default: 1, inclusiveRange: (1, 1_000_000))
    var quantity: Int

    @Parameter(title: "Note")
    var note: String?

    @Parameter(title: "Photo", supportedContentTypes: [.image])
    var photo: IntentFile?

    @Dependency private var viewModel: BelongingsViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) to Belongings") {
            \.$categories
            \.$brand
            \.$seller
            \.$obtained
            \.$buyPrice
            \.$buyCurrency
            \.$quantity
            \.$note
            \.$photo
        }
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<ItemEntity> & ProvidesDialog & ShowsSnippetView {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw $name.needsValueError()
        }
        let currency = (buyCurrency ?? CurrencyOptionsProvider.appCurrency).uppercased()
        guard CurrencyOptionsProvider.currencyCodes.contains(currency) else {
            throw $buyCurrency.needsValueError("Which currency?")
        }

        let kinds: [Kind] = try (categories ?? []).map { try viewModel.object(.kind, uuid: $0.id) }
        let brand: Brand? = try self.brand.map { try viewModel.object(.brand, uuid: $0.id) }
        let seller: Seller? = try self.seller.map { try viewModel.object(.seller, uuid: $0.id) }
        // Resized like a photo picked in the app
        let image = if let photo { await viewModel.resized(photo.data) } else { Data?.none }

        let dto = ItemDTO(id: UUID(), name: name, note: note ?? "", quantity: quantity, buyPrice: buyPrice ?? 0, sellPrice: 0,
                          buyCurrency: currency, sellCurrency: "",
                          obtained: Calendar(identifier: .iso8601).startOfDay(for: obtained ?? Date()),
                          disposed: Date(), image: image, kind: kinds, brand: brand, seller: seller)
        let item = try await viewModel.addItem(dto)
        let entity = try await ItemEntity.fetched(item)
        return .result(value: entity, dialog: "Added \(name) to Belongings.", view: ItemSnippetView(item: entity))
    }
}

struct CurrencyOptionsProvider: DynamicOptionsProvider {
    static var currencyCodes: [String] {
        Locale.commonISOCurrencyCodes
    }

    // The currency the app's Add Item sheet last used
    static var appCurrency: String {
        UserDefaults.standard.string(forKey: BelongsOrganizerConstants.currency.rawValue) ?? "USD"
    }

    func results() async throws -> [String] {
        Self.currencyCodes
    }

    func defaultResult() async -> String? {
        Self.appCurrency
    }
}
