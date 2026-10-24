//
//  CatalogView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/12/26.
//

import SwiftUI

enum CatalogSection: String, CaseIterable, Identifiable {
    case categories = "Categories"
    case brands = "Brands"
    case sellers = "Sellers"

    var id: Self { self }
}

// Categories, brands, and sellers share one tab, switched with a segmented picker
struct CatalogView: View {
    @Binding var section: CatalogSection
    @Binding var selectedKind: Kind?
    @Binding var selectedBrand: Brand?
    @Binding var selectedSeller: Seller?

    var body: some View {
        list
            .safeAreaBar(edge: .top) {
                Picker("Catalog", selection: $section) {
                    ForEach(CatalogSection.allCases) { section in
                        Text(section.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("CatalogPicker")
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
    }

    @ViewBuilder
    private var list: some View {
        switch section {
        case .categories:
            KindListView(selected: $selectedKind)
        case .brands:
            BrandListView(selected: $selectedBrand)
        case .sellers:
            SellerListView(selected: $selectedSeller)
        }
    }
}
