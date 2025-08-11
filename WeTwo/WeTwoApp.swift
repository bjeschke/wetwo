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
                    setupBackendService()
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
    
    private func setupBackendService() {
        // Configure the service factory for the current environment
        ServiceFactory.shared.configureForEnvironment()
        
        // Print configuration information
        BackendConfig.printConfiguration()
        
        // Test backend connection
        Task {
            print("🧪 Starting backend connection test...")
            if let backendService = ServiceFactory.shared.getCurrentService() as? BackendService {
                await backendService.testBackendConnection()
            }
            
            // Validate the current service
            let isValid = await ServiceFactory.shared.validateCurrentService()
            if isValid {
                print("✅ Backend service is healthy")
            } else {
                print("⚠️ Backend service validation failed, attempting fallback")
                await ServiceFactory.shared.fallbackToSupabaseIfNeeded()
            }
        }
    }
}
