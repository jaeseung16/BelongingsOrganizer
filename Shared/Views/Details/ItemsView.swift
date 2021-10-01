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
                List {
                    ForEach(items) { item in
                        NavigationLink(destination: ItemSummaryView(item: item)) {
                            VStack(alignment: .leading) {
                                HStack {
                                    if let imageData = item.image, let nsImage = NSImage(data: imageData) {
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 100)
                                    }
                                    Text(item.name ?? "")
                                }
                            }
                        }
                    }
                }
            }
            #else
            List {
                ForEach(items) { item in
                    NavigationLink(destination: ItemSummaryView(item: item)) {
                        VStack(alignment: .leading) {
                            HStack {
                                if let imageData = item.image, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                }
                                Text(item.name ?? "")
                            }
                        }
                    }
                }
            }
            #endif
        }
    }
}

