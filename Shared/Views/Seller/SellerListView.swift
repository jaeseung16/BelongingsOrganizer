//
//  SellerListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct SellerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State var presentAddSelleriew = false

    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    var filteredSellers: Array<Seller> {
        viewModel.sellers.filter { seller in
            if viewModel.stringToSearch == "" {
                return true
            } else if let name = seller.name {
                return name.lowercased().contains(viewModel.stringToSearch.lowercased())
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    sellerListView()
                    .sheet(isPresented: $presentAddSelleriew, content: {
                        AddSellerView()
                            .environmentObject(viewModel.addItemViewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Seller")
            }
        }
        .onChange(of: viewModel.addItemViewModel.showAlert) { _ in
            showAlert = viewModel.addItemViewModel.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(viewModel.addItemViewModel.message)
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
                        SellerRowView(seller: seller, name: sellerName)
                    }
                }
            }
            .onDelete(perform: deleteSellers)
        }
    }
    
    private func getItems(_ seller: Seller) -> [Item] {
        guard let items = seller.items else {
            return [Item]()
        }
        
        return items.compactMap { $0 as? Item }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
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

struct SellerListView_Previews: PreviewProvider {
    static var previews: some View {
        SellerListView()
    }
}
