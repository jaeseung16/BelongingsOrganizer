//
//  AddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

import SwiftUI
import UniformTypeIdentifiers
import SDWebImageWebPCoder

struct AddPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State private var selectedImage: Data?
    @State private var showImagePickerView = false
    @State private var showPHPickerView = false
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
                ImagePickerView(selectedImage: $selectedImage, sourceType: .camera)
                    .padding()
            }
            .sheet(isPresented: $showPHPickerView) {
                PHPickerView(selectedImage: $selectedImage, progress: $progress) { success, errorString in
                    errorMessage = errorString ?? ""
                    showAlert = !success
                }
                    .padding()
            }
            .alert("Cannot add a photo", isPresented: $failed, presenting: details) { details in
                Button("Dismiss") {
                    
                }
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                dismiss.callAsFunction()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })
            
            Spacer()
            
            Button(action: {
                viewModel.updateImage(selectedImage)
                dismiss.callAsFunction()
            }, label: {
                Text("Done")
            })
        }
    }
    
    private func photoView() -> Image {
        if selectedImage != nil {
            return Image(uiImage: UIImage(data: selectedImage!)!)
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
            
            Button {
                progress = nil
                showPHPickerView = true
            } label: {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
            
            if ImagePaster.hasImage() {
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
        ImagePaster.paste { data, _ in
            if let data = data {
                selectedImage = data
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        ImagePaster.getData(from: info) { data, error in
            guard let data = data else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                self.selectedImage = nil
                failed.toggle()
                return
            }
            
            self.selectedImage = data
        }
        
        return selectedImage != nil
    }
}
