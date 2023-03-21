//
//  SellerRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct SellerRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var seller: Seller {
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
        name = seller.name
        itemCount = seller.items?.count ?? 0
    }
}

