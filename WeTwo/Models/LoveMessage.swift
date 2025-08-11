//
//  LoveMessage.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 07.08.25.
//

import Foundation

struct LoveMessage: Codable, Identifiable {
    let id: String
    let senderId: UUID
    let receiverId: UUID
    let message: String
    let timestamp: Date
    let isRead: Bool
    
    init(senderId: UUID, receiverId: UUID, message: String) {
        self.id = UUID().uuidString
        self.senderId = senderId
        self.receiverId = receiverId
        self.message = message
        self.timestamp = Date()
        self.isRead = false
    }
    
    init(id: String, senderId: UUID, receiverId: UUID, message: String, timestamp: Date, isRead: Bool) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

// MARK: - Love Message Manager
class LoveMessageManager: ObservableObject {
    @Published var receivedMessages: [LoveMessage] = []
    @Published var sentMessages: [LoveMessage] = []
    @Published var unreadCount: Int = 0
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        loadMessages()
    }
    
    func sendLoveMessage(to partnerId: UUID, message: String) async throws {
        guard let currentUserId = getCurrentUserId() else {
            throw LoveMessageError.userNotFound
        }
        
        // Check if user is connected to a partner
        guard await PartnerManager.shared.isConnected else {
            throw LoveMessageError.notConnected
        }
        
        let loveMessage = LoveMessage(
            senderId: currentUserId,
            receiverId: partnerId,
            message: message
        )
        
        // Save to Supabase
        try await supabaseService.sendLoveMessage(
            to: partnerId,
            text: message
        )
        
        // Send push notification to partner
        await notifyPartnerAboutLoveMessage(partnerId: partnerId, message: message)
        
        // Update local state
        await MainActor.run {
            sentMessages.append(loveMessage)
        }
    }
    
    private func notifyPartnerAboutLoveMessage(partnerId: UUID, message: String) async {
        guard let currentUserId = getCurrentUserId() else { return }
        
        do {
            let title = "💌 Neue Liebesnachricht"
            let body = message.count > 50 ? String(message.prefix(50)) + "..." : message
            let data = [
                "type": "love_message",
                "message_id": UUID().uuidString,
                "sender_id": currentUserId.uuidString
            ]
            
            try await supabaseService.sendPushNotificationToPartner(
                userId: currentUserId,
                partnerId: partnerId,
                title: title,
                body: body,
                data: data
            )
        } catch {
            print("Failed to send push notification for love message: \(error)")
        }
    }
    
    func markAsRead(_ messageId: String) async throws {
        guard let messageUUID = UUID(uuidString: messageId) else { return }
        try await supabaseService.markMessageRead(messageUUID)
        
        await MainActor.run {
            if let index = receivedMessages.firstIndex(where: { $0.id == messageId }) {
                receivedMessages[index] = LoveMessage(
                    id: receivedMessages[index].id,
                    senderId: receivedMessages[index].senderId,
                    receiverId: receivedMessages[index].receiverId,
                    message: receivedMessages[index].message,
                    timestamp: receivedMessages[index].timestamp,
                    isRead: true
                )
            }
            updateUnreadCount()
        }
    }
    
    func loadMessages() {
        Task {
            do {
                guard let currentUserId = getCurrentUserId() else { return }
                let messages = try await supabaseService.conversation(with: currentUserId)
                await MainActor.run {
                    self.receivedMessages = messages.filter { $0.receiverId == currentUserId }
                    self.sentMessages = messages.filter { $0.senderId == currentUserId }
                    updateUnreadCount()
                }
            } catch {
                print("Error loading love messages: \(error)")
            }
        }
    }
    
    private func updateUnreadCount() {
        unreadCount = receivedMessages.filter { !$0.isRead }.count
    }
    
    private func getCurrentUserId() -> UUID? {
        // First try to get from SupabaseService (most reliable)
        if let supabaseUserId = supabaseService.currentUserId {
            print("✅ Got user ID from SupabaseService: \(supabaseUserId)")
            return supabaseUserId
        }
        
        // Fallback to secure storage (should be set during login/signup)
        do {
            let userIdString = try SecurityService.shared.secureLoadString(forKey: "currentUserId")
            if let userId = UUID(uuidString: userIdString) {
                print("✅ Got user ID from secure storage: \(userId)")
                return userId
            }
        } catch {
            print("⚠️ Error loading current user ID from secure storage: \(error)")
        }
        
        print("❌ No current user ID found in SupabaseService or secure storage")
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