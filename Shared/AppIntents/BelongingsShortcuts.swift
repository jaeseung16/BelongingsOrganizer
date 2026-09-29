//
//  BelongingsShortcuts.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import Foundation
import AppIntents

struct BelongingsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SearchItemsIntent(),
                    phrases: ["Search \(.applicationName)",
                              "Find an item in \(.applicationName)"],
                    shortTitle: "Search Items",
                    systemImageName: "magnifyingglass")
        AppShortcut(intent: OpenItemIntent(),
                    phrases: ["Open \(\.$target) in \(.applicationName)"],
                    shortTitle: "Open Item",
                    systemImageName: "shippingbox")
    }

    static let shortcutTileColor = ShortcutTileColor.orange
}
