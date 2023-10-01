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
    
    @State private var selectedBrand: Brand?
    
    var brands: [Brand] {
        return viewModel.filteredBrands
    }
    
    var body: some View {
        VStack {
            brandListView()
            .sheet(isPresented: $presentAddBrandView) {
                AddBrandView()
                    .environmentObject(viewModel)
                    .frame(minWidth: 350, minHeight: 450)
                    .padding()
            }
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
                showAlertForDeletion.toggle()
            }
        } message: {
            Text("Failed to delete the selected brand")
        }
    }
    
    private func header() -> ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button{
                viewModel.persistenceHelper.reset()
                presentAddBrandView = true
            } label: {
                Label("Add a brand", systemImage: "plus")
            }
        }
    }
    
    private func brandListView() -> some View {
        NavigationSplitView {
            VStack {
                List(selection: $selectedBrand) {
                    ForEach(brands) { brand in
                        NavigationLink(value: brand) {
                            BrandKindSellerRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                        }
                    }
                    .onDelete(perform: deleteBrands)
                }
                .navigationTitle("Brands")
                .toolbar {
                    header()
                }
            }
            .refreshable {
                viewModel.fetchEntities()
            }
        } detail: {
            if let brand = selectedBrand {
                BrandDetailView(brand: brand, name: brand.name ?? "", urlString: brand.url?.absoluteString ?? "", items: viewModel.getItems(brand))
                    .environmentObject(viewModel)
                    .id(UUID())
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { brands[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

