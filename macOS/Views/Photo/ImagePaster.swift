//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/2/21.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

class ImagePaster {
    private static let logger = Logger()
    
    private static let imageTypes: [UTType] = [.png, .jpeg, .webP]
    private static let fileTypes: [UTType] = [.fileURL]
    private static let urlTypes: [UTType] = [.url]
    
    static let maxDataSize = 1_000_000
    static let maxResizeSize = CGSize(width: 128, height: 128)
    
    static func getData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        if info.hasItemsConforming(to: ImagePaster.imageTypes) {
        }
        
        
        ImagePaster.logger.log("loadData")
        ImagePaster.loadData(from: info) { data, error in
            var image: Data?
            
            if let imageData = data, let nsImage = NSImage(data: imageData) {
                if imageData.count > ImagePaster.maxDataSize {
                    if let resized = ImagePaster.resize(nsImage: nsImage, within: ImagePaster.maxResizeSize).tiffRepresentation,
                       let imageRep = NSBitmapImageRep(data: resized) {
                        image = imageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                    } else {
                        image = imageData
                    }
                } else {
                    image = imageData
                }
            }
            ImagePaster.logger.log("loadData: imageData=\(String(describing: image), privacy: .public)")
            
            if image != nil || error != nil {
                completionHandler(image, error)
            } else {
                ImagePaster.logger.log("loadFile")
                ImagePaster.loadFile(from: info) { item, error in
                    var imageData: Data?
                    if let item = item, let url = URL(dataRepresentation: item as! Data, relativeTo: nil) {
                        imageData = try? Data(contentsOf: url)
                    }
                    
                    ImagePaster.logger.log("loadFile: imageData=\(String(describing: imageData), privacy: .public)")
                    if (imageData != nil && NSImage(data: imageData!) != nil) || error != nil {
                        completionHandler(imageData, error)
                    } else if imageData != nil && NSImage(data: imageData!) == nil {
                        completionHandler(nil, BelongingsError.noImage)
                    } else {
                        ImagePaster.logger.log("download")
                        ImagePaster.download(from: info) { data, error in
                            var imageData: Data?
                            if let data = data, let _ = NSImage(data: data) {
                                imageData = data
                            }
                            ImagePaster.logger.log("download: imageData=\(String(describing: imageData), privacy: .public)")
                            completionHandler(imageData, error)
                        }
                    }
                }
            }
        }
    }
    
    static func loadData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        if info.hasItemsConforming(to: ImagePaster.imageTypes) {
            let itemProviders = info.itemProviders(for: ImagePaster.imageTypes)
            if !itemProviders.isEmpty {
                itemProviders.forEach { itemProvider in
                    ImagePaster.logger.log("loadData: itemProvider=\(itemProvider, privacy: .public)")
                    for type in ImagePaster.imageTypes {
                        ImagePaster.logger.log("loadData: type=\(type, privacy: .public)")
                        if info.hasItemsConforming(to: [type]) {
                            itemProvider.loadDataRepresentation(forTypeIdentifier: type.identifier, completionHandler: completionHandler)
                        }
                    }
                }
            } else {
                ImagePaster.logger.log("loadData: no itemProviders")
                completionHandler(nil, nil)
            }
        } else {
            ImagePaster.logger.log("loadData: completionHandler(nil, nil)")
            completionHandler(nil, nil)
        }
    }
    
    static func loadFile(from info: DropInfo, completionHandler: @escaping NSItemProvider.CompletionHandler) -> Void {
        if info.hasItemsConforming(to: ImagePaster.fileTypes) {
            let itemProviders = info.itemProviders(for: ImagePaster.fileTypes)
            if !itemProviders.isEmpty {
                itemProviders.forEach { itemProvider in
                    for type in ImagePaster.fileTypes {
                        ImagePaster.logger.log("loadFile: type=\(type, privacy: .public)")
                        if info.hasItemsConforming(to: [type]) {
                            itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, completionHandler: completionHandler)
                        }
                    }
                }
            } else {
                ImagePaster.logger.log("loadFile: no itemProviders")
                completionHandler(nil, nil)
            }
        } else {
            completionHandler(nil, nil)
        }
    }
    
    static func download(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) -> Void {
        ImagePaster.logger.log("info.hasItemsConforming(to: ImagePaster.urlTypes)=\(info.hasItemsConforming(to: ImagePaster.urlTypes), privacy: .public)")
        if info.hasItemsConforming(to: ImagePaster.urlTypes) {
            getData(from: .drag, forType: .URL, completionHandler: completionHandler)
        }
    }
    
    static func resize(nsImage: NSImage, within size: CGSize) -> NSImage {
        let widthScale = size.width / nsImage.size.width
        let heightScale = size.height / nsImage.size.height
        ImagePaster.logger.log("widthScale = \(widthScale, privacy: .public), heightScale = \(heightScale, privacy: .public)")
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
    
    static func paste(completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        urlTypes
            .map { NSPasteboard.PasteboardType($0.identifier) }
            .forEach { getData(from: .general, forType: $0, completionHandler: completionHandler) }
    }
    
    private static func getData(from pasteboard: NSPasteboard.Name, forType dataType: NSPasteboard.PasteboardType, completionHandler: @escaping (Data?, Error?) -> Void) -> Void {
        let pasteboard = NSPasteboard(name: pasteboard)
        
        if let data = pasteboard.data(forType: dataType) {
            if let url = URL(string: String(decoding: data, as: UTF8.self)) {
                ImagePaster.logger.log("url=\(url, privacy: .public)")
                let request = URLRequest(url: url as URL, timeoutInterval: 15)
                let task = URLSession.shared.downloadTask(with: request) { url, response, error in
                    if let url = url, let data = try? Data(contentsOf: url), NSImage(data: data) != nil {
                        ImagePaster.logger.log("data=\(data, privacy: .public)")
                        completionHandler(data, nil)
                    } else {
                        ImagePaster.logger.log("noimage data=\(data, privacy: .public)")
                        completionHandler(nil, BelongingsError.noImage)
                    }
                }
                task.resume()
            }
        }
    }
    
    static func hasImage() -> Bool {
        var result = false
        for urlType in urlTypes {
            if NSPasteboard.general.data(forType: NSPasteboard.PasteboardType(urlType.identifier)) != nil {
                result = true
                break
            }
        }
        return result
    }
}
