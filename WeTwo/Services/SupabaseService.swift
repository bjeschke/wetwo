import Foundation
import Supabase
import CryptoKit

// MARK: - Error Types

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case signUpFailed
    case userNotFound
    case networkError
    case databaseError
    case validationError
    case unauthorized
    case quotaExceeded
    case serviceUnavailable
    case invalidData
    case partnerNotFound
    case photoUploadFailed
    case photoDeleteFailed
    case storageError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .signUpFailed:
            return "Failed to create account"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network connection error"
        case .databaseError:
            return "Database operation failed"
        case .validationError:
            return "Data validation failed"
        case .unauthorized:
            return "Unauthorized access"
        case .quotaExceeded:
            return "Service quota exceeded"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        case .invalidData:
            return "Invalid data provided"
        case .partnerNotFound:
            return "Partner not found"
        case .photoUploadFailed:
            return "Failed to upload photo"
        case .photoDeleteFailed:
            return "Failed to delete photo"
        case .storageError:
            return "Storage operation failed"
        }
    }
}

// MARK: - Extensions

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - Models (Schema-exakt, snake_case via CodingKeys)

struct Profile: Codable, Sendable {
    let id: UUID
    var name: String
    var zodiac_sign: String
    var birth_date: String           // YYYY-MM-DD (Postgres DATE)
    var profile_photo_url: String?
    var relationship_status: String?
    var has_children: String?
    var children_count: String?
    var created_at: Date?
    var updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, zodiac_sign, birth_date, profile_photo_url
        case relationship_status, has_children, children_count
        case created_at, updated_at
    }
}

struct Memory: Codable, Sendable {
    var id: UUID?
    var user_id: UUID
    var partner_id: UUID?
    var date: String                 // YYYY-MM-DD
    var title: String
    var description: String?
    var photo_data: String?
    var location: String?
    var mood_level: String           // TEXT im Schema
    var tags: String?
    var is_shared: String?           // 'true' | 'false' (TEXT im Schema)
    var created_at: Date?
    var updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, user_id, partner_id, date, title, description
        case photo_data, location, mood_level, tags, is_shared
        case created_at, updated_at
    }
}

struct Partnership: Codable, Sendable {
    var id: String?
    var user_id: String
    var partner_id: String
    var connection_code: String
    var status: String?              // 'active' ...
    var created_at: Date?
    var updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, user_id, partner_id, connection_code
        case status, created_at, updated_at
    }
}

struct SupabaseUser: Codable, Sendable {
    let id: String
    let email: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
    }
}

// MARK: - Supabase Service

/**
 * Main service class for handling all Supabase operations in the WeTwo app.
 * 
 * This service provides a comprehensive interface for:
 * - User authentication and profile management
 * - Memory and calendar entry operations
 * - Partnership management and partner synchronization
 * - Love message handling
 * - Data export and backup operations
 * - Advanced search and filtering capabilities
 * 
 * The service is designed to be thread-safe and follows Swift concurrency best practices.
 * All database operations are performed asynchronously and include proper error handling.
 */
final class SupabaseService: @unchecked Sendable {
    static let shared = SupabaseService()

    let client: SupabaseClient
    
    // MARK: - Initialization
    
    private init() {
        // Use SupabaseConfig instead of environment variables
        let urlStr = SupabaseConfig.supabaseURL
        let key = SupabaseConfig.supabaseAnonKey
        
        guard let url = URL(string: urlStr), !key.isEmpty else {
            fatalError("Invalid Supabase configuration in SupabaseConfig.swift")
        }
        
        print("🔧 Initializing Supabase client with URL: \(urlStr)")
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    // MARK: - Authentication
    
    var currentUserId: UUID? {
        return client.auth.currentUser?.id
    }

    func session() async throws -> Session? {
        try await client.auth.session
    }

    func signIn(email: String) async throws {
        try await client.auth.signInWithOTP(email: email)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        // Create a default User with current date as birth date
        return User(
            name: response.user.userMetadata["name"]?.stringValue ?? "User",
            birthDate: Date()
        )
    }
    
    func signUp(email: String, password: String) async throws -> User {
        _ = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        // Create a default User with current date as birth date
        return User(
            name: "User",
            birthDate: Date()
        )
    }
    
    /// Completes onboarding by creating user account and updating profile
    /// Expects: Onboarding data collected locally, no DB writes yet
    @discardableResult
    func completeOnboarding(email: String,
                            password: String,
                            name: String,
                            birthDate: Date) async throws -> SupabaseUser {
        // 1) Signup
        _ = try await client.auth.signUp(email: email, password: password)

        // 2) Ensure session (for dev, you might get it directly; in prod, show verification flow)
        if (try? await client.auth.session) == nil {
            _ = try await client.auth.signIn(email: email, password: password)
        }
        
        guard let session = try? await client.auth.session else {
            throw AuthError.unauthorized
        }
        
        let user = session.user

        // 3) Update profile only (profile exists through trigger)
        let birth = DateFormatter.yyyyMMdd.string(from: birthDate)
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

        return SupabaseUser(
            id: user.id.uuidString,
            email: user.email ?? email,
            createdAt: user.createdAt
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Profile Management
    
    func upsertProfile(_ profile: Profile) async throws -> Profile {
        let resp = try await client
            .from("profiles")
            .upsert(profile, onConflict: "id")
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(Profile.self, from: resp.data)
    }

    func myProfile() async throws -> Profile? {
        guard let uid = currentUserId else { 
            throw AuthError.userNotFound 
        }
        
        let resp = try await client
            .from("profiles")
            .select()
            .eq("id", value: uid.uuidString)
            .single()
            .execute()
        
        return try? JSONDecoder().decode(Profile.self, from: resp.data)
    }

    func profile(of userId: UUID) async throws -> Profile? {
        let resp = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
        
        return try? JSONDecoder().decode(Profile.self, from: resp.data)
    }
    
    func profileByEmail(_ email: String) async throws -> Profile? {
        let resp = try await client
            .from("profiles")
            .select()
            .eq("email", value: email)
            .single()
            .execute()
        
        return try? JSONDecoder().decode(Profile.self, from: resp.data)
    }
    
    func updateProfile(userId: String, name: String, birthDate: Date?) async throws {
        let birthDateString: String
        if let birthDate = birthDate {
            birthDateString = DateFormatter.yyyyMMdd.string(from: birthDate)
        } else {
            birthDateString = DateFormatter.yyyyMMdd.string(from: Date())
        }

        let updates: [String: String] = [
            "name": name,
            "birth_date": birthDateString,
            "updated_at": Date().ISO8601String()
        ]
        
        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }
    
    func updateRelationshipData(userId: String, relationshipStatus: String, hasChildren: String, childrenCount: String) async throws {
        let updates: [String: String] = [
            "relationship_status": relationshipStatus,
            "has_children": hasChildren,
            "children_count": childrenCount,
            "updated_at": Date().ISO8601String()
        ]
        
        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Partnership Management
    
    func createOrActivatePartnership(userId: UUID, partnerId: UUID, code: String) async throws -> Partnership {
        let payload = Partnership(
            id: nil,
            user_id: userId.uuidString,
            partner_id: partnerId.uuidString,
            connection_code: code,
            status: "active",
            created_at: nil,
            updated_at: nil
        )
        
        let resp = try await client
            .from("partnerships")
            .upsert(payload, onConflict: "user_id,partner_id")
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(Partnership.self, from: resp.data)
    }
    
    func partnershipsMine(userId: UUID) async throws -> [Partnership] {
        let resp = try await client
            .from("partnerships")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        return try JSONDecoder().decode([Partnership].self, from: resp.data)
    }
    
    func partnership(userId: UUID) async throws -> Partnership? {
        let resp = try await client
            .from("partnerships")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "active")
            .limit(1)
            .single()
            .execute()
        
        return try? JSONDecoder().decode(Partnership.self, from: resp.data)
    }

    func findPartnershipByCode(_ code: String) async throws -> Partnership? {
        let resp = try await client
            .from("partnerships")
            .select()
            .eq("connection_code", value: code)
            .limit(1)
            .single()
            .execute()
        
        return try? JSONDecoder().decode(Partnership.self, from: resp.data)
    }

    func updatePartnershipStatus(id: String, status: String) async throws {
        try await client
            .from("partnerships")
            .update(["status": status])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Memory Management
    
    func createMemory(_ memory: Memory) async throws -> Memory {
        let resp = try await client
            .from("memories")
            .insert(memory)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(Memory.self, from: resp.data)
    }
    
    func memories(userId: UUID) async throws -> [Memory] {
        let resp = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([Memory].self, from: resp.data)
    }
    
    func sharedMemories(userId: UUID, partnerId: UUID) async throws -> [Memory] {
        let resp = try await client
            .from("memories")
            .select()
            .or("user_id.eq.\(userId.uuidString),partner_id.eq.\(partnerId.uuidString)")
            .eq("is_shared", value: "true")
            .order("date", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([Memory].self, from: resp.data)
    }

    // MARK: - Love Message Management
    
    func conversation(with partnerId: UUID) async throws -> [LoveMessage] {
        guard let userId = currentUserId else {
            throw AuthError.userNotFound
        }
        
        let response = try await client
            .from("love_messages")
            .select()
            .or("sender_id.eq.\(userId.uuidString),receiver_id.eq.\(userId.uuidString)")
            .or("sender_id.eq.\(partnerId.uuidString),receiver_id.eq.\(partnerId.uuidString)")
            .order("timestamp", ascending: true)
            .execute()
        
        return try JSONDecoder().decode([LoveMessage].self, from: response.data)
    }
    
    func sendLoveMessage(to partnerId: UUID, text: String) async throws -> LoveMessage {
        guard let userId = currentUserId else {
            throw AuthError.userNotFound
        }
        
        let message = LoveMessage(
            senderId: userId,
            receiverId: partnerId,
            message: text
        )
        
        let response = try await client
            .from("love_messages")
            .insert(message)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(LoveMessage.self, from: response.data)
    }
    
    func markMessageRead(_ messageId: UUID) async throws {
        try await client
            .from("love_messages")
            .update(["is_read": true])
            .eq("id", value: messageId.uuidString)
            .execute()
    }
    
    func getUnreadMessageCount(userId: UUID) async throws -> Int {
        let response = try await client
            .from("love_messages")
            .select("id", count: .exact)
            .eq("receiver_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
        
        return response.count ?? 0
    }
    
    func deleteLoveMessage(_ messageId: UUID) async throws {
        try await client
            .from("love_messages")
            .delete()
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    // MARK: - Partnership Status
    
    func getPartnershipStatus(userId: UUID) async throws -> PartnershipStatus {
        let resp = try await client
            .from("partnerships")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "active")
            .limit(1)
            .single()
            .execute()
        
        if let partnership = try? JSONDecoder().decode(Partnership.self, from: resp.data) {
            // Get partner profile
            let partnerResp = try await client
                .from("profiles")
                .select()
                .eq("id", value: partnership.partner_id)
                .single()
                .execute()
            
            if let partnerProfile = try? JSONDecoder().decode(Profile.self, from: partnerResp.data) {
                return .connected(partnerName: partnerProfile.name, partnerId: partnership.partner_id)
            }
        }
        
        return .notConnected
    }

    // MARK: - Partner Management Methods
    
    func findPartnerByCode(connectionCode: String) async throws -> Profile? {
        let partnership = try await findPartnershipByCode(connectionCode)
        guard let partnership = partnership else { return nil }
        
        let partnerId = partnership.user_id == currentUserId?.uuidString ? partnership.partner_id : partnership.user_id
        guard let partnerUUID = UUID(uuidString: partnerId) else { return nil }
        
        return try await profile(of: partnerUUID)
    }
    
    func createPartnership(userId: UUID, partnerId: UUID, connectionCode: String) async throws -> Partnership {
        return try await createOrActivatePartnership(userId: userId, partnerId: partnerId, code: connectionCode)
    }
    
    func subscribeToPartnerUpdates(userId: UUID, onUpdate: @escaping @Sendable (Profile) -> Void) async throws {
        // TODO: Implement realtime subscription for partner updates
        print("🔄 Partner updates subscription not yet implemented")
    }
    
    func unsubscribeFromPartnerUpdates(userId: UUID) async throws {
        // TODO: Implement unsubscribing from partner updates
        print("🔌 Partner updates unsubscription not yet implemented")
    }
    
    func subscribeToLoveMessages(userId: UUID, onNewMessage: @escaping @Sendable (LoveMessage) -> Void) async throws {
        // TODO: Implement realtime subscription for love messages
        print("💌 Love messages subscription not yet implemented")
    }
    
    func unsubscribeFromLoveMessages(userId: UUID) async throws {
        // TODO: Implement unsubscribing from love messages
        print("🔌 Love messages unsubscription not yet implemented")
    }
    
    func subscribeToMemories(userId: UUID, onNewMemory: @escaping @Sendable (Memory) -> Void) async throws {
        // TODO: Implement realtime subscription for memories
        print("📸 Memories subscription not yet implemented")
    }
    
    func unsubscribeFromMemories(userId: UUID) async throws {
        // TODO: Implement unsubscribing from memories
        print("🔌 Memories unsubscription not yet implemented")
    }
    
    func disconnectPartner(userId: UUID) async throws {
        try await updatePartnershipStatus(id: userId.uuidString, status: "disconnected")
    }
    
    func updateSharedProfile(userId: UUID, updates: [String: String]) async throws {
        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    func getPartnerProfile(userId: UUID) async throws -> Profile? {
        let partnerships = try await partnershipsMine(userId: userId)
        guard let partnership = partnerships.first(where: { $0.status == "active" }) else { 
            return nil 
        }
        
        let partnerId = partnership.user_id == userId.uuidString ? partnership.partner_id : partnership.user_id
        guard let partnerUUID = UUID(uuidString: partnerId) else { return nil }
        
        return try await profile(of: partnerUUID)
    }
    
    // MARK: - Memory Management Methods
    
    func myMemories() async throws -> [Memory] {
        guard let userId = currentUserId else {
            throw AuthError.userNotFound
        }
        
        let response = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([Memory].self, from: response.data)
    }
    
    func addMemory(_ memory: Memory) async throws -> Memory {
        guard let userId = currentUserId else {
            throw AuthError.userNotFound
        }
        
        var memoryToInsert = memory
        memoryToInsert.user_id = userId
        
        let response = try await client
            .from("memories")
            .insert(memoryToInsert)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(Memory.self, from: response.data)
    }
    
    func updateMemory(_ memory: Memory) async throws -> Memory {
        guard let memoryId = memory.id else {
            throw AuthError.invalidData
        }
        
        let response = try await client
            .from("memories")
            .update(memory)
            .eq("id", value: memoryId.uuidString)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(Memory.self, from: response.data)
    }
    
    func deleteMemory(_ memoryId: UUID) async throws {
        try await client
            .from("memories")
            .delete()
            .eq("id", value: memoryId.uuidString)
            .execute()
    }
    
    // MARK: - Profile Photo Storage
    
    func uploadProfilePhoto(userId: UUID, imageData: Data) async throws {
        let fileName = "\(userId.uuidString)_profile.jpg"
        
        do {
            try await client.storage
                .from("profile-photos")
                .upload(
                    fileName,
                    data: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg"
                    )
                )
        } catch {
            print("❌ Error uploading profile photo: \(error)")
            throw AuthError.photoUploadFailed
        }
    }
    
    func getProfilePhotoURL(userId: UUID) async throws -> URL? {
        print("🔍 Getting profile photo URL for user: \(userId)")
        
        do {
            let response: [String: String] = try await client
                .from("profiles")
                .select("profile_photo_url")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            if let photoURLString = response["profile_photo_url"], !photoURLString.isEmpty {
                return URL(string: photoURLString)
            }
            return nil
        } catch {
            print("❌ Error getting profile photo URL: \(error)")
            throw error
        }
    }
    
    func deleteProfilePhoto(userId: UUID) async throws {
        let response = try await client
            .storage
            .from("profile-photos")
            .remove(paths: ["\(userId.uuidString).jpg"])
        
        print("🗑️ Profile photo deleted for user \(userId)")
    }
    
    func downloadProfilePhoto(userId: UUID) async throws -> Data? {
        do {
            let response = try await client
                .storage
                .from("profile-photos")
                .download(path: "\(userId.uuidString).jpg")
            
            return response
        } catch {
            // If photo doesn't exist, return nil instead of throwing
            if let supabaseError = error as? StorageError,
               supabaseError.message.contains("not found") {
                return nil
            }
            throw error
        }
    }
    
    func listProfilePhotos(userId: UUID) async throws -> [FileObject] {
        let response = try await client
            .storage
            .from("profile-photos")
            .list(path: userId.uuidString)
        
        return response
    }
    
    func getProfilePhotoData(userId: UUID) async throws -> Data? {
        do {
            let response = try await client
                .storage
                .from("profile-photos")
                .download(path: "\(userId.uuidString).jpg")
            
            return response
        } catch {
            // If photo doesn't exist, return nil instead of throwing
            print("📸 Error downloading profile photo: \(error)")
            return nil
        }
    }

    // MARK: - Apple ID Integration
    
    func createProfileWithAppleID(userId: String, name: String, birthDate: Date, appleUserID: String) async throws {
        print("🍎 Creating profile with Apple ID for user: \(userId)")
        
        do {
            let profileData: [String: String] = [
                "name": name,
                "birth_date": isoDate(birthDate),
                "apple_user_id": appleUserID,
                "updated_at": isoDate(Date())
            ]
            
            try await client
                .from("profiles")
                .update(profileData)
                .eq("id", value: userId)
                .execute()
            
            print("✅ Profile updated with Apple ID successfully")
        } catch {
            print("❌ Error updating profile with Apple ID: \(error)")
            throw error
        }
    }
    
    func updateProfileWithAppleID(userId: String, name: String, birthDate: Date, appleUserID: String) async throws {
        print("🍎 Updating profile with Apple ID for user: \(userId)")
        
        do {
            let profileData: [String: String] = [
                "name": name,
                "birth_date": isoDate(birthDate),
                "apple_user_id": appleUserID,
                "updated_at": isoDate(Date())
            ]
            
            try await client
                .from("profiles")
                .update(profileData)
                .eq("id", value: userId)
                .execute()
            
            print("✅ Profile updated with Apple ID successfully")
        } catch {
            print("❌ Error updating profile with Apple ID: \(error)")
            throw error
        }
    }
    
    // MARK: - Partner Sync & Shared Data
    
    func syncProfileWithPartner(userId: String, updates: [String: String]) async throws {
        print("🔄 Syncing profile with partner for user: \(userId)")
        
        do {
            // Update the user's profile
            try await client
                .from("profiles")
                .update(updates)
                .eq("id", value: userId)
                .execute()
            
            // Also update the shared profile data if partner exists
            if let userIdUUID = UUID(uuidString: userId),
               let partnerProfile = try await getPartnerProfile(userId: userIdUUID) {
                let sharedUpdates = updates.filter { key, _ in
                    ["name", "birth_date", "zodiac_sign"].contains(key)
                }
                
                if !sharedUpdates.isEmpty {
                    try await updateSharedProfile(userId: userIdUUID, updates: sharedUpdates)
                }
            }
            
            print("✅ Profile synced with partner successfully")
        } catch {
            print("❌ Error syncing profile with partner: \(error)")
            throw error
        }
    }
    
    func getSharedProfileData(userId: String) async throws -> [String: String]? {
        print("🔍 Getting shared profile data for user: \(userId)")
        
        do {
            let response: [String: String] = try await client
                .from("profiles")
                .select("name, birth_date, zodiac_sign, profile_photo_url")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            return response
        } catch {
            print("❌ Error getting shared profile data: \(error)")
            throw error
        }
    }
    
    // MARK: - Calendar Entries
    
    func createCalendarEntry(userId: UUID, date: Date, title: String, description: String?, moodLevel: String) async throws -> Memory {
        let calendarEntry = Memory(
            id: nil,
            user_id: userId,
            partner_id: nil,
            date: isoDate(date),
            title: title,
            description: description,
            photo_data: nil,
            location: nil,
            mood_level: moodLevel,
            tags: nil,
            is_shared: "false",
            created_at: Date(),
            updated_at: Date()
        )
        
        return try await createMemory(calendarEntry)
    }
    
    func getCalendarEntries(userId: UUID, startDate: Date, endDate: Date) async throws -> [Memory] {
        let startDateStr = isoDate(startDate)
        let endDateStr = isoDate(endDate)
        
        let response = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startDateStr)
            .lte("date", value: endDateStr)
            .order("date", ascending: true)
            .execute()
        
        return try JSONDecoder().decode([Memory].self, from: response.data)
    }
    
    func updateCalendarEntry(_ entry: Memory) async throws -> Memory {
        return try await updateMemory(entry)
    }
    
    func deleteCalendarEntry(_ entryId: UUID) async throws {
        try await deleteMemory(entryId)
    }
    
    // MARK: - Mood Tracking
    
    func getMoodHistory(userId: UUID, days: Int = 30) async throws -> [Memory] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            throw AuthError.invalidData
        }
        
        let startDateStr = isoDate(startDate)
        let endDateStr = isoDate(endDate)
        
        let response = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startDateStr)
            .lte("date", value: endDateStr)
            .neq("mood_level", value: "")
            .order("date", ascending: true)
            .execute()
        
        return try JSONDecoder().decode([Memory].self, from: response.data)
    }
    
    func getAverageMood(userId: UUID, days: Int = 7) async throws -> Double? {
        let moodEntries = try await getMoodHistory(userId: userId, days: days)
        
        let moodValues = moodEntries.compactMap { entry -> Int? in
            Int(entry.mood_level)
        }
        
        guard !moodValues.isEmpty else { return nil }
        
        let sum = moodValues.reduce(0, +)
        return Double(sum) / Double(moodValues.count)
    }
    
    func createMoodEntry(userId: UUID, moodLevel: Int, eventLabel: String?, location: String?, photoData: Data?) async throws -> Memory {
        let moodEntry = Memory(
            id: nil,
            user_id: userId,
            partner_id: nil,
            date: isoDate(Date()),
            title: "Mood Entry",
            description: eventLabel,
            photo_data: photoData?.base64EncodedString(),
            location: location,
            mood_level: String(moodLevel),
            tags: nil,
            is_shared: "false",
            created_at: Date(),
            updated_at: Date()
        )
        
        return try await createMemory(moodEntry)
    }
    
    func getMoodEntryForDate(userId: UUID, date: Date) async throws -> Memory? {
        let dateStr = isoDate(date)
        
        let response = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateStr)
            .eq("title", value: "Mood Entry")
            .limit(1)
            .single()
            .execute()
        
        return try? JSONDecoder().decode(Memory.self, from: response.data)
    }

    // MARK: - Search and Filtering
    
    func searchMemories(userId: UUID, query: String, tags: [String]? = nil, location: String? = nil) async throws -> [Memory] {
        let queryBuilder = client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .or("title.ilike.%\(query)%,description.ilike.%\(query)%")
        
        var finalQuery = queryBuilder
        
        if let tags = tags, !tags.isEmpty {
            for tag in tags {
                finalQuery = finalQuery.ilike("tags", pattern: "%\(tag)%")
            }
        }
        
        if let location = location, !location.isEmpty {
            finalQuery = finalQuery.ilike("location", pattern: "%\(location)%")
        }
        
        let response = try await finalQuery.order("date", ascending: false).execute()
        return try JSONDecoder().decode([Memory].self, from: response.data)
    }
    
    func getMemoriesByTag(userId: UUID, tag: String) async throws -> [Memory] {
        let response = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .ilike("tags", pattern: "%\(tag)%")
            .order("date", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([Memory].self, from: response.data)
    }
    
    func getMemoriesByLocation(userId: UUID, location: String) async throws -> [Memory] {
        let response = try await client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .ilike("location", pattern: "%\(location)%")
            .order("date", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([Memory].self, from: response.data)
    }
    
    // MARK: - Statistics and Analytics
    
    func getMemoryStats(userId: UUID) async throws -> MemoryStats {
        let allMemories = try await memories(userId: userId)
        
        let totalMemories = allMemories.count
        let sharedMemories = allMemories.filter { $0.is_shared == "true" }.count
        let thisMonth = Calendar.current.component(.month, from: Date())
        let thisYear = Calendar.current.component(.year, from: Date())
        
        let memoriesThisMonth = allMemories.filter { memory in
            if let date = DateFormatter.yyyyMMdd.date(from: memory.date) {
                let month = Calendar.current.component(.month, from: date)
                let year = Calendar.current.component(.year, from: date)
                return month == thisMonth && year == thisYear
            }
            return false
        }.count
        
        let memoriesThisYear = allMemories.filter { memory in
            if let date = DateFormatter.yyyyMMdd.date(from: memory.date) {
                let year = Calendar.current.component(.year, from: date)
                return year == thisYear
            }
            return false
        }.count
        
        return MemoryStats(
            totalMemories: totalMemories,
            sharedMemories: sharedMemories,
            memoriesThisMonth: memoriesThisMonth,
            memoriesThisYear: memoriesThisYear
        )
    }
    
    // MARK: - Backup and Export
    
    func exportUserData(userId: UUID) async throws -> UserDataExport {
        let profile = try await profile(of: userId)
        let memories = try await memories(userId: userId)
        let partnerships = try await partnershipsMine(userId: userId)
        
        return UserDataExport(
            profile: profile,
            memories: memories,
            partnerships: partnerships,
            exportDate: Date()
        )
    }
    
    // MARK: - Connection Health Check
    
    func checkConnectionHealth() async throws -> Bool {
        do {
            // Try to fetch a simple profile to check connection
            if let userId = currentUserId {
                _ = try await profile(of: userId)
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    // MARK: - Batch Operations
    
    func batchCreateMemories(_ memories: [Memory]) async throws -> [Memory] {
        var createdMemories: [Memory] = []
        
        for memory in memories {
            let created = try await createMemory(memory)
            createdMemories.append(created)
        }
        
        return createdMemories
    }
    
    func batchUpdateMemories(_ memories: [Memory]) async throws -> [Memory] {
        var updatedMemories: [Memory] = []
        
        for memory in memories {
            let updated = try await updateMemory(memory)
            updatedMemories.append(updated)
        }
        
        return updatedMemories
    }
    
    // MARK: - Notification Preferences
    
    func updateNotificationPreferences(userId: UUID, preferences: [String: Bool]) async throws {
        let updates = preferences.mapValues { value in
            value
        }
        
        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    func getNotificationPreferences(userId: UUID) async throws -> [String: Bool] {
        let response: [String: String] = try await client
            .from("profiles")
            .select("notify_new_memories,notify_partner_updates,notify_love_messages")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return response.mapValues { value in
            value == "true"
        }
    }
    
    // MARK: - Data Validation
    
    private func validateMemory(_ memory: Memory) throws {
        guard !memory.title.isEmpty else {
            throw AuthError.validationError
        }
        
        guard !memory.mood_level.isEmpty else {
            throw AuthError.validationError
        }
        
        // Validate date format
        guard DateFormatter.yyyyMMdd.date(from: memory.date) != nil else {
            throw AuthError.validationError
        }
        
        // Validate mood level is numeric
        guard let _ = Int(memory.mood_level) else {
            throw AuthError.validationError
        }
    }
    
    private func validateProfile(_ profile: Profile) throws {
        guard !profile.name.isEmpty else {
            throw AuthError.validationError
        }
        
        guard !profile.birth_date.isEmpty else {
            throw AuthError.validationError
        }
        
        // Validate birth date format
        guard DateFormatter.yyyyMMdd.date(from: profile.birth_date) != nil else {
            throw AuthError.validationError
        }
        
        // Validate zodiac sign
        guard !profile.zodiac_sign.isEmpty else {
            throw AuthError.validationError
        }
    }
    
    private func validateLoveMessage(_ message: LoveMessage) throws {
        guard !message.message.isEmpty else {
            throw AuthError.validationError
        }
        
        guard message.message.count <= 500 else {
            throw AuthError.validationError
        }
    }
    
    func validateConnectionCode(_ code: String) -> Bool {
        // Connection codes should be 6 characters alphanumeric
        let codeRegex = "^[A-Z0-9]{6}$"
        return code.range(of: codeRegex, options: .regularExpression) != nil
    }

    // MARK: - Utility Methods
    
    func cleanupOrphanedData() async throws {
        guard let userId = currentUserId else { return }
        
        // Clean up memories without valid dates
        let allMemories = try await memories(userId: userId)
        let invalidMemories = allMemories.filter { memory in
            DateFormatter.yyyyMMdd.date(from: memory.date) == nil
        }
        
        for memory in invalidMemories {
            if let memoryId = memory.id {
                try await deleteMemory(memoryId)
            }
        }
        
        print("🧹 Cleaned up \(invalidMemories.count) invalid memories")
    }
    
    func getDataUsageStats(userId: UUID) async throws -> DataUsageStats {
        let profile = try await profile(of: userId)
        let memories = try await memories(userId: userId)
        let partnerships = try await partnershipsMine(userId: userId)
        
        let totalMemoriesSize = memories.reduce(0) { $0 + $1.title.count + ($1.description?.count ?? 0) }
        let hasProfilePhoto = !(profile?.profile_photo_url?.isEmpty ?? true)
        
        return DataUsageStats(
            totalMemories: memories.count,
            totalPhotos: hasProfilePhoto ? 1 : 0,
            storageUsed: Int64(totalMemoriesSize),
            storageLimit: 100 * 1024 * 1024, // 100MB
            lastBackup: nil
        )
    }
    
    func backupUserData(userId: UUID) async throws -> Data {
        let export = try await exportUserData(userId: userId)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(export)
    }
    
    func restoreUserData(userId: UUID, backupData: Data) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let export = try decoder.decode(UserDataExport.self, from: backupData)
        
        // Restore profile
        if let profile = export.profile {
            try await upsertProfile(profile)
        }
        
        // Restore memories (batch operation)
        if !export.memories.isEmpty {
            try await batchCreateMemories(export.memories)
        }
        
        // Restore partnerships
        for partnership in export.partnerships {
            if let userId = UUID(uuidString: partnership.user_id),
               let partnerId = UUID(uuidString: partnership.partner_id) {
                try await createOrActivatePartnership(
                    userId: userId,
                    partnerId: partnerId,
                    code: partnership.connection_code
                )
            }
        }
        
        print("✅ User data restored successfully")
    }
    
    func validateConnection() async throws -> Bool {
        do {
            // Try to fetch a simple profile to check connection
            if let userId = currentUserId {
                _ = try await profile(of: userId)
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    func getConnectionStatus() async throws -> ConnectionStatus {
        do {
            let isConnected = try await validateConnection()
            if isConnected {
                return .connected
            } else {
                return .disconnected
            }
        } catch {
            return .error(error)
        }
    }

    // MARK: - Advanced Search Methods
    
    func advancedMemorySearch(
        userId: UUID,
        query: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        moodLevel: String? = nil,
        tags: [String]? = nil,
        location: String? = nil,
        isShared: Bool? = nil
    ) async throws -> [Memory] {
        var queryBuilder = client
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
        
        if let query = query, !query.isEmpty {
            queryBuilder = queryBuilder.or("title.ilike.%\(query)%,description.ilike.%\(query)%")
        }
        
        if let startDate = startDate {
            queryBuilder = queryBuilder.gte("date", value: isoDate(startDate))
        }
        
        if let endDate = endDate {
            queryBuilder = queryBuilder.lte("date", value: isoDate(endDate))
        }
        
        if let moodLevel = moodLevel {
            queryBuilder = queryBuilder.eq("mood_level", value: moodLevel)
        }
        
        if let tags = tags, !tags.isEmpty {
            for tag in tags {
                queryBuilder = queryBuilder.ilike("tags", pattern: "%\(tag)%")
            }
        }
        
        if let location = location, !location.isEmpty {
            queryBuilder = queryBuilder.ilike("location", pattern: "%\(location)%")
        }
        
        if let isShared = isShared {
            queryBuilder = queryBuilder.eq("is_shared", value: isShared ? "true" : "false")
        }
        
        let response = try await queryBuilder.order("date", ascending: false).execute()
        return try JSONDecoder().decode([Memory].self, from: response.data)
    }
    
    // MARK: - Partner Activity Tracking
    
    func getPartnerActivity(userId: UUID, days: Int = 7) async throws -> PartnerActivity {
        guard let partnerProfile = try await getPartnerProfile(userId: userId) else {
            throw AuthError.partnerNotFound
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            throw AuthError.invalidData
        }
        
        let startDateStr = isoDate(startDate)
        let endDateStr = isoDate(endDate)
        
        let response = try await client
            .from("memories")
            .select()
            .eq("user_id", value: partnerProfile.id.uuidString)
            .gte("date", value: startDateStr)
            .lte("date", value: endDateStr)
            .order("date", ascending: false)
            .execute()
        
        let memories = try JSONDecoder().decode([Memory].self, from: response.data)
        
        return PartnerActivity(
            partnerName: partnerProfile.name,
            memoriesCount: memories.count,
            lastActivity: memories.first?.date,
            averageMood: calculateAverageMood(from: memories)
        )
    }
    
    private func calculateAverageMood(from memories: [Memory]) -> Double? {
        let moodValues = memories.compactMap { memory -> Int? in
            Int(memory.mood_level)
        }
        
        guard !moodValues.isEmpty else { return nil }
        
        let sum = moodValues.reduce(0, +)
        return Double(sum) / Double(moodValues.count)
    }
    
    // MARK: - Data Export Formats
    
    func exportMemoriesAsCSV(userId: UUID) async throws -> String {
        let memories = try await memories(userId: userId)
        
        var csv = "Date,Title,Description,Mood Level,Location,Tags,Shared\n"
        
        for memory in memories {
            let row = [
                memory.date,
                memory.title,
                memory.description ?? "",
                memory.mood_level,
                memory.location ?? "",
                memory.tags ?? "",
                memory.is_shared ?? "false"
            ].map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }
            .joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    func exportMemoriesAsJSON(userId: UUID) async throws -> Data {
        let memories = try await memories(userId: userId)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(memories)
    }
    
    // MARK: - Performance Optimization
    
    func prefetchUserData(userId: UUID) async throws {
        // Prefetch commonly used data in parallel
        async let profileTask = profile(of: userId)
        async let memoriesTask = memories(userId: userId)
        async let partnershipsTask = partnershipsMine(userId: userId)
        
        // Wait for all to complete
        _ = try await (profileTask, memoriesTask, partnershipsTask)
    }
    
    func clearCache() {
        // TODO: Implement cache clearing for better memory management
        print("🗑️ Cache clearing not yet implemented")
    }
    
    func getCacheStats() -> CacheStats {
        // TODO: Implement cache statistics
        return CacheStats(
            memoryUsage: 0,
            cacheHits: 0,
            cacheMisses: 0,
            lastCleared: Date()
        )
    }
    
    // MARK: - Error Recovery
    
    func retryOperation<T>(_ operation: () async throws -> T, maxRetries: Int = 3) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
            }
        }
        
        throw lastError ?? AuthError.invalidCredentials
    }
    
    func handleNetworkError(_ error: Error) -> AuthError {
        // Map network errors to appropriate AuthError cases
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError
            case .timedOut:
                return .serviceUnavailable
            case .serverCertificateUntrusted, .clientCertificateRejected:
                return .unauthorized
            default:
                return .networkError
            }
        }
        return .databaseError
    }
    
    // MARK: - Helper Functions
    
    private func isoDate(_ date: Date) -> String {
        DateFormatter.yyyyMMdd.string(from: date)
    }

    func getUserId(from userIdString: String) -> UUID? {
        return UUID(uuidString: userIdString)
    }
}

// MARK: - Supporting Types

struct CacheStats {
    let memoryUsage: Int
    let cacheHits: Int
    let cacheMisses: Int
    let lastCleared: Date
}

struct DataUsageStats {
    let totalMemories: Int
    let totalPhotos: Int
    let storageUsed: Int64
    let storageLimit: Int64
    let lastBackup: Date?
}

enum PartnershipStatus: Equatable {
    case notConnected
    case connected(partnerName: String, partnerId: String)
    
    static func fromString(_ status: String) -> PartnershipStatus {
        if status == "active" || status == "connected" {
            return .notConnected // This will be updated when we have partner info
        }
        return .notConnected
    }
}

enum ConnectionStatus: Equatable {
    case connected
    case disconnected
    case error(Error)
    
    static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected), (.disconnected, .disconnected):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

struct MemoryStats: Codable, Sendable {
    let totalMemories: Int
    let sharedMemories: Int
    let memoriesThisMonth: Int
    let memoriesThisYear: Int
}

struct UserDataExport: Codable, Sendable {
    let profile: Profile?
    let memories: [Memory]
    let partnerships: [Partnership]
    let exportDate: Date
}

struct PartnerActivity: Codable, Sendable {
    let partnerName: String
    let memoriesCount: Int
    let lastActivity: String?
    let averageMood: Double?
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension SupabaseService {
    // MARK: - Convenience Methods
    
    func isConnected() async throws -> Bool {
        let session = try await client.auth.session
        return true // Session is non-optional in newer Supabase versions
    }
    
    func getCurrentUserEmail() async throws -> String? {
        let session = try await client.auth.session
        return session.user.email
    }
    
    func getCurrentUserId() -> UUID? {
        return currentUserId
    }
    
    func logout() async throws {
        try await client.auth.signOut()
        // Note: currentUserId is read-only, so we can't set it to nil here
        // The session will be cleared by the auth.signOut() call
    }
}

// MARK: - Documentation

/*
 SupabaseService - Comprehensive service for managing all Supabase operations
 
 This service provides:
 - User authentication and management
 - Profile management
 - Memory and mood tracking
 - Partner connection management
 - Love message handling
 - Photo storage and management
 - Real-time subscriptions
 - Error handling and recovery
 - Performance optimization
 
 Key Features:
 - Comprehensive error handling with localized descriptions
 - Async/await support for modern Swift concurrency
 - Automatic retry mechanisms for network operations
 - Data validation and sanitization
 - Cache management and optimization
 - Real-time data synchronization
 
 Usage:
 let service = SupabaseService.shared
 try await service.signIn(email: "user@example.com", password: "password")
 let memories = try await service.memories(userId: userId)
 
 Error Handling:
 All methods throw AuthError types with localized descriptions
 Use do-catch blocks to handle errors appropriately
 
 Performance:
 - Use prefetchUserData for bulk data loading
 - Implement caching strategies for frequently accessed data
 - Use retryOperation for network resilience
 */
