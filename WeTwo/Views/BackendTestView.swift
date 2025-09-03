//
//  BackendTestView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI
import FirebaseAuth

struct BackendTestView: View {
    @State private var testResults: [String] = []
    @State private var isTesting = false
    @State private var showResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Text("🔧 Backend Connection Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Test the connection to your backend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Configuration Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configuration:")
                        .font(.headline)
                    
                    Text("🌐 URL: \(BackendConfig.baseURL)")
                        .font(.caption)
                        .padding(.horizontal)
                    
                    Text("🔧 Environment: \(BackendConfig.currentEnvironment)")
                        .font(.caption)
                        .padding(.horizontal)
                    
                    Text("🔑 Service Type: \(ServiceFactory.shared.getCurrentServiceType())")
                        .font(.caption)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Test Button
                Button(action: {
                    runConnectionTest()
                }) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "network")
                        }
                        Text(isTesting ? "Testing..." : "Test Connection")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTesting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isTesting)
                .padding(.horizontal)
                
                // Test Memory Creation Button
                Button(action: {
                    testMemoryCreation()
                }) {
                    HStack {
                        Image(systemName: "memories")
                        Text("Test Memory Creation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isTesting)
                .padding(.horizontal)
                
                // Results
                if showResults {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Test Results:")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 5) {
                                ForEach(testResults, id: \.self) { result in
                                    Text(result)
                                        .font(.caption)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Backend Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func runConnectionTest() {
        isTesting = true
        testResults.removeAll()
        showResults = true
        
        Task {
            await performConnectionTest()
            
            await MainActor.run {
                isTesting = false
            }
        }
    }
    
    private func performConnectionTest() async {
        addResult("🧪 Starting backend connection test...")
        addResult("🌐 Backend URL: \(BackendConfig.baseURL)")
        
        // Test basic connection
        do {
            let isHealthy = try await ServiceFactory.shared.getCurrentService().checkConnectionHealth()
            if isHealthy {
                addResult("✅ Basic connection: SUCCESS")
            } else {
                addResult("❌ Basic connection: FAILED")
            }
        } catch {
            addResult("❌ Basic connection error: \(error.localizedDescription)")
        }
        
        // Test specific endpoints if using BackendService
        if let backendService = ServiceFactory.shared.getCurrentService() as? BackendService {
            await testSpecificEndpoints(backendService)
        }
        
        // Test service validation
        do {
            let isValid = try await ServiceFactory.shared.getCurrentService().isConnected()
            if isValid {
                addResult("✅ Service validation: SUCCESS")
            } else {
                addResult("❌ Service validation: FAILED")
            }
        } catch {
            addResult("❌ Service validation error: \(error.localizedDescription)")
        }
        
        addResult("🏁 Connection test completed")
    }
    
    private func testSpecificEndpoints(_ backendService: BackendService) async {
        // Test Firebase token
        addResult("🔑 Testing Firebase token...")
        
        if let currentUser = Auth.auth().currentUser {
            addResult("✅ Firebase user authenticated: \(currentUser.email ?? "Unknown")")
            
            do {
                let token = try await currentUser.getIDToken()
                addResult("✅ Firebase token obtained successfully")
                addResult("🔑 Token prefix: \(token.prefix(20))...")
            } catch {
                addResult("❌ Failed to get Firebase token: \(error.localizedDescription)")
            }
        } else {
            addResult("⚠️ No Firebase user authenticated")
        }
        
        // Test auth endpoint with Firebase token
        addResult("🔐 Testing auth endpoint with Firebase token...")
        
        guard let authURL = BackendConfig.authURL() else {
            addResult("❌ Auth URL not available")
            return
        }
        
        do {
            var request = URLRequest(url: authURL)
            
            // Try to add Firebase token
            if let currentUser = Auth.auth().currentUser {
                let token = try await currentUser.getIDToken()
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                addResult("✅ Added Firebase token to request headers")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                addResult("🔐 Auth endpoint status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    addResult("🔐 Auth response: \(responseString.prefix(100))...")
                }
            }
        } catch {
            addResult("❌ Auth endpoint error: \(error.localizedDescription)")
        }
        
        // Test profiles endpoint with Firebase token
        addResult("👤 Testing profiles endpoint with Firebase token...")
        
        guard let profilesURL = BackendConfig.profilesURL() else {
            addResult("❌ Profiles URL not available")
            return
        }
        
        do {
            var request = URLRequest(url: profilesURL)
            
            // Try to add Firebase token
            if let currentUser = Auth.auth().currentUser {
                let token = try await currentUser.getIDToken()
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                addResult("✅ Added Firebase token to profiles request")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                addResult("👤 Profiles endpoint status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    addResult("👤 Profiles response: \(responseString.prefix(100))...")
                }
            }
        } catch {
            addResult("❌ Profiles endpoint error: \(error.localizedDescription)")
        }
        
        // Test getting user profile using BackendService
        addResult("🧑 Testing getUserProfile() with Firebase token...")
        
        do {
            if let profile = try await backendService.getUserProfile() {
                addResult("✅ Got user profile: \(profile.name)")
                addResult("   Zodiac: \(profile.zodiacSign)")
                addResult("   Birth Date: \(profile.birthDate)")
                addResult("   Photo URL: \(profile.photoUrl ?? "None")")
            } else {
                addResult("⚠️ No profile returned")
            }
        } catch {
            addResult("❌ getUserProfile() error: \(error.localizedDescription)")
        }
    }
    
    private func addResult(_ result: String) {
        DispatchQueue.main.async {
            testResults.append(result)
        }
    }
    
    private func testMemoryCreation() {
        isTesting = true
        testResults.removeAll()
        showResults = true
        
        Task {
            await performMemoryTest()
            
            await MainActor.run {
                isTesting = false
            }
        }
    }
    
    private func performMemoryTest() async {
        addResult("🧪 Starting Memory Creation Test...")
        
        // Check Firebase auth
        guard let currentUser = Auth.auth().currentUser else {
            addResult("❌ Not authenticated with Firebase")
            return
        }
        
        addResult("✅ Firebase user: \(currentUser.email ?? "Unknown")")
        addResult("   UID: \(currentUser.uid)")
        
        // Get Firebase token
        do {
            let token = try await currentUser.getIDToken()
            addResult("✅ Firebase token obtained")
            addResult("   Token prefix: \(token.prefix(20))...")
            
            // Create test memory
            let testMemory = Memory(
                id: nil,
                user_id: 999, // Test ID - backend should override with actual user ID
                partner_id: nil, // No partner for test
                date: "2025-09-03",
                title: "Test Memory \(Int(Date().timeIntervalSince1970))",
                description: "This is a test memory created from BackendTestView",
                photo_data: nil,
                location: "Test Location",
                mood_level: "happy",
                tags: "test,debug",
                is_shared: "false",
                created_at: Date(),
                updated_at: Date()
            )
            
            addResult("📝 Creating test memory: \(testMemory.title)")
            
            // Try to save via BackendService
            let backendService = BackendService.shared
            
            addResult("📤 Sending memory to backend...")
            addResult("   URL: \(BackendConfig.memoriesURL()?.absoluteString ?? "Unknown")")
            
            let savedMemory = try await backendService.createMemory(testMemory)
            
            addResult("✅ MEMORY SAVED SUCCESSFULLY!")
            addResult("   ID: \(savedMemory.id ?? 0)")
            addResult("   Title: \(savedMemory.title)")
            addResult("   Date: \(savedMemory.date)")
            addResult("   User ID: \(savedMemory.user_id)")
            addResult("   Is Shared: \(savedMemory.is_shared ?? "false")")
            
        } catch {
            addResult("❌ Memory creation failed: \(error)")
            
            // Try to get more details
            if let backendError = error as? BackendError {
                addResult("   Backend Error Type: \(backendError)")
                switch backendError {
                case .invalidResponse:
                    addResult("   → Invalid response from server")
                case .networkError:
                    addResult("   → Network connection issue")
                case .databaseError:
                    addResult("   → Database operation failed")
                case .decodingError:
                    addResult("   → Failed to decode response")
                default:
                    addResult("   → \(backendError.localizedDescription)")
                }
            }
            
            // Check console logs for request/response details
            addResult("💡 Check Xcode console for detailed logs:")
            addResult("   - Request body")
            addResult("   - Response status")
            addResult("   - Response body")
        }
        
        addResult("🏁 Memory test completed")
    }
}

#Preview {
    BackendTestView()
}
