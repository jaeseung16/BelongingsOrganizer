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
    @State private var isImagePickerDisplay = false
    @State private var isPHPickerDisplay = false
    @State private var progress: Progress?
    
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
                        isImagePickerDisplay = true
                    } label: {
                        Text("Take a photo")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    
                    Spacer()
                    
                    Button {
                        selectedImage = nil
                        progress = nil
                        isPHPickerDisplay = true
                    } label: {
                        Text("Select a photo")
                    }
                }
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $isImagePickerDisplay) {
                ImagePickerView(selectedImage: $selectedImage, sourceType: .camera)
                    .padding()
            }
            .sheet(isPresented: $isPHPickerDisplay) {
                PHPickerView(selectedImage: $selectedImage, progress: $progress)
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
