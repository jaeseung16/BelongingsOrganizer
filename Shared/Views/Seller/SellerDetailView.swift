//
//  SellerDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/14/21.
//

import SwiftUI

struct SellerDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var seller: Seller
    @State var name = ""
    @State var urlString = ""
    var items: [Item]
    
    @State private var showAlert = false
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
    
    private var header: some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            update()
        }
    }
    
    private func reset() {
        name = seller.name ?? ""
        urlString = seller.url?.absoluteString ?? ""
        isEdited = false
    }
    
    private func update() {
        viewModel.update(SellerDTO(id: seller.uuid, name: name, url: URL(string: urlString)))
        isEdited = false
    }
    
    private var detail: some View {
        VStack {
            NameView(name: $name, isEdited: $isEdited) {
                EmptyView()
            }
            URLView(title: .url, url: seller.url, urlString: $urlString, isEdited: $isEdited, showProgress: $showProgress) {
                EmptyView()
            }
            .environmentObject(viewModel)
            DateSectionView(sectionTitle: .added, date: seller.created ?? Date())
            DateSectionView(sectionTitle: .updated, date: seller.lastupd ?? Date())
        }
    }
    
}
