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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: AddItemViewModel
    
    @State private var selectedImage: Data?
    @State private var isTargeted = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                photoView()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onDrop(of: ["public.image", "public.file-url"], delegate: self)
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        ImagePaster.loadData(from: info) { data, _ in
            if let imageData = data {
                if imageData.count > ImagePaster.maxDataSize, let nsImage = NSImage(data: imageData) {
                    if let resized = ImagePaster.resize(nsImage: nsImage, within: ImagePaster.maxResizeSize).tiffRepresentation,
                       let imageRep = NSBitmapImageRep(data: resized) {
                        selectedImage = imageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                    } else {
                        selectedImage = imageData
                    }
                } else {
                    selectedImage = imageData
                }
            }
        }
        
        ImagePaster.loadFile(from: info) { item, error in
            if let url = URL(dataRepresentation: item as! Data, relativeTo: nil) {
                if url.absoluteString.contains(".webp") {
                    if let data: Data = try? Data(contentsOf: url) {
                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                        self.selectedImage = image?.tiffRepresentation
                    }
                } else {
                    self.selectedImage = try? Data(contentsOf: url)
                }
            }
            print("selectedImage = \(String(describing: selectedImage))")
        }
        
        return selectedImage != nil
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
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
}
