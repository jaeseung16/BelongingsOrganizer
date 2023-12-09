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
    
    @State private var itemCountByKind = [KindStats]()
    @State private var itemCountByBrand = [BrandStats]()
    @State private var itemCountBySeller = [SellerStats]()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
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
    
    private func refresh() -> Void {
        itemCountByKind = viewModel.itemCountsByKind(type: statsType, from: start, to: end)
        itemCountByBrand = viewModel.itemCountByBrand(type: statsType, from: start, to: end)
        itemCountBySeller = viewModel.itemCountBySeller(type: statsType, from: start, to: end)
    }
}
