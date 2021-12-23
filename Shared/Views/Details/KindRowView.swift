//
//  KindRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct KindRowView: View {
    var kind: Kind
    var name: String
    
    var body: some View {
        HStack {
            Text(name)
            
            Spacer()
            
            if let items = kind.items {
                Text("\(items.count) items")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}
