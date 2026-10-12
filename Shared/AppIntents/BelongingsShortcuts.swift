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
        AppShortcut(intent: AddItemIntent(),
                    phrases: ["Add an item to \(.applicationName)"],
                    shortTitle: "Add Item",
                    systemImageName: "plus")
        AppShortcut(intent: MarkItemDisposedIntent(),
                    phrases: ["Mark \(\.$item) as disposed in \(.applicationName)"],
                    shortTitle: "Mark as Disposed",
                    systemImageName: "archivebox")
        AppShortcut(intent: CountItemsIntent(),
                    phrases: ["How many items do I have in \(.applicationName)",
                              "Count items in \(.applicationName)"],
                    shortTitle: "Count Items",
                    systemImageName: "number")
    }

    static let shortcutTileColor = ShortcutTileColor.orange
}
