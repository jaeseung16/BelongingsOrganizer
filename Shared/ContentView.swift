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

    var body: some View {
        TabView {
            ItemListView(items: viewModel.items)
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Items")
                }
            
            KindListView(kinds: viewModel.kinds)
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Categories")
                }
            
            BrandListView(brands: viewModel.brands)
                .tabItem {
                    Image(systemName: "r.circle")
                    Text("Brands")
                }
            
            SellerListView(sellers: viewModel.sellers)
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("Sellers")
                }
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Stats")
                }
            
        }
        .searchable(text: $viewModel.stringToSearch)
        .alert("Unable to save data", isPresented: $viewModel.showAlert) {
            Button("Dismiss") {
            }
        } message: {
            Text("viewModel.message")
        }
    }
}
