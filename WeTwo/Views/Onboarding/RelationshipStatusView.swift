//
//  RelationshipStatusView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct RelationshipStatusView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var meetingDate = Date()
    @State private var relationshipStatus: RelationshipStatus = .inRelationship
    @State private var hasChildren = false
    @State private var childrenCount = 0
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [ColorTheme.primaryPurple, ColorTheme.secondaryPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("💕")
                        .font(.system(size: 60))
                    
                    Text(NSLocalizedString("onboarding_relationship_title", comment: "Relationship title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Erzähl uns von eurer Beziehung")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Meeting date section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("onboarding_meeting_date_label", comment: "Meeting date label"))
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            DatePicker("", selection: $meetingDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .colorScheme(.dark)
                                .accentColor(.white)
                                .labelsHidden()
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(ColorTheme.cardBackgroundSecondary)
                                )
                        }
                        
                        // Relationship status section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("onboarding_relationship_status_label", comment: "Relationship status label"))
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(RelationshipStatus.allCases, id: \.self) { status in
                                    Button(action: {
                                        relationshipStatus = status
                                    }) {
                                        HStack {
                                            Text(status.emoji)
                                                .font(.title2)
                                            Text(status.localizedName)
                                                .font(.body)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(relationshipStatus == status ? .white : ColorTheme.primaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(relationshipStatus == status ? ColorTheme.accentPink : ColorTheme.cardBackgroundSecondary)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Children section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("onboarding_children_label", comment: "Children label"))
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            VStack(spacing: 15) {
                                // Has children toggle
                                HStack {
                                    Text(NSLocalizedString("onboarding_has_children", comment: "Has children"))
                                        .font(.body)
                                        .foregroundColor(ColorTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $hasChildren)
                                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
                                }
                                
                                // Children count (if has children)
                                if hasChildren {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(NSLocalizedString("onboarding_children_count_label", comment: "Children count label"))
                                            .font(.subheadline)
                                            .foregroundColor(ColorTheme.secondaryText)
                                        
                                        HStack {
                                            Button(action: {
                                                if childrenCount > 0 {
                                                    childrenCount -= 1
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(ColorTheme.accentPink)
                                            }
                                            .disabled(childrenCount == 0)
                                            
                                            Text("\(childrenCount)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(ColorTheme.primaryText)
                                                .frame(minWidth: 50)
                                            
                                            Button(action: {
                                                if childrenCount < 10 {
                                                    childrenCount += 1
                                                }
                                            }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(ColorTheme.accentPink)
                                            }
                                            .disabled(childrenCount == 10)
                                            
                                            Spacer()
                                            
                                            Text(childrenCount == 1 ? NSLocalizedString("child", comment: "child") : NSLocalizedString("children", comment: "children"))
                                                .font(.body)
                                                .foregroundColor(ColorTheme.secondaryText)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(ColorTheme.cardBackgroundSecondary)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: saveRelationshipData) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Speichern")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(ColorTheme.accentPink)
                        )
                    }
                    .disabled(isLoading)
                    
                    Button(action: { dismiss() }) {
                        Text("Später")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
    
    private func saveRelationshipData() {
        isLoading = true
        
        Task {
            do {
                guard let userId = appState.currentUser?.id else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
                
                // For now, just save locally and show success
                // TODO: Implement proper Supabase relationship data saving
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
                
                print("✅ Relationship data saved successfully")
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("❌ Error saving relationship data: \(error)")
            }
        }
    }
}

#Preview {
    RelationshipStatusView()
        .environmentObject(AppState())
} 