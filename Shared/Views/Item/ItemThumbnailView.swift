//
//  ItemThumbnailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/23/26.
//

import SwiftUI
import CoreData
import ImageIO

// Draws an item's photo downsampled to the size it is shown at. Decoding runs off the main
// thread and the result is cached, so scrolling back to a row doesn't decode its photo again.
struct ItemThumbnailView<Placeholder: View>: View {
    @ObservedObject var item: Item
    // Points; an infinite dimension leaves that side unconstrained (the image is fitted to the other)
    let size: CGSize
    @ViewBuilder let placeholder: () -> Placeholder

    @Environment(\.displayScale) private var displayScale
    @State private var loaded: (key: ThumbnailCache.Key, image: CGImage?)?

    var body: some View {
        if let data = item.image {
            let key = ThumbnailCache.Key(objectID: item.objectID, lastupd: item.lastupd, byteCount: data.count,
                                         pixelSize: CGSize(width: size.width * displayScale, height: size.height * displayScale))
            let image = ThumbnailCache.shared.image(for: key) ?? (loaded?.key == key ? loaded?.image : nil)
            Group {
                if let image {
                    Image(decorative: image, scale: displayScale)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if loaded?.key == key {
                    // Not decodable
                    placeholder()
                } else {
                    Color.clear
                }
            }
            .frame(width: size.width.isFinite ? size.width : nil, height: size.height.isFinite ? size.height : nil)
            .task(id: key) {
                guard ThumbnailCache.shared.image(for: key) == nil else { return }
                let image = await ThumbnailCache.shared.thumbnail(for: key, from: data)
                loaded = (key, image)
            }
        } else {
            placeholder()
        }
    }
}

nonisolated final class ThumbnailCache: @unchecked Sendable {
    static let shared = ThumbnailCache()

    // lastupd changes on every edit, and a CloudKit import brings the new one along with the photo
    struct Key: Hashable, Sendable {
        let objectID: NSManagedObjectID
        let lastupd: Date?
        let byteCount: Int
        let pixelSize: CGSize

        func hash(into hasher: inout Hasher) {
            hasher.combine(objectID)
            hasher.combine(lastupd)
            hasher.combine(byteCount)
            hasher.combine(pixelSize.width)
            hasher.combine(pixelSize.height)
        }
    }

    // NSCache is thread-safe; it also evicts under memory pressure
    private let cache: NSCache<KeyBox, CGImage> = {
        let cache = NSCache<KeyBox, CGImage>()
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    func image(for key: Key) -> CGImage? {
        cache.object(forKey: KeyBox(key))
    }

    @concurrent
    func thumbnail(for key: Key, from data: Data) async -> CGImage? {
        let image = PerformanceSignposts.measure("thumbnail") {
            ThumbnailCache.downsample(data, toFit: key.pixelSize)
        }
        if let image {
            cache.setObject(image, forKey: KeyBox(key), cost: image.bytesPerRow * image.height)
        }
        return image
    }

    private static func downsample(_ data: Data, toFit pixelSize: CGSize) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat,
              width > 0, height > 0 else {
            return nil
        }

        // Rotated EXIF orientations swap the displayed width and height
        let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let (shownWidth, shownHeight) = orientation >= 5 ? (height, width) : (width, height)
        let scale = min(pixelSize.width / shownWidth, pixelSize.height / shownHeight, 1)
        let maxPixelSize = max(1, (max(shownWidth, shownHeight) * scale).rounded(.up))

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private final class KeyBox: NSObject {
        let key: Key

        init(_ key: Key) {
            self.key = key
        }

        override var hash: Int {
            key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            (object as? KeyBox)?.key == key
        }
    }
}
