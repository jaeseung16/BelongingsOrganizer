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
        openPanel.allowedContentTypes = [.png, .jpeg, .webP]
        
        openPanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let url = openPanel.url!
                
                completionHandler(url)
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
