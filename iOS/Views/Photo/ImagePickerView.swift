//
//  ImagePickerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

import Foundation
import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: BelongingsViewModel
    @Environment(\.dismiss) var dismiss
    
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
            guard let selected = info[.originalImage] as? UIImage, let imageData = selected.pngData() else {
                self.picker.dismiss.callAsFunction()
                return
            }
            
            // No need to orient since the correct orientation is used with UIImage.draw(in:)
            self.picker.selectedImage = self.picker.viewModel.tryResize(image: imageData)
            self.picker.dismiss.callAsFunction()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            self.picker.dismiss.callAsFunction()
        }
        
        private func orient(uiImage: UIImage) -> UIImage? {
            guard let  ciImage = CIImage(image: uiImage) else {
                return nil
            }
            return UIImage(ciImage: ciImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)
        }
        
    }
}
