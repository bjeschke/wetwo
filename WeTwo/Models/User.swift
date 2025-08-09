//
//  User.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

struct User: Codable, Identifiable {
    let id = UUID()
    var name: String
    var zodiacSign: ZodiacSign
    var birthDate: Date
    var partnerCode: String?
    var partnerId: UUID?
    var profileImageData: Data?
    var preferences: UserPreferences
    
    init(name: String, birthDate: Date) {
        self.name = name
        self.birthDate = birthDate
        self.zodiacSign = ZodiacSign.calculate(from: birthDate)
        self.preferences = UserPreferences()
    }
    
    // Legacy initializer for backward compatibility
    init(name: String, zodiacSign: ZodiacSign, birthDate: Date) {
        self.name = name
        self.zodiacSign = zodiacSign
        self.birthDate = birthDate
        self.preferences = UserPreferences()
    }
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool = true
    var dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var theme: AppTheme = .romantic
    var language: String = "en"
}

enum ZodiacSign: String, CaseIterable, Codable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    var emoji: String {
        switch self {
        case .aries: return "♈️"
        case .taurus: return "♉️"
        case .gemini: return "♊️"
        case .cancer: return "♋️"
        case .leo: return "♌️"
        case .virgo: return "♍️"
        case .libra: return "♎️"
        case .scorpio: return "♏️"
        case .sagittarius: return "♐️"
        case .capricorn: return "♑️"
        case .aquarius: return "♒️"
        case .pisces: return "♓️"
        }
    }
    
    var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fire"
        case .taurus, .virgo, .capricorn: return "Earth"
        case .gemini, .libra, .aquarius: return "Air"
        case .cancer, .scorpio, .pisces: return "Water"
        }
    }
    
    // Calculate zodiac sign from birth date
    static func calculate(from birthDate: Date) -> ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: birthDate)
        let day = calendar.component(.day, from: birthDate)
        
        switch (month, day) {
        case (3, 21...31), (4, 1...19):
            return .aries
        case (4, 20...30), (5, 1...20):
            return .taurus
        case (5, 21...31), (6, 1...20):
            return .gemini
        case (6, 21...30), (7, 1...22):
            return .cancer
        case (7, 23...31), (8, 1...22):
            return .leo
        case (8, 23...31), (9, 1...22):
            return .virgo
        case (9, 23...30), (10, 1...22):
            return .libra
        case (10, 23...31), (11, 1...21):
            return .scorpio
        case (11, 22...30), (12, 1...21):
            return .sagittarius
        case (12, 22...31), (1, 1...19):
            return .capricorn
        case (1, 20...31), (2, 1...18):
            return .aquarius
        case (2, 19...29), (3, 1...20):
            return .pisces
        default:
            return .aries // Fallback
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case romantic = "romantic"
    case cozy = "cozy"
    case playful = "playful"
    case mystical = "mystical"
} 