//
//  AddCalendarEntryView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 07.08.25.
//

import SwiftUI

struct AddCalendarEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var isAllDay = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerSection
                    
                    // Title input
                    titleSection
                    
                    // Description input
                    descriptionSection
                    
                    // Date and time selection
                    dateTimeSection
                    
                    // All day toggle
                    allDaySection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 100)
            }
            .purpleTheme()
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.accentBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("save", comment: "Save")) {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.accentBlue)
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.accentPink)
            
            Text(NSLocalizedString("calendar_add_entry_title", comment: "Add Calendar Entry"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            Text(NSLocalizedString("calendar_add_entry_subtitle", comment: "Create a new calendar entry with date and time"))
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("calendar_entry_title_label", comment: "Title"))
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            TextField(NSLocalizedString("calendar_entry_title_placeholder", comment: "Enter title"), text: $title)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .padding()
                .background(ColorTheme.cardBackgroundSecondary)
                .cornerRadius(10)
                .foregroundColor(ColorTheme.primaryText)
        }
        .purpleCard()
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("calendar_entry_description_label", comment: "Description"))
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            TextField(NSLocalizedString("calendar_entry_description_placeholder", comment: "Enter description"), text: $description, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .lineLimit(3...6)
                .padding()
                .background(ColorTheme.cardBackgroundSecondary)
                .cornerRadius(10)
                .foregroundColor(ColorTheme.primaryText)
        }
        .purpleCard()
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("calendar_entry_datetime_label", comment: "Date & Time"))
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 15) {
                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("calendar_entry_date_label", comment: "Date"))
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    DatePicker(
                        NSLocalizedString("calendar_entry_date_placeholder", comment: "Select date"),
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(.white)
                }
                
                if !isAllDay {
                    // Time picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("calendar_entry_time_label", comment: "Time"))
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        DatePicker(
                            NSLocalizedString("calendar_entry_time_placeholder", comment: "Select time"),
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .colorScheme(.dark)
                        .accentColor(.white)
                    }
                }
            }
        }
        .purpleCard()
    }
    
    private var allDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("calendar_entry_allday_label", comment: "All Day"))
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Toggle("", isOn: $isAllDay)
                    .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
            }
            
            if isAllDay {
                Text(NSLocalizedString("calendar_entry_allday_description", comment: "This event will last the entire day"))
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .purpleCard()
    }
    
    private func saveEntry() {
        isSaving = true
        
        Task {
            // Combine date and time
            let calendar = Calendar.current
            let combinedDate = calendar.date(
                bySettingHour: calendar.component(.hour, from: selectedTime),
                minute: calendar.component(.minute, from: selectedTime),
                second: 0,
                of: selectedDate
            ) ?? selectedDate
            
            // Create calendar entry
            let entry = CalendarEntry(
                id: UUID().uuidString,
                userId: appState.currentUser?.id ?? UUID(),
                title: title,
                description: description,
                date: combinedDate,
                isAllDay: isAllDay,
                createdAt: Date()
            )
            
            // Save to Supabase (this would be implemented)
            print("✅ Calendar entry to save: \(entry)")
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

// MARK: - Calendar Entry Model

struct CalendarEntry: Codable, Identifiable {
    let id: String
    let userId: UUID
    let title: String
    let description: String
    let date: Date
    let isAllDay: Bool
    let createdAt: Date
}

#Preview {
    AddCalendarEntryView()
        .environmentObject(AppState())
} 