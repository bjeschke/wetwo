//
//  PartnerManager.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import SwiftUI
import FirebaseAuth

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

@MainActor
class PartnerManager: ObservableObject, Sendable {
    static let shared = PartnerManager()
    
    @Published var partner: User?
    @Published var isConnected: Bool = false
    @Published var connectionCode: String = ""
    @Published var ownConnectionCode: String = ""
    @Published var qrCodeImage: UIImage?
    @Published var isGeneratingCode: Bool = false
    @Published var partnershipStatus: PartnershipStatus = .notConnected
    @Published var partnerProfile: Profile?
    @Published var partnerProfilePhoto: UIImage?
    @Published var pendingInvitation: BackendInvitation?
    @Published var hasPendingInvitation: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let dataService = ServiceFactory.shared.getCurrentService()
    private var invitationCheckTimer: Timer?
    
    private func getCurrentUserId() async -> String? {
        // Get Firebase Auth UID
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No Firebase authenticated user")
            return nil
        }
        
        print("✅ Got Firebase UID: \(uid)")
        return uid
    }
    
    private init() {
        loadPartnerData()
        loadOwnConnectionCode()
        Task {
            await checkForPendingInvitations()
        }
        startInvitationCheckTimer()
    }
    
    deinit {
        invitationCheckTimer?.invalidate()
    }
    
    private func startInvitationCheckTimer() {
        // Check for pending invitations every 30 seconds
        invitationCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.checkForPendingInvitations()
            }
        }
    }
    
    func loadOwnConnectionCode() {
        // Load partner code from backend (stored during signup)
        if let storedCode = UserDefaults.standard.string(forKey: "userPartnerCode") {
            ownConnectionCode = storedCode
            print("✅ Loaded partner code from backend: \(storedCode)")
            generateQRCode()
        } else {
            // Fetch from backend
            ownConnectionCode = "Lädt..."
            print("⚠️ No partner code found locally, fetching from backend")
            Task {
                await refreshConnectionCodeFromBackend()
            }
        }
    }
    
    func refreshConnectionCodeFromBackend() async {
        // Fetch the current user's partner code from backend
        do {
            let backendService = BackendService.shared
            if let partnerCode = try await backendService.getUserPartnerCode() {
                await MainActor.run {
                    self.ownConnectionCode = partnerCode
                    UserDefaults.standard.set(partnerCode, forKey: "userPartnerCode")
                    self.generateQRCode()
                    print("✅ Refreshed partner code from backend: \(partnerCode)")
                }
            } else {
                print("⚠️ No partner code found in user profile")
                // Fallback: try to get from partnerships if BackendService
                if let backendService = dataService as? BackendService {
                    let partnerships = try await backendService.getPartnerships()
                    if let userPartnership = partnerships.first {
                        await MainActor.run {
                            self.ownConnectionCode = userPartnership.connection_code
                            UserDefaults.standard.set(userPartnership.connection_code, forKey: "userPartnerCode")
                            self.generateQRCode()
                            print("✅ Refreshed partner code from partnerships: \(userPartnership.connection_code)")
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to refresh partner code from backend: \(error)")
        }
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
        guard let partnership = try await dataService.findPartnershipByCode(code) else {
            throw PartnerError.invalidCode
        }
        
        // For now, create a basic Profile from the partnership
        // In a real implementation, you would fetch the partner's profile details
        let partnerProfile = Profile(
            id: partnership.partner_id,
            name: "Partner", // This would come from the partner's profile
            zodiac_sign: "aries", // This would come from the partner's profile
            birth_date: "1990-01-01", // This would come from the partner's profile
            profile_photo_url: nil,
            relationship_status: "single",
            has_children: "false",
            children_count: "0",
            push_token: nil,
            created_at: Date(),
            updated_at: Date()
        )
        
        // Create partnership
        guard let currentUserId = await getCurrentUserId() else {
            throw PartnerError.networkError
        }
        let _ = try await dataService.createPartnership(
            userId: currentUserId,
            partnerId: String(partnerProfile.id),
            connectionCode: code
        )
        
        // Update local state
        await MainActor.run {
            self.isConnected = true
            self.partnerProfile = partnerProfile
            self.partnershipStatus = .connected
            self.savePartnerData()
        }
        
        // Subscribe to partner updates
        try await dataService.subscribeToPartnerUpdates(userId: currentUserId) { [weak self] updatedProfile in
            DispatchQueue.main.async {
                self?.partnerProfile = updatedProfile
            }
        }
        
        // Load partner profile photo
        await loadPartnerProfilePhoto(partnerId: String(partnerProfile.id))
        
        // Send push notification to partner about connection
        await notifyPartnerAboutConnection(partnerId: String(partnerProfile.id))
    }
    
    func disconnectPartner() async {
        do {
            guard let currentUserId = await getCurrentUserId() else {
                throw PartnerError.networkError
            }
            try await dataService.disconnectPartner(userId: currentUserId)
            
            await MainActor.run {
                self.partner = nil
                self.isConnected = false
                self.partnerProfile = nil
                self.partnershipStatus = .notConnected
                self.savePartnerData()
            }
            
            // Unsubscribe from partner updates
            try await dataService.unsubscribeFromPartnerUpdates(userId: currentUserId)
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
            userId: partner?.id ?? "",
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
    
    // MARK: - Push Notifications
    
    private func notifyPartnerAboutConnection(partnerId: String) async {
        guard let currentUserId = await getCurrentUserId() else { return }
        
        do {
            let title = "💕 Neuer Partner verbunden!"
            let body = "Jemand hat sich mit dir verbunden"
            let data = [
                "type": "partner_connected",
                "user_id": currentUserId
            ]
            
            try await dataService.sendPushNotificationToPartner(
                userId: currentUserId,
                partnerId: partnerId,
                title: title,
                body: body,
                data: data
            )
        } catch {
            print("Failed to send connection notification to partner: \(error)")
        }
    }
    
    // MARK: - Profile Synchronization
    func syncProfileWithPartner(name: String, zodiacSign: String, birthDate: Date) async {
        do {
            guard let currentUserId = await getCurrentUserId() else {
                throw PartnerError.networkError
            }
            try await dataService.updateSharedProfile(
                userId: currentUserId,
                updates: [
                    "name": name,
                    "zodiac_sign": zodiacSign,
                    "birthDate": birthDate.ISO8601String()
                ]
            )
            
            print("✅ Profile synchronized with partner")
        } catch {
            print("Error syncing profile with partner: \(error)")
        }
    }
    
    func checkForPendingInvitations() async {
        do {
            let backendService = BackendService.shared
            let invitations = try await backendService.getPendingInvitations()
            
            if let firstInvitation = invitations.first {
                await MainActor.run {
                    self.pendingInvitation = firstInvitation
                    self.hasPendingInvitation = true
                    print("✅ Found pending invitation from: \(firstInvitation.fromUser?.name ?? "Unknown")")
                }
            } else {
                await MainActor.run {
                    self.pendingInvitation = nil
                    self.hasPendingInvitation = false
                }
            }
        } catch {
            print("❌ Error checking for pending invitations: \(error)")
        }
    }
    
    func acceptInvitation() async {
        guard let invitation = pendingInvitation else { return }
        
        do {
            let backendService = BackendService.shared
            let partnership = try await backendService.acceptInvitation(invitationId: invitation.id)
            
            print("✅ Invitation accepted, partnership created: \(partnership)")
            
            // Clear the pending invitation
            await MainActor.run {
                self.pendingInvitation = nil
                self.hasPendingInvitation = false
                self.isConnected = true
                self.partnershipStatus = .connected
            }
            
            // Reload partnership status
            await loadPartnershipStatus()
            
            // Save partner data
            savePartnerData()
            
        } catch {
            print("❌ Error accepting invitation: \(error)")
        }
    }
    
    func rejectInvitation() async {
        guard let invitation = pendingInvitation else { return }
        
        do {
            let backendService = BackendService.shared
            try await backendService.rejectInvitation(invitationId: invitation.id)
            
            print("✅ Invitation rejected")
            
            // Clear the pending invitation
            await MainActor.run {
                self.pendingInvitation = nil
                self.hasPendingInvitation = false
            }
        } catch {
            print("❌ Error rejecting invitation: \(error)")
        }
    }
    
    func loadPartnershipStatus() async {
        do {
            guard let currentUserId = await getCurrentUserId() else {
                throw PartnerError.networkError
            }
            let status = try await dataService.getPartnershipStatus(userId: currentUserId)
            
            await MainActor.run {
                self.partnershipStatus = status
                self.isConnected = status != .notConnected
            }
            
            // If connected, load partner profile
            if case .connected = status {
                let partnerProfile = try await dataService.getPartnerProfile(userId: currentUserId)
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
            // Load partner profile photo from current service
            if let photoData = try await dataService.downloadProfilePhoto(userId: partnerId),
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