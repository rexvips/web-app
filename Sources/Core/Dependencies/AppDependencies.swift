//
//  AppDependencies.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import Combine

/// Central dependency injection container following the Dependency Inversion Principle
final class AppDependencies: ObservableObject {
    
    // MARK: - Services
    lazy var notificationService: NotificationServiceProtocol = NotificationService()
    lazy var audioService: AudioServiceProtocol = AudioService()
    lazy var healthKitService: HealthKitServiceProtocol = HealthKitService()
    lazy var analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    lazy var exportService: ExportServiceProtocol = ExportService()
    
    // MARK: - Data Layer
    lazy var coreDataStack: CoreDataStackProtocol = CoreDataStack()
    lazy var cloudKitService: CloudKitServiceProtocol = CloudKitService()
    
    // MARK: - Repositories
    lazy var routineRepository: RoutineRepositoryProtocol = RoutineRepository(
        coreDataStack: coreDataStack,
        cloudKitService: cloudKitService
    )
    lazy var meditationRepository: MeditationRepositoryProtocol = MeditationRepository(
        coreDataStack: coreDataStack,
        cloudKitService: cloudKitService
    )
    lazy var habitRepository: HabitRepositoryProtocol = HabitRepository(
        coreDataStack: coreDataStack,
        cloudKitService: cloudKitService
    )
    
    // MARK: - Use Cases
    lazy var routineUseCases: RoutineUseCasesProtocol = RoutineUseCases(
        repository: routineRepository,
        notificationService: notificationService,
        analyticsService: analyticsService
    )
    lazy var meditationUseCases: MeditationUseCasesProtocol = MeditationUseCases(
        repository: meditationRepository,
        audioService: audioService,
        healthKitService: healthKitService,
        analyticsService: analyticsService
    )
    lazy var habitUseCases: HabitUseCasesProtocol = HabitUseCases(
        repository: habitRepository,
        notificationService: notificationService,
        analyticsService: analyticsService
    )
    
    // MARK: - Initialization
    func initializeServices() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.notificationService.initialize() }
                group.addTask { await self.audioService.initialize() }
                group.addTask { await self.healthKitService.initialize() }
                group.addTask { await self.coreDataStack.initialize() }
            }
        }
    }
    
    deinit {
        AppLogger.shared.log("AppDependencies deinitialized", level: .debug)
    }
}