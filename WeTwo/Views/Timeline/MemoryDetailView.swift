//
//  MemoryDetailView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct MemoryDetailView: View {
    let memory: Memory
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
                    if let tags = memory.tags, !tags.isEmpty {
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
            if let photoDataString = memory.photo_data, 
               let photoData = Data(base64Encoded: photoDataString),
               let uiImage = UIImage(data: photoData) {
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
                Text(MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.emoji ?? "😐")
                    .font(.title)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                
                if memory.is_shared == "true" {
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
                
                Text(memory.date)
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
                    Text(MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.emoji ?? "😐")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.description ?? "Neutral")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.color ?? .gray)
                        
                        Text("Wie du dich gefühlt hast")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill((MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.color ?? .gray).opacity(0.1))
                )
            }
            
            // Sharing status
            if memory.is_shared == "true" {
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
                ForEach(memory.tags?.components(separatedBy: ",") ?? [], id: \.self) { tag in
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
        Task {
            guard let memoryId = memory.id else { return }
            await memoryManager.deleteMemory(memoryId)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct EditMemoryView: View {
    let memory: Memory
    @EnvironmentObject var memoryManager: MemoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var selectedMood: MoodLevel
    @State private var tags: [String]
    @State private var isSaving = false
    
    init(memory: Memory) {
        self.memory = memory
        self._title = State(initialValue: memory.title)
        self._description = State(initialValue: memory.description ?? "")
        self._location = State(initialValue: memory.location ?? "")
        self._selectedMood = State(initialValue: MoodLevel(rawValue: Int(memory.mood_level) ?? 3) ?? .neutral)
        self._tags = State(initialValue: memory.tags?.components(separatedBy: ",") ?? [])
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
        
        let updatedMemory = Memory(
            id: memory.id,
            user_id: memory.user_id,
            partner_id: memory.partner_id,
            date: memory.date,
            title: title,
            description: description.isEmpty ? nil : description,
            photo_data: memory.photo_data,
            location: location.isEmpty ? nil : location,
            mood_level: String(selectedMood.rawValue),
            tags: tags.joined(separator: ","),
            is_shared: memory.is_shared
        )
        
        // Update the memory with new ID but keep the original date
        var memoryToUpdate = updatedMemory
        memoryToUpdate = Memory(
            id: memory.id,
            user_id: memory.user_id,
            partner_id: memory.partner_id,
            date: memory.date,
            title: title,
            description: description.isEmpty ? nil : description,
            photo_data: memory.photo_data,
            location: location.isEmpty ? nil : location,
            mood_level: String(selectedMood.rawValue),
            tags: tags.joined(separator: ","),
            is_shared: memory.is_shared
        )
        
        Task {
            await memoryManager.updateMemory(memoryToUpdate)
            
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    MemoryDetailView(
        memory: Memory(
            user_id: 0,
            date: "2023-08-15",
            title: "Unser erster Urlaub zusammen",
            description: "Ein wunderschöner Tag am Strand mit Sonnenuntergang. Wir haben den ganzen Tag gelacht und neue Erinnerungen geschaffen.",
            location: "Mallorca, Spanien",
            mood_level: "5",
            tags: "Urlaub,Strand,favorite"
        )
    )
    .environmentObject(MemoryManager())
} 