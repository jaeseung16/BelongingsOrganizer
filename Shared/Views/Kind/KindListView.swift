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
    
    @State var selectedKind: Kind?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                VStack {
                    header()
                    
                    List(selection: $selectedKind) {
                        ForEach(filteredKinds, id: \.self) { kind in
                            if let kindName = kind.name {
                                NavigationLink(value: kind) {
                                    KindRowView(name: kindName, itemCount: getItems(kind).count)
                                }
                            }
                        }
                        .onDelete(perform: deleteKinds)
                    }
                    .navigationTitle("Categories")
                    .id(UUID())
                }
            } detail: {
                if let kind = selectedKind, let name = kind.name {
                    KindDetailView(kind: kind, name: name, items: getItems(kind))
                    .id(UUID())
                } else {
                    Text("Sellect a seller")
                }
            }
        }
        .onReceive(viewModel.$updated) { _ in
            kinds = viewModel.kinds
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .sheet(isPresented: $presentAddKindView) {
            AddKindView()
                .environmentObject(viewModel)
                .frame(minWidth: 350, minHeight: 450)
                .padding()
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
