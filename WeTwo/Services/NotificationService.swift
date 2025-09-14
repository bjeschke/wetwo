//
//  NotificationService.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var pushToken: String?
    
    private let dataService = ServiceFactory.shared.getCurrentService()
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("❌ Failed to request notification authorization: \(error)")
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Push Token Management
    
    func setPushToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        pushToken = token
        
        // Save token to UserDefaults
        UserDefaults.standard.set(token, forKey: "pushToken")
        
        // Send token to current service
        Task {
            await sendPushTokenToCurrentService(token)
        }
    }
    
    private func sendPushTokenToCurrentService(_ token: String) async {
        guard let userId = try? await dataService.getCurrentUserId() else { return }
        
        do {
            // Update user's push token in profiles table
            try await dataService.updateProfilePushToken(userId: userId, pushToken: token)
            print("✅ Push token sent to backend successfully")
        } catch {
            print("❌ Failed to send push token to backend: \(error)")
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval = 1.0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule local notification: \(error)")
            }
        }
    }
    
    // MARK: - Partner Notifications
    
    func notifyPartnerMoodUpdate(partnerName: String, moodLevel: String) {
        let title = "💕 Neue Stimmung von \(partnerName)"
        let body = "\(partnerName) hat seine Stimmung auf \(moodLevel) gesetzt"
        
        scheduleLocalNotification(title: title, body: body)
    }
    
    func notifyLoveMessageReceived(partnerName: String, message: String) {
        let title = "💌 Liebesnachricht von \(partnerName)"
        let body = message.count > 50 ? String(message.prefix(50)) + "..." : message
        
        scheduleLocalNotification(title: title, body: body)
    }
    
    func notifyPartnerConnected(partnerName: String) {
        let title = "💕 Partner verbunden!"
        let body = "Du bist jetzt mit \(partnerName) verbunden"
        
        scheduleLocalNotification(title: title, body: body)
    }
    
    func notifyPartnerDisconnected(partnerName: String) {
        let title = "💔 Partner getrennt"
        let body = "Die Verbindung zu \(partnerName) wurde getrennt"
        
        scheduleLocalNotification(title: title, body: body)
    }
    
    // MARK: - Daily Reminders
    
    func scheduleDailyReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "💕 Zeit für deine tägliche Stimmung!"
        content.body = "Wie fühlst du dich heute? Teile es mit deinem Partner."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "dailyMoodReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily reminder: \(error)")
            } else {
                print("✅ Daily reminder scheduled for \(hour):\(minute)")
            }
        }
    }
    
    func removeDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyMoodReminder"])
    }
    
    // MARK: - Invitation Notifications
    
    func handleInvitationNotification(from userName: String, code: String) {
        // Schedule a local notification for the invitation
        let content = UNMutableNotificationContent()
        content.title = "💕 Neue Partner-Einladung!"
        content.body = "\(userName) möchte sich mit dir verbinden."
        content.sound = .default
        content.categoryIdentifier = "partner_invitation"
        content.userInfo = [
            "type": "partner_invitation",
            "from_user": userName,
            "connection_code": code
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "invitation_\(code)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show invitation notification: \(error)")
            } else {
                print("✅ Invitation notification scheduled")
            }
        }
        
        // Also trigger a check for pending invitations
        Task {
            await PartnerManager.shared.checkForPendingInvitations()
        }
    }
    
    // MARK: - Calendar Reminders
    
    func scheduleCalendarReminder(for entry: CalendarEntry, minutesBefore: Int = 60) {
        let reminderTime = entry.date.addingTimeInterval(-Double(minutesBefore * 60))
        
        guard reminderTime > Date() else {
            print("⚠️ Cannot schedule reminder for past event")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "📅 Erinnerung: \(entry.title)"
        content.body = entry.description.isEmpty ? "Dein Termin beginnt in \(minutesBefore) Minuten" : entry.description
        content.sound = .default
        content.categoryIdentifier = "calendar_reminder"
        content.userInfo = [
            "calendar_entry_id": entry.id,
            "entry_title": entry.title,
            "entry_date": entry.date.timeIntervalSince1970
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "calendar_\(entry.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule calendar reminder: \(error)")
            } else {
                print("✅ Calendar reminder scheduled for: \(entry.title) at \(reminderTime)")
            }
        }
    }
    
    func cancelCalendarReminder(for entryId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["calendar_\(entryId)"]
        )
    }
    
    func scheduleCustomReminder(title: String, body: String, at date: Date, identifier: String) {
        guard date > Date() else {
            print("⚠️ Cannot schedule reminder for past date")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "custom_reminder"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: date.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule custom reminder: \(error)")
            } else {
                print("✅ Custom reminder scheduled: \(title)")
            }
        }
    }
    
    func getAllPendingReminders() async -> [UNNotificationRequest] {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let identifier = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        
        if identifier == "dailyMoodReminder" {
            // Navigate to mood input
            // This would be handled by the app's navigation system
        } else if identifier.starts(with: "invitation_") {
            // Handle invitation notification tap
            Task {
                await PartnerManager.shared.checkForPendingInvitations()
            }
            // Navigate to Today view to show the invitation
            NotificationCenter.default.post(name: Notification.Name("ShowInvitation"), object: nil)
        }
        
        completionHandler()
    }
}
