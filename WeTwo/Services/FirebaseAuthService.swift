import Foundation
import FirebaseAuth
import FirebaseCore
import Combine

class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> FirebaseAuth.User {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        return authResult.user
    }
    
    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return authResult.user
    }
    
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> FirebaseAuth.User {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: fullName
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        
        if let fullName = fullName {
            let displayName = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            if !displayName.isEmpty {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
        }
        
        return authResult.user
    }
    
    func sendPasswordResetEmail(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        try await user.sendEmailVerification()
    }
    
    func updateProfile(displayName: String? = nil, photoURL: URL? = nil) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        
        let changeRequest = user.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        try await changeRequest.commitChanges()
    }
    
    func updateEmail(to newEmail: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
    }
    
    func updatePassword(to newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        try await user.updatePassword(to: newPassword)
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        try await user.delete()
    }
    
    func signInWithCustomToken(_ token: String) async throws -> FirebaseAuth.User {
        let authResult = try await Auth.auth().signIn(withCustomToken: token)
        return authResult.user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func getIDToken(forcingRefresh: Bool = false) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        return try await user.getIDToken(forcingRefresh: forcingRefresh)
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "No authenticated user found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error occurred"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}