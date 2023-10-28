//
//  ItemListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct ItemListView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var presentAddItemView = false
    @State var presentFilterItemsView = false
    @State var presentSortItemView = false

    @State var selectedKinds = Set<Kind>()
    @State var selectedBrands = Set<Brand>()
    @State var selectedSellers = Set<Seller>()
    
    @State private var showAlertForDeletion = false
    
    @State private var sortType = SortType.lastupd
    @State private var sortDirection = SortDirection.descending
    
    @State private var selected: Item?
    
    var filteredItems: [Item] {
        viewModel.items.filter {
            var filter = true
            
            if let kind = $0.kind as? Set<Kind>, !selectedKinds.isEmpty && selectedKinds.intersection(kind).isEmpty {
                filter = false
            }
            
            if let brand = $0.brand as? Set<Brand>, !selectedBrands.isEmpty && selectedBrands.intersection(brand).isEmpty {
                filter = false
            }
            
            if let seller = $0.seller as? Set<Seller>, !selectedSellers.isEmpty && selectedSellers.intersection(seller).isEmpty {
                filter = false
            }
            
            if let name = $0.name {
                filter = viewModel.checkIfStringToSearchContainedIn(name)
            } else {
                filter = false
            }
            
            return filter
        }
        .sorted {
            switch sortType {
            case .lastupd:
                if let lastupd1 = $0.lastupd, let lastupd2 = $1.lastupd {
                    return sortDirection == .ascending ? lastupd1 < lastupd2 : lastupd2 < lastupd1
                } else {
                    return false
                }
            case .obtained:
                if let obtained1 = $0.obtained, let obtained2 = $1.obtained {
                    return sortDirection == .ascending ? obtained1 < obtained2 : obtained2 < obtained1
                } else {
                    return false
                }
            case .name:
                if let name1 = $0.name, let name2 = $1.name {
                    return sortDirection == .ascending ? name1 < name2 : name2 < name1
                } else {
                    return false
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                VStack {
                    List(selection: $selected) {
                        ForEach(filteredItems) { item in
                            NavigationLink(value: item) {
                                ItemRowView(item: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .navigationTitle("Items")
                    .toolbar {
                        header
                    }
                    
                    #if os(iOS)
                    Spacer()
                    BannerAd()
                        .frame(height: 50)
                    #endif
                }
                .refreshable {
                    viewModel.fetchEntities()
                }
            } detail: {
                if let item = selected {
                    ItemDetailView(item: item, dto: ItemDTO.create(from: item))
                    .environmentObject(viewModel)
                    .id(item)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
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
    
    private var header: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .topBarLeading) {
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
            
            Button {
                viewModel.persistenceHelper.reset()
                presentAddItemView = true
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredItems[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
