//
//  BelogingsOrganizerUIPerformanceTests.swift
//  BelogingsOrganizerUIPerformanceTests
//
//  Created by Jae Seung Lee on 10/30/23.
//

import XCTest

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
        let app = XCUIApplication()
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
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: measureOptions) {
            itemList.cells.element(boundBy: 0).tap()
            itemList.cells.element(boundBy: 1).tap()
            stopMeasuring()
        }
    }

    // MARK: - Stress data (DEBUG builds seed an in-memory store; see StressTestData)
    private static let stressItemCount = "2000"
    private static let subsystem = "com.resonance.jlee.Belongings"

    private func signpostMetric(_ name: String) -> XCTOSSignpostMetric {
        XCTOSSignpostMetric(subsystem: Self.subsystem, category: "PointsOfInterest", name: name)
    }

    private func stressApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-StressTestItemCount", Self.stressItemCount]
        return app
    }

    private func showItemList(in app: XCUIApplication) -> XCUIElement {
        let itemList = app.descendants(matching: .any)["ItemList"]
        if !itemList.waitForExistence(timeout: 10) {
            app.staticTexts["Items"].firstMatch.tap()
            XCTAssertTrue(itemList.waitForExistence(timeout: 10))
        }
        return itemList
    }

    // Launch with seeded data: time spent fetching and filtering, and resident memory
    func testStressLaunchAndShowItems() throws {
        let app = stressApp()
        let metrics: [XCTMetric] = [signpostMetric("fetchEntities"),
                                    signpostMetric("fetchEntitiesToFilterItems"),
                                    signpostMetric("filterItems"),
                                    XCTMemoryMetric(application: app)]
        measure(metrics: metrics) {
            // launch() relaunches the app, so every iteration starts cold
            app.launch()
            _ = showItemList(in: app)
        }
    }

    // Scrolling the seeded item list: hitches, list filtering, and memory growth
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

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
