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
    
    @State var sellers: [SellerDTO] {
        didSet {
            filteredSellers = sellers.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
            print("filtered sellers=\(filteredSellers)")
        }
    }
    
    @State var filteredSellers = [SellerDTO]()
    @State var selectedSeller: SellerDTO?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    sellerListView()
                    .sheet(isPresented: $presentAddSelleriew, content: {
                        AddSellerView()
                            .environmentObject(viewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Seller")
            }
        }
        .onChange(of: viewModel.sellers) { _ in
            sellers = viewModel.sellers
        }
        .onReceive(viewModel.$stringToSearch) { _ in
            filteredSellers = sellers.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
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
    
    private func header() -> some View {
        HStack {
            Button(action: {
                viewModel.addItemViewModel.reset()
                presentAddSelleriew = true
            }) {
                Label("Add a seller", systemImage: "plus")
            }
        }
    }
    
    private func sellerListView() -> some View {
        List {
            ForEach(filteredSellers) { seller in
                if let sellerName = seller.name {
                    NavigationLink(destination: SellerDetailView(seller: seller,
                                                                 name: sellerName,
                                                                 urlString: seller.url?.absoluteString ?? "",
                                                                 items: getItems(seller))) {
                        SellerRowView(seller: seller)
                    }
                }
            }
            .onDelete(perform: deleteSellers)
        }
        .id(UUID())
    }
    
    private func getItems(_ seller: SellerDTO) -> [Item] {
        return viewModel.items
            .filter { item in
                if let sellerSet = item.seller {
                    let matchedSeller = sellerSet.filter { element in
                        if let sellerEntity = element as? Seller, sellerEntity.uuid == seller.id {
                            return true
                        } else {
                            return false
                        }
                    }
                    return !matchedSeller.isEmpty
                } else {
                    return false
                }
            }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.compactMap {
                if let id = filteredSellers[$0].id {
                    return viewModel.get(entity: .Seller, id: id)
                } else {
                    return nil
                }
            }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

