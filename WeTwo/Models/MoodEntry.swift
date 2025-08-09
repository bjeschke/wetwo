//
//  MoodEntry.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

struct MoodEntry: Codable, Identifiable {
    let id = UUID()
    let userId: UUID
    let date: Date
    let moodLevel: MoodLevel
    let eventLabel: String?
    let location: String?
    let photoData: Data?
    let insight: String?
    let loveMessage: String?
    
    init(userId: UUID, moodLevel: MoodLevel, eventLabel: String? = nil, location: String? = nil, photoData: Data? = nil) {
        self.userId = userId
        self.date = Date()
        self.moodLevel = moodLevel
        self.eventLabel = eventLabel
        self.location = location
        self.photoData = photoData
        self.insight = nil
        self.loveMessage = nil
    }
}

enum MoodLevel: Int, CaseIterable, Codable {
    case veryHappy = 5
    case happy = 4
    case neutral = 3
    case sad = 2
    case verySad = 1
    
    var emoji: String {
        switch self {
        case .veryHappy: return "😍"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .verySad: return "😩"
        }
    }
    
    var description: String {
        switch self {
        case .veryHappy: return "Ecstatic"
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .verySad: return "Very Sad"
        }
    }
    
    var color: Color {
        switch self {
        case .veryHappy: return Color.pink
        case .happy: return Color.orange
        case .neutral: return Color.yellow
        case .sad: return Color.blue
        case .verySad: return Color.purple
        }
    }
}

struct DailyInsight: Codable {
    let insight: String
    let loveMessage: String?
    let astrologicalInfluence: String?
    let compatibilityScore: Int?
}

struct WeeklyMoodSummary: Codable {
    let weekStartDate: Date
    let averageMood: Double
    let moodTrend: MoodTrend
    let mostFrequentMood: MoodLevel
    let insights: [String]
}

enum MoodTrend: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    
    var emoji: String {
        switch self {
        case .improving: return "📈"
        case .declining: return "📉"
        case .stable: return "➡️"
        }
    }
} 