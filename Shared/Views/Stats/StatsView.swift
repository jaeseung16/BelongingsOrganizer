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
                HStack {
                    Spacer()
                    header
                        .frame(width: 250, height: 0.1 * geometry.size.height)
                }
                
                Spacer(minLength: 20.0)
                
                HStack {
                    Text("CATEGORY")
                    Spacer()
                }
                
                chart(for: itemCountByKind, color: .green)
            
                HStack {
                    Text("BRAND")
                    Spacer()
                }
                
                chart(for: itemCountByBrand, color: .blue)
           
                HStack {
                    Text("SELLER")
                    Spacer()
                }

                chart(for: itemCountBySeller, color: .red)
                
            }
            .padding()
        }
    }
    
    private var header: some View {
        VStack {
            DatePicker("Start Date", selection: $start, displayedComponents: [.date])
            DatePicker("End Date", selection: $end, displayedComponents: [.date])
        }
    }
    
    private func chart(for stats: [BelongsStats], color: Color) -> some View {
        Chart(stats, id: \.name) { item in
            BarMark(
                x: .value("# of items", item.itemCount)
            )
            .foregroundStyle(by: .value("Category", item.name))
            .annotation(position: .overlay) {
                Text("\(item.itemCount)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
}
