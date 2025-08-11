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
    func signUp(email: String, password: String, name: String, birthDate: Date) async throws -> User
    func signOut() async throws
    func getCurrentUserId() async throws -> String?
    
    // Profile Management
    func getUserProfile() async throws -> Profile?
    func updateProfile(userId: String, name: String, birthDate: Date?) async throws
    func updateAuthUserDisplayName(name: String) async throws
    func ensureProfileExists() async throws
    
    // Memory Management
    func createMemory(_ memory: Memory) async throws -> Memory
    func memories(userId: String) async throws -> [Memory]
    func updateMemory(_ memory: Memory) async throws -> Memory
    func deleteMemory(_ memoryId: UUID) async throws
    
    // Partnership Management
    func createPartnership(userId: String, partnerId: String, connectionCode: String) async throws -> Partnership
    func findPartnershipByCode(_ code: String) async throws -> Partnership?
    func partnership(userId: String) async throws -> Partnership?
    
    // Love Message Management
    func sendLoveMessage(to partnerId: String, text: String) async throws -> LoveMessage
    func conversation(with partnerId: String) async throws -> [LoveMessage]
    
    // Mood Entry Management
    func createMoodEntry(_ moodEntry: SupabaseMoodEntry) async throws -> SupabaseMoodEntry
    func getMoodEntries(userId: String, startDate: Date?, endDate: Date?) async throws -> [SupabaseMoodEntry]
    func getTodayMoodEntry(userId: String) async throws -> SupabaseMoodEntry?
    
    // Photo Storage
    func uploadProfilePhoto(userId: String, imageData: Data) async throws
    
    // Push Notifications
    func sendPushNotificationToPartner(userId: String, partnerId: String, title: String, body: String, data: [String: String]) async throws
    
    // Onboarding
    func completeOnboarding(email: String, password: String, name: String, birthDate: Date) async throws -> SupabaseUser
    
    // Utility
    func checkConnectionHealth() async throws -> Bool
    func isConnected() async throws -> Bool
    func logout() async throws
}

// MARK: - Service Factory

enum ServiceType {
    case supabase
    case backend
}

final class ServiceFactory {
    static let shared = ServiceFactory()
    
    private var currentServiceType: ServiceType = .backend // Default to backend
    private var currentService: DataServiceProtocol?
    
    private init() {
        // Initialize with the default service
        currentService = createService(type: currentServiceType)
    }
    
    // MARK: - Service Creation
    
    func createService(type: ServiceType) -> DataServiceProtocol {
        switch type {
        case .supabase:
            return SupabaseService.shared
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
        // In debug mode, you can choose which service to use
        // For now, default to backend
        switchToService(.backend)
        #else
        // In production, use backend
        switchToService(.backend)
        #endif
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
    
    func fallbackToSupabaseIfNeeded() async {
        if currentServiceType == .backend {
            let isHealthy = await validateCurrentService()
            if !isHealthy {
                print("⚠️ Backend service unhealthy, falling back to Supabase")
                switchToService(.supabase)
            }
        }
    }
}

// MARK: - Service Extensions

extension SupabaseService: DataServiceProtocol {
    func memories(userId: String) async throws -> [Memory] {
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw AuthError.invalidData
        }
        return try await memories(userId: userIdUUID)
    }
    
    func createPartnership(userId: String, partnerId: String, connectionCode: String) async throws -> Partnership {
        guard let userIdUUID = UUID(uuidString: userId),
              let partnerIdUUID = UUID(uuidString: partnerId) else {
            throw AuthError.invalidData
        }
        return try await createOrActivatePartnership(userId: userIdUUID, partnerId: partnerIdUUID, code: connectionCode)
    }
    
    func findPartnershipByCode(_ code: String) async throws -> Partnership? {
        return try await findPartnershipByCode(code)
    }
    
    func partnership(userId: String) async throws -> Partnership? {
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw AuthError.invalidData
        }
        return try await partnership(userId: userIdUUID)
    }
    
    func sendLoveMessage(to partnerId: String, text: String) async throws -> LoveMessage {
        guard let partnerIdUUID = UUID(uuidString: partnerId) else {
            throw AuthError.invalidData
        }
        return try await sendLoveMessage(to: partnerIdUUID, text: text)
    }
    
    func conversation(with partnerId: String) async throws -> [LoveMessage] {
        guard let partnerIdUUID = UUID(uuidString: partnerId) else {
            throw AuthError.invalidData
        }
        return try await conversation(with: partnerIdUUID)
    }
    
    func getMoodEntries(userId: String, startDate: Date?, endDate: Date?) async throws -> [SupabaseMoodEntry] {
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw AuthError.invalidData
        }
        return try await getMoodEntries(userId: userIdUUID, startDate: startDate, endDate: endDate)
    }
    
    func getTodayMoodEntry(userId: String) async throws -> SupabaseMoodEntry? {
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw AuthError.invalidData
        }
        return try await getTodayMoodEntry(userId: userIdUUID)
    }
    
    func uploadProfilePhoto(userId: String, imageData: Data) async throws {
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw AuthError.invalidData
        }
        try await uploadProfilePhoto(userId: userIdUUID, imageData: imageData)
    }
    
    func sendPushNotificationToPartner(userId: String, partnerId: String, title: String, body: String, data: [String: String]) async throws {
        guard let userIdUUID = UUID(uuidString: userId),
              let partnerIdUUID = UUID(uuidString: partnerId) else {
            throw AuthError.invalidData
        }
        try await sendPushNotificationToPartner(userId: userIdUUID, partnerId: partnerIdUUID, title: title, body: body, data: data)
    }
    
    func updateAuthUserDisplayName(name: String) async throws {
        try await updateAuthUserDisplayName(name: name)
    }
    
    func ensureProfileExists() async throws {
        try await ensureProfileExists()
    }
    
    func completeOnboarding(email: String, password: String, name: String, birthDate: Date) async throws -> SupabaseUser {
        return try await completeOnboarding(email: email, password: password, name: name, birthDate: birthDate)
    }
}

extension BackendService: DataServiceProtocol {
    // BackendService already implements all required methods
}
