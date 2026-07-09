//
//  LockScreenView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 7/9/26.
//

import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var authService: AuthenticationService

    #if os(macOS)
    private let backgroundColor = Color(nsColor: .windowBackgroundColor)
    #else
    private let backgroundColor = Color(uiColor: .systemBackground)
    #endif

    private var biometrySymbol: String {
        switch authService.biometryType {
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "faceid"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Belongings Organizer is locked")
                .font(.title3)

            if let authenticationError = authService.authenticationError {
                Text(authenticationError)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Button {
                Task {
                    await authService.authenticate()
                }
            } label: {
                Label("Unlock", systemImage: biometrySymbol)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
        .accessibilityIdentifier("LockScreen")
    }
}
