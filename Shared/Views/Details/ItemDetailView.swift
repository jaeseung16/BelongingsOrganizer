//
//  ItemDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct ItemDetailView: View {
    @State var item: Item
    
    var body: some View {
        VStack {
            Text("\(item.name ?? "")")
            Text("price: \(item.currency ?? "") \(item.buyPrice)")
            Text("obtained: \(item.obtained ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
            Text("added: \(item.created!, formatter: BelongingsViewModel.dateFormatter)")
        }
    }
}

