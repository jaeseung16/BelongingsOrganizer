//
//  ItemRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/19/21.
//

import SwiftUI

struct ItemRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @ObservedObject var item: Item
    var imageWidth: CGFloat = 50
    
    var body: some View {
        HStack {
            ItemThumbnailView(item: item, size: CGSize(width: imageWidth, height: imageWidth)) {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageWidth, height: imageWidth)
            }
            
            Spacer()
                .frame(width: 8)
            
            VStack {
                HStack {
                    Text(item.name ?? "")
                    Spacer()
                }
                
                if let date = item.obtained {
                    HStack {
                        Spacer()
                        #if os(macOS)
                        Text("\(date, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        #else
                        Text(date, style: .date)
                            .font(.callout)
                            .foregroundColor(.secondary)
                        #endif
                    }
                }
            }
        }
    }

}

