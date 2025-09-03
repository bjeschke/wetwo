//
//  CloudflareR2Config.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

// MARK: - Cloudflare R2 Configuration

struct CloudflareR2Config {
    
    // MARK: - Environment Configuration
    enum Environment {
        case development
        case staging
        case production
        
        var accessKeyId: String {
            switch self {
            case .development, .staging, .production:
                return "6071a81a8af171dfdc31200f9e85c5cf"
            }
        }
        
        var secretAccessKey: String {
            switch self {
            case .development, .staging, .production:
                return "700fae89ff7f09302ca79b5505891557ba0d0a96621a8720b9b269d998ac077e"
            }
        }
        
        var endpoint: String {
            switch self {
            case .development, .staging, .production:
                return "https://fa151e87de0b5708a9317ae0e5be1cd6.r2.cloudflarestorage.com"
            }
        }
        
        var bucketName: String {
            switch self {
            case .development:
                return "wetwo-photos-dev"
            case .staging:
                return "wetwo-photos-staging"
            case .production:
                return "wetwo-photos"
            }
        }
    }
    
    // MARK: - Current Environment
    static let currentEnvironment: Environment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    // MARK: - Configuration Values
    static let accessKeyId = currentEnvironment.accessKeyId
    static let secretAccessKey = currentEnvironment.secretAccessKey
    static let endpoint = currentEnvironment.endpoint
    static let bucketName = currentEnvironment.bucketName
    static let region = "auto" // Cloudflare R2 uses 'auto' as the region
    
    // MARK: - Storage Settings
    static let maxFileSizeMB: Int = 10
    static let allowedImageTypes = ["image/jpeg", "image/png", "image/heic", "image/heif"]
    static let compressionQuality: Float = 0.8
    
    // MARK: - Folder Structure
    static let profilePhotosFolder = "profile-photos"
    static let memoryPhotosFolder = "memory-photos"
    static let moodPhotosFolder = "mood-photos"
    static let tempFolder = "temp"
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        guard !accessKeyId.isEmpty,
              !secretAccessKey.isEmpty,
              !endpoint.isEmpty,
              !bucketName.isEmpty,
              endpoint.hasPrefix("https://") else {
            print("❌ Invalid Cloudflare R2 configuration")
            return false
        }
        
        print("✅ Cloudflare R2 configuration is valid")
        return true
    }
    
    // MARK: - Debug Information
    static func printConfiguration() {
        print("🔧 Cloudflare R2 Configuration:")
        print("   Environment: \(currentEnvironment)")
        print("   Endpoint: \(endpoint)")
        print("   Bucket: \(bucketName)")
        print("   Access Key: \(String(accessKeyId.prefix(8)))...")
        print("   Max File Size: \(maxFileSizeMB)MB")
        print("   Compression Quality: \(compressionQuality)")
    }
    
    // MARK: - URL Generation
    static func getPublicURL(for path: String) -> URL {
        return URL(string: "\(endpoint)/\(bucketName)/\(path)")!
    }
    
    static func getProfilePhotoURL(userId: String) -> URL {
        let path = "\(profilePhotosFolder)/\(userId)/profile.jpg"
        return getPublicURL(for: path)
    }
    
    static func getMemoryPhotoURL(memoryId: String) -> URL {
        let path = "\(memoryPhotosFolder)/\(memoryId)/photo.jpg"
        return getPublicURL(for: path)
    }
    
    static func getMoodPhotoURL(userId: String, date: Date) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let path = "\(moodPhotosFolder)/\(userId)/\(dateString)/photo.jpg"
        return getPublicURL(for: path)
    }
}

// MARK: - Environment Detection
extension CloudflareR2Config {
    
    static var isDevelopment: Bool {
        return currentEnvironment == .development
    }
    
    static var isProduction: Bool {
        return currentEnvironment == .production
    }
    
    static var isStaging: Bool {
        return currentEnvironment == .staging
    }
}

// MARK: - File Management
extension CloudflareR2Config {
    
    static func validateFileSize(_ data: Data) -> Bool {
        let sizeInMB = Double(data.count) / (1024 * 1024)
        return sizeInMB <= Double(maxFileSizeMB)
    }
    
    static func validateImageType(_ mimeType: String) -> Bool {
        return allowedImageTypes.contains(mimeType)
    }
    
    static func getFileExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/jpeg":
            return "jpg"
        case "image/png":
            return "png"
        case "image/heic", "image/heif":
            return "heic"
        default:
            return "jpg"
        }
    }
}


