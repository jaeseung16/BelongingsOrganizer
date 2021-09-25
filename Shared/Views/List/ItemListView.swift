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
                            NavigationLink(item.name ?? "", destination: ItemDetailView(item: item,
                                                                                        imageData: item.image,
                                                                                        name: item.name ?? "",
                                                                                        quantity: item.quantity,
                                                                                        buyPrice: item.buyPrice,
                                                                                        sellPrice: item.sellPrice,
                                                                                        buyCurrency: item.buyCurrency ?? "USD",
                                                                                        sellCurrency: item.sellCurrency ?? "USD",
                                                                                        note: item.note ?? "",
                                                                                        obtained: item.obtained ?? Date(),
                                                                                        disposed: item.disposed ?? Date()))
                                .environment(\.managedObjectContext, viewContext)
                                .environmentObject(viewModel)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .sheet(isPresented: $presentAddItemView, content: {
                        AddItemView(geometry: geometry)
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(AddItemViewModel())
                            .frame(minWidth: 350, minHeight: 550)
                            .padding()
                    })
                    .sheet(isPresented: $presentFilterItemsView, content: {
                        FilterItemsView(selectedKinds: $selectedKinds, selectedBrands: $selectedBrands, selectedSellers: $selectedSellers)
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(viewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Items")
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                presentFilterItemsView = true
            }) {
                Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
            }
            
            Button(action: {
                presentAddItemView = true
            }) {
                Label("Add", systemImage: "plus")
            }
        }
        .scaledToFit()
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredItems[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ItemListView_Previews: PreviewProvider {
    static var previews: some View {
        ItemListView()
    }
}
