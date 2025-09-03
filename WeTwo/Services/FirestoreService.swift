import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private init() {
        configureFirestore()
    }
    
    private func configureFirestore() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // MARK: - User Profile
    
    func createUserProfile(_ profile: User) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        var profileData = profile.toDictionary()
        profileData["userId"] = userId
        profileData["createdAt"] = FieldValue.serverTimestamp()
        profileData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await db.collection("users").document(userId).setData(profileData)
    }
    
    func getUserProfile(userId: String? = nil) async throws -> User? {
        let uid = userId ?? Auth.auth().currentUser?.uid
        guard let uid = uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        let document = try await db.collection("users").document(uid).getDocument()
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        return User.fromDictionary(data)
    }
    
    func updateUserProfile(_ updates: [String: Any]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        var updatesWithTimestamp = updates
        updatesWithTimestamp["updatedAt"] = FieldValue.serverTimestamp()
        
        try await db.collection("users").document(userId).updateData(updatesWithTimestamp)
    }
    
    // MARK: - Partnership
    
    func createPartnership(withCode code: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        let partnershipData: [String: Any] = [
            "users": [userId],
            "connectionCode": code,
            "createdAt": FieldValue.serverTimestamp(),
            "status": "pending"
        ]
        
        try await db.collection("partnerships").document(code).setData(partnershipData)
    }
    
    func joinPartnership(code: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        let partnershipRef = db.collection("partnerships").document(code)
        
        try await db.runTransaction { transaction, errorPointer in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(partnershipRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard document.exists,
                  var data = document.data(),
                  var users = data["users"] as? [String] else {
                errorPointer?.pointee = NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Partnership not found"])
                return nil
            }
            
            if !users.contains(userId) {
                users.append(userId)
                transaction.updateData([
                    "users": users,
                    "status": "connected",
                    "connectedAt": FieldValue.serverTimestamp()
                ], forDocument: partnershipRef)
            }
            
            return nil
        }
    }
    
    // MARK: - Love Messages
    
    func sendLoveMessage(_ message: LoveMessage) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        var messageData = message.toDictionary()
        messageData["senderId"] = userId
        messageData["createdAt"] = FieldValue.serverTimestamp()
        
        try await db.collection("loveMessages").addDocument(data: messageData)
    }
    
    func getLoveMessages(limit: Int = 50) async throws -> [LoveMessage] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        let snapshot = try await db.collection("loveMessages")
            .whereField("recipientId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            LoveMessage.fromDictionary(document.data())
        }
    }
    
    // MARK: - Mood Entries
    
    func saveMoodEntry(_ mood: MoodEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        var moodData = mood.toDictionary()
        moodData["userId"] = userId
        moodData["createdAt"] = FieldValue.serverTimestamp()
        
        // Use the mood's id directly (it's already a String)
        let moodId = mood.id
        try await db.collection("moods").document(moodId).setData(moodData, merge: true)
    }
    
    func getMoodEntries(startDate: Date? = nil, endDate: Date? = nil) async throws -> [MoodEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        var query = db.collection("moods")
            .whereField("userId", isEqualTo: userId)
        
        if let startDate = startDate {
            query = query.whereField("date", isGreaterThanOrEqualTo: startDate)
        }
        
        if let endDate = endDate {
            query = query.whereField("date", isLessThanOrEqualTo: endDate)
        }
        
        let snapshot = try await query
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            MoodEntry.fromDictionary(document.data())
        }
    }
    
    // MARK: - Real-time Listeners
    
    func listenToPartnershipUpdates(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(FirestoreError.userNotAuthenticated))
            return
        }
        
        let listener = db.collection("partnerships")
            .whereField("users", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.success([:]))
                    return
                }
                
                if let data = documents.first?.data() {
                    completion(.success(data))
                }
            }
        
        listeners.append(listener)
    }
    
    func listenToLoveMessages(completion: @escaping (Result<[LoveMessage], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(FirestoreError.userNotAuthenticated))
            return
        }
        
        let listener = db.collection("loveMessages")
            .whereField("recipientId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let messages = snapshot?.documents.compactMap { document in
                    LoveMessage.fromDictionary(document.data())
                } ?? []
                
                completion(.success(messages))
            }
        
        listeners.append(listener)
    }
    
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    deinit {
        removeAllListeners()
    }
}

enum FirestoreError: LocalizedError {
    case userNotAuthenticated
    case documentNotFound
    case invalidData
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Model Extensions for Firestore

extension User {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "name": name,
            "profilePictureUrl": profilePictureUrl ?? "",
            "partnerId": partnerId ?? "",
            "connectionCode": connectionCode ?? "",
            "isConnected": isConnected,
            "relationshipStartDate": relationshipStartDate ?? Date(),
            "relationshipStatus": relationshipStatus.rawValue,
            "notificationSettings": [
                "dailyReminders": notificationSettings.dailyReminders,
                "loveMessages": notificationSettings.loveMessages,
                "moodUpdates": notificationSettings.moodUpdates
            ],
            "isPremium": isPremium
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> User? {
        guard let idString = data["id"] as? String,
              let email = data["email"] as? String,
              let name = data["name"] as? String else {
            return nil
        }
        
        var user = User(id: idString, email: email, name: name)
        user.profilePictureUrl = data["profilePictureUrl"] as? String
        
        if let partnerIdString = data["partnerId"] as? String {
            user.partnerId = partnerIdString
        }
        
        user.connectionCode = data["connectionCode"] as? String
        user.isConnected = data["isConnected"] as? Bool ?? false
        
        if let timestamp = data["relationshipStartDate"] as? Timestamp {
            user.relationshipStartDate = timestamp.dateValue()
        }
        
        if let statusString = data["relationshipStatus"] as? String,
           let status = RelationshipStatus(rawValue: statusString) {
            user.relationshipStatus = status
        }
        
        if let notificationData = data["notificationSettings"] as? [String: Any] {
            user.notificationSettings.dailyReminders = notificationData["dailyReminders"] as? Bool ?? true
            user.notificationSettings.loveMessages = notificationData["loveMessages"] as? Bool ?? true
            user.notificationSettings.moodUpdates = notificationData["moodUpdates"] as? Bool ?? true
        }
        
        user.isPremium = data["isPremium"] as? Bool ?? false
        
        return user
    }
}

extension LoveMessage {
    func toDictionary() -> [String: Any] {
        return [
            "id": String(id),
            "message": message,
            "senderId": String(senderId),
            "receiverId": String(receiverId),
            "timestamp": timestamp,
            "isRead": isRead
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> LoveMessage? {
        guard let idString = data["id"] as? String,
              let id = Int(idString),
              let message = data["message"] as? String,
              let senderIdString = data["senderId"] as? String,
              let senderId = Int(senderIdString),
              let receiverIdString = data["receiverId"] as? String,
              let receiverId = Int(receiverIdString) else {
            return nil
        }
        
        let timestamp: Date
        if let firestoreTimestamp = data["timestamp"] as? Timestamp {
            timestamp = firestoreTimestamp.dateValue()
        } else if let dateTimestamp = data["timestamp"] as? Date {
            timestamp = dateTimestamp
        } else {
            timestamp = Date()
        }
        
        let isRead = data["isRead"] as? Bool ?? false
        
        let loveMessage = LoveMessage(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            message: message,
            timestamp: timestamp,
            isRead: isRead
        )
        
        return loveMessage
    }
}

extension MoodEntry {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "moodLevel": moodLevel.rawValue,
            "eventLabel": eventLabel ?? "",
            "date": date,
            "location": location ?? "",
            "photoData": photoData?.base64EncodedString() ?? "",
            "insight": insight ?? "",
            "loveMessage": loveMessage ?? ""
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> MoodEntry? {
        guard let userId = data["userId"] as? String,
              let moodLevelRaw = data["moodLevel"] as? Int,
              let moodLevel = MoodLevel(rawValue: moodLevelRaw) else {
            return nil
        }
        
        var entry = MoodEntry(
            userId: userId,
            moodLevel: moodLevel,
            eventLabel: data["eventLabel"] as? String,
            location: data["location"] as? String,
            photoData: nil
        )
        
        if let photoString = data["photoData"] as? String,
           !photoString.isEmpty,
           let photoData = Data(base64Encoded: photoString) {
            entry = MoodEntry(
                userId: userId,
                moodLevel: moodLevel,
                eventLabel: data["eventLabel"] as? String,
                location: data["location"] as? String,
                photoData: photoData
            )
        }
        
        return entry
    }
}