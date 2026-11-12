import UIKit

/// Loads artwork with aggressive downsampling + a small NSCache.
/// Every image is decoded at the exact display size, so a 1 GB-RAM iPhone 6
/// never holds full-resolution covers in memory.
final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private var running: [ObjectIdentifier: URLSessionTask] = [:]
    private var tokens: [ObjectIdentifier: Int] = [:]

    private init() {
        cache.countLimit = 120
        cache.totalCostLimit = 24 * 1024 * 1024
    }

    func clearCache() {
        cache.removeAllObjects()
    }

    /// Simple one-shot fetch (used for lock-screen artwork).
    func fetch(_ url: URL, side: CGFloat, completion: @escaping (UIImage?) -> Void) {
        if let hit = cache.object(forKey: url as NSURL) {
            completion(hit)
            return
        }
        let scale = max(1, min(3, UIScreen.main.scale))
        let pixel = Int(side * scale)
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            var image: UIImage?
            if let data, !data.isEmpty {
                image = self.downsampled(data: data, maxPixel: pixel)
            }
            if let image {
                self.cache.setObject(image, forKey: url as NSURL, cost: pixel * pixel * 4)
            }
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
    }

    /// Cancellable, reuse-safe image assignment for cells / image views.
    func setImage(on imageView: UIImageView, url: URL?, side: CGFloat, placeholder: UIImage?) {
        let key = ObjectIdentifier(imageView)
        let myToken = (tokens[key] ?? 0) + 1
        tokens[key] = myToken
        if let old = running[key] {
            old.cancel()
            running[key] = nil
        }
        imageView.image = placeholder
        guard let url else { return }

        if let hit = cache.object(forKey: url as NSURL) {
            imageView.image = hit
            return
        }

        let scale = max(1, min(3, UIScreen.main.scale))
        let pixel = Int(side * scale)
        let task = URLSession.shared.dataTask(with: url) { [weak self, weak imageView] data, _, _ in
            guard let self, let imageView else { return }
            guard self.tokens[ObjectIdentifier(imageView)] == myToken else { return }
            var image: UIImage?
            if let data, !data.isEmpty {
                image = self.downsampled(data: data, maxPixel: pixel)
            }
            if let image {
                self.cache.setObject(image, forKey: url as NSURL, cost: pixel * pixel * 4)
            }
            DispatchQueue.main.async {
                guard self.tokens[ObjectIdentifier(imageView)] == myToken else { return }
                self.running[ObjectIdentifier(imageView)] = nil
                imageView.image = image ?? placeholder
            }
        }
        running[key] = task
        task.resume()
    }

    private func downsampled(data: Data, maxPixel: Int) -> UIImage? {
        let srcOpts = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let src = CGImageSourceCreateWithData(data as CFData, srcOpts) else { return nil }
        let thumbOpts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, thumbOpts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }
}
