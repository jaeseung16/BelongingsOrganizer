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
                
                nameView()
                
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
                viewModel.kindDTO = KindDTO(id: kind.uuid, name: name)
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
            
            TextField(kind.name ?? "", text: $name) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
        }
    }

    private func addedView() -> some View {
        HStack {
            Text("ADDED")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(kind.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
    
    private func lastUpdatedView() -> some View {
        HStack {
            Text("LAST UPDATED")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(kind.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
}

