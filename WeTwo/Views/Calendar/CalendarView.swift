//
//  CalendarView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var partnerManager: PartnerManager
    @EnvironmentObject var appState: AppState
    @StateObject private var calendarManager = CalendarManager.shared
    
    @State private var relationshipData: [String: Any] = [:]
    @State private var isLoadingRelationshipData = true
    
    @State private var selectedWeek: Date = Date()

    @State private var showingAddEntry = false
    @State private var showingWeekSummary = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Meeting date card
                    meetingDateCard
                    
                    // Week selector
                    weekSelector
                    
                    // Mood calendar grid
                    moodCalendarGrid
                    
                    // Calendar entries for selected week
                    calendarEntriesSection
                    
                    // Week summary button
                    weekSummaryButton
                    
                    // Add new entry button
                    addEntryButton
                    
                    // Partner's week (if connected)
                    if partnerManager.isConnected {
                        partnerWeekSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 120)
            }
            .purpleTheme()
            .navigationBarHidden(true)

            .sheet(isPresented: $showingAddEntry) {
                AddCalendarEntryView()
                    .environmentObject(calendarManager)
            }
            .sheet(isPresented: $showingWeekSummary) {
                WeekSummaryView(
                    weekSummary: calendarManager.generateWeeklyMoodSummary(
                        for: selectedWeek,
                        moodManager: moodManager
                    )
                )
            }
            .onAppear {
                loadRelationshipData()
            }
        }
    }
    
    private var weekSelector: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(ColorTheme.accentBlue)
            }
            
            Spacer()
            
            VStack(spacing: 5) {
                Text(weekTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text("\(NSLocalizedString("calendar_week", comment: "Week")) \(weekOfYear)")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(ColorTheme.accentBlue)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var meetingDateCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("💕")
                    .font(.title2)
                
                Text(NSLocalizedString("calendar_meeting_date", comment: "Meeting date"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                // Meeting date display
                HStack {
                    Text(NSLocalizedString("calendar_meeting_date_label", comment: "We met on"))
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Spacer()
                    
                    Text(getMeetingDateFormatted())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                }
                
                // Relationship duration
                HStack {
                    Text(NSLocalizedString("calendar_relationship_duration", comment: "Together for"))
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Spacer()
                    
                    Text(getRelationshipDuration())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                }
                
                // Relationship status
                HStack {
                    Text(NSLocalizedString("calendar_relationship_status", comment: "Status"))
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Spacer()
                    
                    Text(getRelationshipStatusDisplay())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                }
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    private var moodCalendarGrid: some View {
        VStack(spacing: 20) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Mood dots for current user
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 8) {
                        Text(dateFormatter.string(from: date))
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        if let mood = getMoodForDate(date) {
                            Text(mood.emoji)
                                .font(.title2)
                                .scaleEffect(1.2)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: mood)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Partner's mood dots (if connected)
            if partnerManager.isConnected {
                HStack(spacing: 0) {
                    ForEach(weekDates, id: \.self) { date in
                        VStack(spacing: 8) {
                            if let partnerMood = getPartnerMoodForDate(date) {
                                Text(partnerMood.emoji)
                                    .font(.title2)
                                    .scaleEffect(1.2)
                                    .opacity(0.7)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 30, height: 30)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    private var calendarEntriesSection: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("📅")
                    .font(.title2)
                
                Text(NSLocalizedString("calendar_entries", comment: "Calendar Entries"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(calendarManager.getEntriesForWeek(selectedWeek).count)")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ColorTheme.accentPink.opacity(0.2))
                    )
            }
            
            // Calendar entries list
            let weekEntries = calendarManager.getEntriesForWeek(selectedWeek)
            
            if weekEntries.isEmpty {
                VStack(spacing: 10) {
                    Text("📝")
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text(NSLocalizedString("calendar_no_entries", comment: "No calendar entries this week"))
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(weekEntries.sorted { $0.date < $1.date }) { entry in
                        CalendarEntryRow(entry: entry)
                    }
                }
            }
        }
        .padding(25)
        .purpleCard()
    }

    
    private var partnerWeekSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("👥")
                    .font(.title2)
                
                Text(NSLocalizedString("calendar_partner_week", comment: "Partner week"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            // Partner's mood summary
            VStack(spacing: 10) {
                let partnerMoods = getPartnerMoodsForWeek()
                let averagePartnerMood = partnerMoods.isEmpty ? 3.0 : Double(partnerMoods.map { $0.rawValue }.reduce(0, +)) / Double(partnerMoods.count)
                
                HStack {
                    Text("\(NSLocalizedString("calendar_average", comment: "Average")):")
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Spacer()
                    
                    Text(averagePartnerMood.isFinite ? String(format: "%.1f", averagePartnerMood) : "3.0")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                }
                
                HStack {
                    Text("\(NSLocalizedString("calendar_days_shared", comment: "Days Shared")):")
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Spacer()
                    
                    Text("\(partnerMoods.count)/7")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                }
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    // MARK: - Helper Methods
    
    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedWeek)?.start ?? selectedWeek
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? selectedWeek
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    private var weekOfYear: Int {
        calendar.component(.weekOfYear, from: selectedWeek)
    }
    
    private var weekDays: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return (0..<7).map { day in
            let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) ?? Date()
            return formatter.string(from: date)
        }
    }
    
    private var weekDates: [Date] {
        (0..<7).map { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek) ?? Date()
        }
    }
    
    private var startOfWeek: Date {
        calendar.dateInterval(of: .weekOfYear, for: selectedWeek)?.start ?? selectedWeek
    }
    
    private func getMoodForDate(_ date: Date) -> MoodLevel? {
        return moodManager.weeklyMoods.first { mood in
            calendar.isDate(mood.date, inSameDayAs: date)
        }?.moodLevel
    }
    
    private func getPartnerMoodForDate(_ date: Date) -> MoodLevel? {
        return partnerManager.getPartnerMood(for: date)?.moodLevel
    }
    
    private func getPartnerMoodsForWeek() -> [MoodLevel] {
        return weekDates.compactMap { date in
            partnerManager.getPartnerMood(for: date)?.moodLevel
        }
    }
    
    private func previousWeek() {
        selectedWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeek) ?? selectedWeek
    }
    
    private func nextWeek() {
        selectedWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeek) ?? selectedWeek
    }
    
    // MARK: - Relationship Data Methods
    
    private func getMeetingDateFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        
        if let meetingDateString = relationshipData["meeting_date"] as? String,
           let meetingDate = ISO8601DateFormatter().date(from: meetingDateString) {
            return formatter.string(from: meetingDate)
        }
        
        // Fallback to simulated date
        let meetingDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return formatter.string(from: meetingDate)
    }
    
    private func getRelationshipDuration() -> String {
        if let meetingDateString = relationshipData["meeting_date"] as? String,
           let meetingDate = ISO8601DateFormatter().date(from: meetingDateString) {
            let duration = calendar.dateComponents([.year, .month], from: meetingDate, to: Date())
            
            if let years = duration.year, let months = duration.month {
                if years > 0 {
                    return "\(years) \(years == 1 ? NSLocalizedString("year", comment: "year") : NSLocalizedString("years", comment: "years")), \(months) \(months == 1 ? NSLocalizedString("month", comment: "month") : NSLocalizedString("months", comment: "months"))"
                } else {
                    return "\(months) \(months == 1 ? NSLocalizedString("month", comment: "month") : NSLocalizedString("months", comment: "months"))"
                }
            }
        }
        
        // Fallback to simulated date
        let meetingDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let duration = calendar.dateComponents([.year, .month], from: meetingDate, to: Date())
        
        if let years = duration.year, let months = duration.month {
            if years > 0 {
                return "\(years) \(years == 1 ? NSLocalizedString("year", comment: "year") : NSLocalizedString("years", comment: "years")), \(months) \(months == 1 ? NSLocalizedString("month", comment: "month") : NSLocalizedString("months", comment: "months"))"
            } else {
                return "\(months) \(months == 1 ? NSLocalizedString("month", comment: "month") : NSLocalizedString("months", comment: "months"))"
            }
        }
        
        return NSLocalizedString("calendar_unknown_duration", comment: "Unknown duration")
    }
    
    private func getRelationshipStatusDisplay() -> String {
        if let status = relationshipData["relationship_status"] as? String {
            return NSLocalizedString("relationship_status_\(status)", comment: status)
        }
        
        return NSLocalizedString("relationship_status_dating", comment: "Dating")
    }
    
    private func loadRelationshipData() {
        Task {
            do {
                // For now, we'll simulate loading data
                // In a real app, this would load from Supabase or UserDefaults
                let simulatedData: [String: Any] = [
                    "meeting_date": ISO8601DateFormatter().string(from: calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()),
                    "relationship_status": "dating",
                    "has_children": false,
                    "children_count": 0
                ]
                
                await MainActor.run {
                    relationshipData = simulatedData
                    isLoadingRelationshipData = false
                }
            } catch {
                print("Error loading relationship data: \(error)")
                await MainActor.run {
                    isLoadingRelationshipData = false
                }
            }
        }
    }
    
    private var weekSummaryButton: some View {
        Button(action: {
            showingWeekSummary = true
        }) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(ColorTheme.accentBlue)
                
                Text(NSLocalizedString("calendar_week_summary", comment: "Week Summary"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .purpleCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var addEntryButton: some View {
        Button(action: {
            showingAddEntry = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(ColorTheme.accentPink)
                
                Text(NSLocalizedString("calendar_add_entry", comment: "Add Calendar Entry"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .purpleCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CalendarView()
        .environmentObject(MoodManager())
        .environmentObject(PartnerManager.shared)
} 