//
//  FilterItemsView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

enum Filter: String, CaseIterable {
    case kind, brand, seller
}

struct FilterItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Kind.name, ascending: true)],
        animation: .default)
    private var kinds: FetchedResults<Kind>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Brand.name, ascending: true)],
        animation: .default)
    private var brands: FetchedResults<Brand>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Seller.name, ascending: true)],
        animation: .default)
    private var sellers: FetchedResults<Seller>
    
    @Binding var selectedKinds: Set<Kind>
    @Binding var selectedBrands: Set<Brand>
    @Binding var selectedSellers: Set<Seller>
    
    @State private var selectedFilter = Filter.kind
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                Text("Filter")
                    .font(.title3)
                
                selectedKindsSection()
                
                selectedBrandsSection()
               
                selectedSellersSection()
                
                Divider()
                
                Picker("Filter Type", selection: $selectedFilter) {
                    Text("Category").tag(Filter.kind)
                    Text("Brand").tag(Filter.brand)
                    Text("Seller").tag(Filter.seller)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                filterListView()
            }
            .padding()
        }
    }
    
    func selectedKindsSection() -> some View {
        VStack(alignment: .leading) {
            Text("CATEGORY")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(selectedKinds.sorted(by: { $0.name ?? "" > $1.name ?? ""
                    }), id: \.self) { kind in
                        Button {
                            selectedKinds.remove(kind)
                        } label: {
                            Text(kind.name ?? "")
                                .foregroundColor(.white)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 1.0)))
                }
                .padding()
            }
            .background(RoundedRectangle(cornerRadius: 10.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            .frame(maxHeight: 40.0)
        }
    }
    
    func selectedBrandsSection() -> some View {
        VStack(alignment: .leading) {
            Text("BRAND")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(selectedBrands.sorted(by: { $0.name ?? "" > $1.name ?? ""
                    }), id: \.self) { kind in
                        Button {
                            selectedBrands.remove(kind)
                        } label: {
                            Text(kind.name ?? "")
                                .foregroundColor(.white)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 1.0)))
                }
                .padding()
            }
            .background(RoundedRectangle(cornerRadius: 10.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            .frame(maxHeight: 40.0)
        }
    }
    
    func selectedSellersSection() -> some View {
        VStack(alignment: .leading) {
            Text("SELLER")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(selectedSellers.sorted(by: { $0.name ?? "" > $1.name ?? ""
                    }), id: \.self) { seller in
                        Button {
                            selectedSellers.remove(seller)
                        } label: {
                            Text(seller.name ?? "")
                                .foregroundColor(.white)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 1.0)))
                }
                .padding()
            }
            .background(RoundedRectangle(cornerRadius: 10.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            .frame(maxHeight: 40.0)
        }
    }
    
    func filterListView() -> some View {
        List {
            switch (selectedFilter) {
            case .kind:
                ForEach(kinds, id: \.id) { kind in
                    if kind.name != nil {
                        Button {
                            if selectedKinds.contains(kind) {
                                selectedKinds.remove(kind)
                            } else {
                                selectedKinds.insert(kind)
                            }
                        } label: {
                            KindRowView(kind: kind)
                        }
                    }
                }
            case .brand:
                ForEach(brands, id: \.id) { brand in
                    if brand.name != nil {
                        Button {
                            if selectedBrands.contains(brand) {
                                selectedBrands.remove(brand)
                            } else {
                                selectedBrands.insert(brand)
                            }
                        } label: {
                            BrandRowView(brand: BrandDTO(id: brand.uuid, name: brand.name, url: brand.url, created: brand.created, lastupd: brand.lastupd))
                        }
                    }
                }
            case .seller:
                ForEach(sellers, id: \.id) { seller in
                    if seller.name != nil {
                        Button {
                            if selectedSellers.contains(seller) {
                                selectedSellers.remove(seller)
                            } else {
                                selectedSellers.insert(seller)
                            }
                        } label: {
                            SellerRowView(seller: SellerDTO(id: seller.uuid, name: seller.name, url: seller.url, created: seller.created, lastupd: seller.lastupd))
                        }
                    }
                }
            }
        }
    }
    
    func header() -> some View {
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


