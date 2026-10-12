//
//  URLViewModifier.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/9/23.
//

import SwiftUI

struct NameURLModifier<Background: View>: ViewModifier {
    var color: Color
    @ViewBuilder var background: Background
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .frame(maxWidth: .infinity, idealHeight: 50)
            .background(alignment: .center) {
                background
            }
    }
}
