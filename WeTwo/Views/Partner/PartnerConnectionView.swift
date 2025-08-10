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
                    
                    Text("partner_connection_title".localized)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("partner_connection_subtitle".localized)
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
                            Text("partner_generate_code".localized)
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
                        Text("partner_or".localized)
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                            .padding(.horizontal, 10)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    
                    // Enter code section
                    VStack(spacing: 15) {
                        Text("partner_enter_code".localized)
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        TextField("partner_code_placeholder".localized, text: $connectionCode)
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
                                Text("partner_connect".localized)
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
            .navigationTitle("partner_connection_nav_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("partner_close".localized) {
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
        
        Task {
            do {
                try await partnerManager.connectWithPartner(using: connectionCode)
                await MainActor.run {
                    isConnecting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    if let partnerError = error as? PartnerError {
                        errorMessage = partnerError.localizedDescription
                    } else {
                        errorMessage = NSLocalizedString("partner_error_unknown", comment: "An unknown error occurred")
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
                    Text("partner_qr_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("partner_qr_subtitle".localized)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("partner_qr_nav_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("partner_close".localized) {
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