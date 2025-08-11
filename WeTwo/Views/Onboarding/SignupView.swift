import SwiftUI
import AuthenticationServices
import CryptoKit

extension Notification.Name {
    static let signupCompleted = Notification.Name("signupCompleted")
}

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingEmailConfirmation = false
    
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
            .sheet(isPresented: $showingEmailConfirmation) {
                EmailConfirmationView()
                    .environmentObject(appState)
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
        
        // Store credentials securely for later use
        Task {
            do {
                print("🔧 Storing credentials securely...")
                try SecurityService.shared.secureStore(email, forKey: "userEmail")
                try SecurityService.shared.secureStore(password, forKey: "userPassword")
                
                // Verify storage was successful
                let storedEmail = try SecurityService.shared.secureLoadString(forKey: "userEmail")
                let storedPassword = try SecurityService.shared.secureLoadString(forKey: "userPassword")
                print("✅ Credentials stored and verified:")
                print("   Email: \(storedEmail)")
                print("   Password: \(String(repeating: "*", count: storedPassword.count))")
                
                print("🔧 Attempting to complete signup with Supabase...")
                
                // Try to complete signup with Supabase
                do {
                    let _ = try await SupabaseService.shared.completeOnboarding(
                        email: email,
                        password: password,
                        name: fullName,
                        birthDate: Date() // Using current date as fallback since we don't have birth date in this view
                    )
                    
                    print("✅ Signup completed successfully without email confirmation")
                    
                    // If we get here, email confirmation was not required
                    // Create user and complete signup
                    let user = User(name: fullName, birthDate: Date())
                    appState.completeOnboarding(user: user)
                    appState.completeOnboardingWithSupabase(user: user)
                    
                    DispatchQueue.main.async {
                        isLoading = false
                        NotificationCenter.default.post(name: .signupCompleted, object: nil)
                    }
                    
                } catch AuthError.validationError {
                    print("⚠️ Email confirmation required - showing email confirmation screen")
                    // Email confirmation required
                    DispatchQueue.main.async {
                        isLoading = false
                        showingEmailConfirmation = true
                    }
                } catch {
                    print("❌ Error during signup: \(error)")
                    print("❌ Error type: \(type(of: error))")
                    
                    // For debugging: if no specific error is caught, still show email confirmation
                    // This helps if Supabase project doesn't require email confirmation but we want to test the flow
                    if error.localizedDescription.contains("validation") || error.localizedDescription.contains("confirm") {
                        print("⚠️ Assuming email confirmation required based on error message")
                        DispatchQueue.main.async {
                            isLoading = false
                            showingEmailConfirmation = true
                        }
                    } else {
                        DispatchQueue.main.async {
                            isLoading = false
                            showError = true
                            errorMessage = "Error creating account: \(error.localizedDescription)"
                        }
                    }
                }
                
            } catch {
                print("❌ Error storing credentials: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                    errorMessage = "Error storing credentials: \(error.localizedDescription)"
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
