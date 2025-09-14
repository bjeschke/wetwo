//
//  OptimizedModels.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 10.09.25.
//

import Foundation
import SwiftUI

// MARK: - Memory Filter
enum MemoryFilter: String, CaseIterable {
    case all = "all"
    case special = "special"
    case everyday = "everyday"
    
    var displayName: String {
        switch self {
        case .all:
            return "Alle"
        case .special:
            return "Besondere"
        case .everyday:
            return "Alltägliche"
        }
    }
}

// MARK: - Extended Memory Model
extension Memory {
    var isSpecial: Bool {
        // Check if memory is marked as special based on mood level or tags
        if let moodLevelInt = Int(mood_level), moodLevelInt >= 4 {
            return true
        }
        if let tags = tags, tags.contains("special") {
            return true
        }
        return false
    }
    
    // Initialize with simplified parameters for testing
    init(userId: String, partnerId: String, title: String, description: String, photoData: Data? = nil, location: String? = nil, isSpecial: Bool = false, eventLabel: String? = nil) {
        self.id = nil
        self.user_id = Int(userId) ?? 0
        self.partner_id = Int(partnerId) ?? 0
        self.date = DateFormatter.yyyyMMdd.string(from: Date())
        self.title = title
        self.description = description
        self.photo_data = photoData?.base64EncodedString()
        self.location = location
        self.mood_level = isSpecial ? "5" : "3"
        self.tags = isSpecial ? "special" : nil
        self.is_shared = "true"
        self.created_at = Date()
        self.updated_at = Date()
    }
}

// MARK: - Partner Profile
struct PartnerProfile: Codable {
    let id: String
    let name: String
    let email: String?
    let profileImageUrl: String?
    let zodiacSign: ZodiacSign?
    let birthDate: Date?
    let connectionDate: Date?
    let lastActiveDate: Date?
    
    init(from profile: Profile) {
        self.id = String(profile.id)
        self.name = profile.name
        self.email = nil // Not exposed from Profile
        self.profileImageUrl = profile.profile_photo_url
        self.zodiacSign = ZodiacSign(rawValue: profile.zodiac_sign) ?? .unknown
        self.birthDate = DateFormatter.yyyyMMdd.date(from: profile.birth_date)
        self.connectionDate = profile.created_at
        self.lastActiveDate = profile.updated_at
    }
}

// MARK: - Invitation
struct Invitation: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let code: String
    let status: InvitationStatus
    let createdAt: Date
    let expiresAt: Date?
}

enum InvitationStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
}

