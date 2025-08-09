//
//  MemoryDetailView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct MemoryDetailView: View {
    let memory: MemoryEntry
    @EnvironmentObject var memoryManager: MemoryManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Photo section
                    photoSection
                    
                    // Content section
                    contentSection
                    
                    // Tags section
                    if !memory.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Actions section
                    actionsSection
                    
                    Spacer(minLength: 100)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.accentBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        
                        Button(action: { showingDeleteAlert = true }) {
                            Label("Löschen", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(ColorTheme.accentBlue)
                    }
                }
            }
            .alert("Erinnerung löschen", isPresented: $showingDeleteAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    deleteMemory()
                }
            } message: {
                Text("Möchtest du diese Erinnerung wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .sheet(isPresented: $showingEditSheet) {
                EditMemoryView(memory: memory)
                    .environmentObject(memoryManager)
            }
        }
    }
    
    private var photoSection: some View {
        ZStack(alignment: .topTrailing) {
            if let photoData = memory.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.pink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 15) {
                            Text("📸")
                                .font(.system(size: 60))
                            Text("Kein Foto")
                                .font(.title3)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    )
            }
            
            // Mood and sharing indicators
            VStack(spacing: 10) {
                Text(memory.moodLevel.emoji)
                    .font(.title)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                
                if memory.isShared {
                    Text("💕")
                        .font(.title2)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                }
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and date
            VStack(alignment: .leading, spacing: 10) {
                Text(memory.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(dateFormatter.string(from: memory.date))
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            // Description
            if let description = memory.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreibung")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Location
            if let location = memory.location, !location.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ort")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.body)
                            .foregroundColor(ColorTheme.accentBlue)
                        
                        Text(location)
                            .font(.body)
                            .foregroundColor(ColorTheme.primaryText)
                    }
                }
            }
            
            // Mood
            VStack(alignment: .leading, spacing: 8) {
                Text("Stimmung")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                HStack(spacing: 12) {
                    Text(memory.moodLevel.emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(memory.moodLevel.description)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(memory.moodLevel.color)
                        
                        Text("Wie du dich gefühlt hast")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(memory.moodLevel.color.opacity(0.1))
                )
            }
            
            // Sharing status
            if memory.isShared {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Geteilt mit Partner")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    HStack(spacing: 12) {
                        Text("💕")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Diese Erinnerung ist mit deinem Partner geteilt")
                                .font(.body)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Text("Beide können sie sehen und bearbeiten")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.pink.opacity(0.1))
                    )
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(memory.tags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue)
                    )
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 15) {
            Button(action: { showingEditSheet = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Erinnerung bearbeiten")
                }
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.accentBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white)
                )
            }
            
            Button(action: { showingDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Erinnerung löschen")
                }
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.red, lineWidth: 2)
                        .background(Color.white)
                )
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func deleteMemory() {
        memoryManager.deleteMemory(memory)
        dismiss()
    }
}

struct EditMemoryView: View {
    let memory: MemoryEntry
    @EnvironmentObject var memoryManager: MemoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var selectedMood: MoodLevel
    @State private var tags: [String]
    @State private var isSaving = false
    
    init(memory: MemoryEntry) {
        self.memory = memory
        self._title = State(initialValue: memory.title)
        self._description = State(initialValue: memory.description ?? "")
        self._location = State(initialValue: memory.location ?? "")
        self._selectedMood = State(initialValue: memory.moodLevel)
        self._tags = State(initialValue: memory.tags)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    Text("Erinnerung bearbeiten")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    // Title and description
                    VStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Titel")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            TextField("Titel", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Beschreibung")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            TextField("Beschreibung", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ort")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            TextField("Ort", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    
                    // Mood selection
                    VStack(spacing: 15) {
                        Text("Stimmung")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
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
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.accentBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.accentBlue)
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        let updatedMemory = MemoryEntry(
            userId: memory.userId,
            title: title,
            description: description.isEmpty ? nil : description,
            photoData: memory.photoData,
            location: location.isEmpty ? nil : location,
            moodLevel: selectedMood,
            tags: tags,
            partnerId: memory.partnerId
        )
        
        // Update the memory with new ID but keep the original date
        var memoryToUpdate = updatedMemory
        memoryToUpdate = MemoryEntry(
            userId: memory.userId,
            title: title,
            description: description.isEmpty ? nil : description,
            photoData: memory.photoData,
            location: location.isEmpty ? nil : location,
            moodLevel: selectedMood,
            tags: tags,
            partnerId: memory.partnerId
        )
        
        memoryManager.updateMemory(memoryToUpdate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    MemoryDetailView(
        memory: MemoryEntry(
            userId: UUID(),
            title: "Unser erster Urlaub zusammen",
            description: "Ein wunderschöner Tag am Strand mit Sonnenuntergang. Wir haben den ganzen Tag gelacht und neue Erinnerungen geschaffen.",
            location: "Mallorca, Spanien",
            moodLevel: .veryHappy,
            tags: ["Urlaub", "Strand", "favorite"]
        )
    )
    .environmentObject(MemoryManager())
} 