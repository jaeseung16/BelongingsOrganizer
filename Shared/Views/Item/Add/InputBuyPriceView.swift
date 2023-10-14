//
//  InputBuyPriceView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputBuyPriceView: View {
    @Binding var buyPrice: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack {
            Text("PRICE")
                .font(.caption)
            
            Spacer()
            
            #if os(macOS)
            TextField("0.00", text: $buyPrice)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .background{ CommonRoundedRectangle() }
            #else
            TextField("0.00", text: $buyPrice)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .background { CommonRoundedRectangle() }
                .keyboardType(.decimalPad)
            #endif
        }
    }
}
