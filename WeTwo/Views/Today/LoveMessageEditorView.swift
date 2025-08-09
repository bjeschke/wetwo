//
//  LoveMessageEditorView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct LoveMessageEditorView: View {
    let initialMessage: String
    @Binding var customMessage: String
    let onGenerate: () -> Void
    let onSend: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var showingSendConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(ColorTheme.accentPink)
                    
                    Text(NSLocalizedString("today_love_message_editor_title", comment: "Love message editor title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(NSLocalizedString("today_love_message_editor_subtitle", comment: "Love message editor subtitle"))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .padding(.top, 20)
                
                // Message editor
                VStack(spacing: 15) {
                    HStack {
                        Text(NSLocalizedString("today_love_message_label", comment: "Love message label"))
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            isGenerating = true
                            onGenerate()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isGenerating = false
                            }
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.accentPink))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text(NSLocalizedString("today_generate_new", comment: "Generate new"))
                            }
                            .font(.caption)
                            .foregroundColor(ColorTheme.accentPink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(ColorTheme.accentPink.opacity(0.1))
                            )
                        }
                        .disabled(isGenerating)
                    }
                    
                    TextEditor(text: $customMessage)
                        .font(.body)
                        .foregroundColor(ColorTheme.primaryText)
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(ColorTheme.cardBackgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(ColorTheme.accentPink.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if customMessage.isEmpty {
                                    VStack {
                                        HStack {
                                            Text(NSLocalizedString("today_love_message_placeholder", comment: "Love message placeholder"))
                                                .font(.body)
                                                .foregroundColor(ColorTheme.secondaryText.opacity(0.6))
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .padding(20)
                                    .allowsHitTesting(false)
                                }
                            }
                        )
                }
                
                // Character count
                HStack {
                    Text("\(customMessage.count) / 500")
                        .font(.caption)
                        .foregroundColor(customMessage.count > 450 ? ColorTheme.error : ColorTheme.secondaryText)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        showingSendConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text(NSLocalizedString("today_send_love_message", comment: "Send love message"))
                        }
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [ColorTheme.accentPink, ColorTheme.primaryPurple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(25)
                        .shadow(color: ColorTheme.accentPink.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        UIPasteboard.general.string = customMessage
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text(NSLocalizedString("today_copy_message", comment: "Copy message"))
                        }
                        .font(.body)
                        .foregroundColor(ColorTheme.accentPink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(ColorTheme.accentPink, lineWidth: 1)
                        )
                    }
                    .disabled(customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .purpleTheme()
            .navigationTitle(NSLocalizedString("today_love_message_editor_title", comment: "Love message editor title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if customMessage.isEmpty && !initialMessage.isEmpty {
                    customMessage = initialMessage
                }
            }
            .alert(NSLocalizedString("today_send_confirmation_title", comment: "Send confirmation title"), isPresented: $showingSendConfirmation) {
                Button(NSLocalizedString("today_send", comment: "Send")) {
                    onSend()
                }
                Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("today_send_confirmation_message", comment: "Send confirmation message"))
            }
        }
    }
}

#Preview {
    LoveMessageEditorView(
        initialMessage: "Du bist der beste Partner der Welt! 💕",
        customMessage: .constant("Du bist der beste Partner der Welt! 💕"),
        onGenerate: {},
        onSend: {}
    )
}
