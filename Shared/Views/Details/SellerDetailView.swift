//
//  SellerDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/14/21.
//

import SwiftUI

struct SellerDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var seller: Seller
    
    private var items: [Item] {
        var items = [Item]()
        seller.items?.forEach { item in
            if let item = item as? Item {
                items.append(item)
            }
        }
        return items.sorted {
            ($0.obtained ?? Date()) > ($1.obtained ?? Date())
        }
    }
    
    @State private var isEditing = false
    @State private var isEdited = false
    @State var name = ""
    @State var urlString = ""
    
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
            .padding()
            .onReceive(viewModel.$changedPeristentContext) { _ in
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Cancel", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited)
            
            Spacer()
            
            Button {
                viewModel.sellerDTO = SellerDTO(id: seller.uuid, name: name, url: URL(string: urlString))
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited)
            
            Spacer()
        }
    }
    
    private func nameView() -> some View {
        VStack {
            HStack {
                Text("NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            TextField(seller.name ?? "", text: $name) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
        }
    }
    
    private func urlView() -> some View {
        VStack {
            HStack {
                Text("URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let url = seller.url {
                    Link(destination: url) {
                        Label("Open in Browser", systemImage: "link")
                            .font(.caption)
                    }
                }
            }
            
            TextField(seller.url?.absoluteString ?? "N/A", text: $urlString) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
                
                if let url = URLValidator.validate(urlString: urlString) {
                    urlString = url.absoluteString
                }
            }
        }
    }
    
    private func addedView() -> some View {
        HStack {
            Text("ADDED")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(seller.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
    
    private func lastUpdatedView() -> some View {
        HStack {
            Text("LAST UPDATED")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(seller.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
}
