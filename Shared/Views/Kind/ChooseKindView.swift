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
    
    @State private var presentAddItem = false
    @State private var showAlertForDeletion = false
    @Binding var kinds: [Kind]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Choose a category")
                    .font(.title3)
                
                Divider()
                
                selectedKinds
                    .frame(minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 10.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                
                Divider()
                
                kindList
                
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
    
    private var selectedKinds: some View {
        VStack {
            HStack {
                Text("SELECTED")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
           
            List {
                ForEach(kinds) { kind in
                    Button {
                        if let index = kinds.firstIndex(of: kind) {
                            kinds.remove(at: index)
                        }
                    } label: {
                        Text(kind.name ?? "")
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
    }
    
    private var kindList: some View {
        List {
            ForEach(viewModel.allKinds) { kind in
                Button {
                    if kinds.contains(kind) {
                        if let index = kinds.firstIndex(of: kind) {
                            kinds.remove(at: index)
                        }
                    } else {
                        kinds.append(kind)
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
            viewModel.delete(offsets.map { viewModel.allKinds[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a category, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
            }
        }
    }
}

