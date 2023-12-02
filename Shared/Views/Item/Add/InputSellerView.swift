//
//  InputSellerView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputSellerView: View {
    @EnvironmentObject private var viewModel: BelongingsViewModel
    
    @Binding var seller: Seller?
    let geometry: GeometryProxy
    @State private var presentSellerView = false
    
    var body: some View {
        VStack {
            HStack {
                Text("SELLER")
                    .font(.caption)
                Spacer()
                Button {
                    viewModel.fetchAllSellers()
                    presentSellerView = true
                } label: {
                    Label("add", systemImage: "plus")
                }
            }
            
            if seller == nil {
                Text("seller")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background { CommonRoundedRectangle() }
            } else {
                Text(seller!.name ?? "N/A")
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background { CommonRoundedRectangle() }
            }
        }
        .sheet(isPresented: $presentSellerView, content: {
            ChooseSellerView(seller: $seller)
                .environmentObject(viewModel)
                .frame(width: geometry.size.width, height: geometry.size.height)
        })
    }
}
