//
//  DeepLinkTestView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct DeepLinkTestView: View {
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(ColorTheme.accentPink)
                    
                    Text("Deep Link Test")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Test the email confirmation deep link functionality")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Status
                VStack(spacing: 15) {
                    HStack {
                        Text("Deep Link Status:")
                            .font(.headline)
                        Spacer()
                        Text(deepLinkHandler.pendingEmailConfirmation ? "Processing" : "Ready")
                            .font(.body)
                            .foregroundColor(deepLinkHandler.pendingEmailConfirmation ? .orange : .green)
                    }
                    .padding()
                    .background(ColorTheme.cardBackgroundSecondary)
                    .cornerRadius(12)
                    
                    if let confirmationData = deepLinkHandler.emailConfirmationData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmation Data:")
                                .font(.headline)
                            Text("Email: \(confirmationData.email)")
                                .font(.body)
                            Text("Name: \(confirmationData.name)")
                                .font(.body)
                        }
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .cornerRadius(12)
                    }
                }
                
                // Test buttons
                VStack(spacing: 15) {
                    Button("Test Deep Link") {
                        testDeepLink()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.accentPink)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    
                    Button("Clear Pending Data") {
                        deepLinkHandler.clearPendingConfirmation()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.cardBackgroundSecondary)
                    .foregroundColor(ColorTheme.primaryText)
                    .cornerRadius(25)
                }
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Deep Link Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func testDeepLink() {
        // Simulate a Supabase email confirmation link
        let testURL = URL(string: "wetwo://email-confirmation?access_token=test_token&type=signup&token_hash=test_hash")!
        deepLinkHandler.handleDeepLink(testURL)
    }
}

#Preview {
    DeepLinkTestView()
        .environmentObject(DeepLinkHandler())
}
