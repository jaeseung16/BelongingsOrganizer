//
//  AppIntentsTests.swift
//  Tests iOS
//
//  Created by Jae Seung Lee on 9/29/26.
//

import XCTest
import AppIntents
import AppIntentsTesting

// Runs the app's intents the way Siri and Shortcuts do, against the DEBUG stress store
// (see StressTestData), which is reseeded with new uuids on every launch
nonisolated class AppIntentsTests: XCTestCase {
    private static let itemCount = 50

    private let definitions = IntentDefinitions(bundleIdentifier: "com.resonance.jlee.Belongings")

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> (app: XCUIApplication, itemList: XCUIElement) {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "\(Self.itemCount)"]
        app.launch()

        let itemList = app.descendants(matching: .any)["ItemList"]
        if !itemList.waitForExistence(timeout: 10) {
            app.staticTexts["Items"].firstMatch.tap()
            XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        }
        return (app, itemList)
    }

    @MainActor
    private func waitForNameField(_ app: XCUIApplication, showing name: String) async {
        let shown = expectation(for: NSPredicate(format: "value == %@", name), evaluatedWith: app.textFields.firstMatch)
        await fulfillment(of: [shown], timeout: 5)
    }

    private func isDisposed(_ entity: AnyAppEntity) -> Bool {
        let disposed: (any IntentValueExpressing)? = entity.disposed
        return disposed != nil
    }

    // Every item, from name searches ("Item <n>" contains a digit)
    private func allItems() async throws -> [AnyAppEntity] {
        var items = [AnyAppEntity]()
        for digit in 0...9 {
            for item in try await definitions.entities["ItemEntity"].entities(matching: "\(digit)") where !items.contains(item) {
                items.append(item)
            }
        }
        return items
    }

    private func count(_ disposition: String, category: AnyAppEntity? = nil) async throws -> Int {
        let intent = definitions.intents["CountItemsIntent"]
            .makeIntent(disposition: AnyAppEnum(typeIdentifier: "ItemDispositionAppEnum", rawValue: disposition), category: category)
        return try await intent.run().value
    }

    // MARK: - Queries

    @MainActor
    func testItemQueries() async throws {
        _ = launch()
        let items = definitions.entities["ItemEntity"]

        let suggested = try await items.suggestedEntities()
        XCTAssertFalse(suggested.isEmpty)
        XCTAssertLessThanOrEqual(suggested.count, 20)
        XCTAssertFalse(suggested.contains(where: isDisposed), "Suggestions are owned items only")

        let matching = try await items.entities(matching: "item 1")
        XCTAssertFalse(matching.isEmpty)
        for item in matching {
            let name: String = try item.name
            XCTAssertTrue(name.hasPrefix("Item 1"), "Unexpected match: \(name)")
        }

        let id = try XCTUnwrap(UUID(uuidString: matching[0].identifier.instanceIdentifier))
        let byID = try await items.entities(identifiers: [id])
        XCTAssertEqual(byID, [matching[0]])

        for type in ["CategoryEntity", "BrandEntity", "SellerEntity"] {
            let suggested = try await definitions.entities[type].suggestedEntities()
            XCTAssertFalse(suggested.isEmpty, "No \(type) suggestions")
        }
    }

    // MARK: - Open and search

    @MainActor
    func testOpenIntents() async throws {
        let (app, _) = launch()
        let open = definitions.intents["OpenItemIntent"]

        let owned = try await definitions.entities["ItemEntity"].suggestedEntities()[0]
        try await open.makeIntent(target: owned).run()
        await waitForNameField(app, showing: try owned.name)
        XCTAssertTrue(app.navigationBars.buttons["Items"].exists)

        let items = try await allItems()
        let disposed = try XCTUnwrap(items.first(where: isDisposed), "The seed disposes about one in ten")
        try await open.makeIntent(target: disposed).run()
        await waitForNameField(app, showing: try disposed.name)
        XCTAssertTrue(app.navigationBars.buttons["Disposed"].exists)

        for (type, intent, section) in [("CategoryEntity", "OpenCategoryIntent", "Categories"),
                                        ("BrandEntity", "OpenBrandIntent", "Brands"),
                                        ("SellerEntity", "OpenSellerIntent", "Sellers")] {
            let entity = try await definitions.entities[type].suggestedEntities()[0]
            try await definitions.intents[intent].makeIntent(target: entity).run()
            await waitForNameField(app, showing: try entity.name)
            XCTAssertTrue(app.navigationBars.buttons[section].exists, "\(intent) didn't open \(section)")
        }
    }

    @MainActor
    func testSearchClosesNonMatchingItem() async throws {
        let (app, itemList) = launch()

        let item = try await definitions.entities["ItemEntity"].suggestedEntities()[0]
        let name: String = try item.name
        try await definitions.intents["OpenItemIntent"].makeIntent(target: item).run()
        await waitForNameField(app, showing: name)

        let term = name.hasPrefix("Item 4") ? "Item 3" : "Item 4"
        try await definitions.intents["SearchItemsIntent"].makeIntent(criteria: StringSearchCriteria(term: term)).run()
        let firstName = itemList.cells.element(boundBy: 0).staticTexts.element(boundBy: 0)
        XCTAssertTrue(firstName.waitForExistence(timeout: 5))
        for index in 0..<itemList.cells.count {
            let name = itemList.cells.element(boundBy: index).staticTexts.element(boundBy: 0).label
            XCTAssertTrue(name.hasPrefix(term), "Unexpected match: \(name)")
        }
        XCTAssertEqual(app.searchFields.firstMatch.value as? String, term)
    }

    // Also checks that the detail is pushed once: one Back returns to the list
    @MainActor
    func testOpenItemClearsSearchHidingIt() async throws {
        let (app, itemList) = launch()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("no such item")
        XCTAssertFalse(itemList.cells.firstMatch.waitForExistence(timeout: 2))

        let item = try await definitions.entities["ItemEntity"].suggestedEntities()[0]
        try await definitions.intents["OpenItemIntent"].makeIntent(target: item).run()
        await waitForNameField(app, showing: try item.name)

        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(itemList.cells.firstMatch.waitForExistence(timeout: 5), "Back should return to the list, with the search cleared")
        XCTAssertEqual(app.searchFields.firstMatch.placeholderValue, app.searchFields.firstMatch.value as? String)
    }

    // MARK: - Add, dispose, count

    @MainActor
    func testCountItemsIntent() async throws {
        _ = launch()
        let items = try await allItems()
        let disposedCount = items.filter(isDisposed).count

        let current = try await count("current")
        let disposed = try await count("disposed")
        XCTAssertEqual(current + disposed, Self.itemCount)
        XCTAssertEqual(disposed, disposedCount)

        // Every category's items fall within the totals
        let category = try await definitions.entities["CategoryEntity"].suggestedEntities()[0]
        let inCategory = try await count("current", category: category)
        XCTAssertGreaterThan(inCategory, 0)
        XCTAssertLessThanOrEqual(inCategory, current)
    }

    @MainActor
    func testAddItemIntent() async throws {
        let (app, itemList) = launch()
        let category = try await definitions.entities["CategoryEntity"].suggestedEntities()[0]
        let brand = try await definitions.entities["BrandEntity"].suggestedEntities()[0]
        let currentBefore = try await count("current")
        let inCategoryBefore = try await count("current", category: category)

        let intent = definitions.intents["AddItemIntent"]
            .makeIntent(name: "  Siri Item  ", categories: [category], brand: brand, buyPrice: 12.5, buyCurrency: "eur", quantity: 2)
        let added: AnyAppEntity = try await intent.run().value

        XCTAssertEqual(try added.name as String, "Siri Item")
        XCTAssertEqual(try added.quantity as Int, 2)
        XCTAssertEqual(try added.buyPrice as Double, 12.5)
        XCTAssertEqual(try added.buyCurrency as String, "EUR")
        XCTAssertEqual(try added.obtained as Date, Calendar(identifier: .iso8601).startOfDay(for: Date()))
        XCTAssertFalse(isDisposed(added))

        let currentAfter = try await count("current")
        let inCategoryAfter = try await count("current", category: category)
        XCTAssertEqual(currentAfter, currentBefore + 1)
        XCTAssertEqual(inCategoryAfter, inCategoryBefore + 1)

        // The newest item tops the list, which is sorted by last update
        let firstName = itemList.cells.element(boundBy: 0).staticTexts.element(boundBy: 0)
        let listed = expectation(for: NSPredicate(format: "label == %@", "Siri Item"), evaluatedWith: firstName)
        await fulfillment(of: [listed], timeout: 5)
        _ = app
    }

    @MainActor
    func testAddItemIntentRejectsUnknownCurrency() async throws {
        _ = launch()
        let currentBefore = try await count("current")

        let intent = definitions.intents["AddItemIntent"].makeIntent(name: "Bad Currency", buyCurrency: "XYZ1")
        do {
            try await intent.run()
            XCTFail("An unknown currency should be rejected")
        } catch {
            // Expected: the intent asks for a currency
        }
        let currentAfter = try await count("current")
        XCTAssertEqual(currentAfter, currentBefore)
    }

    @MainActor
    func testMarkItemDisposedIntent() async throws {
        let (_, itemList) = launch()
        let item = try await definitions.entities["ItemEntity"].suggestedEntities()[0]
        let name: String = try item.name
        let currentBefore = try await count("current")
        let disposedBefore = try await count("disposed")
        XCTAssertTrue(itemList.staticTexts[name].waitForExistence(timeout: 5))

        let dispose = definitions.intents["MarkItemDisposedIntent"]
        let disposed: AnyAppEntity = try await dispose.makeIntent(item: item).run().value
        XCTAssertTrue(isDisposed(disposed))
        XCTAssertEqual(try disposed.disposed as Date, Calendar(identifier: .iso8601).startOfDay(for: Date()))

        let currentAfter = try await count("current")
        let disposedAfter = try await count("disposed")
        XCTAssertEqual(currentAfter, currentBefore - 1)
        XCTAssertEqual(disposedAfter, disposedBefore + 1)

        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: itemList.staticTexts[name])
        await fulfillment(of: [gone], timeout: 5)

        // Disposing again changes nothing
        let again: AnyAppEntity = try await dispose.makeIntent(item: item).run().value
        XCTAssertEqual(try again.disposed as Date, try disposed.disposed as Date)
        let disposedAgain = try await count("disposed")
        XCTAssertEqual(disposedAgain, disposedAfter)
    }

    @MainActor
    func testGetItemDetailsIntent() async throws {
        _ = launch()
        let item = try await definitions.entities["ItemEntity"].suggestedEntities()[0]
        let details: AnyAppEntity = try await definitions.intents["GetItemDetailsIntent"].makeIntent(item: item).run().value
        XCTAssertEqual(details.identifier, item.identifier)
        XCTAssertEqual(try details.name as String, try item.name as String)
        let categories: (any IntentValueExpressing)? = details.categories
        XCTAssertNotNil(categories)
    }

    // MARK: - Spotlight

    // The uuids Spotlight holds, including items no longer in the store (spotlightQuery drops those).
    // Indexing runs in the background, so this waits for the index to catch up.
    private func indexedItems(until condition: (Set<String>) -> Bool) async throws -> Set<String> {
        let intent = definitions.intents["IndexedItemIdentifiersIntent"].makeIntent()
        let deadline = Date.now.addingTimeInterval(30)
        var identifiers = Set<String>(try await intent.run().value as [String])
        while !condition(identifiers) && Date.now < deadline {
            try await Task.sleep(for: .milliseconds(500))
            identifiers = Set(try await intent.run().value as [String])
        }
        return identifiers
    }

    private func spotlightResults(_ query: String, until condition: ([AnyAppEntity]) -> Bool) async throws -> [AnyAppEntity] {
        let items = definitions.entities["ItemEntity"]
        let deadline = Date.now.addingTimeInterval(30)
        var results = try await items.spotlightQuery(query)
        while !condition(results) && Date.now < deadline {
            try await Task.sleep(for: .milliseconds(500))
            results = try await items.spotlightQuery(query)
        }
        return results
    }

    // A launch replaces the stress store, so the index holds exactly its items: the previous
    // launch's are removed
    @MainActor
    func testSpotlightIndexesItems() async throws {
        _ = launch()
        let items = Set(try await allItems().map(\.identifier.instanceIdentifier))
        XCTAssertEqual(items.count, Self.itemCount)
        let indexed = try await indexedItems { $0 == items }
        XCTAssertEqual(indexed, items, "Every item, owned or disposed, is indexed, and nothing else")
    }

    @MainActor
    func testSpotlightFollowsAddAndDelete() async throws {
        let (app, itemList) = launch()
        _ = try await indexedItems { $0.count == Self.itemCount }

        let intent = definitions.intents["AddItemIntent"].makeIntent(name: "Brass Lamp", note: "Reading light by the window")
        let added: AnyAppEntity = try await intent.run().value
        let id = added.identifier.instanceIdentifier
        let afterAdd = try await indexedItems { $0.contains(id) }
        XCTAssertTrue(afterAdd.contains(id))
        let byName = try await spotlightResults("Lamp") { $0.contains(added) }
        XCTAssertTrue(byName.contains(added), "The added item is found by name")
        let byNote = try await spotlightResults("window") { $0.contains(added) }
        XCTAssertTrue(byNote.contains(added), "The added item is found by its note")

        // The newest item tops the list
        let cell = itemList.cells.element(boundBy: 0)
        let listed = expectation(for: NSPredicate(format: "label == %@", "Brass Lamp"), evaluatedWith: cell.staticTexts.element(boundBy: 0))
        await fulfillment(of: [listed], timeout: 5)
        cell.swipeLeft()
        app.buttons["Delete"].tap()

        let afterDelete = try await indexedItems { !$0.contains(id) }
        XCTAssertFalse(afterDelete.contains(id), "A deleted item leaves the index")
        XCTAssertEqual(afterDelete.count, Self.itemCount)
    }

    // Nothing is indexed while the app lock is on
    @MainActor
    func testSpotlightIsEmptyWhileLocked() async throws {
        let (app, _) = launch()
        _ = try await indexedItems { $0.count == Self.itemCount }
        app.terminate()

        let lockedApp = XCUIApplication()
        lockedApp.launchArguments += ["-StressTestItemCount", "\(Self.itemCount)", "-requireAuthentication", "YES"]
        lockedApp.launch()
        let indexed = try await indexedItems { $0.isEmpty }
        XCTAssertTrue(indexed.isEmpty, "\(indexed.count) items are still indexed while locked")
    }
}
