//
//  MacAddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/21/21.
//

#if os(macOS)
import SwiftUI
import SDWebImageWebPCoder

struct MacAddPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: AddItemViewModel
    
    @State private var selectedImage: Data?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                photoView()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
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
            
            Button {
                openPanel()
            } label: {
                Text("Select an image")
            }
            
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
            return Image(nsImage: NSImage(data: selectedImage!)!)
        } else {
            return Image(systemName: "photo.on.rectangle")
        }
    }
    
    private func openPanel() -> Void {
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
                        self.selectedImage = image?.tiffRepresentation
                    }
                } else {
                    self.selectedImage = try? Data(contentsOf: url)
                }
            }
        }
    }
}

#endif
