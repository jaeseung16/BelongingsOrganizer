//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/2/21.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

nonisolated final class ImageProcesser: ImagePasting, ImageResizing, Sendable {
    static let shared = ImageProcesser()

    private static let logger = Logger()

    private static let imageTypes: [UTType] = [.png, .jpeg, .webP]
    private static let fileTypes: [UTType] = [.fileURL]
    private static let urlTypes: [UTType] = [.url]

    private static let maxDataSize = 1_000_000
    private static let maxResizeSize = CGSize(width: 256, height: 256)

    // Callers (photo views) write completion results into @State/@Binding, so
    // completions must always land on the main actor regardless of which
    // background queue the underlying SDK (NSItemProvider, URLSession) calls back on.
    private static func onMain(_ completionHandler: @escaping @MainActor (Data?, Error?) -> Void) -> @Sendable (Data?, Error?) -> Void {
        { data, error in
            Task { @MainActor in
                completionHandler(data, error)
            }
        }
    }

    func getData(from info: DropInfo, completionHandler: @escaping @MainActor (Data?, Error?) -> Void) -> Void {
        let completionHandler = ImageProcesser.onMain(completionHandler)
        ImageProcesser.logger.log("loadData")
        let imageProviders = info.itemProviders(for: ImageProcesser.imageTypes)
        nonisolated(unsafe) let fileProviders = info.itemProviders(for: ImageProcesser.fileTypes)
        let hasURLItems = info.hasItemsConforming(to: ImageProcesser.urlTypes)

        loadData(from: imageProviders) { data, error in
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
                self.loadFile(from: fileProviders) { item, error in
                    let imageData: Data?
                    if let item = item, let url = URL(dataRepresentation: item as! Data, relativeTo: nil) {
                        imageData = try? Data(contentsOf: url)
                    } else {
                        imageData = nil
                    }

                    ImageProcesser.logger.log("loadFile: imageData=\(String(describing: imageData), privacy: .public)")
                    if (imageData != nil && NSImage(data: imageData!) != nil) || error != nil {
                        completionHandler(imageData, error)
                    } else if imageData != nil && NSImage(data: imageData!) == nil {
                        completionHandler(nil, BelongingsError.noImage)
                    } else {
                        ImageProcesser.logger.log("download")
                        self.download(hasURLItems: hasURLItems) { data, error in
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

    private func loadData(from itemProviders: [NSItemProvider], completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Void {
        guard !itemProviders.isEmpty else {
            ImageProcesser.logger.log("loadData: no itemProviders")
            completionHandler(nil, nil)
            return
        }
        itemProviders.forEach { itemProvider in
            ImageProcesser.logger.log("loadData: itemProvider=\(itemProvider, privacy: .public)")
            for type in ImageProcesser.imageTypes {
                if itemProvider.hasItemConformingToTypeIdentifier(type.identifier) {
                    itemProvider.loadDataRepresentation(forTypeIdentifier: type.identifier, completionHandler: completionHandler)
                }
            }
        }
    }

    private func loadFile(from itemProviders: [NSItemProvider], completionHandler: @escaping NSItemProvider.CompletionHandler) -> Void {
        guard !itemProviders.isEmpty else {
            ImageProcesser.logger.log("loadFile: no itemProviders")
            completionHandler(nil, nil)
            return
        }
        itemProviders.forEach { itemProvider in
            for type in ImageProcesser.fileTypes {
                if itemProvider.hasItemConformingToTypeIdentifier(type.identifier) {
                    itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, completionHandler: completionHandler)
                }
            }
        }
    }

    private func download(hasURLItems: Bool, completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Void {
        ImageProcesser.logger.log("hasURLItems=\(hasURLItems, privacy: .public)")
        if hasURLItems {
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

    func paste(completionHandler: @escaping @MainActor (Data?, Error?) -> Void) -> Void {
        let completionHandler = ImageProcesser.onMain(completionHandler)
        if let nsImage = NSImage(pasteboard: NSPasteboard.general), let tiffData = nsImage.tiffRepresentation {
            completionHandler(tryResize(image: tiffData) ?? tiffData, nil)
            return
        }

        ImageProcesser.urlTypes
            .map { NSPasteboard.PasteboardType($0.identifier) }
            .forEach { getData(from: .general, forType: $0, completionHandler: completionHandler) }
    }

    private func getData(from pasteboard: NSPasteboard.Name, forType dataType: NSPasteboard.PasteboardType, completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Void {
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
        if NSPasteboard.general.canReadObject(forClasses: [NSImage.self], options: nil) {
            return true
        }

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
