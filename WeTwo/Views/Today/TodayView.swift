//
//  TodayView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var partnerManager: PartnerManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var gptService: GPTService
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var loveMessageManager = LoveMessageManager()
    
    private let supabaseService = SupabaseService.shared
    
    @State private var selectedMood: MoodLevel = .neutral
    @State private var eventLabel = ""
    @State private var showingEventInput = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: UIImage?
    @State private var showingLoveMessage = false
    @State private var showingLoveMessageEditor = false
    @State private var generatedLoveMessage = ""
    @State private var customLoveMessage = ""
    
    // Partner connection states
    @State private var partnerCodeInput = ""
    @State private var isConnecting = false
    @State private var showingConnectionError = false
    @State private var connectionErrorMessage = ""
    @State private var showingConnectionSuccess = false
    
    // Profile photo states
    @State private var showingProfilePhotoPicker = false
    @State private var profilePhoto: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header with greeting
                    headerSection
                    
                    // Partner connection section (if not connected)
                    if !partnerManager.isConnected {
                        partnerConnectionSection
                        
                        // Love message info when not connected
                        loveMessageInfoSection
                    }
                    
                    // Mood input section
                    moodInputSection
                    
                    // Daily insight card
                    if let insight = moodManager.dailyInsight {
                        dailyInsightCard(insight)
                    }
                    
                    // Love message button (only when connected)
                    if partnerManager.isConnected {
                        loveMessageButton
                    }
                    
                    // Test notification button (for development)
                    if !notificationService.isAuthorized {
                        testNotificationButton
                    }
                    
                    // Partner's mood (if connected)
                    if partnerManager.isConnected {
                        partnerMoodSection
                    }
                    
                    // Received love messages (if connected)
                    if partnerManager.isConnected && !loveMessageManager.receivedMessages.isEmpty {
                        receivedLoveMessagesSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 120)
            }
            .purpleTheme()
            .navigationBarHidden(true)
            .onAppear {
                loadTodayMood()
                loadProfilePhoto()
            }
            .onChange(of: profilePhoto) { _ in
                saveProfilePhoto()
            }
            .sheet(isPresented: $showingEventInput) {
                EventInputView(eventLabel: $eventLabel, onSave: saveMoodEntry)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedImage: $selectedPhoto)
            }
            .sheet(isPresented: $showingProfilePhotoPicker) {
                PhotoPickerView(selectedImage: $profilePhoto)
            }
            .sheet(isPresented: $showingLoveMessageEditor) {
                LoveMessageEditorView(
                    initialMessage: generatedLoveMessage,
                    customMessage: $customLoveMessage,
                    onGenerate: generateLoveMessage,
                    onSend: sendLoveMessage
                )
            }
            .alert(NSLocalizedString("today_generate_love_message", comment: "Generate love message"), isPresented: $showingLoveMessage) {
                Button("Send") {
                    // In a real app, this would send the message to partner
                }
                Button("Copy") {
                    UIPasteboard.general.string = generatedLoveMessage
                }
                Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) { }
            } message: {
                Text(generatedLoveMessage)
            }
            .alert("Verbindungsfehler", isPresented: $showingConnectionError) {
                Button("OK") { }
            } message: {
                Text(connectionErrorMessage)
            }
            .alert("Erfolgreich verbunden! 💕", isPresented: $showingConnectionSuccess) {
                Button("OK") { }
            } message: {
                Text("Du bist jetzt mit deinem Partner verbunden!")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            // User profile section
            HStack(spacing: 15) {
                // Profile photo
                Button(action: { showingProfilePhotoPicker = true }) {
                    if let profilePhoto = profilePhoto {
                        Image(uiImage: profilePhoto)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(ColorTheme.accentPink, lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(ColorTheme.cardBackgroundSecondary)
                            .frame(width: 60, height: 60)
                            .overlay(
                                VStack(spacing: 2) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(ColorTheme.secondaryText)
                                    
                                    Text("Foto")
                                        .font(.caption2)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(ColorTheme.accentPink, lineWidth: 2)
                            )
                    }
                }
                
                // User greeting
                VStack(alignment: .leading, spacing: 5) {
                    if let user = appState.currentUser {
                        Text("Hello, \(user.name)! 💕")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.primaryText)
                    }
                    
                    Text("Tippe auf das Foto um es zu ändern")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
            }
            
            // Partner info (if connected)
            if partnerManager.isConnected, let partnerProfile = partnerManager.partnerProfile {
                Divider()
                    .background(ColorTheme.secondaryText.opacity(0.3))
                
                HStack(spacing: 15) {
                    // Partner profile photo
                    if let partnerPhoto = partnerManager.partnerProfilePhoto {
                        Image(uiImage: partnerPhoto)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(ColorTheme.accentBlue, lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(ColorTheme.cardBackgroundSecondary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("👥")
                                    .font(.title2)
                                    .foregroundColor(ColorTheme.secondaryText)
                            )
                            .overlay(
                                Circle()
                                    .stroke(ColorTheme.accentBlue, lineWidth: 2)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Verbunden mit \(partnerProfile.name)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("Partner-Code: \(partnerManager.ownConnectionCode)")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: disconnectPartner) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(ColorTheme.error)
                    }
                }
            }
        }
        .purpleCard()
        .padding(.horizontal)
    }
    
    private var partnerConnectionSection: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Text("💕")
                    .font(.title2)
                
                Text("Partner verbinden")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            // Partner code input
            VStack(spacing: 10) {
                Text("Partner-Code eingeben:")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    TextField("Code eingeben...", text: $partnerCodeInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .disabled(isConnecting)
                    
                    Button(action: connectWithPartner) {
                        if isConnecting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Verbinden")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(partnerCodeInput.isEmpty ? Color.gray : ColorTheme.accentPink)
                    )
                    .disabled(partnerCodeInput.isEmpty || isConnecting)
                }
            }
            
            Divider()
                .background(ColorTheme.secondaryText.opacity(0.3))
            
            // Own partner code
            VStack(spacing: 10) {
                Text("Dein Partner-Code:")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Text(partnerManager.ownConnectionCode)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ColorTheme.cardBackgroundSecondary)
                        )
                    
                    Button(action: copyOwnCode) {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .foregroundColor(ColorTheme.accentBlue)
                    }
                    .padding(.horizontal, 10)
                }
                
                Text("Gib diesen Code deinem Partner, damit er dich verbinden kann")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    private var moodInputSection: some View {
        VStack(spacing: 25) {
            // Emoji mood slider
            VStack(spacing: 15) {
                Text(selectedMood.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(selectedMood == .veryHappy ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: selectedMood)
                
                Text(selectedMood.description)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(selectedMood.color)
            }
            
            // Mood slider
            VStack(spacing: 10) {
                HStack(spacing: 0) {
                    ForEach(MoodLevel.allCases, id: \.self) { mood in
                        Button(action: { selectedMood = mood }) {
                            Text(mood.emoji)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(selectedMood == mood ? mood.color.opacity(0.2) : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(ColorTheme.cardBackgroundSecondary)
                )
            }
            
            // Action buttons
            HStack(spacing: 15) {
                Button(action: { showingEventInput = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(NSLocalizedString("today_add_event", comment: "Add event"))
                    }
                    .font(.body)
                    .foregroundColor(ColorTheme.accentBlue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ColorTheme.accentBlue, lineWidth: 1)
                    )
                }
                
                Button(action: { showingPhotoPicker = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text(NSLocalizedString("today_add_photo", comment: "Add photo"))
                    }
                    .font(.body)
                    .foregroundColor(ColorTheme.accentPink)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ColorTheme.accentPink, lineWidth: 1)
                    )
                }
            }
            
            // Save mood button
            Button(action: saveMoodEntry) {
                let gradientColors = [selectedMood.color, selectedMood.color.opacity(0.7)]
                let gradient = LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                
                Text(NSLocalizedString("today_save_mood", comment: "Save mood"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(gradient)
                    )
                    .shadow(color: selectedMood.color.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    private func dailyInsightCard(_ insight: DailyInsight) -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("💫")
                    .font(.title)
                
                Text(NSLocalizedString("today_daily_insight", comment: "Daily insight"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                if !appState.isPremium {
                    Text("\(appState.dailyInsightsRemaining) \(NSLocalizedString("today_insights_remaining", comment: "Insights remaining"))")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.1))
                        )
                }
            }
            
                            if moodManager.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(NSLocalizedString("today_generating_insight", comment: "Generating insight"))
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    Text(insight.insight)
                        .font(.body)
                        .foregroundColor(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    if let astrologicalInfluence = insight.astrologicalInfluence {
                        HStack {
                            Text("⭐")
                            Text(astrologicalInfluence)
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    if let compatibilityScore = insight.compatibilityScore {
                        HStack {
                            Text(NSLocalizedString("today_compatibility_score", comment: "Compatibility score") + ":")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                            
                            Text("\(compatibilityScore)%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorTheme.accentBlue)
                        }
                    }
                }
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    private var loveMessageButton: some View {
        Button(action: {
            showingLoveMessageEditor = true
        }) {
            HStack {
                Text("💕")
                    .font(.title2)
                
                Text(NSLocalizedString("today_generate_love_message", comment: "Generate love message"))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if gptService.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right")
                    .font(.title3)
                }
            }
            .foregroundColor(.white)
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .disabled(gptService.isGenerating)
    }
    
    private var testNotificationButton: some View {
        Button(action: {
            notificationService.scheduleLocalNotification(
                title: "🧪 Test-Benachrichtigung",
                body: "Dies ist eine Test-Benachrichtigung für die Entwicklung"
            )
        }) {
            HStack {
                Text("🔔")
                    .font(.title2)
                
                Text("Push-Benachrichtigungen aktivieren")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    private var partnerMoodSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("💕")
                    .font(.title2)
                
                Text(NSLocalizedString("today_partner_mood", comment: "Partner mood"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                // Show partner name if available
                if let partnerName = partnerManager.partnerProfile?.name {
                    Text(partnerName)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ColorTheme.accentPink.opacity(0.2))
                        )
                }
            }
            
            if let partnerMood = partnerManager.getPartnerMood(for: Date()) {
                VStack(spacing: 12) {
                    HStack {
                        Text(partnerMood.moodLevel.emoji)
                            .font(.system(size: 40))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(partnerMood.moodLevel.description)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(partnerMood.moodLevel.color)
                            
                            if let event = partnerMood.eventLabel {
                                Text(event)
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Time indicator
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(NSLocalizedString("today_partner_mood_today", comment: "Partner mood today"))
                                .font(.caption2)
                                .foregroundColor(ColorTheme.secondaryText)
                            
                            Text("✓")
                                .font(.caption)
                                .foregroundColor(ColorTheme.success)
                        }
                    }
                    
                    // Mood visualization
                    HStack(spacing: 8) {
                        ForEach(MoodLevel.allCases, id: \.self) { mood in
                            Circle()
                                .fill(mood == partnerMood.moodLevel ? mood.color : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(partnerMood.moodLevel.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(partnerMood.moodLevel.color.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("⏳")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("today_partner_no_mood", comment: "Partner no mood"))
                                .font(.body)
                                .foregroundColor(ColorTheme.secondaryText)
                            
                            Text(NSLocalizedString("today_waiting_for_partner", comment: "Waiting for partner"))
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(25)
        .purpleCard()
    }
    
    private func saveMoodEntry() {
        var photoData: Data?
        if let image = selectedPhoto {
            // Add error handling for image processing
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                print("❌ Error: Failed to convert image to JPEG data")
                return
            }
            photoData = data
        }
        
        moodManager.addMoodEntry(
            selectedMood,
            eventLabel: eventLabel.isEmpty ? nil : eventLabel,
            photoData: photoData
        )
        
        // Sync with partner if connected
        if partnerManager.isConnected {
            let entry = MoodEntry(
                userId: appState.currentUser?.id ?? UUID(),
                moodLevel: selectedMood,
                eventLabel: eventLabel.isEmpty ? nil : eventLabel,
                photoData: photoData
            )
            partnerManager.syncPartnerMood(entry)
        }
        
        // Reset form but keep the selected mood
        eventLabel = ""
        selectedPhoto = nil
        // Don't reset selectedMood - keep the saved mood visible
        
        // Use daily insight if not premium
        if !appState.isPremium {
            appState.useDailyInsight()
        }
    }
    
    private func loadTodayMood() {
        // Load today's saved mood if it exists
        if let todayMood = moodManager.todayMood {
            selectedMood = todayMood.moodLevel
            if let event = todayMood.eventLabel {
                eventLabel = event
            }
        }
    }
    
    private func generateLoveMessage() {
        guard let user = appState.currentUser else { return }
        
        Task {
            do {
                let message = try await gptService.generateLoveMessage(for: user.name, mood: selectedMood)
                await MainActor.run {
                    generatedLoveMessage = message
                    customLoveMessage = message
                }
            } catch {
                print("Error generating love message: \(error)")
            }
        }
    }
    
    private func sendLoveMessage() {
        guard let partnerId = partnerManager.partnerProfile?.id else {
            print("❌ Partner not found")
            return
        }
        
        Task {
            do {
                try await loveMessageManager.sendLoveMessage(to: partnerId, message: customLoveMessage)
                
                await MainActor.run {
                    showingLoveMessageEditor = false
                    customLoveMessage = ""
                }
                
                print("✅ Love message sent successfully")
            } catch {
                print("❌ Error sending love message: \(error)")
            }
        }
    }
    
    private func connectWithPartner() {
        guard !partnerCodeInput.isEmpty else { return }
        
        isConnecting = true
        
        Task {
            do {
                try await partnerManager.connectWithPartner(using: partnerCodeInput)
                
                await MainActor.run {
                    isConnecting = false
                    partnerCodeInput = ""
                    showingConnectionSuccess = true
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    connectionErrorMessage = "Verbindung fehlgeschlagen: \(error.localizedDescription)"
                    showingConnectionError = true
                }
            }
        }
    }
    
    private func copyOwnCode() {
        UIPasteboard.general.string = partnerManager.ownConnectionCode
    }
    
    private func disconnectPartner() {
        Task {
            await partnerManager.disconnectPartner()
        }
    }
    
    private func saveProfilePhoto() {
        guard let photo = profilePhoto,
              let userId = appState.currentUser?.id else { return }
        
        Task {
            do {
                if let imageData = photo.jpegData(compressionQuality: 0.8) {
                    // Upload to Supabase Storage with folder structure
                    _ = try await supabaseService.uploadProfilePhoto(userId: userId, imageData: imageData)
                    
                    // Also save locally for offline access
                    UserDefaults.standard.set(imageData, forKey: "userProfilePhoto")
                    
                    print("✅ Profile photo uploaded successfully")
                }
            } catch {
                print("❌ Error uploading profile photo: \(error)")
                
                // Fallback to local storage only
                if let imageData = photo.jpegData(compressionQuality: 0.8) {
                    UserDefaults.standard.set(imageData, forKey: "userProfilePhoto")
                }
            }
        }
    }
    
    private func loadProfilePhoto() {
        guard let userId = appState.currentUser?.id else { return }
        
        Task {
            do {
                // Try to load from Supabase first
                if let photoData = try await supabaseService.downloadProfilePhoto(userId: userId),
                   let image = UIImage(data: photoData) {
                    await MainActor.run {
                        profilePhoto = image
                    }
                    print("✅ Profile photo loaded from Supabase")
                } else {
                    // Fallback to local storage
                    await MainActor.run {
                        if let imageData = UserDefaults.standard.data(forKey: "userProfilePhoto"),
                           let image = UIImage(data: imageData) {
                            profilePhoto = image
                        }
                    }
                    print("📱 Profile photo loaded from local storage")
                }
            } catch {
                print("❌ Error loading profile photo from Supabase: \(error)")
                
                // Fallback to local storage
                await MainActor.run {
                    if let imageData = UserDefaults.standard.data(forKey: "userProfilePhoto"),
                       let image = UIImage(data: imageData) {
                        profilePhoto = image
                    }
                }
            }
        }
    }
    
    // MARK: - Love Message Info Section (when not connected)
    private var loveMessageInfoSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("💕")
                    .font(.title2)
                
                Text("Liebesnachrichten")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("🔗")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("love_messages_connect_required", comment: "Connect with partner"))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text(NSLocalizedString("love_messages_connect_description", comment: "Send and receive love messages"))
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Text("💌")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("love_messages_personalized", comment: "Personalized messages"))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text(NSLocalizedString("love_messages_ai_generated", comment: "AI-generated love messages based on mood"))
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorTheme.cardBackgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ColorTheme.accentPink.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Received Love Messages Section
    private var receivedLoveMessagesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("💌 Liebesnachrichten")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                if loveMessageManager.unreadCount > 0 {
                    Text("\(loveMessageManager.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(ColorTheme.accentPink))
                }
            }
            
            ForEach(loveMessageManager.receivedMessages.prefix(3)) { message in
                LoveMessageCard(message: message) {
                    Task {
                        try? await loveMessageManager.markAsRead(message.id)
                    }
                }
            }
            
            if loveMessageManager.receivedMessages.count > 3 {
                Button(action: {
                    // TODO: Show all messages view
                }) {
                    Text("Alle anzeigen (\(loveMessageManager.receivedMessages.count))")
                        .font(.body)
                        .foregroundColor(ColorTheme.accentPink)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorTheme.cardBackgroundSecondary)
        )
    }
}

// MARK: - Love Message Card
struct LoveMessageCard: View {
    let message: LoveMessage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Unread indicator
                if !message.isRead {
                    Circle()
                        .fill(ColorTheme.accentPink)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.message)
                        .font(.body)
                        .foregroundColor(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    Text(formatDate(message.timestamp))
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(message.isRead ? ColorTheme.cardBackgroundSecondary : ColorTheme.accentPink.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

#Preview {
    TodayView()
        .environmentObject(MoodManager())
        .environmentObject(PartnerManager.shared)
        .environmentObject(AppState())
        .environmentObject(GPTService())
        .environmentObject(NotificationService.shared)
} 