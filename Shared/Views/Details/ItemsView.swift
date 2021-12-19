//
//  ItemsView.swift
//  Belongings Organizer (macOS)
//
//  Created by Jae Seung Lee on 9/30/21.
//

import SwiftUI

struct ItemsView: View {
    var items: [Item]
    
    var body: some View {
        VStack {
            HStack {
                Text("ITEMS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            NavigationView {
                List {
                    ForEach(items) { item in
                        NavigationLink(destination: ItemSummaryView(item: item)) {
                            ItemRowView(item: item, name: item.name ?? "", imageWidth: 40.0)
                        }
                    }
                }
            }
        }
    }
}

