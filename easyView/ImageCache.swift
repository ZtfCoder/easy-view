import AppKit

/// Simple NSImage cache wrapper using NSCache
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        // 限制缓存：最多 10 张图片，最大约 50MB
        cache.countLimit = 10
        cache.totalCostLimit = 1024 * 1024 * 50 // 50 MB
    }

    func image(forKey key: NSString) -> NSImage? {
        return cache.object(forKey: key)
    }

    func setImage(_ image: NSImage, forKey key: NSString) {
        // 准确计算内存占用：width * height * 4 bytes (RGBA)
        let size = image.size
        let cost = Int(size.width * size.height * 4)
        cache.setObject(image, forKey: key, cost: cost)
    }

    func removeImage(forKey key: NSString) {
        cache.removeObject(forKey: key)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
