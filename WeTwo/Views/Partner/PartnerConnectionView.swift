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
                    // Generate code button
                    Button(action: generateConnectionCode) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Code generieren")
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
                        Text("Code eingeben")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        TextField("Partner-Code eingeben", text: $connectionCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
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
        isConnecting = true
        errorMessage = ""
        
        // Simulate generating a connection code
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            connectionCode = String(format: "%06d", Int.random(in: 100000...999999))
            showingQRCode = true
            isConnecting = false
        }
    }
    
    private func connectWithCode() {
        guard !connectionCode.isEmpty else { return }
        
        isConnecting = true
        errorMessage = ""
        
        print("🔗 Attempting to connect with code: \(connectionCode)")
        
        Task {
            do {
                // The backend expects partnerEmail
                // In a real app, the connection code would map to a partner email
                // For now, we use the entered code as the partner email if it contains @
                let partnerEmail: String
                if connectionCode.contains("@") {
                    partnerEmail = connectionCode
                } else {
                    // For testing: map specific codes to test emails
                    switch connectionCode {
                    case "TEST1":
                        partnerEmail = "partner2_1756932268@test.de"
                    case "TEST2":
                        partnerEmail = "partner1_1756932267@test.de"
                    default:
                        // If it's a numeric code, assume it's a test user ID
                        partnerEmail = "test\(connectionCode)@test.de"
                    }
                }
                
                print("📧 Connecting with partner email: \(partnerEmail)")
                
                let backendService = BackendService.shared
                
                // Generate connection code for this partnership
                let connectionCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
                
                let partnership = try await backendService.createPartnership(
                    partnerEmail: partnerEmail,
                    message: "Let's connect!",
                    connectionCode: connectionCode
                )
                
                print("✅ Partnership created successfully: \(partnership)")
                
                await MainActor.run {
                    isConnecting = false
                    errorMessage = "Partnership created! ID: \(partnership.id ?? 0)"
                    // Don't dismiss yet so user can see the message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
                        errorMessage = backendError.localizedDescription
                    } else {
                        errorMessage = "Connection failed: \(error.localizedDescription)"
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