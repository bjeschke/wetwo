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
                    
                    Text("Test the deep link functionality")
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
                        Text("Ready")
                            .font(.body)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(ColorTheme.cardBackgroundSecondary)
                    .cornerRadius(12)
                    

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
                    
                    Button("Clear Data") {
                        // Clear any pending data
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
        // Simulate a deep link
        let testURL = URL(string: "wetwo://test?data=test_data")!
        deepLinkHandler.handleDeepLink(testURL)
    }
}

#Preview {
    DeepLinkTestView()
        .environmentObject(DeepLinkHandler())
}
