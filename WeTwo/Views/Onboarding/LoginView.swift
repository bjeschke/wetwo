import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [ColorTheme.primaryPurple, ColorTheme.secondaryPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Header
                        VStack(spacing: 20) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 80))
                                .foregroundColor(ColorTheme.accentPink)
                            
                            Text("Willkommen zurück!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ColorTheme.primaryText)
                                .multilineTextAlignment(.center)
                            
                            Text("Melde dich mit deinen Anmeldedaten an")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(ColorTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                        
                        // Login form
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("E-Mail-Adresse")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.primaryText)
                                
                                TextField("deine@email.com", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(ColorTheme.cardBackgroundSecondary)
                                    .cornerRadius(12)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Passwort")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.primaryText)
                                
                                SecureField("Dein Passwort", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                    .background(ColorTheme.cardBackgroundSecondary)
                                    .cornerRadius(12)
                            }
                            
                            // Forgot password button
                            HStack {
                                Spacer()
                                Button(action: {
                                    showForgotPassword = true
                                }) {
                                    Text("Passwort vergessen?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorTheme.accentPink)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Login button
                        Button(action: handleLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                }
                                Text(isLoading ? "Anmelden..." : "Anmelden")
                                    .font(.system(size: 16, weight: .semibold))
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
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal)
                        
                        // Error message
                        if showError {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(ColorTheme.secondaryText.opacity(0.3))
                            Text("oder")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ColorTheme.secondaryText)
                                .padding(.horizontal, 20)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(ColorTheme.secondaryText.opacity(0.3))
                        }
                        .padding(.horizontal)
                        
                        // Apple Sign In
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .background(ColorTheme.cardBackground)
            .navigationTitle("Anmelden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .alert("Passwort zurücksetzen", isPresented: $showForgotPassword) {
                Button("E-Mail senden") {
                    handleForgotPassword()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Wir senden dir eine E-Mail mit einem Link zum Zurücksetzen deines Passworts.")
            }
        }
    }
    
    private func handleLogin() {
        isLoading = true
        showError = false
        
        Task {
            do {
                print("🔄 Attempting to sign in with email: \(email)")
                
                // Try to sign in with Supabase
                let user = try await SupabaseService.shared.signIn(email: email, password: password)
                
                // Store credentials securely for future use
                try SecurityService.shared.secureStore(email, forKey: "userEmail")
                try SecurityService.shared.secureStore(password, forKey: "userPassword")
                
                // Get the current Supabase user ID
                if let userId = try? await SupabaseService.shared.getCurrentUserId() {
                    try? SecurityService.shared.secureStore(userId, forKey: "currentUserId")
                    print("✅ User ID saved: \(userId)")
                }
                
                // Ensure profile exists
                try? await SupabaseService.shared.ensureProfileExists()
                
                DispatchQueue.main.async {
                    isLoading = false
                    
                    // Create a User object and complete onboarding
                    let appUser = User(name: user.name, birthDate: user.birthDate)
                    appState.completeOnboarding(user: appUser)
                    appState.completeOnboardingWithSupabase(user: appUser)
                    
                    dismiss()
                }
                
                print("✅ Login successful")
                
            } catch {
                print("❌ Login failed: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                    
                    // Provide specific error messages
                    if let authError = error as? AuthError {
                        switch authError {
                        case .invalidCredentials:
                            errorMessage = "Falsche E-Mail oder Passwort. Bitte überprüfe deine Anmeldedaten."
                        case .userNotFound:
                            errorMessage = "Benutzer nicht gefunden. Bitte registriere dich zuerst."
                        case .networkError:
                            errorMessage = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
                        default:
                            errorMessage = "Anmeldung fehlgeschlagen. Bitte versuche es erneut."
                        }
                    } else {
                        errorMessage = "Anmeldung fehlgeschlagen. Bitte überprüfe deine Anmeldedaten."
                    }
                }
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    do {
                        guard let idToken = appleIDCredential.identityToken,
                              let idTokenString = String(data: idToken, encoding: .utf8) else {
                            throw AuthError.invalidCredentials
                        }
                        
                        let nonce = SecurityService.generateNonce()
                        let hashedNonce = SecurityService.sha256(nonce)
                        
                        let user = try await SupabaseService.shared.signInWithApple(
                            idToken: idTokenString,
                            nonce: hashedNonce
                        )
                        
                        // Store Apple User ID
                        let appleUserID = appleIDCredential.user
                        try? SecurityService.shared.secureStore(appleUserID, forKey: "appleUserID")
                        
                        DispatchQueue.main.async {
                            let appUser = User(name: user.name, birthDate: user.birthDate)
                            let appleUserID = appleIDCredential.user
                            appState.completeOnboardingWithAppleID(user: appUser, appleUserID: appleUserID)
                            dismiss()
                        }
                        
                    } catch {
                        DispatchQueue.main.async {
                            showError = true
                            errorMessage = "Apple Sign-In fehlgeschlagen. Bitte versuche es erneut."
                        }
                    }
                }
            }
        case .failure(let error):
            print("❌ Apple Sign-In failed: \(error)")
            showError = true
            errorMessage = "Apple Sign-In fehlgeschlagen. Bitte versuche es erneut."
        }
    }
    
    private func handleForgotPassword() {
        guard !email.isEmpty else {
            showError = true
            errorMessage = "Bitte gib deine E-Mail-Adresse ein."
            return
        }
        
        Task {
            do {
                try await SupabaseService.shared.signIn(email: email)
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "E-Mail zum Zurücksetzen des Passworts wurde gesendet. Bitte überprüfe deinen Posteingang."
                }
            } catch {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "Fehler beim Senden der E-Mail. Bitte versuche es erneut."
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
