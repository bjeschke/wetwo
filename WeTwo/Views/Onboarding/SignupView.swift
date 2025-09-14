import SwiftUI
import AuthenticationServices
import CryptoKit

extension Notification.Name {
    static let signupCompleted = Notification.Name("signupCompleted")
    static let showLogin = Notification.Name("showLogin")
}

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject var authService: FirebaseAuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showEmailExistsAlert = false
    @State private var showLogin = false
    @State private var prefillEmail = ""

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("Create Your Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(.label))
                        
                        Text("Start your journey together")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(.systemGray))
                    }
                    .padding(.top, 40)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        AppleStyleInputField(
                            placeholder: "Full Name",
                            text: $fullName,
                            textContentType: .name,
                            autocapitalization: .words
                        )
                        
                        AppleStyleInputField(
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        AppleStyleInputField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            textContentType: .newPassword
                        )
                        
                        AppleStyleInputField(
                            placeholder: "Confirm Password",
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
                                Text("Create Account")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor)
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
                    
                    // Already have an account?
                    HStack {
                        Text("Bereits registriert?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(.systemGray))
                        
                        Button("Zur Anmeldung") {
                            showLogin = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                    }
                    .padding(.top, 16)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By creating an account, you agree to our")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(.systemGray))
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                // Handle terms tap
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                            
                            Text("and")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(.systemGray))
                            
                            Button("Privacy Policy") {
                                // Handle privacy tap
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .alert("Account bereits vorhanden", isPresented: $showEmailExistsAlert) {
                Button("Zur Anmeldung") {
                    prefillEmail = email
                    showLogin = true
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Ein Account mit der Email-Adresse '\(email)' existiert bereits. Möchtest du dich stattdessen anmelden?")
            }
            .sheet(isPresented: $showLogin) {
                LoginView(prefillEmail: prefillEmail)
                    .environmentObject(appState)
                    .environmentObject(deepLinkHandler)
            }
            .alert("Fehler", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }

        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        !fullName.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        email.contains("@")
    }
    
    private func handleSignup() {
        isLoading = true
        showError = false
        
        print("🔧 Starting signup process for email: \(email)")
        
        // Validate passwords match
        if password != confirmPassword {
            showError = true
            errorMessage = "Passwords don't match"
            isLoading = false
            return
        }
        
        // Validate password length
        if password.count < 6 {
            showError = true
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Validate email format
        if !email.contains("@") {
            showError = true
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        // Validate full name
        if fullName.isEmpty {
            showError = true
            errorMessage = "Please enter your full name"
            isLoading = false
            return
        }
        
        // Backend handles complete registration including Firebase
        Task {
            do {
                print("🔧 Creating user account via backend service...")
                
                // Register user through BackendService - backend creates Firebase user
                let backendService = BackendService.shared
                let backendUser = try await backendService.signUpDirectly(
                    email: email,
                    password: password,
                    name: fullName,
                    birthDate: Date()
                )
                
                print("✅ Backend registration successful")
                print("🔑 Firebase UID from backend: \(backendUser.firebaseUid ?? "none")")
                print("🔗 Partner code from backend: \(backendUser.partnerCode ?? "none")")
                
                // Now sign in to Firebase with email/password
                // The backend already created the Firebase user with the same credentials
                do {
                    let firebaseUser = try await authService.signIn(
                        email: email,
                        password: password
                    )
                    print("✅ Firebase authentication successful: \(firebaseUser.uid)")
                    
                    // Get the Firebase ID token for future backend calls
                    let idToken = try await authService.getIDToken()
                    print("🔑 Firebase ID Token obtained for future API calls")
                    
                    // Create the user object with Firebase UID
                    let appUser = User(
                        id: firebaseUser.uid,
                        email: email,
                        name: fullName
                    )
                    
                    // Store partner code from backend if available
                    if let partnerCode = backendUser.partnerCode {
                        UserDefaults.standard.set(partnerCode, forKey: "userPartnerCode")
                        print("✅ Partner code stored: \(partnerCode)")
                    }
                    
                    // Update app state with authenticated user
                    await MainActor.run {
                        appState.currentUser = appUser
                        appState.firebaseIdToken = idToken
                        appState.isOnboarded = true
                        appState.isOnboarding = false
                        isLoading = false
                        NotificationCenter.default.post(name: .signupCompleted, object: nil)
                    }
                    
                } catch {
                    print("❌ Firebase authentication with custom token failed: \(error)")
                    // This should not happen if backend properly created the Firebase user
                    await MainActor.run {
                        isLoading = false
                        showError = true
                        errorMessage = "Authentication failed. Please try logging in."
                        // Redirect to login
                        prefillEmail = email
                        showLogin = true
                    }
                }
                
            } catch {
                print("❌ Registration error: \(error)")
                
                // Handle specific backend errors
                if let backendError = error as? BackendError {
                    await MainActor.run {
                        isLoading = false
                        if backendError == BackendError.emailAlreadyExists {
                            showEmailExistsAlert = true
                        } else {
                            showError = true
                            errorMessage = backendError.localizedDescription
                        }
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        showError = true
                        errorMessage = "Error creating account: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
