//
//  ItemsView.swift
//  Belongings Organizer (macOS)
//
//  Created by Jae Seung Lee on 9/30/21.
//

import SwiftUI

struct ItemsView: View {
    @State private var path: [Item] = []
    
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
        NavigationStack {
            List {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        ItemRowView(item: item, imageWidth: 40.0)
                    }
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemSummaryView(item: item)
                    .id(UUID())
            }
        }
        
    }
}

