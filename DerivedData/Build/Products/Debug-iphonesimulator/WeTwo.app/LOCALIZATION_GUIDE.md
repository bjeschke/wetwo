# Lokalisierungs-Guide für WeTwo App

## 🌍 Übersicht

Die WeTwo App unterstützt jetzt **3 Sprachen**:
- 🇩🇪 **Deutsch** (Standard)
- 🇺🇸 **Englisch**
- 🇪🇸 **Spanisch**

## 📁 Dateistruktur

```
WeTwo/Resources/
├── Localizable.strings          # Deutsche Strings (Standard)
├── en.lproj/
│   └── Localizable.strings      # Englische Strings
└── es.lproj/
    └── Localizable.strings      # Spanische Strings
```

## 🔧 Verwendung

### 1. Strings in Views verwenden

```swift
// Einfache Lokalisierung
Text("today_title".localized)

// Mit Parametern
Text("welcome_message".localized(with: userName))

// Direkt über LocalizationManager
Text(LocalizationManager.shared.localizedString(for: "today_title"))
```

### 2. Lokalisierung in Code

```swift
// String Extension
let title = "today_title".localized

// LocalizationManager
let title = LocalizationManager.shared.localizedString(for: "today_title")

// Mit Parametern
let message = "welcome_user".localized(with: userName, userAge)
```

### 3. Datum und Zahlen formatieren

```swift
// Datum formatieren
let dateString = LocalizationManager.shared.formatDate(Date())

// Zahlen formatieren
let numberString = LocalizationManager.shared.formatNumber(1234)

// Prozent formatieren
let percentageString = LocalizationManager.shared.formatPercentage(85.5)
```

## 🎛️ Sprachauswahl

### In den Einstellungen
1. Gehe zu **Profil** → **Einstellungen**
2. Tippe auf **Sprache**
3. Wähle deine bevorzugte Sprache:
   - 🌐 **Gerätesprache** (Standard)
   - 🇩🇪 **Deutsch**
   - 🇺🇸 **English**
   - 🇪🇸 **Español**

### Automatische Erkennung
- **Standard**: Verwendet die Gerätesprache
- **Fallback**: Falls die Gerätesprache nicht unterstützt wird → Deutsch
- **Speicherung**: Die gewählte Sprache wird gespeichert

## 📝 Neue Strings hinzufügen

### 1. String-Key definieren
Füge den Key zu allen Sprachdateien hinzu:

**Deutsch (Localizable.strings):**
```strings
"new_feature_title" = "Neue Funktion";
```

**Englisch (en.lproj/Localizable.strings):**
```strings
"new_feature_title" = "New Feature";
```

**Spanisch (es.lproj/Localizable.strings):**
```strings
"new_feature_title" = "Nueva función";
```

### 2. In der App verwenden
```swift
Text("new_feature_title".localized)
```

## 🔄 Sprachwechsel

### Automatisch
- Die App erkennt Sprachänderungen automatisch
- Alle Texte werden sofort aktualisiert
- Datum und Zahlen werden entsprechend formatiert

### Manuell
```swift
// Sprache programmatisch ändern
LocalizationManager.shared.currentLanguage = .english

// Benachrichtigung über Sprachänderung
NotificationCenter.default.addObserver(
    forName: .languageChanged,
    object: nil,
    queue: .main
) { _ in
    // UI aktualisieren
}
```

## 📊 Unterstützte Formate

### Datum
```swift
// Verschiedene Datum-Stile
LocalizationManager.shared.formatDate(Date(), style: .short)    // 01.01.24
LocalizationManager.shared.formatDate(Date(), style: .medium)   // 1. Jan 2024
LocalizationManager.shared.formatDate(Date(), style: .long)     // 1. Januar 2024
LocalizationManager.shared.formatDate(Date(), style: .full)     // Montag, 1. Januar 2024
```

### Zeit
```swift
LocalizationManager.shared.formatTime(Date(), style: .short)    // 14:30
LocalizationManager.shared.formatTime(Date(), style: .medium)   // 14:30:45
```

### Zahlen
```swift
LocalizationManager.shared.formatNumber(1234)        // 1.234 (DE) / 1,234 (EN)
LocalizationManager.shared.formatPercentage(85.5)    // 86% (DE) / 86% (EN)
```

## 🏷️ Kategorien

### Allgemein
- `ok`, `cancel`, `save`, `delete`, `edit`, `close`
- `loading`, `error`, `success`

### Onboarding
- `onboarding_welcome_title`, `onboarding_name_title`
- `onboarding_zodiac_title`, `onboarding_birthdate_title`

### Tab Navigation
- `tab_today`, `tab_timeline`, `tab_calendar`
- `tab_partner`, `tab_profile`

### Today View
- `today_title`, `today_mood_happy`, `today_mood_sad`
- `today_add_event`, `today_generate_insight`

### Timeline
- `timeline_title`, `timeline_add_memory`
- `timeline_no_memories`, `timeline_stats_total`

### Memory
- `memory_new_title`, `memory_photo_title`
- `memory_title_label`, `memory_description_label`

### Partner
- `partner_title`, `partner_not_connected`
- `partner_connect_now`, `partner_compatibility`

### Profile & Settings
- `profile_title`, `profile_settings`
- `settings_language`, `settings_notifications`

### Premium
- `premium_title`, `premium_subtitle`
- `premium_monthly`, `premium_yearly`

### Sternzeichen
- `zodiac_aries`, `zodiac_taurus`, `zodiac_gemini`
- Alle 12 Sternzeichen

### Fehler & Erfolg
- `error_network`, `error_auth`, `error_upload`
- `success_memory_created`, `success_profile_updated`

### Quick Tags
- `tag_vacation`, `tag_date_night`, `tag_birthday`
- `tag_anniversary`, `tag_travel`, `tag_food`

## 🚀 Best Practices

### 1. Konsistente Namensgebung
```swift
// ✅ Gut
"today_title"
"memory_new_title"
"partner_connect_button"

// ❌ Schlecht
"title"
"new_memory"
"connect"
```

### 2. Kommentare verwenden
```swift
"today_title" = "Wie fühlst du dich heute?"; // Title for today's mood input
```

### 3. Parameter verwenden
```swift
// In Strings-Datei
"welcome_user" = "Willkommen, %@! Du bist %d Jahre alt.";

// In Code
Text("welcome_user".localized(with: userName, userAge))
```

### 4. Pluralisierung
```swift
// Für verschiedene Sprachen
"memory_count" = "%d Erinnerung";     // DE
"memory_count" = "%d memory";         // EN
"memory_count" = "%d recuerdo";       // ES

// Im Code
let count = memories.count
if count == 1 {
    Text("memory_count".localized(with: count))
} else {
    Text("memories_count".localized(with: count))
}
```

## 🔍 Debugging

### Fehlende Übersetzungen finden
```swift
// In der Konsole werden Warnungen ausgegeben:
// ⚠️ Missing localization for key: missing_key
```

### Aktuelle Sprache prüfen
```swift
print("Current language: \(LocalizationManager.shared.currentLanguage)")
print("Current locale: \(LocalizationManager.shared.currentLanguage.locale)")
```

### Alle verfügbaren Sprachen
```swift
for language in LocalizationManager.AppLanguage.allCases {
    print("\(language.flag) \(language.displayName)")
}
```

## 📱 Testing

### 1. Alle Sprachen testen
- App in verschiedenen Sprachen starten
- Sprachwechsel in Einstellungen testen
- Datum/Zeit-Formatierung prüfen

### 2. Edge Cases
- Sehr lange Texte in verschiedenen Sprachen
- Sonderzeichen und Emojis
- RTL-Sprachen (falls später hinzugefügt)

### 3. Performance
- Sprachwechsel-Geschwindigkeit
- Memory-Usage bei vielen Strings

## 🔮 Erweiterungen

### Weitere Sprachen hinzufügen
1. Neuen Ordner erstellen: `fr.lproj/`
2. `Localizable.strings` Datei hinzufügen
3. `AppLanguage` Enum erweitern
4. Alle Strings übersetzen

### RTL-Support
- Für Arabisch, Hebräisch, etc.
- Layout-Anpassungen nötig

### Voice-Over
- Accessibility-Labels lokalisieren
- Voice-Over-Texte hinzufügen

## 📚 Ressourcen

- [Apple Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [SwiftUI Localization](https://developer.apple.com/documentation/swiftui/environmentvalues/locale)
- [NSLocalizedString Documentation](https://developer.apple.com/documentation/foundation/nslocalizedstring)

---

**Viel Erfolg mit der mehrsprachigen WeTwo App! 🌍💕** 