//
//  SellerRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct SellerRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var name: String
    @State var itemCount: Int
    
    var body: some View {
        HStack {
            Text(name)
            
            Spacer()
            
            Text("\(itemCount) items")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
    
}

