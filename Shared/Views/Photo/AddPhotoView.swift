//
//  AddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

#if !os(macOS)
import SwiftUI

struct AddPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: AddItemViewModel

    @State private var selectedImage: Data?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isImagePickerDisplay = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                photoView()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                Divider()
                
                HStack {
                    Button {
                        sourceType = .camera
                        isImagePickerDisplay = true
                    } label: {
                        Text("Take a photo")
                    }
                    
                    Spacer()
                    
                    Button {
                        sourceType = .photoLibrary
                        isImagePickerDisplay = true
                    } label: {
                        Text("Select a photo")
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $isImagePickerDisplay) {
                ImagePickerView(selectedImage: $selectedImage, sourceType: sourceType)
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
#endif
