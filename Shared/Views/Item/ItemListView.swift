//
//  ItemListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct ItemListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.lastupd, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State var presentAddItemView = false
    @State var presentFilterItemsView = false

    @State var selectedKinds = Set<Kind>()
    @State var selectedBrands = Set<Brand>()
    @State var selectedSellers = Set<Seller>()
    
    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    var filteredItems: Array<Item> {
        items.filter { item in
            var filter = true
            
            if let kind = item.kind as? Set<Kind>, !selectedKinds.isEmpty && selectedKinds.intersection(kind).isEmpty {
                filter = false
            }
            
            if let brand = item.brand as? Set<Brand>, !selectedBrands.isEmpty && selectedBrands.intersection(brand).isEmpty {
                filter = false
            }
            
            if let seller = item.seller as? Set<Seller>, !selectedSellers.isEmpty && selectedSellers.intersection(seller).isEmpty {
                filter = false
            }
            
            return filter
        }
        .filter { item in
            if viewModel.stringToSearch == "" {
                return true
            } else if let name = item.name {
                return name.lowercased().contains(viewModel.stringToSearch.lowercased())
            } else {
                return false
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
                                .environmentObject(viewModel.addItemViewModel)
                                .frame(minWidth: 350, minHeight: 550)
                                .padding()
                        }
                    
                    #if os(iOS)
                    Spacer()
                    BannerAd()
                        .frame(height: 50)
                    #endif
                }
                .navigationTitle("Items")
            }
        }
        .sheet(isPresented: $presentFilterItemsView) {
            FilterItemsView(selectedKinds: $selectedKinds, selectedBrands: $selectedBrands, selectedSellers: $selectedSellers)
                .frame(minWidth: 350, minHeight: 450)
                .padding()
        }
        .onChange(of: viewModel.addItemViewModel.showAlert) { _ in
            showAlert = viewModel.addItemViewModel.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
            }
        } message: {
            Text(viewModel.addItemViewModel.message)
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
                                                               quantity: Int(item.quantity),
                                                               buyPrice: item.buyPrice,
                                                               sellPrice: item.sellPrice,
                                                               buyCurrency: item.buyCurrency ?? "USD",
                                                               sellCurrency: item.sellCurrency ?? "USD",
                                                               note: item.note ?? "",
                                                               obtained: item.obtained ?? Date(),
                                                               disposed: item.disposed ?? Date())) {
                        ItemRowView(item: item, name: itemName)
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

struct ItemListView_Previews: PreviewProvider {
    static var previews: some View {
        ItemListView()
    }
}
