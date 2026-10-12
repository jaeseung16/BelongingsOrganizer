//
//  PerformanceSignposts.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/21/26.
//

import os

// Points of Interest intervals around Core Data work; shown in Instruments and
// measured by XCTOSSignpostMetric in BelogingsOrganizerUIPerformanceTests.
enum PerformanceSignposts {
    nonisolated static let subsystem = "com.resonance.jlee.Belongings"
    nonisolated static let signposter = OSSignposter(subsystem: subsystem, category: .pointsOfInterest)

    nonisolated static func measure<T>(_ name: StaticString, _ block: () throws -> T) rethrows -> T {
        let state = signposter.beginInterval(name)
        defer { signposter.endInterval(name, state) }
        return try block()
    }
}
