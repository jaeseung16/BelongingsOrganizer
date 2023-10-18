//
//  DetailSellPriceView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailSellPriceView: View {
    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    private let currencyCodes = NSLocale.commonISOCurrencyCodes
    
    private func localizedString(for currencyCode: String) -> String {
        return NSLocale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? ""
    }
    
    var item: Item
    @Binding var sellPrice: Double
    @Binding var sellCurrency: String
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    var body: some View {
        let priceBinding = Binding {
            sellPrice
        } set: {
            sellPrice = $0
            isEdited = $0 != item.sellPrice
        }
        
        let currencyBinding = Binding {
            sellCurrency
        } set: {
            sellCurrency = $0
            isEdited = $0 != item.sellCurrency
        }

        VStack {
            HStack {
                Spacer()
                
                SectionTitleView(title: .price)
                
                #if os(macOS)
                TextField("sell price", value: $sellPrice, formatter: priceFormatter, prompt: Text("0.00"))
                    .onSubmit({
                        isEdited = true
                    })
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                    .background { CommonRoundedRectangle() }
                #else
                TextField("sell price", value: priceBinding, formatter: priceFormatter, prompt: Text("0.00"))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                    .background { CommonRoundedRectangle() }
                    .keyboardType(.decimalPad)
                #endif
            }
            
            HStack {
                Spacer()
                
                Picker("", selection: currencyBinding) {
                    ForEach(currencyCodes, id: \.self) { currencyCode in
                        Text("\(currencyCode)")
                    }
                }
                .background { CommonRoundedRectangle() }
            }
        }
    }
}
