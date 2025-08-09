# Understand Me Today 💕

A playful and emotional iOS app for couples to strengthen their relationship through daily micro-interactions. Built with SwiftUI and designed with love in mind.

## 🌟 Features

### Core Features
- **Mood Input via Emoji Slider** - Express your feelings with animated emoji sliders (😍😐😩)
- **Daily Insight Cards** - AI-powered insights based on your mood, zodiac sign, and daily events
- **Photo Missions** - Capture and share the "emotion of the day" with your partner
- **GPT-Generated Love Messages** - One-tap personalized love messages
- **Weekly Love Calendar** - Visual mood history with emoji dots and trends
- **Partner Matching** - Connect via QR codes or manual code entry
- **Astrology Engine** - Zodiac-based compatibility and insights

### Premium Features
- Unlimited daily insights
- Unlimited photo missions
- Custom GPT love messages
- Advanced analytics and trends
- Priority support

## 🏗️ Architecture

### Project Structure
```
WeTwo/
├── Models/
│   ├── AppState.swift          # Main app state management
│   ├── User.swift              # User profile and zodiac models
│   └── MoodEntry.swift         # Mood tracking and insights
├── Managers/
│   ├── MoodManager.swift       # Mood entry and analysis
│   ├── PartnerManager.swift    # Partner connection and sync
│   └── GPTService.swift        # AI-powered insights
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── Main/
│   │   └── MainTabView.swift
│   ├── Today/
│   │   ├── TodayView.swift
│   │   ├── EventInputView.swift
│   │   └── PhotoPickerView.swift
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   └── WeekSummaryView.swift
│   ├── Partner/
│   │   ├── PartnerView.swift
│   │   └── PartnerConnectionView.swift
│   └── Profile/
│       ├── ProfileView.swift
│       └── PremiumUpgradeView.swift
└── WeTwoApp.swift              # Main app entry point
```

### Key Components

#### Data Models
- **User**: Profile with zodiac sign, preferences, and partner info
- **MoodEntry**: Daily mood inputs with optional events and photos
- **DailyInsight**: AI-generated insights and love messages
- **WeeklyMoodSummary**: Mood trends and analytics

#### State Management
- **AppState**: Global app state, onboarding, and premium status
- **MoodManager**: Mood tracking, insights generation, and weekly summaries
- **PartnerManager**: Partner connection, QR codes, and compatibility scoring
- **GPTService**: AI-powered insights and message generation

#### UI Components
- **OnboardingView**: Multi-step user setup with zodiac selection
- **MainTabView**: Tab-based navigation between main features
- **TodayView**: Daily mood input with emoji slider and insights
- **CalendarView**: Weekly mood history with visual trends
- **PartnerView**: Partner connection and compatibility features
- **ProfileView**: User settings and premium upgrade

## 🎨 Design Philosophy

### Visual Design
- **Rounded UI elements** with soft shadows and pastel colors
- **Floating buttons** with hearts, stars, and moons
- **Animated emoji sliders** for engaging mood input
- **Modular card components** with minimal text
- **Gradient backgrounds** in romantic pink and purple tones

### UX Principles
- **Minimal typing required** - Focus on visual interactions
- **Emoji-first approach** - Universal emotional expression
- **Micro-interactions** - Small, delightful moments throughout
- **Partner-focused** - Always consider the couple's experience
- **Astrology integration** - Personal and mystical elements

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `WeTwo.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project

### Configuration
1. **GPT Integration**: Add your OpenAI API key in `GPTService.swift`
2. **Push Notifications**: Configure for daily reminders
3. **Photo Permissions**: Enable camera and photo library access

## 🔧 Technical Implementation

### SwiftUI Best Practices
- **Environment Objects** for state management
- **MVVM Architecture** with ObservableObject classes
- **Modular Views** with reusable components
- **Async/Await** for API calls and data processing

### Data Persistence
- **UserDefaults** for user preferences and app state
- **Core Data** ready for future implementation
- **CloudKit** integration planned for partner sync

### AI Integration
- **OpenAI GPT-4** for personalized insights
- **Custom prompts** for relationship-focused responses
- **Astrological context** for enhanced personalization

## 📱 App Flow

### Onboarding
1. Welcome screen with app introduction
2. Name and zodiac sign selection
3. Optional partner connection setup

### Daily Usage
1. **Today Tab**: Input mood with emoji slider
2. **Optional**: Add event label or photo
3. **AI Insight**: Receive personalized daily insight
4. **Love Message**: Generate and share with partner

### Weekly Review
1. **Calendar Tab**: View mood history and trends
2. **Weekly Summary**: Detailed analytics and recommendations
3. **Partner Sync**: Compare moods and compatibility

## 🎯 Future Enhancements

### Planned Features
- **Voice Messages**: Audio mood sharing
- **Mood Challenges**: Couple activities and prompts
- **Relationship Milestones**: Anniversary tracking
- **Mood Journal**: Detailed emotional logging
- **Social Features**: Anonymous couple communities

### Technical Improvements
- **Offline Support**: Local mood tracking
- **Widgets**: Home screen mood display
- **Apple Watch**: Quick mood input
- **Siri Integration**: Voice-activated mood sharing

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for:
- Code style and architecture
- UI/UX improvements
- Feature suggestions
- Bug reports

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 💝 Made with Love

Built by couples, for couples. Every feature is designed to bring partners closer together through understanding, empathy, and daily moments of connection.

---

**Understand Me Today** - Because every relationship deserves to be understood, one day at a time. 💕 