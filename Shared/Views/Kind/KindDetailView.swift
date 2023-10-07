//
//  KindDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/12/21.
//

import SwiftUI

struct KindDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var kind: Kind
    @State var name = ""
    var items: [Item]
    
    @State private var isEdited = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header
                
                Divider()
                
                detail
                
                Divider()
                
                ItemsView(items: items)
            }
            .navigationTitle(name)
            .padding()
        }
    }
    
    private func reset() {
        name = kind.name ?? ""
        
        isEdited = false
    }
    
    private var header: some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            viewModel.kindDTO = KindDTO(id: kind.uuid, name: name)
            isEdited = false
        }
    }
    
    private var detail: some View {
        VStack {
            NameView(name: $name, isEdited: $isEdited) {
                EmptyView()
            }
            DateSectionView(sectionTitle: .added, date: kind.created ?? Date())
            DateSectionView(sectionTitle: .updated, date: kind.lastupd ?? Date())
        }
    }
    
}

