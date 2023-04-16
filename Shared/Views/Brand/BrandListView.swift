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
    
    @State var brands: [Brand]
    
    private var filteredBrands: [Brand] {
        brands.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
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
        }
        .onReceive(viewModel.$updated) { _ in
            brands = viewModel.brands
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
            ForEach(filteredBrands) { brand in
                NavigationLink {
                    BrandDetailView(brand: brand, name: brand.name ?? "", urlString: brand.url?.absoluteString ?? "", items: viewModel.getItems(brand))
                        .id(UUID())
                } label: {
                    BrandRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                        .id(UUID())
                }
            }
            .onDelete(perform: deleteBrands)
        }
        .id(UUID())
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredBrands[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

