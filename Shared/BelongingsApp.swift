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
        WindowGroup {
            #if os(macOS)
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .environment(\.managedObjectContext, appDelegate.persistence.container.viewContext)
                .environmentObject(appDelegate.viewModel)
            #else
            ContentView()
                .environment(\.managedObjectContext, appDelegate.persistence.container.viewContext)
                .environmentObject(appDelegate.viewModel)
            #endif
        }
    }
}
