import SwiftUI

// MARK: - Standard Screen Layout
struct StandardScreenLayout<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                content
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.top, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xxl + 80) // Tab bar space
        }
        .background(
            LinearGradient(
                colors: [ColorTheme.primaryPurple, ColorTheme.secondaryPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Standard Card
struct StandardCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            content
        }
        .padding(DesignSystem.Spacing.m)
        .background(ColorTheme.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(
            color: Color.black.opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Standard Button
struct StandardButton: View {
    enum Size {
        case small, medium, large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 16  // body size
            case .medium: return 18  // headline size
            case .large: return 22  // title2 size
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return DesignSystem.Spacing.s
            case .medium: return DesignSystem.Spacing.m
            case .large: return DesignSystem.Spacing.l
            }
        }
    }
    
    enum Style {
        case primary, secondary, tertiary, destructive
    }
    
    let title: String
    let size: Size
    let style: Style
    let action: () -> Void
    @State private var isPressed = false
    
    init(_ title: String, size: Size = .medium, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: size.height)
                .frame(minWidth: 64) // Minimum touch target
                .background(background)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .shadow(
                    color: shadowColor,
                    radius: isPressed ? 2 : 6,
                    x: 0,
                    y: isPressed ? 1 : 3
                )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return ColorTheme.primaryText
        case .tertiary:
            return ColorTheme.accentPink
        }
    }
    
    private var background: some View {
        Group {
            switch style {
            case .primary:
                LinearGradient(
                    colors: [ColorTheme.accentPink, ColorTheme.accentBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .secondary:
                ColorTheme.cardBackground
            case .tertiary:
                Color.clear
            case .destructive:
                ColorTheme.error
            }
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return ColorTheme.accentPink.opacity(0.3)
        case .secondary:
            return Color.black.opacity(0.2)
        case .tertiary:
            return Color.clear
        case .destructive:
            return ColorTheme.error.opacity(0.3)
        }
    }
}

// MARK: - Form Section
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            content
        }
        .padding(.vertical, DesignSystem.Spacing.s)
    }
}

// MARK: - Standard List Item
struct StandardListItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: DesignSystem.Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: ComponentSize.Icon.medium))
                    .foregroundColor(ColorTheme.accentBlue)
                    .frame(width: ComponentSize.Icon.medium, height: ComponentSize.Icon.medium)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: ComponentSize.Icon.small))
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.s)
            .padding(.horizontal, DesignSystem.Spacing.m)
            .frame(minHeight: ComponentSize.minTouchTarget) // Ensure minimum touch target
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Standard Input Field
struct StandardInputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .font(DesignSystem.Typography.body)
        .foregroundColor(ColorTheme.primaryText)
        .padding(DesignSystem.Spacing.m)
        .frame(height: ComponentSize.Input.height)
        .background(ColorTheme.cardBackgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(ColorTheme.accentBlue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Mood Selector Card
struct MoodSelectorCard: View {
    let mood: MoodLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                
                Text(mood.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? .white : ColorTheme.secondaryText)
            }
            .frame(width: 80, height: 100)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? mood.color : ColorTheme.cardBackgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.accentBlue.opacity(0.6))
            
            VStack(spacing: DesignSystem.Spacing.s) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                StandardButton(actionTitle, size: .medium, style: .primary, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    init(message: String = "Lädt...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.accentPink))
                .scaleEffect(1.5)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(ColorTheme.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - View Extensions for Easy Usage
extension View {
    func standardCard() -> some View {
        StandardCard { self }
    }
    
    func standardScreenLayout() -> some View {
        StandardScreenLayout { self }
    }
}