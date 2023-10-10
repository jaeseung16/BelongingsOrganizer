//
//  SecondaryItemDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/23/21.
//

import SwiftUI

struct ItemSummaryView: View {
    @State var item: Item
    
    private let notApplicable = "N/A"
    
    private var kind: Kind? {
        let kinds = item.kind?.filter { $0 is Kind }.map { $0 as! Kind }
        return kinds?.first
    }
    
    private var brand: Brand? {
        let brands = item.brand?.filter { $0 is Brand }.map { $0 as! Brand }
        return brands?.first
    }
    
    private var seller: Seller? {
        let sellers = item.seller?.filter { $0 is Seller }.map { $0 as! Seller }
        return sellers?.first
    }
    
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
            name
            
            photo
            
            Divider()
            
            detail

            Divider()
            
            misc
        }
        .padding()
    }
    
    private var name: some View {
        HStack {
            Spacer()
            Text(item.name ?? "")
                .font(.headline)
            Spacer()
        }
    }
    
    private var photo: some View {
        HStack {
            Spacer()
            
            #if os(macOS)
            if let image = item.image, let nsImage = NSImage(data: image) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
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
                    .frame(height: 100)
            } else {
                Text("No Photo")
                    .font(.body.italic())
                    .foregroundColor(.secondary)
            }
            #endif
            
            Spacer()
        }
    }
    
    private var detail: some View {
        Grid(verticalSpacing: 10) {
            GridRow {
                categoryBrandSeller
            }
            
            GridRow {
                obtained
            }
            
            GridRow {
                disposed
            }
            
            GridRow {
                quantity
            }
            
            GridRow {
                noteView
            }
        }
            
    }
    
    private var categoryBrandSeller: some View {
        Group {
            VStack {
                SectionTitleView(title: .category)

                Text(self.kind?.name ?? notApplicable)
            }
            
            VStack {
                SectionTitleView(title: .brand)

                Text(self.brand?.name ?? notApplicable)
            }

            VStack {
                SectionTitleView(title: .seller)

                Text(self.seller?.name ?? notApplicable)
            }
        }
    }
    
    private var quantity: some View {
        Group {
            VStack {
                SectionTitleView(title: .quantity)
                
                Text(quantityFormatter.string(from: NSNumber(value: item.quantity)) ?? notApplicable)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var obtained: some View {
        Group {
            VStack {
                SectionTitleView(title: .obtained)
                
                if let obtained = item.obtained {
                    Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
            }
            
            VStack {
                SectionTitleView(title: .buyPrice)

                Text(priceFormatter.string(from: NSNumber(value: item.buyPrice)) ?? notApplicable)
                    .multilineTextAlignment(.trailing)
            }

            VStack {
                SectionTitleView(title: .currency)

                Text(item.buyCurrency ?? notApplicable)
            }
        }
    }
    
    private var disposed: some View {
        Group {
            VStack {
                SectionTitleView(title: .disposed)
  
                if let disposed = item.disposed {
                    Text("\(disposed, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
            }

            VStack {
                SectionTitleView(title: .sellPrice)

                Text(priceFormatter.string(from: NSNumber(value: item.sellPrice)) ?? notApplicable)
                    .multilineTextAlignment(.trailing)
            }
            
            VStack {
                SectionTitleView(title: .currency)

                Text(item.sellCurrency ?? notApplicable)
            }
        }
    }
    
    private var noteView: some View {
        Group {
            VStack {
                SectionTitleView(title: .note)
                
                if let note = item.note, !note.isEmpty {
                    Text(note)
                } else {
                    Text("N/A")
                }
            }
        }
    }
    
    private var misc: some View {
        Grid {
            GridRow {
                SectionTitleView(title: .created)

                Text("\(item.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }

            GridRow {
                SectionTitleView(title: .updated)

                Text("\(item.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
        }
    }
    
}
