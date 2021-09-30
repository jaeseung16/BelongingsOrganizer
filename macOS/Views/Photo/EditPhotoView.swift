//
//  MacEditPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/26/21.
//

import SwiftUI
import SDWebImageWebPCoder

struct EditPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State var originalImage: Data?
    @Binding var image: Data?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if image != nil {
                    Image(nsImage: NSImage(data: image!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if originalImage != nil {
                    Image(nsImage: NSImage(data: originalImage!)!)
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
                        let openPanel = NSOpenPanel()
                        openPanel.prompt = "Select File"
                        openPanel.allowsMultipleSelection = false
                        openPanel.canChooseDirectories = false
                        openPanel.canCreateDirectories = false
                        openPanel.canChooseFiles = true
                        openPanel.allowedFileTypes = ["png","jpg","jpeg","webp"]
                        
                        openPanel.begin { (result) -> Void in
                            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                                let url = openPanel.url!
                                
                                if url.absoluteString.contains(".webp") {
                                    if let data: Data = try? Data(contentsOf: url) {
                                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                                        self.image = image?.tiffRepresentation
                                    }
                                } else {
                                    self.image = try? Data(contentsOf: url)
                                }
                            }
                        }
                    } label: {
                        Text("Select an image")
                    }
                }
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
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
