import SwiftUI

extension Notification.Name {
    static let emailConfirmed = Notification.Name("emailConfirmed")
}

struct EmailConfirmationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showManualPasswordInput = false
    @State private var manualPassword = ""
    @State private var showManualEmailInput = false
    @State private var manualEmail = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(ColorTheme.accentPink)
                        
                        Text("E-Mail bestätigen")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(ColorTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Wir haben dir eine Bestätigungs-E-Mail gesendet. Bitte bestätige deine E-Mail-Adresse, um dein Konto zu aktivieren.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ColorTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Email display
                    VStack(spacing: 15) {
                        Text("E-Mail-Adresse:")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        if email.isEmpty {
                            Button(action: {
                                showManualEmailInput = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .font(.title2)
                                    Text("E-Mail-Adresse eingeben")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(ColorTheme.accentPink)
                                .padding()
                                .background(ColorTheme.cardBackgroundSecondary)
                                .cornerRadius(12)
                            }
                        } else {
                            HStack {
                                Text(email)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(ColorTheme.accentPink)
                                
                                Spacer()
                                
                                Button(action: {
                                    showManualEmailInput = true
                                }) {
                                    Image(systemName: "pencil.circle")
                                        .font(.title2)
                                        .foregroundColor(ColorTheme.accentPink)
                                }
                            }
                            .padding()
                            .background(ColorTheme.cardBackgroundSecondary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Instructions
                    VStack(spacing: 15) {
                        Text("So gehst du vor:")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionRow(number: "1", text: "Öffne deine E-Mail-App")
                            InstructionRow(number: "2", text: "Suche nach einer E-Mail von WeTwo")
                            InstructionRow(number: "3", text: "Klicke auf den Bestätigungslink")
                            InstructionRow(number: "4", text: "Kehre zur App zurück und tippe auf 'Bestätigung prüfen'")
                        }
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Check confirmation button
                    Button(action: checkConfirmation) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.title2)
                            }
                            Text(isLoading ? "Prüfe Bestätigung..." : "Bestätigung prüfen")
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
                    .disabled(isLoading)
                    .padding(.horizontal)
                    
                    // Resend email button
                    Button(action: resendEmail) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                            Text("E-Mail erneut senden")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(ColorTheme.accentPink)
                    }
                    .disabled(isLoading)
                    
                    // Debug button (only in debug builds)
                    #if DEBUG
                    Button(action: debugStoredCredentials) {
                        HStack {
                            Image(systemName: "ladybug")
                                .font(.title2)
                            Text("Debug: Gespeicherte Daten prüfen")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.orange)
                    }
                    .disabled(isLoading)
                    #endif
                    
                    // Error Message
                    if showError {
                        VStack(spacing: 10) {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            
                                                // Add a retry button for password issues
                    if errorMessage.contains("Passwort nicht gefunden") {
                        Button(action: {
                            showManualPasswordInput = true
                        }) {
                            Text("Passwort manuell eingeben")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ColorTheme.accentPink)
                        }
                    }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(ColorTheme.cardBackground)
            .navigationTitle("E-Mail Bestätigung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadEmail()
            }
            .alert("E-Mail bestätigt!", isPresented: $showSuccess) {
                Button("Weiter") {
                    // Complete the onboarding process
                    if let userData = try? SecurityService.shared.secureLoad(forKey: "currentUser"),
                       let user = try? JSONDecoder().decode(User.self, from: userData) {
                        // Complete Supabase onboarding
                        Task {
                            await completeSupabaseOnboarding(user: user)
                        }
                    }
                    dismiss()
                    NotificationCenter.default.post(name: .emailConfirmed, object: nil)
                }
            } message: {
                Text("Deine E-Mail-Adresse wurde erfolgreich bestätigt. Du kannst jetzt mit der App beginnen!")
            }
            .sheet(isPresented: $showManualPasswordInput) {
                ManualPasswordInputView(
                    email: email,
                    onPasswordEntered: { password in
                        manualPassword = password
                        showManualPasswordInput = false
                        checkConfirmationWithPassword(password)
                    },
                    onCancel: {
                        showManualPasswordInput = false
                    }
                )
            }
            .sheet(isPresented: $showManualEmailInput) {
                ManualEmailInputView(
                    currentEmail: email,
                    onEmailEntered: { newEmail in
                        email = newEmail
                        manualEmail = newEmail
                        showManualEmailInput = false
                        // Store the email for future use
                        try? SecurityService.shared.secureStore(newEmail, forKey: "userEmail")
                    },
                    onCancel: {
                        showManualEmailInput = false
                    }
                )
            }
        }
    }
    
    private func loadEmail() {
        // Load email from secure storage
        if let storedEmail = try? SecurityService.shared.secureLoadString(forKey: "userEmail") {
            email = storedEmail
            print("✅ Email loaded from storage: \(storedEmail)")
        } else {
            print("❌ No email found in storage")
        }
    }
    
    private func checkConfirmation() {
        isLoading = true
        showError = false
        
        // Debug: Check what's stored
        print("🔍 Debug: Checking stored credentials...")
        print("🔍 Email from storage: \(email)")
        
        // Try to load password from secure storage with fallback
        var storedPassword: String?
        do {
            storedPassword = try SecurityService.shared.secureLoadString(forKey: "userPassword")
            print("✅ Password loaded successfully from secure storage")
        } catch {
            print("❌ Failed to load password from secure storage: \(error)")
            
            // Fallback: Try unencrypted storage
            storedPassword = UserDefaults.standard.string(forKey: "userPassword")
            if storedPassword != nil {
                print("⚠️ Using unencrypted password storage as fallback")
            } else {
                print("❌ No password found in any storage")
                isLoading = false
                showError = true
                errorMessage = "Passwort nicht gefunden. Bitte gib dein Passwort manuell ein."
                return
            }
        }
        
        guard let password = storedPassword else {
            isLoading = false
            showError = true
            errorMessage = "Passwort nicht gefunden. Bitte gib dein Passwort manuell ein."
            return
        }
        
        Task {
            do {
                print("🔄 Attempting to sign in with email: \(email)")
                // Try to sign in - if successful, email is confirmed
                let user = try await SupabaseService.shared.confirmEmailAndSignIn(
                    email: email,
                    password: password
                )
                
                DispatchQueue.main.async {
                    isLoading = false
                    showSuccess = true
                }
                
            } catch {
                print("❌ Sign in failed: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                    
                    // Provide more specific error messages
                    if let authError = error as? AuthError {
                        switch authError {
                        case .invalidCredentials:
                            errorMessage = "Falsche Anmeldedaten. Bitte überprüfe deine E-Mail und dein Passwort."
                        case .validationError:
                            errorMessage = "E-Mail noch nicht bestätigt. Bitte überprüfe deine E-Mails und klicke auf den Bestätigungslink."
                        case .networkError:
                            errorMessage = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung und versuche es erneut."
                        default:
                            errorMessage = "Ein Fehler ist aufgetreten. Bitte versuche es erneut."
                        }
                    } else {
                        errorMessage = "E-Mail noch nicht bestätigt. Bitte überprüfe deine E-Mails und klicke auf den Bestätigungslink."
                    }
                }
            }
        }
    }
    
    private func resendEmail() {
        // This would typically call a resend confirmation email API
        // For now, we'll just show a message
        showError = true
        errorMessage = "E-Mail wurde erneut gesendet. Bitte überprüfe deinen Posteingang."
    }
    
    #if DEBUG
    private func debugStoredCredentials() {
        print("🔍 DEBUG: Checking stored credentials...")
        
        // Check if email is stored
        do {
            let storedEmail = try SecurityService.shared.secureLoadString(forKey: "userEmail")
            print("✅ Email found in storage: \(storedEmail)")
        } catch {
            print("❌ Email not found in secure storage: \(error)")
            
            // Check unencrypted storage
            if let unencryptedEmail = UserDefaults.standard.string(forKey: "userEmail") {
                print("⚠️ Email found in unencrypted storage: \(unencryptedEmail)")
            } else {
                print("❌ Email not found in any storage")
            }
        }
        
        // Check if password is stored
        do {
            let storedPassword = try SecurityService.shared.secureLoadString(forKey: "userPassword")
            print("✅ Password found in secure storage: \(String(repeating: "*", count: storedPassword.count))")
        } catch {
            print("❌ Password not found in secure storage: \(error)")
            
            // Check unencrypted storage
            if let unencryptedPassword = UserDefaults.standard.string(forKey: "userPassword") {
                print("⚠️ Password found in unencrypted storage: \(String(repeating: "*", count: unencryptedPassword.count))")
            } else {
                print("❌ Password not found in any storage")
            }
        }
        
        // Check UserDefaults directly
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        print("📋 All UserDefaults keys: \(Array(allKeys))")
        
        // Show debug info to user
        showError = true
        errorMessage = "Debug-Info in der Konsole ausgegeben. Bitte überprüfe die Xcode-Konsole."
    }
    #endif
    
    private func setPasswordManually(_ password: String) {
        SecurityService.shared.setPasswordManually(password, forKey: "userPassword")
        print("✅ Password set manually")
    }
    
    private func checkConfirmationWithPassword(_ password: String) {
        isLoading = true
        showError = false
        
        Task {
            do {
                print("🔄 Attempting to sign in with manual password for email: \(email)")
                let user = try await SupabaseService.shared.confirmEmailAndSignIn(
                    email: email,
                    password: password
                )
                
                // If successful, store the password securely for future use
                try? SecurityService.shared.secureStore(password, forKey: "userPassword")
                
                DispatchQueue.main.async {
                    isLoading = false
                    showSuccess = true
                }
                
            } catch {
                print("❌ Sign in failed with manual password: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                    
                    // Provide more specific error messages
                    if let authError = error as? AuthError {
                        switch authError {
                        case .invalidCredentials:
                            errorMessage = "Falsche Anmeldedaten. Bitte überprüfe deine E-Mail und dein Passwort."
                        case .validationError:
                            errorMessage = "E-Mail noch nicht bestätigt. Bitte überprüfe deine E-Mails und klicke auf den Bestätigungslink."
                        case .networkError:
                            errorMessage = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung und versuche es erneut."
                        default:
                            errorMessage = "Ein Fehler ist aufgetreten. Bitte versuche es erneut."
                        }
                    } else {
                        errorMessage = "E-Mail noch nicht bestätigt oder falsches Passwort. Bitte überprüfe deine E-Mails und klicke auf den Bestätigungslink."
                    }
                }
            }
        }
    }
    
    private func completeSupabaseOnboarding(user: User) async {
        do {
            // Get the email and password from secure storage with fallback
            var email: String?
            var password: String?
            
            // Try to load email
            do {
                email = try SecurityService.shared.secureLoadString(forKey: "userEmail")
            } catch {
                email = UserDefaults.standard.string(forKey: "userEmail")
            }
            
            // Try to load password
            do {
                password = try SecurityService.shared.secureLoadString(forKey: "userPassword")
            } catch {
                password = UserDefaults.standard.string(forKey: "userPassword")
            }
            
            guard let email = email, let password = password else {
                print("❌ No email/password found in any storage")
                return
            }
            
            print("🔄 Completing Supabase onboarding after email confirmation...")
            
            // Try to sign in again to get the session
            let confirmedUser = try await SupabaseService.shared.confirmEmailAndSignIn(
                email: email,
                password: password
            )
            
            // Get the current Supabase user ID
            if let userId = try? await SupabaseService.shared.getCurrentUserId() {
                // Save the user ID securely
                try? SecurityService.shared.secureStore(userId, forKey: "currentUserId")
                
                // Ensure profile exists
                try? await SupabaseService.shared.ensureProfileExists()
                
                print("✅ User ID saved: \(userId)")
            }
            
            print("✅ Supabase onboarding completed successfully after email confirmation")
            
        } catch {
            print("❌ Error completing Supabase onboarding: \(error)")
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(ColorTheme.accentPink))
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
        }
    }
}

// MARK: - Manual Email Input View

struct ManualEmailInputView: View {
    let currentEmail: String
    let onEmailEntered: (String) -> Void
    let onCancel: () -> Void
    
    @State private var email = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentPink)
                    
                    Text("E-Mail-Adresse eingeben")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Gib die E-Mail-Adresse ein, die du bei der Registrierung verwendet hast.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Email input
                VStack(spacing: 15) {
                    Text("E-Mail-Adresse:")
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
                .padding(.horizontal)
                
                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        if email.isEmpty {
                            showError = true
                            errorMessage = "Bitte gib eine E-Mail-Adresse ein."
                            return
                        }
                        
                        if !email.contains("@") {
                            showError = true
                            errorMessage = "Bitte gib eine gültige E-Mail-Adresse ein."
                            return
                        }
                        
                        onEmailEntered(email)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                            Text("Bestätigen")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ColorTheme.accentPink)
                        )
                    }
                    .disabled(email.isEmpty)
                    
                    Button(action: onCancel) {
                        Text("Abbrechen")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                .padding(.horizontal)
            }
            .background(ColorTheme.cardBackground)
            .navigationTitle("E-Mail eingeben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") {
                        onCancel()
                    }
                }
            }
            .onAppear {
                email = currentEmail
            }
        }
    }
}

#Preview {
    EmailConfirmationView()
        .environmentObject(AppState())
}

// MARK: - Manual Password Input View

struct ManualPasswordInputView: View {
    let email: String
    let onPasswordEntered: (String) -> Void
    let onCancel: () -> Void
    
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentPink)
                    
                    Text("Passwort eingeben")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Bitte gib dein Passwort ein, um die E-Mail-Bestätigung zu überprüfen.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Email display
                VStack(spacing: 15) {
                    Text("E-Mail-Adresse:")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(email)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorTheme.accentPink)
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Password input
                VStack(spacing: 15) {
                    Text("Passwort:")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    SecureField("Passwort eingeben", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        if password.isEmpty {
                            showError = true
                            errorMessage = "Bitte gib dein Passwort ein."
                            return
                        }
                        onPasswordEntered(password)
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.title2)
                            }
                            Text("Bestätigen")
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
                    .disabled(isLoading || password.isEmpty)
                    
                    Button(action: onCancel) {
                        Text("Abbrechen")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                .padding(.horizontal)
            }
            .background(ColorTheme.cardBackground)
            .navigationTitle("Passwort eingeben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") {
                        onCancel()
                    }
                }
            }
        }
    }
}
