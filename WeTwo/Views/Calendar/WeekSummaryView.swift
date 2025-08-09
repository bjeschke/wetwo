//
//  WeekSummaryView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct WeekSummaryView: View {
    let weekSummary: WeeklyMoodSummary
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Text("📊")
                            .font(.system(size: 60))
                        
                        Text("Weekly Insights")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your mood journey this week")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Mood statistics
                    moodStatisticsCard
                    
                    // Mood trend analysis
                    moodTrendCard
                    
                    // Weekly insights
                    insightsCard
                    
                    // Recommendations
                    recommendationsCard
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var moodStatisticsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("📈")
                    .font(.title)
                
                Text("Mood Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                HStack {
                    Text("Average Mood:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(weekSummary.mostFrequentMood.emoji)
                        .font(.title2)
                    
                    Text(weekSummary.averageMood.isFinite ? String(format: "%.1f", weekSummary.averageMood) : "3.0")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Most Common:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(weekSummary.mostFrequentMood.emoji)
                        .font(.title2)
                    
                    Text(weekSummary.mostFrequentMood.description)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Mood Range:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("1-5")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
    }
    
    private var moodTrendCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("📉")
                    .font(.title)
                
                Text("Mood Trend")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                HStack {
                    Text("Overall Trend:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(weekSummary.moodTrend.emoji)
                        .font(.title2)
                    
                    Text(weekSummary.moodTrend.rawValue.capitalized)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(trendColor)
                }
                
                // Trend description
                Text(trendDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 5)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
    }
    
    private var insightsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("💡")
                    .font(.title)
                
                Text("Weekly Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(weekSummary.insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.blue)
                        
                        Text(insight)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
    }
    
    private var recommendationsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("💝")
                    .font(.title)
                
                Text("Recommendations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(getRecommendations(), id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 10) {
                        Text("💕")
                            .font(.body)
                        
                        Text(recommendation)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
    }
    
    // MARK: - Helper Methods
    
    private var trendColor: Color {
        switch weekSummary.moodTrend {
        case .improving:
            return .green
        case .declining:
            return .red
        case .stable:
            return .blue
        }
    }
    
    private var trendDescription: String {
        switch weekSummary.moodTrend {
        case .improving:
            return "Your mood has been getting better throughout the week. Keep up the positive energy!"
        case .declining:
            return "Your mood has been trending downward. Consider talking to your partner about what's on your mind."
        case .stable:
            return "Your mood has been consistent this week. You're maintaining good emotional balance."
        }
    }
    
    private func getRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if weekSummary.averageMood < 3.0 {
            recommendations.append("Try to schedule some quality time with your partner this weekend")
            recommendations.append("Consider sharing your feelings more openly with your partner")
        } else if weekSummary.averageMood > 4.0 {
            recommendations.append("Your positive energy is contagious! Share it with your partner")
            recommendations.append("Plan a special date night to celebrate your good mood")
        } else {
            recommendations.append("Your mood is balanced - perfect time for meaningful conversations")
            recommendations.append("Try a new activity together to keep things exciting")
        }
        
        if weekSummary.moodTrend == .declining {
            recommendations.append("Reach out to your partner for support and understanding")
        }
        
        return recommendations
    }
}

#Preview {
    WeekSummaryView(weekSummary: WeeklyMoodSummary(
        weekStartDate: Date(),
        averageMood: 3.5,
        moodTrend: .improving,
        mostFrequentMood: .happy,
        insights: ["You've been more positive this week!", "Great communication with your partner"]
    ))
} 