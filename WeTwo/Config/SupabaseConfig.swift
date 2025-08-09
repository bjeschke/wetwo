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
            switch self {
            case .development:
                return "https://yrzpfwatuxpnjsirjsma.supabase.co"
            case .staging:
                return "https://yrzpfwatuxpnjsirjsma.supabase.co"
            case .production:
                return "https://yrzpfwatuxpnjsirjsma.supabase.co"
            }
        }
        
        var supabaseAnonKey: String {
            switch self {
            case .development:
                return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyenBmd2F0dXhwbmpzaXJqc21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0MTQ0OTUsImV4cCI6MjA2OTk5MDQ5NX0.AH96-HIirPyiGxyMAbraVEFNEq02vVHWO0_S0loI5wY"
            case .staging:
                return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyenBmd2F0dXhwbmpzaXJqc21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0MTQ0OTUsImV4cCI6MjA2OTk5MDQ5NX0.AH96-HIirPyiGxyMAbraVEFNEq02vVHWO0_S0loI5wY"
            case .production:
                return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyenBmd2F0dXhwbmpzaXJqc21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0MTQ0OTUsImV4cCI6MjA2OTk5MDQ5NX0.AH96-HIirPyiGxyMAbraVEFNEq02vVHWO0_S0loI5wY"
            }
        }
    }
    
    // MARK: - Current Environment
    static let currentEnvironment: Environment = {
        #if DEBUG
        return .development
        #else
        // In production, you might want to use a different method
        // like reading from a configuration file or environment variable
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
              supabaseURL.hasPrefix("https://"),
              supabaseAnonKey.hasPrefix("eyJ") else {
            print("❌ Invalid Supabase configuration")
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
        print("   Key: \(String(supabaseAnonKey.prefix(20)))...")
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