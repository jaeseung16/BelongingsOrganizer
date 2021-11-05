//
//  ItemListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct ItemListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
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
            
            if let kind = item.kind, !selectedKinds.isEmpty && !selectedKinds.contains(kind) {
                filter = false
            }
            
            if let brand = item.brand, !selectedBrands.isEmpty && !selectedBrands.contains(brand) {
                filter = false
            }
            
            if let seller = item.seller, !selectedSellers.isEmpty && !selectedSellers.contains(seller) {
                filter = false
            }
            
            return filter
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                        .frame(width: geometry.size.width)
                    
                    Divider()
                    
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
                                    HStack {
                                        if let data = item.image {
                                        #if os(macOS)
                                            if let nsImage = NSImage(data: data) {
                                                Image(nsImage: nsImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50)
                                            }
                                        #else
                                            if let uiImage = UIImage(data: data) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50)
                                            }
                                        #endif
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50)
                                        }
                                        
                                        Text(itemName)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .sheet(isPresented: $presentAddItemView, content: {
                        AddItemView(geometry: geometry)
                            .environmentObject(AddItemViewModel.shared)
                            .frame(minWidth: 350, minHeight: 550)
                            .padding()
                    })
                    .sheet(isPresented: $presentFilterItemsView, content: {
                        FilterItemsView(selectedKinds: $selectedKinds, selectedBrands: $selectedBrands, selectedSellers: $selectedSellers)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Items")
            }
        }
        .onChange(of: AddItemViewModel.shared.showAlert) { _ in
            showAlert = AddItemViewModel.shared.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(AddItemViewModel.shared.message)
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
                showAlert.toggle()
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
                AddItemViewModel.shared.reset()
                presentAddItemView = true
            }) {
                Label("Add", systemImage: "plus")
            }
            
            Spacer()
        }
        .scaledToFit()
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredItems[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

struct ItemListView_Previews: PreviewProvider {
    static var previews: some View {
        ItemListView()
    }
}
