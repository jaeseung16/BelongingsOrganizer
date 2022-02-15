//
//  BelongingsApp.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI
#if os(iOS)
import AppTrackingTransparency
import GoogleMobileAds
#endif

@main
struct BelongingsApp: App {
    let persistenceController = PersistenceController.shared
    let viewModel = BelongingsViewModel.shared
    
    #if os(iOS)
    init() {
        ATTrackingManager.requestTrackingAuthorization { status in
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(viewModel)
            #else
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(viewModel)
            #endif
        }
    }
}
