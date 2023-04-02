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
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var originalImage: Data?
    @Binding var image: Data?
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
                    .onDrop(of: ["public.image", "public.file-url"], delegate: self)
                
                Divider()
                
                footer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .alert("Cannot replace a photo", isPresented: $failed, presenting: details) { details in
            Button("Dismiss") {
                
            }
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
        viewModel.getData(from: info) { data, error in
            guard let data = data else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                self.image = nil
                failed.toggle()
                return
            }
            
            self.image = data
        }
        
        return image != nil
    }
    
    private func footer() -> some View {
        HStack {
            Spacer()
            
            if viewModel.hasImage() {
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
        viewModel.paste { data, error in
            if let data = data {
                image = data
            } else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                failed.toggle()
            }
        }
    }
}
