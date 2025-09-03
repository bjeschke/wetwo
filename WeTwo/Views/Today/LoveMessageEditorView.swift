//
//  LoveMessageEditorView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct LoveMessageEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loveMessageManager: LoveMessageManager
    @State private var message = ""
    @State private var selectedMood: MoodLevel = .happy
    @State private var isPrivate = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Write a Love Message")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(.label))
                        
                        Text("Share your feelings with your partner")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(.systemGray))
                    }
                    .padding(.top, 20)
                    
                    // Message Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Message")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        TextEditor(text: $message)
                            .frame(minHeight: 150)
                            .modifier(AppleTextEditorStyle(placeholder: "Write your love message here...", text: $message))
                    }
                    .padding(.horizontal, 20)
                    
                    // Mood Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(MoodLevel.allCases, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    VStack(spacing: 8) {
                                        Text(mood.emoji)
                                            .font(.system(size: 24))
                                        
                                        Text(mood.description)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selectedMood == mood ? .white : Color(.label))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedMood == mood ? Color.accentColor : Color(.systemGray6))
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Privacy Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Private Message")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(.label))
                                
                                Text("Only you can see this message")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(.systemGray))
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isPrivate)
                                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Send Button
                    Button(action: sendMessage) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Send Message")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor)
                        )
                        .opacity(isLoading ? 0.7 : 1.0)
                    }
                    .disabled(isLoading || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Fehler", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private func sendMessage() {
        isLoading = true
        errorMessage = ""
        showError = false
        
        print("💌 Sending love message...")
        
        Task {
            do {
                // Get partner ID from PartnerManager
                let partnerManager = PartnerManager.shared
                guard let partnerId = partnerManager.partnerProfile?.id else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Kein Partner verbunden. Bitte verbinde dich zuerst mit deinem Partner."
                        showError = true
                    }
                    return
                }
                
                print("📤 Sending to partner ID: \(partnerId)")
                
                // Send love message using the manager
                try await loveMessageManager.sendMessage(message, to: partnerId)
                
                print("✅ Love message sent successfully!")
                
                // Add mood context to the message (optional)
                let fullMessage = "\(selectedMood.emoji) \(message)"
                
                await MainActor.run {
                    isLoading = false
                    // Show success feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    dismiss()
                }
                
            } catch {
                print("❌ Failed to send love message: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Nachricht konnte nicht gesendet werden: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

struct LoveMessageEditorView_Previews: PreviewProvider {
    static var previews: some View {
        LoveMessageEditorView()
    }
}
