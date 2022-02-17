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
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.lastupd, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        TabView {
            ItemListView()
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Items")
                }
            
            KindListView()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Categories")
                }
            
            BrandListView()
                .tabItem {
                    Image(systemName: "r.circle")
                    Text("Brands")
                }
            
            SellerListView()
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("Sellers")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
