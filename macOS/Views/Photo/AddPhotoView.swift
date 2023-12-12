//
//  MacAddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/21/21.
//

import SwiftUI
import SDWebImageWebPCoder
import UniformTypeIdentifiers
import PhotosUI

struct AddPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @Binding var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?

    @State private var progress: Progress?
    
    @State private var failed = false
    @State private var details = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if progress != nil && !(progress!.isFinished) {
                    ProgressView(progress!)
                }
                
                photoView()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                
                Divider()
                
                footer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onDrop(of: ["public.image", "public.file-url", "public.url"], delegate: self)
        }
        .alert("Cannot add a photo", isPresented: $failed, presenting: details) { details in
            Button("Dismiss") {
                
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        viewModel.getData(from: info) { data, error in
            guard let data = data else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                self.photo = nil
                failed.toggle()
                return
            }
            
            self.photo = data
        }
        
        return photo != nil
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
                        self.photo = image?.tiffRepresentation
                    }
                } else {
                    self.photo = try? Data(contentsOf: url)
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.updateImage(photo)
                dismiss.callAsFunction()
            }, label: {
                Text("Done")
            })
        }
    }
    
    private func photoView() -> Image {
        if photo != nil {
            return Image(nsImage: NSImage(data: photo!)!)
        } else {
            return Image(systemName: "photo.on.rectangle")
        }
    }
    
    private func footer() -> some View {
        HStack {
            Spacer()
            
            PhotosPicker(selection: $selectedPhoto, matching: .any(of: [.images])) {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
            
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
                photo = data
            } else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                failed.toggle()
            }
        }
    }
    
}
