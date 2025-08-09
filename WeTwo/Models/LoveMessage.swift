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
        
        let loveMessage = LoveMessage(
            senderId: currentUserId,
            receiverId: partnerId,
            message: message
        )
        
        // Save to Supabase
        try await supabaseService.saveLoveMessage(
            senderId: currentUserId.uuidString,
            receiverId: partnerId.uuidString,
            message: message
        )
        
        // TODO: Send push notification to receiver
        // This could be done through:
        // 1. Supabase Edge Functions
        // 2. Firebase Cloud Messaging
        // 3. Apple Push Notification Service (APNs)
        
        // Update local state
        await MainActor.run {
            sentMessages.append(loveMessage)
        }
    }
    
    func markAsRead(_ messageId: String) async throws {
        try await supabaseService.markLoveMessageAsRead(messageId: messageId)
        
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
                let messages = try await supabaseService.getLoveMessages(userId: currentUserId.uuidString)
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
        guard let userIdString = UserDefaults.standard.string(forKey: "currentUserId"),
              let userId = UUID(uuidString: userIdString) else {
            return nil
        }
        return userId
    }
}

enum LoveMessageError: Error, LocalizedError {
    case userNotFound
    case partnerNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return NSLocalizedString("love_message_error_user_not_found", comment: "User not found")
        case .partnerNotFound:
            return NSLocalizedString("love_message_error_partner_not_found", comment: "Partner not found")
        case .networkError:
            return NSLocalizedString("love_message_error_network", comment: "Network error")
        }
    }
} 