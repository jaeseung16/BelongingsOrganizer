//
//  BrandRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct BrandRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    var name: String?
    var itemCount = 0
    
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
    }
    
}

