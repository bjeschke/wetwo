//
//  MemoryManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

class MemoryManager: ObservableObject {
    @Published var memories: [MemoryEntry] = []
    @Published var timeline: MemoryTimeline
    @Published var isLoading: Bool = false
    @Published var selectedFilter: MemoryFilter = .all
    @Published var currentUserId: String?
    
    private let supabaseService = SupabaseService.shared
    
    enum MemoryFilter: String, CaseIterable {
        case all = "timeline_filter_all"
        case shared = "timeline_filter_shared"
        case personal = "timeline_filter_personal"
        case favorites = "timeline_filter_favorites"
        
        var emoji: String {
            switch self {
            case .all: return "📅"
            case .shared: return "💕"
            case .personal: return "👤"
            case .favorites: return "⭐"
            }
        }
        
        var localizedTitle: String {
            return NSLocalizedString(self.rawValue, comment: "Memory filter")
        }
    }
    
    init() {
        self.timeline = MemoryTimeline(memories: [])
        Task {
            await loadCurrentUser()
            await loadMemories()
        }
    }
    
    @MainActor
    func addMemory(_ memory: MemoryEntry) {
        Task {
            do {
                // Convert MemoryEntry to Memory
                let memoryData = Memory(
                    id: memory.id,
                    user_id: memory.userId,
                    partner_id: memory.partnerId,
                    date: memory.date.ISO8601String().prefix(10).description, // YYYY-MM-DD format
                    title: memory.title,
                    description: memory.description,
                    photo_data: memory.photoData?.base64EncodedString(),
                    location: memory.location,
                    mood_level: memory.moodLevel.rawValue.description,
                    tags: memory.tags.joined(separator: ","),
                    is_shared: memory.isShared ? "true" : "false",
                    created_at: memory.createdAt,
                    updated_at: memory.updatedAt
                )
                
                try await supabaseService.createMemory(memoryData)
                await loadMemories()
                
                // Sync with partner if shared
                if memory.isShared {
                    syncMemoryWithPartner(memory)
                }
            } catch {
                print("Error adding memory: \(error)")
            }
        }
    }
    
    @MainActor
    func updateMemory(_ memory: MemoryEntry) {
        Task {
            do {
                // Convert MemoryEntry to Memory
                let memoryData = Memory(
                    id: memory.id,
                    user_id: memory.userId,
                    partner_id: memory.partnerId,
                    date: memory.date.ISO8601String().prefix(10).description, // YYYY-MM-DD format
                    title: memory.title,
                    description: memory.description,
                    photo_data: memory.photoData?.base64EncodedString(),
                    location: memory.location,
                    mood_level: memory.moodLevel.rawValue.description,
                    tags: memory.tags.joined(separator: ","),
                    is_shared: memory.isShared ? "true" : "false",
                    created_at: memory.createdAt,
                    updated_at: memory.updatedAt
                )
                
                try await supabaseService.updateMemory(memoryData)
                await loadMemories()
            } catch {
                print("Error updating memory: \(error)")
            }
        }
    }
    
    @MainActor
    func deleteMemory(_ memory: MemoryEntry) {
        Task {
            do {
                try await supabaseService.deleteMemory(memory.id)
                await loadMemories()
            } catch {
                print("Error deleting memory: \(error)")
            }
        }
    }
    
    func getFilteredMemories() -> [MemoryEntry] {
        switch selectedFilter {
        case .all:
            return timeline.memories
        case .shared:
            return timeline.memories.filter { $0.isShared }
        case .personal:
            return timeline.memories.filter { !$0.isShared }
        case .favorites:
            return timeline.memories.filter { $0.tags.contains("favorite") }
        }
    }
    
    func getMemoriesForDate(_ date: Date) -> [MemoryEntry] {
        let calendar = Calendar.current
        return timeline.memories.filter { memory in
            calendar.isDate(memory.date, inSameDayAs: date)
        }
    }
    
    func getMemoriesForMonth(_ date: Date) -> [MemoryEntry] {
        return timeline.memoriesForMonth(date)
    }
    
    func getRecentMemories(limit: Int = 5) -> [MemoryEntry] {
        return Array(timeline.memories.prefix(limit))
    }
    
    func getMemoryStats() -> (total: Int, shared: Int, personal: Int, averageMood: Double) {
        let total = timeline.totalCount
        let shared = timeline.sharedCount
        let personal = total - shared
        let averageMood = timeline.averageMood
        
        return (total, shared, personal, averageMood)
    }
    
    @MainActor
    private func loadCurrentUser() async {
        if let userId = supabaseService.currentUserId {
            currentUserId = userId.uuidString
        }
    }
    
    @MainActor
    private func loadMemories() async {
        guard let userId = currentUserId,
              let userUUID = UUID(uuidString: userId) else { return }
        
        isLoading = true
        do {
            let loadedMemories = try await supabaseService.memories(userId: userUUID)
            
            // Convert Memory to MemoryEntry and filter out any invalid memories
            var convertedMemories: [MemoryEntry] = []
            
            for memory in loadedMemories {
                // Convert Memory to MemoryEntry
                let moodLevel = MoodLevel(rawValue: Int(memory.mood_level) ?? 3) ?? .neutral
                let tags = memory.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
                let isShared = memory.is_shared == "true"
                
                // Parse photo data
                var photoData: Data? = nil
                if let photoDataString = memory.photo_data {
                    photoData = Data(base64Encoded: photoDataString)
                }
                
                // Parse date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: memory.date) ?? Date()
                
                // Parse timestamps
                let createdAt = memory.created_at ?? Date()
                let updatedAt = memory.updated_at ?? Date()
                
                // Create MemoryEntry with available data
                let memoryEntry = MemoryEntry(
                    fromDatabase: memory.id,
                    userId: memory.user_id,
                    partnerId: memory.partner_id,
                    dateString: memory.date,
                    title: memory.title,
                    description: memory.description,
                    photoData: photoData,
                    location: memory.location,
                    moodLevel: moodLevel,
                    tags: tags,
                    isShared: isShared,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
                
                convertedMemories.append(memoryEntry)
            }
            
            self.memories = convertedMemories
        } catch {
            print("Error loading memories: \(error)")
        }
        
        isLoading = false
    }
    
    private func updateTimeline() {
        timeline = MemoryTimeline(memories: memories)
    }
    
    private func syncMemoryWithPartner(_ memory: MemoryEntry) {
        // In a real app, this would sync with the partner's device
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Synced memory with partner: \(memory.title)")
        }
    }
} 