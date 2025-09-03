import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @StateObject private var partnerManager = PartnerManager.shared
    @StateObject private var moodManager = MoodManager()
    @StateObject private var memoryManager = MemoryManager()
    
    var body: some View {
        Group {
            if appState.isOnboarding {
                OnboardingView()
                    .environmentObject(appState)
                    .environmentObject(authService)
                    .environmentObject(partnerManager)
                    .environmentObject(moodManager)
                    .environmentObject(memoryManager)
                    .environmentObject(notificationService)
                    .environmentObject(deepLinkHandler)
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(authService)
                    .environmentObject(partnerManager)
                    .environmentObject(moodManager)
                    .environmentObject(memoryManager)
                    .environmentObject(notificationService)
                    .environmentObject(deepLinkHandler)
            }
        }
        .purpleTheme()
        .accentColor(ColorTheme.primaryPurple)
        .environment(\.locale, Locale.current)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("emailConfirmed"))) { _ in
            // Email was confirmed, complete onboarding
            DispatchQueue.main.async {
                appState.isOnboarding = false
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var partnerManager: PartnerManager
    @EnvironmentObject var notificationService: NotificationService
    
    var body: some View {
        TabView {
            TodayView()
                .environmentObject(moodManager)
                .environmentObject(partnerManager)
                .environmentObject(appState)
                .environmentObject(notificationService)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Today")
                }
            
            CalendarView()
                .environmentObject(moodManager)
                .environmentObject(partnerManager)
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Kalender")
                }
            
            TimelineView()
                .environmentObject(moodManager)
                .environmentObject(partnerManager)
                .environmentObject(appState)
                .environmentObject(memoryManager)
                .tabItem {
                    Image(systemName: "clock")
                    Text("Timeline")
                }
            
            ActivityView()
                .environmentObject(moodManager)
                .environmentObject(partnerManager)
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("Activity")
                }
            
            RemindersView()
                .environmentObject(notificationService)
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "bell")
                    Text("Erinnerungen")
                }
            
            ProfileView()
                .environmentObject(appState)
                .environmentObject(partnerManager)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
        }
        .accentColor(ColorTheme.primaryPurple)
        .toolbarBackground(Color.gray.opacity(0.1), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainAppView()
} 