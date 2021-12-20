//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/1/21.
//

import SwiftUI
import UniformTypeIdentifiers

class ImagePaster {
    private static let imageTypes: [UTType] = [.png, .jpeg, .webP]
    private static let fileTypes: [UTType] = [.fileURL]
    
    static let maxDataSize = 1_000_000
    static let maxResizeSize = CGSize(width: 128, height: 128)
    
    static func loadData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        if info.hasItemsConforming(to: ImagePaster.imageTypes) {
            info.itemProviders(for: ImagePaster.imageTypes).forEach { itemProvider in
                for type in ImagePaster.imageTypes {
                    itemProvider.loadDataRepresentation(forTypeIdentifier: type.identifier, completionHandler: completionHandler)
                }
            }
        }
    }
    
    static func loadFile(from info: DropInfo, completionHandler: @escaping NSItemProvider.CompletionHandler) -> Void {
        if info.hasItemsConforming(to: ImagePaster.fileTypes) {
            info.itemProviders(for: ImagePaster.fileTypes).forEach { itemProvider in
                itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, completionHandler: completionHandler)
            }
        }
    }
    
    static func resize(uiImage: UIImage, within size: CGSize) -> UIImage? {
        let widthScale = size.width / uiImage.size.width
        let heightScale = size.height / uiImage.size.height
        print("widthScale = \(widthScale), heightScale = \(heightScale)")
        guard widthScale < 1.0 && heightScale < 1.0 else {
            return uiImage
        }
        
        let scale = widthScale > heightScale ? widthScale : heightScale
        let scaledSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(scaledSize, true, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: scaledSize))
        defer { UIGraphicsEndImageContext() }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage
    }
    
    static func paste(completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        ImageType.allCases.forEach { imageType in
            UIPasteboard.general.itemProviders.first(where: {
                $0.hasItemConformingToTypeIdentifier(imageType.identifier())
            })?
                .loadDataRepresentation(forTypeIdentifier: imageType.identifier(), completionHandler: completionHandler)
        }
    }
    
    static func hasImage() -> Bool {
        var result = false
        for imageType in ImageType.allCases {
            if UIPasteboard.general.itemProviders.first(where: {$0.hasItemConformingToTypeIdentifier(imageType.identifier())}) != nil {
                result = true
                break
            }
        }
        return result
    }
}
