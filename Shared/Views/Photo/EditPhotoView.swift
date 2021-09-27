//
//  EditPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/20/21.
//

#if !os(macOS)
import SwiftUI

struct EditPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State var originalImage: Data?
    @Binding var image: Data?

    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: Data?
    @State private var isImagePickerDisplay = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if image != nil {
                    Image(uiImage: UIImage(data: image!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if originalImage != nil {
                    Image(uiImage: UIImage(data: originalImage!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
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
}
#endif
