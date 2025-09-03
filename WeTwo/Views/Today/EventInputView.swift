//
//  EventInputView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct EventInputView: View {
    @Binding var eventLabel: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var customEventText = ""
    @State private var selectedQuickEvent: String? = nil
    
    private let quickEvents = [
        "Arbeitstag", "Date Night", "Familienzeit", "Freunde getroffen",
        "Sport gemacht", "Entspannt", "Kochen", "Spaziergang",
        "Film geschaut", "Gelesen", "Musik gehört", "Shopping",
        "Reisen", "Essen gegangen", "Zuhause geblieben"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerSection
                    
                    // Quick events grid
                    quickEventsSection
                    
                    // Custom text input
                    customTextSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .purpleTheme()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Überspringen") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        saveEvent()
                    }
                    .foregroundColor(ColorTheme.accentPink)
                    .disabled(getCurrentEventText().isEmpty)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("📝")
                .font(.system(size: 60))
            
            Text("Was hast du heute gemacht?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Wähle ein Event aus oder schreibe dein eigenes")
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private var quickEventsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Schnell-Events")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
                .padding(.horizontal, 5)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                ForEach(quickEvents, id: \.self) { event in
                    Button(action: {
                        selectQuickEvent(event)
                    }) {
                        Text(event)
                            .font(.body)
                            .foregroundColor(selectedQuickEvent == event ? .white : ColorTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(selectedQuickEvent == event ? ColorTheme.accentBlue : ColorTheme.cardBackgroundSecondary)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .purpleCard()
    }
    
    private var customTextSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Eigenes Event")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
                .padding(.horizontal, 5)
            
            TextField("Beschreibe dein Event...", text: $customEventText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .foregroundColor(ColorTheme.primaryText)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(ColorTheme.cardBackgroundSecondary)
                )
                .lineLimit(3...5)
                .onChange(of: customEventText) { _ in
                    if !customEventText.isEmpty {
                        selectedQuickEvent = nil
                    }
                }
        }
        .purpleCard()
    }
    
    private func selectQuickEvent(_ event: String) {
        selectedQuickEvent = event
        customEventText = ""
    }
    
    private func getCurrentEventText() -> String {
        if let selectedEvent = selectedQuickEvent {
            return selectedEvent
        }
        return customEventText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func saveEvent() {
        let eventText = getCurrentEventText()
        if !eventText.isEmpty {
            onSave(eventText)
        }
        dismiss()
    }
}

#Preview {
    EventInputView(eventLabel: .constant(""), onSave: { _ in })
} 