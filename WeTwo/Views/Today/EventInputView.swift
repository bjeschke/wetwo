//
//  EventInputView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct EventInputView: View {
    @Binding var eventLabel: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempEventLabel = ""
    @State private var selectedQuickEvent: String?
    
    private let quickEvents = [
        "Work day", "Date night", "Family time", "Workout", "Coffee date",
        "Movie night", "Dinner out", "Staycation", "Travel day", "Chill day",
        "Party time", "Study session", "Shopping", "Cooking", "Gaming"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("📝")
                        .font(.system(size: 60))
                    
                    Text("What happened today?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Add a quick note about your day")
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Custom event input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Or write your own:")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    TextField("e.g., Had an amazing lunch with friends", text: $tempEventLabel)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                .padding(.horizontal, 20)
                
                // Quick event buttons
                VStack(alignment: .leading, spacing: 15) {
                    Text("Quick events:")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(quickEvents, id: \.self) { event in
                            Button(action: {
                                selectedQuickEvent = event
                                tempEventLabel = event
                            }) {
                                                        Text(event)
                            .font(.body)
                            .foregroundColor(selectedQuickEvent == event ? .white : .primary)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedQuickEvent == event ? Color.blue : Color.gray.opacity(0.1))
                            )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 15) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.accentBlue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                    
                    Button("Save") {
                        eventLabel = tempEventLabel
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .disabled(tempEventLabel.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.accentBlue)
                }
            }
        }
        .onAppear {
            tempEventLabel = eventLabel
        }
    }
}

#Preview {
    EventInputView(eventLabel: .constant(""), onSave: {})
} 