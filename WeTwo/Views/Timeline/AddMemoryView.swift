//
//  AddMemoryView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI
import PhotosUI

struct AddMemoryView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var selectedMood: MoodLevel = .happy
    @State private var selectedPhoto: UIImage?
    @State private var showingPhotoPicker = false
    @State private var showingTagInput = false
    @State private var tags: [String] = []
    @State private var isSharingWithPartner = false
    @State private var isSaving = false
    
    private let quickTags = [
        "Urlaub", "Date Night", "Geburtstag", "Jahrestag", "Reise", 
        "Essen", "Konzert", "Sport", "Familie", "Freunde", "favorite"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header with buttons
                headerWithButtons
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Icon only
                        VStack(spacing: 20) {
                            Text("📸")
                                .font(.system(size: 60))
                        }
                        
                        // Photo section
                        photoSection
                        
                        // Title and description
                        titleDescriptionSection
                        
                        // Location
                        locationSection
                        
                        // Mood selection
                        moodSection
                        
                        // Tags
                        tagsSection
                        
                        // Partner sharing
                        if partnerManager.isConnected {
                            partnerSharingSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .purpleTheme()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedImage: $selectedPhoto)
            }
            .alert("Tag hinzufügen", isPresented: $showingTagInput) {
                TextField("Tag eingeben", text: .constant(""))
                Button("Hinzufügen") {
                    // Add tag logic
                }
                Button("Abbrechen", role: .cancel) { }
            }
        }
    }
    
    private var headerWithButtons: some View {
        HStack {
            Button("Abbrechen") {
                dismiss()
            }
            .foregroundColor(ColorTheme.accentBlue)
            .font(.body)
            
            Spacer()
            
            Text("Neue Erinnerung")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
            
            Button("Speichern") {
                saveMemory()
            }
            .fontWeight(.semibold)
            .foregroundColor(ColorTheme.accentBlue)
            .disabled(title.isEmpty || isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
        .background(ColorTheme.cardBackground)
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("📸")
                .font(.system(size: 60))
            
            Text("Neue Erinnerung erstellen")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Teile einen besonderen Moment mit deinem Partner")
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    private var photoSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("📷")
                    .font(.title2)
                
                Text("Foto")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            if let image = selectedPhoto {
                VStack(spacing: 10) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Button("Foto ändern") {
                        showingPhotoPicker = true
                    }
                    .font(.body)
                    .foregroundColor(ColorTheme.accentBlue)
                }
            } else {
                Button(action: { showingPhotoPicker = true }) {
                    VStack(spacing: 15) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ColorTheme.accentBlue)
                        
                        Text("Foto hinzufügen")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("Optional - aber Fotos machen Erinnerungen lebendiger!")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(ColorTheme.accentBlue, style: StrokeStyle(lineWidth: 2, dash: [10]))
                            .background(ColorTheme.accentBlue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .purpleCard()
    }
    
    private var titleDescriptionSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("✏️")
                    .font(.title2)
                
                Text("Details")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Titel")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    TextField("z.B. Unser erster Urlaub zusammen", text: $title)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .cornerRadius(10)
                        .foregroundColor(ColorTheme.primaryText)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreibung (optional)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    TextField("Erzähle mehr über diesen Moment...", text: $description, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .lineLimit(3...6)
                        .padding()
                        .background(ColorTheme.cardBackgroundSecondary)
                        .cornerRadius(10)
                        .foregroundColor(ColorTheme.primaryText)
                }
            }
        }
        .padding(20)
        .purpleCard()
    }
    
    private var locationSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("📍")
                    .font(.title2)
                
                Text("Ort")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            TextField("z.B. Mallorca, Spanien", text: $location)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .padding()
                .background(ColorTheme.cardBackgroundSecondary)
                .cornerRadius(10)
                .foregroundColor(ColorTheme.primaryText)
        }
        .padding(20)
        .purpleCard()
    }
    
    private var moodSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("😊")
                    .font(.title2)
                
                Text("Wie war deine Stimmung?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                Text(selectedMood.emoji)
                    .font(.system(size: 50))
                    .scaleEffect(selectedMood == .veryHappy ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: selectedMood)
                
                Text(selectedMood.description)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(selectedMood.color)
            }
            
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
                    .fill(ColorTheme.cardBackgroundSecondary.opacity(0.3))
            )
        }
        .padding(20)
        .purpleCard()
    }
    
    private var tagsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("🏷️")
                    .font(.title2)
                
                Text("Tags")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Button("+") {
                    showingTagInput = true
                }
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.accentBlue)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(ColorTheme.accentBlue.opacity(0.2))
                )
            }
            
            if tags.isEmpty {
                Text("Füge Tags hinzu, um deine Erinnerung zu kategorisieren")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: { tags.removeAll { $0 == tag } }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(ColorTheme.accentBlue)
                        )
                    }
                }
            }
            
            // Quick tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickTags, id: \.self) { tag in
                        Button(action: {
                            if !tags.contains(tag) {
                                tags.append(tag)
                            }
                        }) {
                            Text(tag)
                                .font(.body)
                                .foregroundColor(tags.contains(tag) ? .white : ColorTheme.accentBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(tags.contains(tag) ? ColorTheme.accentBlue : ColorTheme.accentBlue.opacity(0.2))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 5)
            }
        }
        .padding(20)
        .purpleCard()
    }
    
    private var partnerSharingSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("💕")
                    .font(.title2)
                
                Text("Mit Partner teilen")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Toggle("", isOn: $isSharingWithPartner)
                    .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accentBlue))
            }
            
            if isSharingWithPartner {
                Text("Diese Erinnerung wird automatisch mit deinem Partner geteilt")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .purpleCard()
    }
    
    private func saveMemory() {
        isSaving = true
        
        var photoData: Data?
        if let image = selectedPhoto {
            // Add error handling for image processing
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                print("❌ Error: Failed to convert image to JPEG data")
                isSaving = false
                return
            }
            photoData = data
        }
        
        let memory = MemoryEntry(
            userId: appState.currentUser?.id ?? UUID(),
            title: title,
            description: description.isEmpty ? nil : description,
            photoData: photoData,
            location: location.isEmpty ? nil : location,
            moodLevel: selectedMood,
            tags: tags,
            partnerId: isSharingWithPartner ? partnerManager.partner?.id : nil
        )
        
        memoryManager.addMemory(memory)
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    AddMemoryView()
        .environmentObject(MemoryManager())
        .environmentObject(AppState())
        .environmentObject(PartnerManager())
} 