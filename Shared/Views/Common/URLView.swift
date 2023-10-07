//
//  URLView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/7/23.
//

import SwiftUI

struct URLView<Background: View>: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    var title: SectionTitle
    var url: URL?
    @Binding var urlString: String
    @Binding var isEdited: Bool
    @Binding var showProgress: Bool
    @State private var showAlert = false
    var color = Color.primary
    @ViewBuilder var background: Background
    
    var body: some View {
        VStack {
            HStack {
                SectionTitleView(title: .url, color: color == .primary ? .secondary : .primary)
                
                Spacer()
                
                if let url {
                    Link(destination: url) {
                        Label("Open in Browser", systemImage: "link")
                            .font(.caption)
                    }
                }
            }
            
            TextField(url?.absoluteString ?? "N/A", text: $urlString, prompt: nil)
                .onSubmit {
                    isEdited = true
                    
                    showProgress = true
                    Task {
                        if let url = await viewModel.validatedURL(from: urlString) {
                            self.urlString = url.absoluteString
                        } else {
                            self.showAlert = true
                        }
                        self.showProgress = false
                    }
                }
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .foregroundColor(color)
                .frame(maxWidth: .infinity, idealHeight: 50)
                .background(alignment: .center) {
                    background
                }
        }
        .alert("Invalid URL", isPresented: $showAlert) {
            Button("Dismiss")  {
                urlString = ""
            }
        } message: {
            Text("Cannot access the URL. Try a different one or leave it empty.")
        }
    }
}
