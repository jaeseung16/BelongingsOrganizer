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
            nameView()
            
            photoView()
            
            Divider()
            
            categoryBrandSellerView()
            
            quantityView()
            
            obtainedView()
            
            disposedView()
            
            noteView()

            miscView()
        }
        .navigationTitle(item.name ?? "")
        .padding()
    }
    
    private func nameView() -> some View {
        HStack {
            Spacer()
            Text(item.name ?? "")
                .font(.headline)
            Spacer()
        }
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
    
    private func categoryBrandSellerView() -> some View {
        HStack {
            Spacer()
            
            VStack {
                SectionTitleView(title: "CATEGORY")

                Text(self.kind?.name ?? notApplicable)
            }
            
            Spacer()
            
            VStack {
                SectionTitleView(title: "BRAND")

                Text(self.brand?.name ?? notApplicable)
            }
            
            Spacer()
            
            VStack {
                SectionTitleView(title: "SELLER")

                Text(self.seller?.name ?? notApplicable)
            }
            
            Spacer()
        }
    }
    
    private func quantityView() -> some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: "QUANTITY")

            Text(quantityFormatter.string(from: NSNumber(value: item.quantity)) ?? notApplicable)
                .multilineTextAlignment(.trailing)
            Spacer()
        }
    }
    
    private func obtainedView() -> some View {
        HStack {
            Spacer()
            
            VStack {
                SectionTitleView(title: "OBTAINED")
                
                if let obtained = item.obtained {
                    Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
            }
            
            Spacer()
            
            VStack {
                SectionTitleView(title: "BUY PRICE")

                Text(priceFormatter.string(from: NSNumber(value: item.buyPrice)) ?? notApplicable)
                    .multilineTextAlignment(.trailing)
            }
            
            Spacer()
            
            VStack {
                SectionTitleView(title: "CURRENCY")

                Text(item.buyCurrency ?? notApplicable)
            }

            Spacer()
        }
    }
    
    private func disposedView() -> some View {
        HStack {
            Spacer()
       
            VStack {
                SectionTitleView(title: "DISPOSED")
  
                if let disposed = item.disposed {
                    Text("\(disposed, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
            }
            
            Spacer()
            
            VStack {
                SectionTitleView(title: "SELL PRICE")

                Text(priceFormatter.string(from: NSNumber(value: item.sellPrice)) ?? notApplicable)
                    .multilineTextAlignment(.trailing)
            }
            
            Spacer()
            
            VStack {
                SectionTitleView(title: "CURRENCY")

                Text(item.sellCurrency ?? notApplicable)
            }
            
            Spacer()
        }
    }
    
    private func noteView() -> some View {
        VStack {
            SectionTitleView(title: "NOTE")
            
            if let note = item.note, !note.isEmpty {
                Text(note)
            } else {
                Text("N/A")
            }
        }
    }
    
    private func miscView() -> some View {
        VStack {
            Divider()
            
            HStack {
                SectionTitleView(title: "CREATED")

                Text("\(item.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }

            HStack {
                SectionTitleView(title: "UPDATED")

                Text("\(item.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
        }
    }
    
}
