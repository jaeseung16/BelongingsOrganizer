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
    
    @State private var filteredSellers = [Seller]()
    
    @State var selectedSeller: Seller?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                VStack {
                    header()
                    
                    List(selection: $selectedSeller) {
                        ForEach(filteredSellers, id: \.self) { seller in
                            NavigationLink(value: seller) {
                                SellerRowView(name: seller.name ?? "",
                                              itemCount: viewModel.getItemCount(seller))
                                    .id(UUID())
                            }
                        }
                        .onDelete(perform: deleteSellers)
                    }
                    .navigationTitle("Sellers")
                }
            } detail: {
                if let seller = selectedSeller {
                    SellerDetailView(seller: seller,
                                     name: seller.name ?? "",
                                     urlString: seller.url?.absoluteString ?? "",
                                     items: viewModel.getItems(seller))
                    .id(UUID())
                } else {
                    Text("Sellect a seller")
                }
            }
        }
        .onReceive(viewModel.$sellers) { _ in
            filteredSellers = viewModel.filteredSellers
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .onReceive(viewModel.$stringToSearch) { _ in
            filteredSellers = viewModel.filteredSellers
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
            Button {
                presentAddSelleriew = true
            } label: {
                Label("Add a seller", systemImage: "plus")
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

