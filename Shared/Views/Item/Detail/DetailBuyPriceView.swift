//
//  DetailBuyPriceView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailBuyPriceView: View {
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
    @Binding var buyPrice: Double
    @Binding var buyCurrency: String
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                SectionTitleView(title: .price)
                
                #if os(macOS)
                TextField("sell price", value: $buyPrice, formatter: priceFormatter, prompt: Text("0.00"))
                    .onSubmit({
                        isEdited = true
                    })
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                    .background { CommonRoundedRectangle() }
                #else
                TextField("sell price", value: $buyPrice, formatter: priceFormatter, prompt: Text("0.00"))
                    .onChange(of: buyPrice) { newValue in
                        // TODO:
                        isEdited = newValue != item.buyPrice
                    }
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                    .background { CommonRoundedRectangle() }
                    .keyboardType(.decimalPad)
                #endif
            }
            
            HStack {
                Spacer()
                
                Picker("", selection: $buyCurrency) {
                    ForEach(currencyCodes, id: \.self) { currencyCode in
                        Text("\(currencyCode)")
                    }
                }
                .background { CommonRoundedRectangle() }
                .onChange(of: buyCurrency) { newValue in
                    // TODO:
                    isEdited = newValue != item.buyCurrency
                }
            }
        }
    }
}
