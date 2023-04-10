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
    
    @State var kinds: [KindDTO] {
        didSet {
            filteredKinds = kinds.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
        }
    }
    
    @State var filteredKinds = [KindDTO]()
    
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
        .onChange(of: viewModel.kinds) { _ in
            kinds = viewModel.kinds
        }
        .onReceive(viewModel.$stringToSearch) { _ in
            filteredKinds = kinds.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
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
                        KindRowView(kind: kind)
                    }
                }
            }
            .onDelete(perform: deleteKinds)
        }
        .id(UUID())
    }
    
    private func getItems(_ kind: KindDTO) -> [ItemDTO] {
        return viewModel.items
            .filter { item in
                if let kindSet = item.kinds {
                    let matchedKind = kindSet.filter { element in
                        if element.id == kind.id {
                            return true
                        } else {
                            return false
                        }
                    }
                    return !matchedKind.isEmpty
                } else {
                    return false
                }
            }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }
    
    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.compactMap {
                if let id = filteredKinds[$0].id {
                    return viewModel.get(entity: .Kind, id: id)
                } else {
                    return nil
                }
            }) { error in
                if error != nil {
                    showAlertForDeletion.toggle()
                } else {
                    viewModel.fetchKinds()
                }
            }
        }
    }
}
