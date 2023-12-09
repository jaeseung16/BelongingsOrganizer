//
//  ContentView.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State private var selectedMenu: SidebarItem? = .items
    
    @State private var selectedItem: Item?
    @State private var selectedKind: Kind?
    @State private var selectedBrand: Brand?
    @State private var selectedSeller: Seller?
    
    @State private var statsType = StatsType.obtained
    @State private var start = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())!
    @State private var end = Date()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMenu) {
                ForEach(SidebarItem.allCases) { menuItem in
                    switch menuItem {
                    case .items:
                        Label(
                            title: { Text("Items") },
                            icon: { Image(systemName: "gift.fill") }
                        )
                    case .categories:
                        Label(
                            title: { Text("Categories") },
                            icon: { Image(systemName: "list.dash") }
                        )
                    case .brands:
                        Label(
                            title: { Text("Brands") },
                            icon: { Image(systemName: "r.circle") }
                        )
                    case .sellers:
                        Label(
                            title: { Text("Sellers") },
                            icon: { Image(systemName: "shippingbox.fill") }
                        )
                    case .stats:
                        Label(
                            title: { Text("Stats") },
                            icon: { Image(systemName: "chart.xyaxis.line") }
                        )
                    }
                }
            }
        } content: {
            switch selectedMenu {
            case .none, .some(.items):
                ItemListView(selected: $selectedItem)
            case .some(.categories):
                KindListView(selected: $selectedKind)
            case .some(.brands):
                BrandListView(selected: $selectedBrand)
            case .some(.sellers):
                SellerListView(selected: $selectedSeller)
            case .some(.stats):
                StatsView(statsType: $statsType, start: $start, end: $end)
            }
        } detail: {
            switch selectedMenu {
            case .none:
                EmptyView()
            case .some(.items):
                if let item = selectedItem {
                    ItemDetailView(item: item, dto: ItemDTO.create(from: item))
                        .environmentObject(viewModel)
                        .id(item)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                } else {
                    EmptyView()
                }
            case .some(.categories):
                if let kind = selectedKind {
                    KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                        .environmentObject(viewModel)
                        .id(kind)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                } else {
                    EmptyView()
                }
            case .some(.brands):
                if let brand = selectedBrand {
                    BrandDetailView(brand: brand, name: brand.name ?? "", urlString: brand.url?.absoluteString ?? "", items: viewModel.getItems(brand))
                        .environmentObject(viewModel)
                        .id(brand)
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                } else {
                    EmptyView()
                }
            case .some(.sellers):
                if let seller = selectedSeller {
                    SellerDetailView(seller: seller, name: seller.name ?? "", urlString: seller.url?.absoluteString ?? "", items: viewModel.getItems(seller))
                        .environmentObject(viewModel)
                        .id(seller)
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                } else {
                    EmptyView()
                }
            case .some(.stats):
                StatsDetailView(statsType: $statsType, start: $start, end: $end)
                    .environmentObject(viewModel)
            }
            
        }
        .searchable(text: $viewModel.stringToSearch)
        .alert("Unable to save data", isPresented: $viewModel.showAlert) {
            Button("Dismiss") {
            }
        } message: {
            Text(viewModel.message)
        }
    }
}
