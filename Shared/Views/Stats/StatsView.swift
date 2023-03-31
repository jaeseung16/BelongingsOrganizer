//
//  StatsView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 3/19/23.
//

import Charts
import SwiftUI

struct StatsView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State private var statsType = StatsType.kind
    @State private var start = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())!
    @State private var end = Date()
    
    private var itemCountByKind: [KindStats] {
        viewModel.itemCountsByKind(from: start, to: end)
    }
    
    private var itemCountByBrand: [BrandStats] {
        viewModel.itemCountByBrand(from: start, to: end)
    }
    
    private var itemCountBySeller: [SellerStats] {
        viewModel.itemCountBySeller(from: start, to: end)
    }
    
    var body: some View {
        VStack {
            header
            
            switch statsType {
            case .kind:
                kindChart
                    .padding()
            case .brand:
                brandChart
                    .padding()
            case .seller:
                sellerChart
                    .padding()
            }
                
        }
        .padding()
    }
    
    private var header: some View {
        HStack {
            Spacer()
            
            Picker("Stats", selection: $statsType) {
                Text("Category").tag(StatsType.kind)
                Text("Brand").tag(StatsType.brand)
                Text("Seller").tag(StatsType.seller)
            }
            
            Spacer()
            
            DatePicker("Start Date", selection: $start, displayedComponents: [.date])
            
            Spacer()
            
            DatePicker("End Date", selection: $end, displayedComponents: [.date])
            
            Spacer()
        }
    }
    
    
    private var kindChart: some View {
        Chart {
            ForEach(itemCountByKind, id: \.name) {
                BarMark(
                    x: .value("# of items", $0.itemCount),
                    y: .value("Category", $0.name)
                )
                .foregroundStyle(.green)
            }
        }
    }
    
    private var brandChart: some View {
        Chart {
            ForEach(itemCountByBrand, id: \.name) {
                BarMark(
                    x: .value("# of items", $0.itemCount),
                    y: .value("Brand", $0.name)
                )
                .foregroundStyle(.blue)
            }
        }
    }
    
    private var sellerChart: some View {
        Chart {
            ForEach(itemCountBySeller, id: \.name) {
                BarMark(
                    x: .value("# of items", $0.itemCount),
                    y: .value("Seller", $0.name)
                )
                .foregroundStyle(.red)
            }
        }
    }
}
