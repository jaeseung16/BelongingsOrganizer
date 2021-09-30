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
                
                Divider()
                
                HStack {
                    Button {
                        showImagePickerView = true
                    } label: {
                        Text("Take a photo")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    
                    Spacer()
                    
                    Button {
                        image = nil
                        progress = nil
                        showPHPickerView = true
                    } label: {
                        Text("Select a photo")
                    }
                }
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
            
            Text("Choose a photo")
            
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
}
