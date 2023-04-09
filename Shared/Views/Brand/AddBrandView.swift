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
    @State private var showAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            Text("Add a brand")
                .font(.title3)
            
            Divider()
            
            Text("NAME")
                .font(.caption)
            
            TextField("name", text: $name)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, idealHeight: 50)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("URL")
                .font(.caption)
            
            TextField("url", text: $urlString, prompt: nil)
                .onSubmit {
                    if let url = URLValidator.validate(urlString: urlString) {
                        print("url = \(url)")
                        self.urlString = url.absoluteString
                    } else {
                        showAlert = true
                    }
                }
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, idealHeight: 50)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))

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
        .frame(minHeight: 200.0)
        .alert("Invalid URL", isPresented: $showAlert, actions: {
            Button("Dismiss")  {
                urlString = ""
            }
        }, message: {
            Text("Cannot access the URL. Try a different one or leave it empty.")
        })
    }
}

