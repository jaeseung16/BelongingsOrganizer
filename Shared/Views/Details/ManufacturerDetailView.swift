//
//  ManufacturerDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/14/21.
//

import SwiftUI

struct ManufacturerDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var manufacturer: Manufacturer
    
    private var items: [Item] {
        var items = [Item]()
        manufacturer.items?.forEach { item in
            if let item = item as? Item {
                items.append(item)
            }
        }
        return items
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
                        TextField(manufacturer.name ?? "", text: $name) { isEditing in
                            self.isEditing = isEditing
                        } onCommit: {
                            isEditing = false
                            isEdited = true
                        }
                    }
                    
                    Section(header: Text("added on").foregroundColor(.secondary)) {
                        HStack {
                            Spacer()
                            Text("\(manufacturer.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                        }
                    }
                    
                    Section(header: Text("last updated on").foregroundColor(.secondary)) {
                        HStack {
                            Spacer()
                            Text("\(manufacturer.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                        }
                    }
                    
                    Section(header: Text("items").foregroundColor(.secondary)) {
                        List {
                            ForEach(items) { item in
                                Text(item.name ?? "")
                            }
                        }
                    }
                }
                .padding()
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
                viewModel.manufacturerDTO = ManufacturerDTO(id: manufacturer.uuid, name: name)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited)
            
            Spacer()
        }
    }
}

