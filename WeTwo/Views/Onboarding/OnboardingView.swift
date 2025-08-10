//
//  OnboardingView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var partnerManager: PartnerManager
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0
    @State private var showingPartnerConnection = false
    @State private var showingEmailConfirmation = false
    
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [ColorTheme.primaryPurple, ColorTheme.secondaryPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: ColorTheme.primaryPurple))
                    .padding(.horizontal)
                
                Spacer()
                
                // Step content
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    profileStep
                case 2:
                    relationshipStep
                case 3:
                    registrationStep
                default:
                    EmptyView()
                }
                
                Spacer(minLength: 50)
                
                // Navigation buttons
                navigationButtons
            }
            .padding()
        }
        .sheet(isPresented: $showingPartnerConnection) {
            SimplePartnerConnectionView()
                .environmentObject(partnerManager)
        }
        .sheet(isPresented: $showingEmailConfirmation) {
            EmailConfirmationView()
                .environmentObject(appState)
        }
        .onAppear {
            checkEmailConfirmationStatus()
        }
    }
    
    // MARK: - Step Views
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            // App icon and title
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ColorTheme.accentPink)
                
                Text(NSLocalizedString("onboarding_welcome_title", comment: "Welcome title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(NSLocalizedString("onboarding_welcome_subtitle", comment: "Welcome subtitle"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            // Features preview
            VStack(spacing: 15) {
                OnboardingFeatureRow(icon: "heart.fill", title: NSLocalizedString("onboarding_feature_mood", comment: "Mood feature"))
                OnboardingFeatureRow(icon: "calendar", title: NSLocalizedString("onboarding_feature_calendar", comment: "Calendar feature"))
                OnboardingFeatureRow(icon: "photo", title: NSLocalizedString("onboarding_feature_memories", comment: "Memories feature"))
                OnboardingFeatureRow(icon: "person.2.fill", title: NSLocalizedString("onboarding_feature_partner", comment: "Partner feature"))
            }
        }
    }
    
    private var profileStep: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("onboarding_profile_title", comment: "Profile title"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("onboarding_name_label", comment: "Name label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField(NSLocalizedString("onboarding_name_placeholder", comment: "Name placeholder"), text: $viewModel.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Birth date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("onboarding_birthdate_label", comment: "Birthdate label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DatePicker(
                        NSLocalizedString("onboarding_birthdate_placeholder", comment: "Birthdate placeholder"),
                        selection: $viewModel.birthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(.white)
                    
                    // Show calculated zodiac sign
                    if !viewModel.name.isEmpty {
                        let zodiacSign = ZodiacSign.calculate(from: viewModel.birthDate)
                        HStack {
                            Text(NSLocalizedString("onboarding_zodiac_label", comment: "Zodiac label"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(zodiacSign.emoji + " " + zodiacSign.rawValue)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var relationshipStep: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("onboarding_relationship_title", comment: "Relationship title"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 25) {
                // Relationship status
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("onboarding_relationship_status_label", comment: "Relationship status label"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(RelationshipStatus.allCases, id: \.self) { status in
                            Button(action: {
                                viewModel.relationshipStatus = status
                            }) {
                                HStack {
                                    Text(status.emoji)
                                        .font(.title2)
                                    Text(status.localizedName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(viewModel.relationshipStatus == status ? .white : ColorTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.relationshipStatus == status ? ColorTheme.accentPink : ColorTheme.cardBackgroundSecondary)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Children section
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("onboarding_children_label", comment: "Children label"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    VStack(spacing: 15) {
                        // Has children toggle
                        HStack {
                            Text(NSLocalizedString("onboarding_has_children", comment: "Has children"))
                                .font(.body)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.hasChildren)
                                .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
                        }
                        
                        // Children count (if has children)
                        if viewModel.hasChildren {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(NSLocalizedString("onboarding_children_count_label", comment: "Children count label"))
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondaryText)
                                
                                HStack {
                                    Button(action: {
                                        if viewModel.childrenCount > 0 {
                                            viewModel.childrenCount -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(ColorTheme.accentPink)
                                    }
                                    .disabled(viewModel.childrenCount == 0)
                                    
                                    Text("\(viewModel.childrenCount)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(ColorTheme.primaryText)
                                        .frame(minWidth: 50)
                                    
                                    Button(action: {
                                        if viewModel.childrenCount < 10 {
                                            viewModel.childrenCount += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(ColorTheme.accentPink)
                                    }
                                    .disabled(viewModel.childrenCount == 10)
                                    
                                    Spacer()
                                    
                                    Text(viewModel.childrenCount == 1 ? NSLocalizedString("child", comment: "child") : NSLocalizedString("children", comment: "children"))
                                        .font(.body)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ColorTheme.cardBackgroundSecondary)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var registrationStep: some View {
        RegistrationView(
            name: viewModel.name,
            birthDate: viewModel.birthDate,
            relationshipStatus: viewModel.relationshipStatus,
            hasChildren: viewModel.hasChildren,
            childrenCount: viewModel.childrenCount
        )
        .environmentObject(appState)
        .onReceive(NotificationCenter.default.publisher(for: .registrationCompleted)) { _ in
            withAnimation {
                completeOnboarding()
            }
        }
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(NSLocalizedString("onboarding_back", comment: "Back button")) {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .foregroundColor(ColorTheme.primaryText)
            }
            
            Spacer()
            
            if currentStep < totalSteps - 1 {
                Button(NSLocalizedString("onboarding_next", comment: "Next button")) {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .foregroundColor(ColorTheme.primaryText)
                .disabled(currentStep == 1 && viewModel.name.isEmpty) // Disable if no name entered
            } else {
                // Registration step - no next button needed
                EmptyView()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        let user = User(name: viewModel.name, birthDate: viewModel.birthDate)
        appState.completeOnboarding(user: user)
        
        // Create profile and save relationship data
        Task {
            await createProfileAndSaveData()
        }
        
        // Show partner connection option
        showingPartnerConnection = true
    }
    
    private func createProfileAndSaveData() async {
        do {
            guard let userId = appState.currentUser?.id else { 
                print("❌ No current user ID found")
                return 
            }
            
            print("🔧 Updating profile for user: \(userId)")
            print("   Name: \(viewModel.name)")
            print("   Birth Date: \(viewModel.birthDate)")
            
            // Profile wird automatisch durch Trigger erstellt, nur Update nötig
            try await SupabaseService.shared.updateProfile(
                userId: userId.uuidString,
                name: viewModel.name,
                birthDate: viewModel.birthDate
            )
            
            print("✅ Profile updated successfully!")
            
            // Save relationship data
            await saveRelationshipData()
            
        } catch {
            print("❌ Error updating profile: \(error)")
        }
    }
    
    private func saveRelationshipData() async {
        do {
            guard let userId = appState.currentUser?.id else { 
                print("❌ No current user ID found for relationship data")
                return 
            }
            
            print("🔧 Saving relationship data for user: \(userId)")
            print("   Status: \(viewModel.relationshipStatus.rawValue)")
            print("   Has Children: \(viewModel.hasChildren)")
            print("   Children Count: \(viewModel.childrenCount)")
            
            // Save relationship data to database
            try await SupabaseService.shared.updateRelationshipData(
                userId: userId.uuidString,
                relationshipStatus: viewModel.relationshipStatus.rawValue,
                hasChildren: viewModel.hasChildren ? "true" : "false",
                childrenCount: String(viewModel.childrenCount)
            )
            
            print("✅ Relationship data saved successfully!")
            
        } catch {
            print("❌ Error saving relationship data: \(error)")
        }
    }
    
    private func checkEmailConfirmationStatus() {
        // Check if user exists but email might not be confirmed
        if appState.currentUser != nil {
            // Check if we have email/password but no current user ID (indicating email not confirmed)
            if let _ = try? SecurityService.shared.secureLoadString(forKey: "userEmail"),
               let _ = try? SecurityService.shared.secureLoadString(forKey: "userPassword"),
               try? SecurityService.shared.secureLoadString(forKey: "currentUserId") == nil {
                
                print("🔄 User exists but email not confirmed - showing email confirmation")
                showingEmailConfirmation = true
            }
        }
    }
}

// MARK: - Onboarding ViewModel

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var name = ""
    @Published var birthDate = Date()
    @Published var email = ""
    @Published var password = ""
    @Published var relationshipStatus: RelationshipStatus = .single
    @Published var hasChildren = false
    @Published var childrenCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
}

// MARK: - Supporting Views

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ColorTheme.accentPink)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Registration View
struct RegistrationView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingEmailSignup = false
    @State private var showingAppleSignIn = false
    
    let name: String
    let birthDate: Date
    let relationshipStatus: RelationshipStatus
    let hasChildren: Bool
    let childrenCount: Int
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(ColorTheme.accentPink)
                
                Text(NSLocalizedString("onboarding_signin_title", comment: "Sign In Title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(NSLocalizedString("onboarding_signin_subtitle", comment: "Sign In Subtitle"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            // Registration options
            VStack(spacing: 20) {
                // Apple Sign In
                Button(action: {
                    showingAppleSignIn = true
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        Text("Mit Apple anmelden")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.3))
                    
                    Text(NSLocalizedString("onboarding_or", comment: "Or separator"))
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(.horizontal, 10)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.3))
                }
                
                // Email registration
                Button(action: {
                    showingEmailSignup = true
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.title2)
                        Text("Mit E-Mail registrieren")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.accentPink)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .sheet(isPresented: $showingEmailSignup) {
            EmailSignupView(
                name: name,
                birthDate: birthDate,
                relationshipStatus: relationshipStatus,
                hasChildren: hasChildren,
                childrenCount: childrenCount
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showingAppleSignIn) {
            AppleSignInView(
                name: name,
                birthDate: birthDate,
                relationshipStatus: relationshipStatus,
                hasChildren: hasChildren,
                childrenCount: childrenCount
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showingEmailConfirmation) {
            EmailConfirmationView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Email Signup View
struct EmailSignupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingEmailConfirmation = false
    
    let name: String
    let birthDate: Date
    let relationshipStatus: RelationshipStatus
    let hasChildren: Bool
    let childrenCount: Int
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle")
                            .font(.system(size: 60))
                            .foregroundColor(ColorTheme.accentPink)
                        
                        Text("Account erstellen")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("Erstelle dein Konto mit E-Mail")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .padding(.top, 40)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        AppleStyleInputField(
                            placeholder: "E-Mail",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        AppleStyleInputField(
                            placeholder: "Passwort",
                            text: $password,
                            isSecure: true,
                            textContentType: .newPassword
                        )
                        
                        AppleStyleInputField(
                            placeholder: "Passwort bestätigen",
                            text: $confirmPassword,
                            isSecure: true,
                            textContentType: .newPassword
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign Up Button
                    Button(action: handleSignup) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Account erstellen")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ColorTheme.accentPink)
                        )
                        .opacity(isLoading ? 0.7 : 1.0)
                    }
                    .disabled(isLoading || !isFormValid)
                    .padding(.horizontal, 20)
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("Mit der Erstellung eines Kontos stimmst du unseren")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        HStack(spacing: 4) {
                            Button("Nutzungsbedingungen") {
                                // Handle terms tap
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorTheme.accentPink)
                            
                            Text("und")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(ColorTheme.secondaryText)
                            
                            Button("Datenschutzrichtlinie") {
                                // Handle privacy tap
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorTheme.accentPink)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(ColorTheme.cardBackground)
            .navigationTitle("E-Mail Registrierung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        email.contains("@")
    }
    
    private func handleSignup() {
        isLoading = true
        showError = false
        
        // Validate passwords match
        if password != confirmPassword {
            showError = true
            errorMessage = "Passwörter stimmen nicht überein"
            isLoading = false
            return
        }
        
        // Validate password length
        if password.count < 6 {
            showError = true
            errorMessage = "Passwort muss mindestens 6 Zeichen lang sein"
            isLoading = false
            return
        }
        
        // Validate email format
        if !email.contains("@") {
            showError = true
            errorMessage = "Bitte gib eine gültige E-Mail-Adresse ein"
            isLoading = false
            return
        }
        
        // Store credentials securely for later use
        Task {
            do {
                try SecurityService.shared.secureStore(email, forKey: "userEmail")
                try SecurityService.shared.secureStore(password, forKey: "userPassword")
                
                // Try to complete onboarding with Supabase
                do {
                    let supabaseUser = try await SupabaseService.shared.completeOnboarding(
                        email: email,
                        password: password,
                        name: name,
                        birthDate: birthDate
                    )
                    
                    // If we get here, email confirmation was not required
                    // Create user and complete onboarding
                    let user = User(name: name, birthDate: birthDate)
                    appState.completeOnboarding(user: user)
                    appState.completeOnboardingWithSupabase(user: user)
                    
                    // Save relationship data
                    await saveRelationshipData()
                    
                    DispatchQueue.main.async {
                        isLoading = false
                        dismiss()
                        NotificationCenter.default.post(name: .registrationCompleted, object: nil)
                    }
                    
                } catch AuthError.validationError {
                    // Email confirmation required
                    DispatchQueue.main.async {
                        isLoading = false
                        showingEmailConfirmation = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        isLoading = false
                        showError = true
                        errorMessage = "Fehler beim Erstellen des Kontos: \(error.localizedDescription)"
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                    errorMessage = "Fehler beim Speichern der Anmeldedaten: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveRelationshipData() async {
        do {
            guard let userId = appState.currentUser?.id else { return }
            
            try await SupabaseService.shared.updateRelationshipData(
                userId: userId.uuidString,
                relationshipStatus: relationshipStatus.rawValue,
                hasChildren: hasChildren ? "true" : "false",
                childrenCount: String(childrenCount)
            )
        } catch {
            print("❌ Error saving relationship data: \(error)")
        }
    }
}

// MARK: - Apple Sign In View
struct AppleSignInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let name: String
    let birthDate: Date
    let relationshipStatus: RelationshipStatus
    let hasChildren: Bool
    let childrenCount: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 80))
                        .foregroundColor(.black)
                    
                    Text("Mit Apple anmelden")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Schnell und sicher mit deinem Apple ID anmelden")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Apple Sign In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(25)
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Anmeldung läuft...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .navigationTitle("Apple Anmeldung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .alert("Anmeldefehler", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let appleUserID = appleIDCredential.user
                
                // Create user and complete onboarding
                let user = User(name: name, birthDate: birthDate)
                appState.completeOnboardingWithAppleID(user: user, appleUserID: appleUserID)
                
                // Save relationship data
                Task {
                    await saveRelationshipData()
                    
                    DispatchQueue.main.async {
                        isLoading = false
                        dismiss()
                        NotificationCenter.default.post(name: .registrationCompleted, object: nil)
                    }
                }
            } else {
                isLoading = false
                showError = true
                errorMessage = "Ungültige Anmeldedaten"
            }
            
        case .failure(let error):
            isLoading = false
            showError = true
            errorMessage = "Anmeldefehler: \(error.localizedDescription)"
        }
    }
    
    private func saveRelationshipData() async {
        do {
            guard let userId = appState.currentUser?.id else { return }
            
            try await SupabaseService.shared.updateRelationshipData(
                userId: userId.uuidString,
                relationshipStatus: relationshipStatus.rawValue,
                hasChildren: hasChildren ? "true" : "false",
                childrenCount: String(childrenCount)
            )
        } catch {
            print("❌ Error saving relationship data: \(error)")
        }
    }
}

// MARK: - Simple Partner Connection View
struct SimplePartnerConnectionView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCodeGeneration = false
    @State private var showingCodeEntry = false
    @State private var connectionCode = ""
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentBlue)
                    
                    Text("Partner Connection")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Connect with your partner to share memories and moments")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Connection options
                VStack(spacing: 20) {
                    Button(action: {
                        showingCodeGeneration = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Generate Connection Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [ColorTheme.primaryPurple, ColorTheme.accentPink], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(color: ColorTheme.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        showingCodeEntry = true
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Enter Partner's Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.success)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Skip for now")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .foregroundColor(ColorTheme.secondaryText)
                        .cornerRadius(25)
                    }
                }
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Partner Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCodeGeneration) {
                CodeGenerationView()
                    .environmentObject(partnerManager)
            }
            .sheet(isPresented: $showingCodeEntry) {
                CodeEntryView()
                    .environmentObject(partnerManager)
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Code Generation View
struct CodeGenerationView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var generatedCode = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentBlue)
                    
                    Text("Generate Connection Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Share this code with your partner to connect")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Generated code display
                if !generatedCode.isEmpty {
                    VStack(spacing: 20) {
                        Text("Your Connection Code")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text(generatedCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(ColorTheme.accentPink)
                            .padding()
                            .background(ColorTheme.cardBackground)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(ColorTheme.accentPink, lineWidth: 2)
                            )
                        
                        Button(action: {
                            UIPasteboard.general.string = generatedCode
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Code")
                            }
                            .foregroundColor(ColorTheme.accentPink)
                        }
                    }
                    .purpleCard()
                }
                
                // Generate button
                Button(action: {
                    generateCode()
                }) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Code")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [ColorTheme.primaryPurple, ColorTheme.accentPink], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(isGenerating)
                }
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Generate Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateCode() {
        isGenerating = true
        
        // Generate a random 6-digit code
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            generatedCode = code
            isGenerating = false
        }
    }
}

// MARK: - Code Entry View
struct CodeEntryView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode = ""
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "link")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.success)
                    
                    Text("Enter Partner's Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Enter the 6-digit code your partner shared with you")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Code input
                VStack(spacing: 20) {
                    Text("Connection Code")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    TextField("000000", text: $enteredCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: enteredCode) { oldValue, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                enteredCode = String(newValue.prefix(6))
                            }
                            // Only allow numbers
                            enteredCode = newValue.filter { $0.isNumber }
                        }
                }
                .purpleCard()
                
                // Connect button
                Button(action: {
                    connectWithPartner()
                }) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "link.circle")
                        }
                        Text(isConnecting ? "Connecting..." : "Connect with Partner")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [ColorTheme.success, ColorTheme.accentBlue], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(enteredCode.count != 6 || isConnecting)
                }
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Enter Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Connection Successful", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You are now connected with your partner!")
            }
        }
    }
    
    private func connectWithPartner() {
        guard enteredCode.count == 6 else {
            errorMessage = "Please enter a valid 6-digit code"
            showingError = true
            return
        }
        
        isConnecting = true
        
        // Simulate connection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isConnecting = false
            
            // For demo purposes, accept any 6-digit code
            if enteredCode.count == 6 {
                showingSuccess = true
                // Here you would actually call partnerManager.connectWithPartner(using: enteredCode)
            } else {
                errorMessage = "Invalid connection code. Please try again."
                showingError = true
            }
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let registrationCompleted = Notification.Name("registrationCompleted")
} 