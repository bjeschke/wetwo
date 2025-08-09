import Foundation
import CryptoKit
import Security

/// SecurityService für GDPR/DSGVO-konforme Verschlüsselung
/// Implementiert AES-256-GCM Verschlüsselung für sensible Daten
class SecurityService: ObservableObject {
    static let shared = SecurityService()
    
    private let keychain = Keychain(service: "com.amavo.security")
    private let encryptionKeyIdentifier = "AmavoEncryptionKey"
    
    private init() {
        ensureEncryptionKeyExists()
    }
    
    // MARK: - Key Management
    
    /// Erstellt einen sicheren AES-256-Schlüssel
    private func generateEncryptionKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    /// Stellt sicher, dass ein Verschlüsselungsschlüssel existiert
    private func ensureEncryptionKeyExists() {
        if getEncryptionKey() == nil {
            let key = generateEncryptionKey()
            saveEncryptionKey(key)
        }
    }
    
    /// Speichert den Verschlüsselungsschlüssel sicher im Keychain
    private func saveEncryptionKey(_ key: SymmetricKey) {
        do {
            try keychain.set(key.withUnsafeBytes { Data($0) }, forKey: encryptionKeyIdentifier)
        } catch {
            print("❌ Fehler beim Speichern des Verschlüsselungsschlüssels: \(error)")
        }
    }
    
    /// Lädt den Verschlüsselungsschlüssel aus dem Keychain
    private func getEncryptionKey() -> SymmetricKey? {
        do {
            let keyData = try keychain.data(forKey: encryptionKeyIdentifier)
            return SymmetricKey(data: keyData)
        } catch {
            print("❌ Fehler beim Laden des Verschlüsselungsschlüssels: \(error)")
            return nil
        }
    }
    
    // MARK: - Encryption/Decryption
    
    /// Verschlüsselt Daten mit AES-256-GCM
    /// - Parameter data: Zu verschlüsselnde Daten
    /// - Returns: Verschlüsselte Daten mit Nonce und Tag
    func encrypt(_ data: Data) throws -> EncryptedData {
        guard let key = getEncryptionKey() else {
            throw SecurityError.encryptionKeyNotFound
        }
        
        let nonce = try AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        guard let encryptedData = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        
        return EncryptedData(
            data: encryptedData,
            nonce: sealedBox.nonce.withUnsafeBytes { Data($0) },
            tag: sealedBox.tag
        )
    }
    
    /// Entschlüsselt Daten mit AES-256-GCM
    /// - Parameter encryptedData: Verschlüsselte Daten
    /// - Returns: Entschlüsselte Daten
    func decrypt(_ encryptedData: EncryptedData) throws -> Data {
        guard let key = getEncryptionKey() else {
            throw SecurityError.encryptionKeyNotFound
        }
        
        let nonce = try AES.GCM.Nonce(data: encryptedData.nonce)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: encryptedData.data,
            tag: encryptedData.tag
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Secure Storage
    
    /// Speichert sensible Daten verschlüsselt
    /// - Parameters:
    ///   - data: Zu speichernde Daten
    ///   - key: Schlüssel für UserDefaults
    func secureStore(_ data: Data, forKey key: String) throws {
        let encryptedData = try encrypt(data)
        let combinedData = try JSONEncoder().encode(encryptedData)
        UserDefaults.standard.set(combinedData, forKey: key)
    }
    
    /// Lädt sensible Daten entschlüsselt
    /// - Parameter key: Schlüssel für UserDefaults
    /// - Returns: Entschlüsselte Daten
    func secureLoad(forKey key: String) throws -> Data {
        guard let combinedData = UserDefaults.standard.data(forKey: key) else {
            throw SecurityError.dataNotFound
        }
        
        let encryptedData = try JSONDecoder().decode(EncryptedData.self, from: combinedData)
        return try decrypt(encryptedData)
    }
    
    /// Speichert sensible Strings verschlüsselt
    /// - Parameters:
    ///   - string: Zu speichernder String
    ///   - key: Schlüssel für UserDefaults
    func secureStore(_ string: String, forKey key: String) throws {
        let data = string.data(using: .utf8) ?? Data()
        try secureStore(data, forKey: key)
    }
    
    /// Lädt sensible Strings entschlüsselt
    /// - Parameter key: Schlüssel für UserDefaults
    /// - Returns: Entschlüsselter String
    func secureLoadString(forKey key: String) throws -> String {
        let data = try secureLoad(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecurityError.decodingFailed
        }
        return string
    }
    
    /// Löscht sensible Daten sicher
    /// - Parameter key: Schlüssel für UserDefaults
    func secureDelete(forKey key: String) throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - GDPR Compliance
    
    /// Löscht alle verschlüsselten Daten (GDPR Art. 17 - Recht auf Löschung)
    func deleteAllEncryptedData() {
        let userDefaults = UserDefaults.standard
        let domain = Bundle.main.bundleIdentifier ?? "com.amavo"
        userDefaults.removePersistentDomain(forName: domain)
        
        // Lösche auch den Verschlüsselungsschlüssel
        do {
            try keychain.deleteItem(forKey: encryptionKeyIdentifier)
        } catch {
            print("⚠️ Fehler beim Löschen des Verschlüsselungsschlüssels: \(error)")
        }
    }
    
    /// Exportiert alle verschlüsselten Daten (GDPR Art. 20 - Recht auf Datenübertragbarkeit)
    func exportAllEncryptedData() -> [String: Data] {
        var exportedData: [String: Data] = [:]
        let userDefaults = UserDefaults.standard
        
        // Sammle alle verschlüsselten Daten
        for key in userDefaults.dictionaryRepresentation().keys {
            if let data = userDefaults.data(forKey: key) {
                // Versuche zu entschlüsseln
                do {
                    let decryptedData = try secureLoad(forKey: key)
                    exportedData[key] = decryptedData
                } catch {
                    // Wenn Entschlüsselung fehlschlägt, ist es wahrscheinlich nicht verschlüsselt
                    exportedData[key] = data
                }
            }
        }
        
        return exportedData
    }
    
    // MARK: - Security Validation
    
    /// Validiert die Sicherheit der gespeicherten Daten
    func validateSecurity() -> SecurityValidationResult {
        var issues: [SecurityIssue] = []
        
        // Prüfe ob Verschlüsselungsschlüssel existiert
        if getEncryptionKey() == nil {
            issues.append(.encryptionKeyMissing)
        }
        
        // Prüfe auf unverschlüsselte sensible Daten
        let userDefaults = UserDefaults.standard
        let sensitiveKeys = ["userPassword", "userEmail", "currentUserId", "appleUserID"]
        
        for key in sensitiveKeys {
            if userDefaults.object(forKey: key) != nil {
                // Prüfe ob es verschlüsselt ist
                do {
                    _ = try secureLoad(forKey: key)
                } catch {
                    issues.append(.unencryptedSensitiveData(key: key))
                }
            }
        }
        
        return SecurityValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
}

// MARK: - Supporting Types

/// Repräsentiert verschlüsselte Daten mit Nonce und Tag
struct EncryptedData: Codable {
    let data: Data
    let nonce: Data
    let tag: Data
}

/// Sicherheitsfehler
enum SecurityError: Error, LocalizedError {
    case encryptionKeyNotFound
    case encryptionFailed
    case decryptionFailed
    case dataNotFound
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .encryptionKeyNotFound:
            return "Verschlüsselungsschlüssel nicht gefunden"
        case .encryptionFailed:
            return "Verschlüsselung fehlgeschlagen"
        case .decryptionFailed:
            return "Entschlüsselung fehlgeschlagen"
        case .dataNotFound:
            return "Daten nicht gefunden"
        case .decodingFailed:
            return "Dekodierung fehlgeschlagen"
        }
    }
}

/// Sicherheitsprobleme
enum SecurityIssue {
    case encryptionKeyMissing
    case unencryptedSensitiveData(key: String)
    
    var description: String {
        switch self {
        case .encryptionKeyMissing:
            return "Verschlüsselungsschlüssel fehlt"
        case .unencryptedSensitiveData(let key):
            return "Unverschlüsselte sensible Daten gefunden: \(key)"
        }
    }
}

/// Ergebnis der Sicherheitsvalidierung
struct SecurityValidationResult {
    let isValid: Bool
    let issues: [SecurityIssue]
}

// MARK: - Keychain Wrapper

/// Einfacher Keychain-Wrapper für sichere Schlüsselspeicherung
struct Keychain {
    private let service: String
    private let accessGroup: String?
    
    init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    func set(_ value: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item existiert bereits, aktualisiere es
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: value
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.other(status: updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.other(status: status)
        }
    }
    
    func data(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.other(status: status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.decodeFailed
        }
        
        return data
    }
    
    func deleteItem(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.other(status: status)
        }
    }
}

/// Keychain-Fehler
enum KeychainError: Error {
    case other(status: OSStatus)
    case decodeFailed
    
    var localizedDescription: String {
        switch self {
        case .other(let status):
            return "Keychain-Fehler: \(status)"
        case .decodeFailed:
            return "Dekodierung fehlgeschlagen"
        }
    }
} 