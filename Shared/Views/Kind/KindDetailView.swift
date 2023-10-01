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
                header()
                
                Divider()
                
                nameView()
                
                addedView()
                
                lastUpdatedView()
                
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
    
    private func header() -> some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            viewModel.kindDTO = KindDTO(id: kind.uuid, name: name)
            isEdited = false
        }
    }
    
    private func nameView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: .name)
                
                Spacer()
            }
            
            TextField(kind.name ?? "", text: $name, prompt: nil)
                .onSubmit {
                    isEdited = true
                }
        }
    }

    private func addedView() -> some View {
        DateSectionView(sectionTitle: .added, date: kind.created ?? Date())
    }
    
    private func lastUpdatedView() -> some View {
        DateSectionView(sectionTitle: .updated, date: kind.lastupd ?? Date())
    }
}

