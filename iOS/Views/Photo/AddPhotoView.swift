//
//  AddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

import SwiftUI

struct AddPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: AddItemViewModel

    @State private var selectedImage: Data?
    @State private var showImagePickerView = false
    @State private var showPHPickerView = false
    @State private var progress: Progress?
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var showProgress = false
    
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
                VStack {
                    Spacer()
                    
                    Text("Unable to Load the Photo")
                        .font(.headline)
                    
                    Text("Please try a different photo")
                        .font(.callout)
                    
                    Divider()
                    
                    Button {
                        showAlert.toggle()
                    } label: {
                        Text("Dismiss")
                    }
                    
                    Spacer()
                }
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
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })
            
            Spacer()
            
            Text("Choose a photo")
            
            Spacer()
            
            Button(action: {
                viewModel.imageData = selectedImage
                presentationMode.wrappedValue.dismiss()
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
}
