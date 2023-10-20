//
//  DetailPriceView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/20/23.
//

import SwiftUI

struct DetailPriceView: View {
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
    
    let originalPrice: Double
    let originalCurrency: String?
    @Binding var price: Double
    @Binding var currency: String
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    var body: some View {
        let priceBinding = Binding {
            price
        } set: {
            price = $0
            isEdited = $0 != originalPrice
        }
        
        let currencyBinding = Binding {
            currency
        } set: {
            currency = $0
            isEdited = $0 != originalCurrency
        }

        VStack {
            HStack {
                Spacer()
                
                SectionTitleView(title: .price)
                
                #if os(macOS)
                TextField("sell price", value: priceBinding, formatter: priceFormatter, prompt: Text("0.00"))
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
