//
//  FilterItemsView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

enum Filter: String, CaseIterable {
    case kind = "Category"
    case brand = "Brand"
    case seller = "Seller"
}

struct FilterItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel

    @Binding var selectedKinds: Set<Kind>
    @Binding var selectedBrands: Set<Brand>
    @Binding var selectedSellers: Set<Seller>
    
    @State private var selectedFilter = Filter.kind
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header
                
                Divider()
                
                Text("Filter")
                    .font(.title3)
                
                selectedKindsSection
                
                selectedBrandsSection
               
                selectedSellersSection
                
                Divider()
                
                Picker("Filter Type", selection: $selectedFilter) {
                    Text(Filter.kind.rawValue).tag(Filter.kind)
                    Text(Filter.brand.rawValue).tag(Filter.brand)
                    Text(Filter.seller.rawValue).tag(Filter.seller)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                filterList
            }
            .padding()
        }
    }
    
    private var selectedKindsSection: some View {
        SelectionSectionView(title: .category) {
            ForEach(selectedKinds.sorted(by: { $0.name ?? "" > $1.name ?? ""} ), id: \.self) { kind in
                Button {
                    selectedKinds.remove(kind)
                } label: {
                    Text(kind.name ?? "")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var selectedBrandsSection: some View {
        SelectionSectionView(title: .brand) {
            ForEach(selectedBrands.sorted(by: { $0.name ?? "" > $1.name ?? ""} ), id: \.self) { brand in
                Button {
                    selectedBrands.remove(brand)
                } label: {
                    Text(brand.name ?? "")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var selectedSellersSection: some View {
        SelectionSectionView(title: .seller) {
            ForEach(selectedSellers.sorted(by: { $0.name ?? "" > $1.name ?? "" }), id: \.self) { seller in
                Button {
                    selectedSellers.remove(seller)
                } label: {
                    Text(seller.name ?? "")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var filterList: some View {
        List {
            switch (selectedFilter) {
            case .kind:
                ForEach(viewModel.allKinds, id: \.id) { kind in
                    if let kindName = kind.name {
                        Button {
                            if selectedKinds.contains(kind) {
                                selectedKinds.remove(kind)
                            } else {
                                selectedKinds.insert(kind)
                            }
                        } label: {
                            BrandKindSellerRowView(name: kindName, itemCount: viewModel.getItemCount(kind))
                        }
                    }
                }
            case .brand:
                ForEach(viewModel.allBrands, id: \.id) { brand in
                    if let brandName = brand.name {
                        Button {
                            if selectedBrands.contains(brand) {
                                selectedBrands.remove(brand)
                            } else {
                                selectedBrands.insert(brand)
                            }
                        } label: {
                            BrandKindSellerRowView(name: brandName, itemCount: viewModel.getItemCount(brand))
                        }
                    }
                }
            case .seller:
                ForEach(viewModel.allSellers, id: \.id) { seller in
                    if let sellerName = seller.name {
                        Button {
                            if selectedSellers.contains(seller) {
                                selectedSellers.remove(seller)
                            } else {
                                selectedSellers.insert(seller)
                            }
                        } label: {
                            BrandKindSellerRowView(name: sellerName, itemCount: viewModel.getItemCount(seller))
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Dismiss")
            }
            
            Spacer()
            
            Button {
                selectedKinds.removeAll()
                selectedBrands.removeAll()
                selectedSellers.removeAll()
            } label: {
                Text("Reset")
            }
        }
    }
}


