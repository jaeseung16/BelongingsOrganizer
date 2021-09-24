//
//  ChooseCurrencyView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct ChooseCurrencyView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding var currency: String
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Choose a currency")
                
                #if os(macOS)
                Picker("", selection: $currency) {
                    ForEach(NSLocale.commonISOCurrencyCodes, id: \.self) { currencyCode in
                        Text("\(currencyCode) (\(NSLocale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? ""))")
                    }
                }
                #else
                Picker("", selection: $currency) {
                    ForEach(NSLocale.commonISOCurrencyCodes, id: \.self) { currencyCode in
                        Text("\(currencyCode) (\(NSLocale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? ""))")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                #endif
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Done")
                })
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

struct ChooseCurrencyView_Previews: PreviewProvider {
    @State static var currency: String = "USD"
    static var previews: some View {
        ChooseCurrencyView(currency: $currency)
    }
}
