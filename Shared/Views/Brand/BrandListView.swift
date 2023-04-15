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
    
    @State private var filteredBrands = [Brand]()
    @State private var selectedBrand: Brand?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                VStack {
                    header()
                    
                    List(selection: $selectedBrand) {
                        ForEach(filteredBrands, id: \.self) { brand in
                            NavigationLink(value: brand) {
                                BrandRowView(name: brand.name ?? "",
                                             itemCount: viewModel.getItemCount(brand))
                                .id(UUID())
                            }
                        }
                        .onDelete(perform: deleteBrands)
                    }
                    .navigationTitle("Brands")
                }
                
            } detail: {
                if let brand = selectedBrand {
                    BrandDetailView(brand: brand,
                                    name: brand.name ?? "",
                                    urlString: brand.url?.absoluteString ?? "",
                                    items: viewModel.getItems(brand))
                    .id(UUID())
                } else {
                    Text("Sellect a seller")
                }
            }
        }
        .onReceive(viewModel.$brands) { _ in
            filteredBrands = viewModel.filteredBrands
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .onReceive(viewModel.$stringToSearch) { _ in
            filteredBrands = viewModel.filteredBrands
        }
        .sheet(isPresented: $presentAddBrandView, content: {
            AddBrandView()
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
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredBrands[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

