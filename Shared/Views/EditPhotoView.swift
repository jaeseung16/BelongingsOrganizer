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
    
    #if !os(macOS)
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    #endif

    @State private var isImagePickerDisplay = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if image != nil {
                    #if os(macOS)
                    Image(nsImage: NSImage(data: image!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #else
                    Image(uiImage: UIImage(data: image!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #endif
                } else if originalImage != nil {
                    #if os(macOS)
                    Image(nsImage: NSImage(data: originalImage!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #else
                    Image(uiImage: UIImage(data: originalImage!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #endif
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                Divider()
                
                #if os(macOS)
                HStack {
                    Button {
                        let openPanel = NSOpenPanel()
                        openPanel.prompt = "Select File"
                        openPanel.allowsMultipleSelection = false
                        openPanel.canChooseDirectories = false
                        openPanel.canCreateDirectories = false
                        openPanel.canChooseFiles = true
                        openPanel.allowedFileTypes = ["png","jpg","jpeg"]
                        openPanel.begin { (result) -> Void in
                            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                                let url = openPanel.url!
                                self.image = try? Data(contentsOf: url)
                            }
                        }
                    } label: {
                        Text("Select an image")
                    }
                }
                #else
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
                #endif
                
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $isImagePickerDisplay) {
                #if os(macOS)
                #else
                ImagePickerView(selectedImage: $selectedImage, sourceType: sourceType)
                    .padding()
                #endif
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
