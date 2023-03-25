//
//  MacAddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/21/21.
//

import SwiftUI
import SDWebImageWebPCoder
import UniformTypeIdentifiers

struct AddPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AddItemViewModel
    
    @State private var selectedImage: Data?
    @State private var isTargeted = false
    @State private var failed = false
    @State private var details = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                photoView()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                
                Divider()
                
                footer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onDrop(of: ["public.image", "public.file-url"], delegate: self)
        }
        .alert("Cannot add a photo", isPresented: $failed, presenting: details) { details in
            Button("Dismiss") {
                
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        ImagePaster.loadData(from: info) { data, error in
            var image: Data?
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
            
            if image == nil || NSImage(data: image!) == nil {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                image = nil
                failed.toggle()
            }
            
            self.selectedImage = image
            print("loadData: selectedImage = \(String(describing: selectedImage))")
        }
        
        ImagePaster.loadFile(from: info) { item, error in
            var imageData: Data?
            if let url = URL(dataRepresentation: item as! Data, relativeTo: nil) {
                if url.absoluteString.contains(".webp") {
                    if let data: Data = try? Data(contentsOf: url) {
                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                        imageData = image?.tiffRepresentation
                    }
                } else {
                    imageData = try? Data(contentsOf: url)
                }
            }
            
            if imageData == nil || NSImage(data: imageData!) == nil {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                imageData = nil
                failed.toggle()
            }
            
            self.selectedImage = imageData
            print("loadFile: selectedImage = \(String(describing: selectedImage))")
        }
        
        ImagePaster.download(from: info) { data, error in
            var imageData: Data?
            if let data = data {
                imageData = data
            } else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                failed.toggle()
            }
            
            self.selectedImage = imageData
            print("download: selectedImage = \(String(describing: selectedImage))")
        }
        
        return selectedImage != nil
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                dismiss.callAsFunction()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })
            
            Spacer()
            
            SelectImageButton { url in
                if url.absoluteString.contains(".webp") {
                    if let data: Data = try? Data(contentsOf: url) {
                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                        self.selectedImage = image?.tiffRepresentation
                    }
                } else {
                    self.selectedImage = try? Data(contentsOf: url)
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.imageData = selectedImage
                dismiss.callAsFunction()
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
    
    private func footer() -> some View {
        HStack {
            Spacer()
            
            if ImagePaster.hasImage() {
                Spacer()
                
                Button {
                    pasteImage()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard.fill")
                }
            }
        }
    }
    
    private func pasteImage() -> Void {
        ImagePaster.paste { data, error in
            if let data = data {
                selectedImage = data
            } else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                failed.toggle()
            }
        }
    }
    
}
