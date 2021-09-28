//
//  KindDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/12/21.
//

import SwiftUI

struct KindDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var kind: Kind
    
    private var items: [Item] {
        var items = [Item]()
        kind.items?.forEach { item in
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
                        TextField(kind.name ?? "", text: $name) { isEditing in
                            self.isEditing = isEditing
                        } onCommit: {
                            isEditing = false
                            isEdited = true
                        }
                    }
                    
                    Section(header: Text("added on").foregroundColor(.secondary)) {
                        HStack {
                            Spacer()
                            Text("\(kind.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                        }
                    }
                    
                    Section(header: Text("last updated on").foregroundColor(.secondary)) {
                        HStack {
                            Spacer()
                            Text("\(kind.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
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
                viewModel.kindDTO = KindDTO(id: kind.uuid, name: name)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited)
            
            Spacer()
        }
    }
}

