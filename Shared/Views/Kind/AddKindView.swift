//
//  AddItemView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/6/21.
//

import SwiftUI

struct AddKindView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State private var name = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            Text("Add a category")
                .font(.title3)
            
            Divider()
            
            Text("NAME")
                .font(.caption)
            
            TextField("name", text: $name)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, idealHeight: 50)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Divider()
            
            AddBottomView {
                dismiss.callAsFunction()
            } save: {
                viewModel.saveKind(name: name)
                dismiss.callAsFunction()
            }
            
            Spacer()
        }
        .padding()
        .frame(minHeight: 200.0)
        
    }
}
