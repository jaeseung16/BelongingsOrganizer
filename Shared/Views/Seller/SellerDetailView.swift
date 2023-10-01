//
//  SellerDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/14/21.
//

import SwiftUI

struct SellerDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var seller: Seller
    @State var name = ""
    @State var urlString = ""
    var items: [Item]
    
    @State private var showAlert = false
    @State private var isEdited = false
    
    @State private var showProgress = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                nameView()
                
                urlView()
                
                addedView()
                
                lastUpdatedView()
                
                Divider()
                
                ItemsView(items: items)
            }
            .navigationTitle(name)
            .padding()
            .overlay {
                ProgressView("Please wait...")
                    .progressViewStyle(.circular)
                    .opacity(showProgress ? 1 : 0)
            }
            .alert("Invalid URL", isPresented: $showAlert, actions: {
                Button("Dismiss")  {
                    urlString = seller.url?.absoluteString ?? ""
                }
            }, message: {
                Text("Cannot access the URL. Try a different one or leave it empty.")
            })
        }
        
    }
    
    private func header() -> some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            update()
        }
    }
    
    private func reset() {
        name = seller.name ?? ""
        urlString = seller.url?.absoluteString ?? ""
        isEdited = false
    }
    
    private func update() {
        viewModel.sellerDTO = SellerDTO(id: seller.uuid, name: name, url: URL(string: urlString))
        isEdited = false
    }
    
    private func nameView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: .name)
                
                Spacer()
            }
            
            TextField(seller.name ?? "", text: $name, prompt: nil)
                .onSubmit {
                    isEdited = true
                }
        }
    }
    
    private func urlView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: .url)
                
                Spacer()
                
                if let url = seller.url {
                    Link(destination: url) {
                        Label("Open in Browser", systemImage: "link")
                            .font(.caption)
                    }
                }
            }
            
            TextField(seller.url?.absoluteString ?? "N/A", text: $urlString, prompt: nil)
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
        }
    }
    
    private func addedView() -> some View {
        DateSectionView(sectionTitle: .added, date: seller.created ?? Date())
    }
    
    private func lastUpdatedView() -> some View {
        DateSectionView(sectionTitle: .updated, date: seller.lastupd ?? Date())
    }
}
