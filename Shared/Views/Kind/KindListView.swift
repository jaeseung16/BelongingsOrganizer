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
    // The split view's search field; the tab root searches in its Search tab
    var search = ""
    @Binding var selected: Kind?

    var kinds: [Kind] {
        return viewModel.kinds(matching: search)
    }

    var body: some View {
        List(selection: $selected) {
            ForEach(kinds) { kind in
                NavigationLink(value: kind) {
                    BrandKindSellerRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    deleteButton(kind)
                }
                .contextMenu {
                    deleteButton(kind)
                }
            }
        }
        #if os(macOS)
        // ⌫ deletes the selected row
        .onDeleteCommand {
            if let selected {
                delete([selected])
            }
        }
        #endif
        .onscreenEntities(Kind.self)
        .accessibilityIdentifier("KindList")
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

    // Add trails, as on the Items list
    @ToolbarContentBuilder
    private var header: some ToolbarContent {
        // Shown only once another device has changed something, leaving the title room on iPad
        if viewModel.canRefresh {
            ToolbarItem(placement: .leadingButtons) {
                Button {
                    viewModel.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                presentAddKindView = true
            } label: {
                Label("Add a category", systemImage: "plus")
            }
        }
    }

    private func deleteButton(_ kind: Kind) -> some View {
        Button(role: .destructive) {
            delete([kind])
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func delete(_ kindsToDelete: [Kind]) {
        withAnimation {
            if let selected, kindsToDelete.contains(selected) {
                self.selected = nil
            }
            viewModel.delete(kindsToDelete) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
