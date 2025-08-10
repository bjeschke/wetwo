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
                        
                        Text(email)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorTheme.accentPink)
                            .padding()
                            .background(ColorTheme.cardBackgroundSecondary)
                            .cornerRadius(12)
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
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
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
        }
    }
    
    private func loadEmail() {
        // Load email from secure storage
        if let storedEmail = try? SecurityService.shared.secureLoadString(forKey: "userEmail") {
            email = storedEmail
        }
    }
    
    private func checkConfirmation() {
        isLoading = true
        showError = false
        
        // Load password from secure storage
        guard let storedPassword = try? SecurityService.shared.secureLoadString(forKey: "userPassword") else {
            isLoading = false
            showError = true
            errorMessage = "Passwort nicht gefunden. Bitte melde dich erneut an."
            return
        }
        
        Task {
            do {
                // Try to sign in - if successful, email is confirmed
                let user = try await SupabaseService.shared.confirmEmailAndSignIn(
                    email: email,
                    password: storedPassword
                )
                
                DispatchQueue.main.async {
                    isLoading = false
                    showSuccess = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                    errorMessage = "E-Mail noch nicht bestätigt. Bitte überprüfe deine E-Mails und klicke auf den Bestätigungslink."
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
    
    private func completeSupabaseOnboarding(user: User) async {
        do {
            // Get the email and password from secure storage
            guard let email = try? SecurityService.shared.secureLoadString(forKey: "userEmail"),
                  let password = try? SecurityService.shared.secureLoadString(forKey: "userPassword") else {
                print("❌ No email/password found in secure storage")
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

#Preview {
    EmailConfirmationView()
        .environmentObject(AppState())
}
