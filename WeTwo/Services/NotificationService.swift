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
    
    private let supabaseService = SupabaseService.shared
    
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
        
        // Send token to Supabase
        Task {
            await sendPushTokenToSupabase(token)
        }
    }
    
    private func sendPushTokenToSupabase(_ token: String) async {
        guard let userId = supabaseService.currentUserId else { return }
        
        do {
            // Update user's push token in profiles table
            try await supabaseService.updateProfilePushToken(userId: userId, pushToken: token)
            print("✅ Push token sent to Supabase successfully")
        } catch {
            print("❌ Failed to send push token to Supabase: \(error)")
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
        
        if identifier == "dailyMoodReminder" {
            // Navigate to mood input
            // This would be handled by the app's navigation system
        }
        
        completionHandler()
    }
}
