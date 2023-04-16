//
//  ItemRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/19/21.
//

import SwiftUI

struct ItemRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var item: Item
    var imageWidth: CGFloat = 50
    
    var body: some View {
        HStack {
            if let imageData = item.image {
            #if os(macOS)
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageWidth)
                }
            #else
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageWidth)
                }
            #endif
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageWidth)
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

