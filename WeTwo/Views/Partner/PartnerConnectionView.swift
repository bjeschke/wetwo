import SwiftUI

struct PartnerConnectionView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var connectionCode = ""
    @State private var showingQRCode = false
    @State private var isConnecting = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentBlue)
                    
                    Text("Partner verbinden")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Verbinde dich mit deinem Partner")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Connection options
                VStack(spacing: 20) {
                    // Show own code button
                    Button(action: generateConnectionCode) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Mein Code anzeigen")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // Or divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("ODER")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                            .padding(.horizontal, 10)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    
                    // Enter code section
                    VStack(spacing: 15) {
                        Text("Partner-Code eingeben")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        TextField("6-stelliger Code", text: $connectionCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .onChange(of: connectionCode) { newValue in
                                // Automatically convert to uppercase and limit to 6 characters
                                connectionCode = String(newValue.uppercased().prefix(6))
                            }
                        
                        Button(action: connectWithCode) {
                            HStack {
                                if isConnecting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "link")
                                }
                                Text("Verbinden")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .disabled(connectionCode.isEmpty || isConnecting)
                        }
                    }
                }
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingQRCode) {
                QRCodeView(code: connectionCode)
            }
        }
    }
    
    private func generateConnectionCode() {
        // Show the user's own partner code from backend
        if let storedCode = UserDefaults.standard.string(forKey: "userPartnerCode") {
            connectionCode = storedCode
            showingQRCode = true
        } else {
            // Try to refresh from backend
            isConnecting = true
            errorMessage = ""
            
            Task {
                await partnerManager.refreshConnectionCodeFromBackend()
                await MainActor.run {
                    connectionCode = partnerManager.ownConnectionCode
                    if connectionCode != "PENDING" {
                        showingQRCode = true
                    } else {
                        errorMessage = "Could not load your partner code. Please try again."
                    }
                    isConnecting = false
                }
            }
        }
    }
    
    private func connectWithCode() {
        guard !connectionCode.isEmpty else { return }
        
        isConnecting = true
        errorMessage = ""
        
        print("🔗 Attempting to connect with partner code: \(connectionCode)")
        
        Task {
            do {
                let backendService = BackendService.shared
                
                // Send invitation using the partner's code
                let partnership = try await backendService.sendInvitation(withCode: connectionCode)
                
                print("✅ Partnership created successfully via invitation: \(partnership)")
                
                // Update partner manager with the new connection
                await partnerManager.loadPartnershipStatus()
                
                await MainActor.run {
                    isConnecting = false
                    errorMessage = "Erfolgreich verbunden!"
                    // Dismiss after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                print("❌ Partnership connection failed: \(error)")
                await MainActor.run {
                    isConnecting = false
                    if let partnerError = error as? PartnerError {
                        errorMessage = partnerError.localizedDescription
                    } else if let backendError = error as? BackendError {
                        switch backendError {
                        case .partnerNotFound:
                            errorMessage = "Ungültiger Partner-Code. Bitte überprüfen Sie den Code und versuchen Sie es erneut."
                        case .invalidData:
                            errorMessage = "Der eingegebene Code ist ungültig."
                        case .alreadyConnected:
                            errorMessage = "Sie sind bereits mit einem Partner verbunden."
                        default:
                            errorMessage = backendError.localizedDescription
                        }
                    } else {
                        errorMessage = "Verbindung fehlgeschlagen: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct QRCodeView: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // QR Code placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text(code)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ColorTheme.primaryText)
                        }
                    )
                
                VStack(spacing: 15) {
                    Text("Dein QR-Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Lass deinen Partner diesen Code scannen")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR-Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PartnerConnectionView()
        .environmentObject(PartnerManager.shared)
} 