//
//  RemindersView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 23.08.25.
//

import SwiftUI
import UserNotifications

struct RemindersView: View {
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var calendarManager = CalendarManager.shared
    @EnvironmentObject var appState: AppState
    
    @State private var pendingReminders: [UNNotificationRequest] = []
    @State private var isLoading = true
    
    // Daily reminder settings
    @State private var isDailyReminderEnabled = false
    @State private var dailyReminderTime = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerSection
                    
                    // Daily mood reminder
                    dailyMoodReminderSection
                    
                    // Calendar reminders
                    calendarRemindersSection
                    
                    // Upcoming reminders
                    upcomingRemindersSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 120)
            }
            .purpleTheme()
            .navigationBarHidden(true)
            .onAppear {
                loadReminders()
                loadDailyReminderSettings()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.accentPink)
            
            Text("Erinnerungen")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Verwalte deine Benachrichtigungen und Erinnerungen")
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    private var dailyMoodReminderSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("🌅")
                    .font(.title2)
                
                Text("Tägliche Stimmungs-Erinnerung")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Toggle("", isOn: $isDailyReminderEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
                    .onChange(of: isDailyReminderEnabled) { oldValue, newValue in
                        handleDailyReminderToggle(newValue)
                    }
            }
            
            if isDailyReminderEnabled {
                VStack(spacing: 12) {
                    HStack {
                        Text("Zeit:")
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        Spacer()
                        
                        DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(CompactDatePickerStyle())
                            .onChange(of: dailyReminderTime) { oldValue, newValue in
                                scheduleDailyReminder()
                            }
                    }
                    
                    Text("Wir erinnern dich täglich daran, deine Stimmung zu teilen.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .purpleCard()
    }
    
    private var calendarRemindersSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("📅")
                    .font(.title2)
                
                Text("Kalender-Erinnerungen")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(calendarManager.getUpcomingEntries().count)")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ColorTheme.accentPink.opacity(0.2))
                    )
            }
            
            if calendarManager.getUpcomingEntries().isEmpty {
                VStack(spacing: 10) {
                    Text("📝")
                        .font(.system(size: 30))
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text("Keine anstehenden Termine")
                        .foregroundColor(ColorTheme.secondaryText)
                        .font(.body)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(calendarManager.getUpcomingEntries().prefix(3), id: \.id) { entry in
                        CalendarReminderRow(entry: entry)
                    }
                    
                    if calendarManager.getUpcomingEntries().count > 3 {
                        Text("Und \(calendarManager.getUpcomingEntries().count - 3) weitere...")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                            .padding(.top, 5)
                    }
                }
            }
        }
        .padding(20)
        .purpleCard()
    }
    
    private var upcomingRemindersSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("⏰")
                    .font(.title2)
                
                Text("Anstehende Erinnerungen")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(pendingReminders.count)")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ColorTheme.accentBlue.opacity(0.2))
                        )
                }
            }
            
            if isLoading {
                ProgressView("Lade Erinnerungen...")
                    .padding(.vertical, 20)
            } else if pendingReminders.isEmpty {
                VStack(spacing: 10) {
                    Text("🔕")
                        .font(.system(size: 30))
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text("Keine anstehenden Erinnerungen")
                        .foregroundColor(ColorTheme.secondaryText)
                        .font(.body)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(pendingReminders.prefix(5), id: \.identifier) { reminder in
                        PendingReminderRow(reminder: reminder)
                    }
                }
            }
        }
        .padding(20)
        .purpleCard()
    }
    
    // MARK: - Helper Methods
    
    private func loadReminders() {
        isLoading = true
        Task {
            let reminders = await notificationService.getAllPendingReminders()
            await MainActor.run {
                pendingReminders = reminders
                isLoading = false
            }
        }
    }
    
    private func loadDailyReminderSettings() {
        isDailyReminderEnabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        if let timeData = UserDefaults.standard.data(forKey: "dailyReminderTime"),
           let savedTime = try? JSONDecoder().decode(Date.self, from: timeData) {
            dailyReminderTime = savedTime
        } else {
            // Default time: 19:00
            let calendar = Calendar.current
            dailyReminderTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
    
    private func handleDailyReminderToggle(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "dailyReminderEnabled")
        
        if enabled {
            scheduleDailyReminder()
        } else {
            notificationService.removeDailyReminder()
        }
    }
    
    private func scheduleDailyReminder() {
        guard isDailyReminderEnabled else { return }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dailyReminderTime)
        let minute = calendar.component(.minute, from: dailyReminderTime)
        
        notificationService.scheduleDailyReminder(at: hour, minute: minute)
        
        // Save the time
        if let timeData = try? JSONEncoder().encode(dailyReminderTime) {
            UserDefaults.standard.set(timeData, forKey: "dailyReminderTime")
        }
    }
}

// MARK: - Supporting Views

struct CalendarReminderRow: View {
    let entry: CalendarEntry
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d - HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Text("📅")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(timeFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            if entry.isAllDay {
                Text("Ganztägig")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ColorTheme.accentPink)
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorTheme.cardBackgroundSecondary)
        )
    }
}

struct PendingReminderRow: View {
    let reminder: UNNotificationRequest
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d - HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Text("🔔")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.content.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primaryText)
                    .lineLimit(1)
                
                if !reminder.content.body.isEmpty {
                    Text(reminder.content.body)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .lineLimit(2)
                }
                
                if let trigger = reminder.trigger as? UNTimeIntervalNotificationTrigger {
                    let triggerDate = Date().addingTimeInterval(trigger.timeInterval)
                    Text(dateFormatter.string(from: triggerDate))
                        .font(.caption2)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorTheme.cardBackgroundSecondary)
        )
    }
}

#Preview {
    RemindersView()
        .environmentObject(NotificationService.shared)
        .environmentObject(AppState())
}