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
    
    @State var kinds: [Kind]
    
    private var filteredKinds: [Kind] {
        kinds.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
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
        }
        .onReceive(viewModel.$updated) { _ in
            kinds = viewModel.kinds
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
            ForEach(filteredKinds) { kind in
                NavigationLink {
                    KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                        .id(UUID())
                } label: {
                    KindRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                        .id(UUID())
                }
            }
            .onDelete(perform: deleteKinds)
        }
        .id(UUID())
    }

    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredKinds[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
