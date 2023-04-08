//
//  KindRowView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/23/21.
//

import SwiftUI

struct KindRowView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var kind: KindDTO {
        didSet {
            refresh()
        }
    }
    
    @State private var name: String?
    @State private var itemCount = 0
    
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
        .onReceive(viewModel.$updated) { _ in
            refresh()
        }
    }
    
    private func refresh() {
        if let id = kind.id, let kindEntity: Kind = viewModel.get(entity: .Kind, id: id) {
            name = kind.name
            itemCount = kindEntity.items?.count ?? 0
        } else {
            name = kind.name
            itemCount = 0
        }
    }
}
