//
//  DeepLinkHandler.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

@MainActor
class DeepLinkHandler: ObservableObject {
    @Published var pendingEmailConfirmation: Bool = false
    @Published var emailConfirmationData: EmailConfirmationData?
    
    private let supabaseService = SupabaseService.shared
    private let securityService = SecurityService.shared
    
    struct EmailConfirmationData {
        let email: String
        let password: String
        let name: String
        let birthDate: Date
    }
    
    func handleDeepLink(_ url: URL) {
        print("🔗 Processing deep link: \(url)")
        
        // Check if this is a Supabase email confirmation link
        if isSupabaseEmailConfirmation(url) {
            handleEmailConfirmation(url)
        } else {
            print("⚠️ Unknown deep link format: \(url)")
        }
    }
    
    private func isSupabaseEmailConfirmation(_ url: URL) -> Bool {
        // Supabase email confirmation links typically contain these patterns:
        // - access_token parameter
        // - type=signup or type=recovery
        // - token_hash parameter
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        let hasAccessToken = queryItems.contains { $0.name == "access_token" }
        let hasType = queryItems.contains { $0.name == "type" }
        let hasTokenHash = queryItems.contains { $0.name == "token_hash" }
        
        return hasAccessToken && hasType && hasTokenHash
    }
    
    private func handleEmailConfirmation(_ url: URL) {
        print("✅ Processing email confirmation link")
        
        // Extract confirmation data from secure storage
        if let email = try? securityService.secureLoadString(forKey: "pendingEmail"),
           let password = try? securityService.secureLoadString(forKey: "pendingPassword"),
           let name = try? securityService.secureLoadString(forKey: "pendingName"),
           let birthDateString = try? securityService.secureLoadString(forKey: "pendingBirthDate"),
           let birthDate = DateFormatter.yyyyMMdd.date(from: birthDateString) {
            
            let confirmationData = EmailConfirmationData(
                email: email,
                password: password,
                name: name,
                birthDate: birthDate
            )
            
            self.emailConfirmationData = confirmationData
            self.pendingEmailConfirmation = true
            
            print("✅ Email confirmation data loaded from secure storage")
            
            // Process the confirmation
            Task {
                await processEmailConfirmation(confirmationData)
            }
        } else {
            print("❌ No pending email confirmation data found")
        }
    }
    
    private func processEmailConfirmation(_ data: EmailConfirmationData) async {
        do {
            print("🔄 Processing email confirmation for: \(data.email)")
            
            // Try to sign in with the confirmed credentials
            let user = try await supabaseService.confirmEmailAndSignIn(
                email: data.email,
                password: data.password
            )
            
            print("✅ Email confirmation successful")
            
            // Clear pending data from secure storage
            try? securityService.secureDelete(forKey: "pendingEmail")
            try? securityService.secureDelete(forKey: "pendingPassword")
            try? securityService.secureDelete(forKey: "pendingName")
            try? securityService.secureDelete(forKey: "pendingBirthDate")
            
            // Store confirmed credentials
            try? securityService.secureStore(data.email, forKey: "userEmail")
            try? securityService.secureStore(data.password, forKey: "userPassword")
            
            // Update app state
            DispatchQueue.main.async {
                self.pendingEmailConfirmation = false
                self.emailConfirmationData = nil
                
                // Post notification to trigger onboarding completion
                NotificationCenter.default.post(name: .emailConfirmed, object: nil)
            }
            
        } catch {
            print("❌ Email confirmation failed: \(error)")
            
            DispatchQueue.main.async {
                self.pendingEmailConfirmation = false
                self.emailConfirmationData = nil
            }
        }
    }
    
    // MARK: - Public Methods
    
    func storePendingConfirmation(email: String, password: String, name: String, birthDate: Date) {
        print("💾 Storing pending email confirmation data")
        
        try? securityService.secureStore(email, forKey: "pendingEmail")
        try? securityService.secureStore(password, forKey: "pendingPassword")
        try? securityService.secureStore(name, forKey: "pendingName")
        try? securityService.secureStore(DateFormatter.yyyyMMdd.string(from: birthDate), forKey: "pendingBirthDate")
    }
    
    func clearPendingConfirmation() {
        print("🗑️ Clearing pending email confirmation data")
        
        try? securityService.secureDelete(forKey: "pendingEmail")
        try? securityService.secureDelete(forKey: "pendingPassword")
        try? securityService.secureDelete(forKey: "pendingName")
        try? securityService.secureDelete(forKey: "pendingBirthDate")
        
        pendingEmailConfirmation = false
        emailConfirmationData = nil
    }
}
