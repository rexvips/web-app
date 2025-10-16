//
//  AnalyticsManager.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation

/// Analytics event types
enum AnalyticsEvent {
    case appLaunched
    case onboardingCompleted
    case tabSelected(String)
    case screenViewed(String)
    case routineCreated(String)
    case routineCompleted(String)
    case meditationStarted(String, duration: Int)
    case meditationCompleted(String, duration: Int)
    case habitMarkedComplete(String)
    case notificationReceived(String)
    case notificationTapped(String)
    case dataExported(String)
    case settingChanged(String, value: String)
    case errorOccurred(String, context: String)
    
    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .onboardingCompleted: return "onboarding_completed"
        case .tabSelected: return "tab_selected"
        case .screenViewed: return "screen_viewed"
        case .routineCreated: return "routine_created"
        case .routineCompleted: return "routine_completed"
        case .meditationStarted: return "meditation_started"
        case .meditationCompleted: return "meditation_completed"
        case .habitMarkedComplete: return "habit_marked_complete"
        case .notificationReceived: return "notification_received"
        case .notificationTapped: return "notification_tapped"
        case .dataExported: return "data_exported"
        case .settingChanged: return "setting_changed"
        case .errorOccurred: return "error_occurred"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .appLaunched:
            return [
                "timestamp": Date().timeIntervalSince1970,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
        case .onboardingCompleted:
            return ["timestamp": Date().timeIntervalSince1970]
        case .tabSelected(let tab):
            return ["tab_name": tab]
        case .screenViewed(let screen):
            return ["screen_name": screen]
        case .routineCreated(let routineType):
            return ["routine_type": routineType]
        case .routineCompleted(let routineId):
            return ["routine_id": routineId]
        case .meditationStarted(let type, let duration):
            return ["meditation_type": type, "planned_duration": duration]
        case .meditationCompleted(let type, let duration):
            return ["meditation_type": type, "actual_duration": duration]
        case .habitMarkedComplete(let habitId):
            return ["habit_id": habitId]
        case .notificationReceived(let type):
            return ["notification_type": type]
        case .notificationTapped(let type):
            return ["notification_type": type]
        case .dataExported(let format):
            return ["export_format": format]
        case .settingChanged(let setting, let value):
            return ["setting_name": setting, "new_value": value]
        case .errorOccurred(let error, let context):
            return ["error_message": error, "context": context]
        }
    }
}

/// Central analytics manager for tracking user behavior and app performance
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var isEnabled: Bool {
        // Check user preference for analytics
        UserDefaults.standard.bool(forKey: "analytics_enabled")
    }
    
    private init() {}
    
    /// Track an analytics event
    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        
        AppLogger.shared.log(
            "Analytics event: \(event.name)",
            level: .debug,
            category: "Analytics"
        )
        
        #if !DEBUG
        // Send to Firebase Analytics in production
        // Analytics.logEvent(event.name, parameters: event.parameters)
        #endif
        
        // Store locally for offline analytics
        storeEventLocally(event)
    }
    
    /// Set user property for analytics
    func setUserProperty(_ value: String, forName name: String) {
        guard isEnabled else { return }
        
        AppLogger.shared.log(
            "User property set: \(name) = \(value)",
            level: .debug,
            category: "Analytics"
        )
        
        #if !DEBUG
        // Analytics.setUserProperty(value, forName: name)
        #endif
    }
    
    /// Enable or disable analytics
    func setAnalyticsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
        
        #if !DEBUG
        // Analytics.setAnalyticsCollectionEnabled(enabled)
        #endif
        
        AppLogger.shared.log(
            "Analytics \(enabled ? "enabled" : "disabled")",
            level: .info,
            category: "Analytics"
        )
    }
    
    // MARK: - Private Methods
    private func storeEventLocally(_ event: AnalyticsEvent) {
        let eventData = [
            "name": event.name,
            "parameters": event.parameters,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        var storedEvents = UserDefaults.standard.array(forKey: "stored_analytics_events") as? [[String: Any]] ?? []
        storedEvents.append(eventData)
        
        // Keep only last 100 events to prevent storage bloat
        if storedEvents.count > 100 {
            storedEvents = Array(storedEvents.suffix(100))
        }
        
        UserDefaults.standard.set(storedEvents, forKey: "stored_analytics_events")
    }
    
    /// Flush stored events (called when network becomes available)
    func flushStoredEvents() {
        guard isEnabled else { return }
        
        let storedEvents = UserDefaults.standard.array(forKey: "stored_analytics_events") as? [[String: Any]] ?? []
        
        for eventData in storedEvents {
            // Send stored events to analytics service
            AppLogger.shared.log(
                "Flushing stored event: \(eventData["name"] ?? "unknown")",
                level: .debug,
                category: "Analytics"
            )
        }
        
        // Clear stored events after flushing
        UserDefaults.standard.removeObject(forKey: "stored_analytics_events")
    }
}