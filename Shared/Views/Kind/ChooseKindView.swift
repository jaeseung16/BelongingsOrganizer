//
//  ChooseItemView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI

struct ChooseKindView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var presentAddItem = false
    
    @Binding var selectedKinds: [KindDTO]
    
    @State private var showAlertForDeletion = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Choose a category")
                    .font(.title3)
                
                Divider()
                
                selectedView()
                    .frame(minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 10.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                
                Divider()
                
                kindList()
                
                Divider()
                
                SheetBottom(labelText: "Add a category") {
                    presentAddItem = true
                } done: {
                    dismiss.callAsFunction()
                }
            }
            .padding()
            .sheet(isPresented: $presentAddItem, content: {
                #if os(macOS)
                AddKindView()
                    .frame(minWidth: 0.5 * geometry.size.width)
                    .environmentObject(viewModel)
                #else
                AddKindView()
                    .environmentObject(viewModel)
                #endif
            })
            .alert(isPresented: $showAlertForDeletion) {
                Alert(title: Text("Unable to Delete Data"),
                      message: Text("Failed to delete the selected category"),
                      dismissButton: .default(Text("Dismiss")))
            }
        }
        
    }
    
    private func selectedView() -> some View {
        VStack {
            HStack {
                Text("SELECTED")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
           
            List {
                ForEach(selectedKinds) { kind in
                    Button {
                        if let index = selectedKinds.firstIndex(of: kind) {
                            selectedKinds.remove(at: index)
                        }
                    } label: {
                        Text(kind.name ?? "")
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
    }
    
    private func kindList() -> some View {
        List {
            ForEach(viewModel.kinds) { kind in
                Button {
                    if selectedKinds.contains(kind) {
                        if let index = selectedKinds.firstIndex(of: kind) {
                            selectedKinds.remove(at: index)
                        }
                    } else {
                        selectedKinds.append(kind)
                    }
                } label: {
                    Text(kind.name ?? "")
                }
            }
            .onDelete(perform: deleteItems)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.compactMap {
                if let id = viewModel.kinds[$0].id {
                    return viewModel.get(entity: .Kind, id: id)
                } else {
                    return nil
                }
            }) { error in
                if let error = error {
                    showAlertForDeletion.toggle()
                } else {
                    viewModel.fetchKinds()
                }
            }
        }
    }
}

