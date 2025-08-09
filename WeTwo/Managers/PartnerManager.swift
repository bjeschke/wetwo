//
//  PartnerManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI

enum PartnerError: Error, LocalizedError {
    case invalidCode
    case networkError
    case alreadyConnected
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return NSLocalizedString("partner_error_invalid_code", comment: "Invalid connection code")
        case .networkError:
            return NSLocalizedString("partner_error_network", comment: "Network error occurred")
        case .alreadyConnected:
            return NSLocalizedString("partner_error_already_connected", comment: "Already connected to a partner")
        }
    }
}

class PartnerManager: ObservableObject {
    @Published var partner: User?
    @Published var isConnected: Bool = false
    @Published var connectionCode: String = ""
    @Published var ownConnectionCode: String = ""
    @Published var qrCodeImage: UIImage?
    @Published var isGeneratingCode: Bool = false
    @Published var partnershipStatus: PartnershipStatus = .notConnected
    @Published var partnerProfile: Profile?
    @Published var partnerProfilePhoto: UIImage?
    
    private let userDefaults = UserDefaults.standard
    private let supabaseService = SupabaseService.shared
    
    init() {
        loadPartnerData()
        generateOwnConnectionCode()
    }
    
    func generateOwnConnectionCode() {
        isGeneratingCode = true
        
        // Generate a unique 6-character code
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        ownConnectionCode = String((0..<6).map { _ in characters.randomElement()! })
        
        // Generate QR code
        generateQRCode()
        
        isGeneratingCode = false
    }
    
    private func generateQRCode() {
        guard let data = ownConnectionCode.data(using: .utf8) else { return }
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter?.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    func connectWithPartner(using code: String) async throws {
        // Find partner by connection code
        guard let partnerProfile = try await supabaseService.findPartnerByCode(connectionCode: code) else {
            throw PartnerError.invalidCode
        }
        
        // Create partnership
        let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
        try await supabaseService.createPartnership(
            userId: currentUserId,
            partnerId: partnerProfile.id,
            connectionCode: code
        )
        
        // Update local state
        await MainActor.run {
            self.isConnected = true
            self.partnerProfile = partnerProfile
            self.partnershipStatus = .connected(partnerName: partnerProfile.name, partnerId: partnerProfile.id)
            self.savePartnerData()
        }
        
        // Subscribe to partner updates
        try await supabaseService.subscribeToPartnerUpdates(userId: currentUserId) { [weak self] updatedProfile in
            DispatchQueue.main.async {
                self?.partnerProfile = updatedProfile
            }
        }
        
        // Load partner profile photo
        await loadPartnerProfilePhoto(partnerId: partnerProfile.id)
    }
    
    func disconnectPartner() async {
        do {
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
            try await supabaseService.disconnectPartner(userId: currentUserId)
            
            await MainActor.run {
                self.partner = nil
                self.isConnected = false
                self.partnerProfile = nil
                self.partnershipStatus = .notConnected
                self.savePartnerData()
            }
            
            // Unsubscribe from partner updates
            try await supabaseService.unsubscribeFromPartnerUpdates(userId: currentUserId)
        } catch {
            print("Error disconnecting partner: \(error)")
        }
    }
    
    func syncPartnerMood(_ mood: MoodEntry) {
        // In a real app, this would sync with the partner's device
        // For now, we'll simulate it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate receiving partner's mood
            print("Synced mood with partner: \(mood.moodLevel.emoji)")
        }
    }
    
    func getPartnerMood(for date: Date) -> MoodEntry? {
        // In a real app, this would fetch from server/database
        // For now, return a simulated mood that's consistent
        guard isConnected else { return nil }
        
        // Use a consistent mood based on the date for demo purposes
        // In a real app, this would fetch from the database
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        let moods: [MoodLevel] = [.happy, .neutral, .veryHappy, .sad, .happy]
        let moodIndex = dayOfYear % moods.count
        let selectedMood = moods[moodIndex]
        
        let events = ["Work day", "Weekend vibes", "Date night", "Family time", "Relaxing"]
        let eventIndex = dayOfYear % events.count
        let selectedEvent = events[eventIndex]
        
        return MoodEntry(
            userId: partner?.id ?? UUID(),
            moodLevel: selectedMood,
            eventLabel: selectedEvent,
            location: "Home"
        )
    }
    
    func getCompatibilityScore() -> Int {
        guard let currentUser = getCurrentUser(),
              let partner = partner else { return 0 }
        
        // Simple compatibility based on zodiac elements
        let currentElement = currentUser.zodiacSign.element
        let partnerElement = partner.zodiacSign.element
        
        switch (currentElement, partnerElement) {
        case ("Fire", "Air"), ("Air", "Fire"):
            return 95 // Great compatibility
        case ("Earth", "Water"), ("Water", "Earth"):
            return 90 // Good compatibility
        case ("Fire", "Fire"), ("Air", "Air"), ("Earth", "Earth"), ("Water", "Water"):
            return 85 // Same element
        default:
            return 75 // Neutral compatibility
        }
    }
    
    // MARK: - Profile Synchronization
    func syncProfileWithPartner(name: String, zodiacSign: String, birthDate: Date) async {
        do {
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
            try await supabaseService.updateSharedProfile(
                userId: currentUserId,
                name: name,
                zodiacSign: zodiacSign,
                birthDate: birthDate
            )
            
            print("✅ Profile synchronized with partner")
        } catch {
            print("Error syncing profile with partner: \(error)")
        }
    }
    
    func loadPartnershipStatus() async {
        do {
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
            let status = try await supabaseService.getPartnershipStatus(userId: currentUserId)
            
            await MainActor.run {
                self.partnershipStatus = PartnershipStatus.fromString(status)
                self.isConnected = status == "active"
            }
            
            // If connected, load partner profile
            if status == "active" {
                let partnerProfile = try await supabaseService.getPartnerProfile(userId: currentUserId)
                await MainActor.run {
                    self.partnerProfile = partnerProfile
                }
            }
        } catch {
            print("Error loading partnership status: \(error)")
        }
    }
    
    private func getCurrentUser() -> User? {
        // This would come from AppState
        return User(name: "Current User", birthDate: Date())
    }
    
    private func savePartnerData() {
        if let encoded = try? JSONEncoder().encode(partner) {
            userDefaults.set(encoded, forKey: "partner")
        }
        userDefaults.set(isConnected, forKey: "isConnected")
    }
    
    private func loadPartnerData() {
        if let data = userDefaults.data(forKey: "partner"),
           let partnerData = try? JSONDecoder().decode(User.self, from: data) {
            partner = partnerData
        }
        
        isConnected = userDefaults.bool(forKey: "isConnected")
    }
    
    private func loadPartnerProfilePhoto(partnerId: String) async {
        do {
            // Load partner profile photo from Supabase
            if let photoData = try await supabaseService.downloadProfilePhoto(userId: partnerId),
               let image = UIImage(data: photoData) {
                await MainActor.run {
                    self.partnerProfilePhoto = image
                }
                print("✅ Partner profile photo loaded successfully")
            } else {
                print("📱 No partner profile photo found")
            }
        } catch {
            print("❌ Error loading partner profile photo: \(error)")
        }
    }
} 