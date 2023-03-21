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
            
            #if os(macOS)
            NavigationView {
                itemList()
            }
            #else
            itemList()
            #endif
        }
    }
    
    private func itemList() -> some View {
        List {
            ForEach(items) { item in
                NavigationLink(destination: ItemSummaryView(item: item)) {
                    ItemRowView(item: item, imageWidth: 40.0)
                }
            }
        }
    }
}

