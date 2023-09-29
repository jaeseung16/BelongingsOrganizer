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

    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    var sellers: [Seller] {
        return viewModel.filteredSellers
    }
    
    @State var selectedSeller: Seller?
    
    var body: some View {
        VStack {
            sellerListView()
            .sheet(isPresented: $presentAddSelleriew, content: {
                AddSellerView()
                    .environmentObject(viewModel)
                    .frame(minWidth: 350, minHeight: 450)
                    .padding()
            })
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(viewModel.message)
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
                showAlert.toggle()
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
                            SellerRowView(name: seller.name ?? "", itemCount: viewModel.getItemCount(seller))
                        }
                    }
                    .onDelete(perform: deleteSellers)
                }
                .navigationTitle("Sellers")
                .toolbar {
                    header()
                }
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
    
    private func sellerRowView(_ seller: Seller, name: String) -> some View {
        HStack {
            Text(name)
            
            Spacer()
            
            if let items = seller.items {
                Text("\(items.count) items")
                    .font(.callout)
                    .foregroundColor(.secondary)
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

