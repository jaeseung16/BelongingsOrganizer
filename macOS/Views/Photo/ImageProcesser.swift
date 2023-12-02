//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/2/21.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

class ImageProcesser: ImagePasting, ImageResizing {
    static let shared = ImageProcesser()
    
    private static let logger = Logger()
    
    private static let imageTypes: [UTType] = [.png, .jpeg, .webP]
    private static let fileTypes: [UTType] = [.fileURL]
    private static let urlTypes: [UTType] = [.url]
    
    private static let maxDataSize = 1_000_000
    private static let maxResizeSize = CGSize(width: 128, height: 128)
    
    func getData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        ImageProcesser.logger.log("loadData")
        loadData(from: info) { data, error in
            var image: Data?
            
            if let imageData = data, let nsImage = NSImage(data: imageData) {
                if let resized = self.resize(nsImage: nsImage, within: ImageProcesser.maxResizeSize).tiffRepresentation,
                   let imageRep = NSBitmapImageRep(data: resized) {
                    image = imageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                } else {
                    image = imageData
                }
            }
            ImageProcesser.logger.log("loadData: imageData=\(String(describing: image), privacy: .public)")
            
            if image != nil || error != nil {
                completionHandler(image, error)
            } else {
                ImageProcesser.logger.log("loadFile")
                self.loadFile(from: info) { item, error in
                    var imageData: Data?
                    if let item = item, let url = URL(dataRepresentation: item as! Data, relativeTo: nil) {
                        imageData = try? Data(contentsOf: url)
                    }
                    
                    ImageProcesser.logger.log("loadFile: imageData=\(String(describing: imageData), privacy: .public)")
                    if (imageData != nil && NSImage(data: imageData!) != nil) || error != nil {
                        completionHandler(imageData, error)
                    } else if imageData != nil && NSImage(data: imageData!) == nil {
                        completionHandler(nil, BelongingsError.noImage)
                    } else {
                        ImageProcesser.logger.log("download")
                        self.download(from: info) { data, error in
                            var imageData: Data?
                            if let data = data, let _ = NSImage(data: data) {
                                imageData = data
                            }
                            ImageProcesser.logger.log("download: imageData=\(String(describing: imageData), privacy: .public)")
                            completionHandler(imageData, error)
                        }
                    }
                }
            }
        }
    }
    
    func loadData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        if info.hasItemsConforming(to: ImageProcesser.imageTypes) {
            let itemProviders = info.itemProviders(for: ImageProcesser.imageTypes)
            if !itemProviders.isEmpty {
                itemProviders.forEach { itemProvider in
                    ImageProcesser.logger.log("loadData: itemProvider=\(itemProvider, privacy: .public)")
                    for type in ImageProcesser.imageTypes {
                        ImageProcesser.logger.log("loadData: type=\(type, privacy: .public)")
                        if info.hasItemsConforming(to: [type]) {
                            itemProvider.loadDataRepresentation(forTypeIdentifier: type.identifier, completionHandler: completionHandler)
                        }
                    }
                }
            } else {
                ImageProcesser.logger.log("loadData: no itemProviders")
                completionHandler(nil, nil)
            }
        } else {
            ImageProcesser.logger.log("loadData: completionHandler(nil, nil)")
            completionHandler(nil, nil)
        }
    }
    
    func loadFile(from info: DropInfo, completionHandler: @escaping NSItemProvider.CompletionHandler) -> Void {
        if info.hasItemsConforming(to: ImageProcesser.fileTypes) {
            let itemProviders = info.itemProviders(for: ImageProcesser.fileTypes)
            if !itemProviders.isEmpty {
                itemProviders.forEach { itemProvider in
                    for type in ImageProcesser.fileTypes {
                        ImageProcesser.logger.log("loadFile: type=\(type, privacy: .public)")
                        if info.hasItemsConforming(to: [type]) {
                            itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, completionHandler: completionHandler)
                        }
                    }
                }
            } else {
                ImageProcesser.logger.log("loadFile: no itemProviders")
                completionHandler(nil, nil)
            }
        } else {
            completionHandler(nil, nil)
        }
    }
    
    func download(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) -> Void {
        ImageProcesser.logger.log("info.hasItemsConforming(to: ImagePaster.urlTypes)=\(info.hasItemsConforming(to: ImageProcesser.urlTypes), privacy: .public)")
        if info.hasItemsConforming(to: ImageProcesser.urlTypes) {
            getData(from: .drag, forType: .URL, completionHandler: completionHandler)
        }
    }
    
    func tryResize(image: Data) -> Data? {
        guard let nsImage = NSImage(data: image) else {
            ImageProcesser.logger.error("Can't convert to NSImage to try resizing")
            return nil
        }
        
        if let resized = self.resize(nsImage: nsImage, within: ImageProcesser.maxResizeSize).tiffRepresentation,
           let imageRep = NSBitmapImageRep(data: resized) {
            return imageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        } else {
            return image
        }
    }
    
    private func resize(nsImage: NSImage, within size: CGSize) -> NSImage {
        let widthScale = size.width / nsImage.size.width
        let heightScale = size.height / nsImage.size.height
        ImageProcesser.logger.log("widthScale = \(widthScale, privacy: .public), heightScale = \(heightScale, privacy: .public)")
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
    
    func paste(completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        ImageProcesser.urlTypes
            .map { NSPasteboard.PasteboardType($0.identifier) }
            .forEach { getData(from: .general, forType: $0, completionHandler: completionHandler) }
    }
    
    private func getData(from pasteboard: NSPasteboard.Name, forType dataType: NSPasteboard.PasteboardType, completionHandler: @escaping (Data?, Error?) -> Void) -> Void {
        let pasteboard = NSPasteboard(name: pasteboard)
        
        if let data = pasteboard.data(forType: dataType) {
            if let url = URL(string: String(decoding: data, as: UTF8.self)) {
                ImageProcesser.logger.log("url=\(url, privacy: .public)")
                let request = URLRequest(url: url as URL, timeoutInterval: 15)
                let task = URLSession.shared.downloadTask(with: request) { url, response, error in
                    if let url = url, let data = try? Data(contentsOf: url), NSImage(data: data) != nil {
                        ImageProcesser.logger.log("data=\(data, privacy: .public)")
                        completionHandler(data, nil)
                    } else {
                        ImageProcesser.logger.log("noimage data=\(data, privacy: .public)")
                        completionHandler(nil, BelongingsError.noImage)
                    }
                }
                task.resume()
            }
        }
    }
    
    func hasImage() -> Bool {
        var result = false
        for urlType in ImageProcesser.urlTypes {
            if NSPasteboard.general.data(forType: NSPasteboard.PasteboardType(urlType.identifier)) != nil {
                result = true
                break
            }
        }
        return result
    }
}
