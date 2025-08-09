# Supabase Setup Guide für WeTwo App

## 🚀 Schritt-für-Schritt Anleitung

### 1. Supabase Projekt erstellen

1. Gehe zu [supabase.com](https://supabase.com)
2. Klicke auf "Start your project"
3. Wähle "New Project"
4. Gib deinem Projekt einen Namen: `wetwo-app`
5. Wähle ein sicheres Datenbank-Passwort
6. Wähle eine Region (am besten nahe an deinem Standort)
7. Klicke auf "Create new project"

### 2. Datenbank-Schema einrichten

1. Gehe zu deinem Supabase Dashboard
2. Klicke auf "SQL Editor" im linken Menü
3. Klicke auf "New query"
4. Kopiere den gesamten Inhalt aus `supabase_schema.sql`
5. Führe das SQL-Script aus (Klick auf "Run")

### 3. Storage Bucket erstellen

1. Gehe zu "Storage" im linken Menü
2. Klicke auf "New bucket"
3. Name: `memory-photos`
4. Public bucket: ✅ **Aktiviert**
5. Klicke auf "Create bucket"

### 4. API Keys abrufen

1. Gehe zu "Settings" → "API" im linken Menü
2. Kopiere die folgenden Werte:
   - **Project URL** (z.B. `https://your-project.supabase.co`)
   - **anon public** Key (beginnt mit `eyJ...`)

### 5. App konfigurieren

1. Öffne `WeTwo/Services/SupabaseService.swift`
2. Ersetze die Platzhalter:
   ```swift
   private let supabaseURL = "YOUR_SUPABASE_URL"        // ← Deine Project URL
   private let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY" // ← Dein anon Key
   ```

### 6. Supabase SDK hinzufügen

Füge das Supabase Swift SDK zu deinem Xcode-Projekt hinzu:

1. In Xcode: File → Add Package Dependencies
2. URL: `https://github.com/supabase-community/supabase-swift`
3. Version: Latest
4. Klicke auf "Add Package"

### 7. Authentication einrichten

1. Gehe zu "Authentication" → "Settings" im Supabase Dashboard
2. Aktiviere "Email auth"
3. Optional: Aktiviere "Confirm email" für zusätzliche Sicherheit

### 8. Row Level Security (RLS) testen

Das Schema enthält bereits alle notwendigen RLS-Policies. Teste sie:

1. Gehe zu "Authentication" → "Users"
2. Erstelle einen Test-User
3. Gehe zu "Table Editor" → "profiles"
4. Versuche Daten einzufügen/bearbeiten

## 📊 Datenbank-Schema Übersicht

### Tabellen:

| Tabelle | Beschreibung |
|---------|-------------|
| `profiles` | Benutzerprofile mit Namen, Sternzeichen, Geburtsdatum |
| `partnerships` | Partner-Verbindungen mit Verbindungscodes |
| `memories` | Geteilte und persönliche Erinnerungen |
| `mood_entries` | Tägliche Stimmungs-Einträge |
| `subscriptions` | Premium-Abonnements |
| `usage_tracking` | Freemium-Nutzungsverfolgung |

### Wichtige Features:

- ✅ **Row Level Security** - Jeder User sieht nur seine eigenen Daten
- ✅ **Partner-Sharing** - Geteilte Erinnerungen zwischen Partnern
- ✅ **Photo Storage** - Sichere Foto-Speicherung in Supabase Storage
- ✅ **Automatische Timestamps** - `created_at` und `updated_at`
- ✅ **Performance Indexes** - Optimierte Datenbankabfragen
- ✅ **Freemium Tracking** - Nutzungslimits für kostenlose Features

## 🔐 Sicherheit

### RLS Policies:
- User können nur ihre eigenen Daten sehen/bearbeiten
- Partner können geteilte Erinnerungen sehen/bearbeiten
- Fotos sind nur für berechtigte User zugänglich

### Authentication:
- Email/Password Authentication
- Sichere Session-Verwaltung
- Automatische Token-Erneuerung

## 📱 App-Integration

### MemoryManager:
- Automatische Synchronisation mit Supabase
- Offline-First mit lokaler Zwischenspeicherung
- Fehlerbehandlung und Retry-Logic

### Partner-Synchronisation:
- Echtzeit-Updates zwischen Partnern
- Sichere Verbindungscodes
- Automatische Foto-Synchronisation

## 🧪 Testing

### Test-Szenarien:
1. **User Registration**: Neuer User registriert sich
2. **Profile Creation**: User erstellt sein Profil
3. **Memory Creation**: User erstellt eine Erinnerung
4. **Photo Upload**: User lädt ein Foto hoch
5. **Partner Connection**: Zwei User verbinden sich
6. **Shared Memories**: Partner teilen Erinnerungen

### Debugging:
- Supabase Dashboard → Logs
- Xcode Console für App-Logs
- Network Inspector für API-Calls

## 🚀 Deployment

### Production Checklist:
- [ ] Supabase Project in Production-Region
- [ ] Custom Domain (optional)
- [ ] SSL-Zertifikat aktiviert
- [ ] Backup-Strategie konfiguriert
- [ ] Monitoring eingerichtet
- [ ] Rate Limiting aktiviert

### Environment Variables:
```swift
// Development
private let supabaseURL = "https://dev-project.supabase.co"
private let supabaseAnonKey = "dev-anon-key"

// Production
private let supabaseURL = "https://prod-project.supabase.co"
private let supabaseAnonKey = "prod-anon-key"
```

## 📈 Monitoring

### Supabase Dashboard:
- **Database**: Query Performance, Connection Count
- **Storage**: Upload/Download Statistics
- **Auth**: User Registration, Login Attempts
- **Logs**: Error Tracking, API Usage

### App Analytics:
- Memory Creation Rate
- Photo Upload Success Rate
- Partner Connection Success
- User Engagement Metrics

## 🔧 Troubleshooting

### Häufige Probleme:

**1. "Invalid API Key"**
- Überprüfe die API Keys in SupabaseService.swift
- Stelle sicher, dass der anon Key korrekt ist

**2. "RLS Policy Violation"**
- Überprüfe die RLS Policies in der Datenbank
- Stelle sicher, dass der User authentifiziert ist

**3. "Photo Upload Failed"**
- Überprüfe Storage Bucket Konfiguration
- Stelle sicher, dass Storage Policies korrekt sind

**4. "Partner Connection Failed"**
- Überprüfe partnerships Tabelle
- Stelle sicher, dass connection_code eindeutig ist

### Support:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Community](https://github.com/supabase/supabase/discussions)
- [Swift SDK Issues](https://github.com/supabase-community/supabase-swift/issues)

## 🎉 Fertig!

Deine WeTwo App ist jetzt vollständig mit Supabase integriert! 

**Nächste Schritte:**
1. Teste die App mit echten Daten
2. Konfiguriere Push-Notifications (optional)
3. Setze Analytics ein (optional)
4. Plane das Production-Deployment

**Viel Erfolg mit deiner WeTwo App! 💕📸** 