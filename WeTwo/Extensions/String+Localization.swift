import Foundation

extension String {
    var localized: String {
        // Verwende die aktuelle Gerätesprache
        let currentLocale = Locale.current
        let languageCode = currentLocale.languageCode ?? "en"
        
        print("🌍 Current language code: \(languageCode)")
        print("🌍 Current locale: \(currentLocale.identifier)")
        
        // Versuche zuerst die spezifische Sprache zu laden
        if let languagePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let languageBundle = Bundle(path: languagePath) {
            print("✅ Found language bundle for: \(languageCode)")
            return NSLocalizedString(self, bundle: languageBundle, comment: "")
        }
        
        // Fallback: Versuche die erste verfügbare Sprache
        let availableLanguages = Bundle.main.localizations
        print("🌍 Available languages: \(availableLanguages)")
        
        if let firstLanguage = availableLanguages.first,
           let languagePath = Bundle.main.path(forResource: firstLanguage, ofType: "lproj"),
           let languageBundle = Bundle(path: languagePath) {
            print("✅ Using fallback language: \(firstLanguage)")
            return NSLocalizedString(self, bundle: languageBundle, comment: "")
        }
        
        // Final fallback auf die Standard-Lokalisierung
        print("⚠️ Using default localization")
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    // Spezifische Lokalisierung für bestimmte Sprachen
    var localizedSpanish: String {
        if let spanishPath = Bundle.main.path(forResource: "es", ofType: "lproj"),
           let spanishBundle = Bundle(path: spanishPath) {
            return NSLocalizedString(self, bundle: spanishBundle, comment: "")
        }
        return NSLocalizedString(self, comment: "")
    }
    
    var localizedGerman: String {
        if let germanPath = Bundle.main.path(forResource: "de", ofType: "lproj"),
           let germanBundle = Bundle(path: germanPath) {
            return NSLocalizedString(self, bundle: germanBundle, comment: "")
        }
        return NSLocalizedString(self, comment: "")
    }
    
    var localizedEnglish: String {
        if let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let englishBundle = Bundle(path: englishPath) {
            return NSLocalizedString(self, bundle: englishBundle, comment: "")
        }
        return NSLocalizedString(self, comment: "")
    }
} 