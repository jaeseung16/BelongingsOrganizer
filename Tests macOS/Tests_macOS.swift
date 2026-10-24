//
//  Tests_macOS.swift
//  Tests macOS
//
//  Created by Jae Seung Lee on 9/1/21.
//

import XCTest

nonisolated class Tests_macOS: XCTestCase {

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

    @MainActor
    private func waitForNameField(_ app: XCUIApplication, showing name: String) {
        let shown = expectation(for: NSPredicate(format: "value == %@", name), evaluatedWith: app.textFields.firstMatch)
        wait(for: [shown], timeout: 5)
    }

    // Selects the list's first row and returns its name (a row's label starts with the name)
    @MainActor
    private func selectFirstRow(of list: XCUIElement) -> String {
        let row = list.cells.element(boundBy: 0)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let label = row.buttons.firstMatch.label
        row.click()
        return label.components(separatedBy: ", ")[0]
    }

    // The toolbar tabs; the selected one's value is 1
    @MainActor
    private func select(_ tab: String, in app: XCUIApplication) {
        let tabs = app.toolbars.tabGroups.firstMatch.tabs
        tabs[tab].click()
        let selected = expectation(for: NSPredicate(format: "value == 1"), evaluatedWith: tabs[tab])
        wait(for: [selected], timeout: 5)
    }

    // Each tab keeps its own list selection and detail
    @MainActor
    func testTabsKeepTheirSelection() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "50"]
        app.launch()

        let itemList = app.descendants(matching: .any)["ItemList"]
        XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        XCTAssertEqual(app.toolbars.tabGroups.firstMatch.tabs["Items"].value as? Int, 1)
        XCTAssertTrue(app.toolbars.buttons["Add"].exists)
        let item = selectFirstRow(of: itemList)
        waitForNameField(app, showing: item)

        select("Catalog", in: app)
        let picker = app.descendants(matching: .any)["CatalogPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.radioButtons["Brands"].click()
        let brand = selectFirstRow(of: app.descendants(matching: .any)["BrandList"])
        waitForNameField(app, showing: brand)

        select("Disposed", in: app)
        // Disposed keeps Filter and Sort but has no Add
        XCTAssertTrue(app.toolbars.buttons["Filter"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.toolbars.buttons["Add"].exists)
        let disposed = selectFirstRow(of: app.descendants(matching: .any)["DisposedItemList"])
        waitForNameField(app, showing: disposed)

        select("Items", in: app)
        waitForNameField(app, showing: item)
        select("Catalog", in: app)
        waitForNameField(app, showing: brand)
        XCTAssertTrue(app.descendants(matching: .any)["BrandList"].exists, "The picker is still on Brands")
        select("Disposed", in: app)
        waitForNameField(app, showing: disposed)
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
