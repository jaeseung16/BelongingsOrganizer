//
//  AddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

import SwiftUI
import UniformTypeIdentifiers
import SDWebImageWebPCoder

struct AddPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AddItemViewModel

    @State private var selectedImage: Data?
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
                ImagePickerView(selectedImage: $selectedImage, sourceType: .camera)
                    .padding()
            }
            .sheet(isPresented: $showPHPickerView) {
                PHPickerView(selectedImage: $selectedImage, progress: $progress) { success, errorString in
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
                dismiss.callAsFunction()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })
            
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
            return Image(uiImage: UIImage(data: selectedImage!)!)
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
                selectedImage = data
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        ImagePaster.loadData(from: info) { data, _ in
            if let imageData = data {
                if imageData.count > ImagePaster.maxDataSize, let uiImage = UIImage(data: imageData) {
                    if let resized = ImagePaster.resize(uiImage: uiImage, within: ImagePaster.maxResizeSize),
                       let data = resized.pngData() {
                        selectedImage = data
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
                    let _ = url.startAccessingSecurityScopedResource()
                    if let data: Data = try? Data(contentsOf: url) {
                        let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                        self.selectedImage = image?.pngData()
                    }
                    url.stopAccessingSecurityScopedResource()
                } else {
                    self.selectedImage = try? Data(contentsOf: url)
                }
            }
            print("selectedImage = \(String(describing: selectedImage))")
        }
        
        return selectedImage != nil
    }
}
