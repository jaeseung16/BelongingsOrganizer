//
//  BrandRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct BrandRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var brand: Brand {
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
        name = brand.name
        itemCount = brand.items?.count ?? 0
    }
}

