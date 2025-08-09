//
//  ColorTheme.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct ColorTheme {
    // Dunkler Lila Hintergrund
    static let primaryPurple = Color(red: 0.2, green: 0.1, blue: 0.4)  // Dunkleres Lila
    static let secondaryPurple = Color(red: 0.25, green: 0.15, blue: 0.5)  // Noch dunkleres Lila
    
    // Akzent-Farben
    static let accentPink = Color(red: 0.9, green: 0.3, blue: 0.6)
    static let accentBlue = Color(red: 0.3, green: 0.7, blue: 0.9)
    
    // Text-Farben
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    // Hellere Lila Cards
    static let cardBackground = Color(red: 0.4, green: 0.2, blue: 0.7)  // Helleres Lila für Cards
    static let cardBackgroundSecondary = Color(red: 0.45, green: 0.25, blue: 0.75)  // Noch helleres Lila
    
    // Status-Farben
    static let error = Color.red
    static let success = Color.green
    static let warning = Color.orange
}

extension View {
    func purpleTheme() -> some View {
        self.background(
            LinearGradient(
                colors: [ColorTheme.primaryPurple, ColorTheme.secondaryPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    func purpleCard() -> some View {
        self.background(ColorTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
