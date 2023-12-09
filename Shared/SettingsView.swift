//
//  SettingsView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/9/23.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("BelongingsOrganizer.currency") private var currency = "USD"
    
    private let currencyCodes = NSLocale.commonISOCurrencyCodes
    
    private func localizedString(for currencyCode: String) -> String {
        return NSLocale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? ""
    }
    
    var body: some View {
        Form {
            Picker("Currency", selection: $currency) {
                ForEach(currencyCodes, id: \.self) { currencyCode in
                    Text("\(currencyCode) (\(localizedString(for: currencyCode)))")
                }
            }
        }
        .padding()
        .frame(maxWidth: 500)
    }
}
