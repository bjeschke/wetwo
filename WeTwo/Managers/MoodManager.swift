//
//  MoodManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

class MoodManager: ObservableObject {
    @Published var todayMood: MoodEntry?
    @Published var weeklyMoods: [MoodEntry] = []
    @Published var partnerTodayMood: MoodEntry?
    @Published var partnerWeeklyMoods: [MoodEntry] = []
    @Published var dailyInsight: DailyInsight?
    @Published var isLoading: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadMoodData()
    }
    
    func addMoodEntry(_ mood: MoodLevel, eventLabel: String? = nil, location: String? = nil, photoData: Data? = nil) {
        guard let userId = getCurrentUserId() else { return }
        
        let entry = MoodEntry(userId: userId, moodLevel: mood, eventLabel: eventLabel, location: location, photoData: photoData)
        todayMood = entry
        
        // Add to weekly moods
        weeklyMoods.append(entry)
        
        // Save to UserDefaults
        saveMoodData()
        
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
        // This would come from AppState
        return UUID()
    }
    
    private func getCurrentUserName() -> String {
        // This would come from AppState
        return "Your partner"
    }
    
    private func saveMoodData() {
        if let encoded = try? JSONEncoder().encode(weeklyMoods) {
            userDefaults.set(encoded, forKey: "weeklyMoods")
        }
        if let encoded = try? JSONEncoder().encode(todayMood) {
            userDefaults.set(encoded, forKey: "todayMood")
        }
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