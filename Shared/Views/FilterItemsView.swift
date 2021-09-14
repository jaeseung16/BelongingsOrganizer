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
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
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
                Text("Filter")
                    .font(.title3)
                
                Form {
                    Section(header: Text("Kind")) {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(selectedKinds.sorted(by: { $0.name ?? "" > $1.name ?? ""
                                }), id: \.self) { kind in
                                    Button {
                                        selectedKinds.remove(kind)
                                    } label: {
                                        Text(kind.name ?? "")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Brand")) {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(selectedBrands.sorted(by: { $0.name ?? "" > $1.name ?? ""
                                }), id: \.self) { brand in
                                    Button {
                                        selectedBrands.remove(brand)
                                    } label: {
                                        Text(brand.name ?? "")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: Text("Seller")) {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(selectedSellers.sorted(by: { $0.name ?? "" > $1.name ?? ""
                                }), id: \.self) { seller in
                                    Button {
                                        selectedSellers.remove(seller)
                                    } label: {
                                        Text(seller.name ?? "")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }

                }
                .frame(width: geometry.size.width)
                
                Divider()
                
                Picker("Filter Type", selection: $selectedFilter) {
                    Text("Category").tag(Filter.kind)
                    Text("Brand").tag(Filter.brand)
                    Text("Seller").tag(Filter.seller)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                switch (selectedFilter) {
                case .kind:
                    List {
                        ForEach(kinds, id: \.id) { kind in
                            Button {
                                if selectedKinds.contains(kind) {
                                    selectedKinds.remove(kind)
                                } else {
                                    selectedKinds.insert(kind)
                                }
                            } label: {
                                Text(kind.name ?? "")
                            }
                        }
                    }
                case .brand:
                    List {
                        ForEach(brands, id: \.id) { brand in
                            Button {
                                if selectedBrands.contains(brand) {
                                    selectedBrands.remove(brand)
                                } else {
                                    selectedBrands.insert(brand)
                                }
                            } label: {
                                Text(brand.name ?? "")
                            }
                        }
                    }
                    
                case .seller:
                    List {
                        ForEach(sellers, id: \.id) { seller in
                            Button {
                                if selectedSellers.contains(seller) {
                                    selectedSellers.remove(seller)
                                } else {
                                    selectedSellers.insert(seller)
                                }
                            } label: {
                                Text(seller.name ?? "")
                            }
                        }
                    }
                }

                HStack {
                    Button {
                        selectedKinds.removeAll()
                        selectedBrands.removeAll()
                        selectedSellers.removeAll()
                    } label: {
                        Text("Reset")
                    }
                    
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }
}


