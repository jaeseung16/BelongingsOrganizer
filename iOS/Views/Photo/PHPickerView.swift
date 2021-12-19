//
//  PHPickerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/27/21.
//

import Foundation
import SwiftUI
import PhotosUI

struct PHPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedImage: Data?
    @Binding var progress: Progress?
    var completionHandler: (Bool, String?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let imagePicker = PHPickerViewController(configuration: PHPickerConfiguration())
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        var picker: PHPickerView
        
        init(picker: PHPickerView) {
            self.picker = picker
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if !results.isEmpty {
                let itemProvider = results[0].itemProvider
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    self.picker.progress = itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        DispatchQueue.main.async {
                            guard error == nil else {
                                self?.picker.completionHandler(false, "\(error!.localizedDescription)")
                                return
                            }
                            
                            if let image = image as? UIImage {
                                self?.picker.selectedImage = self?.resize(uiImage: image, within: CGSize(width: 1024.0, height: 1024.0))?.pngData()
                                self?.picker.completionHandler(true, nil)
                            } else {
                                self?.picker.completionHandler(false, "cannot load image")
                            }
                        }
                    }
                } else {
                    self.picker.completionHandler(false, "cannot load image")
                }
            }
            
            self.picker.dismiss.callAsFunction()
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
