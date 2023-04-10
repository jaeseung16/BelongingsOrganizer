//
//  KindDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/12/21.
//

import SwiftUI

struct KindDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var kind: KindDTO
    @State var name = ""
    var items: [ItemDTO]
    
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
            viewModel.kindDTO = KindDTO(id: kind.id, name: name)
            isEdited = false
        }
    }
    
    private func nameView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: "NAME")
                
                Spacer()
            }
            
            TextField(kind.name ?? "", text: $name, prompt: nil)
                .onSubmit {
                    isEdited = true
                }
        }
    }

    private func addedView() -> some View {
        HStack {
            SectionTitleView(title: "ADDED")
            
            Spacer()
            
            Text("\(kind.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
    
    private func lastUpdatedView() -> some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: "UPDATED")
            
            Text("\(kind.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
        }
    }
}

