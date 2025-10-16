//
//  HealthKitService.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import HealthKit
import Combine

/// Production-grade HealthKit integration service
final class HealthKitService: NSObject, HealthKitServiceProtocol {
    
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    private var isInitialized = false
    
    // Published properties for reactive UI
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var currentHeartRate: Double?
    
    private let heartRateSubject = PassthroughSubject<HeartRateReading, Never>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        isAvailable = HKHealthStore.isHealthDataAvailable()
        
        if isAvailable {
            isAuthorized = await checkAuthorizationStatus()
        }
        
        isInitialized = true
        AppLogger.shared.log("HealthKitService initialized - Available: \(isAvailable), Authorized: \(isAuthorized)", level: .info, category: "HealthKit")
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            AppLogger.shared.log("HealthKit not available on device", level: .warning, category: "HealthKit")
            return false
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            
            isAuthorized = await checkAuthorizationStatus()
            
            AppLogger.shared.log("HealthKit authorization requested - Granted: \(isAuthorized)", level: .info, category: "HealthKit")
            
            return isAuthorized
        } catch {
            AppLogger.shared.logError(error, context: "Failed to request HealthKit authorization", category: "HealthKit")
            return false
        }
    }
    
    private func checkAuthorizationStatus() async -> Bool {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            return false
        }
        
        let heartRateStatus = healthStore.authorizationStatus(for: heartRateType)
        let mindfulStatus = healthStore.authorizationStatus(for: mindfulType)
        
        return heartRateStatus == .sharingAuthorized && mindfulStatus == .sharingAuthorized
    }
    
    // MARK: - Meditation Session Management
    func saveMeditationSession(_ session: MeditationSession) async throws {
        guard isAvailable && isAuthorized else {
            throw ServiceError.healthKitUnavailable
        }
        
        guard session.isCompleted,
              let startTime = session.startTime,
              let endTime = session.endTime else {
            throw ServiceError.invalidData
        }
        
        let mindfulSession = HKCategorySample(
            type: HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startTime,
            end: endTime,
            metadata: [
                HKMetadataKeyActivityType: session.type.rawValue,
                "DailyRoutineApp.SessionID": session.id.uuidString,
                "DailyRoutineApp.PlannedDuration": session.duration,
                "DailyRoutineApp.ActualDuration": session.actualDuration ?? 0
            ]
        )
        
        try await healthStore.save(mindfulSession)
        
        AppLogger.shared.log("Saved meditation session to HealthKit: \(session.type.displayName)", level: .info, category: "HealthKit")
        
        // Also save heart rate data if available
        if let heartRateData = session.heartRateData, !heartRateData.isEmpty {
            try await saveHeartRateData(heartRateData)
        }
    }
    
    private func saveHeartRateData(_ heartRateData: [HeartRateReading]) async throws {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw ServiceError.healthKitUnavailable
        }
        
        let heartRateSamples = heartRateData.map { reading in
            HKQuantitySample(
                type: heartRateType,
                quantity: HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: reading.value),
                start: reading.timestamp,
                end: reading.timestamp,
                metadata: [
                    "DailyRoutineApp.Source": "MeditationSession"
                ]
            )
        }
        
        try await healthStore.save(heartRateSamples)
        
        AppLogger.shared.log("Saved \(heartRateSamples.count) heart rate readings to HealthKit", level: .debug, category: "HealthKit")
    }
    
    // MARK: - Heart Rate Data
    func fetchHeartRateData(for dateRange: DateInterval) async throws -> [HeartRateReading] {
        guard isAvailable && isAuthorized else {
            throw ServiceError.healthKitUnavailable
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw ServiceError.healthKitUnavailable
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.start,
            end: dateRange.end,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let heartRateReadings = samples?.compactMap { sample -> HeartRateReading? in
                    guard let quantitySample = sample as? HKQuantitySample else { return nil }
                    
                    let heartRateUnit = HKUnit(from: "count/min")
                    let value = quantitySample.quantity.doubleValue(for: heartRateUnit)
                    
                    return HeartRateReading(timestamp: sample.startDate, value: value)
                } ?? []
                
                continuation.resume(returning: heartRateReadings)
            }
            
            healthStore.execute(query)
        }
    }
    
    func startHeartRateCollection() async throws {
        guard isAvailable && isAuthorized else {
            throw ServiceError.healthKitUnavailable
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw ServiceError.healthKitUnavailable
        }
        
        // Stop any existing query
        await stopHeartRateCollection()
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, deletedObjects, anchor, error in
            guard let self = self else { return }
            
            if let error = error {
                AppLogger.shared.logError(error, context: "Heart rate collection error", category: "HealthKit")
                return
            }
            
            let heartRateReadings = samples?.compactMap { sample -> HeartRateReading? in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                
                let heartRateUnit = HKUnit(from: "count/min")
                let value = quantitySample.quantity.doubleValue(for: heartRateUnit)
                
                return HeartRateReading(timestamp: sample.startDate, value: value)
            } ?? []
            
            // Update current heart rate
            if let latestReading = heartRateReadings.last {
                DispatchQueue.main.async {
                    self.currentHeartRate = latestReading.value
                }
                
                self.heartRateSubject.send(latestReading)
            }
        }
        
        query.updateHandler = { [weak self] _, samples, deletedObjects, anchor, error in
            guard let self = self else { return }
            
            if let error = error {
                AppLogger.shared.logError(error, context: "Heart rate update error", category: "HealthKit")
                return
            }
            
            let heartRateReadings = samples?.compactMap { sample -> HeartRateReading? in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                
                let heartRateUnit = HKUnit(from: "count/min")
                let value = quantitySample.quantity.doubleValue(for: heartRateUnit)
                
                return HeartRateReading(timestamp: sample.startDate, value: value)
            } ?? []
            
            // Update current heart rate and notify subscribers
            for reading in heartRateReadings {
                DispatchQueue.main.async {
                    self.currentHeartRate = reading.value
                }
                
                self.heartRateSubject.send(reading)
            }
        }
        
        heartRateQuery = query
        healthStore.execute(query)
        
        AppLogger.shared.log("Started heart rate collection", level: .info, category: "HealthKit")
    }
    
    func stopHeartRateCollection() async {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
            
            AppLogger.shared.log("Stopped heart rate collection", level: .info, category: "HealthKit")
        }
    }
    
    // MARK: - Mindful Sessions
    func fetchMindfulSessions() async throws -> [HKCategorySample] {
        guard isAvailable && isAuthorized else {
            throw ServiceError.healthKitUnavailable
        }
        
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            throw ServiceError.healthKitUnavailable
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: 100,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let mindfulSessions = samples?.compactMap { $0 as? HKCategorySample } ?? []
                continuation.resume(returning: mindfulSessions)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Health Statistics
    func getHealthInsights(for dateRange: DateInterval) async throws -> HealthInsights {
        guard isAvailable && isAuthorized else {
            throw ServiceError.healthKitUnavailable
        }
        
        async let heartRateData = fetchHeartRateData(for: dateRange)
        async let mindfulSessions = fetchMindfulSessions()
        
        let (heartRates, sessions) = try await (heartRateData, mindfulSessions)
        
        let insights = HealthInsights(
            averageHeartRate: heartRates.isEmpty ? nil : heartRates.map { $0.value }.reduce(0, +) / Double(heartRates.count),
            heartRateVariability: calculateHeartRateVariability(from: heartRates),
            totalMindfulMinutes: sessions.reduce(0) { total, session in
                total + session.endDate.timeIntervalSince(session.startDate) / 60
            },
            mindfulSessionsCount: sessions.count,
            longestMindfulSession: sessions.map { $0.endDate.timeIntervalSince($0.startDate) }.max() ?? 0
        )
        
        return insights
    }
    
    private func calculateHeartRateVariability(from readings: [HeartRateReading]) -> Double? {
        guard readings.count > 1 else { return nil }
        
        let heartRates = readings.map { $0.value }
        let intervals = zip(heartRates, heartRates.dropFirst()).map { abs($1 - $0) }
        
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        
        return sqrt(variance)
    }
    
    // MARK: - Heart Rate Publisher
    var heartRatePublisher: AnyPublisher<HeartRateReading, Never> {
        heartRateSubject.eraseToAnyPublisher()
    }
    
    deinit {
        Task {
            await stopHeartRateCollection()
        }
    }
}

// MARK: - Supporting Types
struct HealthInsights: Codable {
    let averageHeartRate: Double?
    let heartRateVariability: Double?
    let totalMindfulMinutes: Double
    let mindfulSessionsCount: Int
    let longestMindfulSession: TimeInterval
    
    var formattedAverageHeartRate: String {
        guard let heartRate = averageHeartRate else { return "N/A" }
        return String(format: "%.0f BPM", heartRate)
    }
    
    var formattedHeartRateVariability: String {
        guard let hrv = heartRateVariability else { return "N/A" }
        return String(format: "%.1f BPM", hrv)
    }
    
    var formattedTotalMindfulMinutes: String {
        if totalMindfulMinutes >= 60 {
            let hours = Int(totalMindfulMinutes / 60)
            let minutes = Int(totalMindfulMinutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(minutes)m"
        } else {
            return String(format: "%.0f min", totalMindfulMinutes)
        }
    }
}