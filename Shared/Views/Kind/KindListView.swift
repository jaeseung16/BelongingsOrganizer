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
                                .environmentObject(viewModel.addItemViewModel)
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
        .onChange(of: viewModel.addItemViewModel.showAlert) { _ in
            showAlert = viewModel.addItemViewModel.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(viewModel.addItemViewModel.message)
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
                viewModel.addItemViewModel.reset()
                presentAddKindView = true
            }) {
                Label("Add a category", systemImage: "plus")
            }
        }
    }
    
    private func kindListView() -> some View {
        List {
            ForEach(filteredKinds) { kind in
                if let kindName = kind.name {
                    NavigationLink(destination: KindDetailView(kind: kind, name: kindName, items: getItems(kind))) {
                        KindRowView(kind: kind, name: kindName)
                    }
                }
            }
            .onDelete(perform: deleteKinds)
        }
    }
    
    private func getItems(_ kind: Kind) -> [Item] {
        guard let items = kind.items else {
            return [Item]()
        }
        
        return items.compactMap { $0 as? Item }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }
    
    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredKinds[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
