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
    
    @State var brands = [Brand]()
    
    var body: some View {
        NavigationView {
            VStack {
                header()
                
                brandListView()
                .sheet(isPresented: $presentAddBrandView, content: {
                    AddBrandView()
                        .environmentObject(viewModel)
                        .frame(minWidth: 350, minHeight: 450)
                        .padding()
                })
            }
            .navigationTitle("Brands")
        }
        .onChange(of: viewModel.brands) { _ in
            brands = viewModel.filteredBrands
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .onChange(of: viewModel.stringToSearch) { _ in
            brands = viewModel.filteredBrands
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
    
    private func header() -> some View {
        HStack {
            Button(action: {
                viewModel.persistenceHelper.reset()
                presentAddBrandView = true
            }) {
                Label("Add a brand", systemImage: "plus")
            }
        }
    }
    
    private func brandListView() -> some View {
        List {
            ForEach(brands) { brand in
                NavigationLink {
                    BrandDetailView(brand: brand, name: brand.name ?? "", urlString: brand.url?.absoluteString ?? "", items: viewModel.getItems(brand))
                } label: {
                    BrandRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                }
            }
            .onDelete(perform: deleteBrands)
        }
        .id(UUID())
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { brands[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

