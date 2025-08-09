//
//  MemoryEntry.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

struct MemoryEntry: Codable, Identifiable {
    var id = UUID()
    let userId: UUID
    let partnerId: UUID?
    let date: Date
    let title: String
    let description: String?
    let photoData: Data?
    let location: String?
    let moodLevel: MoodLevel
    let tags: [String]
    let isShared: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: UUID, title: String, description: String? = nil, photoData: Data? = nil, location: String? = nil, moodLevel: MoodLevel = .happy, tags: [String] = [], partnerId: UUID? = nil) {
        self.userId = userId
        self.partnerId = partnerId
        self.date = Date()
        self.title = title
        self.description = description
        self.photoData = photoData
        self.location = location
        self.moodLevel = moodLevel
        self.tags = tags
        self.isShared = partnerId != nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Custom initializer for creating from database data
    init(fromDatabase id: UUID?, userId: UUID, partnerId: UUID?, dateString: String, title: String, description: String?, photoData: Data?, location: String?, moodLevel: MoodLevel, tags: [String], isShared: Bool, createdAt: Date?, updatedAt: Date?) {
        if let id = id {
            self.id = id
        }
        self.userId = userId
        self.partnerId = partnerId
        
        // Parse date from YYYY-MM-DD string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.date(from: dateString) ?? Date()
        
        self.title = title
        self.description = description
        self.photoData = photoData
        self.location = location
        self.moodLevel = moodLevel
        self.tags = tags
        self.isShared = isShared
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }
}

struct MemoryTimeline: Codable {
    let memories: [MemoryEntry]
    let totalCount: Int
    let sharedCount: Int
    let averageMood: Double
    
    init(memories: [MemoryEntry]) {
        self.memories = memories.sorted { $0.date > $1.date }
        self.totalCount = memories.count
        self.sharedCount = memories.filter { $0.isShared }.count
        
        // Calculate average mood with better error handling
        if memories.isEmpty {
            self.averageMood = 3.0
        } else {
            let moodValues = memories.compactMap { memory -> Double? in
                let rawValue = Double(memory.moodLevel.rawValue)
                return rawValue.isFinite ? rawValue : nil
            }
            
            if moodValues.isEmpty {
                self.averageMood = 3.0
            } else {
                let sum = moodValues.reduce(0.0, +)
                self.averageMood = sum.isFinite && !moodValues.isEmpty ? sum / Double(moodValues.count) : 3.0
            }
        }
    }
    
    func memoriesForMonth(_ date: Date) -> [MemoryEntry] {
        let calendar = Calendar.current
        return memories.filter { memory in
            calendar.isDate(memory.date, equalTo: date, toGranularity: .month)
        }
    }
    
    func memoriesForYear(_ date: Date) -> [MemoryEntry] {
        let calendar = Calendar.current
        return memories.filter { memory in
            calendar.isDate(memory.date, equalTo: date, toGranularity: .year)
        }
    }
} 