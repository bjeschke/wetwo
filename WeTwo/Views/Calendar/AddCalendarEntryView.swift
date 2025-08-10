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
            VStack(spacing: 0) {
                // Header with navigation
                headerWithNavigation
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Title input
                        titleSection
                        
                        // Description input
                        descriptionSection
                        
                        // Date and time selection
                        dateTimeSection
                        
                        // All day toggle
                        allDaySection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .purpleTheme()
            .navigationBarHidden(true)
        }
    }
    
    private var headerWithNavigation: some View {
        HStack {
            Button("Abbrechen") {
                dismiss()
            }
            .foregroundColor(ColorTheme.accentBlue)
            .font(.body)
            
            Spacer()
            
            Text(NSLocalizedString("calendar_add_entry_title", comment: "Add Calendar Entry"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
            
            Button("Speichern") {
                saveEntry()
            }
            .fontWeight(.semibold)
            .foregroundColor(ColorTheme.accentBlue)
            .disabled(title.isEmpty || isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
        .background(ColorTheme.cardBackground)
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
    
    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            // Save button
            Button(action: saveEntry) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                    }
                    
                    Text(NSLocalizedString("save", comment: "Save"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(title.isEmpty || isSaving ? ColorTheme.secondaryText : ColorTheme.accentPink)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(title.isEmpty || isSaving)
            
            // Cancel button
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                    
                    Text(NSLocalizedString("cancel", comment: "Cancel"))
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ColorTheme.cardBackgroundSecondary)
                .foregroundColor(ColorTheme.primaryText)
                .cornerRadius(12)
            }
        }
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