//
//  SellerListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct SellerListView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State var presentAddSelleriew = false

    @State private var showAlertForDeletion = false
    @State var selected: Seller?
    
    private var sellers: [Seller] {
        return viewModel.filteredSellers
    }
    
    var body: some View {
        VStack {
            sellerList
                .sheet(isPresented: $presentAddSelleriew) {
                    AddSellerView()
                        .environmentObject(viewModel)
                        .modifier(SheetModifier())
            }
        }
        .alert("Failed to delete", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Unable to delete the selected seller")
        }
    }
    
    private var sellerList: some View {
        NavigationSplitView {
            VStack {
                List(selection: $selected) {
                    ForEach(sellers) { seller in
                        NavigationLink(value: seller) {
                            BrandKindSellerRowView(name: seller.name ?? "", itemCount: viewModel.getItemCount(seller))
                        }
                    }
                    .onDelete(perform: deleteSellers)
                }
                .navigationTitle("Sellers")
                .toolbar {
                    header
                }
            }
            .refreshable {
                viewModel.fetchEntities()
            }
        } detail: {
            if let seller = selected {
                SellerDetailView(seller: seller, name: seller.name ?? "", urlString: seller.url?.absoluteString ?? "", items: viewModel.getItems(seller))
                    .environmentObject(viewModel)
                    .id(seller)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        #if os(iOS)
        .id(UUID())
        #endif
    }
    
    private var header: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                presentAddSelleriew = true
            } label: {
                Label("Add a seller", systemImage: "plus")
            }
        }
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { sellers[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

