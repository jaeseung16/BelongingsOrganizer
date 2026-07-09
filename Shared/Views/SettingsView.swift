//
//  SettingsView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 7/9/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService

    @AppStorage(BelongsOrganizerConstants.requireAuthentication.rawValue)
    private var requireAuthentication = false

    @State private var lockToggle = false

    var body: some View {
        VStack {
            header

            Divider()

            Text("Settings")
                .font(.title3)

            Form {
                Section {
                    Toggle("Require \(authService.biometryDescription)", isOn: $lockToggle)
                        .onChange(of: lockToggle) { _, newValue in
                            guard newValue != requireAuthentication else {
                                return
                            }
                            Task {
                                await authService.authenticate()
                                if authService.isUnlocked {
                                    requireAuthentication = newValue
                                } else {
                                    lockToggle = requireAuthentication
                                }
                            }
                        }
                } footer: {
                    Text("When enabled, \(authService.biometryDescription) is required each time the app launches or returns from the background.")
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            lockToggle = requireAuthentication
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Dismiss")
            }

            Spacer()
        }
    }
}
