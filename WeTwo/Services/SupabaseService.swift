//
//  SupabaseService.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    // MARK: - Configuration
    private let supabaseURL = SupabaseConfig.supabaseURL
    private let supabaseAnonKey = SupabaseConfig.supabaseAnonKey
    
    private init() {
        print("🔧 Initializing Supabase client...")
        print("   URL: \(supabaseURL)")
        print("   Key: \(String(supabaseAnonKey.prefix(20)))...")
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
        print("✅ Supabase client initialized with URL: \(supabaseURL)")
        
        // Test connection
        Task {
            await testConnection()
        }
    }
    
    // MARK: - Helper Functions
    private func isoDate(_ d: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: d)
    }
    
    // MARK: - Connection Test
    private func testConnection() async {
        do {
            print("🔍 Testing Supabase connection...")
            let response: [String] = try await client
                .from("profiles")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            print("✅ Supabase connection successful! Found \(response.count) profiles")
        } catch {
            print("❌ Supabase connection failed: \(error)")
        }
    }
    
    // MARK: - User Management
    func signUp(email: String, password: String) async throws -> SupabaseUser {
        print("🔧 Attempting to sign up user: \(email)")
        
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        let user = authResponse.user
        print("✅ User signed up successfully: \(user.id)")
        
        return SupabaseUser(
            id: user.id.uuidString,
            email: user.email ?? "",
            createdAt: user.createdAt
        )
    }
    
    func signUpWithProfile(email: String, password: String, name: String, birthDate: Date) async throws -> SupabaseUser {
        print("🔧 Attempting to sign up user with profile: \(email)")

        // 1) Sign up
        let _ = try await client.auth.signUp(email: email, password: password)

        // 2) Falls keine Session (z. B. Email Confirm ON) → signIn
        if (try? await client.auth.session) == nil {
            _ = try await client.auth.signIn(email: email, password: password)
        }

        guard let session = try? await client.auth.session else {
            throw SupabaseError.invalidResponse
        }
        let user = session.user

        // 3) Profile nur updaten (wurde durch DB-Trigger erstellt)
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd" // WICHTIG: DATE in DB

        let birth = df.string(from: birthDate)
        let zodiac = ZodiacSign.calculate(from: birthDate).rawValue

        try await client
            .from("profiles")
            .update([
                "name": name,
                "zodiac_sign": zodiac,
                "birth_date": birth
            ])
            .eq("id", value: user.id.uuidString)
            .execute()

        print("✅ Profile updated for user \(user.id)")

        return SupabaseUser(id: user.id.uuidString, email: user.email ?? "", createdAt: user.createdAt)
    }
    
    func signIn(email: String, password: String) async throws -> SupabaseUser {
        print("🔧 Attempting to sign in user: \(email)")
        
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        let user = authResponse.user
        print("✅ User signed in successfully: \(user.id)")
        
        return SupabaseUser(
            id: user.id.uuidString,
            email: user.email ?? "",
            createdAt: user.createdAt
        )
    }
    
    func signOut() async throws {
        print("🔧 Attempting to sign out user")
        
        try await client.auth.signOut()
        print("✅ User signed out successfully")
    }
    
    func getCurrentUser() async -> SupabaseUser? {
        do {
            let session = try await client.auth.session
            let user = session.user
            
            return SupabaseUser(
                id: user.id.uuidString,
                email: user.email ?? "",
                createdAt: user.createdAt
            )
        } catch {
            print("❌ Error getting current user: \(error)")
            return nil
        }
    }
    
    // MARK: - Profile Management
    func createProfile(userId: String, name: String, birthDate: Date) async throws {
        print("🔧 Creating profile for user: \(userId)")
        print("   Name: \(name)")
        print("   Birth Date: \(birthDate)")
        
        let calculatedZodiac = ZodiacSign.calculate(from: birthDate)
        let profile = Profile(
            id: userId,
            name: name,
            zodiacSign: calculatedZodiac.rawValue,
            birthDate: birthDate,
            profilePhotoURL: nil,
            relationshipStatus: nil,
            hasChildren: nil,
            childrenCount: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await client
            .from("profiles")
            .insert(profile)
            .execute()
        
        print("✅ Profile created successfully for user: \(userId)")
    }
    
    func updateProfile(userId: String, name: String, birthDate: Date) async throws {
        print("🔧 Updating profile for user: \(userId)")
        
        let calculatedZodiac = ZodiacSign.calculate(from: birthDate)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        
        try await client
            .from("profiles")
            .update([
                "name": name,
                "zodiac_sign": calculatedZodiac.rawValue,
                "birth_date": df.string(from: birthDate),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: userId)
            .execute()
        
        print("✅ Profile updated successfully!")
    }
    
    func getProfile(userId: String) async throws -> Profile? {
        print("🔧 Getting profile for user: \(userId)")
        
        let response: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        
        return response.first
    }
    
    func updateRelationshipData(userId: String, relationshipStatus: String, hasChildren: Bool, childrenCount: Int) async throws {
        print("🔧 Updating relationship data for user: \(userId)")
        print("   Status: \(relationshipStatus)")
        print("   Has Children: \(hasChildren)")
        print("   Children Count: \(childrenCount)")
        
        try await client
            .from("profiles")
            .update([
                "relationship_status": relationshipStatus,
                "has_children": hasChildren ? "true" : "false",
                "children_count": String(childrenCount),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: userId)
            .execute()
        
        print("✅ Relationship data updated successfully!")
    }
    
    // MARK: - Memory Management
    func createMemory(_ memory: MemoryEntry) async throws {
        print("🔧 Creating memory: \(memory.title)")
        guard let session = try? await client.auth.session else { throw SupabaseError.userNotFound }
        let userId = session.user.id.uuidString

        let databaseMemory = DatabaseMemory(
            id: memory.id.uuidString,
            userId: memory.userId.uuidString,
            partnerId: memory.partnerId?.uuidString,
            date: memory.date,
            title: memory.title,
            description: memory.description,
            photoData: memory.photoData,
            location: memory.location,
            moodLevel: String(memory.moodLevel.rawValue),
            tags: memory.tags.joined(separator: ","),
            isShared: memory.isShared,
            createdAt: memory.createdAt,
            updatedAt: Date()
        )

        try await client.from("memories").insert(databaseMemory).execute()
        print("✅ Memory created successfully: \(memory.title)")
    }
    
    func getMemories(userId: String) async throws -> [MemoryEntry] {
        print("🔧 Getting memories for user: \(userId)")
        
        let response: [DatabaseMemory] = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.compactMap { dbMemory -> MemoryEntry? in
            guard let id = UUID(uuidString: dbMemory.id),
                  let userId = UUID(uuidString: dbMemory.userId),
                  let moodLevel = MoodLevel(rawValue: Int(dbMemory.moodLevel) ?? 0) else {
                return nil
            }
            
            let partnerId = dbMemory.partnerId.flatMap { UUID(uuidString: $0) }
            let tags = dbMemory.tags.isEmpty ? [] : dbMemory.tags.components(separatedBy: ",")
            
            return MemoryEntry(
                userId: userId,
                title: dbMemory.title,
                description: dbMemory.description,
                photoData: dbMemory.photoData,
                location: dbMemory.location,
                moodLevel: moodLevel,
                tags: tags,
                partnerId: partnerId
            )
        }
    }
    
    func getSharedMemories(userId: String, partnerId: String) async throws -> [MemoryEntry] {
        print("🔧 Getting shared memories between users: \(userId) and \(partnerId)")
        
        let response: [DatabaseMemory] = try await client
            .from("memories")
            .select()
            .or("user_id.eq.\(userId),user_id.eq.\(partnerId)")
            .eq("is_shared", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.compactMap { dbMemory -> MemoryEntry? in
            guard let id = UUID(uuidString: dbMemory.id),
                  let userId = UUID(uuidString: dbMemory.userId),
                  let moodLevel = MoodLevel(rawValue: Int(dbMemory.moodLevel) ?? 0) else {
                return nil
            }
            
            let partnerId = dbMemory.partnerId.flatMap { UUID(uuidString: $0) }
            let tags = dbMemory.tags.isEmpty ? [] : dbMemory.tags.components(separatedBy: ",")
            
            return MemoryEntry(
                userId: userId,
                title: dbMemory.title,
                description: dbMemory.description,
                photoData: dbMemory.photoData,
                location: dbMemory.location,
                moodLevel: moodLevel,
                tags: tags,
                partnerId: partnerId
            )
        }
    }
    
    func updateMemory(_ memory: MemoryEntry) async throws {
        print("🔧 Updating memory: \(memory.title)")
        
        try await client
            .from("memories")
            .update([
                "title": memory.title,
                "description": memory.description,
                "photo_data": memory.photoData?.base64EncodedString(),
                "location": memory.location,
                "mood_level": String(memory.moodLevel.rawValue),
                "tags": memory.tags.joined(separator: ","),
                "is_shared": memory.isShared ? "true" : "false",
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: memory.id.uuidString)
            .execute()
        
        print("✅ Memory updated successfully!")
    }
    
    func deleteMemory(_ memoryId: String) async throws {
        print("🔧 Deleting memory: \(memoryId)")
        
        try await client
            .from("memories")
            .delete()
            .eq("id", value: memoryId)
            .execute()
        
        print("✅ Memory deleted successfully!")
    }
    
    // MARK: - Profile Photo Management
    func uploadProfilePhoto(userId: String, imageData: Data) async throws -> String {
        print("🔧 Uploading profile photo for user: \(userId)")
        
        let fileName = "\(userId).jpg"
        
        try await client.storage
            .from("profile-photos")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        let photoURL = try client.storage
            .from("profile-photos")
            .getPublicURL(path: fileName)
        
        // Update profile with photo URL
        try await client
            .from("profiles")
            .update(["profile_photo_url": photoURL])
            .eq("id", value: userId)
            .execute()
        
        print("✅ Profile photo uploaded successfully!")
        return photoURL.absoluteString
    }
    
    func getProfilePhotoURL(userId: String) async -> String? {
        return try? client.storage
            .from("profile-photos")
            .getPublicURL(path: "\(userId).jpg")
            .absoluteString
    }
    
    func deleteProfilePhoto(userId: String) async throws {
        print("🔧 Deleting profile photo for user: \(userId)")
        
        try await client.storage
            .from("profile-photos")
            .remove(paths: ["\(userId).jpg"])
        
        // Remove photo URL from profile
        try await client
            .from("profiles")
            .update(["profile_photo_url": ""])
            .eq("id", value: userId)
            .execute()
        
        print("✅ Profile photo deleted successfully!")
    }
    
    // MARK: - Partner Management
    func getPartnerProfile(userId: String) async throws -> Profile? {
        print("🔧 Getting partner profile for user: \(userId)")
        
        // First get the partnership
        let partnerships: [Partnership] = try await client
            .from("partnerships")
            .select()
            .or("user_id.eq.\(userId),partner_id.eq.\(userId)")
            .eq("status", value: "active")
            .execute()
            .value
        
        guard let partnership = partnerships.first else {
            print("❌ No active partnership found")
            return nil
        }
        
        // Get partner ID
        let partnerId = partnership.userId == userId ? partnership.partnerId : partnership.userId
        
        // Get partner profile
        let profile: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: partnerId)
            .execute()
            .value
        
        return profile.first
    }
    
    func createPartnership(userId: String, partnerId: String, connectionCode: String) async throws {
        print("🔧 Creating partnership between users: \(userId) and \(partnerId)")
        
        let partnership = Partnership(
            id: UUID().uuidString,
            userId: userId,
            partnerId: partnerId,
            connectionCode: connectionCode,
            status: "active",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await client
            .from("partnerships")
            .insert(partnership)
            .execute()
        
        print("✅ Partnership created successfully!")
    }
    
    func getPartnerships(userId: String) async throws -> [Partnership] {
        print("🔧 Getting partnerships for user: \(userId)")
        
        let response: [Partnership] = try await client
            .from("partnerships")
            .select()
            .or("user_id.eq.\(userId),partner_id.eq.\(userId)")
            .execute()
            .value
        
        return response
    }
    
    func getPartnershipByCode(connectionCode: String) async throws -> Partnership? {
        print("🔧 Getting partnership by connection code: \(connectionCode)")
        
        let response: [Partnership] = try await client
            .from("partnerships")
            .select()
            .eq("connection_code", value: connectionCode)
            .eq("status", value: "active")
            .execute()
            .value
        
        return response.first
    }
    
    // MARK: - Partner Management
    func findPartnerByCode(connectionCode: String) async throws -> Profile? {
        print("🔧 Finding partner by connection code: \(connectionCode)")
        
        // First get the partnership
        guard let partnership = try await getPartnershipByCode(connectionCode: connectionCode) else {
            return nil
        }
        
        // Then get the partner's profile
        return try await getProfile(userId: partnership.partnerId)
    }
    
    func subscribeToPartnerUpdates(userId: String, completion: @escaping (Profile) -> Void) async throws {
        print("🔧 Subscribing to partner updates for user: \(userId)")
        
        // TODO: Implement real-time subscription using Supabase Realtime
        // For now, this is a placeholder that will be implemented later
        print("⚠️ Real-time subscription not yet implemented")
    }
    
    func disconnectPartner(userId: String) async throws {
        print("🔧 Disconnecting partner for user: \(userId)")
        
        try await client
            .from("partnerships")
            .update(["status": "inactive"])
            .eq("user_id", value: userId)
            .execute()
        
        print("✅ Partner disconnected successfully!")
    }
    
    func unsubscribeFromPartnerUpdates(userId: String) async throws {
        print("🔧 Unsubscribing from partner updates for user: \(userId)")
        
        // TODO: Implement unsubscription from Supabase Realtime
        // For now, this is a placeholder that will be implemented later
        print("⚠️ Real-time unsubscription not yet implemented")
    }
    
    func updateSharedProfile(userId: String, name: String, zodiacSign: String, birthDate: Date) async throws {
        print("🔧 Updating shared profile for user: \(userId)")
        
        let profileData = SharedProfileUpdate(
            name: name,
            zodiacSign: zodiacSign,
            birthDate: ISO8601DateFormatter().string(from: birthDate),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("profiles")
            .update(profileData)
            .eq("id", value: userId)
            .execute()
        
        print("✅ Shared profile updated successfully!")
    }
    
    func getPartnershipStatus(userId: String) async throws -> String {
        print("🔧 Getting partnership status for user: \(userId)")
        
        let response: [Partnership] = try await client
            .from("partnerships")
            .select("status")
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .execute()
            .value
        
        return response.first?.status ?? "not_connected"
    }
    
    func downloadProfilePhoto(userId: String) async throws -> Data? {
        print("🔧 Downloading profile photo for user: \(userId)")
        
        // First get the profile to find the photo URL
        guard let profile = try await getProfile(userId: userId),
              let photoURL = profile.profilePhotoURL else {
            return nil
        }
        
        // TODO: Implement actual photo download from storage
        // For now, return nil as placeholder
        print("⚠️ Photo download not yet implemented")
        return nil
    }
    
    // MARK: - Love Messages
    func saveLoveMessage(senderId: String, receiverId: String, message: String) async throws {
        print("🔧 Saving love message from \(senderId) to \(receiverId)")
        
        let loveMessage = LoveMessageInsert(
            id: UUID().uuidString,
            senderId: senderId,
            receiverId: receiverId,
            message: message,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            isRead: false
        )
        
        try await client
            .from("love_messages")
            .insert(loveMessage)
            .execute()
        
        print("✅ Love message saved successfully!")
        
        // TODO: Send push notification to receiver
        // This could be done through:
        // 1. Supabase Edge Functions
        // 2. Firebase Cloud Messaging
        // 3. Apple Push Notification Service (APNs)
    }
    
    func getLoveMessages(userId: String) async throws -> [LoveMessage] {
        print("🔧 Getting love messages for user: \(userId)")
        
        let response: [DatabaseLoveMessage] = try await client
            .from("love_messages")
            .select()
            .or("sender_id.eq.\(userId),receiver_id.eq.\(userId)")
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        return response.map { dbMessage in
            LoveMessage(
                id: dbMessage.id,
                senderId: UUID(uuidString: dbMessage.senderId) ?? UUID(),
                receiverId: UUID(uuidString: dbMessage.receiverId) ?? UUID(),
                message: dbMessage.message,
                timestamp: ISO8601DateFormatter().date(from: dbMessage.timestamp) ?? Date(),
                isRead: dbMessage.isRead
            )
        }
    }
    
    func markLoveMessageAsRead(messageId: String) async throws {
        print("🔧 Marking love message as read: \(messageId)")
        
        try await client
            .from("love_messages")
            .update(["is_read": true])
            .eq("id", value: messageId)
            .execute()
        
        print("✅ Love message marked as read!")
    }
}

// MARK: - Data Models
struct SupabaseUser: Codable {
    let id: String
    let email: String
    let createdAt: Date
}

struct Profile: Codable {
    let id: String
    let name: String
    let zodiacSign: String
    let birthDate: Date
    let profilePhotoURL: String?
    let relationshipStatus: String?
    let hasChildren: Bool?
    let childrenCount: Int?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case zodiacSign = "zodiac_sign"
        case birthDate = "birth_date"
        case profilePhotoURL = "profile_photo_url"
        case relationshipStatus = "relationship_status"
        case hasChildren = "has_children"
        case childrenCount = "children_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProfileWithAppleID: Codable {
    let id: String
    let name: String
    let zodiacSign: String
    let birthDate: Date
    let appleUserID: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case zodiacSign = "zodiac_sign"
        case birthDate = "birth_date"
        case appleUserID = "apple_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LoveMessageInsert: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let message: String
    let timestamp: String
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case message
        case timestamp
        case isRead = "is_read"
    }
}

struct DatabaseLoveMessage: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let message: String
    let timestamp: String
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case message
        case timestamp
        case isRead = "is_read"
    }
}

struct DatabaseMemory: Codable {
    let id: String
    let userId: String
    let partnerId: String?
    let date: Date
    let title: String
    let description: String?
    let photoData: Data?
    let location: String?
    let moodLevel: String
    let tags: String
    let isShared: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partnerId = "partner_id"
        case date
        case title
        case description
        case photoData = "photo_data"
        case location
        case moodLevel = "mood_level"
        case tags
        case isShared = "is_shared"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SharedProfileUpdate: Codable {
    let name: String
    let zodiacSign: String
    let birthDate: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case zodiacSign = "zodiac_sign"
        case birthDate = "birth_date"
        case updatedAt = "updated_at"
    }
}

struct Partnership: Codable {
    let id: String
    let userId: String
    let partnerId: String
    let connectionCode: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partnerId = "partner_id"
        case connectionCode = "connection_code"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum PartnershipStatus {
    case notConnected
    case connected(partnerName: String, partnerId: String)
    
    var isConnected: Bool {
        switch self {
        case .notConnected: return false
        case .connected: return true
        }
    }
    
    var partnerName: String? {
        switch self {
        case .notConnected: return nil
        case .connected(let name, _): return name
        }
    }
    
    var partnerId: String? {
        switch self {
        case .notConnected: return nil
        case .connected(_, let id): return id
        }
    }
    
    static func fromString(_ status: String) -> PartnershipStatus {
        switch status {
        case "active":
            // For now, return notConnected since we don't have partner details here
            // In a real implementation, you'd need to pass the partner details
            return .notConnected
        default:
            return .notConnected
        }
    }
}

// MARK: - Errors
enum SupabaseError: Error, LocalizedError {
    case userNotFound
    case invalidResponse
    case uploadFailed
    case downloadFailed
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Benutzer nicht gefunden"
        case .invalidResponse:
            return "Ungültige Antwort vom Server"
        case .uploadFailed:
            return "Upload fehlgeschlagen"
        case .downloadFailed:
            return "Download fehlgeschlagen"
        case .notImplemented:
            return "Funktion noch nicht implementiert"
        }
    }
}

// MARK: - Extensions
extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        var results: [T] = []
        for element in self {
            if let transformed = try await transform(element) {
                results.append(transformed)
            }
        }
        return results
    }
} 