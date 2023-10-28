//
//  DetailSellerView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailSellerView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    let originalSeller: Seller?
    @Binding var seller: Seller?
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentChooseSellerView = false
    
    var body: some View {
        HStack {
            SectionTitleView(title: .seller)
            
            Spacer()
            
            if seller == nil {
                Text(originalSeller?.name ?? "")
            } else {
                Text(seller!.name ?? "")
            }
            
            Button {
                seller = originalSeller
                presentChooseSellerView = true
            } label: {
                Text("edit")
            }
            .buttonStyle(.borderless)
        }
        .sheet(isPresented: $presentChooseSellerView) {
            #if os(macOS)
            ChooseSellerView(seller: $seller)
                .environmentObject(viewModel)
                .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
            #else
            ChooseSellerView(seller: $seller)
                .environmentObject(viewModel)
                
            #endif
        }
        .onChange(of: seller) { _ in
            isEdited = true
        }
    }
}
