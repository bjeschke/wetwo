import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit

class FirebaseStorageService: ObservableObject {
    static let shared = FirebaseStorageService()
    
    private let storage = Storage.storage()
    private let maxUploadSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    private init() {
        configureStorage()
    }
    
    private func configureStorage() {
        storage.maxUploadRetryTime = 10.0
        storage.maxDownloadRetryTime = 10.0
    }
    
    // MARK: - Profile Pictures
    
    func uploadProfilePicture(_ image: UIImage) async throws -> URL {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImageData
        }
        
        guard imageData.count <= maxUploadSize else {
            throw StorageError.fileTooLarge
        }
        
        let fileName = "\(userId)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = storage.reference().child("profile_pictures/\(userId)/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL
    }
    
    // MARK: - Memory Photos
    
    func uploadMemoryPhoto(_ image: UIImage, memoryId: String) async throws -> URL {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImageData
        }
        
        guard imageData.count <= maxUploadSize else {
            throw StorageError.fileTooLarge
        }
        
        let fileName = "\(memoryId)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = storage.reference().child("memories/\(userId)/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "userId": userId,
            "memoryId": memoryId
        ]
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL
    }
    
    func uploadMultipleMemoryPhotos(_ images: [UIImage], memoryId: String) async throws -> [URL] {
        var uploadedURLs: [URL] = []
        
        for image in images {
            do {
                let url = try await uploadMemoryPhoto(image, memoryId: memoryId)
                uploadedURLs.append(url)
            } catch {
                print("Failed to upload image: \(error)")
                continue
            }
        }
        
        if uploadedURLs.isEmpty && !images.isEmpty {
            throw StorageError.uploadFailed
        }
        
        return uploadedURLs
    }
    
    // MARK: - File Downloads
    
    func downloadImage(from url: URL) async throws -> UIImage {
        let storageRef = storage.reference(forURL: url.absoluteString)
        let data = try await storageRef.data(maxSize: maxUploadSize)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.invalidImageData
        }
        
        return image
    }
    
    func downloadImageData(from url: URL) async throws -> Data {
        let storageRef = storage.reference(forURL: url.absoluteString)
        return try await storageRef.data(maxSize: maxUploadSize)
    }
    
    // MARK: - File Deletion
    
    func deleteFile(at url: URL) async throws {
        let storageRef = storage.reference(forURL: url.absoluteString)
        try await storageRef.delete()
    }
    
    func deleteProfilePicture() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        let folderRef = storage.reference().child("profile_pictures/\(userId)")
        
        do {
            let result = try await folderRef.listAll()
            for item in result.items {
                try await item.delete()
            }
        } catch {
            print("Error deleting profile pictures: \(error)")
            throw StorageError.deletionFailed
        }
    }
    
    func deleteMemoryPhotos(memoryId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        let folderRef = storage.reference().child("memories/\(userId)")
        
        do {
            let result = try await folderRef.listAll()
            
            for item in result.items {
                let metadata = try await item.getMetadata()
                if metadata.customMetadata?["memoryId"] == memoryId {
                    try await item.delete()
                }
            }
        } catch {
            print("Error deleting memory photos: \(error)")
            throw StorageError.deletionFailed
        }
    }
    
    // MARK: - Storage Management
    
    func getUserStorageUsage() async throws -> Int64 {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        var totalSize: Int64 = 0
        
        // Check profile pictures
        let profileRef = storage.reference().child("profile_pictures/\(userId)")
        if let profileResult = try? await profileRef.listAll() {
            for item in profileResult.items {
                if let metadata = try? await item.getMetadata() {
                    totalSize += metadata.size
                }
            }
        }
        
        // Check memory photos
        let memoriesRef = storage.reference().child("memories/\(userId)")
        if let memoriesResult = try? await memoriesRef.listAll() {
            for item in memoriesResult.items {
                if let metadata = try? await item.getMetadata() {
                    totalSize += metadata.size
                }
            }
        }
        
        return totalSize
    }
    
    func clearUserCache() {
        // Clear any local cache if needed
        URLCache.shared.removeAllCachedResponses()
    }
}

enum StorageError: LocalizedError {
    case userNotAuthenticated
    case invalidImageData
    case fileTooLarge
    case uploadFailed
    case downloadFailed
    case deletionFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .invalidImageData:
            return "Invalid image data"
        case .fileTooLarge:
            return "File size exceeds maximum allowed size"
        case .uploadFailed:
            return "Failed to upload file"
        case .downloadFailed:
            return "Failed to download file"
        case .deletionFailed:
            return "Failed to delete file"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}