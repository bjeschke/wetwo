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
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackgroundView()
            
            // Content
            VStack(spacing: 0) {
                // Tab content
                Group {
                    switch selectedTab {
                    case 0:
                        TodayView()
                            .environmentObject(moodManager)
                            .environmentObject(partnerManager)
                            .environmentObject(appState)
                            .environmentObject(notificationService)
                    case 1:
                        CalendarView()
                            .environmentObject(moodManager)
                            .environmentObject(partnerManager)
                            .environmentObject(appState)
                    case 2:
                        TimelineView()
                            .environmentObject(moodManager)
                            .environmentObject(partnerManager)
                            .environmentObject(appState)
                            .environmentObject(memoryManager)
                    case 3:
                        ActivityView()
                            .environmentObject(moodManager)
                            .environmentObject(partnerManager)
                            .environmentObject(appState)
                    case 4:
                        RemindersView()
                            .environmentObject(notificationService)
                            .environmentObject(appState)
                    case 5:
                        ProfileView()
                            .environmentObject(appState)
                            .environmentObject(partnerManager)
                    default:
                        TodayView()
                            .environmentObject(moodManager)
                            .environmentObject(partnerManager)
                            .environmentObject(appState)
                            .environmentObject(notificationService)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
                Spacer(minLength: 0)
                
                // Custom playful tab bar
                PlayfulTabBar(
                    selectedTab: $selectedTab,
                    tabs: [
                        (icon: "heart.fill", title: "Today"),
                        (icon: "calendar", title: "Kalender"),
                        (icon: "clock", title: "Timeline"),
                        (icon: "gamecontroller", title: "Activity"),
                        (icon: "bell", title: "Erinnerungen"),
                        (icon: "person.circle.fill", title: "Profil")
                    ]
                )
                .padding(.bottom, 10)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainAppView()
} 