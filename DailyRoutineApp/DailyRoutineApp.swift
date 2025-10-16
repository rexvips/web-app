//
//  DailyRoutineApp.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI
import UserNotifications
import HealthKit
import Combine

@main
struct DailyRoutineApp: App {
    
    @StateObject private var dependencies = AppDependencies()
    @StateObject private var coordinator = AppCoordinator()
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
                .environmentObject(coordinator)
                .task {
                    await requestPermissions()
                }
        }
    }
    
    // MARK: - App Setup
    private func setupApp() {
        configureAnalytics()
        setupErrorHandling()
    }
    
    private func configureAnalytics() {
        #if DEBUG
        AppLogger.shared.log("App launched in DEBUG mode", category: .app)
        #else
        // Configure Firebase Analytics in production
        #endif
    }
    
    private func setupErrorHandling() {
        // Global error handling setup
        AppLogger.shared.log("Error handling configured", category: .app)
    }
    
    // MARK: - Permissions
    private func requestPermissions() async {
        await requestNotificationPermission()
        await requestHealthKitPermission()
    }
    
    private func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            AppLogger.shared.log(
                "Notification permission: \(granted ? "granted" : "denied")",
                category: .permissions
            )
        } catch {
            AppLogger.shared.log(
                "Failed to request notification permission: \(error)",
                category: .permissions,
                type: .error
            )
        }
    }
    
    private func requestHealthKitPermission() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLogger.shared.log("HealthKit not available", category: .permissions)
            return
        }
        
        let healthStore = HKHealthStore()
        let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        do {
            try await healthStore.requestAuthorization(
                toShare: [mindfulnessType],
                read: [mindfulnessType]
            )
            AppLogger.shared.log("HealthKit permission requested", category: .permissions)
        } catch {
            AppLogger.shared.log(
                "Failed to request HealthKit permission: \(error)",
                category: .permissions,
                type: .error
            )
        }
    }
}