import Foundation

struct FirebaseConfig {
    static let projectId = "your-firebase-project-id"
    static let apiKey = "your-firebase-api-key"
    static let googleAppId = "your-google-app-id"
    static let gcmSenderId = "your-gcm-sender-id"
    static let storageBucket = "your-storage-bucket.appspot.com"
    static let authDomain = "your-project.firebaseapp.com"
    static let databaseURL = "https://your-project.firebaseio.com"
    static let messagingSenderId = "your-messaging-sender-id"
    
    static var plistPath: String? {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
    }
}