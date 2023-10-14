//
//  InputBrandView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputBrandView: View {
    @EnvironmentObject private var viewModel: BelongingsViewModel
    
    @Binding var brand: Brand?
    let geometry: GeometryProxy
    @State private var presentBrandView = false
    
    var body: some View {
        VStack {
            HStack {
                Text("BRAND")
                    .font(.caption)
                Spacer()
                Button {
                    viewModel.fetchAllBrands()
                    presentBrandView = true
                } label: {
                    Label("add", systemImage: "plus")
                }
            }
            
            if brand == nil {
                Text("brand")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background { CommonRoundedRectangle() }
            } else {
                Text(brand!.name ?? "N/A")
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background { CommonRoundedRectangle() }
            }
        }
        .sheet(isPresented: $presentBrandView, content: {
            ChooseBrandView(brand: $brand)
                .environmentObject(viewModel)
                .frame(width: geometry.size.width, height: geometry.size.height)
        })
    }
}
