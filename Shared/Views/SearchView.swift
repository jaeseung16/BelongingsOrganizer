//
//  SearchView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/14/26.
//

import SwiftUI
import CoreData

// What the Search tab pushes onto its stack
enum SearchResult: Hashable {
    case item(Item)
    case kind(Kind)
    case brand(Brand)
    case seller(Seller)

    var object: NSManagedObject {
        switch self {
        case .item(let item):
            return item
        case .kind(let kind):
            return kind
        case .brand(let brand):
            return brand
        case .seller(let seller):
            return seller
        }
    }
}

// The Search tab: items (disposed ones too), categories, brands, and sellers whose names contain
// the search string
struct SearchView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State private var items = [Item]()

    private var search: String {
        viewModel.stringToSearch
    }

    private var kinds: [Kind] {
        search.isEmpty ? [] : viewModel.kinds(matching: search)
    }

    private var brands: [Brand] {
        search.isEmpty ? [] : viewModel.brands(matching: search)
    }

    private var sellers: [Seller] {
        search.isEmpty ? [] : viewModel.sellers(matching: search)
    }

    private func updateItems() {
        items = PerformanceSignposts.measure("searchItems") {
            viewModel.searchItems(matching: search)
        }
    }

    var body: some View {
        let kinds = self.kinds
        let brands = self.brands
        let sellers = self.sellers

        List {
            if !items.isEmpty {
                Section("Items") {
                    ForEach(items, id: \.self) { item in
                        NavigationLink(value: SearchResult.item(item)) {
                            ItemRowView(item: item)
                        }
                        .badge(item.disposed == nil ? nil : Text("Disposed"))
                    }
                }
            }

            if !kinds.isEmpty {
                Section("Categories") {
                    ForEach(kinds) { kind in
                        NavigationLink(value: SearchResult.kind(kind)) {
                            BrandKindSellerRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                        }
                    }
                }
            }

            if !brands.isEmpty {
                Section("Brands") {
                    ForEach(brands) { brand in
                        NavigationLink(value: SearchResult.brand(brand)) {
                            BrandKindSellerRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                        }
                    }
                }
            }

            if !sellers.isEmpty {
                Section("Sellers") {
                    ForEach(sellers) { seller in
                        NavigationLink(value: SearchResult.seller(seller)) {
                            BrandKindSellerRowView(name: seller.name ?? "", itemCount: viewModel.getItemCount(seller))
                        }
                    }
                }
            }
        }
        .overlay {
            if search.isEmpty {
                ContentUnavailableView("Search Belongings", systemImage: "magnifyingglass",
                                       description: Text("Find items, categories, brands, and sellers by name."))
            } else if items.isEmpty && kinds.isEmpty && brands.isEmpty && sellers.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
        .onChange(of: search, initial: true) {
            updateItems()
        }
        .onChange(of: viewModel.itemsGeneration) {
            updateItems()
        }
        // Deletions are pruned from items without a refetch
        .onChange(of: viewModel.items) {
            updateItems()
        }
        .accessibilityIdentifier("SearchResults")
        .navigationTitle("Search")
    }
}
