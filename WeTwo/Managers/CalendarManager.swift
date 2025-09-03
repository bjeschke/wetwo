//
//  CalendarManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 23.08.25.
//

import Foundation
import SwiftUI

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var calendarEntries: [CalendarEntry] = []
    @Published var isLoading = false
    
    private let backendService = BackendService.shared
    
    private init() {
        loadCalendarEntries()
    }
    
    // MARK: - Calendar Entries Management
    
    func loadCalendarEntries() {
        isLoading = true
        
        Task {
            do {
                // Load entries from backend
                let entries = try await backendService.getCalendarEntries()
                await MainActor.run {
                    self.calendarEntries = entries
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to load calendar entries: \(error)")
                // Load from local storage as fallback
                await loadLocalCalendarEntries()
            }
        }
    }
    
    private func loadLocalCalendarEntries() {
        if let data = UserDefaults.standard.data(forKey: "calendarEntries"),
           let entries = try? JSONDecoder().decode([CalendarEntry].self, from: data) {
            calendarEntries = entries
        }
        isLoading = false
    }
    
    func addCalendarEntry(_ entry: CalendarEntry) {
        Task {
            do {
                // Save to backend
                try await backendService.createCalendarEntry(entry)
                
                await MainActor.run {
                    self.calendarEntries.append(entry)
                    self.saveToLocalStorage()
                }
                
                // Schedule reminder notification if needed
                scheduleReminderForEntry(entry)
                
            } catch {
                print("❌ Failed to save calendar entry: \(error)")
                // Save locally as fallback
                await MainActor.run {
                    self.calendarEntries.append(entry)
                    self.saveToLocalStorage()
                }
            }
        }
    }
    
    func updateCalendarEntry(_ entry: CalendarEntry) {
        Task {
            do {
                try await backendService.updateCalendarEntry(entry)
                
                await MainActor.run {
                    if let index = self.calendarEntries.firstIndex(where: { $0.id == entry.id }) {
                        self.calendarEntries[index] = entry
                        self.saveToLocalStorage()
                    }
                }
                
                // Update reminder notification
                scheduleReminderForEntry(entry)
                
            } catch {
                print("❌ Failed to update calendar entry: \(error)")
                // Update locally as fallback
                await MainActor.run {
                    if let index = self.calendarEntries.firstIndex(where: { $0.id == entry.id }) {
                        self.calendarEntries[index] = entry
                        self.saveToLocalStorage()
                    }
                }
            }
        }
    }
    
    func deleteCalendarEntry(_ entry: CalendarEntry) {
        Task {
            do {
                try await backendService.deleteCalendarEntry(String(entry.id))
                
                await MainActor.run {
                    self.calendarEntries.removeAll { $0.id == entry.id }
                    self.saveToLocalStorage()
                }
                
                // Remove reminder notification
                cancelReminderForEntry(entry)
                
            } catch {
                print("❌ Failed to delete calendar entry: \(error)")
                // Delete locally as fallback
                await MainActor.run {
                    self.calendarEntries.removeAll { $0.id == entry.id }
                    self.saveToLocalStorage()
                }
            }
        }
    }
    
    // MARK: - Calendar Data Access
    
    func getEntriesForDate(_ date: Date) -> [CalendarEntry] {
        let calendar = Calendar.current
        return calendarEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    func getEntriesForWeek(_ date: Date) -> [CalendarEntry] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        
        return calendarEntries.filter { entry in
            weekInterval.contains(entry.date)
        }
    }
    
    func getUpcomingEntries(limit: Int = 5) -> [CalendarEntry] {
        let now = Date()
        return calendarEntries
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Reminder Notifications
    
    private func scheduleReminderForEntry(_ entry: CalendarEntry) {
        // Schedule notification 1 hour before the event
        let reminderTime = entry.date.addingTimeInterval(-3600) // 1 hour before
        
        if reminderTime > Date() {
            let content = UNMutableNotificationContent()
            content.title = "📅 Erinnerung: \(entry.title)"
            content.body = entry.description.isEmpty ? "Dein Termin beginnt in einer Stunde" : entry.description
            content.sound = .default
            content.categoryIdentifier = "calendar_reminder"
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: reminderTime.timeIntervalSinceNow,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "calendar_\(entry.id)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule reminder for calendar entry: \(error)")
                } else {
                    print("✅ Reminder scheduled for: \(entry.title)")
                }
            }
        }
    }
    
    private func cancelReminderForEntry(_ entry: CalendarEntry) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["calendar_\(entry.id)"]
        )
    }
    
    // MARK: - Local Storage
    
    private func saveToLocalStorage() {
        if let data = try? JSONEncoder().encode(calendarEntries) {
            UserDefaults.standard.set(data, forKey: "calendarEntries")
        }
    }
    
    // MARK: - Statistics
    
    func getCalendarStats() -> CalendarStats {
        let now = Date()
        let calendar = Calendar.current
        
        let thisWeek = getEntriesForWeek(now).count
        
        let upcomingCount = calendarEntries.filter { $0.date >= now }.count
        
        let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let thisMonth = calendarEntries.filter { entry in
            entry.date >= thisMonthStart && entry.date <= now
        }.count
        
        return CalendarStats(
            totalEntries: calendarEntries.count,
            thisWeekEntries: thisWeek,
            thisMonthEntries: thisMonth,
            upcomingEntries: upcomingCount
        )
    }
    
    // MARK: - Weekly Mood Summary
    
    func generateWeeklyMoodSummary(for date: Date, moodManager: MoodManager) -> WeeklyMoodSummary {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return defaultWeeklyMoodSummary(for: date)
        }
        
        // Get mood entries for the week
        let weekMoods = moodManager.weeklyMoods.filter { mood in
            weekInterval.contains(mood.date)
        }
        
        let moodLevels = weekMoods.map { $0.moodLevel }
        
        // Calculate statistics
        let averageMood = moodLevels.isEmpty ? 3.0 : Double(moodLevels.map { $0.rawValue }.reduce(0, +)) / Double(moodLevels.count)
        
        let moodTrend = calculateMoodTrend(weekMoods)
        let mostFrequentMood = calculateMostFrequentMood(moodLevels)
        let insights = generateInsights(weekMoods, averageMood: averageMood, trend: moodTrend)
        
        return WeeklyMoodSummary(
            weekStartDate: weekInterval.start,
            averageMood: averageMood,
            moodTrend: moodTrend,
            mostFrequentMood: mostFrequentMood,
            insights: insights
        )
    }
    
    private func defaultWeeklyMoodSummary(for date: Date) -> WeeklyMoodSummary {
        return WeeklyMoodSummary(
            weekStartDate: date,
            averageMood: 3.0,
            moodTrend: .stable,
            mostFrequentMood: .neutral,
            insights: [NSLocalizedString("no_mood_data", comment: "No mood data available for this week")]
        )
    }
    
    private func calculateMoodTrend(_ moods: [MoodEntry]) -> MoodTrend {
        guard moods.count >= 3 else { return .stable }
        
        let sortedMoods = moods.sorted { $0.date < $1.date }
        let firstHalf = Array(sortedMoods.prefix(sortedMoods.count / 2))
        let secondHalf = Array(sortedMoods.suffix(sortedMoods.count / 2))
        
        let firstHalfAverage = firstHalf.isEmpty ? 3.0 : Double(firstHalf.map { $0.moodLevel.rawValue }.reduce(0, +)) / Double(firstHalf.count)
        let secondHalfAverage = secondHalf.isEmpty ? 3.0 : Double(secondHalf.map { $0.moodLevel.rawValue }.reduce(0, +)) / Double(secondHalf.count)
        
        let difference = secondHalfAverage - firstHalfAverage
        
        if difference > 0.5 {
            return .improving
        } else if difference < -0.5 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func calculateMostFrequentMood(_ moodLevels: [MoodLevel]) -> MoodLevel {
        guard !moodLevels.isEmpty else { return .neutral }
        
        let counts = Dictionary(grouping: moodLevels, by: { $0 }).mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key ?? .neutral
    }
    
    private func generateInsights(_ moods: [MoodEntry], averageMood: Double, trend: MoodTrend) -> [String] {
        var insights: [String] = []
        
        if moods.isEmpty {
            insights.append(NSLocalizedString("no_mood_entries", comment: "No mood entries recorded this week"))
            return insights
        }
        
        // Mood consistency insight
        let moodVariation = calculateMoodVariation(moods.map { $0.moodLevel })
        if moodVariation < 1.0 {
            insights.append(NSLocalizedString("consistent_mood", comment: "Your mood has been very consistent this week"))
        } else if moodVariation > 2.0 {
            insights.append(NSLocalizedString("variable_mood", comment: "Your mood has varied significantly this week"))
        }
        
        // Consecutive days insight
        let consecutivePositiveDays = calculateConsecutivePositiveDays(moods)
        if consecutivePositiveDays >= 3 {
            insights.append(NSLocalizedString("consecutive_positive", comment: "You've had \(consecutivePositiveDays) consecutive positive days!"))
        }
        
        // Weekend vs weekday comparison
        let weekendMoodAverage = getWeekendMoodAverage(moods)
        let weekdayMoodAverage = getWeekdayMoodAverage(moods)
        
        if weekendMoodAverage > weekdayMoodAverage + 0.5 {
            insights.append(NSLocalizedString("better_weekends", comment: "Your mood is significantly better on weekends"))
        } else if weekdayMoodAverage > weekendMoodAverage + 0.5 {
            insights.append(NSLocalizedString("better_weekdays", comment: "Your mood is better during weekdays"))
        }
        
        // Overall mood assessment
        if averageMood >= 4.5 {
            insights.append(NSLocalizedString("excellent_week", comment: "You've had an excellent week emotionally!"))
        } else if averageMood <= 2.5 {
            insights.append(NSLocalizedString("challenging_week", comment: "This week has been emotionally challenging"))
        }
        
        return insights
    }
    
    private func calculateMoodVariation(_ moodLevels: [MoodLevel]) -> Double {
        guard !moodLevels.isEmpty else { return 0.0 }
        
        let values = moodLevels.map { Double($0.rawValue) }
        let average = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - average, 2) }.reduce(0, +) / Double(values.count)
        
        return sqrt(variance)
    }
    
    private func calculateConsecutivePositiveDays(_ moods: [MoodEntry]) -> Int {
        let sortedMoods = moods.sorted { $0.date < $1.date }
        var consecutive = 0
        var maxConsecutive = 0
        
        for mood in sortedMoods {
            if mood.moodLevel.rawValue >= 4 {
                consecutive += 1
                maxConsecutive = max(maxConsecutive, consecutive)
            } else {
                consecutive = 0
            }
        }
        
        return maxConsecutive
    }
    
    private func getWeekendMoodAverage(_ moods: [MoodEntry]) -> Double {
        let weekendMoods = moods.filter { mood in
            let weekday = Calendar.current.component(.weekday, from: mood.date)
            return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
        }
        
        guard !weekendMoods.isEmpty else { return 0.0 }
        let sum = weekendMoods.map { Double($0.moodLevel.rawValue) }.reduce(0, +)
        return sum / Double(weekendMoods.count)
    }
    
    private func getWeekdayMoodAverage(_ moods: [MoodEntry]) -> Double {
        let weekdayMoods = moods.filter { mood in
            let weekday = Calendar.current.component(.weekday, from: mood.date)
            return weekday >= 2 && weekday <= 6 // Monday to Friday
        }
        
        guard !weekdayMoods.isEmpty else { return 0.0 }
        let sum = weekdayMoods.map { Double($0.moodLevel.rawValue) }.reduce(0, +)
        return sum / Double(weekdayMoods.count)
    }
}

// MARK: - Models

struct CalendarEntry: Codable, Identifiable, Equatable {
    let id: Int
    let userId: String  // Changed to String for Firebase UID
    let title: String
    let description: String
    let date: Date
    let isAllDay: Bool
    let createdAt: Date
    
    init(id: Int = 0, userId: String, title: String, description: String, date: Date, isAllDay: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.date = date
        self.isAllDay = isAllDay
        self.createdAt = createdAt
    }
}

struct CalendarStats {
    let totalEntries: Int
    let thisWeekEntries: Int
    let thisMonthEntries: Int
    let upcomingEntries: Int
}

// MARK: - UserNotifications Extension

extension UNUserNotificationCenter {
    func addCalendarReminderCategory() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ENTRY",
            title: "Anzeigen",
            options: [.foreground]
        )
        
        let postponeAction = UNNotificationAction(
            identifier: "POSTPONE_REMINDER",
            title: "Später erinnern",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "calendar_reminder",
            actions: [viewAction, postponeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        self.setNotificationCategories([category])
    }
}