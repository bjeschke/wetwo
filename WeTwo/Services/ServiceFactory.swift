//
//  ServiceFactory.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

// MARK: - Service Protocol

protocol DataServiceProtocol {
    // Authentication
    func signIn(email: String, password: String) async throws -> User
    func signInWithApple(idToken: String, nonce: String) async throws -> User
    func signUp(email: String, password: String, name: String, birthDate: Date) async throws -> User
    func signOut() async throws
    func getCurrentUserId() async throws -> String?
    
    // Profile Management
    func getUserProfile() async throws -> SimpleProfile?
    func updateProfile(userId: String, name: String, birthDate: Date?) async throws
    func updateAuthUserDisplayName(name: String) async throws
    func ensureProfileExists() async throws
    func updateProfilePushToken(userId: String, pushToken: String) async throws
    func updateRelationshipData(userId: String, relationshipStatus: String, hasChildren: String, childrenCount: String) async throws
    
    // Memory Management
    func createMemory(_ memory: Memory) async throws -> Memory
    func memories(userId: String) async throws -> [Memory]
    func updateMemory(_ memory: Memory) async throws -> Memory
    func deleteMemory(_ memoryId: Int) async throws
    
    // Partnership Management
    func createPartnership(userId: String, partnerId: String, connectionCode: String) async throws -> Partnership
    func findPartnershipByCode(_ code: String) async throws -> Partnership?
    func partnership(userId: String) async throws -> Partnership?
    func subscribeToPartnerUpdates(userId: String, completion: @escaping (Profile) -> Void) async throws
    func unsubscribeFromPartnerUpdates(userId: String) async throws
    func disconnectPartner(userId: String) async throws
    func getPartnershipStatus(userId: String) async throws -> PartnershipStatus
    func getPartnerProfile(userId: String) async throws -> Profile?
    func updateSharedProfile(userId: String, updates: [String: Any]) async throws
    func downloadProfilePhoto(userId: String) async throws -> Data?
    
    // Love Message Management
    func sendLoveMessage(to partnerId: String, text: String) async throws -> LoveMessage
    func conversation(with partnerId: String) async throws -> [LoveMessage]
    
    // Mood Entry Management
    func createMoodEntry(_ moodEntry: DatabaseMoodEntry) async throws -> DatabaseMoodEntry
    func getMoodEntries(userId: String, startDate: Date?, endDate: Date?) async throws -> [DatabaseMoodEntry]
    func getTodayMoodEntry(userId: String) async throws -> DatabaseMoodEntry?
    
    // Photo Storage
    func uploadProfilePhoto(userId: String, imageData: Data) async throws
    
    // Push Notifications
    func sendPushNotificationToPartner(userId: String, partnerId: String, title: String, body: String, data: [String: String]) async throws
    
    // Onboarding
    func completeOnboarding(email: String, password: String, name: String, birthDate: Date) async throws -> DatabaseUser
    
    // Utility
    func checkConnectionHealth() async throws -> Bool
    func isConnected() async throws -> Bool
    func logout() async throws
}

// MARK: - Service Factory

enum ServiceType {
    case backend
}

final class ServiceFactory {
    static let shared = ServiceFactory()
    
    private var currentServiceType: ServiceType = .backend
    private var currentService: DataServiceProtocol?
    
    private init() {
        // Initialize with the default service
        currentService = createService(type: currentServiceType)
    }
    
    // MARK: - Service Creation
    
    func createService(type: ServiceType) -> DataServiceProtocol {
        switch type {
        case .backend:
            return BackendService.shared
        }
    }
    
    // MARK: - Service Management
    
    func getCurrentService() -> DataServiceProtocol {
        if currentService == nil {
            currentService = createService(type: currentServiceType)
        }
        return currentService!
    }
    
    func switchToService(_ type: ServiceType) {
        currentServiceType = type
        currentService = createService(type: type)
        print("🔄 Switched to \(type) service")
    }
    
    func getCurrentServiceType() -> ServiceType {
        return currentServiceType
    }
    
    // MARK: - Configuration
    
    func configureForEnvironment() {
        #if DEBUG
        // In debug mode, use backend
        switchToService(.backend)
        #else
        // In production, use backend
        switchToService(.backend)
        #endif
        
        // Ensure we're using backend for everything
        currentServiceType = .backend
        currentService = createService(type: .backend)
    }
    
    // MARK: - Service Validation
    
    func validateCurrentService() async -> Bool {
        do {
            return try await getCurrentService().checkConnectionHealth()
        } catch {
            print("❌ Service validation failed: \(error)")
            return false
        }
    }
    
    func fallbackToBackendIfNeeded() async {
        let isHealthy = await validateCurrentService()
        if !isHealthy {
            print("⚠️ Current service unhealthy, switching to Backend")
            switchToService(.backend)
        }
    }
}
