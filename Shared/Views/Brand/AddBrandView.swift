//
//  AddBrandView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct AddBrandView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State private var name = ""
    @State private var urlString = ""
    @State private var isEditing = false
    @State private var isEdited = false    
    @State private var showProgress = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            Text("Add a brand")
                .font(.title3)
            
            Divider()
            
            NameView(name: $name, isEdited: $isEdited, color: .secondary) {
                RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1))
            }
            
            URLView(title: .url, urlString: $urlString, isEdited: $isEdited, showProgress: $showProgress, color: .secondary) {
                RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1))
            }
            .environmentObject(viewModel)
            
            Divider()
            
            AddBottomView {
                dismiss.callAsFunction()
            } save: {
                viewModel.saveBrand(name: name, urlString: urlString)
                dismiss.callAsFunction()
            }

            Spacer()
        }
        .padding()
        .overlay {
            ProgressView("Please wait...")
                .progressViewStyle(.circular)
                .opacity(showProgress ? 1 : 0)
        }
        .frame(minHeight: 200.0)
    }
}
