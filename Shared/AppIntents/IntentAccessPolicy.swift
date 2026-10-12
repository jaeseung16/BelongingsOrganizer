//
//  IntentAccessPolicy.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/28/26.
//

import Foundation
import AppIntents

// The app lock only covers the app's window. Siri, Shortcuts, and Spotlight read and change
// belongings without it, so they follow this policy while the lock is on.
nonisolated enum IntentAccessPolicy {
    static var isAppLocked: Bool {
        UserDefaults.standard.bool(forKey: BelongsOrganizerConstants.requireAuthentication.rawValue)
    }

    // For intents that read or change belongings: the device has to be unlocked
    static var authenticationPolicy: IntentAuthenticationPolicy {
        isAppLocked ? .requiresAuthentication : .alwaysAllowed
    }

    // Photos stay out of Siri and Shortcuts results while the lock is on
    static var showsPhotos: Bool {
        !isAppLocked
    }

    // So do prices in snippets
    static var showsPrices: Bool {
        !isAppLocked
    }
}
