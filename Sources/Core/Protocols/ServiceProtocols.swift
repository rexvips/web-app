//
//  ServiceProtocols.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import AVFoundation
import HealthKit
import UserNotifications
import Combine

// MARK: - Notification Service Protocol
protocol NotificationServiceProtocol: AnyObject {
    func initialize() async
    func requestPermission() async -> Bool
    func scheduleRoutineReminder(_ routine: Routine) async throws
    func scheduleHabitReminder(_ habit: Habit) async throws
    func scheduleMeditationReminder(at date: Date, type: MeditationType) async throws
    func cancelNotification(withIdentifier identifier: String) async
    func cancelAllNotifications() async
    func getPendingNotifications() async -> [UNNotificationRequest]
    func getDeliveredNotifications() async -> [UNNotification]
}

// MARK: - Audio Service Protocol
protocol AudioServiceProtocol: AnyObject {
    var isPlaying: Bool { get }
    var currentAmbientSound: AmbientSound? { get }
    
    func initialize() async
    func playAmbientSound(_ sound: AmbientSound, volume: Double) async throws
    func stopAmbientSound() async
    func playBreathingCue(_ cue: BreathingCueType, volume: Double) async throws
    func configureBellSound(interval: TimeInterval, duration: TimeInterval) async throws
    func startBellTimer() async
    func stopBellTimer() async
    func setVolume(_ volume: Double) async
    func setupBackgroundAudio() async throws
}

// MARK: - HealthKit Service Protocol
protocol HealthKitServiceProtocol: AnyObject {
    var isAvailable: Bool { get }
    var isAuthorized: Bool { get }
    
    func initialize() async
    func requestAuthorization() async -> Bool
    func saveMeditationSession(_ session: MeditationSession) async throws
    func fetchHeartRateData(for dateRange: DateInterval) async throws -> [HeartRateReading]
    func startHeartRateCollection() async throws
    func stopHeartRateCollection() async
    func fetchMindfulSessions() async throws -> [HKCategorySample]
}

// MARK: - Analytics Service Protocol
protocol AnalyticsServiceProtocol: AnyObject {
    func trackEvent(_ event: AnalyticsEvent) async
    func setUserProperty(_ value: String, forName name: String) async
    func trackRoutineCompletion(_ routine: Routine, duration: TimeInterval) async
    func trackMeditationSession(_ session: MeditationSession) async
    func trackHabitCompletion(_ habit: Habit) async
    func trackScreenView(_ screenName: String) async
    func trackError(_ error: Error, context: String) async
}

// MARK: - Export Service Protocol
protocol ExportServiceProtocol: AnyObject {
    func exportRoutines(format: ExportFormat) async throws -> URL
    func exportHabits(format: ExportFormat) async throws -> URL
    func exportMeditationSessions(format: ExportFormat) async throws -> URL
    func exportAllData(format: ExportFormat) async throws -> URL
    func importData(from url: URL) async throws
}

// MARK: - CloudKit Service Protocol
protocol CloudKitServiceProtocol: AnyObject {
    var isAvailable: Bool { get }
    var accountStatus: CKAccountStatus { get }
    
    func initialize() async
    func syncRoutines() async throws
    func syncHabits() async throws
    func syncMeditationSessions() async throws
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async
}

// MARK: - Core Data Stack Protocol
protocol CoreDataStackProtocol: AnyObject {
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
    
    func initialize() async
    func save() async throws
    func saveBackground() async throws
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T
}

// MARK: - Supporting Types

enum ExportFormat: String, CaseIterable {
    case json = "json"
    case csv = "csv"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV"
        case .pdf: return "PDF"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .pdf: return "application/pdf"
        }
    }
}

import CloudKit

enum CKAccountStatus {
    case couldNotDetermine
    case available
    case restricted
    case noAccount
    
    init(from ckStatus: CloudKit.CKAccountStatus) {
        switch ckStatus {
        case .couldNotDetermine: self = .couldNotDetermine
        case .available: self = .available
        case .restricted: self = .restricted
        case .noAccount: self = .noAccount
        @unknown default: self = .couldNotDetermine
        }
    }
}

// MARK: - Error Types
enum ServiceError: LocalizedError {
    case notInitialized
    case permissionDenied
    case networkUnavailable
    case dataCorrupted
    case exportFailed(String)
    case importFailed(String)
    case audioSessionFailed(String)
    case healthKitUnavailable
    case cloudKitUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Service not initialized"
        case .permissionDenied:
            return "Permission denied"
        case .networkUnavailable:
            return "Network unavailable"
        case .dataCorrupted:
            return "Data corrupted"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        case .audioSessionFailed(let reason):
            return "Audio session failed: \(reason)"
        case .healthKitUnavailable:
            return "HealthKit unavailable"
        case .cloudKitUnavailable:
            return "CloudKit unavailable"
        }
    }
}

// MARK: - Service State Publishers
protocol ServiceStatePublisher {
    var statePublisher: AnyPublisher<ServiceState, Never> { get }
}

enum ServiceState {
    case initializing
    case ready
    case error(Error)
    case unavailable
}

// MARK: - Background Task Management
protocol BackgroundTaskManager: AnyObject {
    func beginBackgroundTask(name: String) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

import UIKit

extension UIApplication: BackgroundTaskManager {
    func beginBackgroundTask(name: String) -> UIBackgroundTaskIdentifier {
        return beginBackgroundTask(withName: name) {
            // Handle expiration
        }
    }
    
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endBackgroundTask(identifier)
    }
}