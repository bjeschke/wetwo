//
//  MoodManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

@MainActor
class MoodManager: ObservableObject {
    @Published var todayMood: MoodEntry?
    @Published var weeklyMoods: [MoodEntry] = []
    @Published var partnerTodayMood: MoodEntry?
    @Published var partnerWeeklyMoods: [MoodEntry] = []
    @Published var dailyInsight: DailyInsight?
    @Published var isLoading: Bool = false
    
    private let supabaseService = SupabaseService.shared
    private let partnerManager = PartnerManager.shared
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadMoodData()
        loadPartnerMoodData()
    }
    
    func addMoodEntry(_ mood: MoodLevel, eventLabel: String? = nil, location: String? = nil, photoData: Data? = nil) {
        guard let userId = getCurrentUserId() else { 
            print("❌ Cannot add mood entry: No current user ID found")
            return 
        }
        
        print("🔧 Adding mood entry for user: \(userId)")
        print("   Mood: \(mood.description) (\(mood.rawValue))")
        print("   Event: \(eventLabel ?? "none")")
        print("   Location: \(location ?? "none")")
        
        let entry = MoodEntry(userId: userId, moodLevel: mood, eventLabel: eventLabel, location: location, photoData: photoData)
        todayMood = entry
        
        // Add to weekly moods
        weeklyMoods.append(entry)
        
        // Save to Supabase
        Task {
            await saveMoodEntryToSupabase(entry)
        }
        
        // Generate insight if available
        generateDailyInsight(for: entry)
    }
    
    func generateDailyInsight(for entry: MoodEntry) {
        isLoading = true
        
        // Simulate GPT API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.dailyInsight = DailyInsight(
                insight: self.generateInsightText(for: entry),
                loveMessage: self.generateLoveMessage(),
                astrologicalInfluence: self.getAstrologicalInfluence(),
                compatibilityScore: self.calculateCompatibilityScore()
            )
            self.isLoading = false
        }
    }
    
    private func generateInsightText(for entry: MoodEntry) -> String {
        let moodDescriptions = [
            MoodLevel.veryHappy: "feels absolutely amazing today",
            MoodLevel.happy: "is in a good mood",
            MoodLevel.neutral: "feels calm and balanced",
            MoodLevel.sad: "could use some extra love",
            MoodLevel.verySad: "needs your support today"
        ]
        
        let baseText = moodDescriptions[entry.moodLevel] ?? "is feeling okay"
        
        if let event = entry.eventLabel {
            return "\(getCurrentUserName()) \(baseText) after \(event.lowercased())"
        } else {
            return "\(getCurrentUserName()) \(baseText)"
        }
    }
    
    private func generateLoveMessage() -> String {
        let messages = [
            "Sending you a virtual hug! 🤗",
            "You're doing amazing! 💫",
            "I'm here for you always 💕",
            "You make my world brighter ✨",
            "Sending love your way 💖"
        ]
        return messages.randomElement() ?? "Thinking of you! 💭"
    }
    
    private func getAstrologicalInfluence() -> String {
        let influences = [
            "The moon is in a loving phase tonight 🌙",
            "Venus is bringing extra romance today 💫",
            "Mercury retrograde might affect communication 📱",
            "Jupiter brings good fortune to relationships 🍀"
        ]
        return influences.randomElement() ?? "The stars are aligned for love ⭐"
    }
    
    private func calculateCompatibilityScore() -> Int {
        return Int.random(in: 75...95)
    }
    
    func getWeeklyMoodSummary() -> WeeklyMoodSummary {
        let averageMood = weeklyMoods.isEmpty ? 3.0 : Double(weeklyMoods.map { $0.moodLevel.rawValue }.reduce(0, +)) / Double(weeklyMoods.count)
        
        let moodTrend: MoodTrend
        if weeklyMoods.count >= 2 {
            let recentMoods = weeklyMoods.suffix(3).map { $0.moodLevel.rawValue }
            let olderMoods = weeklyMoods.prefix(3).map { $0.moodLevel.rawValue }
            
            let recentAvg = Double(recentMoods.reduce(0, +)) / Double(recentMoods.count)
            let olderAvg = Double(olderMoods.reduce(0, +)) / Double(olderMoods.count)
            
            if recentAvg > olderAvg + 0.5 {
                moodTrend = .improving
            } else if recentAvg < olderAvg - 0.5 {
                moodTrend = .declining
            } else {
                moodTrend = .stable
            }
        } else {
            moodTrend = .stable
        }
        
        let mostFrequentMood = weeklyMoods.isEmpty ? .neutral : weeklyMoods.map { $0.moodLevel }.mostFrequent() ?? .neutral
        
        return WeeklyMoodSummary(
            weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
            averageMood: averageMood,
            moodTrend: moodTrend,
            mostFrequentMood: mostFrequentMood,
            insights: ["You've been more positive this week!", "Great communication with your partner"]
        )
    }
    
    private func getCurrentUserId() -> UUID? {
        // Get from secure storage (should be set during login/signup)
        do {
            if let userIdString = try SecurityService.shared.secureLoadString(forKey: "currentUserId"),
               let userId = UUID(uuidString: userIdString) {
                return userId
            }
        } catch {
            print("⚠️ Error loading current user ID from secure storage: \(error)")
        }
        
        print("⚠️ No current user ID found in secure storage")
        return nil
    }
    
    private func getCurrentUserName() -> String {
        // This would come from AppState
        return "Your partner"
    }
    
    private func saveMoodEntryToSupabase(_ entry: MoodEntry) async {
        do {
            print("🔧 Saving mood entry to Supabase for user: \(entry.userId)")
            
            // Convert local MoodEntry to Supabase MoodEntry
            let supabaseEntry = SupabaseMoodEntry(
                user_id: entry.userId,
                date: entry.date.formatted(date: .numeric, time: .omitted),
                mood_level: entry.moodLevel.rawValue,
                event_label: entry.eventLabel,
                location: entry.location,
                photo_data: entry.photoData,
                insight: entry.insight,
                love_message: entry.loveMessage
            )
            
            // Check if entry already exists for today
            if let existingEntry = try await supabaseService.getTodayMoodEntry(userId: entry.userId) {
                print("🔄 Updating existing mood entry for today")
                // Update existing entry
                var updatedEntry = supabaseEntry
                updatedEntry.id = existingEntry.id
                _ = try await supabaseService.updateMoodEntry(updatedEntry)
                print("✅ Mood entry updated successfully")
            } else {
                print("🆕 Creating new mood entry for today")
                // Create new entry
                _ = try await supabaseService.createMoodEntry(supabaseEntry)
                print("✅ Mood entry created successfully")
            }
            
            // Send push notification to partner
            await notifyPartnerAboutMoodUpdate(entry)
        } catch {
            print("❌ Failed to save mood entry to Supabase: \(error)")
        }
    }
    
    private func notifyPartnerAboutMoodUpdate(_ entry: MoodEntry) async {
        guard let currentUserId = getCurrentUserId(),
              let partnerId = getPartnerId(for: currentUserId) else { return }
        
        do {
            let title = "💕 Neue Stimmung von deinem Partner"
            let body = "Dein Partner hat seine Stimmung auf \(entry.moodLevel.description) gesetzt"
            let data = [
                "type": "mood_update",
                "mood_level": String(entry.moodLevel.rawValue),
                "date": entry.date.formatted(date: .numeric, time: .omitted)
            ]
            
            try await supabaseService.sendPushNotificationToPartner(
                userId: currentUserId,
                partnerId: partnerId,
                title: title,
                body: body,
                data: data
            )
        } catch {
            print("Failed to send push notification to partner: \(error)")
        }
    }
    
    // MARK: - Partner Mood Management
    
    func loadPartnerMoodData() {
        Task {
            await loadPartnerTodayMood()
            await loadPartnerWeeklyMoods()
        }
    }
    
    private func loadPartnerTodayMood() async {
        guard let currentUserId = getCurrentUserId(),
              let partnerId = getPartnerId(for: currentUserId) else { return }
        
        do {
            if let partnerMoodEntry = try await supabaseService.getTodayMoodEntry(userId: partnerId) {
                await MainActor.run {
                    // Convert Supabase MoodEntry to local MoodEntry
                    let localEntry = MoodEntry(
                        userId: partnerMoodEntry.user_id,
                        moodLevel: MoodLevel(rawValue: partnerMoodEntry.mood_level) ?? .neutral,
                        eventLabel: partnerMoodEntry.event_label,
                        location: partnerMoodEntry.location,
                        photoData: partnerMoodEntry.photo_data
                    )
                    partnerTodayMood = localEntry
                }
            }
        } catch {
            print("Failed to load partner today mood: \(error)")
        }
    }
    
    private func loadPartnerWeeklyMoods() async {
        guard let currentUserId = getCurrentUserId(),
              let partnerId = getPartnerId(for: currentUserId) else { return }
        
        do {
            // Get partner moods for the last 7 days
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate) ?? endDate
            
            let partnerMoodEntries = try await supabaseService.getMoodEntries(
                userId: partnerId,
                startDate: startDate,
                endDate: endDate
            )
            
            await MainActor.run {
                // Convert Supabase MoodEntries to local MoodEntries
                partnerWeeklyMoods = partnerMoodEntries.compactMap { supabaseEntry in
                    guard let moodLevel = MoodLevel(rawValue: supabaseEntry.mood_level) else { return nil }
                    
                    return MoodEntry(
                        userId: supabaseEntry.user_id,
                        moodLevel: moodLevel,
                        eventLabel: supabaseEntry.event_label,
                        location: supabaseEntry.location,
                        photoData: supabaseEntry.photo_data
                    )
                }
            }
        } catch {
            print("Failed to load partner weekly moods: \(error)")
        }
    }
    
    private func getPartnerId(for userId: UUID) -> UUID? {
        // This should get the partner ID from the partnership
        // For now, we'll need to implement this based on the partnership system
        // TODO: Implement proper partner ID retrieval
        return nil
    }
    
    private func loadMoodData() {
        if let data = userDefaults.data(forKey: "weeklyMoods"),
           let moods = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            weeklyMoods = moods
        }
        
        // Load today's mood and check if it's from today
        if let data = userDefaults.data(forKey: "todayMood"),
           let mood = try? JSONDecoder().decode(MoodEntry.self, from: data) {
            // Only set todayMood if it's from today
            if Calendar.current.isDate(mood.date, inSameDayAs: Date()) {
                todayMood = mood
            } else {
                // Clear old mood data
                todayMood = nil
                userDefaults.removeObject(forKey: "todayMood")
            }
        }
    }
}

extension Array where Element == MoodLevel {
    func mostFrequent() -> MoodLevel? {
        let counts = self.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
} 