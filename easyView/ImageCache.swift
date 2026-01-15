import AppKit

/// Simple NSImage cache wrapper using NSCache
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        // Optional: tune limits
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 200 // 200 MB-ish
    }

    func image(forKey key: NSString) -> NSImage? {
        return cache.object(forKey: key)
    }

    func setImage(_ image: NSImage, forKey key: NSString) {
        // Rough cost estimate based on pixel count
        let size = image.size
        let cost = Int(size.width * size.height)
        cache.setObject(image, forKey: key, cost: cost)
    }

    func removeImage(forKey key: NSString) {
        cache.removeObject(forKey: key)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
