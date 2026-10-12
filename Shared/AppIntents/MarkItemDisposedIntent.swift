//
//  MarkItemDisposedIntent.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import Foundation
import AppIntents

struct MarkItemDisposedIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Item as Disposed"
    static let description = IntentDescription("Moves an item to Disposed.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentAccessPolicy.authenticationPolicy }

    @Parameter(title: "Item")
    var item: ItemEntity

    @Parameter(title: "Date", description: "Today if not given")
    var date: Date?

    @Dependency private var viewModel: BelongingsViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$item) as disposed") {
            \.$date
        }
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<ItemEntity> & ProvidesDialog {
        let object: Item = try viewModel.object(.item, uuid: item.id)
        let name = object.name ?? ""
        guard object.disposed == nil else {
            return .result(value: try await ItemEntity.fetched(object), dialog: "\(name) is already disposed.")
        }

        try await requestConfirmation(actionName: .set, dialog: "Mark \(name) as disposed?")
        try await viewModel.setDisposed(object, on: Calendar(identifier: .iso8601).startOfDay(for: date ?? Date()))
        return .result(value: try await ItemEntity.fetched(object), dialog: "Moved \(name) to Disposed.")
    }
}
