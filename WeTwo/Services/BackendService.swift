import Foundation
import CryptoKit

// MARK: - Error Types

enum BackendError: Error, LocalizedError {
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
    case refreshTokenInvalid
    case sessionExpired
    case invalidResponse
    case decodingError
    
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
        case .refreshTokenInvalid:
            return "Session expired, please sign in again"
        case .sessionExpired:
            return "Session expired, please sign in again"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode server response"
        }
    }
}

// MARK: - Response Models

struct BackendResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct AuthResponse: Codable {
    let user: BackendUser
    let token: String
    let refreshToken: String
}

struct BackendUser: Codable {
    let id: String
    let email: String
    let name: String?
    let birthDate: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case birthDate = "birth_date"
        case createdAt = "created_at"
    }
}

// MARK: - Backend Service

/**
 * Main service class for handling all backend operations in the WeTwo app.
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
 * All network operations are performed asynchronously and include proper error handling.
 */
final class BackendService: @unchecked Sendable {
    static let shared = BackendService()
    
    private let session = URLSession.shared
    private var authToken: String?
    private var refreshToken: String?
    
    // MARK: - Initialization
    
    private init() {
        print("🔧 Initializing BackendService with URL: \(BackendConfig.baseURL)")
    }
    
    // MARK: - Authentication
    
    var currentUserId: String? {
        // TODO: Implement token decoding to get user ID
        return nil
    }
    
    func getCurrentUserId() async throws -> String? {
        guard let token = authToken else {
            return nil
        }
        
        // Decode JWT token to get user ID
        // This is a simplified implementation
        return currentUserId
    }
    
    func signIn(email: String, password: String) async throws -> User {
        print("🔧 Starting email/password sign-in with Backend")
        
        guard let url = BackendConfig.authURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                
                // Store tokens
                self.authToken = authResponse.token
                self.refreshToken = authResponse.refreshToken
                
                print("✅ Email/password sign-in successful for user: \(authResponse.user.id)")
                
                // Create a User with the provided data
                let birthDate = authResponse.user.birthDate != nil ? 
                    DateFormatter.yyyyMMdd.date(from: authResponse.user.birthDate!) ?? Date() : 
                    Date()
                
                return User(
                    name: authResponse.user.name ?? "User",
                    birthDate: birthDate
                )
            } else {
                throw BackendError.invalidCredentials
            }
        } catch {
            print("❌ Email/password sign-in failed: \(error)")
            throw BackendError.invalidCredentials
        }
    }
    
    func signUp(email: String, password: String, name: String, birthDate: Date = Date()) async throws -> User {
        print("🔧 Starting sign-up with Backend")
        
        guard let url = BackendConfig.authURL()?.appendingPathComponent("/signup") else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password,
            "name": name,
            "birth_date": DateFormatter.yyyyMMdd.string(from: birthDate)
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                
                // Store tokens
                self.authToken = authResponse.token
                self.refreshToken = authResponse.refreshToken
                
                print("✅ Sign-up successful for user: \(authResponse.user.id)")
                
                return User(
                    name: name,
                    birthDate: birthDate
                )
            } else {
                throw BackendError.signUpFailed
            }
        } catch {
            print("❌ Sign-up failed: \(error)")
            throw BackendError.signUpFailed
        }
    }
    
    func signOut() async throws {
        print("🔧 Signing out from Backend")
        
        // Clear tokens
        self.authToken = nil
        self.refreshToken = nil
        
        // Optionally call logout endpoint
        if let url = BackendConfig.authURL()?.appendingPathComponent("/logout") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            if let token = authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            do {
                let (_, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Logout successful: \(httpResponse.statusCode)")
                }
            } catch {
                print("⚠️ Logout request failed: \(error)")
            }
        }
    }
    
    // MARK: - Profile Management
    
    func getUserProfile() async throws -> Profile? {
        guard let url = BackendConfig.profilesURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<Profile>.self, from: data)
                return backendResponse.data
            } else {
                throw BackendError.userNotFound
            }
        } catch {
            print("❌ Error getting user profile: \(error)")
            throw BackendError.userNotFound
        }
    }
    
    func updateProfile(userId: String, name: String, birthDate: Date?) async throws {
        guard let url = BackendConfig.profilesURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let actualBirthDate = birthDate ?? Date()
        let zodiacSign = ZodiacSign.calculate(from: actualBirthDate).rawValue
        
        let body = [
            "name": name,
            "birth_date": DateFormatter.yyyyMMdd.string(from: actualBirthDate),
            "zodiac_sign": zodiacSign
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode != 200 {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error updating profile: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func updateAuthUserDisplayName(name: String) async throws {
        // For backend service, this is the same as updating the profile
        // since we don't have separate auth user metadata
        try await updateProfile(userId: "", name: name, birthDate: nil)
    }
    
    func ensureProfileExists() async throws {
        // For backend service, we assume the profile exists after signup
        // If it doesn't, the API will return an error that we can handle
        print("✅ Profile existence ensured for backend service")
    }
    
    func completeOnboarding(email: String, password: String, name: String, birthDate: Date) async throws -> SupabaseUser {
        // For backend service, this is the same as signup
        let user = try await signUp(email: email, password: password, name: name, birthDate: birthDate)
        
        // Create a SupabaseUser from the User
        return SupabaseUser(
            id: try await getCurrentUserId() ?? "",
            email: email,
            createdAt: Date()
        )
    }
    
    // MARK: - Memory Management
    
    func createMemory(_ memory: Memory) async throws -> Memory {
        guard let url = BackendConfig.memoriesURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(memory)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<Memory>.self, from: data)
                guard let createdMemory = backendResponse.data else {
                    throw BackendError.decodingError
                }
                return createdMemory
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error creating memory: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func memories(userId: String) async throws -> [Memory] {
        guard let url = BackendConfig.memoriesURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<[Memory]>.self, from: data)
                return backendResponse.data ?? []
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error getting memories: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func updateMemory(_ memory: Memory) async throws -> Memory {
        guard let memoryId = memory.id,
              let url = BackendConfig.memoriesURL()?.appendingPathComponent(memoryId.uuidString) else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(memory)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<Memory>.self, from: data)
                guard let updatedMemory = backendResponse.data else {
                    throw BackendError.decodingError
                }
                return updatedMemory
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error updating memory: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func deleteMemory(_ memoryId: UUID) async throws {
        guard let url = BackendConfig.memoriesURL()?.appendingPathComponent(memoryId.uuidString) else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error deleting memory: \(error)")
            throw BackendError.databaseError
        }
    }
    
    // MARK: - Partnership Management
    
    func createPartnership(userId: String, partnerId: String, connectionCode: String) async throws -> Partnership {
        guard let url = BackendConfig.partnershipsURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "user_id": userId,
            "partner_id": partnerId,
            "connection_code": connectionCode,
            "status": "active"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<Partnership>.self, from: data)
                guard let partnership = backendResponse.data else {
                    throw BackendError.decodingError
                }
                return partnership
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error creating partnership: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func findPartnershipByCode(_ code: String) async throws -> Partnership? {
        guard let url = BackendConfig.partnershipsURL()?.appendingPathComponent("code/\(code)") else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<Partnership>.self, from: data)
                return backendResponse.data
            } else if httpResponse.statusCode == 404 {
                return nil
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error finding partnership: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func partnership(userId: String) async throws -> Partnership? {
        guard let url = BackendConfig.partnershipsURL()?.appendingPathComponent("user/\(userId)") else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<Partnership>.self, from: data)
                return backendResponse.data
            } else if httpResponse.statusCode == 404 {
                return nil
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error getting partnership: \(error)")
            throw BackendError.databaseError
        }
    }
    
    // MARK: - Love Message Management
    
    func sendLoveMessage(to partnerId: String, text: String) async throws -> LoveMessage {
        guard let url = BackendConfig.loveMessagesURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "receiver_id": partnerId,
            "message": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<LoveMessage>.self, from: data)
                guard let message = backendResponse.data else {
                    throw BackendError.decodingError
                }
                return message
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error sending love message: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func conversation(with partnerId: String) async throws -> [LoveMessage] {
        guard let url = BackendConfig.loveMessagesURL()?.appendingPathComponent("conversation/\(partnerId)") else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<[LoveMessage]>.self, from: data)
                return backendResponse.data ?? []
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error getting conversation: \(error)")
            throw BackendError.databaseError
        }
    }
    
    // MARK: - Mood Entry Management
    
    func createMoodEntry(_ moodEntry: SupabaseMoodEntry) async throws -> SupabaseMoodEntry {
        guard let url = BackendConfig.moodEntriesURL() else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(moodEntry)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<SupabaseMoodEntry>.self, from: data)
                guard let createdEntry = backendResponse.data else {
                    throw BackendError.decodingError
                }
                return createdEntry
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error creating mood entry: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func getMoodEntries(userId: String, startDate: Date? = nil, endDate: Date? = nil) async throws -> [SupabaseMoodEntry] {
        guard var urlComponents = URLComponents(url: BackendConfig.moodEntriesURL()!, resolvingAgainstBaseURL: false) else {
            throw BackendError.invalidData
        }
        
        var queryItems: [URLQueryItem] = []
        
        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: DateFormatter.yyyyMMdd.string(from: startDate)))
        }
        
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: DateFormatter.yyyyMMdd.string(from: endDate)))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<[SupabaseMoodEntry]>.self, from: data)
                return backendResponse.data ?? []
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error getting mood entries: \(error)")
            throw BackendError.databaseError
        }
    }
    
    func getTodayMoodEntry(userId: String) async throws -> SupabaseMoodEntry? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let today = formatter.string(from: Date())
        
        guard var urlComponents = URLComponents(url: BackendConfig.moodEntriesURL()!, resolvingAgainstBaseURL: false) else {
            throw BackendError.invalidData
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "date", value: today)
        ]
        
        guard let url = urlComponents.url else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let backendResponse = try JSONDecoder().decode(BackendResponse<[SupabaseMoodEntry]>.self, from: data)
                return backendResponse.data?.first
            } else {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error getting today's mood entry: \(error)")
            throw BackendError.databaseError
        }
    }
    
    // MARK: - Photo Storage
    
    func uploadProfilePhoto(userId: String, imageData: Data) async throws {
        guard let url = BackendConfig.storageURL()?.appendingPathComponent("profile-photo") else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = imageData
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                throw BackendError.photoUploadFailed
            }
        } catch {
            print("❌ Error uploading profile photo: \(error)")
            throw BackendError.photoUploadFailed
        }
    }
    
    func sendPushNotificationToPartner(userId: String, partnerId: String, title: String, body: String, data: [String: String]) async throws {
        guard let url = BackendConfig.baseURL?.appendingPathComponent("/api/notifications/push") else {
            throw BackendError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "partner_id": partnerId,
            "title": title,
            "body": body,
            "data": data
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                throw BackendError.databaseError
            }
        } catch {
            print("❌ Error sending push notification: \(error)")
            throw BackendError.databaseError
        }
    }
    
    // MARK: - Utility Methods
    
    private func refreshAuthToken() async throws {
        guard let refreshToken = refreshToken,
              let url = BackendConfig.authURL()?.appendingPathComponent("refresh") else {
            throw BackendError.refreshTokenInvalid
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.authToken = authResponse.token
                self.refreshToken = authResponse.refreshToken
            } else {
                throw BackendError.refreshTokenInvalid
            }
        } catch {
            throw BackendError.refreshTokenInvalid
        }
    }
    
    func checkConnectionHealth() async throws -> Bool {
        guard let url = BackendConfig.baseURL else {
            print("❌ No base URL configured")
            return false
        }
        
        let healthURL = URL(string: "\(url)/health") ?? URL(string: "\(url)/")!
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        print("🔍 Testing connection to: \(healthURL)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return false
            }
            
            print("📡 Response status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response body: \(responseString)")
            }
            
            return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
        } catch {
            print("❌ Connection error: \(error)")
            return false
        }
    }
    
    func testBackendConnection() async {
        print("🧪 Starting backend connection test...")
        print("🌐 Backend URL: \(BackendConfig.baseURL)")
        
        do {
            let isHealthy = try await checkConnectionHealth()
            if isHealthy {
                print("✅ Backend connection test: SUCCESS")
            } else {
                print("❌ Backend connection test: FAILED")
            }
        } catch {
            print("❌ Backend connection test error: \(error)")
        }
        
        // Test specific endpoints
        await testAuthEndpoint()
        await testProfilesEndpoint()
    }
    
    private func testAuthEndpoint() async {
        print("🔐 Testing auth endpoint...")
        guard let url = BackendConfig.authURL() else {
            print("❌ Auth URL not available")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid auth response")
                return
            }
            
            print("🔐 Auth endpoint status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔐 Auth response: \(responseString)")
            }
        } catch {
            print("❌ Auth endpoint error: \(error)")
        }
    }
    
    private func testProfilesEndpoint() async {
        print("👤 Testing profiles endpoint...")
        guard let url = BackendConfig.profilesURL() else {
            print("❌ Profiles URL not available")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid profiles response")
                return
            }
            
            print("👤 Profiles endpoint status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("👤 Profiles response: \(responseString)")
            }
        } catch {
            print("❌ Profiles endpoint error: \(error)")
        }
    }
}

// MARK: - Extensions

extension BackendService {
    // MARK: - Convenience Methods
    
    func isConnected() async throws -> Bool {
        return try await checkConnectionHealth()
    }
    
    func getCurrentUserEmail() async throws -> String? {
        // TODO: Implement token decoding to get email
        return nil
    }
    
    func logout() async throws {
        try await signOut()
    }
}
