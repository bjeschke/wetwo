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
    @EnvironmentObject var calendarManager: CalendarManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var isAllDay = false
    @State private var isSaving = false
    @State private var shareWithPartner = true  // Share by default
    @State private var isMemory = false  // Option to create as memory
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header section
                    headerSection
                    
                    // Title input
                    titleSection
                    
                    // Description input
                    descriptionSection
                    
                    // Date and time selection
                    dateTimeSection
                    
                    // All day toggle
                    allDaySection
                    
                    // Sharing options
                    sharingSection
                    
                    // Action buttons
                    actionButtonsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .purpleTheme()
            .navigationTitle("Neuer Kalendereintrag")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.accentPink)
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("📅")
                .font(.system(size: 60))
            
            Text("Neuer Kalendereintrag")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Erstelle einen neuen Eintrag für deinen Kalender")
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Titel")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
                .padding(.horizontal, 5)
            
            TextField("Gib einen Titel ein...", text: $title)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .foregroundColor(ColorTheme.primaryText)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(ColorTheme.cardBackgroundSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(title.isEmpty ? Color.gray.opacity(0.3) : ColorTheme.accentPink, lineWidth: 1)
                )
        }
        .purpleCard()
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Beschreibung")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
                .padding(.horizontal, 5)
            
            TextField("Optionale Beschreibung...", text: $description, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .foregroundColor(ColorTheme.primaryText)
                .lineLimit(3...6)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(ColorTheme.cardBackgroundSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .purpleCard()
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Datum & Zeit")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
                .padding(.horizontal, 5)
            
            VStack(spacing: 20) {
                // Date picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Datum")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    DatePicker(
                        "Datum wählen",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .accentColor(ColorTheme.accentPink)
                }
                
                if !isAllDay {
                    // Time picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Uhrzeit")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        DatePicker(
                            "Zeit wählen",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .accentColor(ColorTheme.accentPink)
                    }
                }
            }
        }
        .purpleCard()
    }
    
    private var allDaySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Ganztägig")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    if isAllDay {
                        Text("Dieser Termin dauert den ganzen Tag")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isAllDay)
                    .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
            }
        }
        .purpleCard()
    }
    
    private var sharingSection: some View {
        VStack(spacing: 15) {
            // Share with partner
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("👥 Mit Partner teilen")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        if shareWithPartner {
                            Text("Dein Partner sieht diese Erinnerung")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $shareWithPartner)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
                }
            }
            .purpleCard()
            
            // Save as memory
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("💖 Als Erinnerung speichern")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        if isMemory {
                            Text("Wird in eurer gemeinsamen Timeline gespeichert")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isMemory)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
                }
            }
            .purpleCard()
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Save button
            Button(action: saveEntry) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }
                    
                    Text("Speichern")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(title.isEmpty || isSaving ? Color.gray.opacity(0.5) : ColorTheme.accentPink)
                )
                .foregroundColor(.white)
                .shadow(color: title.isEmpty || isSaving ? .clear : ColorTheme.accentPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(title.isEmpty || isSaving)
            
            // Cancel button
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 20))
                    
                    Text("Abbrechen")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(ColorTheme.cardBackgroundSecondary)
                )
                .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding(.top, 10)
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
                id: 0, // Will be generated by backend
                userId: appState.currentUser?.id ?? "",
                title: title,
                description: description,
                date: combinedDate,
                isAllDay: isAllDay,
                createdAt: Date()
            )
            
            // Save using CalendarManager
            await calendarManager.addCalendarEntry(entry)
            
            // If sharing with partner or saving as memory
            if shareWithPartner || isMemory {
                await saveAsSharedMemory(entry)
            }
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
    
    private func saveAsSharedMemory(_ entry: CalendarEntry) async {
        print("🔄 Saving as shared memory...")
        
        do {
            // Get partner ID from PartnerManager
            let partnerManager = PartnerManager.shared
            let partnerId = partnerManager.partnerProfile?.id
            
            // Create memory from calendar entry
            let memory = Memory(
                id: nil,
                user_id: Int(entry.userId) ?? 0,
                partner_id: partnerId,
                date: DateFormatter.yyyyMMdd.string(from: entry.date),
                title: entry.title,
                description: entry.description,
                photo_data: nil,
                location: nil,
                mood_level: "happy",
                tags: isMemory ? "memory,calendar" : "calendar",
                is_shared: shareWithPartner ? "true" : "false",
                created_at: Date(),
                updated_at: Date()
            )
            
            // Save memory via BackendService
            let backendService = BackendService.shared
            let savedMemory = try await backendService.createMemory(memory)
            
            print("✅ Memory created with ID: \(savedMemory.id ?? 0)")
            
            // Send notification to partner if shared
            if shareWithPartner, let partnerId = partnerId {
                await notifyPartnerAboutSharedMemory(partnerId: partnerId, memory: savedMemory)
            }
            
        } catch {
            print("❌ Failed to save as memory: \(error)")
        }
    }
    
    private func notifyPartnerAboutSharedMemory(partnerId: Int, memory: Memory) async {
        print("📱 Notifying partner about shared memory...")
        
        do {
            let backendService = BackendService.shared
            
            // Get current user ID
            guard let currentUserId = try? await backendService.getCurrentUserId() else {
                print("❌ No current user ID")
                return
            }
            
            let title = "💝 Neue gemeinsame Erinnerung"
            let body = "\(memory.title)"
            let data = [
                "type": "shared_memory",
                "memory_id": String(memory.id ?? 0),
                "sender_id": currentUserId
            ]
            
            try await backendService.sendPushNotificationToPartner(
                userId: currentUserId,
                partnerId: String(partnerId),
                title: title,
                body: body,
                data: data
            )
            
            print("✅ Partner notification sent")
        } catch {
            print("❌ Failed to notify partner: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    AddCalendarEntryView()
        .environmentObject(AppState())
        .environmentObject(CalendarManager.shared)
} 