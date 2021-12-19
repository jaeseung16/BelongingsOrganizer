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

    @State private var showAlert = false
    
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
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Unable to Save Data"),
                  message: Text(viewModel.message),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
