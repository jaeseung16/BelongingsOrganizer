//
//  KindListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct KindListView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var presentAddKindView = false

    @State private var showAlert = false
    @State private var showAlertForDeletion = false

    @State var kinds = [Kind]()
    
    var body: some View {
        NavigationView {
            VStack {
                header()
                
                kindListView()
                    .sheet(isPresented: $presentAddKindView) {
                        AddKindView()
                            .environmentObject(viewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                        
                    }
            }
            .navigationTitle("Categories")
        }
        .onChange(of: viewModel.kinds) { _ in
            kinds = viewModel.filteredKinds
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .onChange(of: viewModel.stringToSearch) { _ in
            kinds = viewModel.filteredKinds
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(viewModel.message)
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text("Failed to delete the selected category")
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                viewModel.persistenceHelper.reset()
                presentAddKindView = true
            }) {
                Label("Add a category", systemImage: "plus")
            }
        }
    }
    
    private func kindListView() -> some View {
        List {
            ForEach(kinds) { kind in
                NavigationLink {
                    KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                } label: {
                    KindRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                }
            }
            .onDelete(perform: deleteKinds)
        }
        .id(UUID())
    }

    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { kinds[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
