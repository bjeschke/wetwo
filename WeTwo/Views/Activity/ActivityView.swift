//
//  ActivityView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 07.08.25.
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var partnerManager: PartnerManager
    
    @State private var showingGame = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerSection
                    
                    // Game section - only show "Who Knows Better?" game
                    gameSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 100)
            }
            .purpleTheme()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingGame) {
                WhoKnowsBetterGameView()
                    .environmentObject(partnerManager)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Text("🎮")
                .font(.system(size: 50))
            
            VStack(spacing: 10) {
                Text(NSLocalizedString("activity_title", comment: "Activity title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(NSLocalizedString("activity_subtitle", comment: "Activity subtitle"))
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(ColorTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
        )
    }
    
    private var gameSection: some View {
        VStack(spacing: 20) {
            // Only show "Who Knows Better?" game
            GameCard(gameType: .whoKnowsBetter) {
                showingGame = true
            }
        }
    }
}



enum GameType {
    case whoKnowsBetter
    
    var emoji: String {
        switch self {
        case .whoKnowsBetter:
            return "👥"
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .whoKnowsBetter:
            return NSLocalizedString("game_who_knows_better", comment: "Who Knows Better?")
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .whoKnowsBetter:
            return NSLocalizedString("game_who_knows_better_desc", comment: "Test how well you know each other")
        }
    }
}



struct GameCard: View {
    let gameType: GameType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(gameType.emoji)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(gameType.localizedTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(gameType.localizedDescription)
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(ColorTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ActivityView()
        .environmentObject(AppState())
        .environmentObject(PartnerManager())
} 