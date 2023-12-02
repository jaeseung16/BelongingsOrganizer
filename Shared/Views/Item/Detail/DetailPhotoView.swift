//
//  DetailPhotoView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailPhotoView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    let originalImage: Data?
    @Binding var imageData: Data?
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentPhotoView = false
    
    #if os(macOS)
    private var image: NSImage? {
        if let data = imageData {
            return NSImage(data: data)
        } else if let data = originalImage {
            return NSImage(data: data)
        } else {
            return nil
        }
    }
    #else
    private var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        } else if let data = originalImage {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    #endif

    var body: some View {
        VStack {
            HStack {
                SectionTitleView(title: .photo)
                
                Spacer()
                
                Button {
                    presentPhotoView = true
                    viewModel.persistenceHelper.reset()
                } label: {
                    Text("edit")
                }
                .buttonStyle(.borderless)
            }
            
            if imageData == nil {
                Text("Photo")
                    .foregroundColor(.secondary)
            } else {
                #if os(macOS)
                Image(nsImage: image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                #else
                Image(uiImage: image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                #endif
            }
        }
        .sheet(isPresented: $presentPhotoView) {
            #if os(macOS)
            EditPhotoView(originalImage: originalImage, image: $imageData)
                .environmentObject(viewModel)
                .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.5 * geometry.size.height)
            #else
            EditPhotoView(originalImage: originalImage, image: $imageData)
                .environmentObject(viewModel)
            #endif
        }
        .onChange(of: imageData) { _ in
            isEdited = true
        }
    }
}
