//
//  BelogingsOrganizerUIPerformanceTests.swift
//  BelogingsOrganizerUIPerformanceTests
//
//  Created by Jae Seung Lee on 10/30/23.
//

import XCTest
import AppIntentsTesting

nonisolated final class BelogingsOrganizerUIPerformanceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSelectItem() throws {
        // UI tests must launch the application that they test.
        // Seeded data: the real store is empty on a fresh simulator, leaving no cells to tap
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", "50"]
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let itemList = app.descendants(matching: .any)["ItemList"]
        if !itemList.waitForExistence(timeout: 2) {
            // The NavigationSplitView sidebar is showing; select the Items section.
            app.staticTexts["Items"].firstMatch.tap()
            XCTAssertTrue(itemList.waitForExistence(timeout: 5))
        }
            
        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]
        
        // On a compact width (iPhone) selecting an item pushes its detail over the list
        func returnToList() {
            let backButton = app.navigationBars.buttons["BackButton"]
            if backButton.waitForExistence(timeout: 2) {
                backButton.tap()
                XCTAssertTrue(itemList.waitForExistence(timeout: 5))
            }
        }

        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: measureOptions) {
            itemList.cells.element(boundBy: 0).tap()
            returnToList()
            itemList.cells.element(boundBy: 1).tap()
            stopMeasuring()
            returnToList()
        }
    }

    // MARK: - Stress data (DEBUG builds seed an in-memory store; see StressTestData)
    private static let stressItemCount = "2000"
    private static let subsystem = "com.resonance.jlee.Belongings"

    @MainActor
    private func signpostMetric(_ name: String) -> XCTOSSignpostMetric {
        XCTOSSignpostMetric(subsystem: Self.subsystem, category: "PointsOfInterest", name: name)
    }

    @MainActor
    private func stressApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", Self.stressItemCount]
        return app
    }

    @MainActor
    private func showItemList(in app: XCUIApplication) -> XCUIElement {
        let itemList = app.descendants(matching: .any)["ItemList"]
        if !itemList.waitForExistence(timeout: 10) {
            app.staticTexts["Items"].firstMatch.tap()
            XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        }
        return itemList
    }

    // Launch with seeded data: time spent fetching and filtering, and resident memory
    @MainActor
    func testStressLaunchAndShowItems() throws {
        let app = stressApp()
        let metrics: [XCTMetric] = [signpostMetric("fetchEntities"),
                                    signpostMetric("filterItems"),
                                    XCTMemoryMetric(application: app)]
        measure(metrics: metrics) {
            // launch() relaunches the app, so every iteration starts cold
            app.launch()
            _ = showItemList(in: app)
        }
    }

    // Scrolling the seeded item list: hitches, list filtering, and memory growth
    @MainActor
    func testStressScrollItemList() throws {
        let app = stressApp()
        app.launch()
        let itemList = showItemList(in: app)

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]
        let metrics: [XCTMetric] = [XCTOSSignpostMetric.scrollingAndDecelerationMetric,
                                    signpostMetric("filterItems"),
                                    XCTMemoryMetric(application: app)]
        measure(metrics: metrics, options: measureOptions) {
            for _ in 0..<5 {
                itemList.swipeUp(velocity: .fast)
            }
            stopMeasuring()
            for _ in 0..<5 {
                itemList.swipeDown(velocity: .fast)
            }
        }
    }

    // The full Spotlight index of the seeded store, which is rebuilt on every stress launch.
    // Each iteration waits until Spotlight holds exactly the new launch's items, read through a
    // DEBUG intent: the previous launch's entries (other uuids) are there until the rebuild
    // removes them.
    @MainActor
    func testStressInitialSpotlightIndexing() throws {
        let app = stressApp()
        let itemCount = Int(Self.stressItemCount)!
        let definitions = IntentDefinitions(bundleIdentifier: Self.subsystem)
        let metrics: [XCTMetric] = [signpostMetric("indexAllItems"), XCTCPUMetric(application: app)]
        measure(metrics: metrics) {
            app.launch()
            let indexed = expectation(description: "Every item is indexed")
            Task.detached {
                let deadline = Date.now.addingTimeInterval(180)
                let launched = try? await definitions.entities["ItemEntity"].suggestedEntities()
                let sample = Set((launched ?? []).map(\.identifier.instanceIdentifier))
                while Date.now < deadline {
                    let identifiers: [String] = (try? await definitions.intents["IndexedItemIdentifiersIntent"].makeIntent().run().value) ?? []
                    if !sample.isEmpty && identifiers.count == itemCount && sample.isSubset(of: identifiers) {
                        indexed.fulfill()
                        return
                    }
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            wait(for: [indexed], timeout: 180)
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
