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
        GeometryReader { geometry in
            VStack {
                header
                    .frame(width: 200, height: 0.1 * geometry.size.height)
                
                Spacer(minLength: 20.0)
                
                switch statsType {
                case .kind:
                    chart(for: itemCountByKind, color: .green)
                case .brand:
                    chart(for: itemCountByBrand, color: .blue)
                case .seller:
                    chart(for: itemCountBySeller, color: .red)
                }
            }
            .padding()
        }
    }
    
    private var header: some View {
        VStack {
            Picker("Items per", selection: $statsType) {
                Text("Category").tag(StatsType.kind)
                Text("Brand").tag(StatsType.brand)
                Text("Seller").tag(StatsType.seller)
            }
            
            Spacer()
            
            DatePicker("Start Date", selection: $start, displayedComponents: [.date])
            DatePicker("End Date", selection: $end, displayedComponents: [.date])
        }
    }
    
    private func chart(for stats: [BelongsStats], color: Color) -> some View {
        Chart {
            ForEach(stats, id: \.name) { item in
                BarMark(
                    x: .value("# of items", item.itemCount),
                    y: .value("Category", item.name)
                )
                .annotation(position: .trailing) {
                    Text("\(item.itemCount)")
                        .foregroundColor(.secondary)
                }
                .foregroundStyle(color)
            }
        }
    }
    
}
