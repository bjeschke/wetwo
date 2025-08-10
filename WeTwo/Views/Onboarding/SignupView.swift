import SwiftUI
import AuthenticationServices
import CryptoKit

extension Notification.Name {
    static let signupCompleted = Notification.Name("signupCompleted")
    static let emailConfirmed = Notification.Name("emailConfirmed")
}

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var currentStep = 0
    @State private var isLoginMode = false
    @State private var shouldProceedToNextStep = false
    @State private var needsEmailConfirmation = false
    @State private var pendingEmail = ""
    @State private var pendingPassword = ""
    @State private var pendingName = ""
    @State private var pendingBirthDate = Date()
    @State private var showingEmailConfirmation = false
    
    private var totalSteps: Int {
        if isLoginMode {
            return 2
        } else {
            return 4
        }
    }
    
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
                    signupStep
                case 1:
                    if isLoginMode {
                        credentialsStep
                    } else {
                        credentialsStep
                    }
                case 2:
                    if !isLoginMode {
                        nameStep
                    } else {
                        EmptyView()
                    }
                case 3:
                    if !isLoginMode {
                        birthdateStep
                    } else {
                        EmptyView()
                    }
                default:
                    EmptyView()
                }
                
                Spacer(minLength: 50)
                
                // Navigation buttons
                navigationButtons
            }
            .padding()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showingEmailConfirmation) {
            EmailConfirmationView(
                email: pendingEmail,
                password: pendingPassword,
                onConfirmed: {
                    // Email was confirmed, proceed to onboarding
                    DispatchQueue.main.async {
                        // Clear pending data
                        pendingEmail = ""
                        pendingPassword = ""
                        pendingName = ""
                        pendingBirthDate = Date()
                        
                        showingEmailConfirmation = false
                        NotificationCenter.default.post(name: .emailConfirmed, object: nil)
                    }
                }
            )
            .environmentObject(appState)
        }
    }
    
    // MARK: - Step Views
    
    private var signupStep: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ColorTheme.accentPink)
                
                Text(isLoginMode ? NSLocalizedString("login_title", comment: "Login title") : NSLocalizedString("signup_title", comment: "Signup title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(isLoginMode ? NSLocalizedString("login_subtitle", comment: "Login subtitle") : NSLocalizedString("signup_subtitle", comment: "Signup subtitle"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            // Signup/Login options
            VStack(spacing: 20) {
                // Apple Sign-In Button
                SignInWithAppleButton { request in
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = SecurityService.sha256(SecurityService.generateNonce())
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(25)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.3))
                    
                    Text(NSLocalizedString("signup_or", comment: "Or divider"))
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(.horizontal, 20)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.3))
                }
                
                // Email Signup/Login Button
                Button(action: {
                    withAnimation {
                        currentStep = 1
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text(isLoginMode ? NSLocalizedString("login_with_email", comment: "Login with email") : NSLocalizedString("signup_with_email", comment: "Sign up with email"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.accentPink)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
            }
            .padding(.horizontal)
            
            // Toggle between signup and login
            Button(action: {
                withAnimation {
                    isLoginMode.toggle()
                    currentStep = 0
                    email = ""
                    password = ""
                    confirmPassword = ""
                    name = ""
                    birthDate = Date()
                }
            }) {
                Text(isLoginMode ? NSLocalizedString("signup_no_account", comment: "Don't have an account? Sign up") : NSLocalizedString("login_has_account", comment: "Already have an account? Log in"))
                    .font(.body)
                    .foregroundColor(ColorTheme.primaryText)
                    .underline()
            }
            .padding(.top, 20)
        }
    }
    
    private var credentialsStep: some View {
        VStack(spacing: 30) {
            Text(isLoginMode ? NSLocalizedString("login_credentials_title", comment: "Login credentials title") : NSLocalizedString("signup_credentials_title", comment: "Credentials title"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("signup_email_label", comment: "Email label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField(NSLocalizedString("signup_email_placeholder", comment: "Email placeholder"), text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Password input
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("signup_password_label", comment: "Password label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    SecureField(NSLocalizedString("signup_password_placeholder", comment: "Password placeholder"), text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Confirm password input (only for signup)
                if !isLoginMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("signup_confirm_password_label", comment: "Confirm password label"))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        SecureField(NSLocalizedString("signup_confirm_password_placeholder", comment: "Confirm password placeholder"), text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var nameStep: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("signup_name_title", comment: "What's your name?"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text(NSLocalizedString("signup_name_subtitle", comment: "Tell us your name"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.secondaryText)
            
            VStack(spacing: 20) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("signup_name_label", comment: "Name label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField(NSLocalizedString("signup_name_placeholder", comment: "Name placeholder"), text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .autocorrectionDisabled()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var birthdateStep: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("signup_birthdate_title", comment: "When were you born?"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text(NSLocalizedString("signup_birthdate_subtitle", comment: "Tell us your birth date"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.secondaryText)
            
            VStack(spacing: 20) {
                // Birth date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("signup_birthdate_label", comment: "Birth date label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DatePicker(
                        NSLocalizedString("signup_birthdate_placeholder", comment: "Birth date placeholder"),
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .background(Color.white)
                    .cornerRadius(8)
                }
                
                // Zodiac sign display
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("signup_zodiac_label", comment: "Zodiac sign label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(ZodiacSign.calculate(from: birthDate).emoji)
                            .font(.title2)
                        
                        Text(ZodiacSign.calculate(from: birthDate).rawValue)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(NSLocalizedString("signup_back", comment: "Back button")) {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .foregroundColor(ColorTheme.primaryText)
            }
            
            Spacer()
            
            // Show next button for credentials step and name step (signup), action button for login or final step
            if (currentStep == 1 || currentStep == 2) && !isLoginMode {
                Button(NSLocalizedString("signup_next", comment: "Next button")) {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(ColorTheme.accentPink)
                .cornerRadius(25)
                .disabled(!isCurrentStepValid)
            } else {
                Button(action: {
                    if isLoginMode {
                        loginUser()
                    } else {
                        createAccount()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(isLoginMode ? NSLocalizedString("login_sign_in", comment: "Sign in button") : NSLocalizedString("signup_create_account", comment: "Create account button"))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(ColorTheme.accentPink)
                    .cornerRadius(25)
                }
                .disabled(!isFormValid || isLoading)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Validation
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1: // Credentials step
            if isLoginMode {
                return !email.isEmpty && !password.isEmpty
            } else {
                return !email.isEmpty && 
                !password.isEmpty && 
                password == confirmPassword && 
                password.count >= 6
            }
        case 2: // Name step
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && 
            !password.isEmpty && 
            password == confirmPassword && 
            password.count >= 6 &&
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await signInWithApple(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            print("Apple Sign-In failed: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Extract user information
            let fullName = credential.fullName
            let userID = credential.user
            
            // Get the ID token from Apple
            guard let idToken = credential.identityToken,
                  let idTokenString = String(data: idToken, encoding: .utf8) else {
                print("❌ Failed to get ID token from Apple")
                errorMessage = "Failed to get authentication token from Apple"
                showingError = true
                return
            }
            
            // Generate a secure nonce for Apple Sign-In
            let rawNonce = SecurityService.generateNonce()
            let hashedNonce = SecurityService.sha256(rawNonce)
            
            // Create a user name from Apple's data
            let userName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let displayName = userName.isEmpty ? "User" : userName
            
            // Try to sign in with Apple ID first
            do {
                let user = try await SupabaseService.shared.signInWithApple(
                    idToken: idTokenString,
                    nonce: hashedNonce
                )
                
                print("✅ Apple Sign-In successful")
                
                // Set user and continue with onboarding
                appState.currentUser = user
                
                // Save to secure storage
                if let encoded = try? JSONEncoder().encode(user) {
                    try? SecurityService.shared.secureStore(encoded, forKey: "currentUser")
                }
                
                // Store Apple ID securely
                try? SecurityService.shared.secureStore(userID, forKey: "appleUserID")
                
                // Signal that we should proceed to the next onboarding step
                shouldProceedToNextStep = true
                NotificationCenter.default.post(name: .signupCompleted, object: nil)
                
            } catch {
                // If sign-in fails, try to sign up
                print("⚠️ Apple Sign-In failed, trying Sign-Up: \(error)")
                
                let user = try await SupabaseService.shared.signUpWithApple(
                    idToken: idTokenString,
                    nonce: hashedNonce,
                    name: displayName,
                    birthDate: Date()
                )
                
                print("✅ Apple Sign-Up successful")
                
                // Set user and continue with onboarding
                appState.currentUser = user
                
                // Save to secure storage
                if let encoded = try? JSONEncoder().encode(user) {
                    try? SecurityService.shared.secureStore(encoded, forKey: "currentUser")
                }
                
                // Store Apple ID securely
                try? SecurityService.shared.secureStore(userID, forKey: "appleUserID")
                
                // Signal that we should proceed to the next onboarding step
                shouldProceedToNextStep = true
                NotificationCenter.default.post(name: .signupCompleted, object: nil)
            }
            
        } catch {
            print("❌ Apple authentication failed: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func createAccount() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                // Store pending data for email confirmation using DeepLinkHandler
                deepLinkHandler.storePendingConfirmation(
                    email: email,
                    password: password,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    birthDate: birthDate
                )
                
                // Also store locally for the current session
                pendingEmail = email
                pendingPassword = password
                pendingName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                pendingBirthDate = birthDate
                
                // Attempt to sign up with Supabase
                _ = try await SupabaseService.shared.signUp(
                    email: email,
                    password: password,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    birthDate: birthDate
                )
                
                // If we get here, the signup was successful but email confirmation is required
                print("✅ Account created successfully, email confirmation required")
                
                // Show email confirmation screen
                DispatchQueue.main.async {
                    showingEmailConfirmation = true
                }
                
            } catch {
                print("Error creating account: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isLoading = false
        }
    }
    
    private func loginUser() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                // Attempt to sign in with Supabase
                let user = try await SupabaseService.shared.signIn(email: email, password: password)
                
                // If successful, set the user and continue
                appState.currentUser = user
                
                // Save to secure storage
                if let encoded = try? JSONEncoder().encode(user) {
                    try? SecurityService.shared.secureStore(encoded, forKey: "currentUser")
                }
                
                // Signal that we should proceed to the next onboarding step
                shouldProceedToNextStep = true
                NotificationCenter.default.post(name: .signupCompleted, object: nil)
                
            } catch {
                print("Error logging in: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Email Confirmation
}

// MARK: - Email Confirmation View

struct EmailConfirmationView: View {
    let email: String
    let password: String
    let onConfirmed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var checkTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 80))
                        .foregroundColor(ColorTheme.accentPink)
                    
                    Text(NSLocalizedString("email_confirmation_title", comment: "Confirm your email"))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(NSLocalizedString("email_confirmation_subtitle", comment: "We sent a confirmation email to"))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Email display
                VStack(spacing: 15) {
                    Text(email)
                        .font(.headline)
                        .foregroundColor(ColorTheme.accentPink)
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .cornerRadius(12)
                    
                    Text(NSLocalizedString("email_confirmation_instructions", comment: "Please check your email and click the confirmation link, then return here to continue"))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(.horizontal)
                }
                
                // Only resend button
                Button(action: {
                    Task {
                        await resendConfirmationEmail()
                    }
                }) {
                    Text(NSLocalizedString("email_confirmation_resend", comment: "Resend confirmation email"))
                        .font(.body)
                        .foregroundColor(ColorTheme.primaryText)
                        .underline()
                }
                .disabled(isLoading)
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Email Confirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                startEmailConfirmationCheck()
            }
            .onDisappear {
                stopEmailConfirmationCheck()
            }
            .onChange(of: deepLinkHandler.pendingEmailConfirmation) { isPending in
                if !isPending && deepLinkHandler.emailConfirmationData == nil {
                    // Email was confirmed via deep link
                    onConfirmed()
                }
            }
        }
    }
    
    private func startEmailConfirmationCheck() {
        // Check every 3 seconds if email was confirmed
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task {
                await checkEmailConfirmation()
            }
        }
    }
    
    private func stopEmailConfirmationCheck() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func checkEmailConfirmation() async {
        // Try to sign in with pending credentials
        // If successful, email was confirmed
        do {
            let user = try await SupabaseService.shared.confirmEmailAndSignIn(
                email: email,
                password: password
            )
            
            // If we get here, email was confirmed successfully
            DispatchQueue.main.async {
                // Set the user in app state
                appState.currentUser = user
                
                // Save to secure storage
                if let encoded = try? JSONEncoder().encode(user) {
                    try? SecurityService.shared.secureStore(encoded, forKey: "currentUser")
                }
                
                // Stop checking and proceed
                stopEmailConfirmationCheck()
                onConfirmed()
            }
        } catch {
            // Email not confirmed yet, continue checking
            print("Email not confirmed yet: \(error)")
        }
    }
    
    private func resendConfirmationEmail() async {
        do {
            try await SupabaseService.shared.signIn(email: email)
            print("✅ Confirmation email resent")
        } catch {
            print("❌ Error resending confirmation email: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AppState())
}
