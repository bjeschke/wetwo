//
//  SupabaseConfig.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

struct SupabaseConfig {
    
    // MARK: - Environment Configuration
    enum Environment {
        case development
        case staging
        case production
        
        var supabaseURL: String {
            // Prefer environment variables to avoid hardcoding secrets
            if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envURL.isEmpty {
                return envURL
            }
            switch self {
            case .development:
                return ""
            case .staging:
                return ""
            case .production:
                return ""
            }
        }
        
        var supabaseAnonKey: String {
            // Prefer environment variables to avoid hardcoding secrets
            if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envKey.isEmpty {
                return envKey
            }
            switch self {
            case .development:
                return ""
            case .staging:
                return ""
            case .production:
                return ""
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
    static let supabaseURL = currentEnvironment.supabaseURL
    static let supabaseAnonKey = currentEnvironment.supabaseAnonKey
    
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
        guard !supabaseURL.isEmpty,
              !supabaseAnonKey.isEmpty,
              supabaseURL.hasPrefix("https://") else {
            print("❌ Invalid Supabase configuration - Please set SUPABASE_URL and SUPABASE_ANON_KEY in environment variables")
            return false
        }
        
        print("✅ Supabase configuration is valid")
        return true
    }
    
    // MARK: - Debug Information
    static func printConfiguration() {
        print("🔧 Supabase Configuration:")
        print("   Environment: \(currentEnvironment)")
        print("   URL: \(supabaseURL)")
        let maskedKey = supabaseAnonKey.isEmpty ? "<empty>" : String(supabaseAnonKey.prefix(4)) + String(repeating: "*", count: max(0, supabaseAnonKey.count - 8)) + String(supabaseAnonKey.suffix(4))
        print("   Key: \(maskedKey)")
        print("   Real-time Sync: \(enableRealTimeSync)")
        print("   Offline Mode: \(enableOfflineMode)")
        print("   Photo Compression: \(enablePhotoCompression)")
    }
}

// MARK: - Environment Detection
extension SupabaseConfig {
    
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
extension SupabaseConfig {
    
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
extension SupabaseConfig {
    
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