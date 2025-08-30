import Foundation
import UIKit

class ImageCacheService {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared
    
    private init() {
        // Configure cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Public Methods
    
    func loadImage(from urlString: String) async throws -> UIImage {
        let cacheKey = NSString(string: urlString)
        
        // Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            print("ImageCacheService: Returning cached image for: \(urlString)")
            return cachedImage
        }
        
        // Download image
        guard let url = URL(string: urlString) else {
            throw ImageCacheError.invalidURL
        }
        
        print("ImageCacheService: Downloading image from: \(urlString)")
        let (data, response) = try await session.data(from: url)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImageCacheError.invalidResponse
        }
        
        // Validate content type
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           !contentType.starts(with: "image/") {
            throw ImageCacheError.invalidImageType
        }
        
        // Create image
        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }
        
        // Cache the image
        cache.setObject(image, forKey: cacheKey)
        print("ImageCacheService: Image downloaded and cached for: \(urlString)")
        
        return image
    }
    
    func loadImageWithFallback(from urlString: String?, fallback: UIImage? = nil) async -> UIImage? {
        guard let urlString = urlString else {
            return fallback
        }
        
        do {
            return try await loadImage(from: urlString)
        } catch {
            print("ImageCacheService: Failed to load image from \(urlString): \(error)")
            return fallback
        }
    }
    
    func preloadImage(from urlString: String) {
        Task {
            do {
                _ = try await loadImage(from: urlString)
            } catch {
                print("ImageCacheService: Failed to preload image from \(urlString): \(error)")
            }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cache.removeAllObjects()
        print("ImageCacheService: Cache cleared")
    }
    
    func removeImageFromCache(urlString: String) {
        let cacheKey = NSString(string: urlString)
        cache.removeObject(forKey: cacheKey)
        print("ImageCacheService: Removed image from cache: \(urlString)")
    }
    
    func getCacheInfo() -> String {
        return "Image Cache: \(cache.totalCostLimit / (1024 * 1024))MB limit"
    }
}

// MARK: - Image Cache Errors

enum ImageCacheError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidImageType
    case invalidImageData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidImageType:
            return "File is not a valid image"
        case .invalidImageData:
            return "Unable to create image from data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - UIImageView Extension for Convenience

extension UIImageView {
    func loadImage(from urlString: String?, placeholder: UIImage? = nil) {
        // Set placeholder immediately
        self.image = placeholder
        
        guard let urlString = urlString else { return }
        
        Task { @MainActor in
            let image = await ImageCacheService.shared.loadImageWithFallback(from: urlString, fallback: placeholder)
            self.image = image
        }
    }
}