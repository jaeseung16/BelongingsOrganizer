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
    
    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    @State private var sortType = SortType.lastupd
    @State private var sortDirection = SortDirection.descending
    
    @State var items: [Item]
    
    var filteredItems: [Item] {
        items.filter {
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
            
            return filter
        }
        .filter {
            viewModel.checkIfStringToSearchContainedIn($0.name)
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
    
    @State private var seletedItem: Item?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                VStack {
                    header()
                    
                    List(selection: $seletedItem) {
                        ForEach(filteredItems, id: \.self) { item in
                            NavigationLink(value: item) {
                                ItemRowView(item: item)
                                    .id(UUID())
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .navigationTitle("Items")
                }
            } detail: {
                if let item = seletedItem {
                    ItemDetailView(item: item,
                                   imageData: item.image,
                                   name: item.name ?? "",
                                   quantity: Int(item.quantity),
                                   buyPrice: item.buyPrice,
                                   sellPrice: item.sellPrice,
                                   buyCurrency: item.buyCurrency ?? "USD",
                                   sellCurrency: item.sellCurrency ?? "USD",
                                   note: item.note ?? "",
                                   obtained: item.obtained ?? Date(),
                                   disposed: item.disposed ?? Date())
                    .id(UUID())
                }
            }
        }
        .sheet(isPresented: $presentFilterItemsView) {
            FilterItemsView(selectedKinds: $selectedKinds, selectedBrands: $selectedBrands, selectedSellers: $selectedSellers)
                .frame(minWidth: 350, minHeight: 450)
                .padding()
        }
        .sheet(isPresented: $presentSortItemView) {
            SortItemsView(sortType: $sortType, sortDirection: $sortDirection)
                .frame(minWidth: 350, minHeight: 100)
                .padding()
        }
        .onChange(of: viewModel.items) { _ in
            items = viewModel.items
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
            }
        } message: {
            Text(viewModel.message)
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Failed to delete the selected item")
        }
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button(action: {
                presentFilterItemsView = true
            }) {
                Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
            }
            
            Spacer()
            
            Button(action: {
                presentSortItemView = true
            }) {
                Label("Sort", systemImage: "list.number")
            }
            
            Spacer()
            
            Button(action: {
                viewModel.persistenceHelper.reset()
                presentAddItemView = true
            }) {
                Label("Add", systemImage: "plus")
            }
            
            Spacer()
        }
        .scaledToFit()
    }
    
    private func itemListView() -> some View {
        List {
            ForEach(filteredItems) { item in
                if let itemName = item.name {
                    NavigationLink(destination: ItemDetailView(item: item,
                                                               imageData: item.image,
                                                               name: itemName,
                                                               quantity: Int(item.quantity),
                                                               buyPrice: item.buyPrice,
                                                               sellPrice: item.sellPrice,
                                                               buyCurrency: item.buyCurrency ?? "USD",
                                                               sellCurrency: item.sellCurrency ?? "USD",
                                                               note: item.note ?? "",
                                                               obtained: item.obtained ?? Date(),
                                                               disposed: item.disposed ?? Date())) {
                        ItemRowView(item: item)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredItems[$0] }) { _ in
                showAlert.toggle()
            }
        }
    }
}
