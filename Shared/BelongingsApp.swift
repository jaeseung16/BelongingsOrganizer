//
//  BelongingsApp.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI

@main
struct BelongingsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
