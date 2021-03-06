//
//  MacEditPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/26/21.
//

import SwiftUI
import SDWebImageWebPCoder

struct EditPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    
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
                    .frame(height: 100)
                    .onDrop(of: ["public.image", "public.file-url"], delegate: self)
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                image = originalImage
                dismiss.callAsFunction()
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
                dismiss.callAsFunction()
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
    
    func performDrop(info: DropInfo) -> Bool {
        ImagePaster.loadData(from: info) { data, _ in
            if let imageData = data {
                if imageData.count > ImagePaster.maxDataSize, let nsImage = NSImage(data: imageData) {
                    if let resized = ImagePaster.resize(nsImage: nsImage, within: ImagePaster.maxResizeSize).tiffRepresentation,
                       let imageRep = NSBitmapImageRep(data: resized) {
                        image = imageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                    } else {
                        image = imageData
                    }
                } else {
                    image = imageData
                }
            }
        }
        
        ImagePaster.loadFile(from: info) { item, error in
            if let url = URL(dataRepresentation: item as! Data, relativeTo: nil) {
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
        
        return image != nil
    }
}
