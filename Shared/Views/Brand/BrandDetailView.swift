//
//  BrandDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/14/21.
//

import SwiftUI

struct BrandDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var brand: Brand
    @State var name = ""
    @State var urlString = ""
    var items: [Item]
    
    @State private var isEdited = false
    @State private var showProgress = false
    
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
            .overlay {
                ProgressView("Please wait...")
                    .progressViewStyle(.circular)
                    .opacity(showProgress ? 1 : 0)
            }
        }
    }
    
    private func reset() {
        name = brand.name ?? ""
        urlString = brand.url?.absoluteString ?? ""
        
        isEdited = false
    }
    
    private var header: some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            viewModel.update(BrandDTO(id: brand.uuid, name: name, url: URL(string: urlString)))
            isEdited = false
        }
    }
    
    private var detail: some View {
        VStack {
            NameView(name: $name, isEdited: $isEdited) {
                EmptyView()
            }
            URLView(title: .url, url: brand.url, urlString: $urlString, isEdited: $isEdited, showProgress: $showProgress) {
                EmptyView()
            }
            .environmentObject(viewModel)
            DateSectionView(sectionTitle: .added, date: brand.created ?? Date())
            DateSectionView(sectionTitle: .updated, date: brand.lastupd ?? Date())
        }
    }
    
}

