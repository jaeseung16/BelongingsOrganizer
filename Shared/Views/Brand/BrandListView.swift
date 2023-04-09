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
    
    @State var brands: [BrandDTO] {
        didSet {
            filteredBrands = brands.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
        }
    }
    
    @State var filteredBrands = [BrandDTO]()
    
    
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
        .onReceive(viewModel.$stringToSearch) { _ in
            filteredBrands = brands.filter { viewModel.checkIfStringToSearchContainedIn($0.name) }
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
                viewModel.addItemViewModel.reset()
                presentAddBrandView = true
            }) {
                Label("Add a brand", systemImage: "plus")
            }
        }
    }
    
    private func brandListView() -> some View {
        List {
            ForEach(filteredBrands) { brand in
                if let brandName = brand.name {
                    NavigationLink(destination: BrandDetailView(brand: brand,
                                                                name: brandName,
                                                                urlString: brand.url?.absoluteString ?? "",
                                                                items: getItems(brand))) {
                        BrandRowView(brand: brand)
                    }
                }
            }
            .onDelete(perform: deleteBrands)
        }
        .id(UUID())
    }
    
    private func getItems(_ brand: BrandDTO) -> [Item] {
        return viewModel.items
            .filter { item in
                if let brandSet = item.brand {
                    let matchedBrand = brandSet.filter { element in
                        if let brandEntity = element as? Brand, brandEntity.uuid == brand.id {
                            return true
                        } else {
                            return false
                        }
                    }
                    return !matchedBrand.isEmpty
                } else {
                    return false
                }
            }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.compactMap {
                if let id = filteredBrands[$0].id {
                    return viewModel.get(entity: .Brand, id: id)
                } else {
                    return nil
                }
            }) { error in
                if error != nil {
                    showAlertForDeletion.toggle()
                } else {
                    viewModel.fetchBrands()
                }
            }
        }
    }
}

