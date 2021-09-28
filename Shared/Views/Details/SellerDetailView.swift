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
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                Form {
                    Section(header: Text("Name").foregroundColor(.secondary)) {
                        TextField(seller.name ?? "", text: $name) { isEditing in
                            self.isEditing = isEditing
                        } onCommit: {
                            isEditing = false
                            isEdited = true
                        }
                    }
                    
                    Section(header: Text("url").foregroundColor(.secondary)) {
                        HStack {
                            if let url = seller.url {
                                Link("\(url.absoluteString)", destination: url)
                            } else {
                                Text("N/A")
                            }
                        }
                    }
                    
                    Section(header: Text("added on").foregroundColor(.secondary)) {
                        HStack {
                            Spacer()
                            Text("\(seller.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                        }
                    }
                    
                    Section(header: Text("last updated on").foregroundColor(.secondary)) {
                        HStack {
                            Spacer()
                            Text("\(seller.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                        }
                    }
                    
                    Section(header: Text("items").foregroundColor(.secondary)) {
                        #if os(macOS)
                        NavigationView {
                            List {
                                ForEach(items) { item in
                                    NavigationLink(destination: ItemSummaryView(item: item)) {
                                        VStack(alignment: .leading) {
                                            HStack {
                                                if let imageData = item.image, let nsImage = NSImage(data: imageData) {
                                                    Image(nsImage: nsImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                }
                                                Text(item.name ?? "")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        #else
                        List {
                            ForEach(items) { item in
                                NavigationLink(destination: ItemSummaryView(item: item)) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            if let imageData = item.image, let uiImage = UIImage(data: imageData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                            }
                                            Text(item.name ?? "")
                                        }
                                    }
                                }
                            }
                        }
                        #endif
                    }
                }
                .padding()
            }
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
                viewModel.sellerDTO = SellerDTO(id: seller.uuid, name: name)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited)
            
            Spacer()
        }
    }
}
