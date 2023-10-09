//
//  SheetModifier.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/9/23.
//

import SwiftUI

struct SheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 350, minHeight: 450)
            .padding()
    }
}

