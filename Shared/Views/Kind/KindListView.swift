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
    @State private var selected: Kind?
    
    var kinds: [Kind] {
        return viewModel.filteredKinds
    }
    
    var body: some View {
        VStack {
            kindList
                .sheet(isPresented: $presentAddKindView) {
                    AddKindView()
                        .environmentObject(viewModel)
                        .modifier(SheetModifier())
                }
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Failed to delete the selected category")
        }
    }
    
    private var kindList: some View {
        NavigationSplitView {
            VStack {
                List(selection: $selected) {
                    ForEach(kinds) { kind in
                        NavigationLink(value: kind) {
                            BrandKindSellerRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                        }
                    }
                    .onDelete(perform: deleteKinds)
                }
                .navigationTitle("Categories")
                .toolbar {
                    header
                }
            }
            .refreshable {
                viewModel.fetchEntities()
            }
        } detail: {
            if let kind = selected {
                KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                    .environmentObject(viewModel)
                    .id(UUID())
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private var header: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                presentAddKindView = true
            } label: {
                Label("Add a category", systemImage: "plus")
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
