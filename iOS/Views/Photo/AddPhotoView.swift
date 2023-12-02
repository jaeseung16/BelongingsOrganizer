//
//  AddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

import SwiftUI
import UniformTypeIdentifiers
import SDWebImageWebPCoder
import PhotosUI

struct AddPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel

    @Binding var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showImagePickerView = false
    @State private var progress: Progress?
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var failed = false
    @State private var details = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if progress != nil && !(progress!.isFinished) {
                    ProgressView(progress!)
                }
                
                photoView()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .onLongPressGesture {
                        pasteImage()
                    }
                    .onDrop(of: ["public.image", "public.file-url"], delegate: self)
                
                Divider()
                
                footer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $showAlert) {
                PhotoAlertView(isPresenting: $showAlert)
                    .padding()
                    .frame(minHeight: 120.0)
            }
            .sheet(isPresented: $showImagePickerView) {
                ImagePickerView(selectedImage: $photo, sourceType: .camera)
                    .environmentObject(viewModel)
                    .padding()
            }
            .alert("Cannot add a photo", isPresented: $failed, presenting: details) { details in
                Button("Dismiss") {
                    
                }
            }
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photo = viewModel.tryResize(image: data)
                    }
                }
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Label("Cancel", systemImage: "chevron.backward")
            }
            
            Spacer()
            
            Button {
                viewModel.updateImage(photo)
                dismiss.callAsFunction()
            } label: {
                Text("Done")
            }
        }
    }
    
    private func photoView() -> Image {
        if photo != nil {
            return Image(uiImage: UIImage(data: photo!)!)
        } else {
            return Image(systemName: "photo.on.rectangle")
        }
    }
    
    private func footer() -> some View {
        HStack {
            Button {
                showImagePickerView = true
            } label: {
                Label("Camera", systemImage: "camera")
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            
            Spacer()
            
            PhotosPicker(selection: $selectedPhoto, matching: .any(of: [.images])) {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
            
            if viewModel.hasImage() {
                Spacer()
                
                Button {
                    pasteImage()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard.fill")
                }
            }
        }
    }
    
    private func pasteImage() -> Void {
        viewModel.paste { data, _ in
            if let data = data {
                photo = data
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        viewModel.getData(from: info) { data, error in
            guard let data = data else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                self.photo = nil
                failed.toggle()
                return
            }
            
            self.photo = data
        }
        
        return photo != nil
    }
}
