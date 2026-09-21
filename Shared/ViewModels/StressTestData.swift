//
//  StressTestData.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/21/26.
//

#if DEBUG
import Foundation
import CoreData
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import os

// Debug-only: launching with `-StressTestItemCount <n>` replaces the CloudKit store with a
// local-only SQLite store, recreated and seeded with n items on every launch, so performance
// can be measured without touching the user's data or iCloud. It is on disk rather than in
// memory so that image blobs use external storage the way they do in the real store.
enum StressTestData {
    static let itemCountKey = "StressTestItemCount"
    static let storeName = "BelongingsStressTest"

    private static let logger = Logger()

    static var itemCount: Int? {
        let count = UserDefaults.standard.integer(forKey: itemCountKey)
        return count > 0 ? count : nil
    }

    static func destroyStore() {
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("\(storeName).sqlite")
        do {
            try NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
                .destroyPersistentStore(at: storeURL, type: .sqlite)
        } catch {
            logger.error("Failed to destroy the stress test store: \(error.localizedDescription, privacy: .public)")
        }
        // The history token belongs to the destroyed store
        try? FileManager.default.removeItem(at: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(storeName, isDirectory: true))
    }

    static func seed(_ context: NSManagedObjectContext, itemCount: Int) {
        var generator = SplitMix64(seed: 20260921)
        let now = Date()

        let kinds = (0..<20).map { index in
            let kind = Kind(context: context)
            kind.uuid = UUID()
            kind.name = "Category \(index)"
            kind.created = now
            kind.lastupd = now
            return kind
        }
        let brands = (0..<30).map { index in
            let brand = Brand(context: context)
            brand.uuid = UUID()
            brand.name = "Brand \(index)"
            brand.created = now
            brand.lastupd = now
            return brand
        }
        let sellers = (0..<15).map { index in
            let seller = Seller(context: context)
            seller.uuid = UUID()
            seller.name = "Seller \(index)"
            seller.created = now
            seller.lastupd = now
            return seller
        }
        // A few distinct photos, shared between items, sized like ImageProcesser's output
        let images = (0..<12).compactMap { _ in makeImage(using: &generator) }

        let threeYears = 3 * 365 * 24 * 3600.0
        for index in 0..<itemCount {
            let item = Item(context: context)
            item.uuid = UUID()
            item.name = "Item \(index)"
            item.note = "Stress test item \(index)"
            item.quantity = 1
            item.buyPrice = Double(generator.next() % 100_000) / 100
            item.buyCurrency = "USD"
            item.obtained = now.addingTimeInterval(-Double(generator.next() % UInt64(threeYears)))
            item.created = item.obtained
            item.lastupd = item.obtained
            if generator.next() % 10 == 0 {
                item.disposed = now.addingTimeInterval(-Double(generator.next() % UInt64(threeYears / 3)))
            }
            if !images.isEmpty {
                item.image = images[Int(generator.next() % UInt64(images.count))]
            }
            for _ in 0...(generator.next() % 3) {
                kinds[Int(generator.next() % UInt64(kinds.count))].addToItems(item)
            }
            brands[Int(generator.next() % UInt64(brands.count))].addToItems(item)
            sellers[Int(generator.next() % UInt64(sellers.count))].addToItems(item)
        }

        do {
            try context.save()
            // Start from faults, like a real launch, instead of the fully populated seed objects
            context.reset()
            logger.log("Seeded \(itemCount) stress test items")
        } catch {
            logger.error("Failed to seed stress test items: \(error.localizedDescription, privacy: .public)")
        }
    }

    // Noisy 256x256 PNG: compresses about as poorly as a resized photo
    private static func makeImage(using generator: inout SplitMix64) -> Data? {
        let size = 256
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        let base = (UInt8(generator.next() % 200), UInt8(generator.next() % 200), UInt8(generator.next() % 200))
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let noise = UInt8(generator.next() % 56)
            pixels[offset] = base.0 + noise
            pixels[offset + 1] = base.1 + noise
            pixels[offset + 2] = base.2 + noise
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: size * 4,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                    provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return nil
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }
}

// Deterministic generator so every stress run seeds the same data
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
#endif
