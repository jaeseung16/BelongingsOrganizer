//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/1/21.
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
        nonisolated(unsafe) let urlProviders = info.itemProviders(for: ImageProcesser.urlTypes)

        loadData(from: imageProviders) { data, error in
            var image: Data?

            if let imageData = data, let uiImage = UIImage(data: imageData) {
                if let resized = self.resize(uiImage: uiImage, within: ImageProcesser.maxResizeSize),
                   let data = resized.pngData() {
                    image = data
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
                    if (imageData != nil && UIImage(data: imageData!) != nil) || error != nil {
                        completionHandler(imageData, error)
                    } else if imageData != nil && UIImage(data: imageData!) == nil {
                        completionHandler(nil, BelongingsError.noImage)
                    } else {
                        ImageProcesser.logger.log("download")
                        self.download(from: urlProviders) { item, error in
                            if let item = item as? Data, let url = URL(dataRepresentation: item, relativeTo: nil) {
                                ImageProcesser.logger.log("url=\(url, privacy: .public)")
                                let request = URLRequest(url: url as URL, timeoutInterval: 15)
                                let task = URLSession.shared.downloadTask(with: request) { url, response, error in
                                    if let url = url, let data = try? Data(contentsOf: url), UIImage(data: data) != nil {
                                        ImageProcesser.logger.log("data=\(data, privacy: .public)")
                                        completionHandler(data, nil)
                                    } else {
                                        completionHandler(nil, BelongingsError.noImage)
                                    }
                                }
                                task.resume()
                            } else {
                                ImageProcesser.logger.log("download: imageData=nil")
                                completionHandler(nil, error)
                            }
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

    func tryResize(image: Data) -> Data? {
        guard let uiImage = UIImage(data: image) else {
            ImageProcesser.logger.error("Can't convert to UIImage to try resizing")
            return nil
        }
        return resize(uiImage: uiImage, within: ImageProcesser.maxResizeSize)?.pngData()
    }

    private func resize(uiImage: UIImage, within size: CGSize) -> UIImage? {
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

    func paste(completionHandler: @escaping @MainActor (Data?, Error?) -> Void) -> Void {
        let completionHandler = ImageProcesser.onMain(completionHandler)
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

    private func download(from itemProviders: [NSItemProvider], completionHandler: @escaping NSItemProvider.CompletionHandler) -> Void {
        guard !itemProviders.isEmpty else {
            return
        }
        itemProviders.forEach { itemProvider in
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, completionHandler: completionHandler)
        }
    }

}
