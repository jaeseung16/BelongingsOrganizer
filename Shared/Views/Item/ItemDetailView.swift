//
//  ItemDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var item: Item
    @State private var kind = [Kind]()
    @State private var brand: Brand?
    @State private var seller: Seller?
    
    @State private var isEditing = false
    @State private var isEdited = false
    
    @State var imageData: Data?
    @State var name = ""
    @State var quantity: Int = 0
    @State var buyPrice = 0.0
    @State var sellPrice = 0.0
    @State var buyCurrency: String = "USD"
    @State var sellCurrency: String = "USD"
    @State var note: String = ""
    @State var obtained = Date()
    @State var disposed = Date()
    
    @State private var isObtainedDateEdited = false
    @State private var isDisposedDateEdited = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                header
                
                Divider()
                
                itemInfo(in: geometry)
                
                Divider()
                
                footer
            }
            .padding()
        }
    }
    
    private func reset() -> Void {
        imageData = item.image
        name = item.name ?? ""
        quantity = Int(item.quantity)
        buyPrice = item.buyPrice
        sellPrice = item.sellPrice
        buyCurrency = item.buyCurrency ?? "USD"
        sellCurrency = item.sellCurrency ?? "USD"
        note = item.note ?? ""
        obtained = item.obtained ?? Date()
        disposed = item.disposed ?? Date()
        
        kind.removeAll()
        brand = nil
        seller = nil
        
        isEditing = false
        isEdited = false
        isObtainedDateEdited = false
        isDisposedDateEdited = false
    }
    
    private var header: some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            isEdited = false
            
            viewModel.update(item, kind: kind, brand: brand, seller: seller) { item in
                viewModel.itemDTO = ItemDTO(id: item.uuid,
                                            name: name,
                                            note: note,
                                            quantity: Int64(quantity),
                                            buyPrice: buyPrice,
                                            sellPrice: sellPrice,
                                            buyCurrency: buyCurrency,
                                            sellCurrency: sellCurrency,
                                            obtained: isObtainedDateEdited ? obtained : item.obtained,
                                            disposed: isDisposedDateEdited ? disposed : item.disposed,
                                            image: imageData ?? item.image)
            }
        }
    }

    private func itemInfo(in geometry: GeometryProxy) -> some View {
        List {
            ForEach(ItemProperty.allCases) { property in
                switch property {
                case .name:
                    DetailNameView(item: item, name: $name, isEdited: $isEdited)
                case .photo:
                    DetailPhotoView(item: item, imageData: $imageData, isEdited: $isEdited, geometry: geometry)
                case .note:
                    DetailNoteView(item: item, note: $note, isEdited: $isEdited)
                case .quantity:
                    DetailQuantityView(item: item, quantity: $quantity, isEdited: $isEdited)
                case .category:
                    DetailKindView(item: item, kind: $kind, isEdited: $isEdited, geometry: geometry)
                case .brand:
                    DetailBrandView(item: item, brand: $brand, isEdited: $isEdited, geometry: geometry)
                case .seller:
                    DetailSellerView(item: item, seller: $seller, isEdited: $isEdited, geometry: geometry)
                case .obtained:
                    //TODO: isObtainedDateEdited <-> isEdited
                    DetailObtainedView(item: item, obtained: $obtained, isEdited: $isObtainedDateEdited, geometry: geometry)
                case .buyPrice:
                    DetailBuyPriceView(item: item, buyPrice: $buyPrice, buyCurrency: $buyCurrency, isEdited: $isEdited, geometry: geometry)
                case .disposed:
                    //TODO: isDisposedDateEdited <-> isEdited
                    DetailDisposedView(item: item, disposed: $disposed, isEdited: $isDisposedDateEdited, geometry: geometry)
                case .sellPrice:
                    DetailSellPriceView(item: item, sellPrice: $sellPrice, sellCurrency: $sellCurrency, isEdited: $isEdited, geometry: geometry)
                }
            }
        }
    }
    
    private var footer: some View {
        VStack {
            HStack {
                Spacer()
                
                SectionTitleView(title: .created)

                Text("\(item.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
            
            HStack {
                Spacer()
                
                SectionTitleView(title: .updated)
              
                Text("\(item.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
        }
    }
}

