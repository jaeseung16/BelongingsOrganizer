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

    @StateObject private var authService = AuthenticationService()

    @AppStorage(BelongsOrganizerConstants.requireAuthentication.rawValue)
    private var requireAuthentication = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                #if os(macOS)
                ContentView()
                    .frame(minWidth: 900, minHeight: 600)
                    .environmentObject(appDelegate.viewModel)
                #else
                ContentView()
                    .environmentObject(appDelegate.viewModel)
                #endif

                if requireAuthentication && !authService.isUnlocked {
                    LockScreenView()
                        .transition(.opacity)
                }
            }
            .environmentObject(authService)
            .onChange(of: scenePhase) { _, newPhase in
                guard requireAuthentication else {
                    return
                }
                #if os(iOS)
                if newPhase == .background {
                    authService.lock()
                }
                #endif
                if newPhase == .active && !authService.isUnlocked {
                    Task {
                        await authService.authenticate()
                    }
                }
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(authService)
                .formStyle(.grouped)
                .frame(width: 480)
        }
        #endif
    }
}
