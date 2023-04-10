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

    @State var selectedKinds = Set<KindDTO>()
    @State var selectedBrands = Set<BrandDTO>()
    @State var selectedSellers = Set<SellerDTO>()
    
    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    @State private var sortType = SortType.lastupd
    @State private var sortDirection = SortDirection.descending
    
    @State var items: [ItemDTO] {
        didSet {
            filteredItems = filter(items)
        }
    }
    
    @State var filteredItems = [ItemDTO]()
    
    private func filter(_ items: [ItemDTO]) -> [ItemDTO] {
        items.filter {
            var filter = true
            
            if let kinds = $0.kinds, !selectedKinds.isEmpty && selectedKinds.intersection(kinds).isEmpty {
                filter = false
            }
            
            if let brands = $0.brands, !selectedBrands.isEmpty && selectedBrands.intersection(brands).isEmpty {
                filter = false
            }
            
            if let sellers = $0.sellers, !selectedSellers.isEmpty && selectedSellers.intersection(sellers).isEmpty {
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
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                        .frame(width: geometry.size.width)
                    
                    Divider()
                    
                    itemListView()
                        .sheet(isPresented: $presentAddItemView) {
                            AddItemView(geometry: geometry)
                                .environmentObject(viewModel)
                                .frame(minWidth: 350, minHeight: 550)
                                .padding()
                        }
                }
                .navigationTitle("Items")
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
        .onReceive(viewModel.$stringToSearch) { _ in
            filteredItems = filter(items)
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
                viewModel.addItemViewModel.reset()
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
                                                               quantity: Int(item.quantity ?? 0),
                                                               buyPrice: item.buyPrice ?? 0.0,
                                                               sellPrice: item.sellPrice ?? 0.0,
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
            viewModel.delete(offsets.compactMap {
                if let id = filteredItems[$0].id {
                    return viewModel.get(entity: .Item, id: id)
                } else {
                    return nil
                }
            }) { error in
                if error != nil {
                    showAlertForDeletion.toggle()
                } else {
                    viewModel.fetchItems()
                }
            }
        }
    }
}
