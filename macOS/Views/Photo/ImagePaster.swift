//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/2/21.
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
    
    static func resize(nsImage: NSImage, within size: CGSize) -> NSImage {
        let widthScale = size.width / nsImage.size.width
        let heightScale = size.height / nsImage.size.height
        print("widthScale = \(widthScale), heightScale = \(heightScale)")
        guard widthScale < 1.0 && heightScale < 1.0 else {
            return nsImage
        }
        
        let scale = widthScale > heightScale ? widthScale : heightScale
        
        let scaledSize = CGSize(width: nsImage.size.width * scale, height: nsImage.size.height * scale)
        
        let newImage = NSImage(size: scaledSize)
        newImage.lockFocus()
        nsImage.draw(in: NSMakeRect(0, 0, scaledSize.width, scaledSize.height), from: NSMakeRect(0, 0, nsImage.size.width, nsImage.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = scaledSize
        
        return newImage
    }
}
