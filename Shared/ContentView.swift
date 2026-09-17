//
//  ContentView.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI
import CoreData

extension ToolbarItemPlacement {
    // .topBarLeading is unavailable on macOS
    static var leadingButtons: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .automatic
        #endif
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case items = "Items"
    case disposed = "Disposed"
    case categories = "Categories"
    case brands = "Brands"
    case sellers = "Sellers"
    case stats = "Stats"
    case settings = "Settings"

    var id: Self { self }

    // On macOS, Settings lives in the Settings scene (⌘,) instead of the sidebar
    static var sidebarCases: [SidebarSection] {
        #if os(macOS)
        allCases.filter { $0 != .settings }
        #else
        allCases
        #endif
    }

    var systemImage: String {
        switch self {
        case .items:
            return "gift.fill"
        case .disposed:
            return "archivebox.fill"
        case .categories:
            return "list.dash"
        case .brands:
            return "r.circle"
        case .sellers:
            return "shippingbox.fill"
        case .stats:
            return "chart.xyaxis.line"
        case .settings:
            return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State private var section: SidebarSection? = .items
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @State private var selectedItem: Item?
    @State private var selectedDisposedItem: Item?
    @State private var selectedKind: Kind?
    @State private var selectedBrand: Brand?
    @State private var selectedSeller: Seller?

    @State private var statsType = StatsType.obtained
    @State private var statsStart = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())!
    @State private var statsEnd = Date()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarSection.sidebarCases, selection: $section) { section in
                Label(section.rawValue, systemImage: section.systemImage)
            }
            .navigationTitle("Belongings")
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .alert("Unable to save data", isPresented: $viewModel.showAlert) {
            Button("Dismiss") {
            }
        } message: {
            Text(viewModel.message)
        }
        .onChange(of: viewModel.navigateToItems) { _, navigate in
            if navigate {
                section = .items
                viewModel.navigateToItems = false
            }
        }
        #if ADS
        .adSupport()
        #endif
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch section {
        case .stats:
            StatsView(statsType: $statsType, start: $statsStart, end: $statsEnd)
        case .settings:
            SettingsView()
        case nil:
            EmptyView()
        default:
            listColumn
                .searchable(text: $viewModel.stringToSearch)
        }
    }

    @ViewBuilder
    private var listColumn: some View {
        switch section {
        case .items:
            ItemListView(selected: $selectedItem)
        case .disposed:
            ItemListView(disposition: .disposed, selected: $selectedDisposedItem)
        case .categories:
            KindListView(selected: $selectedKind)
        case .brands:
            BrandListView(selected: $selectedBrand)
        case .sellers:
            SellerListView(selected: $selectedSeller)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch section {
        case .items:
            itemDetail(for: selectedItem)
        case .disposed:
            itemDetail(for: selectedDisposedItem)
        case .categories:
            if let kind = selectedKind {
                KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                    .id(kind)
                    .toolbarTitleDisplayMode(.inline)
            }
        case .brands:
            if let brand = selectedBrand {
                BrandDetailView(brand: brand, name: brand.name ?? "", urlString: brand.url?.absoluteString ?? "", items: viewModel.getItems(brand))
                    .id(brand)
                    .toolbarTitleDisplayMode(.inline)
            }
        case .sellers:
            if let seller = selectedSeller {
                SellerDetailView(seller: seller, name: seller.name ?? "", urlString: seller.url?.absoluteString ?? "", items: viewModel.getItems(seller))
                    .id(seller)
                    .toolbarTitleDisplayMode(.inline)
            }
        case .stats:
            StatsDetailView(statsType: statsType, start: statsStart, end: statsEnd)
        case .settings, nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private func itemDetail(for item: Item?) -> some View {
        if let item {
            ItemDetailView(item: item, dto: ItemDTO.create(from: item))
                .id(item)
                .toolbarTitleDisplayMode(.inline)
        }
    }
}
