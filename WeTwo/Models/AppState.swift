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
    @Published var isOnboarded: Bool = false
    @Published var currentUser: User?
    @Published var isPremium: Bool = false
    @Published var dailyInsightsRemaining: Int = 3
    @Published var photoMissionsRemaining: Int = 1
    @Published var firebaseIdToken: String?
    
    private let dataService = ServiceFactory.shared.getCurrentService()
    
    init() {
        loadUserData()
    }
    
    private func loadUserData() {
        print("🔄 Loading user data from UserDefaults...")
        
        // Load from UserDefaults
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            print("✅ User found in UserDefaults: \(user.name)")
            self.currentUser = user
            
            // Check if we have credentials and can sign in
            Task {
                if let email = UserDefaults.standard.string(forKey: "userEmail"),
                   let password = UserDefaults.standard.string(forKey: "userPassword") {
                    print("🔄 Auto-signing in with email/password...")
                    do {
                        let databaseUser = try await dataService.signIn(email: email, password: password)
                        print("✅ Auto-sign in successful for user: \(databaseUser.name)")
                        
                        // Ensure profile exists
                        try? await dataService.ensureProfileExists()
                        
                        // Try to load partner code from backend if not stored locally
                        if UserDefaults.standard.string(forKey: "userPartnerCode") == nil {
                            if let backendService = dataService as? BackendService,
                               let partnerCode = try? await backendService.getUserPartnerCode() {
                                UserDefaults.standard.set(partnerCode, forKey: "userPartnerCode")
                                print("✅ Partner code loaded during auto-sign-in: \(partnerCode)")
                            }
                        }
                        
                        // Only complete onboarding if we can successfully sign in
                        DispatchQueue.main.async {
                            self.isOnboarding = false
                            print("✅ Onboarding set to false - user will see main app")
                        }
                        
                    } catch {
                        print("⚠️ Auto-sign in failed: \(error)")
                        
                        // Handle specific refresh token errors
                        if error.localizedDescription.contains("Refresh Token") || 
                           error.localizedDescription.contains("Invalid") {
                            print("🔄 Clearing invalid credentials due to refresh token error")
                            // Clear the stored credentials since they're invalid
                            UserDefaults.standard.removeObject(forKey: "userEmail")
                            UserDefaults.standard.removeObject(forKey: "userPassword")
                            
                            // Show onboarding again since credentials are invalid
                            DispatchQueue.main.async {
                                self.isOnboarding = true
                                print("🔄 Onboarding set to true - invalid credentials")
                            }
                        } else {
                            // For other errors, stay in onboarding
                            DispatchQueue.main.async {
                                self.isOnboarding = true
                                print("🔄 Onboarding set to true - sign in failed")
                            }
                        }
                    }
                } else {
                    print("⚠️ No email/password found in UserDefaults")
                    // No credentials found, stay in onboarding
                    DispatchQueue.main.async {
                        self.isOnboarding = true
                        print("🔄 Onboarding set to true - no credentials")
                    }
                }
            }
        } else {
            print("❌ No user found in UserDefaults - showing onboarding")
            self.isOnboarding = true
            self.currentUser = nil
        }
        
        // Load non-sensitive data from UserDefaults
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        self.dailyInsightsRemaining = UserDefaults.standard.integer(forKey: "dailyInsightsRemaining")
        self.photoMissionsRemaining = UserDefaults.standard.integer(forKey: "photoMissionsRemaining")
        
        
        print("📱 App state loaded - isOnboarding: \(self.isOnboarding), currentUser: \(self.currentUser?.name ?? "nil")")
    }
    
    func completeOnboardingWithAppleID(user: User, appleUserID: String) {
        self.currentUser = user
        self.isOnboarding = false
        
        // Save to secure storage
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        
        // Store Apple ID securely
        UserDefaults.standard.set(appleUserID, forKey: "appleUserID")
        
        // Create user profile with Apple ID
        Task {
            do {
                // Generate a unique email based on Apple ID and timestamp
                let timestamp = Int(Date().timeIntervalSince1970)
                let email = "\(appleUserID)\(timestamp)@amavo.app"
                let password = "Amavo\(timestamp)!"
                
                print("🔄 Creating user profile with Apple ID: \(appleUserID)")
                
                // First, try to sign up the user
                let dataService = ServiceFactory.shared.getCurrentService()
                let databaseUser = try await dataService.signUp(email: email, password: password, name: user.name, birthDate: user.birthDate)
                let userId = databaseUser.id
                
                // Save the credentials securely
                UserDefaults.standard.set(email, forKey: "userEmail")
                UserDefaults.standard.set(password, forKey: "userPassword")
                
                // Update the profile with Apple ID (created automatically by trigger)
                try await dataService.updateProfile(
                    userId: String(userId), 
                    name: user.name, 
                    birthDate: user.birthDate
                )
                
                // Update the auth user's display name in userMetadata
                try await dataService.updateAuthUserDisplayName(name: user.name)
                
                print("✅ User profile updated with Apple ID successfully")
                print("📧 Email: \(email)")
                print("🍎 Apple ID: \(appleUserID)")
                
            } catch {
                print("❌ Error creating user profile with Apple ID: \(error)")
                
                // If signup fails, try to sign in with existing credentials
                if let existingEmail = UserDefaults.standard.string(forKey: "userEmail"),
                   let existingPassword = UserDefaults.standard.string(forKey: "userPassword") {
                    do {
                        print("🔄 Attempting to sign in with existing credentials...")
                        let databaseUser = try await dataService.signIn(email: existingEmail, password: existingPassword)
                        let userId = databaseUser.id
                        
                        // Update the profile with Apple ID
                        try await dataService.updateProfile(
                            userId: String(userId), 
                            name: user.name, 
                            birthDate: user.birthDate
                        )
                        
                        // Update the auth user's display name in userMetadata
                        try await dataService.updateAuthUserDisplayName(name: user.name)
                        
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
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        
        // Note: Profile creation is now handled in the UI layer

    }
    
    func completeOnboardingWithCurrentService(user: User) {
        // Set the current user immediately
        self.currentUser = user
        self.isOnboarding = false
        
        // Save to secure storage
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        
        // Create user profile in current service using the new robust method
        Task {
            do {
                // Get the email and password from secure storage (set during signup)
                guard let email = UserDefaults.standard.string(forKey: "userEmail"),
                      let password = UserDefaults.standard.string(forKey: "userPassword") else {
                    print("❌ No email/password found in secure storage")
                    return
                }
                
                print("🔄 Attempting to create user with email: \(email)")
                
                // Use the new robust completeOnboarding method
                let databaseUser = try await dataService.completeOnboarding(
                    email: email,
                    password: password,
                    name: user.name,
                    birthDate: user.birthDate
                )
                
                // Update the auth user's display name in userMetadata
                try await dataService.updateAuthUserDisplayName(name: user.name)
                
                // Save the credentials securely
                UserDefaults.standard.set(email, forKey: "userEmail")
                UserDefaults.standard.set(password, forKey: "userPassword")
                
                print("✅ User profile created in current service successfully")
                print("📧 Email: \(email)")
                print("🔑 Password: \(password)")
                
            } catch {
                print("❌ Error creating user profile in current service: \(error)")
                
                // If signup fails, try to sign in with existing credentials
                if let existingEmail = UserDefaults.standard.string(forKey: "userEmail"),
                   let existingPassword = UserDefaults.standard.string(forKey: "userPassword") {
                    do {
                        print("🔄 Attempting to sign in with existing credentials...")
                        let databaseUser = try await dataService.signIn(email: existingEmail, password: existingPassword)
                        let userId = databaseUser.id
                        
                        // Update the profile
                        try await dataService.updateProfile(userId: String(userId), name: user.name, birthDate: user.birthDate)
                        
                        // Update the auth user's display name in userMetadata
                        try await dataService.updateAuthUserDisplayName(name: user.name)
                        
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
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userPassword")
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        
        print("✅ Onboarding reset complete")
    }
    
    func logout() {
        print("🔄 Logging out user...")
        self.isOnboarding = true
        self.currentUser = nil
        
        // Clear secure storage
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userPassword")
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        
        print("✅ Logout complete")
    }
}