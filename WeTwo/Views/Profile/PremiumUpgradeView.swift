//
//  PremiumUpgradeView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct PremiumUpgradeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PremiumPlan = .monthly
    @State private var isProcessing = false
    
    private let plans: [PremiumPlan] = [.monthly, .yearly]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Content only
                    VStack(spacing: 20) {
                        Text("💎")
                            .font(.system(size: 60))
                    }
                    
                    // Features comparison
                    featuresSection
                    
                    // Pricing plans
                    pricingSection
                    
                    // Upgrade button
                    upgradeButton
                    
                    // Terms and privacy
                    termsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
            .purpleTheme()
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.accentBlue)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
                            ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Text("👑")
                    .font(.system(size: 60))
            }
            
            VStack(spacing: 10) {
                Text("Upgrade to Premium")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text("Unlock unlimited features and strengthen your relationship")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("✨")
                    .font(.title)
                
                Text("Premium Features")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                PremiumFeatureRow(
                    icon: "infinity",
                    title: "Unlimited Daily Insights",
                    description: "Get personalized insights every day"
                )
                
                PremiumFeatureRow(
                    icon: "camera.fill",
                    title: "Unlimited Photo Missions",
                    description: "Share unlimited photos with your partner"
                )
                
                PremiumFeatureRow(
                    icon: "heart.fill",
                    title: "Custom Love Messages",
                    description: "Generate personalized love messages"
                )
                
                PremiumFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    description: "Detailed mood trends and patterns"
                )
                
                PremiumFeatureRow(
                    icon: "star.fill",
                    title: "Priority Support",
                    description: "Get help when you need it most"
                )
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    private var pricingSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("💰")
                    .font(.title)
                
                Text("Choose Your Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                ForEach(plans, id: \.self) { plan in
                    PlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        action: { selectedPlan = plan }
                    )
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
    
    private var upgradeButton: some View {
        Button(action: processUpgrade) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isProcessing ? "Processing..." : "Upgrade to Premium")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
                            .background(
                    RoundedRectangle(cornerRadius: 27.5)
                        .fill(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .disabled(isProcessing)
        .padding(.horizontal, 20)
    }
    
    private var termsSection: some View {
        VStack(spacing: 10) {
            Text("By upgrading, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.caption)
                .foregroundColor(ColorTheme.accentBlue)
                
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.caption)
                .foregroundColor(ColorTheme.accentBlue)
            }
        }
    }
    
    private func processUpgrade() {
        isProcessing = true
        
        // Simulate purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            appState.isPremium = true
            UserDefaults.standard.set(true, forKey: "isPremium")
            isProcessing = false
            dismiss()
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ColorTheme.accentBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct PlanCard: View {
    let plan: PremiumPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(plan.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text(plan.price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(plan.period)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum PremiumPlan: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var title: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
    
    var description: String {
        switch self {
        case .monthly:
            return "Perfect for trying out"
        case .yearly:
            return "Best value (Save 40%)"
        }
    }
    
    var price: String {
        switch self {
        case .monthly:
            return "$4.99"
        case .yearly:
            return "$29.99"
        }
    }
    
    var period: String {
        switch self {
        case .monthly:
            return "per month"
        case .yearly:
            return "per year"
        }
    }
}

#Preview {
    PremiumUpgradeView()
        .environmentObject(AppState())
} 