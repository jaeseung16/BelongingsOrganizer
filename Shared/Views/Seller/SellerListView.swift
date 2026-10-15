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
    // The split view's search field; the tab root searches in its Search tab
    var search = ""
    @Binding var selected: Seller?

    private var sellers: [Seller] {
        return viewModel.sellers(matching: search)
    }

    var body: some View {
        List(selection: $selected) {
            ForEach(sellers) { seller in
                NavigationLink(value: seller) {
                    BrandKindSellerRowView(name: seller.name ?? "", itemCount: viewModel.getItemCount(seller))
                }
            }
            .onDelete(perform: deleteSellers)
        }
        .onscreenEntities(Seller.self)
        .accessibilityIdentifier("SellerList")
        .navigationTitle("Sellers")
        .toolbar {
            header
        }
        .refreshable {
            viewModel.fetchEntities()
        }
        .sheet(isPresented: $presentAddSelleriew) {
            AddSellerView()
                .environmentObject(viewModel)
                .modifier(SheetModifier())
        }
        .alert("Failed to delete", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Unable to delete the selected seller")
        }
    }

    // Add trails, as on the Items list
    @ToolbarContentBuilder
    private var header: some ToolbarContent {
        // Shown only once another device has changed something, leaving the title room on iPad
        if viewModel.canRefresh {
            ToolbarItem(placement: .leadingButtons) {
                Button {
                    viewModel.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                presentAddSelleriew = true
            } label: {
                Label("Add a seller", systemImage: "plus")
            }
        }
    }

    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            let sellersToDelete = offsets.map { sellers[$0] }
            if let selected, sellersToDelete.contains(selected) {
                self.selected = nil
            }
            viewModel.delete(sellersToDelete) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
