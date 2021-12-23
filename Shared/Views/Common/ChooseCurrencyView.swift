//
//  ChooseCurrencyView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct ChooseCurrencyView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var currency: String
    
    private let currencyCodes = NSLocale.commonISOCurrencyCodes
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Choose a currency")
                
                #if os(macOS)
                Picker("", selection: $currency) {
                    ForEach(currencyCodes, id: \.self) { currencyCode in
                        Text("\(currencyCode) (\(localizedString(for: currencyCode)))")
                    }
                }
                #else
                Picker("", selection: $currency) {
                    ForEach(currencyCodes, id: \.self) { currencyCode in
                        Text("\(currencyCode) (\(localizedString(for: currencyCode)))")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                #endif
                
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Text("Done")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    private func localizedString(for currencyCode: String) -> String {
        return NSLocale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? ""
    }
}

struct ChooseCurrencyView_Previews: PreviewProvider {
    @State static var currency: String = "USD"
    static var previews: some View {
        ChooseCurrencyView(currency: $currency)
    }
}
