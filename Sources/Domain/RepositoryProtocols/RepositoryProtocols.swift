//
//  RepositoryProtocols.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import Combine

// MARK: - Base Repository Protocol
protocol BaseRepositoryProtocol {
    associatedtype Entity: Identifiable
    
    func create(_ entity: Entity) async throws -> Entity
    func fetch(by id: Entity.ID) async throws -> Entity?
    func fetchAll() async throws -> [Entity]
    func update(_ entity: Entity) async throws -> Entity
    func delete(by id: Entity.ID) async throws
    func delete(_ entity: Entity) async throws
    func count() async throws -> Int
}

// MARK: - Routine Repository Protocol
protocol RoutineRepositoryProtocol: BaseRepositoryProtocol where Entity == Routine {
    func fetchActiveRoutines() async throws -> [Routine]
    func fetchRoutines(for category: RoutineCategory) async throws -> [Routine]
    func fetchRoutinesDueToday() async throws -> [Routine]
    func fetchRoutinesWithReminders() async throws -> [Routine]
    func markRoutineCompleted(_ routineId: UUID, completion: CompletionRecord) async throws
    func updateStreakCount(_ routineId: UUID, streakCount: Int) async throws
    func searchRoutines(query: String) async throws -> [Routine]
    func fetchRecentlyCompleted(limit: Int) async throws -> [Routine]
    
    // Publishers for reactive programming
    var routinesPublisher: AnyPublisher<[Routine], Never> { get }
    var activeRoutinesPublisher: AnyPublisher<[Routine], Never> { get }
}

// MARK: - Meditation Repository Protocol
protocol MeditationRepositoryProtocol: BaseRepositoryProtocol where Entity == MeditationSession {
    func fetchSessions(for type: MeditationType) async throws -> [MeditationSession]
    func fetchSessionsInDateRange(_ dateRange: DateInterval) async throws -> [MeditationSession]
    func fetchCompletedSessions() async throws -> [MeditationSession]
    func fetchRecentSessions(limit: Int) async throws -> [MeditationSession]
    func updateSessionProgress(_ sessionId: UUID, progress: Double) async throws
    func completeSession(_ sessionId: UUID, actualDuration: TimeInterval, heartRateData: [HeartRateReading]?) async throws
    func fetchSessionStatistics() async throws -> MeditationStatistics
    func fetchSessionsByDuration(minDuration: TimeInterval, maxDuration: TimeInterval) async throws -> [MeditationSession]
    
    // Publishers for reactive programming
    var sessionsPublisher: AnyPublisher<[MeditationSession], Never> { get }
    var activeSessionPublisher: AnyPublisher<MeditationSession?, Never> { get }
}

// MARK: - Habit Repository Protocol
protocol HabitRepositoryProtocol: BaseRepositoryProtocol where Entity == Habit {
    func fetchActiveHabits() async throws -> [Habit]
    func fetchHabits(for category: HabitCategory) async throws -> [Habit]
    func fetchHabitsDueToday() async throws -> [Habit]
    func fetchHabitsWithReminders() async throws -> [Habit]
    func markHabitCompleted(_ habitId: UUID, completion: HabitCompletion) async throws
    func updateStreakCount(_ habitId: UUID, streakCount: Int) async throws
    func fetchHabitStatistics(_ habitId: UUID) async throws -> HabitStatistics
    func fetchHabitsCompletionHistory(from startDate: Date, to endDate: Date) async throws -> [Habit]
    func searchHabits(query: String) async throws -> [Habit]
    
    // Publishers for reactive programming
    var habitsPublisher: AnyPublisher<[Habit], Never> { get }
    var activeHabitsPublisher: AnyPublisher<[Habit], Never> { get }
}

// MARK: - Statistics Models
struct MeditationStatistics: Codable {
    let totalSessions: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let longestSession: TimeInterval
    let currentStreak: Int
    let longestStreak: Int
    let sessionsThisWeek: Int
    let sessionsThisMonth: Int
    let favoriteType: MeditationType?
    let averageHeartRate: Double?
    
    init(
        totalSessions: Int = 0,
        totalDuration: TimeInterval = 0,
        averageDuration: TimeInterval = 0,
        longestSession: TimeInterval = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        sessionsThisWeek: Int = 0,
        sessionsThisMonth: Int = 0,
        favoriteType: MeditationType? = nil,
        averageHeartRate: Double? = nil
    ) {
        self.totalSessions = totalSessions
        self.totalDuration = totalDuration
        self.averageDuration = averageDuration
        self.longestSession = longestSession
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.sessionsThisWeek = sessionsThisWeek
        self.sessionsThisMonth = sessionsThisMonth
        self.favoriteType = favoriteType
        self.averageHeartRate = averageHeartRate
    }
}

struct HabitStatistics: Codable {
    let habitId: UUID
    let totalCompletions: Int
    let currentStreak: Int
    let longestStreak: Int
    let completionRate: Double
    let averageMood: Double?
    let averageEffort: Double?
    let completionsThisWeek: Int
    let completionsThisMonth: Int
    let firstCompletionDate: Date?
    let lastCompletionDate: Date?
    
    init(
        habitId: UUID,
        totalCompletions: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        completionRate: Double = 0,
        averageMood: Double? = nil,
        averageEffort: Double? = nil,
        completionsThisWeek: Int = 0,
        completionsThisMonth: Int = 0,
        firstCompletionDate: Date? = nil,
        lastCompletionDate: Date? = nil
    ) {
        self.habitId = habitId
        self.totalCompletions = totalCompletions
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.completionRate = completionRate
        self.averageMood = averageMood
        self.averageEffort = averageEffort
        self.completionsThisWeek = completionsThisWeek
        self.completionsThisMonth = completionsThisMonth
        self.firstCompletionDate = firstCompletionDate
        self.lastCompletionDate = lastCompletionDate
    }
}

// MARK: - Repository Errors
enum RepositoryError: LocalizedError {
    case entityNotFound
    case invalidData
    case persistenceError(String)
    case syncError(String)
    case validationError(String)
    case concurrencyError
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound:
            return "Entity not found"
        case .invalidData:
            return "Invalid data provided"
        case .persistenceError(let message):
            return "Persistence error: \(message)"
        case .syncError(let message):
            return "Sync error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .concurrencyError:
            return "Concurrency error occurred"
        }
    }
}

// MARK: - Query Parameters
struct QueryParameters {
    let limit: Int?
    let offset: Int?
    let sortBy: String?
    let sortOrder: SortOrder
    let filters: [String: Any]
    
    init(
        limit: Int? = nil,
        offset: Int? = nil,
        sortBy: String? = nil,
        sortOrder: SortOrder = .ascending,
        filters: [String: Any] = [:]
    ) {
        self.limit = limit
        self.offset = offset
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.filters = filters
    }
}

enum SortOrder {
    case ascending
    case descending
}

// MARK: - Synchronization Protocol
protocol SynchronizableRepository {
    func syncWithRemote() async throws
    func handleSyncConflict<T>(_ localEntity: T, remoteEntity: T) async throws -> T where T: Identifiable
    var lastSyncTimestamp: Date? { get }
    var hasPendingChanges: Bool { get }
}

// MARK: - Cacheable Repository Protocol
protocol CacheableRepository {
    func clearCache() async
    func refreshCache() async throws
    var cacheExpirationDate: Date? { get }
    var isCacheValid: Bool { get }
}

// MARK: - Transactional Repository Protocol
protocol TransactionalRepository {
    func performTransaction<T>(_ operation: () async throws -> T) async throws -> T
    func rollback() async throws
    func commit() async throws
}

// MARK: - Observable Repository Protocol
protocol ObservableRepository {
    associatedtype Entity: Identifiable
    
    func observe(_ entityId: Entity.ID) -> AnyPublisher<Entity?, Never>
    func observeAll() -> AnyPublisher<[Entity], Never>
    func observeChanges() -> AnyPublisher<RepositoryChange<Entity>, Never>
}

enum RepositoryChange<Entity: Identifiable> {
    case inserted(Entity)
    case updated(Entity)
    case deleted(Entity.ID)
    case moved(from: Int, to: Int)
}

// MARK: - Batch Operations Protocol
protocol BatchOperationsRepository {
    associatedtype Entity: Identifiable
    
    func batchCreate(_ entities: [Entity]) async throws -> [Entity]
    func batchUpdate(_ entities: [Entity]) async throws -> [Entity]
    func batchDelete(_ entityIds: [Entity.ID]) async throws
    func batchProcess<T>(_ entities: [Entity], operation: (Entity) async throws -> T) async throws -> [T]
}