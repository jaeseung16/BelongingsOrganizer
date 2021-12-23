//
//  BrandRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct BrandRowView: View {
    var brand: Brand
    var name: String
    
    var body: some View {
        HStack {
            Text(name)
            
            Spacer()
            
            if let items = brand.items {
                Text("\(items.count) items")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}

