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
                image = nil
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })
            
            Spacer()
            
            SelectImageButton { url in
                if url.absoluteString.contains(".webp") {
                    if let data: Data = try? Data(contentsOf: url) {
                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                        self.image = image?.tiffRepresentation
                    }
                } else {
                    self.image = try? Data(contentsOf: url)
                }
            }
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
            })
        }
    }
    
    private func photoView() -> Image {
        if image != nil {
            return Image(nsImage: NSImage(data: image!)!)
        } else if originalImage != nil {
            return Image(nsImage: NSImage(data: originalImage!)!)
        } else {
            return Image(systemName: "photo.on.rectangle")
        }
    }
}
