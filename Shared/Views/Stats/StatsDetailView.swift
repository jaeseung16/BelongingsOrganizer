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

    let statsType: StatsType
    let start: Date
    let end: Date

    private var itemOverTime: [ItemOverTime] {
        viewModel.itemOverTime(type: statsType, from: start, to: end)
    }

    private var itemCountByKind: [KindStats] {
        viewModel.itemCountsByKind(type: statsType, from: start, to: end)
    }

    private var itemCountByBrand: [BrandStats] {
        viewModel.itemCountByBrand(type: statsType, from: start, to: end)
    }

    private var itemCountBySeller: [SellerStats] {
        viewModel.itemCountBySeller(type: statsType, from: start, to: end)
    }

    var body: some View {
        VStack {
            HStack {
                Text("ITEMS")
                Spacer()
            }

            chart(for: itemOverTime)

            HStack {
                Text("CATEGORY")
                Spacer()
            }

            chart(for: itemCountByKind)

            HStack {
                Text("BRAND")
                Spacer()
            }

            chart(for: itemCountByBrand)

            HStack {
                Text("SELLER")
                Spacer()
            }

            chart(for: itemCountBySeller)
        }
        .padding()
    }

    private func chart(for stats: [ItemOverTime]) -> some View {
        Chart(stats, id: \.date) { stat in
            BarMark(x: .value("Date", stat.date, unit: .day), y: .value("Count", stat.itemCount))
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
}
