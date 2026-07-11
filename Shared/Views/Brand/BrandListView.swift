//
//  BrandListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct BrandListView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State var presentAddBrandView = false
    @State private var showAlertForDeletion = false
    @Binding var selected: Brand?

    var brands: [Brand] {
        return viewModel.filteredBrands
    }

    var body: some View {
        List(selection: $selected) {
            ForEach(brands) { brand in
                NavigationLink(value: brand) {
                    BrandKindSellerRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                }
            }
            .onDelete(perform: deleteBrands)
        }
        .navigationTitle("Brands")
        .toolbar {
            header
        }
        .refreshable {
            viewModel.fetchEntities()
        }
        .sheet(isPresented: $presentAddBrandView) {
            AddBrandView()
                .environmentObject(viewModel)
                .modifier(SheetModifier())
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
                showAlertForDeletion.toggle()
            }
        } message: {
            Text("Failed to delete the selected brand")
        }
    }

    private var header: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .leadingButtons) {
            Button{
                presentAddBrandView = true
            } label: {
                Label("Add a brand", systemImage: "plus")
            }
        }
    }

    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            let brandsToDelete = offsets.map { brands[$0] }
            if let selected, brandsToDelete.contains(selected) {
                self.selected = nil
            }
            viewModel.delete(brandsToDelete) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
