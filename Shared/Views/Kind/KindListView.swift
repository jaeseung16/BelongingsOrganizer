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

    var kinds: [Kind] {
        return viewModel.kinds
    }
    
    var body: some View {
        VStack {
            kindListView()
                .sheet(isPresented: $presentAddKindView) {
                    AddKindView()
                        .environmentObject(viewModel)
                        .frame(minWidth: 350, minHeight: 450)
                        .padding()
                    
                }
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
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
    
    private func header() -> ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                viewModel.persistenceHelper.reset()
                presentAddKindView = true
            } label: {
                Label("Add a category", systemImage: "plus")
            }
        }
    }
    
    private func kindListView() -> some View {
        NavigationStack {
            List {
                ForEach(kinds) { kind in
                    NavigationLink(value: kind) {
                        KindRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                    }
                }
                .onDelete(perform: deleteKinds)
                //.id(UUID())
            }
            .navigationDestination(for: Kind.self) { kind in
                KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                    .environmentObject(viewModel)
            }
            .toolbar {
                header()
            }
            .navigationTitle("Categories")
        }
    }

    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { kinds[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
