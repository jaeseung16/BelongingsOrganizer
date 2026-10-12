//
//  AuthenticationService.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 7/9/26.
//

import Foundation
import LocalAuthentication
import os

@MainActor
final class AuthenticationService: ObservableObject {
    private let logger = Logger()

    @Published var isUnlocked = false
    @Published var authenticationError: String?

    private var isAuthenticating = false

    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
    }

    var biometryDescription: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Passcode"
        }
    }

    func authenticate() async {
        guard !isAuthenticating else {
            return
        }
        isAuthenticating = true
        defer {
            isAuthenticating = false
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No passcode is set on this device: unlock rather than lock the user out.
            logger.log("Cannot evaluate authentication policy: \(String(describing: error), privacy: .public)")
            isUnlocked = true
            return
        }

        do {
            isUnlocked = try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                          localizedReason: "Unlock your belongings")
            authenticationError = nil
        } catch {
            logger.error("Failed to authenticate: \(error.localizedDescription, privacy: .public)")
            authenticationError = error.localizedDescription
            isUnlocked = false
        }
    }

    func lock() {
        isUnlocked = false
    }
}
