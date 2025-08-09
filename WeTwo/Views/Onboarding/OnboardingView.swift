//
//  OnboardingView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var partnerManager: PartnerManager
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var birthDate = Date()
    @State private var showingPartnerConnection = false
    
    // Relationship fields
    @State private var relationshipStatus: RelationshipStatus = .inRelationship
    @State private var hasChildren = false
    @State private var childrenCount = 0
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [ColorTheme.primaryPurple, ColorTheme.secondaryPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: ColorTheme.primaryPurple))
                    .padding(.horizontal)
                
                Spacer()
                
                // Step content
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    profileStep
                case 2:
                    relationshipStep
                default:
                    EmptyView()
                }
                
                Spacer(minLength: 50)
                
                // Navigation buttons
                navigationButtons
            }
            .padding()
        }
        .sheet(isPresented: $showingPartnerConnection) {
            SimplePartnerConnectionView()
                .environmentObject(partnerManager)
        }
    }
    
    // MARK: - Step Views
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            // App icon and title
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ColorTheme.accentPink)
                
                Text(NSLocalizedString("onboarding_welcome_title", comment: "Welcome title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(NSLocalizedString("onboarding_welcome_subtitle", comment: "Welcome subtitle"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            // Features preview
            VStack(spacing: 15) {
                OnboardingFeatureRow(icon: "heart.fill", title: NSLocalizedString("onboarding_feature_mood", comment: "Mood feature"))
                OnboardingFeatureRow(icon: "calendar", title: NSLocalizedString("onboarding_feature_calendar", comment: "Calendar feature"))
                OnboardingFeatureRow(icon: "photo", title: NSLocalizedString("onboarding_feature_memories", comment: "Memories feature"))
                OnboardingFeatureRow(icon: "person.2.fill", title: NSLocalizedString("onboarding_feature_partner", comment: "Partner feature"))
            }
        }
    }
    

    
    private var profileStep: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("onboarding_profile_title", comment: "Profile title"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("onboarding_name_label", comment: "Name label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField(NSLocalizedString("onboarding_name_placeholder", comment: "Name placeholder"), text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Birth date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("onboarding_birthdate_label", comment: "Birthdate label"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DatePicker(
                        NSLocalizedString("onboarding_birthdate_placeholder", comment: "Birthdate placeholder"),
                        selection: $birthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(.white)
                    
                    // Show calculated zodiac sign
                    if !userName.isEmpty {
                        let zodiacSign = ZodiacSign.calculate(from: birthDate)
                        HStack {
                            Text(NSLocalizedString("onboarding_zodiac_label", comment: "Zodiac label"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(zodiacSign.emoji + " " + zodiacSign.rawValue)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var relationshipStep: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("onboarding_relationship_title", comment: "Relationship title"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 25) {
                // Relationship status
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("onboarding_relationship_status_label", comment: "Relationship status label"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(RelationshipStatus.allCases, id: \.self) { status in
                            Button(action: {
                                relationshipStatus = status
                            }) {
                                HStack {
                                    Text(status.emoji)
                                        .font(.title2)
                                                                                Text(status.localizedName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(relationshipStatus == status ? .white : ColorTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(relationshipStatus == status ? ColorTheme.accentPink : ColorTheme.cardBackgroundSecondary)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Children section
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("onboarding_children_label", comment: "Children label"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    VStack(spacing: 15) {
                        // Has children toggle
                        HStack {
                            Text(NSLocalizedString("onboarding_has_children", comment: "Has children"))
                                .font(.body)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Spacer()
                            
                            Toggle("", isOn: $hasChildren)
                                .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentPink))
                        }
                        
                        // Children count (if has children)
                        if hasChildren {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(NSLocalizedString("onboarding_children_count_label", comment: "Children count label"))
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondaryText)
                                
                                HStack {
                                    Button(action: {
                                        if childrenCount > 0 {
                                            childrenCount -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(ColorTheme.accentPink)
                                    }
                                    .disabled(childrenCount == 0)
                                    
                                    Text("\(childrenCount)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(ColorTheme.primaryText)
                                        .frame(minWidth: 50)
                                    
                                    Button(action: {
                                        if childrenCount < 10 {
                                            childrenCount += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(ColorTheme.accentPink)
                                    }
                                    .disabled(childrenCount == 10)
                                    
                                    Spacer()
                                    
                                    Text(childrenCount == 1 ? NSLocalizedString("child", comment: "child") : NSLocalizedString("children", comment: "children"))
                                        .font(.body)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ColorTheme.cardBackgroundSecondary)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(NSLocalizedString("onboarding_back", comment: "Back button")) {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .foregroundColor(ColorTheme.primaryText)
            }
            
            Spacer()
            
            if currentStep < totalSteps - 1 {
                Button(NSLocalizedString("onboarding_next", comment: "Next button")) {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .foregroundColor(ColorTheme.primaryText)
            } else {
                Button(NSLocalizedString("onboarding_complete", comment: "Complete button")) {
                    completeOnboarding()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(ColorTheme.accentPink)
                .cornerRadius(25)
                .disabled(userName.isEmpty)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        let user = User(name: userName, birthDate: birthDate)
        appState.completeOnboarding(user: user)
        
        // Create profile and save relationship data
        Task {
            await createProfileAndSaveData()
        }
        
        // Show partner connection option
        showingPartnerConnection = true
    }
    
    private func createProfileAndSaveData() async {
        do {
            guard let userId = appState.currentUser?.id else { 
                print("❌ No current user ID found")
                return 
            }
            
            print("🔧 Updating profile for user: \(userId)")
            print("   Name: \(userName)")
            print("   Birth Date: \(birthDate)")
            
            // Update profile in database (created automatically by trigger)
            try await SupabaseService.shared.updateProfile(
                userId: userId.uuidString,
                name: userName,
                birthDate: birthDate
            )
            
            print("✅ Profile updated successfully!")
            
            // Save relationship data
            await saveRelationshipData()
            
        } catch {
            print("❌ Error updating profile: \(error)")
        }
    }
    
    private func saveRelationshipData() async {
        do {
            guard let userId = appState.currentUser?.id else { 
                print("❌ No current user ID found for relationship data")
                return 
            }
            
            print("🔧 Saving relationship data for user: \(userId)")
            print("   Status: \(relationshipStatus.rawValue)")
            print("   Has Children: \(hasChildren)")
            print("   Children Count: \(childrenCount)")
            
            // Save relationship data to database
            try await SupabaseService.shared.updateRelationshipData(
                userId: userId.uuidString,
                relationshipStatus: relationshipStatus.rawValue,
                hasChildren: hasChildren,
                childrenCount: childrenCount
            )
            
            print("✅ Relationship data saved successfully!")
            
        } catch {
            print("❌ Error saving relationship data: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ColorTheme.accentPink)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
}

 

// MARK: - Simple Partner Connection View
struct SimplePartnerConnectionView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCodeGeneration = false
    @State private var showingCodeEntry = false
    @State private var connectionCode = ""
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentBlue)
                    
                    Text("Partner Connection")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Connect with your partner to share memories and moments")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Connection options
                VStack(spacing: 20) {
                    Button(action: {
                        showingCodeGeneration = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Generate Connection Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [ColorTheme.primaryPurple, ColorTheme.accentPink], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(color: ColorTheme.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        showingCodeEntry = true
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Enter Partner's Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.success)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Skip for now")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .foregroundColor(ColorTheme.secondaryText)
                        .cornerRadius(25)
                    }
                }
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Partner Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCodeGeneration) {
                CodeGenerationView()
                    .environmentObject(partnerManager)
            }
            .sheet(isPresented: $showingCodeEntry) {
                CodeEntryView()
                    .environmentObject(partnerManager)
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Code Generation View
struct CodeGenerationView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var generatedCode = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accentBlue)
                    
                    Text("Generate Connection Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Share this code with your partner to connect")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Generated code display
                if !generatedCode.isEmpty {
                    VStack(spacing: 20) {
                        Text("Your Connection Code")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text(generatedCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(ColorTheme.accentPink)
                            .padding()
                            .background(ColorTheme.cardBackground)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(ColorTheme.accentPink, lineWidth: 2)
                            )
                        
                        Button(action: {
                            UIPasteboard.general.string = generatedCode
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Code")
                            }
                            .foregroundColor(ColorTheme.accentPink)
                        }
                    }
                    .purpleCard()
                }
                
                // Generate button
                Button(action: {
                    generateCode()
                }) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Code")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [ColorTheme.primaryPurple, ColorTheme.accentPink], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(isGenerating)
                }
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Generate Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateCode() {
        isGenerating = true
        
        // Generate a random 6-digit code
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            generatedCode = code
            isGenerating = false
        }
    }
}

// MARK: - Code Entry View
struct CodeEntryView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode = ""
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "link")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.success)
                    
                    Text("Enter Partner's Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Enter the 6-digit code your partner shared with you")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                // Code input
                VStack(spacing: 20) {
                    Text("Connection Code")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    TextField("000000", text: $enteredCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: enteredCode) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                enteredCode = String(newValue.prefix(6))
                            }
                            // Only allow numbers
                            enteredCode = newValue.filter { $0.isNumber }
                        }
                }
                .purpleCard()
                
                // Connect button
                Button(action: {
                    connectWithPartner()
                }) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "link.circle")
                        }
                        Text(isConnecting ? "Connecting..." : "Connect with Partner")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [ColorTheme.success, ColorTheme.accentBlue], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(enteredCode.count != 6 || isConnecting)
                }
                
                Spacer()
            }
            .padding()
            .purpleTheme()
            .navigationTitle("Enter Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Connection Successful", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You are now connected with your partner!")
            }
        }
    }
    
    private func connectWithPartner() {
        guard enteredCode.count == 6 else {
            errorMessage = "Please enter a valid 6-digit code"
            showingError = true
            return
        }
        
        isConnecting = true
        
        // Simulate connection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isConnecting = false
            
            // For demo purposes, accept any 6-digit code
            if enteredCode.count == 6 {
                showingSuccess = true
                // Here you would actually call partnerManager.connectWithPartner(using: enteredCode)
            } else {
                errorMessage = "Invalid connection code. Please try again."
                showingError = true
            }
        }
    }
} 