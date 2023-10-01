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
    @State var selectedSeller: Seller?
    
    private var sellers: [Seller] {
        return viewModel.filteredSellers
    }
    
    var body: some View {
        VStack {
            sellerListView()
            .sheet(isPresented: $presentAddSelleriew) {
                AddSellerView()
                    .environmentObject(viewModel)
                    .frame(minWidth: 350, minHeight: 450)
                    .padding()
            }
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Failed to delete the selected seller")
        }
    }
    
    private func header() -> ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                viewModel.persistenceHelper.reset()
                presentAddSelleriew = true
            } label: {
                Label("Add a seller", systemImage: "plus")
            }
        }
    }
    
    private func sellerListView() -> some View {
        NavigationSplitView {
            VStack {
                List(selection: $selectedSeller) {
                    ForEach(sellers) { seller in
                        NavigationLink(value: seller) {
                            BrandKindSellerRowView(name: seller.name ?? "", itemCount: viewModel.getItemCount(seller))
                        }
                    }
                    .onDelete(perform: deleteSellers)
                }
                .navigationTitle("Sellers")
                .toolbar {
                    header()
                }
            }
            .refreshable {
                viewModel.fetchEntities()
            }
        } detail: {
            if let seller = selectedSeller {
                SellerDetailView(seller: seller, name: seller.name ?? "", urlString: seller.url?.absoluteString ?? "", items: viewModel.getItems(seller))
                    .environmentObject(viewModel)
                    .id(UUID())
                    .navigationBarTitleDisplayMode(.inline)
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

