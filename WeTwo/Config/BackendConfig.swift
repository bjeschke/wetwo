//
//  BackendConfig.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

struct BackendConfig {
    
    // MARK: - Environment Configuration
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://wetwobackend-production.up.railway.app"
            case .staging:
                return "https://wetwobackend-production.up.railway.app"
            case .production:
                return "https://wetwobackend-production.up.railway.app"
            }
        }
        
        var apiKey: String {
            switch self {
            case .development:
                return "" // Add your Railway API key here if needed
            case .staging:
                return "" // Add your Railway API key here if needed
            case .production:
                return "" // Add your Railway API key here if needed
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
    static let baseURL = currentEnvironment.baseURL
    static let apiKey = currentEnvironment.apiKey
    
    // MARK: - API Endpoints
    static let authEndpoint = "/api/auth"
    static let profilesEndpoint = "/api/profiles"
    static let memoriesEndpoint = "/api/memories"
    static let partnershipsEndpoint = "/api/partnerships"
    static let loveMessagesEndpoint = "/api/love-messages"
    static let moodEntriesEndpoint = "/api/mood-entries"
    static let storageEndpoint = "/api/storage"
    
    // MARK: - Feature Flags
    static let enableRealTimeSync = true
    static let enableOfflineMode = true
    static let enablePhotoCompression = true
    static let photoCompressionQuality: Float = 0.8
    
    // MARK: - Limits
    static let maxPhotoSizeMB: Int = 10
    static let maxMemoriesPerUser: Int = 1000
    static let maxTagsPerMemory: Int = 10
    
    // MARK: - Freemium Limits
    static let freeInsightsPerWeek: Int = 3
    static let freePhotoUploadsPerWeek: Int = 1
    static let freeMemoriesPerMonth: Int = 50
    
    // MARK: - Premium Limits
    static let premiumInsightsPerWeek: Int = 7
    static let premiumPhotoUploadsPerWeek: Int = 10
    static let premiumMemoriesPerMonth: Int = 1000
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        guard !baseURL.isEmpty,
              baseURL.hasPrefix("https://") else {
            print("❌ Invalid Backend configuration")
            return false
        }
        
        print("✅ Backend configuration is valid")
        return true
    }
    
    // MARK: - Debug Information
    static func printConfiguration() {
        print("🔧 Backend Configuration:")
        print("   Environment: \(currentEnvironment)")
        print("   Base URL: \(baseURL)")
        print("   API Key: \(apiKey.isEmpty ? "Not set" : "Set")")
        print("   Real-time Sync: \(enableRealTimeSync)")
        print("   Offline Mode: \(enableOfflineMode)")
        print("   Photo Compression: \(enablePhotoCompression)")
    }
    
    // MARK: - URL Construction
    static func url(for endpoint: String) -> URL? {
        return URL(string: baseURL + endpoint)
    }
    
    static func authURL() -> URL? {
        return url(for: authEndpoint)
    }
    
    static func profilesURL() -> URL? {
        return url(for: profilesEndpoint)
    }
    
    static func memoriesURL() -> URL? {
        return url(for: memoriesEndpoint)
    }
    
    static func partnershipsURL() -> URL? {
        return url(for: partnershipsEndpoint)
    }
    
    static func loveMessagesURL() -> URL? {
        return url(for: loveMessagesEndpoint)
    }
    
    static func moodEntriesURL() -> URL? {
        return url(for: moodEntriesEndpoint)
    }
    
    static func storageURL() -> URL? {
        return url(for: storageEndpoint)
    }
}

// MARK: - Environment Detection
extension BackendConfig {
    
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

// MARK: - Feature Toggles
extension BackendConfig {
    
    static func isFeatureEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .realTimeSync:
            return enableRealTimeSync
        case .offlineMode:
            return enableOfflineMode
        case .photoCompression:
            return enablePhotoCompression
        case .partnerSync:
            return true // Always enabled
        case .premiumFeatures:
            return true // Always enabled, controlled by subscription
        }
    }
    
    enum Feature {
        case realTimeSync
        case offlineMode
        case photoCompression
        case partnerSync
        case premiumFeatures
    }
}

// MARK: - Usage Limits
extension BackendConfig {
    
    static func getLimit(for feature: LimitFeature, isPremium: Bool = false) -> Int {
        switch feature {
        case .insightsPerWeek:
            return isPremium ? premiumInsightsPerWeek : freeInsightsPerWeek
        case .photoUploadsPerWeek:
            return isPremium ? premiumPhotoUploadsPerWeek : freePhotoUploadsPerWeek
        case .memoriesPerMonth:
            return isPremium ? premiumMemoriesPerMonth : freeMemoriesPerMonth
        }
    }
    
    enum LimitFeature {
        case insightsPerWeek
        case photoUploadsPerWeek
        case memoriesPerMonth
    }
}
