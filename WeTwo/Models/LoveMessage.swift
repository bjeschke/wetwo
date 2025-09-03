//
//  LoveMessage.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 07.08.25.
//

import Foundation
import SwiftUI
import FirebaseAuth

// MARK: - Love Message Model

struct LoveMessage: Identifiable, Codable, Sendable {
    let id: Int  // Backend uses Long/Int for id
    let message: String
    let timestamp: Date
    var isRead: Bool
    let sender: LoveMessageUser?
    let receiver: LoveMessageUser?
    
    // Computed properties for compatibility
    var senderId: Int {
        return sender?.id ?? 0
    }
    
    var receiverId: Int {
        return receiver?.id ?? 0
    }
    
    init(id: Int, message: String, timestamp: Date = Date(), isRead: Bool = false, sender: LoveMessageUser? = nil, receiver: LoveMessageUser? = nil) {
        self.id = id
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.sender = sender
        self.receiver = receiver
    }
    
    // Legacy init for compatibility
    init(id: Int = 0, senderId: Int, receiverId: Int, message: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.sender = LoveMessageUser(id: senderId, email: nil, name: nil, firebaseUid: nil)
        self.receiver = LoveMessageUser(id: receiverId, email: nil, name: nil, firebaseUid: nil)
    }
}

// Simplified user structure for love messages
struct LoveMessageUser: Codable, Sendable {
    let id: Int
    let email: String?
    let name: String?
    let firebaseUid: String?
}

// MARK: - Love Message Manager

@MainActor
final class LoveMessageManager: ObservableObject {
    @Published var sentMessages: [LoveMessage] = []
    @Published var receivedMessages: [LoveMessage] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    
    private let dataService = ServiceFactory.shared.getCurrentService()
    
    init() {
        loadMessages()
    }
    
    func sendMessage(_ message: String, to partnerId: Int) async throws {
        guard let currentUserId = getCurrentUserId() else {
            throw LoveMessageError.userNotFound
        }
        
        // Backend handles creating the message with proper IDs
        // We just need to send the message text and recipient ID
        
        // Save to current service
        try await dataService.sendLoveMessage(
            to: String(partnerId),
            text: message
        )
        
        // Send push notification to partner
        await notifyPartnerAboutLoveMessage(partnerId: partnerId, message: message)
        
        // Update local state
        // Reload messages to get the newly sent one
        loadMessages()
    }
    
    private func notifyPartnerAboutLoveMessage(partnerId: Int, message: String) async {
        guard let currentUserId = getCurrentUserId() else { return }
        
        do {
            let title = "💌 Neue Liebesnachricht"
            let body = message.count > 50 ? String(message.prefix(50)) + "..." : message
            let data = [
                "type": "love_message",
                "message_id": String(Int.random(in: 1...999999)),
                "sender_id": String(currentUserId)
            ]
            
            try await dataService.sendPushNotificationToPartner(
                userId: String(currentUserId),
                partnerId: String(partnerId),
                title: title,
                body: body,
                data: data
            )
        } catch {
            print("Failed to send push notification for love message: \(error)")
        }
    }
    
    func markAsRead(_ messageId: Int) async throws {
        // Note: markMessageRead method might not be available in all services
        // This would need to be implemented in the service layer
        
        await MainActor.run {
            if let index = receivedMessages.firstIndex(where: { $0.id == messageId }) {
                var updatedMessage = receivedMessages[index]
                updatedMessage.isRead = true
                receivedMessages[index] = updatedMessage
            }
            updateUnreadCount()
        }
    }
    
    func loadMessages() {
        Task {
            do {
                guard let currentUserId = getCurrentUserId() else { return }
                
                // Use the backend service if available
                if let backendService = dataService as? BackendService {
                    let messages = try await backendService.getLoveMessages()
                    await MainActor.run {
                        // Filter messages based on sender/receiver
                        self.receivedMessages = messages.filter { loveMessage in
                            // Check if current user is the receiver
                            return loveMessage.receiver?.id == currentUserId
                        }
                        self.sentMessages = messages.filter { loveMessage in
                            // Check if current user is the sender
                            return loveMessage.sender?.id == currentUserId
                        }
                        updateUnreadCount()
                    }
                } else {
                    // Fallback to conversation method for other services
                    let messages = try await dataService.conversation(with: String(currentUserId))
                    await MainActor.run {
                        self.receivedMessages = messages.filter { $0.receiverId == currentUserId }
                        self.sentMessages = messages.filter { $0.senderId == currentUserId }
                        updateUnreadCount()
                    }
                }
            } catch {
                print("Error loading love messages: \(error)")
            }
        }
    }
    
    private func updateUnreadCount() {
        unreadCount = receivedMessages.filter { !$0.isRead }.count
    }
    
    private func getCurrentUserId() -> Int? {
        // Get Firebase Auth UID
        guard let firebaseUid = Auth.auth().currentUser?.uid else {
            print("❌ No Firebase authenticated user")
            return nil
        }
        
        print("✅ Got Firebase UID: \(firebaseUid)")
        
        // TODO: Backend should handle mapping between Firebase UID and numeric ID
        // For now, this won't work with real Firebase UIDs (they're alphanumeric)
        return Int(firebaseUid)
        return nil
    }
}

enum LoveMessageError: Error, LocalizedError {
    case userNotFound
    case partnerNotFound
    case notConnected
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return NSLocalizedString("love_message_error_user_not_found", comment: "User not found")
        case .partnerNotFound:
            return NSLocalizedString("love_message_error_partner_not_found", comment: "Partner not found")
        case .notConnected:
            return NSLocalizedString("love_message_error_not_connected", comment: "Not connected to partner")
        case .networkError:
            return NSLocalizedString("love_message_error_network", comment: "Network error")
        }
    }
} 