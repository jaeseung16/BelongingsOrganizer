//
//  ContentView.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI
import CoreData

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
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Items")
                }
            
            KindListView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Categories")
                }
            
            BrandListView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "r.circle")
                    Text("Brands")
                }
            
            SellerListView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("Sellers")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
