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
    @State private var readyToRefresh = false
    @State private var showAlertForDeletion = false
    @Binding var selected: Brand?
    
    var brands: [Brand] {
        return viewModel.filteredBrands
    }
    
    var body: some View {
        VStack {
            brandList
                .sheet(isPresented: $presentAddBrandView) {
                    AddBrandView()
                        .environmentObject(viewModel)
                        .modifier(SheetModifier())
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
    
    private var brandList: some View {
        VStack {
            List(selection: $selected) {
                ForEach(brands) { brand in
                    NavigationLink(value: brand) {
                        BrandKindSellerRowView(name: brand.name ?? "", itemCount: viewModel.getItemCount(brand))
                    }
                }
                .onDelete(perform: deleteBrands)
            }
            .toolbar {
                header
            }
        }
        .refreshable {
            viewModel.fetchEntities()
        }
        .onChange(of: viewModel.canRefresh) { _ in
            readyToRefresh = viewModel.canRefresh
        }
    }
    
    private var header: ToolbarItemGroup<some View> {
        #if os(macOS)
        ToolbarItemGroup() {
            Button {
                viewModel.fetchEntities()
                viewModel.canRefresh = false
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(!readyToRefresh)
            
            Button{
                presentAddBrandView = true
            } label: {
                Label("Add a brand", systemImage: "plus")
            }
        }
        #else
        ToolbarItemGroup(placement: .topBarLeading) {
            Button{
                presentAddBrandView = true
            } label: {
                Label("Add a brand", systemImage: "plus")
            }
        }
        #endif
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { brands[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

