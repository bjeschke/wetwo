//
//  CalendarEntryRow.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 23.08.25.
//

import SwiftUI

struct CalendarEntryRow: View {
    let entry: CalendarEntry
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 4) {
                if entry.isAllDay {
                    Text("🌅")
                        .font(.title3)
                } else {
                    Text(timeFormatter.string(from: entry.date))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.accentBlue)
                }
                
                Text(dateFormatter.string(from: entry.date))
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            .frame(width: 60)
            
            // Entry content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                    .lineLimit(2)
                
                if !entry.description.isEmpty {
                    Text(entry.description)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .lineLimit(2)
                }
                
                // Entry type indicator
                HStack(spacing: 4) {
                    if entry.isAllDay {
                        Text("Ganztägig")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(ColorTheme.accentPink)
                            )
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Action indicator
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(ColorTheme.cardBackgroundSecondary)
        )
    }
}

#Preview {
    VStack(spacing: 10) {
        CalendarEntryRow(
            entry: CalendarEntry(
                userId: "",
                title: "Romantisches Abendessen",
                description: "Gemeinsames Kochen und ein schöner Abend zu zweit",
                date: Date(),
                isAllDay: false
            )
        )
        
        CalendarEntryRow(
            entry: CalendarEntry(
                userId: "",
                title: "Wochenendausflug",
                description: "",
                date: Date().addingTimeInterval(86400),
                isAllDay: true
            )
        )
    }
    .padding()
}