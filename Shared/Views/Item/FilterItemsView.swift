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
                    if let kindName = kind.name {
                        Button {
                            if selectedKinds.contains(kind) {
                                selectedKinds.remove(kind)
                            } else {
                                selectedKinds.insert(kind)
                            }
                        } label: {
                            KindRowView(name: kindName, itemCount: getItems(kind).count)
                        }
                    }
                }
            case .brand:
                ForEach(brands, id: \.id) { brand in
                    if let brandName = brand.name {
                        Button {
                            if selectedBrands.contains(brand) {
                                selectedBrands.remove(brand)
                            } else {
                                selectedBrands.insert(brand)
                            }
                        } label: {
                            BrandRowView(name: brandName, itemCount: getItems(brand).count)
                        }
                    }
                }
            case .seller:
                ForEach(sellers, id: \.id) { seller in
                    if let sellerName = seller.name {
                        Button {
                            if selectedSellers.contains(seller) {
                                selectedSellers.remove(seller)
                            } else {
                                selectedSellers.insert(seller)
                            }
                        } label: {
                            SellerRowView(name: sellerName, itemCount: getItems(seller).count)
                        }
                    }
                }
            }
        }
    }
    
    private func getItems(_ kind: Kind) -> [Item] {
        guard let items = kind.items else {
            return [Item]()
        }
        
        return items.compactMap { $0 as? Item }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }
    
    private func getItems(_ brand: Brand) -> [Item] {
        guard let items = brand.items else {
            return [Item]()
        }
        
        return items.compactMap { $0 as? Item }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }
    
    private func getItems(_ seller: Seller) -> [Item] {
        guard let items = seller.items else {
            return [Item]()
        }
        
        return items.compactMap { $0 as? Item }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
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


