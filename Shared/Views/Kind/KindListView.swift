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
    @Binding var selected: Kind?

    var kinds: [Kind] {
        return viewModel.filteredKinds
    }

    var body: some View {
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
        .refreshable {
            viewModel.fetchEntities()
        }
        .sheet(isPresented: $presentAddKindView) {
            AddKindView()
                .environmentObject(viewModel)
                .modifier(SheetModifier())
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Failed to delete the selected category")
        }
    }

    private var header: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .leadingButtons) {
            Button {
                viewModel.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(!viewModel.canRefresh)

            Button {
                presentAddKindView = true
            } label: {
                Label("Add a category", systemImage: "plus")
            }
        }
    }

    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            let kindsToDelete = offsets.map { kinds[$0] }
            if let selected, kindsToDelete.contains(selected) {
                self.selected = nil
            }
            viewModel.delete(kindsToDelete) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
