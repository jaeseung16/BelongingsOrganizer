//
//  AddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

import SwiftUI

struct AddPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    /*
    #if targetEnvironment(macCatalyst)
    @State private var selectedImage: NSImage?
    @Binding var image: NSImage?
    #else
 */
    
    @State private var selectedImage: Data?
    @Binding var image: Data?
    
    #if !os(macOS)
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    #endif
    //#endif
    
    
    @State private var isImagePickerDisplay = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if selectedImage != nil {
                    #if os(macOS)
                    Image(nsImage: NSImage(data: selectedImage!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #else
                    Image(uiImage: UIImage(data: selectedImage!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #endif
                    //Image(selectedImage!, scale: 0.1, label: Text("image"))
                        
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
                                selectedImage = try? Data(contentsOf: url)
                                //let nsImage = NSImage(contentsOf: url)
                                
                                //selectedImage = nsImage?.cgImage(forProposedRect: nil, context: nil, hints: nil)
                            }
                        }
                    } label: {
                        Text("Select an image")
                    }
                    /*
                    Spacer()
                    
                    Button {
                        sourceType = .photoLibrary
                        isImagePickerDisplay = true
                    } label: {
                        Text("Select a photo")
                    }
                    */
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
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })
            
            Spacer()
            
            Text("Choose a photo")
            
            Spacer()
            
            Button(action: {
                image = selectedImage
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
            })
        }
        
    }
}
