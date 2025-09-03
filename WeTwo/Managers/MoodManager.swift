//
//  MoodManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class MoodManager: ObservableObject {
    @Published var todayMood: MoodEntry?
    @Published var weeklyMoods: [MoodEntry] = []
    @Published var partnerTodayMood: MoodEntry?
    @Published var partnerWeeklyMoods: [MoodEntry] = []
    @Published var dailyInsight: DailyInsight?
    @Published var isLoading: Bool = false
    
    private let dataService = ServiceFactory.shared.getCurrentService()
    private let partnerManager = PartnerManager.shared
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadMoodData()
        loadPartnerMoodData()
    }
    
        func addMoodEntry(_ mood: MoodLevel, eventLabel: String? = nil, location: String? = nil, photoData: Data? = nil) async {
        print("🎯 MoodManager.addMoodEntry called")
        
        // Firebase token will be sent in headers, no need for user ID
        print("🔧 Adding mood entry")
        print("   Mood: \(mood.description) (\(mood.rawValue))")
        print("   Event: \(eventLabel ?? "none")")
        print("   Location: \(location ?? "none")")
        
        // Create entry without userId - backend will determine from token
        let entry = MoodEntry(userId: "", moodLevel: mood, eventLabel: eventLabel, location: location, photoData: photoData)
        todayMood = entry
        
        // Add to weekly moods
        weeklyMoods.append(entry)
        
        // Save to current service
        Task {
            await saveMoodEntryToCurrentService(entry)
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
            MoodLevel.veryHappy: "fühlt sich heute absolut großartig",
            MoodLevel.happy: "ist gut gelaunt",
            MoodLevel.neutral: "fühlt sich ruhig und ausgeglichen",
            MoodLevel.sad: "könnte etwas extra Liebe gebrauchen",
            MoodLevel.verySad: "braucht heute deine Unterstützung"
        ]
        
        let baseText = moodDescriptions[entry.moodLevel] ?? "fühlt sich okay"
        
        if let event = entry.eventLabel {
            return "\(getCurrentUserName()) \(baseText) nach \(event.lowercased())"
        } else {
            return "\(getCurrentUserName()) \(baseText)"
        }
    }
    
    private func generateLoveMessage() -> String {
        let messages = [
            "Sende dir eine virtuelle Umarmung! 🤗",
            "Du machst das großartig! 💫",
            "Ich bin immer für dich da 💕",
            "Du machst meine Welt heller ✨",
            "Sende dir Liebe 💖"
        ]
        return messages.randomElement() ?? "Denke an dich! 💭"
    }
    
    private func getAstrologicalInfluence() -> String {
        let influences = [
            "Der Mond ist heute Nacht in einer liebevollen Phase 🌙",
            "Venus bringt heute extra Romantik 💫",
            "Merkur rückläufig könnte die Kommunikation beeinflussen 📱",
            "Jupiter bringt Glück für Beziehungen 🍀"
        ]
        return influences.randomElement() ?? "Die Sterne stehen günstig für die Liebe ⭐"
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
            insights: ["Du warst diese Woche positiver!", "Großartige Kommunikation mit deinem Partner"]
        )
    }
    
    
    private func getCurrentUserName() -> String {
        // This would come from AppState
        return "Dein Partner"
    }
    
    private func saveMoodEntryToCurrentService(_ entry: MoodEntry) async {
        do {
            print("🔧 Saving mood entry to backend")
            
            // Get Firebase token
            guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
                print("❌ No Firebase token available")
                print("   Current user: \(Auth.auth().currentUser?.uid ?? "nil")")
                return
            }
            
            print("🔑 Got Firebase token: \(String(token.prefix(20)))...")
            
            // Create request with token in header
            let url = URL(string: "http://localhost:8080/api/mood-entries")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Create mood entry data (backend will determine user from token)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: entry.date)
            
            // Backend expects camelCase field names
            let moodData: [String: Any] = [
                "date": dateString,
                "moodLevel": entry.moodLevel.rawValue,  // camelCase
                "eventLabel": entry.eventLabel ?? NSNull(),  // camelCase
                "location": entry.location ?? NSNull()
            ]
            
            print("📤 Sending mood data: \(moodData)")
            
            request.httpBody = try JSONSerialization.data(withJSONObject: moodData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📨 Response status code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📨 Response body: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("✅ Mood entry saved successfully")
                } else {
                    print("❌ Failed to save mood entry: HTTP \(httpResponse.statusCode)")
                }
            } else {
                print("❌ Invalid HTTP response")
            }
            
            // Send push notification to partner
            await notifyPartnerAboutMoodUpdate(entry)
        } catch {
            print("❌ Failed to save mood entry to current service: \(error)")
        }
    }
    
    private func notifyPartnerAboutMoodUpdate(_ entry: MoodEntry) async {
        // Partner notification will be handled by backend when it receives the mood entry
        // Backend knows the partnership and can send notification to partner
        print("📱 Partner notification will be handled by backend")
    }
    
    // MARK: - Partner Mood Management
    
    func loadPartnerMoodData() {
        Task {
            await loadPartnerTodayMood()
            await loadPartnerWeeklyMoods()
        }
    }
    
    private func loadPartnerTodayMood() async {
        // Partner data will be fetched from backend with token authentication
        do {
            guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
                print("❌ No Firebase token available")
                return
            }
            
            let url = URL(string: "http://localhost:8080/api/partner/mood/today")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let moodData = try? JSONDecoder().decode(DatabaseMoodEntry.self, from: data) {
                
                await MainActor.run {
                    let localEntry = MoodEntry(
                        userId: String(moodData.user_id),
                        moodLevel: MoodLevel(rawValue: moodData.mood_level) ?? .neutral,
                        eventLabel: moodData.event_label,
                        location: moodData.location,
                        photoData: moodData.photo_data
                    )
                    partnerTodayMood = localEntry
                }
            }
        } catch {
            print("Failed to load partner today mood: \(error)")
        }
    }
    
    private func loadPartnerWeeklyMoods() async {
        do {
            guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
                print("❌ No Firebase token available")
                return
            }
            
            // Get partner moods for the last 7 days
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate) ?? endDate
            
            let url = URL(string: "http://localhost:8080/api/partner/mood/weekly")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Add date range as query parameters
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "startDate", value: startDate.formatted(date: .numeric, time: .omitted)),
                URLQueryItem(name: "endDate", value: endDate.formatted(date: .numeric, time: .omitted))
            ]
            request.url = components?.url
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let moodEntries = try? JSONDecoder().decode([DatabaseMoodEntry].self, from: data) {
                
                await MainActor.run {
                    partnerWeeklyMoods = moodEntries.compactMap { databaseEntry in
                        guard let moodLevel = MoodLevel(rawValue: databaseEntry.mood_level) else { return nil }
                        
                        return MoodEntry(
                            userId: String(databaseEntry.user_id),
                            moodLevel: moodLevel,
                            eventLabel: databaseEntry.event_label,
                            location: databaseEntry.location,
                            photoData: databaseEntry.photo_data
                        )
                    }
                }
            }
        } catch {
            print("Failed to load partner weekly moods: \(error)")
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