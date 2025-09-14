import SwiftUI

// MARK: - Playful Stat Card
struct PlayfulStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
                .scaleEffect(isPressed ? 1.2 : 1.0)
            
            Text(value)
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundStyle(gradient)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(
                    color: DesignSystem.Colors.shadowColor,
                    radius: isPressed ? 2 : 8,
                    x: 0,
                    y: isPressed ? 1 : 4
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(DesignSystem.Animation.springBouncy) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animation.springBouncy) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Playful Memory Card
struct PlayfulMemoryCard: View {
    let memory: Memory
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var rotation: Double = 0
    
    private var moodEmoji: String {
        switch memory.mood_level {
        case "1": return "😢"
        case "2": return "😟"
        case "3": return "😐"
        case "4": return "😊"
        case "5": return "😁"
        default: return "😐"
        }
    }
    
    private var moodColor: Color {
        switch memory.mood_level {
        case "1": return .red
        case "2": return .orange
        case "3": return .yellow
        case "4": return .green
        case "5": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with mood and date
            HStack {
                Text(moodEmoji)
                    .font(.title)
                    .rotationEffect(.degrees(rotation))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(memory.date)  // Already formatted as YYYY-MM-DD string
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(
                            DesignSystem.Gradients.primaryGradient
                        )
                    
                    Text(memory.title)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if memory.is_shared == "true" {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.heartRed)
                        .pulsingHeart()
                }
            }
            
            // Photo if available
            if memory.photo_data != nil {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accentMint.opacity(0.3),
                                DesignSystem.Colors.accentBlue.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)
                    .overlay(
                        Text("📷")
                            .font(.system(size: 40))
                            .opacity(0.7)
                    )
            }
            
            // Description if available
            if let description = memory.description, !description.isEmpty {
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(DesignSystem.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(
                    color: moodColor.opacity(0.2),
                    radius: isHovered ? 15 : 10,
                    x: 0,
                    y: isHovered ? 8 : 5
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                rotation = 10
            }
        }
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.springSmooth) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Playful Tab Bar
struct PlayfulTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, title: String)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                PlayfulTabItem(
                    icon: tabs[index].icon,
                    title: tabs[index].title,
                    isSelected: selectedTab == index,
                    action: { 
                        withAnimation(DesignSystem.Animation.springBouncy) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(
                    color: DesignSystem.Colors.shadowColor,
                    radius: 20,
                    x: 0,
                    y: -5
                )
        )
    }
}

struct PlayfulTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var bounce = false
    
    var body: some View {
        Button(action: {
            action()
            withAnimation(DesignSystem.Animation.springBouncy) {
                bounce.toggle()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        isSelected ? 
                        DesignSystem.Gradients.primaryGradient :
                        LinearGradient(
                            colors: [DesignSystem.Colors.textSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .rotationEffect(.degrees(bounce ? 10 : 0))
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(
                        isSelected ?
                        DesignSystem.Colors.primaryPink :
                        DesignSystem.Colors.textSecondary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.s)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Animated Background
struct AnimatedBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            DesignSystem.Gradients.backgroundGradient
            
            // Floating shapes
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(
                        DesignSystem.Colors.primaryPink.opacity(0.05)
                    )
                    .frame(
                        width: CGFloat.random(in: 100...200),
                        height: CGFloat.random(in: 100...200)
                    )
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 20)
                    .offset(
                        x: animate ? CGFloat.random(in: -50...50) : 0,
                        y: animate ? CGFloat.random(in: -50...50) : 0
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 10...20))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}