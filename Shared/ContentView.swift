//
//  ContentView.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI
import CoreData
#if os(iOS)
import AppTrackingTransparency
import GoogleMobileAds
#endif

struct ContentView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    var body: some View {
        TabView {
            ItemListView(items: viewModel.items)
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Items")
                }
            
            KindListView(kinds: viewModel.filteredKinds)
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Categories")
                }
            
            BrandListView(brands: viewModel.filteredBrands)
                .tabItem {
                    Image(systemName: "r.circle")
                    Text("Brands")
                }
            
            SellerListView(sellers: viewModel.filteredSellers)
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
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            ATTrackingManager.requestTrackingAuthorization { status in
                GADMobileAds.sharedInstance().start(completionHandler: nil)
                
            }
        }
        #endif
    }
}
