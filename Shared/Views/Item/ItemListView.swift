//
//  ItemListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

enum ItemDisposition {
    case active
    case disposed
}

struct ItemListView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    var disposition = ItemDisposition.active
    // The split view's search field; the tab root searches in its Search tab
    var search = ""

    @State var presentAddItemView = false
    @State var presentFilterItemsView = false
    @State var presentSortItemView = false

    @State var selectedKinds = Set<Kind>()
    @State var selectedBrands = Set<Brand>()
    @State var selectedSellers = Set<Seller>()

    @State private var showAlertForDeletion = false

    @State private var sortType = SortType.lastupd
    @State private var sortDirection = SortDirection.descending

    @Binding var selected: Item?

    // Recomputed only when one of these changes, or when the items do
    private struct Query: Equatable {
        var disposition: ItemDisposition
        var search: String
        var kinds: Set<Kind>
        var brands: Set<Brand>
        var sellers: Set<Seller>
        var sortType: SortType
        var sortDirection: SortDirection
    }

    private var query: Query {
        Query(disposition: disposition, search: search, kinds: selectedKinds, brands: selectedBrands,
              sellers: selectedSellers, sortType: sortType, sortDirection: sortDirection)
    }

    @State private var filteredItems = [Item]()

    private func updateFilteredItems() {
        filteredItems = PerformanceSignposts.measure("filterItems") {
            viewModel.fetchItems(disposition, matching: search, kinds: selectedKinds, brands: selectedBrands, sellers: selectedSellers,
                                 sortType: sortType, sortDirection: sortDirection)
        }
    }

    var body: some View {
        List(selection: $selected) {
            ForEach(filteredItems, id: \.self) { item in
                NavigationLink(value: item) {
                    ItemRowView(item: item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    rowActions(item)
                }
                .contextMenu {
                    rowActions(item)
                }
            }
        }
        #if os(macOS)
        // ⌫ deletes the selected row
        .onDeleteCommand {
            if let selected {
                delete(selected)
            }
        }
        #endif
        .onChange(of: query, initial: true) {
            updateFilteredItems()
        }
        .onChange(of: viewModel.itemsGeneration) {
            updateFilteredItems()
        }
        // Deletions are pruned from items without a refetch
        .onChange(of: viewModel.items) {
            updateFilteredItems()
        }
        .onscreenEntities(Item.self)
        .accessibilityIdentifier(disposition == .active ? "ItemList" : "DisposedItemList")
        .navigationTitle(disposition == .active ? "Items" : "Disposed")
        .toolbar {
            header
        }
        .refreshable {
            viewModel.fetchEntities()
        }
        .sheet(isPresented: $presentAddItemView) {
            AddItemView()
                .environmentObject(viewModel)
                .modifier(SheetModifier())
        }
        .sheet(isPresented: $presentFilterItemsView) {
            FilterItemsView(selectedKinds: $selectedKinds, selectedBrands: $selectedBrands, selectedSellers: $selectedSellers)
                .environmentObject(viewModel)
                .modifier(SheetModifier())
        }
        .sheet(isPresented: $presentSortItemView) {
            SortItemsView(sortType: $sortType, sortDirection: $sortDirection)
                .environmentObject(viewModel)
                .modifier(SheetModifier())
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Failed to delete the selected item")
        }
    }

    // Filter and Sort trail as one glass group, with Add set apart; Disposed has no Add
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

        ToolbarItemGroup(placement: .primaryAction) {
            Button  {
                presentFilterItemsView = true
            } label: {
                Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
            }

            Button {
                presentSortItemView = true
            } label: {
                Label("Sort", systemImage: "list.number")
            }
        }

        if disposition == .active {
            ToolbarSpacer(.fixed, placement: .primaryAction)

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.persistenceHelper.reset()
                    presentAddItemView = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }

    @ViewBuilder
    private func rowActions(_ item: Item) -> some View {
        Button(role: .destructive) {
            delete(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }

        if disposition == .active {
            Button {
                viewModel.updateDisposed(item, to: Date())
            } label: {
                Label("Dispose", systemImage: "archivebox")
            }
            .tint(.orange)
        } else {
            Button {
                viewModel.updateDisposed(item, to: nil)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
        }
    }

    private func delete(_ item: Item) {
        withAnimation {
            if selected == item {
                selected = nil
            }
            viewModel.delete([item]) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
