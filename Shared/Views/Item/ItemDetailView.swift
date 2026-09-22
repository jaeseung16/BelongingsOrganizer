//
//  ItemDetailView2.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/18/23.
//

import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @ObservedObject var item: Item
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
            viewModel.update(item, to: dto, kind: dto.kind, brand: dto.brand, seller: dto.seller, isObtainedDateEdited, isDisposedDateEdited)
        }
    }
    
    private func reset() -> Void {
        isEdited = false
        isDisposedDateEdited = false
        isObtainedDateEdited = false
    }
    
    private func itemInfo(in geometry: GeometryProxy) -> some View {
        List {
            DetailNameView(originalName: item.name, name: $dto.name, isEdited: $isEdited)

            DetailPhotoView(originalImage: item.image, imageData: $dto.image, isEdited: $isEdited, geometry: geometry)
            
            DetailKindView(originalKind: item.kinds, kind: $dto.kind, isEdited: $isEdited, geometry: geometry)

            DetailBrandView(originalBrand: item.firstBrand, brand: $dto.brand, isEdited: $isEdited, geometry: geometry)

            DetailSellerView(originalSeller: item.firstSeller, seller: $dto.seller, isEdited: $isEdited, geometry: geometry)
            
            DetailQuantityView(originalQuantity: Int(item.quantity), quantity: $dto.quantity, isEdited: $isEdited)
  
            DetailDateView(title: .obtained, originalDate: item.obtained, date: $dto.obtained, isEdited: $isObtainedDateEdited)
   
            DetailPriceView(originalPrice: item.buyPrice, originalCurrency: item.buyCurrency, price: $dto.buyPrice, currency: $dto.buyCurrency, isEdited: $isEdited)
        
            DetailDateView(title: .disposed, originalDate: item.disposed, date: $dto.disposed, isEdited: $isDisposedDateEdited)
      
            DetailPriceView(originalPrice: item.sellPrice, originalCurrency: item.sellCurrency, price: $dto.sellPrice, currency: $dto.sellCurrency, isEdited: $isEdited)
            
            DetailNoteView(originalNote: item.note, note: $dto.note, isEdited: $isEdited)
        }
        .onChange(of: isObtainedDateEdited) {
            if !isEdited && isObtainedDateEdited {
                isEdited = true
            }
        }
        .onChange(of: isDisposedDateEdited) {
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
