//
//  DetailQuantityView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailQuantityView: View {
    private var quantityFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        return formatter
    }
    
    let originalQuantity: Int
    @Binding var quantity: Int
    @Binding var isEdited: Bool
    
    var body: some View {
        HStack {
            SectionTitleView(title: .quantity)
            
            Spacer()
            
            #if os(macOS)
            TextField("quantity", value: $quantity, formatter: quantityFormatter, prompt: Text("0"))
                .onSubmit({
                    isEdited = quantity != Int(item.quantity)
                })
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background { CommonRoundedRectangle() }
            #else
            TextField("quantity", value: $quantity, formatter: quantityFormatter, prompt: Text("0"))
                .onSubmit {
                    isEdited = quantity != originalQuantity
                }
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background { CommonRoundedRectangle() }
                .keyboardType(.numberPad)
            #endif
        }
    }
}
