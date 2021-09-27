//
//  SecondaryItemDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/23/21.
//

import SwiftUI

struct ItemSummaryView: View {
    @State var item: Item
    @State private var kind: Kind?
    @State private var brand: Brand?
    @State private var seller: Seller?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
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
        VStack {
            HStack {
                Spacer()
                Text(item.name ?? "")
                Spacer()
            }
            
            photoView()
            
            HStack {
                Spacer()
                
                VStack {
                    Text("CATEGORY")
                        .foregroundColor(.secondary)
                    Text(item.kind?.name ?? "")
                }
                
                Spacer()
                
                VStack {
                    Text("BRAND")
                        .foregroundColor(.secondary)
                    Text(item.brand?.name ?? "")
                }
                
                Spacer()
                
                VStack {
                    Text("SELLER")
                        .foregroundColor(.secondary)
                    Text(item.seller?.name ?? "")
                }
                
                Spacer()
            }
            
            quantityAndPricesView()
            
            datesView()

            miscView()
        }
        .padding()
    }
    
    private func photoView() -> some View {
        HStack {
            Spacer()
            
            #if os(macOS)
            if let image = item.image, let nsImage = NSImage(data: image) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
            } else {
                Text("PHOTO")
                    .foregroundColor(.secondary)
            }
            #else
            if let image = item.image, let uiImage = UIImage(data: image) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("PHOTO")
                    .foregroundColor(.secondary)
            }
            #endif
            
            Spacer()
        }
    }
    
    private func quantityAndPricesView() -> some View {
        HStack {
            Spacer()
            
            VStack {
                Text("QUANTITY")
                    .foregroundColor(.secondary)
                Text(quantityFormatter.string(from: NSNumber(value: item.quantity)) ?? "")
                    .multilineTextAlignment(.trailing)
            }
            
            Spacer()
            
            VStack {
                Text("BUY PRICE")
                    .foregroundColor(.secondary)
                Text(priceFormatter.string(from: NSNumber(value: item.buyPrice)) ?? "")
                    .multilineTextAlignment(.trailing)
            }
            
            VStack {
                Text("CURRENCY")
                    .foregroundColor(.secondary)
                Text(item.buyCurrency ?? "")
            }
            
            Spacer()
            
            VStack {
                Text("SELL PRICE")
                    .foregroundColor(.secondary)
                Text(priceFormatter.string(from: NSNumber(value: item.sellPrice)) ?? "")
                    .multilineTextAlignment(.trailing)
            }
            
            VStack {
                Text("CURRENCY")
                    .foregroundColor(.secondary)
                Text(item.sellCurrency ?? "")
            }
            
            Spacer()
        }
    }
    
    private func datesView() -> some View {
        HStack {
            Text("OBTAINED")
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let obtained = item.obtained {
                Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
            } else {
                Text("N/A")
            }
            
            Spacer()
            Spacer()
            
            Text("DISPOSED")
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let disposed = item.disposed {
                Text("\(disposed, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
            } else {
                Text("N/A")
            }
            
        }
    }
    
    private func miscView() -> some View {
        HStack {
            Text("created")
                .foregroundColor(.secondary)
            Spacer()
            Text("\(item.created!, formatter: BelongingsViewModel.dateFormatter)")
            
            Spacer()
            Spacer()
            
            Text("last updated")
                .foregroundColor(.secondary)
            Spacer()
            Text("\(item.lastupd!, formatter: BelongingsViewModel.dateFormatter)")
        }
    }
}
