import SwiftUI

struct MainAppView: View {
    @StateObject private var appState = AppState()
    @StateObject private var partnerManager = PartnerManager()
    @StateObject private var moodManager = MoodManager()
    @StateObject private var memoryManager = MemoryManager()
    @StateObject private var gptService = GPTService()
    
    var body: some View {
        Group {
            if appState.isOnboarding {
                OnboardingView()
                    .environmentObject(appState)
                    .environmentObject(partnerManager)
                    .environmentObject(moodManager)
                    .environmentObject(memoryManager)
                    .environmentObject(gptService)
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(partnerManager)
                    .environmentObject(moodManager)
                    .environmentObject(memoryManager)
                    .environmentObject(gptService)
            }
        }
        .purpleTheme()
        .accentColor(ColorTheme.primaryPurple)
        .environment(\.locale, Locale.current)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text(NSLocalizedString("tab_today", comment: "Today tab"))
                }
            
            TimelineView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text(NSLocalizedString("tab_timeline", comment: "Timeline tab"))
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text(NSLocalizedString("tab_calendar", comment: "Calendar tab"))
                }
            
            ActivityView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text(NSLocalizedString("tab_activity", comment: "Activity tab"))
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text(NSLocalizedString("tab_profile", comment: "Profile tab"))
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