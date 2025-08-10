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
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                            autocapitalization: .none
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
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            
            // Validate passwords match
            if password != confirmPassword {
                showError = true
                errorMessage = "Passwords don't match"
                return
            }
            
            // Validate password length
            if password.count < 6 {
                showError = true
                errorMessage = "Password must be at least 6 characters"
                return
            }
            
            // Validate email format
            if !email.contains("@") {
                showError = true
                errorMessage = "Please enter a valid email address"
                return
            }
            
            // Proceed with signup
            // TODO: Implement actual signup logic
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
