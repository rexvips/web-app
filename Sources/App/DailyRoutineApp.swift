//
//  DailyRoutineApp.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI
import UserNotifications
import HealthKit

@main
struct DailyRoutineApp: App {
    @StateObject private var appDependencies = AppDependencies()
    @StateObject private var appCoordinator = AppCoordinator()
    
    init() {
        configureApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDependencies)
                .environmentObject(appCoordinator)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func configureApp() {
        // Configure app appearance
        configureAppearance()
        
        // Configure logging
        configureLogging()
    }
    
    private func setupApp() {
        // Request permissions
        requestNotificationPermissions()
        requestHealthKitPermissions()
        
        // Initialize services
        appDependencies.initializeServices()
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func configureLogging() {
        // Configure Firebase Crashlytics if needed
        #if !DEBUG
        // FirebaseApp.configure()
        #endif
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                AppLogger.shared.log("Notification permission error: \(error)", level: .error)
            }
            AppLogger.shared.log("Notification permission granted: \(granted)", level: .info)
        }
    }
    
    private func requestHealthKitPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthStore = HKHealthStore()
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                AppLogger.shared.log("HealthKit permission error: \(error)", level: .error)
            }
            AppLogger.shared.log("HealthKit permission granted: \(success)", level: .info)
        }
    }
}