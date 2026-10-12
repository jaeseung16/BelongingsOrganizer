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
                SectionTitleView(title: .items)
                
                Spacer()
            }
            
            itemList
        }
    }
    
    private var itemList: some View {
        List {
            ForEach(items) { item in
                AnotherItemSummaryView(item: item)
                    .id(item)
                    .frame(height: 60)
            }
        }
    }
}

