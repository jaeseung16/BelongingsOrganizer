//
//  FilterItemsView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

enum Filter: String, CaseIterable {
    case kind, manufacturer, seller
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
        sortDescriptors: [NSSortDescriptor(keyPath: \Manufacturer.name, ascending: true)],
        animation: .default)
    private var manufacturers: FetchedResults<Manufacturer>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Seller.name, ascending: true)],
        animation: .default)
    private var sellers: FetchedResults<Seller>
    
    @Binding var selectedKinds: Set<Kind>
    @Binding var selectedManufacturers: Set<Manufacturer>
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
                    
                    Section(header: Text("Manufacturer")) {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(selectedManufacturers.sorted(by: { $0.name ?? "" > $1.name ?? ""
                                }), id: \.self) { manufacturer in
                                    Button {
                                        selectedManufacturers.remove(manufacturer)
                                    } label: {
                                        Text(manufacturer.name ?? "")
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
                    Text("Manufacturer").tag(Filter.manufacturer)
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
                case .manufacturer:
                    List {
                        ForEach(manufacturers, id: \.id) { manufacture in
                            Button {
                                if selectedManufacturers.contains(manufacture) {
                                    selectedManufacturers.remove(manufacture)
                                } else {
                                    selectedManufacturers.insert(manufacture)
                                }
                            } label: {
                                Text(manufacture.name ?? "")
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
                        selectedManufacturers.removeAll()
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


