//
//  BrandKinsSellerRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/6/23.
//

import SwiftUI

struct BrandKindSellerRowView: View {
    var name: String
    var itemCount: Int
    
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
