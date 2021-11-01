//
//  BrandDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/14/21.
//

import SwiftUI

struct BrandDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var brand: Brand
    
    private var items: [Item] {
        var items = [Item]()
        brand.items?.forEach { item in
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
        }
    }
    
    private func reset() {
        name = brand.name ?? ""
        urlString = brand.url?.absoluteString ?? ""
        
        isEdited = false
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button {
                reset()
            } label: {
                Text("Cancel")
            }
            .disabled(!isEdited)
            
            Spacer()
            
            Button {
                viewModel.brandDTO = BrandDTO(id: brand.uuid, name: name, url: URL(string: urlString))
                isEdited = false
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
                SectionTitleView(title: "NAME")
                
                Spacer()
            }
            
            TextField(brand.name ?? "", text: $name) { isEditing in
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
                SectionTitleView(title: "URL")
                
                Spacer()
                
                if let url = brand.url {
                    Link(destination: url) {
                        Label("Open in Browser", systemImage: "link")
                            .font(.caption)
                    }
                }
            }
            
            TextField(brand.url?.absoluteString ?? "N/A", text: $urlString) { isEditing in
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
            Spacer()
            
            SectionTitleView(title: "ADDED")
            
            Text("\(brand.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
    
    private func lastUpdatedView() -> some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: "UPDATED")
            
            Text("\(brand.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
    
}

