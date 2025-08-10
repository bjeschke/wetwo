# Apple Sign-In Setup für WeTwo App

## 🍎 Supabase Konfiguration

### 1. Apple Developer Account Setup

1. Gehe zu [developer.apple.com](https://developer.apple.com)
2. Melde dich mit deinem Apple Developer Account an
3. Gehe zu "Certificates, Identifiers & Profiles"
4. Wähle "Identifiers" → "App IDs"
5. Erstelle eine neue App ID oder bearbeite deine bestehende:
   - Bundle ID: `com.jacqueline.wetwo`
   - Aktiviere "Sign In with Apple" unter Capabilities

### 2. Apple Sign-In Service ID erstellen

1. Gehe zu "Identifiers" → "Services IDs"
2. Klicke auf "+" um eine neue Service ID zu erstellen
3. Beschreibung: `WeTwo Apple Sign-In`
4. Identifier: `com.jacqueline.wetwo.signin`
5. Aktiviere "Sign In with Apple"
6. Konfiguriere die Domains:
   - Primary App ID: `com.jacqueline.wetwo`
   - Website URLs: `https://yrzpfwatuxpnjsirjsma.supabase.co`

### 3. Supabase OAuth Provider konfigurieren

1. Gehe zu deinem Supabase Dashboard
2. Navigation: "Authentication" → "Providers"
3. Finde "Apple" und aktiviere es
4. Konfiguriere die folgenden Felder:

```
Provider: Apple
Enabled: ✅
Client ID: com.jacqueline.wetwo.signin
Secret: [Dein Apple Secret Key]
Redirect URL: https://yrzpfwatuxpnjsirjsma.supabase.co/auth/v1/callback
```

### 4. Apple Secret Key erstellen

1. Gehe zu "Keys" in deinem Apple Developer Account
2. Klicke auf "+" um einen neuen Key zu erstellen
3. Name: `WeTwo Supabase Key`
4. Aktiviere "Sign In with Apple"
5. Lade den Key herunter (`.p8` Datei)
6. Verwende den Key ID und die Datei um ein JWT Token zu generieren

### 5. JWT Token für Supabase generieren

Verwende ein Tool wie [jwt.io](https://jwt.io) oder ein Online JWT Generator:

**Header:**
```json
{
  "alg": "ES256",
  "kid": "YOUR_KEY_ID"
}
```

**Payload:**
```json
{
  "iss": "YOUR_TEAM_ID",
  "iat": 1640995200,
  "exp": 1641081600,
  "aud": "https://appleid.apple.com",
  "sub": "com.jacqueline.wetwo.signin"
}
```

### 6. Xcode Projekt konfigurieren

1. Öffne dein Xcode Projekt
2. Wähle dein Target "WeTwo"
3. Gehe zu "Signing & Capabilities"
4. Klicke auf "+ Capability"
5. Füge "Sign In with Apple" hinzu
6. Stelle sicher, dass die Entitlements Datei korrekt verknüpft ist

### 7. Bundle ID überprüfen

Stelle sicher, dass deine Bundle ID in Xcode mit der in Apple Developer übereinstimmt:
- Xcode: `com.jacqueline.wetwo`
- Apple Developer: `com.jacqueline.wetwo`

### 8. Testen

1. Baue und starte die App
2. Versuche dich mit Apple Sign-In anzumelden
3. Überprüfe die Supabase Logs auf Fehler
4. Überprüfe die Xcode Console für Debug-Ausgaben

## 🔧 Troubleshooting

### Häufige Fehler:

1. **"Invalid client"**
   - Überprüfe die Client ID in Supabase
   - Stelle sicher, dass die Service ID korrekt ist

2. **"Invalid redirect URI"**
   - Überprüfe die Redirect URL in Supabase
   - Stelle sicher, dass sie mit deiner Supabase URL übereinstimmt

3. **"Invalid nonce"**
   - Überprüfe die Nonce-Generierung im Code
   - Stelle sicher, dass die gleiche Nonce für Request und Response verwendet wird

4. **"Bundle ID mismatch"**
   - Überprüfe die Bundle ID in Xcode und Apple Developer
   - Stelle sicher, dass sie exakt übereinstimmen

### Debug-Ausgaben:

Die App gibt Debug-Ausgaben in der Xcode Console aus:
- `🍎 Starting Apple Sign-In with Supabase`
- `✅ Apple Sign-In successful`
- `❌ Apple Sign-In failed: [error]`

## 📱 App-spezifische Konfiguration

### Entitlements Datei:
Die `WeTwo.entitlements` Datei ist bereits erstellt und enthält:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### Code-Integration:
- `SupabaseService.swift`: Enthält `signInWithApple` und `signUpWithApple` Methoden
- `SignupView.swift`: UI-Integration mit Apple Sign-In Button
- `SecurityService.swift`: Sichere Nonce-Generierung

## 🚀 Deployment

Nach der Konfiguration:
1. Teste lokal auf einem echten Gerät (nicht Simulator)
2. Überprüfe alle Debug-Ausgaben
3. Teste sowohl Sign-In als auch Sign-Up Flows
4. Überprüfe die Datenbank-Einträge in Supabase
