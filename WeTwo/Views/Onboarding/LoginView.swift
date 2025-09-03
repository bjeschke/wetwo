import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: FirebaseAuthService
    @Environment(\.dismiss) private var dismiss
    
    let prefillEmail: String
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showForgotPassword = false
    
    // Initialize with optional prefill email
    init(prefillEmail: String = "") {
        self.prefillEmail = prefillEmail
    }
    
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
            .onAppear {
                if !prefillEmail.isEmpty {
                    email = prefillEmail
                }
            }
        }
    }
    
    private func handleLogin() {
        isLoading = true
        showError = false
        
        Task {
            do {
                print("🔄 Attempting login directly with Firebase using email: \(email)")
                
                // For login, we authenticate directly with Firebase
                // The backend has already created the Firebase user during signup
                let firebaseUser = try await authService.signIn(
                    email: email,
                    password: password
                )
                
                print("✅ Firebase authentication successful: \(firebaseUser.uid)")
                
                // Get the Firebase ID token for future backend API calls
                let idToken = try await authService.getIDToken()
                print("🔑 Firebase ID Token obtained for future API calls")
                
                // Create user object with Firebase UID
                let appUser = User(
                    id: firebaseUser.uid,
                    email: email,
                    name: firebaseUser.displayName ?? email.components(separatedBy: "@").first ?? "User"
                )
                
                // Update app state with authenticated user
                await MainActor.run {
                    appState.currentUser = appUser
                    appState.firebaseIdToken = idToken
                    appState.isOnboarded = true
                    appState.isOnboarding = false
                    isLoading = false
                    dismiss()
                }
                
                print("✅ Login successful")
                
            } catch {
                print("❌ Login failed: \(error)")
                
                // Handle specific backend and Firebase auth errors
                let errorMsg: String
                
                if let backendError = error as? BackendError {
                    switch backendError {
                    case .invalidCredentials:
                        errorMsg = "Falsches Passwort oder E-Mail-Adresse."
                    case .userNotFound:
                        errorMsg = "Benutzer nicht gefunden. Bitte registriere dich zuerst."
                    case .networkError:
                        errorMsg = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
                    default:
                        errorMsg = "Anmeldung fehlgeschlagen: \(backendError.localizedDescription)"
                    }
                } else {
                    // Handle Firebase auth errors
                    let errorCode = (error as NSError).code
                    switch errorCode {
                    case 17009: // Wrong password
                        errorMsg = "Falsches Passwort. Bitte überprüfe deine Anmeldedaten."
                    case 17011: // User not found
                        errorMsg = "Benutzer nicht gefunden. Bitte registriere dich zuerst."
                    case 17020: // Network error
                        errorMsg = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
                    default:
                        errorMsg = "Anmeldung fehlgeschlagen: \(error.localizedDescription)"
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = errorMsg
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
                            throw BackendError.invalidCredentials
                        }
                        
                        
                        let user = try await ServiceFactory.shared.getCurrentService().signInWithApple(
                            idToken: idTokenString,
                            nonce: UUID().uuidString
                        )
                        
                        // Store Apple User ID
                        let appleUserID = appleIDCredential.user
                        
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
                try await authService.sendPasswordResetEmail(to: email)
                await MainActor.run {
                    showError = true
                    errorMessage = "E-Mail zum Zurücksetzen des Passworts wurde gesendet. Bitte überprüfe deinen Posteingang."
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Fehler beim Senden der E-Mail: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
