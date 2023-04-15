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
    
    @State var sellers: [Seller] {
        didSet {
            filteredSellers =  sellers.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
        }
    }
    
    @State var filteredSellers = [Seller]()
    @State var selectedSeller: Seller?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                VStack {
                    header()
                    
                    List(selection: $selectedSeller) {
                        ForEach(filteredSellers, id: \.self) { seller in
                            if let sellerName = seller.name {
                                NavigationLink(value: seller) {
                                    SellerRowView(name: sellerName, itemCount: viewModel.getItemCount(seller))
                                }
                            }
                        }
                        .onDelete(perform: deleteSellers)
                    }
                    .navigationTitle("Sellers")
                    .id(UUID())
                }
            } detail: {
                if let seller = selectedSeller, let name = seller.name {
                    SellerDetailView(seller: seller,
                                     name: name,
                                     urlString: seller.url?.absoluteString ?? "",
                                     items: viewModel.getItems(seller))
                    .id(UUID())
                } else {
                    Text("Sellect a seller")
                }
            }
        }
        .onReceive(viewModel.$updated) { _ in
            sellers = viewModel.sellers
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .onChange(of: viewModel.stringToSearch) { _ in
            filteredSellers = sellers.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
        }
        .sheet(isPresented: $presentAddSelleriew, content: {
            AddSellerView()
                .environmentObject(viewModel)
                .frame(minWidth: 350, minHeight: 450)
                .padding()
        })
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
    
    private func header() -> some View {
        HStack {
            Button(action: {
                viewModel.persistenceHelper.reset()
                presentAddSelleriew = true
            }) {
                Label("Add a seller", systemImage: "plus")
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
            viewModel.delete(offsets.map { filteredSellers[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

