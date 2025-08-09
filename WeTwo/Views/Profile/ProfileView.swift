//
//  ProfileView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI
import Foundation

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingRelationshipStatus = false
    @State private var showingPremiumUpgrade = false
    @State private var showingRegistrationSuccess = false
    @State private var registrationMessage = ""
    
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
                        
                        // TEMPORARY: Test User Registration Button
                        Button(action: {
                            Task {
                                await registerTestUser()
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🧪 Test User Registration")
                                        .font(.headline)
                                        .foregroundColor(ColorTheme.primaryText)
                                    Text("Register a test user in database")
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
                        Button(action: { 
                            appState.logout()
                        }) {
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
        .alert("Registrierung erfolgreich!", isPresented: $showingRegistrationSuccess) {
            Button("OK") { }
        } message: {
            Text(registrationMessage)
        }
    }
    
    // MARK: - Test User Registration Function
    private func registerTestUser() async {
        print("🚀 Starting test user registration...")
        
        // Test user data
        let testEmail = "testuser\(Int.random(in: 1000...9999))@wetwo.com"
        let testPassword = "TestPassword123!"
        let testName = "Test User \(Int.random(in: 1000...9999))"
        let testBirthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15))!
        
        print("📧 Email: \(testEmail)")
        print("👤 Name: \(testName)")
        print("🎂 Birth Date: \(testBirthDate)")
        
        do {
            // Register user with profile using existing app function
            let user = try await SupabaseService.shared.signUp(
                email: testEmail,
                password: testPassword
            )
            
            print("✅ SUCCESS: User registered in database!")
            print("🆔 User ID: \(user.id)")
            print("👤 Name: \(user.name)")
            print("🌟 Zodiac Sign: \(user.zodiacSign.emoji) \(user.zodiacSign.rawValue)")
            print("🎂 Birth Date: \(user.birthDate)")
            print("🔑 Email: \(testEmail)")
            print("🔐 Password: \(testPassword)")
            
            // Show success message and auto-login
            DispatchQueue.main.async {
                print("🎉 User registration completed successfully!")
                print("💡 You can now use these credentials to test the app:")
                print("   📧 Email: \(testEmail)")
                print("   🔐 Password: \(testPassword)")
                
                // Show success alert
                self.registrationMessage = "Benutzer erfolgreich in der Datenbank angelegt!\n\n📧 Email: \(testEmail)\n🔐 Passwort: \(testPassword)\n\nDer Benutzer wurde automatisch eingeloggt."
                self.showingRegistrationSuccess = true
                
                // Auto-login with the new user
                Task {
                    do {
                        let supabaseUser = try await SupabaseService.shared.signIn(email: testEmail, password: testPassword)
                        print("🔐 Auto-login successful for: \(supabaseUser.name)")
                        
                        // Store credentials securely
                        if let securityService = try? SecurityService.shared {
                            try? securityService.secureStore(testEmail, forKey: "userEmail")
                            try? securityService.secureStore(testPassword, forKey: "userPassword")
                            try? securityService.secureStore(supabaseUser.id.uuidString, forKey: "currentUserId")
                        }
                        
                        // Update the profile with the test user data
                        try await SupabaseService.shared.updateProfile(
                            userId: supabaseUser.id.uuidString,
                            name: testName,
                            birthDate: testBirthDate
                        )
                        print("✅ Profile updated with test user data")
                        
                        // Update app state with the new user
                        DispatchQueue.main.async {
                            let newUser = User(name: testName, birthDate: testBirthDate)
                            self.appState.currentUser = newUser
                            print("✅ App state updated with new user")
                        }
                        
                        // Update relationship data with default values
                        try await SupabaseService.shared.updateRelationshipData(
                            userId: supabaseUser.id.uuidString,
                            relationshipStatus: "in_relationship",
                            hasChildren: "false",
                            childrenCount: "0"
                        )
                        print("✅ Relationship data updated with default values")
                        
                        // Update the success message with more details
                        DispatchQueue.main.async {
                            self.registrationMessage = "Benutzer erfolgreich in der Datenbank angelegt!\n\n📧 Email: \(testEmail)\n🔐 Passwort: \(testPassword)\n👤 Name: \(testName)\n🎂 Geburtsdatum: \(testBirthDate)\n🌟 Sternzeichen: \(ZodiacSign.calculate(from: testBirthDate).emoji) \(ZodiacSign.calculate(from: testBirthDate).rawValue)\n💕 Beziehungsstatus: In Beziehung\n👶 Kinder: Nein\n\nDer Benutzer wurde automatisch eingeloggt und alle Daten wurden aktualisiert."
                        }
                        
                    } catch {
                        print("⚠️ Auto-login failed: \(error)")
                        print("💡 You can manually login with the credentials above")
                    }
                }
            }
            
        } catch AuthError.signUpFailed {
            print("❌ ERROR: Sign up failed - check Supabase configuration")
            print("💡 Make sure SUPABASE_URL and SUPABASE_ANON_KEY are set in Xcode Scheme Environment Variables")
        } catch {
            print("❌ ERROR: Unexpected error during registration: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
} 