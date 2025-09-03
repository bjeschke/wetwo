//
//  MemoryManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

class MemoryManager: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var selectedFilter: MemoryFilter = .all
    
    private let dataService = ServiceFactory.shared.getCurrentService()
    
    init() {
        // Initialize empty
    }
    
    func loadMemories() async {
        // Load memories from data service
        do {
            if let userId = try await dataService.getCurrentUserId() {
                let loadedMemories = try await dataService.memories(userId: userId)
                DispatchQueue.main.async {
                    self.memories = loadedMemories
                }
            }
        } catch {
            print("❌ Error loading memories: \(error)")
        }
    }
    
    func addMemory(_ memory: Memory) async {
        do {
            let createdMemory = try await dataService.createMemory(memory)
            DispatchQueue.main.async {
                self.memories.append(createdMemory)
            }
        } catch {
            print("❌ Error adding memory: \(error)")
        }
    }
    
    func updateMemory(_ memory: Memory) async {
        do {
            let updatedMemory = try await dataService.updateMemory(memory)
            DispatchQueue.main.async {
                if let index = self.memories.firstIndex(where: { $0.id == memory.id }) {
                    self.memories[index] = updatedMemory
                }
            }
        } catch {
            print("❌ Error updating memory: \(error)")
        }
    }
    
    func deleteMemory(_ memoryId: Int) async {
        do {
            try await dataService.deleteMemory(memoryId)
            DispatchQueue.main.async {
                self.memories.removeAll { $0.id == memoryId }
            }
        } catch {
            print("❌ Error deleting memory: \(error)")
        }
    }
    
    func getMemoryStats() -> (total: Int, thisMonth: Int, shared: Int, averageMood: Double) {
        let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())
        let thisMonthCount = memories.filter { memory in
            if let startOfMonth = thisMonth?.start,
               let endOfMonth = thisMonth?.end {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let memoryDate = formatter.date(from: memory.date) {
                    return memoryDate >= startOfMonth && memoryDate <= endOfMonth
                }
            }
            return false
        }.count
        
        let sharedCount = memories.filter { memory in
            return memory.is_shared == "true"
        }.count
        
        let averageMood = memories.isEmpty ? 0.0 : 
            memories.compactMap { memory in
                Double(memory.mood_level)
            }.reduce(0, +) / Double(memories.count)
        
        return (total: memories.count, thisMonth: thisMonthCount, shared: sharedCount, averageMood: averageMood)
    }
    
    func getFilteredMemories(filter: MemoryFilter) -> [Memory] {
        switch filter {
        case .all:
            return memories
        case .recent:
            let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return memories.filter { memory in
                if let memoryDate = formatter.date(from: memory.date) {
                    return memoryDate >= oneWeekAgo
                }
                return false
            }
        case .shared:
            return memories.filter { $0.is_shared == "true" }
        case .favorites:
            return memories.filter { memory in
                if let tags = memory.tags {
                    return tags.contains("favorite")
                }
                return false
            }
        }
    }
    
    // Filter enum for Timeline view
    enum MemoryFilter: String, CaseIterable {
        case all = "All"
        case recent = "Recent"
        case shared = "Shared"
        case favorites = "Favorites"
        
        var emoji: String {
            switch self {
            case .all: return "📋"
            case .recent: return "🕒"
            case .shared: return "👫"
            case .favorites: return "⭐"
            }
        }
        
        var localizedTitle: String {
            switch self {
            case .all: return "Alle"
            case .recent: return "Kürzlich"
            case .shared: return "Geteilt"
            case .favorites: return "Favoriten"
            }
        }
    }
}