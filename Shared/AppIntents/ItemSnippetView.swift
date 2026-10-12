//
//  ItemSnippetView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/29/26.
//

import SwiftUI
import ImageIO

// ItemSummaryView's details, shrunk for Siri and Shortcuts. Built from the entity, so the photo
// is already left out while the app lock is on; prices are left out here.
struct ItemSnippetView: View {
    let item: ItemEntity

    private let notApplicable = "N/A"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            photo

            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    row(.category, item.categories.isEmpty ? nil : item.categories.map(\.name).joined(separator: ", "))
                    row(.brand, item.brand?.name)
                    row(.seller, item.seller?.name)
                    row(.obtained, item.obtained.map { BelongingsViewModel.dateFormatterWithDateOnly.string(from: $0) })
                    if let disposed = item.disposed {
                        row(.disposed, BelongingsViewModel.dateFormatterWithDateOnly.string(from: disposed))
                    }
                    if IntentAccessPolicy.showsPrices {
                        row(.buyPrice, item.buyPrice.formatted(.currency(code: item.buyCurrency.isEmpty ? "USD" : item.buyCurrency)))
                    }
                    row(.quantity, "\(item.quantity)")
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    @ViewBuilder
    private var photo: some View {
        if let image = thumbnail {
            Image(decorative: image, scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var thumbnail: CGImage? {
        guard let data = item.thumbnail, let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func row(_ title: SectionTitle, _ value: String?) -> some View {
        GridRow {
            SectionTitleView(title: title)
            Text(value ?? notApplicable)
                .font(.callout)
        }
    }
}
