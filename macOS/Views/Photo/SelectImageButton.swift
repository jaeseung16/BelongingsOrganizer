//
//  SelectImageButton.swift
//  Belongings Organizer (macOS)
//
//  Created by Jae Seung Lee on 9/30/21.
//

import SwiftUI

struct SelectImageButton: View {
    
    var completionHandler: (URL) -> Void
    
    var body: some View {
        Button {
            selectImage()
        } label: {
            Text("Select an image")
        }
    }
    
    private func selectImage() -> Void {
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
                
                completionHandler(url)
                /*
                if url.absoluteString.contains(".webp") {
                    if let data: Data = try? Data(contentsOf: url) {
                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                        self.selectedImage = image?.tiffRepresentation
                    }
                } else {
                    self.selectedImage = try? Data(contentsOf: url)
                }
                 */
            }
        }
    }
}

struct SelectImageButton_Previews: PreviewProvider {
    static var previews: some View {
        SelectImageButton { url in
            print("\(url)")
        }
    }
}
