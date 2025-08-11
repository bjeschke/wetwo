//
//  BackendTestView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

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
                    
                    Text("Test the connection to your Railway backend")
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
        addResult("🔐 Testing auth endpoint...")
        
        // Test auth endpoint
        guard let authURL = BackendConfig.authURL() else {
            addResult("❌ Auth URL not available")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: authURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                addResult("🔐 Auth endpoint status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    addResult("🔐 Auth response: \(responseString.prefix(100))...")
                }
            }
        } catch {
            addResult("❌ Auth endpoint error: \(error.localizedDescription)")
        }
        
        // Test profiles endpoint
        addResult("👤 Testing profiles endpoint...")
        
        guard let profilesURL = BackendConfig.profilesURL() else {
            addResult("❌ Profiles URL not available")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: profilesURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                addResult("👤 Profiles endpoint status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    addResult("👤 Profiles response: \(responseString.prefix(100))...")
                }
            }
        } catch {
            addResult("❌ Profiles endpoint error: \(error.localizedDescription)")
        }
    }
    
    private func addResult(_ result: String) {
        DispatchQueue.main.async {
            testResults.append(result)
        }
    }
}

#Preview {
    BackendTestView()
}
