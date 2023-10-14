//
//  InputBuyCurrencyView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputBuyCurrencyView: View {
    @Binding var currency: String
    let geometry: GeometryProxy
    private let currencyCodes = NSLocale.commonISOCurrencyCodes
    
    private func localizedString(for currencyCode: String) -> String {
        return NSLocale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? ""
    }
    
    var body: some View {
        HStack {
            Text("CURRENCY")
                .font(.caption)
            
            Spacer()
            
            Picker("", selection: $currency) {
                ForEach(currencyCodes, id: \.self) { currencyCode in
                    Text("\(currencyCode) (\(localizedString(for: currencyCode)))")
                }
            }
            .background { CommonRoundedRectangle() }
        }
    }
}
