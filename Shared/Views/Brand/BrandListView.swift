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

    @State private var showAlert = false
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
                            BrandRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                        }
                    }
                    .onDelete(perform: deleteBrands)
                }
                .navigationTitle("Brands")
                .toolbar {
                    header()
                }
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

