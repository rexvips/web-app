//
//  RoutineUseCasesTests.swift
//  DailyRoutineAppTests
//
//  Created by GitHub Copilot on 16/10/2025.
//

import XCTest
import Combine
@testable import DailyRoutineApp

final class RoutineUseCasesTests: XCTestCase {
    
    var sut: RoutineUseCases!
    var mockRepository: MockRoutineRepository!
    var mockNotificationService: MockNotificationService!
    var mockAnalyticsService: MockAnalyticsService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        mockRepository = MockRoutineRepository()
        mockNotificationService = MockNotificationService()
        mockAnalyticsService = MockAnalyticsService()
        
        sut = RoutineUseCases(
            repository: mockRepository,
            notificationService: mockNotificationService,
            analyticsService: mockAnalyticsService
        )
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockRepository = nil
        mockNotificationService = nil
        mockAnalyticsService = nil
        cancellables = nil
    }
    
    // MARK: - Create Routine Tests
    func testCreateRoutine_Success() async throws {
        // Given
        let routine = Routine(name: "Morning Routine", description: "My daily morning routine")
        mockRepository.createResult = .success(routine)
        
        // When
        let result = try await sut.createRoutine(routine)
        
        // Then
        XCTAssertEqual(result.id, routine.id)
        XCTAssertEqual(result.name, "Morning Routine")
        XCTAssertTrue(mockRepository.createCalled)
        XCTAssertTrue(mockAnalyticsService.trackEventCalled)
    }
    
    func testCreateRoutine_Failure() async {
        // Given
        let routine = Routine(name: "", description: "")
        mockRepository.createResult = .failure(RepositoryError.validationError("Name is required"))
        
        // When/Then
        do {
            _ = try await sut.createRoutine(routine)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Get Active Routines Tests
    func testGetActiveRoutines_Success() async throws {
        // Given
        let routines = [
            Routine(name: "Routine 1", isActive: true),
            Routine(name: "Routine 2", isActive: true)
        ]
        mockRepository.fetchActiveRoutinesResult = .success(routines)
        
        // When
        let result = try await sut.getActiveRoutines()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.isActive })
        XCTAssertTrue(mockRepository.fetchActiveRoutinesCalled)
    }
    
    // MARK: - Complete Routine Tests
    func testCompleteRoutine_Success() async throws {
        // Given
        let routineId = UUID()
        let routine = Routine(id: routineId, name: "Test Routine")
        mockRepository.fetchByIdResult = .success(routine)
        mockRepository.updateResult = .success(routine)
        
        // When
        try await sut.completeRoutine(routineId, notes: "Completed successfully")
        
        // Then
        XCTAssertTrue(mockRepository.fetchByIdCalled)
        XCTAssertTrue(mockRepository.updateCalled)
        XCTAssertTrue(mockAnalyticsService.trackRoutineCompletionCalled)
    }
    
    // MARK: - Performance Tests
    func testCreateRoutinePerformance() {
        let routine = Routine(name: "Performance Test", description: "Testing performance")
        mockRepository.createResult = .success(routine)
        
        measure {
            Task {
                try? await sut.createRoutine(routine)
            }
        }
    }
}

// MARK: - Mock Objects
class MockRoutineRepository: RoutineRepositoryProtocol {
    
    // MARK: - Call Tracking
    var createCalled = false
    var fetchByIdCalled = false
    var fetchAllCalled = false
    var updateCalled = false
    var deleteCalled = false
    var fetchActiveRoutinesCalled = false
    
    // MARK: - Results
    var createResult: Result<Routine, Error> = .failure(RepositoryError.entityNotFound)
    var fetchByIdResult: Result<Routine?, Error> = .success(nil)
    var fetchAllResult: Result<[Routine], Error> = .success([])
    var updateResult: Result<Routine, Error> = .failure(RepositoryError.entityNotFound)
    var deleteResult: Result<Void, Error> = .success(())
    var fetchActiveRoutinesResult: Result<[Routine], Error> = .success([])
    
    // MARK: - Publishers
    var routinesPublisher: AnyPublisher<[Routine], Never> {
        Just([]).eraseToAnyPublisher()
    }
    
    var activeRoutinesPublisher: AnyPublisher<[Routine], Never> {
        Just([]).eraseToAnyPublisher()
    }
    
    // MARK: - BaseRepositoryProtocol Implementation
    func create(_ entity: Routine) async throws -> Routine {
        createCalled = true
        return try createResult.get()
    }
    
    func fetch(by id: UUID) async throws -> Routine? {
        fetchByIdCalled = true
        return try fetchByIdResult.get()
    }
    
    func fetchAll() async throws -> [Routine] {
        fetchAllCalled = true
        return try fetchAllResult.get()
    }
    
    func update(_ entity: Routine) async throws -> Routine {
        updateCalled = true
        return try updateResult.get()
    }
    
    func delete(by id: UUID) async throws {
        deleteCalled = true
        try deleteResult.get()
    }
    
    func delete(_ entity: Routine) async throws {
        deleteCalled = true
        try deleteResult.get()
    }
    
    func count() async throws -> Int {
        return try fetchAllResult.get().count
    }
    
    // MARK: - RoutineRepositoryProtocol Implementation
    func fetchActiveRoutines() async throws -> [Routine] {
        fetchActiveRoutinesCalled = true
        return try fetchActiveRoutinesResult.get()
    }
    
    func fetchRoutines(for category: RoutineCategory) async throws -> [Routine] {
        return try fetchAllResult.get().filter { $0.category == category }
    }
    
    func fetchRoutinesDueToday() async throws -> [Routine] {
        return try fetchAllResult.get().filter { $0.isDueToday }
    }
    
    func fetchRoutinesWithReminders() async throws -> [Routine] {
        return try fetchAllResult.get().filter { $0.reminderSettings.isEnabled }
    }
    
    func markRoutineCompleted(_ routineId: UUID, completion: CompletionRecord) async throws {
        // Mock implementation
    }
    
    func updateStreakCount(_ routineId: UUID, streakCount: Int) async throws {
        // Mock implementation
    }
    
    func searchRoutines(query: String) async throws -> [Routine] {
        return try fetchAllResult.get().filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    func fetchRecentlyCompleted(limit: Int) async throws -> [Routine] {
        return Array(try fetchAllResult.get().prefix(limit))
    }
}

class MockNotificationService: NotificationServiceProtocol {
    
    var scheduleRoutineReminderCalled = false
    var scheduleHabitReminderCalled = false
    var scheduleMeditationReminderCalled = false
    
    func initialize() async {}
    
    func requestPermission() async -> Bool { return true }
    
    func scheduleRoutineReminder(_ routine: Routine) async throws {
        scheduleRoutineReminderCalled = true
    }
    
    func scheduleHabitReminder(_ habit: Habit) async throws {
        scheduleHabitReminderCalled = true
    }
    
    func scheduleMeditationReminder(at date: Date, type: MeditationType) async throws {
        scheduleMeditationReminderCalled = true
    }
    
    func cancelNotification(withIdentifier identifier: String) async {}
    func cancelAllNotifications() async {}
    func getPendingNotifications() async -> [UNNotificationRequest] { [] }
    func getDeliveredNotifications() async -> [UNNotification] { [] }
}

class MockAnalyticsService: AnalyticsServiceProtocol {
    
    var trackEventCalled = false
    var trackRoutineCompletionCalled = false
    var trackMeditationSessionCalled = false
    var trackHabitCompletionCalled = false
    
    func trackEvent(_ event: AnalyticsEvent) async {
        trackEventCalled = true
    }
    
    func setUserProperty(_ value: String, forName name: String) async {}
    
    func trackRoutineCompletion(_ routine: Routine, duration: TimeInterval) async {
        trackRoutineCompletionCalled = true
    }
    
    func trackMeditationSession(_ session: MeditationSession) async {
        trackMeditationSessionCalled = true
    }
    
    func trackHabitCompletion(_ habit: Habit) async {
        trackHabitCompletionCalled = true
    }
    
    func trackScreenView(_ screenName: String) async {}
    func trackError(_ error: Error, context: String) async {}
}

// MARK: - Test Utilities
extension XCTestCase {
    func wait(for expectation: XCTestExpectation, timeout: TimeInterval = 1.0) {
        wait(for: [expectation], timeout: timeout)
    }
    
    func expectation(for publisher: AnyPublisher<Bool, Never>, description: String) -> XCTestExpectation {
        let expectation = expectation(description: description)
        
        publisher
            .sink { value in
                if value {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        return expectation
    }
}