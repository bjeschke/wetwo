import SwiftUI

struct ComponentSize {
    struct Icon {
        static let tiny: CGFloat = 12
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
    }

    struct Button {
        static let small: CGFloat = 36
        static let medium: CGFloat = 44
        static let large: CGFloat = 52
    }

    struct Input {
        static let height: CGFloat = 44
    }

    static let minTouchTarget: CGFloat = 44
}

struct DesignSystem {
    
    struct Colors {
        // Dark purple theme colors (using ColorTheme values)
        static let primaryPurple = Color(red: 0.2, green: 0.1, blue: 0.4)  // Dark purple background
        static let secondaryPurple = Color(red: 0.25, green: 0.15, blue: 0.5)  // Darker purple
        
        // Accent colors for dark theme
        static let accentPink = Color(red: 0.9, green: 0.3, blue: 0.6)  // Bright pink accent
        static let accentBlue = Color(red: 0.3, green: 0.7, blue: 0.9)  // Bright blue accent
        static let primaryPink = Color(red: 0.9, green: 0.3, blue: 0.6)  // Primary pink (same as accentPink)
        static let accentMint = Color(red: 0.3, green: 0.85, blue: 0.7)  // Mint accent
        
        // Dark theme backgrounds
        static let backgroundGradientTop = Color(red: 0.2, green: 0.1, blue: 0.4)
        static let backgroundGradientBottom = Color(red: 0.15, green: 0.05, blue: 0.35)
        
        // Card backgrounds for dark theme
        static let cardBackground = Color(red: 0.4, green: 0.2, blue: 0.7).opacity(0.9)  // Purple card
        static let cardBackgroundSecondary = Color(red: 0.45, green: 0.25, blue: 0.75).opacity(0.9)
        static let shadowColor = Color.black.opacity(0.4)  // Darker shadows for dark theme
        
        // Text colors for dark theme
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.9, green: 0.9, blue: 0.9)
        static let textTertiary = Color(red: 0.7, green: 0.7, blue: 0.75)
        
        // Additional accent colors
        static let heartRed = Color(red: 0.95, green: 0.3, blue: 0.4)
        static let success = Color(red: 0.3, green: 0.85, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.65, blue: 0.0)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
        static let accentYellow = Color(red: 1.0, green: 0.8, blue: 0.2)
    }
    
    struct Gradients {
        // Dark theme gradients
        static let primaryGradient = LinearGradient(
            colors: [Colors.primaryPurple, Colors.secondaryPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundGradient = LinearGradient(
            colors: [Colors.backgroundGradientTop, Colors.backgroundGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let cardGradient = LinearGradient(
            colors: [Colors.cardBackground, Colors.cardBackgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [Colors.accentPink, Colors.accentBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let buttonGradient = LinearGradient(
            colors: [Colors.accentPink, Colors.accentBlue],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let secondaryGradient = LinearGradient(
            colors: [Colors.accentYellow, Colors.accentPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .medium, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let round: CGFloat = 999
    }
    
    struct Animation {
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.25)
        static let springSmooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)
        static let easeInOutShort = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let easeInOutMedium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let easeInOutLong = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

struct PlayfulCardModifier: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.large
    var shadowRadius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(color: DesignSystem.Colors.shadowColor, radius: shadowRadius, x: 0, y: 5)
            )
    }
}

struct PlayfulButtonStyle: ButtonStyle {
    var backgroundColor: LinearGradient = DesignSystem.Gradients.primaryGradient
    var foregroundColor: Color = .white
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.vertical, DesignSystem.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.round)
                    .fill(backgroundColor)
                    .shadow(color: DesignSystem.Colors.shadowColor, radius: configuration.isPressed ? 2 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.springBouncy, value: configuration.isPressed)
    }
}

struct FloatingHeartView: View {
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1
    let delay: Double
    
    var body: some View {
        Image(systemName: "heart.fill")
            .foregroundColor(DesignSystem.Colors.heartRed.opacity(0.8))
            .font(.system(size: 20))
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: 2.0)
                        .delay(delay)
                        .repeatForever(autoreverses: false)
                ) {
                    offsetY = -100
                    opacity = 0
                }
            }
    }
}

struct PulsingHeartModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                }
            }
    }
}

extension View {
    func playfulCard(cornerRadius: CGFloat = DesignSystem.CornerRadius.large, shadowRadius: CGFloat = 10) -> some View {
        modifier(PlayfulCardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
    
    func pulsingHeart() -> some View {
        modifier(PulsingHeartModifier())
    }
}