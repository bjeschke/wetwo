//
//  AppState.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI
import Foundation

class AppState: ObservableObject {
    @Published var isOnboarding: Bool = true
    @Published var currentUser: User?
    @Published var isPremium: Bool = false
    @Published var dailyInsightsRemaining: Int = 3
    @Published var photoMissionsRemaining: Int = 1
    
    private let supabaseService = SupabaseService.shared
    private let securityService = SecurityService.shared
    
    init() {
        loadUserData()
    }
    
    private func loadUserData() {
        print("🔄 Loading user data from secure storage...")
        
        // Load from secure storage
        if let userData = try? securityService.secureLoad(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            print("✅ User found in secure storage: \(user.name)")
            self.currentUser = user
            self.isOnboarding = false
            print("✅ Onboarding set to false - user will see main app")
            
            // Try to sign in to Supabase if credentials exist
            Task {
                if let email = try? securityService.secureLoadString(forKey: "userEmail"),
                   let password = try? securityService.secureLoadString(forKey: "userPassword") {
                    print("🔄 Auto-signing in with email/password...")
                    do {
                        let supabaseUser = try await supabaseService.signIn(email: email, password: password)
                        print("✅ Auto-sign in successful for user: \(supabaseUser.email)")
                        
                        // Store the current user ID for other services
                        try? securityService.secureStore(supabaseUser.id, forKey: "currentUserId")
                        
                    } catch {
                        print("⚠️ Auto-sign in failed: \(error)")
                        // Don't show error to user, just continue with local data
                        // The user can still use the app, and we'll try to reconnect later
                    }
                } else {
                    print("⚠️ No email/password found in secure storage")
                }
            }
        } else {
            print("❌ No user found in secure storage - showing onboarding")
            self.isOnboarding = true
            self.currentUser = nil
        }
        
        // Load non-sensitive data from UserDefaults
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        self.dailyInsightsRemaining = UserDefaults.standard.integer(forKey: "dailyInsightsRemaining")
        self.photoMissionsRemaining = UserDefaults.standard.integer(forKey: "photoMissionsRemaining")
        
        // Validate security
        let securityValidation = securityService.validateSecurity()
        if !securityValidation.isValid {
            print("⚠️ Sicherheitsprobleme gefunden:")
            for issue in securityValidation.issues {
                print("  - \(issue.description)")
            }
        }
        
        print("📱 App state loaded - isOnboarding: \(self.isOnboarding), currentUser: \(self.currentUser?.name ?? "nil")")
    }
    
    func completeOnboardingWithAppleID(user: User, appleUserID: String) {
        self.currentUser = user
        self.isOnboarding = false
        
        // Save to secure storage
        if let encoded = try? JSONEncoder().encode(user) {
            try? securityService.secureStore(encoded, forKey: "currentUser")
        }
        
        // Store Apple ID securely
        try? securityService.secureStore(appleUserID, forKey: "appleUserID")
        
        // Create user profile in Supabase with Apple ID
        Task {
            do {
                // Generate a unique email based on Apple ID and timestamp
                let timestamp = Int(Date().timeIntervalSince1970)
                let email = "\(appleUserID)\(timestamp)@amavo.app"
                let password = "Amavo\(timestamp)!"
                
                print("🔄 Creating user profile with Apple ID: \(appleUserID)")
                
                // First, try to sign up the user
                let supabaseUser = try await supabaseService.signUp(email: email, password: password)
                let userId = supabaseUser.id
                
                // Save the user ID and credentials securely
                try? securityService.secureStore(userId, forKey: "currentUserId")
                try? securityService.secureStore(email, forKey: "userEmail")
                try? securityService.secureStore(password, forKey: "userPassword")
                
                // Create the profile with Apple ID
                try await supabaseService.createProfile(
                    userId: userId, 
                    name: user.name, 
                    birthDate: user.birthDate
                )
                
                print("✅ User profile created with Apple ID successfully")
                print("📧 Email: \(email)")
                print("🍎 Apple ID: \(appleUserID)")
                
            } catch {
                print("❌ Error creating user profile with Apple ID: \(error)")
                
                // If signup fails, try to sign in with existing credentials
                if let existingEmail = try? securityService.secureLoadString(forKey: "userEmail"),
                   let existingPassword = try? securityService.secureLoadString(forKey: "userPassword") {
                    do {
                        print("🔄 Attempting to sign in with existing credentials...")
                        let supabaseUser = try await supabaseService.signIn(email: existingEmail, password: existingPassword)
                        let userId = supabaseUser.id
                        try? securityService.secureStore(userId, forKey: "currentUserId")
                        
                        // Update the profile with Apple ID
                        try await supabaseService.updateProfile(
                            userId: userId, 
                            name: user.name, 
                            birthDate: user.birthDate
                        )
                        print("✅ User signed in and profile updated with Apple ID successfully")
                    } catch {
                        print("❌ Error signing in with existing credentials: \(error)")
                    }
                }
            }
        }
    }
    
    func completeOnboarding(user: User) {
        self.currentUser = user
        self.isOnboarding = false
        
        // Save to secure storage
        if let encoded = try? JSONEncoder().encode(user) {
            try? securityService.secureStore(encoded, forKey: "currentUser")
        }
        
        // Create user profile in Supabase
        Task {
            do {
                // Generate a unique email based on user name and timestamp
                let timestamp = Int(Date().timeIntervalSince1970)
                let sanitizedName = user.name.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "ä", with: "ae").replacingOccurrences(of: "ö", with: "oe").replacingOccurrences(of: "ü", with: "ue").replacingOccurrences(of: "ß", with: "ss")
                let email = "\(sanitizedName)\(timestamp)@amavo.app"
                let password = "Amavo\(timestamp)!"
                
                print("🔄 Attempting to create user with email: \(email)")
                
                // Sign up user with profile creation
                let supabaseUser = try await supabaseService.signUpWithProfile(email: email, password: password, name: user.name, birthDate: user.birthDate)
                let userId = supabaseUser.id
                
                // Save the user ID and credentials securely
                try? securityService.secureStore(userId, forKey: "currentUserId")
                try? securityService.secureStore(email, forKey: "userEmail")
                try? securityService.secureStore(password, forKey: "userPassword")
                
                print("✅ User profile created in Supabase successfully")
                print("📧 Email: \(email)")
                print("🔑 Password: \(password)")
                
            } catch {
                print("❌ Error creating user profile in Supabase: \(error)")
                
                // If signup fails, try to sign in with existing credentials
                if let existingEmail = try? securityService.secureLoadString(forKey: "userEmail"),
                   let existingPassword = try? securityService.secureLoadString(forKey: "userPassword") {
                    do {
                        print("🔄 Attempting to sign in with existing credentials...")
                        let supabaseUser = try await supabaseService.signIn(email: existingEmail, password: existingPassword)
                        let userId = supabaseUser.id
                        try? securityService.secureStore(userId, forKey: "currentUserId")
                        
                        // Update the profile
                        try await supabaseService.updateProfile(userId: userId, name: user.name, birthDate: user.birthDate)
                        print("✅ User signed in and profile updated successfully")
                    } catch {
                        print("❌ Error signing in with existing credentials: \(error)")
                    }
                }
            }
        }
    }
    
    func useDailyInsight() {
        if !isPremium && dailyInsightsRemaining > 0 {
            dailyInsightsRemaining -= 1
            UserDefaults.standard.set(dailyInsightsRemaining, forKey: "dailyInsightsRemaining")
        }
    }
    
    func usePhotoMission() {
        if !isPremium && photoMissionsRemaining > 0 {
            photoMissionsRemaining -= 1
            UserDefaults.standard.set(photoMissionsRemaining, forKey: "photoMissionsRemaining")
        }
    }
    
    func resetWeeklyLimits() {
        if !isPremium {
            dailyInsightsRemaining = 3
            photoMissionsRemaining = 1
            UserDefaults.standard.set(dailyInsightsRemaining, forKey: "dailyInsightsRemaining")
            UserDefaults.standard.set(photoMissionsRemaining, forKey: "photoMissionsRemaining")
        }
    }
    
    // MARK: - Debug/Reset Functions
    
    func resetOnboarding() {
        print("🔄 Resetting onboarding state...")
        self.isOnboarding = true
        self.currentUser = nil
        
        // Clear secure storage
        try? securityService.secureDelete(forKey: "currentUser")
        try? securityService.secureDelete(forKey: "currentUserId")
        try? securityService.secureDelete(forKey: "userEmail")
        try? securityService.secureDelete(forKey: "userPassword")
        try? securityService.secureDelete(forKey: "appleUserID")
        
        print("✅ Onboarding reset complete")
    }
    
    func logout() {
        print("🔄 Logging out user...")
        self.isOnboarding = true
        self.currentUser = nil
        
        // Clear secure storage
        try? securityService.secureDelete(forKey: "currentUser")
        try? securityService.secureDelete(forKey: "currentUserId")
        try? securityService.secureDelete(forKey: "userEmail")
        try? securityService.secureDelete(forKey: "userPassword")
        try? securityService.secureDelete(forKey: "appleUserID")
        
        print("✅ Logout complete")
    }
} 