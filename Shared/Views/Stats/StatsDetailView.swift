//
//  StatsDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/9/23.
//

import SwiftUI
import Charts

struct StatsDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @Binding var statsType: StatsType
    @Binding var start: Date
    @Binding var end: Date
    
    @State private var itemOverTime = [ItemOverTime]()
    @State private var itemCountByKind = [KindStats]()
    @State private var itemCountByBrand = [BrandStats]()
    @State private var itemCountBySeller = [SellerStats]()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text("Items")
                    Spacer()
                }
                
                chart(for: itemOverTime)
            
                HStack {
                    Text("Categories")
                    Spacer()
                }
                
                chart(for: itemCountByKind)
            
                HStack {
                    Text("Brands")
                    Spacer()
                }
                
                chart(for: itemCountByBrand)
           
                HStack {
                    Text("Sellers")
                    Spacer()
                }

                chart(for: itemCountBySeller)
            }
            .padding()
        }
        .onAppear {
            refresh()
        }
        .onChange(of: statsType) { _ in
            refresh()
        }
        .onChange(of: start) { _ in
            refresh()
        }
        .onChange(of: end) { _ in
            refresh()
        }
    }
    
    private func chart(for stats: [ItemOverTime]) -> some View {
        Chart(stats, id: \.date) { stat in
            BarMark(x: .value("Date", stat.date), y: .value("Count", stat.itemCount))
        }
    }
    
    private func chart(for stats: [BelongsStats]) -> some View {
        Chart(stats, id: \.name) { stat in
            BarMark(x: .value("# of items", stat.itemCount))
            .foregroundStyle(by: .value("Category", stat.name))
            .annotation(position: .overlay) {
                Text("\(stat.itemCount)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func refresh() -> Void {
        itemOverTime = viewModel.itemOverTime(type: statsType, from: start, to: end)
        itemCountByKind = viewModel.itemCountsByKind(type: statsType, from: start, to: end)
        itemCountByBrand = viewModel.itemCountByBrand(type: statsType, from: start, to: end)
        itemCountBySeller = viewModel.itemCountBySeller(type: statsType, from: start, to: end)
    }
}
