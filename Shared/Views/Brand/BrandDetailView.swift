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
            .alert("Invalid URL", isPresented: $showAlert, actions: {
                Button("Dismiss")  {
                    urlString = brand.url?.absoluteString ?? ""
                }
            }, message: {
                Text("Cannot access the URL. Try a different one or leave it empty.")
            })
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
            viewModel.brandDTO = BrandDTO(id: brand.uuid, name: name, url: URL(string: urlString))
            isEdited = false
        }
    }
    
    private var detail: some View {
        VStack {
            NameView(name: $name, isEdited: $isEdited) {
                EmptyView()
            }
            URLView(title: .url, url: brand.url, urlString: $urlString, isEdited: $isEdited, showProgress: $showProgress, showAlert: $showAlert) {
                EmptyView()
            }
            .environmentObject(viewModel)
            DateSectionView(sectionTitle: .added, date: brand.created ?? Date())
            DateSectionView(sectionTitle: .updated, date: brand.lastupd ?? Date())
        }
    }
    
}

