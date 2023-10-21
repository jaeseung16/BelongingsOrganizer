//
//  ItemDetailView2.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/18/23.
//

import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var item: Item
    @State var dto: ItemDTO
    
    @State private var isEdited = false
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
    
    private var header: some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            isEdited = false
            viewModel.update(dto, kind: dto.kind, brand: dto.brand, seller: dto.seller, isObtainedDateEdited, isDisposedDateEdited)
        }
    }
    
    private func reset() -> Void {
        isEdited = false
        isDisposedDateEdited = false
        isObtainedDateEdited = false
    }
    
    private var itemKinds: [Kind] {
        item.kind?.compactMap { $0 as? Kind } ?? [Kind]()
    }
    
    private var itemBrand: Brand? {
        return item.brand?.compactMap { $0 as? Brand }.first
    }
    
    private var itemSeller: Seller? {
        item.seller?.compactMap { $0 as? Seller }.first
    }

    private func itemInfo(in geometry: GeometryProxy) -> some View {
        List {
            DetailNameView(originalName: item.name, name: $dto.name, isEdited: $isEdited)

            DetailPhotoView(originalImage: item.image, imageData: $dto.image, isEdited: $isEdited, geometry: geometry)
            
            DetailKindView(originalKind: itemKinds, kind: $dto.kind, isEdited: $isEdited, geometry: geometry)

            DetailBrandView(originalBrand: itemBrand, brand: $dto.brand, isEdited: $isEdited, geometry: geometry)

            DetailSellerView(originalSeller: itemSeller, seller: $dto.seller, isEdited: $isEdited, geometry: geometry)
            
            DetailQuantityView(originalQuantity: Int(item.quantity), quantity: $dto.quantity, isEdited: $isEdited)
  
            DetailDateView(title: .obtained, originalDate: item.obtained, date: $dto.obtained, isEdited: $isObtainedDateEdited, geometry: geometry)
   
            DetailPriceView(originalPrice: item.buyPrice, originalCurrency: item.buyCurrency, price: $dto.buyPrice, currency: $dto.buyCurrency, isEdited: $isEdited, geometry: geometry)
        
            DetailDateView(title: .disposed, originalDate: item.disposed, date: $dto.disposed, isEdited: $isDisposedDateEdited, geometry: geometry)
      
            DetailPriceView(originalPrice: item.sellPrice, originalCurrency: item.sellCurrency, price: $dto.sellPrice, currency: $dto.sellCurrency, isEdited: $isEdited, geometry: geometry)
            
            DetailNoteView(originalNote: item.note, note: $dto.note, isEdited: $isEdited)
        }
        .onChange(of: isObtainedDateEdited) { _ in
            if !isEdited && isObtainedDateEdited {
                isEdited = true
            }
        }
        .onChange(of: isDisposedDateEdited) { _ in
            if !isEdited && isDisposedDateEdited {
                isEdited = true
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
