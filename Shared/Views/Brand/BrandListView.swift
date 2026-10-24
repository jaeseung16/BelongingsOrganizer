//
//  BrandListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct BrandListView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State var presentAddBrandView = false
    @State private var showAlertForDeletion = false
    // The split view's search field; the tab root searches in its Search tab
    var search = ""
    @Binding var selected: Brand?

    var brands: [Brand] {
        return viewModel.brands(matching: search)
    }

    var body: some View {
        List(selection: $selected) {
            ForEach(brands) { brand in
                NavigationLink(value: brand) {
                    BrandKindSellerRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    deleteButton(brand)
                }
                .contextMenu {
                    deleteButton(brand)
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
        .onscreenEntities(Brand.self)
        .accessibilityIdentifier("BrandList")
        .navigationTitle("Brands")
        .toolbar {
            header
        }
        .refreshable {
            viewModel.fetchEntities()
        }
        .sheet(isPresented: $presentAddBrandView) {
            AddBrandView()
                .environmentObject(viewModel)
                .modifier(SheetModifier())
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
                showAlertForDeletion.toggle()
            }
        } message: {
            Text("Failed to delete the selected brand")
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
                presentAddBrandView = true
            } label: {
                Label("Add a brand", systemImage: "plus")
            }
        }
    }

    private func deleteButton(_ brand: Brand) -> some View {
        Button(role: .destructive) {
            delete([brand])
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func delete(_ brandsToDelete: [Brand]) {
        withAnimation {
            if let selected, brandsToDelete.contains(selected) {
                self.selected = nil
            }
            viewModel.delete(brandsToDelete) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
