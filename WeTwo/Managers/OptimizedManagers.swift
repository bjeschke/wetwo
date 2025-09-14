import SwiftUI
import Observation
import FirebaseAuth

// MARK: - Modern Observable Pattern with @Observable Macro (iOS 17+)

@Observable
@MainActor
final class OptimizedMoodManager {
    // Properties are automatically observable - no @Published needed
    var todayMood: MoodEntry?
    var weeklyMoods: [MoodEntry] = []
    var partnerTodayMood: MoodEntry?
    var partnerWeeklyMoods: [MoodEntry] = []
    var dailyInsight: DailyInsight?
    var isLoading = false
    
    private let dataService = ServiceFactory.shared.getCurrentService()
    
    // Use nonisolated for background operations
    nonisolated init() {
        Task { @MainActor in
            await loadMoodData()
        }
    }
    
    func loadMoodData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Parallel loading for better performance
            async let userMoods = fetchUserMoods()
            async let partnerMoods = fetchPartnerMoods()
            
            let (userResults, partnerResults) = try await (userMoods, partnerMoods)
            
            self.weeklyMoods = userResults
            self.partnerWeeklyMoods = partnerResults
            self.todayMood = userResults.first
            self.partnerTodayMood = partnerResults.first
        } catch {
            print("Error loading mood data: \(error)")
        }
    }
    
    private func fetchUserMoods() async throws -> [MoodEntry] {
        // Simulate async fetch
        try await Task.sleep(nanoseconds: 100_000_000)
        return []
    }
    
    private func fetchPartnerMoods() async throws -> [MoodEntry] {
        // Simulate async fetch
        try await Task.sleep(nanoseconds: 100_000_000)
        return []
    }
    
    func addMoodEntry(_ mood: MoodLevel, eventLabel: String? = nil) async throws {
        let entry = MoodEntry(
            userId: "",
            moodLevel: mood,
            eventLabel: eventLabel,
            location: nil,
            photoData: nil
        )
        
        // Update UI immediately
        todayMood = entry
        
        // Then sync with backend
        Task.detached {
            // TODO: Implement saveMoodEntry in DataServiceProtocol
            // try await self.dataService.saveMoodEntry(entry)
        }
    }
}

// MARK: - Optimized Partner Manager

@Observable
@MainActor
final class OptimizedPartnerManager {
    static let shared = OptimizedPartnerManager()
    
    var isConnected = false
    var partnerProfile: PartnerProfile?
    var connectionCode = ""
    var hasPendingInvitation = false
    var pendingInvitation: Invitation?
    
    private var connectionTask: Task<Void, Never>?
    
    private init() {
        Task {
            await checkPartnerConnection()
        }
    }
    
    func checkPartnerConnection() async {
        // Cancel previous task if running
        connectionTask?.cancel()
        
        connectionTask = Task {
            do {
                // Check for cancellation
                try Task.checkCancellation()
                
                // Check partner connection using backend service
                let connected = false // TODO: Implement checkPartnerConnection
                // let connected = try await ServiceFactory.shared
                //     .getCurrentService()
                //     .checkPartnerConnection()
                
                self.isConnected = connected
                
                if connected {
                    await loadPartnerProfile()
                }
            } catch {
                if !Task.isCancelled {
                    print("Connection check failed: \(error)")
                }
            }
        }
    }
    
    private func loadPartnerProfile() async {
        // Load partner profile asynchronously
    }
    
    func cleanup() {
        connectionTask?.cancel()
    }
}

// MARK: - Optimized Memory Manager with Lazy Loading

@Observable
@MainActor
final class OptimizedMemoryManager {
    var memories: [Memory] = []
    var selectedFilter: MemoryFilter = .all
    var isLoading = false
    var hasMore = true
    
    private var currentPage = 0
    private let pageSize = 20
    private var loadTask: Task<Void, Never>?
    
    var filteredMemories: [Memory] {
        switch selectedFilter {
        case .all:
            return memories
        case .special:
            return memories.filter { $0.isSpecial }
        case .everyday:
            return memories.filter { !$0.isSpecial }
        }
    }
    
    func loadMoreMemories() async {
        guard !isLoading && hasMore else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        loadTask?.cancel()
        loadTask = Task {
            do {
                try Task.checkCancellation()
                
                let newMemories = try await fetchMemories(
                    page: currentPage,
                    size: pageSize
                )
                
                if !Task.isCancelled {
                    self.memories.append(contentsOf: newMemories)
                    self.currentPage += 1
                    self.hasMore = newMemories.count == pageSize
                }
            } catch {
                if !Task.isCancelled {
                    print("Failed to load memories: \(error)")
                }
            }
        }
    }
    
    private func fetchMemories(page: Int, size: Int) async throws -> [Memory] {
        // Implement pagination
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    func prefetchMemories(at indices: [Int]) {
        let maxIndex = indices.max() ?? 0
        if maxIndex >= memories.count - 5 {
            Task {
                await loadMoreMemories()
            }
        }
    }
}

// MARK: - Performance Optimized Views

struct OptimizedTodayView: View {
    // Use @State for Observable objects in iOS 17+
    @State private var moodManager = OptimizedMoodManager()
    @State private var partnerManager = OptimizedPartnerManager.shared
    
    var body: some View {
        StandardScreenLayout {
            LazyVStack(spacing: DesignSystem.Spacing.l) {
                headerSection
                
                if partnerManager.isConnected {
                    partnerSection
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
                
                moodSection
            }
        }
        .task {
            // Load data when view appears
            await moodManager.loadMoodData()
        }
        .task(id: partnerManager.isConnected) {
            // Reload when connection status changes
            if partnerManager.isConnected {
                await moodManager.loadMoodData()
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        // Header content
        EmptyView()
    }
    
    @ViewBuilder
    private var partnerSection: some View {
        // Partner content
        EmptyView()
    }
    
    @ViewBuilder
    private var moodSection: some View {
        // Mood content
        EmptyView()
    }
}

// MARK: - Optimized Timeline with Lazy Loading

struct OptimizedTimelineView: View {
    @State private var memoryManager = OptimizedMemoryManager()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.m) {
                ForEach(memoryManager.filteredMemories) { memory in
                    MemoryCard(memory: memory, onTap: {})
                        .onAppear {
                            // Prefetch when nearing end
                            if let index = memoryManager.memories.firstIndex(where: { $0.id == memory.id }) {
                                memoryManager.prefetchMemories(at: [index])
                            }
                        }
                }
                
                if memoryManager.isLoading {
                    LoadingView(message: "Lädt weitere Erinnerungen...")
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
        }
        .task {
            await memoryManager.loadMoreMemories()
        }
    }
}

// MARK: - Performance Monitoring Extension

extension View {
    func measurePerformance(_ label: String) -> some View {
        self.onAppear {
            let startTime = CFAbsoluteTimeGetCurrent()
            DispatchQueue.main.async {
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                #if DEBUG
                print("⏱️ \(label) appeared in \(String(format: "%.3f", timeElapsed))s")
                #endif
            }
        }
    }
}

// MARK: - Memory-Efficient Image Loading

struct OptimizedImageView: View {
    let imageData: Data?
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard let imageData = imageData else { return }
        
        // Decode image in background
        let decodedImage = await Task.detached(priority: .background) {
            UIImage(data: imageData)
        }.value
        
        // Downscale if needed
        if let decodedImage = decodedImage {
            self.image = await downscaleImage(decodedImage, maxSize: CGSize(width: 500, height: 500))
        }
    }
    
    private func downscaleImage(_ image: UIImage, maxSize: CGSize) async -> UIImage? {
        await Task.detached(priority: .background) {
            let renderer = UIGraphicsImageRenderer(size: maxSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: maxSize))
            }
        }.value
    }
}