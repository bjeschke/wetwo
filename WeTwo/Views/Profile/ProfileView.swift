//
//  ProfileView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingRelationshipStatus = false
    @State private var showingPremiumUpgrade = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(ColorTheme.accentPink)
                        
                        if let user = appState.currentUser {
                            Text("Hallo, \(user.name)!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorTheme.primaryText)
                        }
                    }
                    .padding(.top, 100)
                    
                    // Profile options
                    VStack(spacing: 20) {
                        // Relationship Status Button
                        Button(action: { showingRelationshipStatus = true }) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundColor(ColorTheme.accentPink)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Beziehungsstatus")
                                        .font(.headline)
                                        .foregroundColor(ColorTheme.primaryText)
                                    Text("Kennlerndatum, Status & Kinder")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(ColorTheme.cardBackgroundSecondary)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Premium Upgrade Button
                        Button(action: { showingPremiumUpgrade = true }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Premium Upgrade")
                                        .font(.headline)
                                        .foregroundColor(ColorTheme.primaryText)
                                    Text("Erweiterte Features freischalten")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(ColorTheme.cardBackgroundSecondary)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Settings
                        VStack(spacing: 15) {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "gear")
                                        .font(.title2)
                                        .foregroundColor(ColorTheme.accentBlue)
                                    
                                    Text("Einstellungen")
                                        .font(.headline)
                                        .foregroundColor(ColorTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.body)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(ColorTheme.cardBackgroundSecondary)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.title2)
                                        .foregroundColor(ColorTheme.accentBlue)
                                    
                                    Text("Über Amavo")
                                        .font(.headline)
                                        .foregroundColor(ColorTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.body)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(ColorTheme.cardBackgroundSecondary)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Logout
                        Button(action: { }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                
                                Text("Abmelden")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(ColorTheme.cardBackgroundSecondary)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
            .purpleTheme()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRelationshipStatus) {
            RelationshipStatusView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
} 