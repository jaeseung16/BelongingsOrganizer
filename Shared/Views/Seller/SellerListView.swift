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
    @Binding var selected: Seller?
    
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
        VStack {
            List(selection: $selected) {
                ForEach(sellers) { seller in
                    NavigationLink(value: seller) {
                        BrandKindSellerRowView(name: seller.name ?? "", itemCount: viewModel.getItemCount(seller))
                    }
                }
                .onDelete(perform: deleteSellers)
            }
            .toolbar {
                header
            }
        }
        .refreshable {
            viewModel.fetchEntities()
        }
    }
    
    private var header: ToolbarItemGroup<some View> {
        #if os(macOS)
        ToolbarItemGroup() {
            Button {
                presentAddSelleriew = true
            } label: {
                Label("Add a seller", systemImage: "plus")
            }
        }
        #else
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                presentAddSelleriew = true
            } label: {
                Label("Add a seller", systemImage: "plus")
            }
        }
        #endif
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { sellers[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

