//
//  BrandRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct BrandRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var brand: BrandDTO {
        didSet {
            refresh()
        }
    }
    
    @State private var name: String?
    @State private var itemCount = 0
    
    var body: some View {
        HStack {
            if let name = name {
                Text(name)
            }
            
            Spacer()
            
            Text("\(itemCount) items")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .onReceive(viewModel.$updated) { _ in
            refresh()
        }
    }
    
    private func refresh() {
        if let id = brand.id, let brandEntity: Brand = viewModel.get(entity: .Brand, id: id) {
            name = brandEntity.name
            itemCount = brandEntity.items?.count ?? 0
        } else {
            name = brand.name
            itemCount = 0
        }
    }
}

