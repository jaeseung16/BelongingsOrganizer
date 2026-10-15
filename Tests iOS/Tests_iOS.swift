//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Jae Seung Lee on 9/1/21.
//

import XCTest

nonisolated class Tests_iOS: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    // Edits and deletes against the DEBUG stress store (see StressTestData) with Core Data's
    // concurrency assertions on, so a main-queue violation crashes the test
    @MainActor
    func testStressDataEditAndDeleteItems() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "300", "-com.apple.CoreData.ConcurrencyDebug", "1"]
        app.launch()

        let itemList = app.descendants(matching: .any)["ItemList"]
        if !itemList.waitForExistence(timeout: 10) {
            app.tabBars.buttons["Items"].tap()
            XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        }

        // Rename the second item through the detail view; the save should move it to the top
        let editedCell = itemList.cells.element(boundBy: 1)
        XCTAssertTrue(editedCell.waitForExistence(timeout: 5))
        let originalName = editedCell.staticTexts.element(boundBy: 0).label
        editedCell.tap()

        let nameField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: originalName.count))
        nameField.typeText("Renamed Item\n")
        app.buttons["Save"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(itemList.staticTexts["Renamed Item"].waitForExistence(timeout: 5))
        XCTAssertFalse(itemList.staticTexts[originalName].exists)
        // A local save is not a remote change
        XCTAssertFalse(app.buttons["Refresh"].exists)
        // The list is sorted by last update, newest first
        XCTAssertEqual(itemList.cells.element(boundBy: 0).staticTexts.element(boundBy: 0).label, "Renamed Item")

        // Disposing moves an item out of the active list
        let disposedCell = itemList.cells.element(boundBy: 1)
        let disposedName = disposedCell.staticTexts.element(boundBy: 0).label
        disposedCell.swipeLeft()
        app.buttons["Dispose"].tap()
        let disposed = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: itemList.staticTexts[disposedName])
        wait(for: [disposed], timeout: 5)

        // Delete it with the swipe action
        let renamedCell = itemList.cells.containing(.staticText, identifier: "Renamed Item").firstMatch
        renamedCell.swipeLeft()
        app.buttons["Delete"].tap()

        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: itemList.staticTexts["Renamed Item"])
        wait(for: [gone], timeout: 5)
        XCTAssertTrue(itemList.cells.element(boundBy: 0).exists)
    }

    // The Search tab filters items in the fetch request; searching must still match names case-insensitively
    @MainActor
    func testStressDataSearchItems() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "300"]
        app.launch()

        let itemList = app.descendants(matching: .any)["ItemList"]
        XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        app.tabBars.buttons["Search"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("item 29")

        // Items 29 and 290-299, disposed ones included, under the "Items" header cell; no category,
        // brand, or seller matches. Rows scrolled off screen aren't cells
        let results = app.descendants(matching: .any)["SearchResults"]
        XCTAssertTrue(results.cells.staticTexts["Items"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(results.cells.count, 1)
        XCTAssertLessThanOrEqual(results.cells.count, 12)
        // A disposed item's cell has its "Disposed" badge too
        for index in 1..<results.cells.count {
            let cell = results.cells.element(boundBy: index)
            XCTAssertTrue(cell.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Item 29")).firstMatch.exists,
                          "Unexpected match: \(cell.staticTexts.element(boundBy: 0).label)")
        }
    }

    @MainActor
    private func waitForNameField(_ app: XCUIApplication, showing name: String) {
        let shown = expectation(for: NSPredicate(format: "value == %@", name), evaluatedWith: app.textFields.firstMatch)
        wait(for: [shown], timeout: 5)
    }

    // The first cell's name (rows show the name first)
    @MainActor
    private func openFirstRow(of list: XCUIElement) -> String {
        let cell = list.cells.element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        let name = cell.staticTexts.element(boundBy: 0).label
        cell.tap()
        return name
    }

    // Each tab keeps its own navigation: switching tabs leaves what another tab has open,
    // including Disposed behind More
    @MainActor
    func testTabsKeepTheirNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "50"]
        app.launch()
        let tabs = app.tabBars.firstMatch

        let itemList = app.descendants(matching: .any)["ItemList"]
        XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        let item = openFirstRow(of: itemList)
        waitForNameField(app, showing: item)

        tabs.buttons["Catalog"].tap()
        let picker = app.segmentedControls["CatalogPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.buttons["Brands"].tap()
        let brand = openFirstRow(of: app.descendants(matching: .any)["BrandList"])
        waitForNameField(app, showing: brand)

        tabs.buttons["More"].tap()
        app.cells.staticTexts["Disposed"].tap()
        let disposed = openFirstRow(of: app.descendants(matching: .any)["DisposedItemList"])
        waitForNameField(app, showing: disposed)

        tabs.buttons["Items"].tap()
        waitForNameField(app, showing: item)
        tabs.buttons["Catalog"].tap()
        waitForNameField(app, showing: brand)
        tabs.buttons["More"].tap()
        waitForNameField(app, showing: disposed)

        // Back in Catalog, the picker is still on Brands
        tabs.buttons["Catalog"].tap()
        app.navigationBars.buttons["Brands"].tap()
        XCTAssertTrue(picker.buttons["Brands"].waitForExistence(timeout: 5))
        XCTAssertTrue(picker.buttons["Brands"].isSelected)
        XCTAssertTrue(app.descendants(matching: .any)["BrandList"].exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
