//
//  DatabaseModels.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

// MARK: - Database Models (Schema-exakt, snake_case via CodingKeys)

struct Profile: Codable, Sendable {
    let id: Int
    var name: String
    var zodiac_sign: String
    var birth_date: String           // YYYY-MM-DD (Postgres DATE)
    var profile_photo_url: String?
    var relationship_status: String?
    var has_children: String?
    var children_count: String?
    var push_token: String?          // For push notifications
    var created_at: Date?
    var updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case zodiac_sign = "zodiacSign"  // Map to camelCase for backend
        case birth_date = "birthDate"
        case profile_photo_url = "profilePhotoUrl"
        case relationship_status = "relationshipStatus"
        case has_children = "hasChildren"
        case children_count = "childrenCount"
        case push_token = "pushToken"
        case created_at = "createdAt"
        case updated_at = "updatedAt"
    }
}

struct DatabaseMoodEntry: Codable, Sendable {
    var id: Int?
    var user_id: Int
    var date: String                 // YYYY-MM-DD
    var mood_level: Int             // 1-5 (1=very sad, 5=very happy)
    var event_label: String?
    var location: String?
    var photo_data: Data?
    var insight: String?
    var love_message: String?
    var created_at: Date?
    var updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id = "userId"  // Map to camelCase for backend
        case date
        case mood_level = "moodLevel"
        case event_label = "eventLabel"
        case location
        case photo_data = "photoData"
        case insight
        case love_message = "loveMessage"
        case created_at = "createdAt"
        case updated_at = "updatedAt"
    }
}

struct Memory: Codable, Sendable, Identifiable {
    var id: Int?
    var user_id: Int
    var partner_id: Int?
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
        case id
        case user_id = "userId"  // Map to camelCase for backend
        case partner_id = "partnerId"
        case date, title, description
        case photo_data = "photoData"
        case location
        case mood_level = "moodLevel"
        case tags
        case is_shared = "isShared"
        case created_at = "createdAt"
        case updated_at = "updatedAt"
    }
}

struct Partnership: Codable, Sendable {
    var id: Int?
    var user_id: Int
    var partner_id: Int
    var connection_code: String
    var status: String?              // 'active' ...
    var created_at: Date?
    var updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id = "userId"  // Map to camelCase for backend
        case partner_id = "partnerId"
        case connection_code = "connectionCode"
        case status
        case created_at = "createdAt"
        case updated_at = "updatedAt"
    }
}

struct DatabaseUser: Codable, Sendable {
    let id: Int
    let email: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
    }
}

// MARK: - Mood Trend Enum

enum MoodTrend: String, Codable, CaseIterable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    var emoji: String {
        switch self {
        case .improving:
            return "📈"
        case .stable:
            return "➡️"
        case .declining:
            return "📉"
        }
    }
    
    var description: String {
        switch self {
        case .improving:
            return NSLocalizedString("mood_trend_improving", comment: "Improving")
        case .stable:
            return NSLocalizedString("mood_trend_stable", comment: "Stable")
        case .declining:
            return NSLocalizedString("mood_trend_declining", comment: "Declining")
        }
    }
}

// MARK: - Partnership Status Enum

enum PartnershipStatus: String, Codable, CaseIterable {
    case notConnected = "not_connected"
    case pending = "pending"
    case connected = "connected"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .notConnected:
            return "Nicht verbunden"
        case .pending:
            return "Ausstehend"
        case .connected:
            return "Verbunden"
        case .blocked:
            return "Blockiert"
        }
    }
    
    var emoji: String {
        switch self {
        case .notConnected:
            return "🔗"
        case .pending:
            return "⏳"
        case .connected:
            return "💕"
        case .blocked:
            return "🚫"
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

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
