//
//  BelongingsApp.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI
import Persistence

@main
struct BelongingsApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #else
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    
    var body: some Scene {
        let persistence = Persistence(name: BelongsOrganizerConstants.appName.rawValue, identifier: BelongsOrganizerConstants.iCloudIdentifier.rawValue)
        let viewModel = BelongingsViewModel(persistence: persistence)
        
        WindowGroup {
            #if os(macOS)
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(viewModel)
            #else
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(viewModel)
            #endif
        }
    }
}
