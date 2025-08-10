//
//  WeTwoApp.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI
import UserNotifications

@main
struct WeTwoApp: App {
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environment(\.locale, Locale.current)
                .environmentObject(notificationService)
                .environmentObject(deepLinkHandler)
                .onAppear {
                    setupNotifications()
                }
                .onOpenURL { url in
                    print("🔗 Deep link received: \(url)")
                    deepLinkHandler.handleDeepLink(url)
                }
        }
    }
    
    private func setupNotifications() {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = notificationService
        
        // Request authorization
        Task {
            await notificationService.requestAuthorization()
        }
    }
}
