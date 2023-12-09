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
    
    @State private var selectedSidebarItem: SidebarItem? = .items
    
    @State private var selectedItem: Item?
    @State private var selectedKind: Kind?
    @State private var selectedBrand: Brand?
    @State private var selectedSeller: Seller?
    
    @State private var statsType = StatsType.obtained
    @State private var start = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())!
    @State private var end = Date()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
                ForEach(SidebarItem.allCases) { sidebarItem in
                    Label {
                        Text(sidebarItem.rawValue)
                    } icon: {
                        Image(systemName: sidebarItem.imageName)
                    }
                }
            }
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .searchable(text: $viewModel.stringToSearch)
        .alert("Unable to save data", isPresented: $viewModel.showAlert) {
            Button("Dismiss") {
            }
        } message: {
            Text(viewModel.message)
        }
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSidebarItem {
        case nil:
            EmptyView()
        case .items:
            ItemListView(selected: $selectedItem)
        case .categories:
            KindListView(selected: $selectedKind)
        case .brands:
            BrandListView(selected: $selectedBrand)
        case .sellers:
            SellerListView(selected: $selectedSeller)
        case .stats:
            StatsView(statsType: $statsType, start: $start, end: $end)
        }
    }
    
    @ViewBuilder
    private var detailColumn: some View {
        switch selectedSidebarItem {
        case nil:
            EmptyView()
        case .items:
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
        case .categories:
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
        case .brands:
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
        case .sellers:
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
        case .stats:
            StatsDetailView(statsType: $statsType, start: $start, end: $end)
                .environmentObject(viewModel)
        }
    }
}
