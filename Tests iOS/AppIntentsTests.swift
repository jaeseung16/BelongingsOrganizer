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

    // With the app lock on, behind the lock screen. The simulator itself is unlocked, so intents
    // that require authentication still run.
    @MainActor
    private func launchLocked() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "\(Self.itemCount)", "-requireAuthentication", "YES"]
        app.launch()
        return app
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

    // Whether each item comes with its thumbnail (every seeded item has a photo)
    private func thumbnails(_ items: [AnyAppEntity]) async throws -> [Bool] {
        try await definitions.intents["ItemThumbnailsIntent"].makeIntent(items: items).run().value
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
        let withThumbnails = try await thumbnails(suggested)
        XCTAssertEqual(withThumbnails.count, suggested.count)
        XCTAssertFalse(withThumbnails.contains(false), "Every item has a photo, so every entity has a thumbnail")

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

    // MARK: - App lock

    // The app lock asks intents for an unlocked device, which the simulator is, so they still
    // read and change belongings. Entities leave out photos, and an item an intent opens stays
    // behind the lock screen.
    @MainActor
    func testIntentsFollowLockPolicy() async throws {
        let app = launchLocked()
        let lockScreen = app.descendants(matching: .any)["LockScreen"]
        XCTAssertTrue(lockScreen.waitForExistence(timeout: 10))

        let suggested = try await definitions.entities["ItemEntity"].suggestedEntities()
        XCTAssertFalse(suggested.isEmpty)
        let withThumbnails = try await thumbnails(suggested)
        XCTAssertEqual(withThumbnails.count, suggested.count)
        XCTAssertFalse(withThumbnails.contains(true), "No photos while locked")

        let currentBefore = try await count("current")
        let added: AnyAppEntity = try await definitions.intents["AddItemIntent"].makeIntent(name: "Locked Item").run().value
        let currentAfter = try await count("current")
        XCTAssertEqual(currentAfter, currentBefore + 1)
        let disposed: AnyAppEntity = try await definitions.intents["MarkItemDisposedIntent"].makeIntent(item: added).run().value
        XCTAssertTrue(isDisposed(disposed))

        // The item opens behind the lock screen, which stays on top
        try await definitions.intents["OpenItemIntent"].makeIntent(target: suggested[0]).run()
        await waitForNameField(app, showing: try suggested[0].name)
        XCTAssertTrue(lockScreen.exists)
        XCTAssertTrue(app.buttons["Unlock"].isHittable, "The lock screen still covers the window")
    }

    // MARK: - Cold launch

    // An intent that launches the app doesn't pass it this test's launch arguments, so the
    // stress-store count is kept in the app's defaults until the test ends
    @MainActor
    private func keepStressStoreForIntentLaunches() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "\(Self.itemCount)", "-StressTestKeepsItemCount", "YES"]
        app.launch()
        addTeardownBlock { @MainActor in
            let app = XCUIApplication()
            app.launchArguments += ["-StressTestItemCount", "\(Self.itemCount)", "-StressTestKeepsItemCount", "NO"]
            app.launch()
            app.terminate()
        }
        app.terminate()
        return app
    }

    // The app isn't running: the search launches it and shows the results
    @MainActor
    func testSearchLaunchesApp() async throws {
        let app = keepStressStoreForIntentLaunches()
        XCTAssertEqual(app.state, .notRunning)

        try await definitions.intents["SearchItemsIntent"].makeIntent(criteria: StringSearchCriteria(term: "Item 3")).run()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let searched = expectation(for: NSPredicate(format: "value == %@", "Item 3"), evaluatedWith: app.searchFields.firstMatch)
        await fulfillment(of: [searched], timeout: 10)
        let itemList = app.descendants(matching: .any)["ItemList"]
        let firstName = itemList.cells.element(boundBy: 0).staticTexts.element(boundBy: 0)
        XCTAssertTrue(firstName.waitForExistence(timeout: 5))
        for index in 0..<itemList.cells.count {
            let name = itemList.cells.element(boundBy: index).staticTexts.element(boundBy: 0).label
            XCTAssertTrue(name.hasPrefix("Item 3"), "Unexpected match: \(name)")
        }
    }

    // The query starts the app without a window; opening the item then brings up the window,
    // which lands on the item, pushed once
    @MainActor
    func testOpenItemLaunchesWindow() async throws {
        let app = keepStressStoreForIntentLaunches()
        let suggested = try await definitions.entities["ItemEntity"].suggestedEntities()
        let item = try XCTUnwrap(suggested.first, "No stress store items")
        XCTAssertNotEqual(app.state, .runningForeground)

        try await definitions.intents["OpenItemIntent"].makeIntent(target: item).run()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        await waitForNameField(app, showing: try item.name)
        app.navigationBars.buttons["BackButton"].tap()
        // Known bug: when the window is new, the 500 ms handoff delay isn't always enough, and
        // the item is pushed twice in about half the runs
        XCTExpectFailure("A window opened by the intent sometimes pushes the item twice", strict: false)
        XCTAssertTrue(app.descendants(matching: .any)["ItemList"].waitForExistence(timeout: 5), "One Back returns to the list")
    }

    // MARK: - Onscreen awareness

    // What the app tells Siri is on screen, once the view settles
    private func annotations(_ type: String, until condition: ([ViewAnnotation]) -> Bool) async throws -> [ViewAnnotation] {
        let entities = definitions.entities[type]
        let deadline = Date.now.addingTimeInterval(10)
        var annotations = try await entities.viewAnnotations()
        while !condition(annotations) && Date.now < deadline {
            try await Task.sleep(for: .milliseconds(500))
            annotations = try await entities.viewAnnotations()
        }
        return annotations
    }

    private func annotates(_ name: String) -> ([ViewAnnotation]) -> Bool {
        { annotations in annotations.contains { (try? $0.entity.name as String) == name } }
    }

    @MainActor
    func testItemListAndDetailAreAnnotated() async throws {
        let (app, itemList) = launch()
        let items = Set(try await allItems().map(\.identifier.instanceIdentifier))

        let listed = try await annotations("ItemEntity") { !$0.isEmpty }
        XCTAssertFalse(listed.isEmpty, "The list's rows are annotated")
        for annotation in listed {
            let id = annotation.entity.identifier.instanceIdentifier
            XCTAssertTrue(items.contains(id), "Not an item in the store: \(id)")
        }

        let cell = itemList.cells.element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        let name = cell.staticTexts.element(boundBy: 0).label
        cell.tap()
        await waitForNameField(app, showing: name)
        let shown = try await annotations("ItemEntity", until: annotates(name))
        XCTAssertTrue(annotates(name)(shown), "The open item is annotated")
    }

    @MainActor
    func testCategoryBrandSellerDetailsAreAnnotated() async throws {
        let (app, _) = launch()
        for (type, intent) in [("CategoryEntity", "OpenCategoryIntent"), ("BrandEntity", "OpenBrandIntent"), ("SellerEntity", "OpenSellerIntent")] {
            let entity = try await definitions.entities[type].suggestedEntities()[0]
            let name: String = try entity.name
            try await definitions.intents[intent].makeIntent(target: entity).run()
            await waitForNameField(app, showing: name)
            let shown = try await annotations(type) { $0.contains { $0.entity == entity } }
            XCTAssertTrue(shown.contains { $0.entity == entity }, "\(name) isn't annotated")
        }
    }

    // The lock screen covers the window, so Siri isn't told about the belongings behind it,
    // even an item an intent opened there
    @MainActor
    func testNothingIsAnnotatedWhileLocked() async throws {
        _ = launchLocked()
        let item = try await definitions.entities["ItemEntity"].suggestedEntities()[0]
        try await definitions.intents["OpenItemIntent"].makeIntent(target: item).run()
        try await Task.sleep(for: .seconds(3))

        for type in ["ItemEntity", "CategoryEntity", "BrandEntity", "SellerEntity"] {
            let annotations = try await definitions.entities[type].viewAnnotations()
            XCTAssertTrue(annotations.isEmpty, "\(annotations.count) \(type) annotations while locked")
        }
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

        _ = launchLocked()
        let indexed = try await indexedItems { $0.isEmpty }
        XCTAssertTrue(indexed.isEmpty, "\(indexed.count) items are still indexed while locked")
    }

    // MARK: - Visual Intelligence

    // The simulator SDK has no VisualIntelligence, so these go through DEBUG intents that run the
    // same matching and search from plain labels (no pixel buffer, so no MobileNet pass)
    private func visualSearch(_ labels: [String]) async throws -> [String] {
        try await definitions.intents["VisualSearchItemNamesIntent"].makeIntent(labels: labels).run().value
    }

    @MainActor
    func testVisualSearchMatchesLabels() async throws {
        _ = launch()

        // Case-insensitive, and a plural label finds the singular
        let lowercased = try await visualSearch(["item 12"])
        XCTAssertEqual(lowercased, ["Item 12"])
        let plural = try await visualSearch(["Item 12s"])
        XCTAssertEqual(plural, ["Item 12"])

        // Item 4 and Items 40–49 match: capped at 10
        let capped = try await visualSearch(["Item 4"])
        XCTAssertEqual(capped.count, 10)
        XCTAssertTrue(capped.allSatisfy { $0.hasPrefix("Item 4") }, "Unexpected match in \(capped)")

        let unmatched = try await visualSearch(["Headphones"])
        XCTAssertTrue(unmatched.isEmpty)
    }

    @MainActor
    func testVisualSearchMatchesCategoryAndBrand() async throws {
        _ = launch()
        let item = try await definitions.entities["ItemEntity"].suggestedEntities()[0]
        let name: String = try item.name
        let brand: AnyAppEntity = try item.brand
        let brandName: String = try brand.name

        // "Brand 2" also matches Brands 20–29, so the item may be past the cap
        let byBrand = try await visualSearch([brandName])
        XCTAssertFalse(byBrand.isEmpty)
        if byBrand.count < 10 {
            XCTAssertTrue(byBrand.contains(name), "\(name) wasn't found by \(brandName)")
        }

        // Name matches rank above category matches, even the least recent item, which recency
        // alone would push past the cap ("Category 1" also matches Categories 10–19)
        // Only a name no other name contains ("Item 7", not "Item 1"), so it's the one name match
        let items = try await allItems()
        let names = try items.map { try $0.name as String }
        let unique = try items.filter { item in
            let name: String = try item.name
            return names.filter { $0.contains(name) }.count == 1
        }
        let oldest = try XCTUnwrap(unique.min { (try? $0.obtained as Date) ?? .distantFuture < (try? $1.obtained as Date) ?? .distantFuture })
        let oldestName: String = try oldest.name
        let ranked = try await visualSearch(["Category 1", oldestName])
        XCTAssertEqual(ranked.count, 10)
        XCTAssertEqual(ranked.first, oldestName, "Name match isn't first: \(ranked)")
    }

    @MainActor
    func testVisualSearchIsEmptyWhileLocked() async throws {
        let (app, _) = launch()
        let unlocked = try await visualSearch(["Item 1"])
        XCTAssertFalse(unlocked.isEmpty)
        app.terminate()

        _ = launchLocked()
        let locked = try await visualSearch(["Item 1"])
        XCTAssertTrue(locked.isEmpty, "\(locked.count) results while locked")
    }

    // "More results" searches the item list for the first label some item's name contains
    @MainActor
    func testVisualSearchMoreResultsSearchesItemList() async throws {
        let (app, itemList) = launch()

        try await definitions.intents["ShowVisualSearchResultsForLabelsIntent"].makeIntent(labels: ["Headphones", "Item 3"]).run()
        let searched = expectation(for: NSPredicate(format: "value == %@", "Item 3"), evaluatedWith: app.searchFields.firstMatch)
        await fulfillment(of: [searched], timeout: 5)
        let firstName = itemList.cells.element(boundBy: 0).staticTexts.element(boundBy: 0)
        XCTAssertTrue(firstName.waitForExistence(timeout: 5))
        for index in 0..<itemList.cells.count {
            let name = itemList.cells.element(boundBy: index).staticTexts.element(boundBy: 0).label
            XCTAssertTrue(name.hasPrefix("Item 3"), "Unexpected match: \(name)")
        }
    }
}
