//
//  EditPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/20/21.
//

import SwiftUI

struct EditPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State var originalImage: Data?
    @Binding var image: Data?

    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImagePickerView = false
    @State private var showPHPickerView = false
    @State private var progress: Progress?
    @State private var showAlert = false
    @State private var errorMessage = ""
    
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
                ImagePickerView(selectedImage: $image, sourceType: .camera)
                    .padding()
            }
            .sheet(isPresented: $showPHPickerView) {
                PHPickerView(selectedImage: $image, progress: $progress) { success, errorString in
                    errorMessage = errorString ?? ""
                    showAlert = !success
                }
                    .padding()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Unable to Load Image"),
                      message: Text(errorMessage),
                      dismissButton: .default(Text("Dismiss")))
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                image = nil
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
            })
        }
    }
    
    private func photoView() -> Image {
        if image != nil {
            return Image(uiImage: UIImage(data: image!)!)
        } else if originalImage != nil {
            return Image(uiImage: UIImage(data: originalImage!)!)
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
                image = nil
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
                image = data
            }
        }
    }
}
