//
//  MemoryCard.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct MemoryCard: View {
    let memory: Memory
    let onTap: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Photo section
                photoSection
                
                // Content section
                contentSection
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var photoSection: some View {
        ZStack(alignment: .topTrailing) {
            if let photoDataString = memory.photo_data, 
               !photoDataString.isEmpty,
               let photoData = Data(base64Encoded: photoDataString),
               let uiImage = UIImage(data: photoData),
               uiImage.size.width > 0 && uiImage.size.height > 0 {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.pink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 10) {
                            Text("📸")
                                .font(.system(size: 40))
                            Text("Kein Foto")
                                .font(.body)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    )
            }
            
            // Mood indicator
            VStack(spacing: 5) {
                Text(MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.emoji ?? "😐")
                    .font(.title2)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                
                if memory.is_shared == "true" {
                    Text("💕")
                        .font(.body)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                }
            }
            .padding(.top, 15)
            .padding(.trailing, 15)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(memory.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primaryText)
                        .lineLimit(2)
                    
                    Text(memory.date)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
                
                // Tags
                if let tagsString = memory.tags, !tagsString.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tagsString.components(separatedBy: ",").prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.8))
                                )
                        }
                        
                        if let tagsString = memory.tags, tagsString.components(separatedBy: ",").count > 2 {
                            Text("+\(tagsString.components(separatedBy: ",").count - 2)")
                                .font(.caption2)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                }
            }
            
            // Description
            if let description = memory.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            // Location and tags
            HStack {
                if let location = memory.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(ColorTheme.accentBlue)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                // Additional info
                HStack(spacing: 8) {
                    if memory.is_shared == "true" {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                            
                            Text("Geteilt")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    Text(MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.description ?? "Neutral")
                        .font(.caption)
                        .foregroundColor(MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.color ?? .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill((MoodLevel(rawValue: Int(memory.mood_level) ?? 3)?.color ?? .gray).opacity(0.1))
                        )
                }
            }
        }
        .padding(20)
    }
}

#Preview {
    MemoryCard(
        memory: Memory(
            user_id: 0,
            date: "2023-08-15",
            title: "Unser erster Urlaub zusammen",
            description: "Ein wunderschöner Tag am Strand mit Sonnenuntergang. Wir haben den ganzen Tag gelacht und neue Erinnerungen geschaffen.",
            location: "Mallorca, Spanien",
            mood_level: "5",
            tags: "Urlaub,Strand,favorite"
        )
    ) {
        print("Memory tapped")
    }
    .padding()
} 