//
//  EditPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/20/21.
//

import SwiftUI
import UniformTypeIdentifiers
import SDWebImageWebPCoder

struct EditPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss

    @State var originalImage: Data?
    @Binding var image: Data?

    @State private var showImagePickerView = false
    @State private var showPHPickerView = false
    @State private var progress: Progress?
    @State private var showAlert = false
    @State private var errorMessage = ""
    
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
                    .onLongPressGesture {
                        pasteImage()
                    }
                    .onDrop(of: ["public.image", "public.file-url"], delegate: self)
                
                Divider()
                
                footer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $showAlert) {
                PhotoAlertView(isPresenting: $showAlert)
                    .padding()
                    .frame(minHeight: 120.0)
            }
            .sheet(isPresented: $showImagePickerView) {
                ImagePickerView(selectedImage: $image, sourceType: .camera)
                    .padding()
            }
            .sheet(isPresented: $showPHPickerView) {
                PHPickerView(selectedImage: $image, progress: $progress) { success, errorString in
                    errorMessage = errorString ?? ""
                    showAlert = !success
                }
                    .padding()
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
            
            Button(action: {
                dismiss.callAsFunction()
            }, label: {
                Text("Done")
            })
        }
    }
    
    private func photoView() -> Image {
        if image != nil {
            return Image(uiImage: UIImage(data: image!)!)
        } else if originalImage != nil {
            return Image(uiImage: UIImage(data: originalImage!)!)
        } else {
            return Image(systemName: "photo.on.rectangle")
        }
    }
    
    private func footer() -> some View {
        HStack {
            Button {
                showImagePickerView = true
            } label: {
                Label("Camera", systemImage: "camera")
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            
            Spacer()
            
            Button {
                image = nil
                progress = nil
                showPHPickerView = true
            } label: {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
            
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
        ImagePaster.paste { data, _ in
            if let data = data {
                image = data
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        ImagePaster.loadData(from: info) { data, _ in
            if let imageData = data {
                if imageData.count > ImagePaster.maxDataSize, let uiImage = UIImage(data: imageData) {
                    if let resized = ImagePaster.resize(uiImage: uiImage, within: ImagePaster.maxResizeSize),
                       let data = resized.pngData() {
                        image = data
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
                    let _ = url.startAccessingSecurityScopedResource()
                    if let data: Data = try? Data(contentsOf: url) {
                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                        self.image = image?.pngData()
                    }
                    url.stopAccessingSecurityScopedResource()
                } else {
                    self.image = try? Data(contentsOf: url)
                }
            }
            print("image = \(String(describing: image))")
        }
        
        return image != nil
    }
}
