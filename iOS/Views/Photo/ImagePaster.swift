//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/1/21.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

class ImagePaster: ImagePasting {
    static let shared = ImagePaster()
    private static let logger = Logger()
    
    private static let imageTypes: [UTType] = [.png, .jpeg, .webP]
    private static let fileTypes: [UTType] = [.fileURL]
    private static let urlTypes: [UTType] = [.url]
    
    private static let maxDataSize = 1_000_000
    private static let maxResizeSize = CGSize(width: 128, height: 128)
    
    func getData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        ImagePaster.logger.log("loadData")
        loadData(from: info) { data, error in
            var image: Data?
            
            if let imageData = data, let uiImage = UIImage(data: imageData) {
                if imageData.count > ImagePaster.maxDataSize {
                    if let resized = self.resize(uiImage: uiImage, within: ImagePaster.maxResizeSize),
                       let data = resized.pngData() {
                        image = data
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
                self.loadFile(from: info) { item, error in
                    var imageData: Data?
                    if let item = item, let url = URL(dataRepresentation: item as! Data, relativeTo: nil) {
                        imageData = try? Data(contentsOf: url)
                    }
                    
                    ImagePaster.logger.log("loadFile: imageData=\(String(describing: imageData), privacy: .public)")
                    if (imageData != nil && UIImage(data: imageData!) != nil) || error != nil {
                        completionHandler(imageData, error)
                    } else if imageData != nil && UIImage(data: imageData!) == nil {
                        completionHandler(nil, BelongingsError.noImage)
                    } else {
                        ImagePaster.logger.log("download")
                        self.download(from: info) { item, error in
                            var imageData: Data?
                            if let item = item as? Data, let url = URL(dataRepresentation: item, relativeTo: nil) {
                                ImagePaster.logger.log("url=\(url, privacy: .public)")
                                let request = URLRequest(url: url as URL, timeoutInterval: 15)
                                let task = URLSession.shared.downloadTask(with: request) { url, response, error in
                                    if let url = url, let data = try? Data(contentsOf: url), UIImage(data: data) != nil {
                                        ImagePaster.logger.log("data=\(data, privacy: .public)")
                                        completionHandler(data, nil)
                                    } else {
                                        completionHandler(nil, BelongingsError.noImage)
                                    }
                                }
                                task.resume()
                            }
                            ImagePaster.logger.log("download: imageData=\(String(describing: imageData), privacy: .public)")
                            completionHandler(imageData, error)
                        }
                    }
                }
            }
        }
    }
    
    func loadData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
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
    
    func loadFile(from info: DropInfo, completionHandler: @escaping NSItemProvider.CompletionHandler) -> Void {
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
    
    func resize(uiImage: UIImage, within size: CGSize) -> UIImage? {
        let widthScale = size.width / uiImage.size.width
        let heightScale = size.height / uiImage.size.height
        
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
    
    func paste(completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        ImageType.allCases.forEach { imageType in
            UIPasteboard.general.itemProviders.first(where: {
                $0.hasItemConformingToTypeIdentifier(imageType.identifier())
            })?
                .loadDataRepresentation(forTypeIdentifier: imageType.identifier(), completionHandler: completionHandler)
        }
    }
    
    func hasImage() -> Bool {
        var result = false
        for imageType in ImageType.allCases {
            if UIPasteboard.general.itemProviders.first(where: {$0.hasItemConformingToTypeIdentifier(imageType.identifier())}) != nil {
                result = true
                break
            }
        }
        return result
    }
    
    func download(from info: DropInfo, completionHandler: @escaping NSItemProvider.CompletionHandler) -> Void {
        ImagePaster.logger.log("info.hasItemsConforming(to: ImagePaster.urlTypes)=\(info.hasItemsConforming(to: ImagePaster.urlTypes), privacy: .public)")
        if info.hasItemsConforming(to: ImagePaster.urlTypes) {
            let itemProviders: [NSItemProvider] = info.itemProviders(for: ImagePaster.urlTypes)
            if !itemProviders.isEmpty {
                itemProviders.forEach { itemProvider in
                    itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, completionHandler: completionHandler)
                }
            }
        }
    }

    
}
