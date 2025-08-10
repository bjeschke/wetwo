# Deep Link Setup für Email-Bestätigung

## 🎯 Übersicht

Diese Anleitung zeigt, wie du Deep Links für Email-Bestätigungen in der WeTwo App einrichtest. Wenn ein User auf den Bestätigungslink in der Email klickt, öffnet sich automatisch die WeTwo App.

## 📱 Xcode URL Scheme Konfiguration

### 1. URL Scheme hinzufügen

1. Öffne `WeTwo.xcodeproj` in Xcode
2. Wähle das `WeTwo` Target aus
3. Gehe zu **Info** Tab
4. Erweitere **URL Types** (falls nicht vorhanden, klicke auf **+**)
5. Klicke auf **+** um einen neuen URL Type hinzuzufügen
6. Fülle die Felder aus:
   - **URL Schemes**: `wetwo`
   - **Identifier**: `com.jacqueline.wetwo`
   - **Icon**: (optional)
   - **Role**: `Editor`

### 2. Info.plist Konfiguration

Alternativ kannst du die URL Scheme direkt in der Info.plist hinzufügen:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.jacqueline.wetwo</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wetwo</string>
        </array>
        <key>CFBundleURLIconFile</key>
        <string></string>
    </dict>
</array>
```

## 🔧 Supabase Konfiguration

### 1. Supabase Dashboard

1. Gehe zu deinem Supabase Projekt Dashboard
2. Navigiere zu **Authentication** → **Settings**
3. Scrolle zu **Redirect URLs**
4. Füge folgende URLs hinzu:
   ```
   wetwo://email-confirmation
   wetwo://auth/callback
   ```
5. Klicke auf **Save**

### 2. SQL Konfiguration (Optional)

Führe das SQL-Script `configure_email_confirmation_redirect.sql` in deinem Supabase SQL Editor aus:

```sql
-- Setze die Email-Bestätigung Redirect URL
UPDATE auth.config 
SET value = 'wetwo://email-confirmation'
WHERE key = 'email_confirmation_redirect_url';
```

### 3. Email Template Anpassung (Optional)

Für bessere UX kannst du das Email-Template anpassen:

1. Gehe zu **Authentication** → **Templates**
2. Wähle **Confirm signup** Template
3. Passe den Link-Text an:
   ```html
   <a href="{{ .ConfirmationURL }}" style="...">
       WeTwo App öffnen
   </a>
   ```

## 🧪 Testing

### 1. Simulator Testing

1. Starte die App im Simulator
2. Registriere einen neuen User
3. Überprüfe die Email (in Supabase Dashboard → Users)
4. Klicke auf den Bestätigungslink
5. Die App sollte sich öffnen und den User automatisch anmelden

### 2. Device Testing

1. Installiere die App auf einem echten Gerät
2. Registriere einen neuen User
3. Öffne die Email-App auf dem Gerät
4. Klicke auf den Bestätigungslink
5. Die WeTwo App sollte sich öffnen

### 3. Debug Testing

Füge diese URL in Safari ein, um Deep Links zu testen:
```
wetwo://email-confirmation?access_token=test&type=signup&token_hash=test
```

## 🔍 Troubleshooting

### Problem: App öffnet sich nicht
**Lösung:**
- Überprüfe die URL Scheme Konfiguration in Xcode
- Stelle sicher, dass die App installiert ist
- Teste mit einem einfachen Link: `wetwo://test`

### Problem: Email-Bestätigung funktioniert nicht
**Lösung:**
- Überprüfe die Supabase Redirect URLs
- Stelle sicher, dass die DeepLinkHandler korrekt implementiert ist
- Überprüfe die Console-Logs für Fehlermeldungen

### Problem: User wird nicht automatisch angemeldet
**Lösung:**
- Überprüfe, ob die pending confirmation data korrekt gespeichert wird
- Stelle sicher, dass die SupabaseService.confirmEmailAndSignIn Methode funktioniert
- Überprüfe die Secure Storage Implementierung

## 📋 Checkliste

- [ ] URL Scheme in Xcode konfiguriert
- [ ] DeepLinkHandler implementiert
- [ ] Supabase Redirect URLs gesetzt
- [ ] Email Template angepasst (optional)
- [ ] Testing im Simulator erfolgreich
- [ ] Testing auf echtem Gerät erfolgreich
- [ ] Error Handling implementiert

## 🚀 Production Deployment

### 1. App Store Connect

Stelle sicher, dass die URL Scheme in App Store Connect korrekt konfiguriert ist.

### 2. Universal Links (Optional)

Für bessere UX kannst du Universal Links einrichten:

1. Erstelle eine `apple-app-site-association` Datei auf deinem Server
2. Konfiguriere Associated Domains in Xcode
3. Aktualisiere die Supabase Redirect URLs

### 3. Monitoring

Überwache die Deep Link Performance:
- Erfolgsrate der Email-Bestätigungen
- App-Öffnungsrate nach Email-Klick
- Fehler bei der automatischen Anmeldung

## 📚 Weitere Ressourcen

- [Apple URL Scheme Documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [SwiftUI Deep Links](https://developer.apple.com/documentation/swiftui/environmentvalues/onopenurl)

## 🎉 Fertig!

Deine WeTwo App unterstützt jetzt Deep Links für Email-Bestätigungen! 

**Nächste Schritte:**
1. Teste die Funktionalität gründlich
2. Überwache die Performance in Production
3. Erwäge Universal Links für bessere UX
4. Implementiere Analytics für Deep Link Nutzung
