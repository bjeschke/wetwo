//
//  TimelineView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var partnerManager: PartnerManager
    @State private var showingAddMemory = false
    @State private var selectedMemory: Memory?
    @State private var showingMemoryDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with stats
                    headerSection
                    
                    // Filter buttons
                    filterSection
                    
                    // Timeline content
                    timelineContent
                }
            }
            .purpleTheme()
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMemory = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(ColorTheme.accentBlue)
                    }
                }
            }
            .sheet(isPresented: $showingAddMemory) {
                AddMemoryView()
                    .environmentObject(memoryManager)
                    .environmentObject(appState)
                    .environmentObject(partnerManager)
            }
            .sheet(isPresented: $showingMemoryDetail) {
                if let memory = selectedMemory {
                    MemoryDetailView(memory: memory)
                        .environmentObject(memoryManager)
                }
            }
        }
    }
    
    private var headerSection: some View {
        let stats = memoryManager.getMemoryStats()
        
        return VStack(spacing: 20) {
            // Stats only
            VStack(spacing: 10) {
                Text("📸")
                    .font(.system(size: 50))
            }
            
            // Stats cards
            HStack(spacing: 15) {
                StatCard(
                    title: NSLocalizedString("timeline_stats_total", comment: "Total memories"),
                    value: "\(stats.total)",
                    icon: "📅",
                    color: .blue
                )
                
                StatCard(
                    title: NSLocalizedString("timeline_stats_shared", comment: "Shared memories"),
                    value: "\(stats.shared)",
                    icon: "💕",
                    color: .pink
                )
                
                StatCard(
                    title: NSLocalizedString("timeline_stats_average", comment: "Average mood"),
                    value: stats.averageMood.isFinite ? String(format: "%.1f", stats.averageMood) : "3.0",
                    icon: "😊",
                    color: .orange
                )
            }
        }
        .padding(25)
        .purpleCard()
        .padding(.horizontal, 20)
        .padding(.top, 120)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(MemoryManager.MemoryFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: memoryManager.selectedFilter == filter,
                        action: { memoryManager.selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    private var timelineContent: some View {
        let filteredMemories = memoryManager.getFilteredMemories(filter: memoryManager.selectedFilter)
        
        return LazyVStack(spacing: 20) {
            if filteredMemories.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredMemories) { memory in
                    MemoryCard(memory: memory) {
                        selectedMemory = memory
                        showingMemoryDetail = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("📸")
                .font(.system(size: 80))
            
            Text(NSLocalizedString("timeline_no_memories", comment: "No memories"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            Text(NSLocalizedString("timeline_no_memories_subtitle", comment: "No memories subtitle"))
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddMemory = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(NSLocalizedString("timeline_add_first_memory", comment: "Add first memory"))
                }
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 20)
        }
        .padding(40)
        .purpleCard()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.1))
        )
    }
}

struct FilterButton: View {
    let filter: MemoryManager.MemoryFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(filter.emoji)
                    .font(.body)
                
                Text(filter.localizedTitle)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : ColorTheme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TimelineView()
        .environmentObject(MemoryManager())
        .environmentObject(AppState())
        .environmentObject(PartnerManager.shared)
} 