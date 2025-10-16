//
//  UseCaseProtocols.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import Combine

// MARK: - Base Use Case Protocol
protocol BaseUseCaseProtocol {
    associatedtype Request
    associatedtype Response
    
    func execute(_ request: Request) async throws -> Response
}

// MARK: - Routine Use Cases Protocol
protocol RoutineUseCasesProtocol: AnyObject {
    // CRUD Operations
    func createRoutine(_ routine: Routine) async throws -> Routine
    func getRoutine(by id: UUID) async throws -> Routine?
    func getAllRoutines() async throws -> [Routine]
    func updateRoutine(_ routine: Routine) async throws -> Routine
    func deleteRoutine(by id: UUID) async throws
    
    // Business Logic
    func getActiveRoutines() async throws -> [Routine]
    func getTodaysRoutines() async throws -> [Routine]
    func completeRoutine(_ routineId: UUID, notes: String?) async throws
    func skipRoutine(_ routineId: UUID, reason: String?) async throws
    func scheduleRoutineReminders(_ routine: Routine) async throws
    func updateRoutineStreak(_ routineId: UUID) async throws
    func getRoutineAnalytics(_ routineId: UUID, period: AnalyticsPeriod) async throws -> RoutineAnalytics
    func searchRoutines(query: String) async throws -> [Routine]
    func duplicateRoutine(_ routineId: UUID, newName: String) async throws -> Routine
    func reorderActivities(in routineId: UUID, from: Int, to: Int) async throws
    
    // Publishers
    var activeRoutinesPublisher: AnyPublisher<[Routine], Never> { get }
    var todaysRoutinesPublisher: AnyPublisher<[Routine], Never> { get }
}

// MARK: - Meditation Use Cases Protocol
protocol MeditationUseCasesProtocol: AnyObject {
    // Session Management
    func startMeditationSession(type: MeditationType, duration: TimeInterval, settings: MeditationSettings) async throws -> MeditationSession
    func pauseMeditationSession(_ sessionId: UUID) async throws
    func resumeMeditationSession(_ sessionId: UUID) async throws
    func completeMeditationSession(_ sessionId: UUID, actualDuration: TimeInterval) async throws
    func cancelMeditationSession(_ sessionId: UUID) async throws
    
    // Data Operations
    func getMeditationSession(by id: UUID) async throws -> MeditationSession?
    func getAllMeditationSessions() async throws -> [MeditationSession]
    func getMeditationHistory(period: AnalyticsPeriod) async throws -> [MeditationSession]
    func getMeditationStatistics() async throws -> MeditationStatistics
    func getMeditationStreak() async throws -> Int
    
    // Audio & Settings
    func updateMeditationSettings(_ settings: MeditationSettings) async throws
    func getMeditationSettings() async throws -> MeditationSettings
    func getAvailableAmbientSounds() async throws -> [AmbientSound]
    func preloadAudioAssets() async throws
    
    // HealthKit Integration
    func saveToHealthKit(_ session: MeditationSession) async throws
    func getHeartRateData(for session: MeditationSession) async throws -> [HeartRateReading]
    
    // Publishers
    var activeSessionPublisher: AnyPublisher<MeditationSession?, Never> { get }
    var statisticsPublisher: AnyPublisher<MeditationStatistics, Never> { get }
}

// MARK: - Habit Use Cases Protocol
protocol HabitUseCasesProtocol: AnyObject {
    // CRUD Operations
    func createHabit(_ habit: Habit) async throws -> Habit
    func getHabit(by id: UUID) async throws -> Habit?
    func getAllHabits() async throws -> [Habit]
    func updateHabit(_ habit: Habit) async throws -> Habit
    func deleteHabit(by id: UUID) async throws
    
    // Business Logic
    func getActiveHabits() async throws -> [Habit]
    func getTodaysHabits() async throws -> [Habit]
    func completeHabit(_ habitId: UUID, mood: MoodRating?, effort: EffortRating?, notes: String?) async throws
    func skipHabit(_ habitId: UUID, reason: String?) async throws
    func updateHabitStreak(_ habitId: UUID) async throws
    func getHabitStatistics(_ habitId: UUID) async throws -> HabitStatistics
    func getHabitAnalytics(_ habitId: UUID, period: AnalyticsPeriod) async throws -> HabitAnalytics
    func scheduleHabitReminders(_ habit: Habit) async throws
    func searchHabits(query: String) async throws -> [Habit]
    
    // Bulk Operations
    func completeMultipleHabits(_ habitIds: [UUID]) async throws
    func getHabitsCompletionSummary(for date: Date) async throws -> HabitCompletionSummary
    
    // Publishers
    var activeHabitsPublisher: AnyPublisher<[Habit], Never> { get }
    var todaysHabitsPublisher: AnyPublisher<[Habit], Never> { get }
    var completionSummaryPublisher: AnyPublisher<HabitCompletionSummary, Never> { get }
}

// MARK: - Analytics Models
struct RoutineAnalytics: Codable {
    let routineId: UUID
    let period: AnalyticsPeriod
    let totalCompletions: Int
    let completionRate: Double
    let averageDuration: TimeInterval
    let longestStreak: Int
    let currentStreak: Int
    let completionsByDay: [Date: Bool]
    let categoryPerformance: [RoutineCategory: Double]
    let timePatterns: TimePatterns
    
    init(
        routineId: UUID,
        period: AnalyticsPeriod,
        totalCompletions: Int = 0,
        completionRate: Double = 0,
        averageDuration: TimeInterval = 0,
        longestStreak: Int = 0,
        currentStreak: Int = 0,
        completionsByDay: [Date: Bool] = [:],
        categoryPerformance: [RoutineCategory: Double] = [:],
        timePatterns: TimePatterns = TimePatterns()
    ) {
        self.routineId = routineId
        self.period = period
        self.totalCompletions = totalCompletions
        self.completionRate = completionRate
        self.averageDuration = averageDuration
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
        self.completionsByDay = completionsByDay
        self.categoryPerformance = categoryPerformance
        self.timePatterns = timePatterns
    }
}

struct HabitAnalytics: Codable {
    let habitId: UUID
    let period: AnalyticsPeriod
    let totalCompletions: Int
    let completionRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let completionsByDay: [Date: Bool]
    let moodTrends: [Date: MoodRating]
    let effortTrends: [Date: EffortRating]
    let bestPerformanceDays: [Weekday]
    let timePatterns: TimePatterns
    
    init(
        habitId: UUID,
        period: AnalyticsPeriod,
        totalCompletions: Int = 0,
        completionRate: Double = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        completionsByDay: [Date: Bool] = [:],
        moodTrends: [Date: MoodRating] = [:],
        effortTrends: [Date: EffortRating] = [:],
        bestPerformanceDays: [Weekday] = [],
        timePatterns: TimePatterns = TimePatterns()
    ) {
        self.habitId = habitId
        self.period = period
        self.totalCompletions = totalCompletions
        self.completionRate = completionRate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.completionsByDay = completionsByDay
        self.moodTrends = moodTrends
        self.effortTrends = effortTrends
        self.bestPerformanceDays = bestPerformanceDays
        self.timePatterns = timePatterns
    }
}

struct HabitCompletionSummary: Codable {
    let date: Date
    let totalHabits: Int
    let completedHabits: Int
    let completionRate: Double
    let streakCount: Int
    let categoryBreakdown: [HabitCategory: Int]
    let moodAverage: Double?
    let effortAverage: Double?
    
    init(
        date: Date,
        totalHabits: Int = 0,
        completedHabits: Int = 0,
        completionRate: Double = 0,
        streakCount: Int = 0,
        categoryBreakdown: [HabitCategory: Int] = [:],
        moodAverage: Double? = nil,
        effortAverage: Double? = nil
    ) {
        self.date = date
        self.totalHabits = totalHabits
        self.completedHabits = completedHabits
        self.completionRate = completionRate
        self.streakCount = streakCount
        self.categoryBreakdown = categoryBreakdown
        self.moodAverage = moodAverage
        self.effortAverage = effortAverage
    }
}

struct TimePatterns: Codable {
    let preferredTimeOfDay: TimeOfDay?
    let averageStartTime: Date?
    let consistencyScore: Double
    let weekdayPerformance: [Weekday: Double]
    
    init(
        preferredTimeOfDay: TimeOfDay? = nil,
        averageStartTime: Date? = nil,
        consistencyScore: Double = 0,
        weekdayPerformance: [Weekday: Double] = [:]
    ) {
        self.preferredTimeOfDay = preferredTimeOfDay
        self.averageStartTime = averageStartTime
        self.consistencyScore = consistencyScore
        self.weekdayPerformance = weekdayPerformance
    }
}

enum TimeOfDay: String, CaseIterable, Codable {
    case earlyMorning = "earlyMorning"  // 5-8 AM
    case morning = "morning"            // 8-12 PM
    case afternoon = "afternoon"        // 12-5 PM
    case evening = "evening"           // 5-8 PM
    case night = "night"               // 8-11 PM
    case lateNight = "lateNight"       // 11 PM - 5 AM
    
    var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning"
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        case .lateNight: return "Late Night"
        }
    }
    
    var timeRange: String {
        switch self {
        case .earlyMorning: return "5:00 - 8:00 AM"
        case .morning: return "8:00 AM - 12:00 PM"
        case .afternoon: return "12:00 - 5:00 PM"
        case .evening: return "5:00 - 8:00 PM"
        case .night: return "8:00 - 11:00 PM"
        case .lateNight: return "11:00 PM - 5:00 AM"
        }
    }
}

enum AnalyticsPeriod: String, CaseIterable, Codable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "This Quarter"
        case .year: return "This Year"
        case .all: return "All Time"
        }
    }
    
    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return DateInterval(start: startOfWeek, end: now)
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return DateInterval(start: startOfMonth, end: now)
        case .quarter:
            let startOfQuarter = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            return DateInterval(start: startOfQuarter, end: now)
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return DateInterval(start: startOfYear, end: now)
        case .all:
            return DateInterval(start: Date.distantPast, end: now)
        }
    }
}

// MARK: - Use Case Errors
enum UseCaseError: LocalizedError {
    case invalidInput(String)
    case businessRuleViolation(String)
    case resourceNotFound(String)
    case unauthorized
    case serviceUnavailable(String)
    case concurrentModification
    case quotaExceeded(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .businessRuleViolation(let message):
            return "Business rule violation: \(message)"
        case .resourceNotFound(let message):
            return "Resource not found: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        case .concurrentModification:
            return "Concurrent modification detected"
        case .quotaExceeded(let message):
            return "Quota exceeded: \(message)"
        }
    }
}

// MARK: - Command Pattern for Use Cases
protocol Command {
    associatedtype Result
    func execute() async throws -> Result
}

protocol UndoableCommand: Command {
    func undo() async throws
}

// MARK: - Use Case Middleware
protocol UseCaseMiddleware {
    func process<T>(_ request: T, next: @escaping (T) async throws -> Any) async throws -> Any
}

// Example middleware implementations
struct LoggingMiddleware: UseCaseMiddleware {
    func process<T>(_ request: T, next: @escaping (T) async throws -> Any) async throws -> Any {
        AppLogger.shared.log("Executing use case with request: \(request)", level: .debug, category: "UseCase")
        let startTime = Date()
        
        do {
            let result = try await next(request)
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.shared.logPerformance("Use case execution", duration: duration, category: "UseCase")
            return result
        } catch {
            AppLogger.shared.logError(error, context: "Use case execution failed", category: "UseCase")
            throw error
        }
    }
}

struct ValidationMiddleware: UseCaseMiddleware {
    func process<T>(_ request: T, next: @escaping (T) async throws -> Any) async throws -> Any {
        // Perform validation logic here
        if let validatable = request as? Validatable {
            try validatable.validate()
        }
        return try await next(request)
    }
}

protocol Validatable {
    func validate() throws
}