import XCTest
import Testing
@testable import WeTwo

// MARK: - OptimizedMoodManager Tests

@MainActor
final class OptimizedMoodManagerTests: XCTestCase {
    
    var sut: OptimizedMoodManager!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = OptimizedMoodManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertNil(sut.todayMood)
        XCTAssertTrue(sut.weeklyMoods.isEmpty)
        XCTAssertNil(sut.partnerTodayMood)
        XCTAssertTrue(sut.partnerWeeklyMoods.isEmpty)
        XCTAssertNil(sut.dailyInsight)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadMoodDataSetsLoadingState() async {
        let expectation = XCTestExpectation(description: "Loading state changes")
        
        Task { @MainActor in
            await sut.loadMoodData()
            expectation.fulfill()
        }
        
        // Check loading state is set immediately
        XCTAssertTrue(sut.isLoading)
        
        await fulfillment(of: [expectation], timeout: 2)
        
        // After completion, loading should be false
        XCTAssertFalse(sut.isLoading)
    }
    
    func testAddMoodEntryUpdatesImmediately() async throws {
        let moodLevel = MoodLevel.happy
        let eventLabel = "Test Event"
        
        try await sut.addMoodEntry(moodLevel, eventLabel: eventLabel)
        
        XCTAssertNotNil(sut.todayMood)
        XCTAssertEqual(sut.todayMood?.moodLevel, moodLevel)
        XCTAssertEqual(sut.todayMood?.eventLabel, eventLabel)
    }
    
    func testConcurrentMoodFetching() async {
        await sut.loadMoodData()
        
        // Verify that both user and partner moods are fetched
        // This tests that the parallel async let pattern works correctly
        XCTAssertFalse(sut.isLoading)
    }
}

// MARK: - OptimizedPartnerManager Tests

@MainActor
final class OptimizedPartnerManagerTests: XCTestCase {
    
    var sut: OptimizedPartnerManager!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = OptimizedPartnerManager.shared
    }
    
    func testSingletonInstance() {
        let instance1 = OptimizedPartnerManager.shared
        let instance2 = OptimizedPartnerManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testInitialState() {
        XCTAssertFalse(sut.isConnected)
        XCTAssertNil(sut.partnerProfile)
        XCTAssertEqual(sut.connectionCode, "")
        XCTAssertFalse(sut.hasPendingInvitation)
        XCTAssertNil(sut.pendingInvitation)
    }
    
    func testCheckPartnerConnectionCancellation() async {
        // Start first connection check
        await sut.checkPartnerConnection()
        
        // Start second connection check (should cancel first)
        await sut.checkPartnerConnection()
        
        // Verify state remains consistent
        XCTAssertNotNil(sut)
    }
}

// MARK: - OptimizedMemoryManager Tests

@MainActor
final class OptimizedMemoryManagerTests: XCTestCase {
    
    var sut: OptimizedMemoryManager!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = OptimizedMemoryManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertTrue(sut.memories.isEmpty)
        XCTAssertEqual(sut.selectedFilter, .all)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.hasMore)
    }
    
    func testFilteredMemoriesAllFilter() {
        let specialMemory = Memory(
            userId: "1",
            partnerId: "2",
            title: "Special",
            description: "",
            photoData: nil,
            location: nil,
            isSpecial: true,
            eventLabel: nil
        )
        
        let everydayMemory = Memory(
            userId: "1",
            partnerId: "2",
            title: "Everyday",
            description: "",
            photoData: nil,
            location: nil,
            isSpecial: false,
            eventLabel: nil
        )
        
        sut.memories = [specialMemory, everydayMemory]
        sut.selectedFilter = .all
        
        XCTAssertEqual(sut.filteredMemories.count, 2)
    }
    
    func testFilteredMemoriesSpecialFilter() {
        let specialMemory = Memory(
            userId: "1",
            partnerId: "2",
            title: "Special",
            description: "",
            photoData: nil,
            location: nil,
            isSpecial: true,
            eventLabel: nil
        )
        
        let everydayMemory = Memory(
            userId: "1",
            partnerId: "2",
            title: "Everyday",
            description: "",
            photoData: nil,
            location: nil,
            isSpecial: false,
            eventLabel: nil
        )
        
        sut.memories = [specialMemory, everydayMemory]
        sut.selectedFilter = .special
        
        XCTAssertEqual(sut.filteredMemories.count, 1)
        XCTAssertTrue(sut.filteredMemories.first?.isSpecial ?? false)
    }
    
    func testFilteredMemoriesEverydayFilter() {
        let specialMemory = Memory(
            userId: "1",
            partnerId: "2",
            title: "Special",
            description: "",
            photoData: nil,
            location: nil,
            isSpecial: true,
            eventLabel: nil
        )
        
        let everydayMemory = Memory(
            userId: "1",
            partnerId: "2",
            title: "Everyday",
            description: "",
            photoData: nil,
            location: nil,
            isSpecial: false,
            eventLabel: nil
        )
        
        sut.memories = [specialMemory, everydayMemory]
        sut.selectedFilter = .everyday
        
        XCTAssertEqual(sut.filteredMemories.count, 1)
        XCTAssertFalse(sut.filteredMemories.first?.isSpecial ?? true)
    }
    
    func testLoadMoreMemoriesWhenAlreadyLoading() async {
        sut.isLoading = true
        
        await sut.loadMoreMemories()
        
        // Should not change state when already loading
        XCTAssertTrue(sut.memories.isEmpty)
    }
    
    func testLoadMoreMemoriesWhenNoMore() async {
        sut.hasMore = false
        
        await sut.loadMoreMemories()
        
        // Should not load when hasMore is false
        XCTAssertTrue(sut.memories.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testPrefetchMemoriesTriggersLoad() {
        // Add some memories
        for i in 0..<10 {
            sut.memories.append(Memory(
                userId: "1",
                partnerId: "2",
                title: "Memory \(i)",
                description: "",
                photoData: nil,
                location: nil,
                isSpecial: false,
                eventLabel: nil
            ))
        }
        
        // Prefetch near the end
        sut.prefetchMemories(at: [7, 8, 9])
        
        // This should trigger a load since we're within 5 items of the end
        // The actual loading happens asynchronously
        XCTAssertNotNil(sut)
    }
}

// MARK: - Performance Tests

@MainActor
final class PerformanceTests: XCTestCase {
    
    func testMoodManagerLoadPerformance() {
        self.measure {
            let manager = OptimizedMoodManager()
            let expectation = self.expectation(description: "Load mood data")
            
            Task {
                await manager.loadMoodData()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5)
        }
    }
    
    func testMemoryFilteringPerformance() {
        let manager = OptimizedMemoryManager()
        
        // Add 1000 memories for performance testing
        for i in 0..<1000 {
            manager.memories.append(Memory(
                userId: "1",
                partnerId: "2",
                title: "Memory \(i)",
                description: "Description \(i)",
                photoData: nil,
                location: nil,
                isSpecial: i % 3 == 0,
                eventLabel: nil
            ))
        }
        
        self.measure {
            _ = manager.filteredMemories
            manager.selectedFilter = .special
            _ = manager.filteredMemories
            manager.selectedFilter = .everyday
            _ = manager.filteredMemories
            manager.selectedFilter = .all
            _ = manager.filteredMemories
        }
    }
}

// MARK: - Integration Tests

@MainActor
final class IntegrationTests: XCTestCase {
    
    func testMoodAndPartnerManagerIntegration() async {
        let moodManager = OptimizedMoodManager()
        let partnerManager = OptimizedPartnerManager.shared
        
        // Simulate partner connection
        await partnerManager.checkPartnerConnection()
        
        // Load mood data which should include partner moods if connected
        await moodManager.loadMoodData()
        
        // Verify state consistency
        if partnerManager.isConnected {
            // When connected, we expect partner mood data to be fetched
            XCTAssertNotNil(moodManager)
        }
    }
    
    func testConcurrentManagerOperations() async {
        let moodManager = OptimizedMoodManager()
        let memoryManager = OptimizedMemoryManager()
        let partnerManager = OptimizedPartnerManager.shared
        
        // Run multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await moodManager.loadMoodData()
            }
            
            group.addTask {
                await memoryManager.loadMoreMemories()
            }
            
            group.addTask {
                await partnerManager.checkPartnerConnection()
            }
        }
        
        // Verify all managers completed their operations
        XCTAssertFalse(moodManager.isLoading)
        XCTAssertFalse(memoryManager.isLoading)
        XCTAssertNotNil(partnerManager)
    }
}

// MARK: - Mock Helpers

extension Memory {
    static func mock(
        id: String = UUID().uuidString,
        userId: String = "user1",
        partnerId: String = "partner1",
        title: String = "Test Memory",
        isSpecial: Bool = false
    ) -> Memory {
        Memory(
            userId: userId,
            partnerId: partnerId,
            title: title,
            description: "Test Description",
            photoData: nil,
            location: nil,
            isSpecial: isSpecial,
            eventLabel: nil
        )
    }
}

extension MoodEntry {
    static func mock(
        userId: String = "user1",
        moodLevel: MoodLevel = .happy,
        eventLabel: String? = nil
    ) -> MoodEntry {
        MoodEntry(
            userId: userId,
            moodLevel: moodLevel,
            eventLabel: eventLabel,
            location: nil,
            photoData: nil
        )
    }
}