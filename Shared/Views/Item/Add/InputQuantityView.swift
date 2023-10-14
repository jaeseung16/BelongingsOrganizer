//
//  InputQuantityView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputQuantityView: View {
    @Binding var quantity: String
    let geometry: GeometryProxy

    var body: some View {
        HStack {
            Text("QUANTITY")
                .font(.caption)
            
            Spacer()
            
            #if os(macOS)
            TextField("0", text: $quantity)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background(CommonRoundedRectangle)
            #else
            TextField("0", text: $quantity)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background { CommonRoundedRectangle() }
                .keyboardType(.numberPad)
            #endif
        }
    }
}

