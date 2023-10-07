//
//  NameView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/7/23.
//

import SwiftUI

struct NameView<Background: View>: View {
    
    @Binding var name: String
    @Binding var isEdited: Bool
    var color = Color.primary
    @ViewBuilder var background: Background
    
    var body: some View {
        VStack {
            HStack {
                SectionTitleView(title: .name, color: color == .primary ? .secondary : .primary)
                
                Spacer()
            }
            
            TextField(text: $name) {
                Text("name")
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity, idealHeight: 50)
            .background(alignment: .center) {
                background
            }
            .onSubmit {
                isEdited = true
            }
        }
    }
}

