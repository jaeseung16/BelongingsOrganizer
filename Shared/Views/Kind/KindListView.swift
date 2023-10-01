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

    @State private var showAlertForDeletion = false

    @State private var selectedKind: Kind?
    
    var kinds: [Kind] {
        return viewModel.filteredKinds
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
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
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
        NavigationSplitView {
            VStack {
                List(selection: $selectedKind) {
                    ForEach(kinds) { kind in
                        NavigationLink(value: kind) {
                            BrandKindSellerRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                        }
                    }
                    .onDelete(perform: deleteKinds)
                }
                .navigationTitle("Categories")
                .toolbar {
                    header()
                }
            }
            .refreshable {
                viewModel.fetchEntities()
            }
        } detail: {
            if let kind = selectedKind {
                KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                    .environmentObject(viewModel)
                    .id(UUID())
                    .navigationBarTitleDisplayMode(.inline)
            }
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
