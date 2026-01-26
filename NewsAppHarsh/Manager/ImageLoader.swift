//
//  ImageLoader.swift
//  NewsAppHarsh
//
//  Created by Harsh on 26/01/26.
//
import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    // Memory & Disk Cache
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    private init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 1024 * 1024 * 100
    }

    // Change: Return Type is URLSessionDataTask? (To allow cancellation)
    @discardableResult
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        // 1. Check Memory Cache ⚡
        if let cachedImage = memoryCache.object(forKey: urlString as NSString) {
            completion(cachedImage)
            return nil // No network task needed
        }

        // 2. Check Disk Cache 💾
        if let diskImage = getImageFromDisk(by: urlString) {
            memoryCache.setObject(diskImage, forKey: urlString as NSString)
            completion(diskImage)
            return nil
        }

        // 3. Network Call 🌍
        guard let url = URL(string: urlString) else {
            completion(nil)
            return nil
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Save to Caches
            self.memoryCache.setObject(image, forKey: urlString as NSString)
            self.saveImageToDisk(image: image, fileName: urlString)

            DispatchQueue.main.async {
                completion(image)
            }
        }

        task.resume()
        return task // Return task handle
    }

    // MARK: - Disk Helper Methods (Same as before)

    private func getCacheDirectory() -> URL? {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private func getFilePath(for urlString: String) -> URL? {
        guard let cacheDir = getCacheDirectory() else { return nil }
        guard let data = urlString.data(using: .utf8) else { return nil }
        let fileName = data.base64EncodedString()
        return cacheDir.appendingPathComponent(fileName)
    }

    private func saveImageToDisk(image: UIImage, fileName: String) {
        // Run on background to avoid UI lag
        DispatchQueue.global(qos: .background).async {
            guard let fileURL = self.getFilePath(for: fileName),
                  let data = image.jpegData(compressionQuality: 1.0) else { return }
            try? data.write(to: fileURL)
        }
    }

    private func getImageFromDisk(by fileName: String) -> UIImage? {
        guard let fileURL = getFilePath(for: fileName),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}
