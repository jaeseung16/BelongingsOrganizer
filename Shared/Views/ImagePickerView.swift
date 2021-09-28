//
//  ImagePickerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

#if !os(macOS)
import Foundation
import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var isPresented
    
    @Binding var selectedImage: Data?
    
    var sourceType: UIImagePickerController.SourceType
            
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var picker: ImagePickerView
        
        init(picker: ImagePickerView) {
            self.picker = picker
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let selected = info[.originalImage] as? UIImage else {
                self.picker.isPresented.wrappedValue.dismiss()
                return
            }
            
            // No need to orient since the correct orientation is used with UIImage.draw(in:)
            self.picker.selectedImage = resize(uiImage: selected, within: CGSize(width: 1024.0, height: 1024.0))?.pngData()
            self.picker.isPresented.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            self.picker.isPresented.wrappedValue.dismiss()
        }
        
        private func orient(uiImage: UIImage) -> UIImage? {
            guard let  ciImage = CIImage(image: uiImage) else {
                return nil
            }
            return UIImage(ciImage: ciImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)
        }
        
        private func resize(uiImage: UIImage, within size: CGSize) -> UIImage? {
            let widthScale = size.width / uiImage.size.width
            let heightScale = size.height / uiImage.size.height
            
            guard widthScale < 1.0 && heightScale < 1.0 else {
                return uiImage
            }
            
            let scale = widthScale > heightScale ? widthScale : heightScale
            
            let scaledSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            
            return renderer.image { _ in
                uiImage.draw(in: CGRect(origin: .zero, size: scaledSize))
            }
        }
    }
}
#endif
