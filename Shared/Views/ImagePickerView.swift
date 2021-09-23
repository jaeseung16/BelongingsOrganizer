//
//  ImagePickerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/16/21.
//

import Foundation
import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: Data?
    @Environment(\.presentationMode) var isPresented
    var sourceType: UIImagePickerController.SourceType
            
    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("sourceType = \(sourceType.rawValue)")
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = self.sourceType
        imagePicker.delegate = context.coordinator // confirming the delegate
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
            guard let selected = info[.imageURL] as? URL else { return }
            self.picker.selectedImage = try? Data(contentsOf: selected)
            self.picker.isPresented.wrappedValue.dismiss()
        }
        
    }
}
