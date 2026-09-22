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
            app.staticTexts["Items"].firstMatch.tap()
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
        XCTAssertFalse(app.buttons["Refresh"].isEnabled)
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

    // The item list filters in the fetch request; searching must still match names case-insensitively
    @MainActor
    func testStressDataSearchItems() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "300"]
        app.launch()

        let itemList = app.descendants(matching: .any)["ItemList"]
        if !itemList.waitForExistence(timeout: 10) {
            app.staticTexts["Items"].firstMatch.tap()
            XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        }

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("item 29")

        // Items 29 and 290-299, minus any the seed disposed
        let firstCell = itemList.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(itemList.cells.count, 11)
        for index in 0..<itemList.cells.count {
            let name = itemList.cells.element(boundBy: index).staticTexts.element(boundBy: 0).label
            XCTAssertTrue(name.hasPrefix("Item 29"), "Unexpected match: \(name)")
        }
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
