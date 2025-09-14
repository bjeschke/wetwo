# WeTwo - Backend & iOS Development Context

## Backend API Documentation

### Base URL
`https://api.wetwo.com` (Production)
`http://localhost:8080` (Development)

### Authentication
All protected endpoints require a JWT Bearer Token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

### API Endpoints

#### Authentication
##### POST `/api/auth/signup`
Registers a new user.

**Request Body:**
```json
{
  "email": "string",
  "password": "string", 
  "name": "string",
  "birthDate": "YYYY-MM-DD"
}
```

**Response:** `SignupResponseDto`
**Status:** 200 OK

---

#### Profiles
##### GET `/api/profiles`
Retrieves the authenticated user's profile.

**Response:** `GetProfileResponseDto`
**Error Handling:**
- 401 UNAUTHORIZED: `USER_NOT_FOUND`
- 404 NOT_FOUND: `PROFILE_NOT_FOUND`

##### PUT `/api/profiles`
Updates the user profile.

**Request Body:** `UpdateProfileRequestDto`
**Response:** `UpdateProfileResponseDto`
**Error Handling:**
- 401 UNAUTHORIZED: `USER_NOT_FOUND`
- 400 BAD_REQUEST: `INVALID_BIRTH_DATE`

---

#### Partnerships
##### GET `/api/partnerships`
Retrieves all user partnerships.

**Response:** `GetPartnershipsResponseDto`

##### POST `/api/partnerships`
Creates a new partnership using a connection code.

**Request Body:**
```json
{
  "connectionCode": "string" // min length: 1
}
```

**Response:** `CreatePartnershipResponseDto`
**Status:** 201 CREATED
**Error Handling:**
- 401 UNAUTHORIZED: `USER_NOT_FOUND`
- 404 NOT_FOUND: `INVALID_CONNECTION_CODE`
- 400 BAD_REQUEST: `CANNOT_CONNECT_WITH_SELF`
- 409 CONFLICT: `PARTNERSHIP_ALREADY_EXISTS`

---

#### Invitations
##### POST `/api/invitations`
Creates a new invitation.

**Request Body:** `CreateInvitationRequestDto`
**Response:** `CreateInvitationResponseDto`
**Error Handling:**
- 401 UNAUTHORIZED: `USER_NOT_FOUND`
- 400 BAD_REQUEST: `INVITEE_NOT_FOUND`, `ALREADY_INVITED`, `INVITEE_ALREADY_REGISTERED`, `CANNOT_INVITE_SELF`

---

#### Mood Entries
##### GET `/api/mood-entries`
Retrieves mood entries.

**Query Parameters:**
- Various filters available (via `GetMoodListRequestDto`)

**Response:** `GetMoodListResponseDto`

##### POST `/api/mood-entries`
Creates a new mood entry.

**Request Body:** `CreateMoodRequestDto`
**Response:** `CreateMoodResponseDto`
**Status:** 201 CREATED
**Error Handling:**
- 401 UNAUTHORIZED: `USER_NOT_FOUND`
- 409 CONFLICT: `MOOD_ENTRY_ALREADY_EXISTS`

##### PUT `/api/mood-entries/{id}`
Updates a mood entry.

**Path Parameter:** `id` (Long)
**Request Body:** `UpdateMoodRequestDto`
**Response:** `UpdateMoodResponseDto`
**Error Handling:**
- 401 UNAUTHORIZED: `USER_NOT_FOUND`
- 404 NOT_FOUND: `MOOD_ENTRY_NOT_FOUND`
- 403 FORBIDDEN: `UNAUTHORIZED`

---

#### Memories
##### GET `/api/memories`
Retrieves memories.

**Query Parameters:**
- `user_id` (optional, Long): Filter by user ID

**Response:** List of `MemoryEntryDto`

##### POST `/api/memories`
Creates a new memory.

**Request Body:** `CreateMemoryRequestDto`
**Response:** `CreateMemoryResponseDto`
**Status:** 201 CREATED

##### PUT `/api/memories/{id}`
Updates a memory.

**Path Parameter:** `id` (Long)
**Request Body:** `UpdateMemoryRequestDto`
**Response:** `UpdateMemoryResponseDto`

##### DELETE `/api/memories/{id}`
Deletes a memory.

**Path Parameter:** `id` (Long)
**Response:** `DeleteMemoryResponseDto`

---

#### Love Messages
##### GET `/api/love-messages`
Retrieves all love messages.

**Response:** `GetLoveMessagesResponseDto`

##### POST `/api/love-messages`
Creates a new love message.

**Request Body:** `CreateLoveMessageRequestDto`
**Response:** `CreateLoveMessageResponseDto`
**Status:** 201 CREATED

---

#### Notifications
##### GET `/api/notifications`
Retrieves all notifications.

**Response:** `GetNotificationsResponseDto`

##### PUT `/api/notifications/{id}/read`
Marks a notification as read.

**Path Parameter:** `id` (Long)
**Response:** `MarkNotificationReadResponseDto`

---

## iOS Swift Development Best Practices

### Architecture Recommendations

#### 1. MVVM (Model-View-ViewModel)
Use MVVM architecture for better testability and separation of concerns:

```swift
// Model
struct User: Codable {
    let id: Int
    let email: String
    let name: String
}

// ViewModel
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadProfile() async {
        isLoading = true
        do {
            user = try await BackendService.shared.getProfile()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// View
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        // UI Implementation
    }
}
```

#### 2. State Management with SwiftUI

##### Property Wrappers for State Management:
- `@State`: Local view state
- `@StateObject`: Owner of an ObservableObject
- `@ObservedObject`: Observer of an ObservableObject
- `@EnvironmentObject`: Global app state
- `@Binding`: Two-way binding to external state
- `@FocusState`: Focus management

#### 3. Networking with Alamofire

##### JWT Authentication Setup:
```swift
class AuthenticationInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        if let token = TokenManager.shared.accessToken {
            request.headers.add(.authorization(bearerToken: token))
        }
        completion(.success(request))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // Token refresh logic
    }
}
```

##### Error Handling:
```swift
enum NetworkError: Error {
    case invalidResponse
    case authenticationFailed
    case serverError(message: String)
    
    init(from afError: AFError) {
        // Map AFError to app-specific errors
    }
}
```

#### 4. Async/Await Best Practices

```swift
// Use modern async/await instead of completion handlers
func fetchData() async throws -> [Memory] {
    let response = try await AF.request("/api/memories")
        .serializingDecodable([Memory].self)
        .value
    return response
}

// Parallel requests
async let profiles = fetchProfiles()
async let partnerships = fetchPartnerships()
let (profilesResult, partnershipsResult) = await (profiles, partnerships)
```

### iOS App Architecture Principles

#### 1. Clean Architecture Layers
- **Presentation Layer**: Views, ViewModels
- **Domain Layer**: Use Cases, Models
- **Data Layer**: Repositories, Network Services

#### 2. Dependency Injection
```swift
protocol BackendServiceProtocol {
    func getProfile() async throws -> User
}

class BackendService: BackendServiceProtocol {
    static let shared = BackendService()
    // Implementation
}

// In Tests:
class MockBackendService: BackendServiceProtocol {
    // Mock implementation
}
```

#### 3. Repository Pattern
```swift
protocol UserRepository {
    func getUser() async throws -> User
    func updateUser(_ user: User) async throws
}

class UserRepositoryImpl: UserRepository {
    private let networkService: BackendServiceProtocol
    private let cacheService: CacheServiceProtocol
    
    // Implementation with caching logic
}
```

### SwiftUI Performance Optimizations

1. **Use `@State` sparingly**: Only for view-specific UI state
2. **Use `EquatableView`**: For complex views that shouldn't always re-render
3. **LazyVStack/LazyHStack**: For long lists
4. **Memoization**: Cache expensive calculations
5. **Avoid unnecessary re-renders**: Use `objectWillChange` strategically

### Security Best Practices

1. **Keychain for sensitive data**: JWT tokens, passwords
2. **SSL Pinning**: For critical API calls
3. **Biometric Authentication**: Face ID/Touch ID integration
4. **Data Encryption**: Encrypt local data

### Testing Strategy

#### Unit Tests
```swift
class ProfileViewModelTests: XCTestCase {
    func testLoadProfile() async {
        let mockService = MockBackendService()
        let viewModel = ProfileViewModel(service: mockService)
        
        await viewModel.loadProfile()
        
        XCTAssertNotNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

#### UI Tests
```swift
class ProfileUITests: XCTestCase {
    func testProfileDisplay() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["Profile"].exists)
    }
}
```

## Context7 MCP Server Integration

### Available Functions

1. **Library Resolution**: `resolve-library-id`
   - Finds the Context7-compatible library ID for a library
   - Example: "SwiftUI" → `/zhangyu1818/swiftui.md`

2. **Documentation Retrieval**: `get-library-docs`
   - Fetches current documentation for a library
   - Parameters: `context7CompatibleLibraryID`, `topic`, `tokens`

### Important iOS/Swift Libraries in Context7

- **SwiftUI**: `/zhangyu1818/swiftui.md` (15469 Code Snippets, Trust Score: 9.3)
- **Alamofire**: `/alamofire/alamofire` (228 Code Snippets, Trust Score: 9.0)
- **Swift Navigation**: `/pointfreeco/swift-navigation` (79 Snippets, Trust Score: 9.1)

### Usage Examples

```swift
// Retrieve documentation for specific topics
// Topic: "networking, JWT, error handling"
// Library: Alamofire
// Tokens: 2000 for optimal balance between detail and context
```

## Development Workflow

### 1. Feature Development
1. Define and implement backend API
2. Write tests for backend
3. Create iOS models and DTOs
4. Implement service layer
5. Develop ViewModel
6. Build SwiftUI View
7. Integration tests

### 2. Debugging & Monitoring
- Charles Proxy for network debugging
- Xcode Instruments for performance
- Firebase Crashlytics for production monitoring

### 3. CI/CD Pipeline
- GitHub Actions for automated tests
- Fastlane for iOS deployment
- TestFlight for beta testing

## Important Conventions

### Naming Conventions
- **DTOs**: Suffix with `Dto` (e.g., `CreateMemoryRequestDto`)
- **ViewModels**: Suffix with `ViewModel`
- **Services**: Suffix with `Service`
- **Repositories**: Suffix with `Repository`

### Code Style
- No comments in code - self-explanatory code
- Descriptive variable and method names
- Follow Swift API Design Guidelines
- SwiftLint for code quality

### Git Workflow
- Feature branches: `feature/name`
- Commit messages: Concise and meaningful
- Pull requests with detailed descriptions
- Code reviews before merge

## Critical Architecture Components (iOS)

### Data Layer Architecture

#### Models
**Location**: `/WeTwo/Models/`
**Key Models**:
- `User`: User profile with Firebase integration
- `MoodEntry`: Mood tracking with timestamps and metadata
- `LoveMessage`: Message exchange between partners
- `Memory`: Shared memories with photos
- `AppState`: Global application state management
- `DatabaseModels`: Core Data entities for offline storage

#### Service Layer
**Pattern**: Repository pattern with protocol-oriented design

**ServiceFactory**:
```swift
class ServiceFactory {
    static let shared = ServiceFactory()
    func getCurrentService() -> DataServiceProtocol
}
```

**Backend Service**:
- Handles all API communication
- Token management and refresh
- Error mapping and recovery
- Request retry logic
- Response caching

**Error Handling Strategy**:
```swift
enum BackendError: Error {
    case invalidCredentials
    case networkError
    case unauthorized
    case sessionExpired
    // Comprehensive error cases
}
```

#### Manager Layer
**Purpose**: Business logic and state management
**Key Managers**:

1. **PartnerManager**: 
   - Partner connection state
   - Connection code generation/validation
   - Real-time sync coordination

2. **MoodManager**:
   - Daily mood tracking
   - Weekly analytics
   - Partner mood visibility

3. **MemoryManager**:
   - Memory CRUD operations
   - Photo management
   - Timeline organization

4. **NotificationService**:
   - Push notification handling
   - Local notifications
   - Deep link processing

### Data Persistence Strategy

#### Storage Types
1. **UserDefaults**: User preferences, settings
2. **Keychain**: Tokens, sensitive data
3. **Core Data**: Offline data cache
4. **File System**: Photos, documents
5. **CloudKit**: Backup and sync (future)

#### Offline Capabilities
- Queue system for pending operations
- Conflict resolution strategy
- Background sync when online
- Local-first architecture for critical features

### Network Layer

#### API Client Architecture
```swift
protocol APIClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
```

#### Request/Response Pipeline
1. Request interceptor (auth headers)
2. Request validation
3. Network call (Alamofire)
4. Response validation
5. Response interceptor (token refresh)
6. Decoding and mapping
7. Error handling

#### Token Management
- Automatic refresh on 401
- Secure storage in Keychain
- Background refresh before expiry
- Multi-request coordination during refresh

### Testing Strategy

#### Unit Tests
- ViewModels: 80% coverage minimum
- Managers: Business logic validation
- Services: Mocked network responses
- Models: Encoding/decoding tests

#### Integration Tests
- API integration with mock server
- Database operations
- Authentication flows
- Partner connection scenarios

#### UI Tests
- Critical user journeys
- Onboarding flow
- Partner connection
- Daily mood tracking

### Build Configuration

#### Environments
1. **Development**
   - Local backend: `http://localhost:8080`
   - Verbose logging
   - Debug menu enabled

2. **Staging**
   - Staging API: `https://staging-api.wetwo.com`
   - TestFlight distribution
   - Crashlytics enabled

3. **Production**
   - Production API: `https://api.wetwo.com`
   - App Store release
   - Analytics enabled

#### Configuration Management
```swift
enum Environment {
    case development
    case staging
    case production
    
    var baseURL: String { }
    var apiKey: String { }
}
```

### Performance Optimization

#### Memory Management
- Weak references in delegates
- Unowned in closures where appropriate
- Image caching with size limits
- View recycling in lists

#### Network Optimization
- Request debouncing
- Batch API calls
- Progressive image loading
- Prefetching for timeline

#### UI Performance
- Lazy loading in ScrollViews
- Image thumbnail generation
- Background queue for heavy operations
- Main thread protection

### Security Considerations

#### Data Protection
- Encryption at rest (Core Data)
- Certificate pinning for API
- Biometric authentication
- App Transport Security enforced

#### Privacy
- GDPR compliance
- Data minimization
- User consent flows
- Right to deletion

### Push Notifications

#### Setup
- APNs configuration
- Firebase Cloud Messaging
- Notification Service Extension
- Rich notifications with images

#### Notification Types
1. **Love Messages**: New message alerts
2. **Mood Reminders**: Daily check-ins
3. **Memories**: Anniversary reminders
4. **Partner Updates**: Connection status

### Deep Linking

#### Supported Links
- `wetwo://partner/connect?code=ABC123`
- `wetwo://memory/view?id=12345`
- `wetwo://mood/track`
- `wetwo://profile/settings`

#### Implementation
```swift
class DeepLinkHandler: ObservableObject {
    func handle(_ url: URL) -> DeepLinkDestination
}
```

### Accessibility

#### VoiceOver Support
- All interactive elements labeled
- Hints for complex interactions
- Grouping of related elements
- Custom actions for swipe gestures

#### Dynamic Type
- Scalable fonts throughout
- Layout adjustments for larger text
- Image scaling where appropriate

### Localization Strategy

#### Supported Languages
- German (de) - Primary
- English (en) - Secondary

#### Localization Files
- `Localizable.strings` - UI text
- `InfoPlist.strings` - System text
- Asset catalogs - Localized images

### Analytics & Monitoring

#### Crashlytics
- Crash reporting
- Non-fatal error logging
- User identification
- Custom logs for debugging

#### Analytics Events
- User engagement metrics
- Feature usage tracking
- Conversion funnels
- Performance metrics

### Release Process

#### Version Strategy
- Semantic versioning (MAJOR.MINOR.PATCH)
- Build number auto-increment
- Release notes automation

#### Distribution
1. Internal testing (TestFlight)
2. Beta testing (100 external testers)
3. Phased rollout (App Store)
4. Monitoring and hotfix process

### Code Quality

#### SwiftLint Rules
```yaml
disabled_rules:
  - line_length
  - function_body_length
opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional
```

#### Code Review Checklist
- [ ] No force unwrapping
- [ ] Proper error handling
- [ ] Memory leak check
- [ ] Accessibility support
- [ ] Localization keys
- [ ] Unit tests included

## Design System & Layout Guidelines

### Core Design Principles

1. **Consistency**: Every view follows the same spacing, sizing, and styling rules
2. **Accessibility**: All touch targets meet minimum size requirements
3. **Responsiveness**: Layouts adapt to different screen sizes
4. **Hierarchy**: Clear visual hierarchy through spacing and typography

### Spacing System (8pt Grid)

Use multiples of 8 for all spacing to ensure consistency:

```swift
enum Spacing {
    static let xxs: CGFloat = 4   // Minimal spacing
    static let xs: CGFloat = 8    // Tight spacing
    static let sm: CGFloat = 12   // Small spacing
    static let md: CGFloat = 16   // Default spacing
    static let lg: CGFloat = 24   // Large spacing
    static let xl: CGFloat = 32   // Extra large spacing
    static let xxl: CGFloat = 48  // Maximum spacing
    static let xxxl: CGFloat = 64 // Hero spacing
}
```

**Usage Guidelines**:
- **Component internal padding**: `sm` (12pt) or `md` (16pt)
- **Between related elements**: `xs` (8pt) or `sm` (12pt)
- **Between sections**: `lg` (24pt) or `xl` (32pt)
- **Screen margins**: `md` (16pt) on phones, `lg` (24pt) on tablets
- **Card padding**: `md` (16pt) minimum

### Typography Scale

```swift
enum Typography {
    enum Size {
        static let caption: CGFloat = 12
        static let body: CGFloat = 16
        static let callout: CGFloat = 18
        static let title3: CGFloat = 20
        static let title2: CGFloat = 24
        static let title1: CGFloat = 28
        static let largeTitle: CGFloat = 34
        static let hero: CGFloat = 48
    }
    
    enum Weight {
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
    }
    
    enum LineHeight {
        static let tight: CGFloat = 1.2
        static let normal: CGFloat = 1.5
        static let relaxed: CGFloat = 1.75
    }
}
```

**Usage Guidelines**:
- **Body text**: 16pt regular, 1.5 line height
- **Headers**: 24-34pt semibold/bold
- **Buttons**: 16-18pt medium/semibold
- **Captions**: 12-14pt regular

### Component Sizing

```swift
enum ComponentSize {
    // Buttons
    enum Button {
        static let heightSmall: CGFloat = 36
        static let heightMedium: CGFloat = 44  // Default
        static let heightLarge: CGFloat = 56
        static let minWidth: CGFloat = 64
    }
    
    // Input Fields
    enum Input {
        static let height: CGFloat = 48
        static let minWidth: CGFloat = 200
    }
    
    // Cards
    enum Card {
        static let minHeight: CGFloat = 80
        static let cornerRadius: CGFloat = 16
    }
    
    // Icons
    enum Icon {
        static let small: CGFloat = 20
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let xlarge: CGFloat = 48
    }
    
    // Touch Targets
    static let minTouchTarget: CGFloat = 44  // Apple HIG minimum
}
```

### Corner Radius System

```swift
enum CornerRadius {
    static let none: CGFloat = 0
    static let xs: CGFloat = 4    // Subtle rounding
    static let sm: CGFloat = 8    // Small elements
    static let md: CGFloat = 12   // Default for buttons
    static let lg: CGFloat = 16   // Cards
    static let xl: CGFloat = 20   // Large cards
    static let xxl: CGFloat = 24  // Modals
    static let full: CGFloat = 999 // Pills/circles
}
```

### Shadow System

```swift
enum Shadow {
    static let none = (color: Color.clear, radius: 0, x: 0, y: 0)
    static let sm = (color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    static let md = (color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let lg = (color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
    static let xl = (color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
}
```

### Dark Theme Color System

```swift
// IMPORTANT: The app uses a DARK PURPLE theme throughout
struct ColorPalette {
    // Dark backgrounds
    static let primaryPurple = Color(red: 0.2, green: 0.1, blue: 0.4)     // RGB(51, 26, 102)
    static let secondaryPurple = Color(red: 0.25, green: 0.15, blue: 0.5) // RGB(64, 38, 128)
    
    // Card backgrounds (lighter purple but still dark)
    static let cardBackground = Color(red: 0.4, green: 0.2, blue: 0.7)    // RGB(102, 51, 179)
    static let cardBackgroundSecondary = Color(red: 0.45, green: 0.25, blue: 0.75) // RGB(115, 64, 191)
    
    // Bright accent colors (high contrast against dark background)
    static let accentPink = Color(red: 0.9, green: 0.3, blue: 0.6)       // RGB(230, 77, 153)
    static let accentBlue = Color(red: 0.3, green: 0.7, blue: 0.9)       // RGB(77, 179, 230)
    
    // Text colors (white/light for dark backgrounds)
    static let textPrimary = Color.white                                   // Pure white
    static let textSecondary = Color(red: 0.9, green: 0.9, blue: 0.9)    // Light gray
    static let textTertiary = Color(red: 0.7, green: 0.7, blue: 0.75)    // Medium gray
    
    // Status colors (bright for visibility)
    static let success = Color(red: 0.3, green: 0.85, blue: 0.4)         // Bright green
    static let warning = Color(red: 1.0, green: 0.65, blue: 0.0)         // Bright orange
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)            // Bright red
}
```

**Usage Guidelines for Dark Theme**:

**Backgrounds**:
- Main screens: `primaryPurple` → `secondaryPurple` gradient (dark to darker)
- Cards/Modals: `cardBackground` with subtle elevation using shadows
- Overlays: `Color.black.opacity(0.7)` for high contrast
- Disabled elements: Add `.opacity(0.5)` to any color

**Text Hierarchy**:
- Headlines: `textPrimary` (white) - maximum contrast
- Body text: `textPrimary` with `.opacity(0.95)` for slight softness
- Secondary info: `textSecondary` - reduced emphasis
- Placeholders/Hints: `textTertiary` - lowest emphasis

**Interactive Elements**:
- Primary CTA: `accentPink` with `buttonGradient` (pink → blue)
- Secondary actions: `accentBlue` solid or with border
- Destructive: `error` color
- Disabled: Any color with `.opacity(0.4)`

**Contrast Requirements** (WCAG AA):
- Text on dark purple: Use white or light colors only
- Minimum contrast ratio: 4.5:1 for normal text
- Minimum contrast ratio: 3:1 for large text (18pt+)
- Interactive elements: Must have visible focus state

**Shadows for Dark Theme**:
```swift
// Darker, more pronounced shadows for depth
static let shadowDark = Color.black.opacity(0.5)
static let shadowMedium = Color.black.opacity(0.3)
static let shadowLight = Color.black.opacity(0.2)
```

### Layout Patterns

#### 1. Screen Layout
```swift
struct StandardScreenLayout<Content: View>: View {
    let content: Content
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl + 80) // Tab bar space
        }
        .background(ColorTheme.primaryPurple.gradient)
    }
}
```

#### 2. Card Layout
```swift
struct StandardCard<Content: View>: View {
    let content: Content
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            content
        }
        .padding(Spacing.md)
        .background(ColorTheme.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: Shadow.md.color, radius: Shadow.md.radius)
    }
}
```

#### 3. Form Layout
```swift
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.system(size: Typography.Size.callout, weight: .semibold))
                .foregroundColor(ColorTheme.primaryText)
            
            content
        }
        .padding(.vertical, Spacing.sm)
    }
}
```

#### 4. List Item Layout
```swift
struct StandardListItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .frame(width: ComponentSize.Icon.medium)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.system(size: Typography.Size.body, weight: .medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: Typography.Size.caption))
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
    }
}
```

### Responsive Design

#### Device-Specific Adjustments
```swift
extension View {
    func responsive() -> some View {
        self.modifier(ResponsiveModifier())
    }
}

struct ResponsiveModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    func body(content: Content) -> some View {
        if sizeClass == .compact {
            // iPhone
            content
                .padding(.horizontal, Spacing.md)
        } else {
            // iPad
            content
                .padding(.horizontal, Spacing.xl)
                .frame(maxWidth: 768) // Limit width on iPad
        }
    }
}
```

### Animation Standards

```swift
enum Animation {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let normal = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
}
```

### Safe Area Handling

```swift
extension View {
    func safeAreaPadding() -> some View {
        self
            .padding(.top, getSafeAreaTop())
            .padding(.bottom, getSafeAreaBottom())
    }
}
```

### Component Library Usage

Every new view MUST use these standard components:

1. **Buttons**: Use `StandardButton` with size variants
2. **Cards**: Use `StandardCard` for all card layouts
3. **Forms**: Use `FormSection` for form grouping
4. **Lists**: Use `StandardListItem` for list rows
5. **Screens**: Wrap in `StandardScreenLayout`

### Implementation Checklist

When creating a new view:
- [ ] Use Spacing enum for all padding/spacing
- [ ] Use Typography enum for all text sizes
- [ ] Use CornerRadius enum for all corners
- [ ] Use Shadow enum for all shadows
- [ ] Use ComponentSize for sizing
- [ ] Test on iPhone SE, iPhone 15, iPad
- [ ] Verify touch targets are ≥ 44pt
- [ ] Check Dynamic Type scaling
- [ ] Verify color contrast ratios

### Known Technical Debt

1. **Migration Needed**:
   - UIKit TabBar to SwiftUI (planned)
   - Combine to async/await (in progress)

2. **Performance Issues**:
   - Timeline with 100+ memories
   - Large image uploads

3. **Missing Features**:
   - Offline mode (partial)
   - iPad support
   - watchOS app

### Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Alamofire Documentation](https://github.com/Alamofire/Alamofire)

## App Concept & Purpose

### WeTwo - A Couple's Connection App

Based on my analysis of the codebase, **WeTwo** is a relationship-focused iOS application designed to strengthen emotional connections between romantic partners. The app serves as a digital space where couples can:

#### Core Features

1. **Partner Connection System**
   - Partners connect through unique connection codes
   - Establishes a private, shared digital space for two people
   - Real-time synchronization of shared data between partners

2. **Mood Tracking & Sharing**
   - Daily mood logging with 5 levels (veryHappy, happy, neutral, sad, verySad)
   - Partners can see each other's current emotional state
   - Weekly mood history and patterns
   - Event labels to provide context for mood changes
   - Location-based mood entries
   - Photo attachments to mood entries

3. **Love Messages**
   - Send and receive love messages between partners
   - AI-generated love message suggestions
   - Read/unread status tracking
   - Timestamp-based message history

4. **Shared Memories Timeline**
   - Create and share memorable moments together
   - Photo-based memory entries
   - Chronological timeline view of relationship milestones
   - Filter memories by categories (all, special, everyday)
   - Rich memory details with titles, descriptions, and dates

5. **Calendar Integration**
   - Track important dates and anniversaries
   - Shared calendar view for planning together
   - Event reminders and notifications

6. **Daily Insights**
   - AI-generated relationship insights based on mood patterns
   - Personalized suggestions for improving connection
   - Trend analysis of emotional patterns

#### Technical Architecture Insights

The app follows a **partner-centric architecture** where:
- Each user has a profile with personal information
- Users form partnerships (one-to-one relationships)
- All features revolve around this partnership context
- Data is scoped to either individual or shared between partners

#### User Experience Philosophy

The app emphasizes:
- **Emotional Awareness**: Helping partners understand each other's emotional states
- **Active Communication**: Encouraging regular check-ins through mood tracking
- **Shared Experiences**: Building a collective memory bank of the relationship
- **Privacy & Intimacy**: Creating a safe, private space just for the couple
- **Gentle Engagement**: Using notifications and love messages to maintain connection

#### Business Model Implications

Based on the features, this appears to be:
- A premium relationship wellness app
- Targeting committed couples who value emotional connection
- Potentially subscription-based (though payment features not visible in current code)
- Focus on long-term user retention through relationship milestones

#### Unique Value Proposition

WeTwo differentiates itself by:
1. **Simplicity**: Not a social network, just for two people
2. **Emotional Focus**: Centers on feelings and emotional connection rather than task management
3. **Memory Building**: Creates a digital scrapbook of the relationship
4. **Mutual Visibility**: Both partners have transparency into each other's emotional state
5. **AI Enhancement**: Uses AI for generating love messages and relationship insights

This app essentially serves as a "digital relationship journal" that helps couples maintain and strengthen their emotional bond through daily interactions, shared memories, and emotional transparency.

## iOS App Views Documentation

### View Architecture Overview

The app uses SwiftUI with a hierarchical view structure centered around `MainAppView` as the root container. The navigation flow is divided between onboarding and authenticated states, with a tab-based navigation for the main app experience.

### Core Views Hierarchy

#### 1. **MainAppView** (`/Views/MainAppView.swift`)
**Purpose**: Root view that orchestrates the entire app navigation
**Functionality**:
- Determines whether to show onboarding or main app based on `appState.isOnboarding`
- Manages environment objects for all child views (AuthService, PartnerManager, MoodManager, etc.)
- Handles email confirmation notifications
- Handles notifications if a user recieved a love message
- Handles notifications if a the connteded user sends a mood to the user
- Contains `MainTabView` for authenticated users

#### 2. **MainTabView** (within MainAppView)
**Purpose**: Tab-based navigation container for authenticated users
**Features**:
- 6 main tabs: Today, Calendar, Timeline, Activity, Reminders, Profile
- Animated background view
- Custom playful tab bar with icons
- Smooth transitions between tabs
- Selected tab state management

### Primary Feature Views

#### 3. **TodayView** (`/Views/Today/TodayView.swift`)
**Tab**: Main/Home tab
**Purpose**: Daily mood tracking and partner connection hub
**Key Features**:
- Mood selection interface (5 mood levels)
- Event label input for context
- Photo attachment capability
- Love message display and creation
- Partner connection status
- Partner's current mood display
- Daily insights section
- Profile photo picker
- Heart animations for interactions

**Sub-views**:
- `EventInputView`: Modal for adding event context to mood
- `PhotoPickerView`: Photo selection interface
- `LoveMessageEditorView`: Create/edit love messages

#### 4. **TimelineView** (`/Views/Timeline/TimelineView.swift`)
**Tab**: Timeline tab
**Purpose**: Shared memories and relationship milestones
**Key Features**:
- Chronological display of memories
- Filter options (all, special, everyday)
- Memory statistics header
- Add new memory button
- Memory cards with photos
- Pull-to-refresh functionality
- Animated card appearances

**Sub-views**:
- `AddMemoryView`: Create new memory entries
- `MemoryDetailView`: Full-screen memory viewer
- `MemoryCard`: Individual memory display component

#### 5. **CalendarView** (`/Views/Calendar/CalendarView.swift`)
**Tab**: Calendar tab
**Purpose**: Shared calendar for important dates and events
**Key Features**:
- Monthly calendar view
- Event markers on dates
- Add calendar entry functionality
- Event list view
- Anniversary tracking
- Date-based mood history

**Sub-views**:
- `AddCalendarEntryView`: Create new calendar events
- `CalendarEntryRow`: Individual event display
- `WeekSummaryView`: Weekly mood and event summary

#### 6. **ActivityView** (`/Views/Activity/ActivityView.swift`)
**Tab**: Activity tab
**Purpose**: Interactive games and couple activities
**Key Features**:
- Game selection interface
- "Who Knows Better?" game launcher
- Activity suggestions
- Game statistics and scores

**Sub-views**:
- `WhoKnowsBetterGameView`: Interactive quiz game for couples

#### 7. **RemindersView** (`/Views/Reminders/RemindersView.swift`)
**Tab**: Reminders tab
**Purpose**: Notification and reminder management
**Key Features**:
- Daily mood reminder settings
- Love message reminder configuration
- Anniversary notifications
- Custom reminder creation
- Notification permission handling

#### 8. **ProfileView** (`/Views/Profile/ProfileView.swift`)
**Tab**: Profile tab
**Purpose**: User settings and account management
**Key Features**:
- User profile display
- Relationship status configuration
- Premium upgrade options
- Account settings
- Logout functionality
- Partner connection management

**Sub-views**:
- `RelationshipStatusView`: Edit relationship details
- `PremiumUpgradeView`: Premium features and subscription

### Onboarding Flow Views

#### 9. **OnboardingView** (`/Views/Onboarding/OnboardingView.swift`)
**Purpose**: Multi-step onboarding process for new users
**Steps**:
1. Welcome step - App introduction
2. Profile step - Name and basic info
3. Relationship step - Partnership details
4. Registration step - Account creation

**Features**:
- Progress indicator
- Step navigation
- Skip options for certain steps
- Animated transitions

#### 10. **LoginView** (`/Views/Onboarding/LoginView.swift`)
**Purpose**: User authentication
**Features**:
- Email/password login
- Social login options (Apple, Google)
- Password reset link
- Switch to signup view
- Remember me option

#### 11. **SignupView** (`/Views/Onboarding/SignupView.swift`)
**Purpose**: New user registration
**Features**:
- Email/password registration
- Name and birthdate input
- Terms acceptance
- Email verification flow
- Social signup options

### Partner Connection Views

#### 12. **PartnerConnectionView** (`/Views/Partner/PartnerConnectionView.swift`)
**Purpose**: Partner linking and connection management
**Features**:
- Generate personal connection code
- QR code display
- Enter partner's code
- Connection status display
- Error handling for invalid codes
- Success animations

### Component and Theme Views

#### 13. **PlayfulComponents** (`/Views/Components/PlayfulComponents.swift`)
**Purpose**: Reusable UI components with playful animations
**Components**:
- PlayfulTabBar: Animated tab bar
- FloatingHearts: Love animation effects
- BounceButton: Animated button interactions
- GlowingCard: Cards with glow effects

#### 14. **ColorTheme** (`/Views/Theme/ColorTheme.swift`)
**Purpose**: Centralized color management
**Defines**:
- Primary and secondary colors
- Background gradients
- Text colors
- Accent colors for different moods

#### 15. **AppleStyleInputField** (`/Views/Theme/AppleStyleInputField.swift`)
**Purpose**: Custom text input with iOS-style design
**Features**:
- Floating placeholder
- Error state display
- Secure text entry option
- Custom styling

### Special Purpose Views

#### 16. **BackendTestView** (`/Views/BackendTestView.swift`)
**Purpose**: Developer testing interface for backend integration
**Note**: Should be removed in production builds

#### 17. **DeepLinkTestView** (`/Views/DeepLinkTestView.swift`)
**Purpose**: Testing deep linking functionality
**Note**: Development testing view

### View State Management

All views utilize SwiftUI's state management:
- `@State`: Local view state
- `@StateObject`: View-owned observable objects
- `@EnvironmentObject`: Shared app-wide state
- `@ObservedObject`: External observable objects
- `@Binding`: Two-way data binding

### Navigation Patterns

1. **Tab Navigation**: Main app uses tab-based navigation
2. **Sheet Presentations**: Modals for forms and detail views
3. **Navigation Links**: Push navigation for hierarchical content
4. **Programmatic Navigation**: State-driven view changes

### Animation and Transitions

- Custom view transitions for tab changes
- Heart animations for love interactions
- Scale and rotation effects for playful elements
- Gradient animations in backgrounds
- Spring animations for user interactions

## Onboarding Process Flow

### Overview

The WeTwo onboarding is a multi-step, progressive disclosure process designed to:
1. Introduce the app's core value proposition
2. Collect essential user information
3. Establish relationship context
4. Create user account
5. Connect with partner (optional during onboarding)

### Entry Points

1. **First Launch**: New users enter onboarding automatically
2. **Deep Link**: Email verification links redirect back to app
3. **Partner Invitation**: Connection codes can trigger partner flow
4. **Post-Signup**: After account creation, onboarding continues

### Onboarding Steps

#### Step 1: Welcome Screen
**Purpose**: First impression and value proposition
**Location**: `OnboardingView.welcomeStep`
**Content**:
- App logo (heart icon)
- Welcome title and subtitle
- Feature preview cards:
  - 💕 Mood tracking
  - 📅 Shared calendar
  - 📸 Memory collection
  - 👫 Partner connection
**User Action**: Tap "Next" to continue

#### Step 2: Profile Setup
**Purpose**: Collect basic user information
**Location**: `OnboardingView.profileStep`
**Data Collected**:
- Full name (required)
- Birth date (required)
  - Automatically calculates zodiac sign
  - Date picker with wheel style
  - Used for astrology features
**Validation**: Name must not be empty
**User Action**: Enter information and tap "Next"

#### Step 3: Relationship Status
**Purpose**: Understand relationship context
**Location**: `OnboardingView.relationshipStep`
**Data Collected**:

**Relationship Status Options**:
- 💑 Dating
- 💍 Engaged  
- 👰 Married
- 🏠 Living Together
- 💔 It's Complicated
- 🦋 Single

**Children Information**:
- Toggle: Has children (yes/no)
- If yes: Number of children (0-10)
  - Plus/minus buttons for count
  - Visual counter display

**User Action**: Select status and tap "Next"

#### Step 4: Account Registration
**Purpose**: Create user account
**Location**: `OnboardingView.registrationStep` → `SignupView`

### Authentication Methods

The app supports two primary authentication methods for both registration and login:

#### Method 1: Email/Password Authentication

**Registration Process**:
- Full name (pre-filled from Step 2)
- Email address
- Password (min 6 characters)
- Confirm password
- Validation:
  - Email format check
  - Password match verification
  - Password strength requirements

**Email Registration Flow**:
1. User enters email and password
2. App sends credentials to backend via `/api/auth/signup`
3. Backend creates Firebase account with email/password
4. Backend generates custom Firebase token
5. Backend returns token and user data to app
6. App signs in to Firebase using the custom token
7. Email verification sent (optional)

**Email Login Flow**:
1. User enters email and password
2. App sends credentials to backend via `/api/auth/login`
3. Backend validates credentials with Firebase
4. Backend generates custom Firebase token
5. Backend returns token and user data to app
6. App signs in to Firebase using the custom token

#### Method 2: Sign in with Apple

**Registration Process**:
- Uses AuthenticationServices framework
- Requests: Email, Full Name, User Identifier
- Automatic account creation on first sign-in

**Apple Sign-In Flow**:
1. User taps "Sign in with Apple" button
2. iOS presents Apple ID authentication sheet
3. User authenticates with Face ID/Touch ID/Password
4. Apple returns identity token and user info
5. App sends Apple token to backend via `/api/auth/apple`
6. Backend validates Apple token
7. Backend creates/retrieves Firebase account
8. Backend generates custom Firebase token
9. Backend returns token and user data to app
10. App signs in to Firebase using the custom token

**Key Differences**:
- **Email**: Requires password management, email verification
- **Apple**: Passwordless, automatic authentication, privacy-focused (can hide email)

**Unified Backend Response**:
Regardless of authentication method, backend always returns:
```json
{
  "firebaseToken": "custom_firebase_token",
  "user": {
    "id": "user_id",
    "email": "user@email.com",
    "name": "User Name"
  }
}
```

**Process Flow (Both Methods)**:
1. User chooses authentication method
2. App sends credentials/tokens to appropriate backend endpoint
3. Backend handles Firebase account creation/retrieval
4. Backend generates custom Firebase token
5. Backend returns unified response to app
6. App signs in to Firebase using the custom token
7. Onboarding completion triggered

### Post-Registration Flow

#### Email Verification
**Purpose**: Verify email ownership
**Process**:
1. Verification email sent automatically
2. User clicks verification link
3. Deep link opens app
4. Email confirmed status updated
5. Onboarding marked complete

#### Partner Connection (Optional)
**When**: Can happen during or after onboarding
**Location**: `PartnerConnectionView`
**Options**:

**Generate Connection Code**:
1. User requests code generation
2. 6-character alphanumeric code created
3. Code displayed with QR option
4. Partner enters code in their app

**Enter Partner's Code**:
1. User enters 6-character code
2. Backend validates via `/api/partnerships`
3. Partnership established
4. Both users notified

### State Management During Onboarding

**AppState Properties**:
- `isOnboarding`: Boolean flag for onboarding status
- `currentUser`: User object after registration
- `hasCompletedOnboarding`: Persistent storage flag

**OnboardingViewModel Properties**:
- `currentStep`: Current step index (0-3)
- `name`: User's full name
- `birthDate`: User's date of birth
- `relationshipStatus`: Selected relationship status
- `hasChildren`: Boolean for children
- `childrenCount`: Number of children

### Navigation Controls

**Progress Indicator**:
- Linear progress bar at top
- Shows current step out of total
- Visual feedback for progression

**Navigation Buttons**:
- "Back": Available from step 2 onward
- "Next": Advances to next step
- "Skip": Available for optional steps
- "Complete": Final action button

### Error Handling

**Common Error Scenarios**:
1. **Email Already Exists**:
   - Alert with option to login
   - Prefills email in login view

2. **Weak Password**:
   - Inline error message
   - Password requirements shown

3. **Network Errors**:
   - Retry mechanism
   - Offline mode indication

4. **Invalid Partner Code**:
   - Error message display
   - Option to generate own code

### Completion Actions

**On Successful Completion**:
1. `appState.isOnboarding = false`
2. Navigate to MainTabView
3. Show welcome message
4. Request notification permissions
5. Sync initial data from backend

### Accessibility Features

- VoiceOver support for all elements
- Dynamic type support
- High contrast mode compatibility
- Keyboard navigation support
- Clear error messages

### Localization

**Supported Languages**:
- German (primary)
- English (in progress)

**Localized Elements**:
- All UI text via NSLocalizedString
- Date formats
- Error messages
- Feature descriptions

### Analytics Events

**Tracked Events**:
- Onboarding started
- Each step completed
- Registration method (email/social)
- Partner connection success/failure
- Onboarding completed
- Drop-off points

### Best Practices Implemented

1. **Progressive Disclosure**: Information collected only when needed
2. **Immediate Value**: Features highlighted before registration
3. **Social Proof**: Partner connection emphasized
4. **Error Prevention**: Real-time validation
5. **Quick Win**: Minimal required fields
6. **Flexibility**: Optional steps can be skipped
7. **Recovery**: Can return to previous steps
8. **Persistence**: Progress saved between sessions

## Testing Strategy

### Testing Philosophy
- **Test Coverage Goal**: Aim for 80% code coverage minimum
- **Testing Pyramid**: 70% unit tests, 20% integration tests, 10% UI tests
- **Performance Baseline**: All views must load within 1 second
- **Memory Management**: No memory leaks, efficient resource usage

### Unit Testing Guidelines

#### Manager Tests
All manager classes should have comprehensive unit tests covering:
- Initial state verification
- State mutations and updates
- Async operation handling
- Error scenarios
- Cancellation behavior
- Thread safety (@MainActor compliance)

#### View Model Tests
- Test all computed properties
- Verify binding updates
- Test business logic
- Mock dependencies
- Test error handling

#### Service Tests
- Mock network responses
- Test error handling
- Verify request/response mapping
- Test authentication flows
- Test retry logic

### UI Testing Guidelines

#### Critical User Flows to Test
1. **Onboarding Flow**
   - Welcome screen navigation
   - Profile setup validation
   - Relationship status selection
   - Account registration (email and Apple Sign-In)
   - Error handling for invalid inputs

2. **Partner Connection Flow**
   - Generate connection code
   - Enter partner code
   - Handle invalid codes
   - Verify connection status updates
   - Test disconnection scenarios

3. **Mood Tracking Flow**
   - Select mood level
   - Add optional event labels
   - Save mood entry
   - View mood history
   - Compare partner moods

4. **Memory Creation Flow**
   - Create new memory
   - Add photos
   - Mark as special
   - Edit existing memories
   - Filter memories

5. **Love Message Flow**
   - Compose message
   - Send message
   - Receive notifications
   - View message history

### Performance Testing

#### Metrics to Monitor
- **Launch Time**: < 2 seconds cold start
- **View Transitions**: < 300ms
- **Scroll Performance**: 60 FPS minimum
- **Memory Usage**: < 100MB baseline
- **Network Requests**: Implement caching, batch where possible

#### Performance Test Scenarios
```swift
// Launch performance
measure(metrics: [XCTApplicationLaunchMetric()]) {
    XCUIApplication().launch()
}

// Memory performance
measure(metrics: [XCTMemoryMetric()]) {
    // Load large datasets
}

// Scroll performance
measure {
    // Scroll through timeline with 100+ items
}
```

### Integration Testing

#### Key Integration Points
1. **Manager Integration**
   - MoodManager + PartnerManager
   - MemoryManager + BackendService
   - NotificationService + UserDefaults

2. **Service Integration**
   - BackendService + NetworkManager
   - AuthenticationService + Firebase
   - DataService + Cache

3. **View Integration**
   - Parent-child view communication
   - Tab navigation state
   - Deep linking

### Test Data Management

#### Mock Data Guidelines
```swift
// Use factory methods for test data
extension Memory {
    static func mock(/* parameters */) -> Memory
}

// Use dependency injection for services
protocol DataServiceProtocol {
    func fetchData() async throws -> [Model]
}
```

#### Test Environment Setup
- Use launch arguments for UI testing
- Separate test database/backend
- Mock Firebase Authentication
- Stub network responses

### Continuous Integration

#### Test Automation
- Run unit tests on every commit
- Run UI tests on PR merges
- Performance tests weekly
- Full regression before releases

#### Test Reports
- Generate coverage reports
- Track performance metrics over time
- Monitor flaky test patterns
- Document known issues

### Accessibility Testing

#### Requirements
- VoiceOver support for all interactive elements
- Dynamic Type support (minimum 85% - maximum 200%)
- Sufficient color contrast (WCAG AA)
- Keyboard navigation support
- Reduced motion support

#### Test Scenarios
```swift
// VoiceOver testing
XCTAssertNotNil(element.accessibilityLabel)
XCTAssertTrue(element.isAccessibilityElement)

// Dynamic Type testing
app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
```

### Error Handling Tests

#### Scenarios to Cover
- Network failures
- Invalid server responses
- Authentication errors
- Expired tokens
- Rate limiting
- Offline mode
- Data corruption
- Concurrent operations

### Security Testing

#### Security Checks
- No sensitive data in logs
- Secure storage for tokens
- Certificate pinning
- Input validation
- SQL injection prevention
- XSS prevention in web views

### Test Maintenance

#### Best Practices
- Keep tests independent and isolated
- Use descriptive test names
- Avoid testing implementation details
- Focus on behavior, not structure
- Regular test refactoring
- Document complex test scenarios

#### Test Organization
```
WeTwoTests/
├── Unit/
│   ├── Managers/
│   ├── Services/
│   ├── Models/
│   └── Utils/
├── Integration/
│   ├── ManagerIntegration/
│   └── ServiceIntegration/
└── Mocks/
    ├── MockServices/
    └── MockData/

WeTwoUITests/
├── Flows/
│   ├── OnboardingTests/
│   ├── MoodTrackingTests/
│   └── PartnerConnectionTests/
├── Performance/
└── Accessibility/
```