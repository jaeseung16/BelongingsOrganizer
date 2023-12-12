//
//  InputPhotoView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputPhotoView: View {
    @EnvironmentObject private var viewModel: BelongingsViewModel
    
    @Binding var image: Data?
    let geometry: GeometryProxy
    @State private var presentPhotoView = false
    
    var body: some View {
        VStack {
            HStack {
                Text("PHOTO")
                    .font(.caption)
                Spacer()
                Button {
                    presentPhotoView = true
                } label: {
                    Label("add", systemImage: "plus")
                }
            }
            
            if image == nil {
                Label("photo", systemImage: "photo.on.rectangle")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background { CommonRoundedRectangle() }
            } else {
                #if os(macOS)
                Image(nsImage: NSImage(data: image!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background{ CommonRoundedRectangle() }
                    .frame(height: 100)
                #else
                Image(uiImage: UIImage(data: image!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background { CommonRoundedRectangle() }
                    .frame(height: 100)
                #endif
            }
        }
        .sheet(isPresented: $presentPhotoView, content: {
            #if os(macOS)
            AddPhotoView(photo: $image)
                .environmentObject(viewModel)
                .frame(width: geometry.size.width, height: geometry.size.height)
            #else
            AddPhotoView(photo: $image)
                .environmentObject(viewModel)
                .frame(width: geometry.size.width, height: geometry.size.height)
            #endif
        })
        
    }
}
