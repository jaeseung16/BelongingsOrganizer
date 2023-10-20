//
//  DetailBrandView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailBrandView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    let originalBrand: Brand?
    @Binding var brand: Brand?
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentChooseBrandView = false
    
    var body: some View {
        HStack {
            SectionTitleView(title: .brand)
            
            Spacer()
            
            if brand == nil {
                Text(originalBrand?.name ?? "")
            } else {
                Text(brand!.name ?? "")
            }
            
            Button {
                brand = originalBrand
                presentChooseBrandView = true
            } label: {
                Text("edit")
            }
        }
        .sheet(isPresented: $presentChooseBrandView) {
            #if os(macOS)
            ChooseBrandView(brand: $brand)
                .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                .onChange(of: brand) { _ in
                    isEdited = true
                }
            #else
            ChooseBrandView(brand: $brand)
                .onChange(of: brand) { _ in
                    isEdited = true
                }
            #endif
        }
    }
}
