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
                try await supabaseService.createMemory(memory)
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
                try await supabaseService.updateMemory(memory)
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
                try await supabaseService.deleteMemory(memory.id.uuidString)
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
        do {
            if let user = await supabaseService.getCurrentUser() {
                currentUserId = user.id
            }
        } catch {
            print("Error loading current user: \(error)")
        }
    }
    
    @MainActor
    private func loadMemories() async {
        guard let userId = currentUserId else { return }
        
        isLoading = true
        do {
            let loadedMemories = try await supabaseService.getMemories(userId: userId)
            // Filter out any invalid memories
            memories = loadedMemories.filter { memory in
                // Ensure memory has valid data
                !memory.title.isEmpty &&
                memory.moodLevel.rawValue >= 1 && memory.moodLevel.rawValue <= 5 &&
                (memory.photoData == nil || !memory.photoData!.isEmpty)
            }
            updateTimeline()
        } catch {
            print("Error loading memories: \(error)")
            memories = []
            updateTimeline()
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