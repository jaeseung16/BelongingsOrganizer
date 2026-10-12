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

extension SearchFieldPlacement {
    // Keeps the field showing without a pull-down, as the split view did; navigationBarDrawer is unavailable on macOS
    static var listSearchField: SearchFieldPlacement {
        #if os(iOS)
        return .navigationBarDrawer(displayMode: .always)
        #else
        return .automatic
        #endif
    }
}

// The tabs of the TabView root; the ads target keeps the SidebarSection sidebar
enum AppTab: Hashable {
    case items
    case catalog
    case search
    case settings
    case stats
    case disposed

    init(_ section: SidebarSection) {
        switch section {
        case .items:
            self = .items
        case .disposed:
            self = .disposed
        case .categories, .brands, .sellers:
            self = .catalog
        case .stats:
            self = .stats
        case .settings:
            self = .settings
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State private var section: SidebarSection? = .items
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var tab = AppTab.items
    @State private var catalogSection = CatalogSection.categories

    @State private var selectedItem: Item?
    @State private var selectedDisposedItem: Item?
    @State private var selectedSearchedItem: Item?
    @State private var selectedKind: Kind?
    @State private var selectedBrand: Brand?
    @State private var selectedSeller: Seller?

    private static let intentHandoffDelay = Duration.milliseconds(500)
    // Siri and Shortcuts donate the intents they run, so opening this one isn't donated again
    @State private var itemOpenedByIntent: Item?

    @State private var statsType = StatsType.obtained
    @State private var statsStart = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())!
    @State private var statsEnd = Date()

    var body: some View {
        root
            .alert("Unable to save data", isPresented: $viewModel.showAlert) {
                Button("Dismiss") {
                }
            } message: {
                Text(viewModel.message)
            }
            // Clear selections whose object was deleted, here or on another device
            .onChange(of: viewModel.items) { _, items in
                if let item = selectedItem, !items.contains(item) {
                    selectedItem = nil
                }
                if let item = selectedDisposedItem, !items.contains(item) {
                    selectedDisposedItem = nil
                }
                if let item = selectedSearchedItem, !items.contains(item) {
                    selectedSearchedItem = nil
                }
            }
            .onChange(of: viewModel.kinds) { _, kinds in
                if let kind = selectedKind, !kinds.contains(kind) {
                    selectedKind = nil
                }
            }
            .onChange(of: viewModel.brands) { _, brands in
                if let brand = selectedBrand, !brands.contains(brand) {
                    selectedBrand = nil
                }
            }
            .onChange(of: viewModel.sellers) { _, sellers in
                if let seller = selectedSeller, !sellers.contains(seller) {
                    selectedSeller = nil
                }
            }
            .onChange(of: selectedItem) { _, item in
                donateOpening(item)
            }
            .onChange(of: selectedDisposedItem) { _, item in
                donateOpening(item)
            }
            .onChange(of: selectedSearchedItem) { _, item in
                donateOpening(item)
            }
            // Initial too: Siri or a notification may ask before the window appears
            .onChange(of: viewModel.navigateToItems, initial: true) { _, navigate in
                if navigate {
                    show(.items)
                    // On iPhone an open item would hide the search results
                    if let item = selectedItem, !viewModel.checkIfStringToSearchContainedIn(item.name ?? "") {
                        selectedItem = nil
                    }
                    viewModel.navigateToItems = false
                }
            }
            .onChange(of: viewModel.navigationRequest, initial: true) { _, request in
                if let request {
                    viewModel.navigationRequest = nil
                    // Selected while Siri or Shortcuts is still handing over, the item is pushed twice
                    // on iPhone (Back then shows it again); waiting for the handoff avoids that
                    Task {
                        try? await Task.sleep(for: Self.intentHandoffDelay)
                        navigate(to: request)
                    }
                }
            }
    }

    @ViewBuilder
    private var root: some View {
        #if ADS
        // The banner's bottom inset leaves no room for a tab bar
        splitViewRoot
            .adSupport()
        #else
        tabViewRoot
        #endif
    }

    private var tabViewRoot: some View {
        TabView(selection: $tab) {
            Tab(SidebarSection.items.rawValue, systemImage: SidebarSection.items.systemImage, value: AppTab.items) {
                NavigationSplitView {
                    ItemListView(selected: $selectedItem)
                        .searchable(text: $viewModel.stringToSearch, placement: .listSearchField)
                } detail: {
                    itemDetail(for: selectedItem)
                }
            }

            Tab("Catalog", systemImage: "square.stack.3d.up.fill", value: AppTab.catalog) {
                NavigationSplitView {
                    CatalogView(section: $catalogSection, selectedKind: $selectedKind, selectedBrand: $selectedBrand,
                                selectedSeller: $selectedSeller)
                        .searchable(text: $viewModel.stringToSearch, placement: .listSearchField)
                } detail: {
                    catalogDetail
                }
            }

            // A plain tab: one with the search role can't overflow into More on iPhone, and is dropped instead.
            // Until search covers every entity, it searches the items
            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                NavigationSplitView {
                    ItemListView(selected: $selectedSearchedItem)
                        .searchable(text: $viewModel.stringToSearch, placement: .listSearchField)
                } detail: {
                    itemDetail(for: selectedSearchedItem)
                }
            }

            #if os(iOS)
            Tab(SidebarSection.settings.rawValue, systemImage: SidebarSection.settings.systemImage, value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
            #endif

            Tab(SidebarSection.stats.rawValue, systemImage: SidebarSection.stats.systemImage, value: AppTab.stats) {
                NavigationSplitView {
                    statsList
                } detail: {
                    statsDetail
                }
            }

            Tab(SidebarSection.disposed.rawValue, systemImage: SidebarSection.disposed.systemImage, value: AppTab.disposed) {
                NavigationSplitView {
                    ItemListView(disposition: .disposed, selected: $selectedDisposedItem)
                        .searchable(text: $viewModel.stringToSearch, placement: .listSearchField)
                } detail: {
                    itemDetail(for: selectedDisposedItem)
                }
            }
        }
        // macOS keeps its toolbar tabs: there the sidebar style around each tab's NavigationSplitView
        // loops on Update Constraints until AppKit throws
        #if os(iOS)
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }

    private var splitViewRoot: some View {
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
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch section {
        case .stats:
            statsList
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
            kindDetail(for: selectedKind)
        case .brands:
            brandDetail(for: selectedBrand)
        case .sellers:
            sellerDetail(for: selectedSeller)
        case .stats:
            statsDetail
        case .settings, nil:
            EmptyView()
        }
    }

    private func navigate(to request: BelongingsViewModel.NavigationRequest) {
        switch request {
        case .item(let item):
            // Keep the item in the list, so it doesn't stay selected but out of sight
            clearSearch(unlessMatching: item.name)
            itemOpenedByIntent = item
            if item.disposed == nil {
                show(.items)
                selectedItem = item
            } else {
                show(.disposed)
                selectedDisposedItem = item
            }
        case .kind(let kind):
            clearSearch(unlessMatching: kind.name)
            show(.categories)
            selectedKind = kind
        case .brand(let brand):
            clearSearch(unlessMatching: brand.name)
            show(.brands)
            selectedBrand = brand
        case .seller(let seller):
            clearSearch(unlessMatching: seller.name)
            show(.sellers)
            selectedSeller = seller
        }
    }

    // Selects the section in whichever root is showing
    private func show(_ section: SidebarSection) {
        self.section = section
        tab = AppTab(section)
        switch section {
        case .categories:
            catalogSection = .categories
        case .brands:
            catalogSection = .brands
        case .sellers:
            catalogSection = .sellers
        default:
            break
        }
    }

    private func donateOpening(_ item: Item?) {
        defer {
            itemOpenedByIntent = nil
        }
        if let item, item != itemOpenedByIntent {
            OpenItemIntent.donate(opening: item)
        }
    }

    private func clearSearch(unlessMatching name: String?) {
        if !viewModel.checkIfStringToSearchContainedIn(name ?? "") {
            viewModel.stringToSearch = ""
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

    @ViewBuilder
    private func kindDetail(for kind: Kind?) -> some View {
        if let kind {
            KindDetailView(kind: kind, name: kind.name ?? "", items: viewModel.getItems(kind))
                .id(kind)
                .toolbarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func brandDetail(for brand: Brand?) -> some View {
        if let brand {
            BrandDetailView(brand: brand, name: brand.name ?? "", urlString: brand.url?.absoluteString ?? "", items: viewModel.getItems(brand))
                .id(brand)
                .toolbarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func sellerDetail(for seller: Seller?) -> some View {
        if let seller {
            SellerDetailView(seller: seller, name: seller.name ?? "", urlString: seller.url?.absoluteString ?? "", items: viewModel.getItems(seller))
                .id(seller)
                .toolbarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var catalogDetail: some View {
        switch catalogSection {
        case .categories:
            kindDetail(for: selectedKind)
        case .brands:
            brandDetail(for: selectedBrand)
        case .sellers:
            sellerDetail(for: selectedSeller)
        }
    }

    private var statsList: some View {
        StatsView(statsType: $statsType, start: $statsStart, end: $statsEnd)
    }

    private var statsDetail: some View {
        StatsDetailView(statsType: statsType, start: statsStart, end: statsEnd)
    }
}
