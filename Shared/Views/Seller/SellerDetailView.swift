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
            .alert("Invalid URL", isPresented: $showAlert, actions: {
                Button("Dismiss")  {
                    urlString = seller.url?.absoluteString ?? ""
                }
            }, message: {
                Text("Cannot access the URL. Try a different one or leave it empty.")
            })
        }
        
    }
    
    private func reset() {
        name = seller.name ?? ""
        urlString = seller.url?.absoluteString ?? ""
        
        isEdited = false
    }
    
    private func header() -> some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            viewModel.sellerDTO = SellerDTO(id: seller.uuid, name: name, url: URL(string: urlString))
            isEdited = false
        }
    }
    
    private func nameView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: "NAME")
                
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
                SectionTitleView(title: "URL")
                
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
                    
                    if let url = URLValidator.validate(urlString: urlString) {
                        urlString = url.absoluteString
                    } else {
                        showAlert = true
                    }
                }
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
        }
    }
    
    private func addedView() -> some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: "ADDED")
            
            Text("\(seller.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
    
    private func lastUpdatedView() -> some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: "UPDATED")
            
            Text("\(seller.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
}
