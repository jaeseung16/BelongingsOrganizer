//
//  DetailSellerView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailSellerView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    var item: Item
    @Binding var seller: Seller?
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentChooseSellerView = false
    private var itemSeller: Seller? {
        item.seller?.compactMap { $0 as? Seller }.first
    }
    
    var body: some View {
        HStack {
            SectionTitleView(title: .seller)
            
            Spacer()
            
            if seller == nil {
                Text(itemSeller?.name ?? "")
            } else {
                Text(seller!.name ?? "")
            }
            
            Button {
                seller = itemSeller
                presentChooseSellerView = true
            } label: {
                Text("edit")
            }
        }
        .sheet(isPresented: $presentChooseSellerView) {
            #if os(macOS)
            ChooseSellerView(seller: $seller)
                .environmentObject(viewModel)
                .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                .onChange(of: seller) { _ in
                    isEdited = true
                }
            #else
            ChooseSellerView(seller: $seller)
                .environmentObject(viewModel)
                .onChange(of: seller) { _ in
                    isEdited = true
                }
            #endif
        }
    }
}
