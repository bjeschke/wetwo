import SwiftUI

struct PartnerCodeInputSheet: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var partnerManager = PartnerManager.shared

    @Binding var partnerCode: String
    let authenticatedUser: User?
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var isConnecting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentPink)

                    Text("Partner verbinden")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primaryText)

                    Text("Hast du bereits einen Partner-Code von deinem Partner erhalten?")
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)

                // Partner code input
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Partner-Code eingeben:")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)

                        TextField("Code eingeben", text: $partnerCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(ColorTheme.cardBackgroundSecondary)
                            .cornerRadius(12)
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal)

                    // Connect button
                    Button(action: connectWithPartner) {
                        HStack {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "link")
                                    .font(.title3)
                            }
                            Text(isConnecting ? "Verbinde..." : "Verbinden")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(partnerCode.isEmpty ? Color.gray : ColorTheme.accentPink)
                        )
                    }
                    .disabled(partnerCode.isEmpty || isConnecting)
                    .padding(.horizontal)

                    // Error message
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                Spacer()

                // Skip button
                Button(action: onSkip) {
                    Text("Später verbinden")
                        .font(.body)
                        .foregroundColor(ColorTheme.accentBlue)
                }
                .padding(.bottom, 30)
            }
            .background(ColorTheme.cardBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Überspringen") {
                        onSkip()
                    }
                }
            }
        }
    }

    private func connectWithPartner() {
        guard !partnerCode.isEmpty else { return }

        isConnecting = true
        showError = false

        Task {
            do {
                try await partnerManager.connectWithPartner(using: partnerCode)

                await MainActor.run {
                    isConnecting = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    showError = true
                    errorMessage = "Verbindung fehlgeschlagen. Bitte überprüfe den Code."
                }
            }
        }
    }
}

#Preview {
    PartnerCodeInputSheet(
        partnerCode: .constant(""),
        authenticatedUser: nil,
        onComplete: {},
        onSkip: {}
    )
    .environmentObject(AppState())
}