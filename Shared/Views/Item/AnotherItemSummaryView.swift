//
//  AnotherItemSummaryView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/10/23.
//

import SwiftUI

struct AnotherItemSummaryView: View {
    @State var item: Item
    
    private let notApplicable = "N/A"
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                itemInfo()
            }
        }
    }
    
    private var quantityFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        return formatter
    }
    
    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    private func itemInfo() -> some View {
        Grid {
            HStack {
                photo
                
                Spacer()
                
                name
                
                Spacer()
                
                detail
            }
        }
    }
    
    private var name: some View {
        Text(item.name ?? "")
            .font(.callout)
            .frame(height: 60)
            .lineLimit(2)
            .allowsTightening(true)
            .minimumScaleFactor(0.7)
    }
    
    private var photo: some View {
        HStack {
            #if os(macOS)
            if let image = item.image, let nsImage = NSImage(data: image) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            } else {
                Text("No Photo")
                    .font(.body.italic())
                    .foregroundColor(.secondary)
            }
            #else
            if let image = item.image, let uiImage = UIImage(data: image) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            } else {
                Text("No Photo")
                    .font(.body.italic())
                    .foregroundColor(.secondary)
            }
            #endif
        }
    }
    
    private var detail: some View {
        Group {
            VStack {
                SectionTitleView(title: .buyPrice)

                Text(priceFormatter.string(from: NSNumber(value: item.buyPrice)) ?? notApplicable)
                    .multilineTextAlignment(.trailing)
            }

            VStack {
                SectionTitleView(title: .currency)

                Text(item.buyCurrency ?? notApplicable)
            }
            
            VStack {
                SectionTitleView(title: .quantity)
                
                Text(quantityFormatter.string(from: NSNumber(value: item.quantity)) ?? notApplicable)
                    .multilineTextAlignment(.trailing)
            }
            
            VStack {
                SectionTitleView(title: .obtained)
                
                if let obtained = item.obtained {
                    Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
            }
            
        }
    }
    
}
