//
//  AnalyticsService.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation

/// Production-grade analytics service for tracking user behavior and app performance
final class AnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Properties
    private let analyticsManager = AnalyticsManager.shared
    private var isInitialized = false
    
    // MARK: - Initialization
    func initialize() async {
        guard !isInitialized else { return }
        
        isInitialized = true
        AppLogger.shared.log("AnalyticsService initialized", level: .info, category: "Analytics")
        
        // Track app launch
        await trackEvent(.appLaunched)
    }
    
    // MARK: - Event Tracking
    func trackEvent(_ event: AnalyticsEvent) async {
        analyticsManager.track(event)
        
        AppLogger.shared.log(
            "Analytics event tracked: \(event.name)",
            level: .debug,
            category: "Analytics"
        )
    }
    
    func setUserProperty(_ value: String, forName name: String) async {
        analyticsManager.setUserProperty(value, forName: name)
        
        AppLogger.shared.log(
            "User property set: \(name) = \(value)",
            level: .debug,
            category: "Analytics"
        )
    }
    
    // MARK: - Routine Analytics
    func trackRoutineCompletion(_ routine: Routine, duration: TimeInterval) async {
        await trackEvent(.routineCompleted(routine.id.uuidString))
        
        // Track additional metrics
        let parameters: [String: Any] = [
            "routine_id": routine.id.uuidString,
            "routine_name": routine.name,
            "routine_category": routine.category.rawValue,
            "planned_duration": routine.estimatedDuration,
            "actual_duration": duration,
            "efficiency": duration > 0 ? routine.estimatedDuration / duration : 0,
            "activity_count": routine.activities.count,
            "completion_rate": routine.completionPercentage
        ]
        
        AppLogger.shared.logUserAction("routine_completed", parameters: parameters, category: "Analytics")
    }
    
    // MARK: - Meditation Analytics
    func trackMeditationSession(_ session: MeditationSession) async {
        if session.isCompleted {
            await trackEvent(.meditationCompleted(
                session.type.rawValue,
                duration: Int(session.actualDuration ?? session.duration)
            ))
        } else {
            await trackEvent(.meditationStarted(
                session.type.rawValue,
                duration: Int(session.duration)
            ))
        }
        
        // Track detailed meditation metrics
        let parameters: [String: Any] = [
            "session_id": session.id.uuidString,
            "meditation_type": session.type.rawValue,
            "planned_duration": session.duration,
            "actual_duration": session.actualDuration ?? 0,
            "completion_percentage": session.completionPercentage,
            "has_heart_rate_data": session.heartRateData?.isEmpty == false,
            "ambient_sound": session.settings.soundSettings.ambientSound?.rawValue ?? "none",
            "breathing_pattern": getBreathingPatternName(session.settings.breathingPattern)
        ]
        
        AppLogger.shared.logUserAction("meditation_session", parameters: parameters, category: "Analytics")
    }
    
    // MARK: - Habit Analytics
    func trackHabitCompletion(_ habit: Habit) async {
        await trackEvent(.habitMarkedComplete(habit.id.uuidString))
        
        // Track habit metrics
        let parameters: [String: Any] = [
            "habit_id": habit.id.uuidString,
            "habit_name": habit.name,
            "habit_category": habit.category.rawValue,
            "current_streak": habit.streakCount,
            "longest_streak": habit.longestStreak,
            "completion_rate": habit.completionPercentage,
            "frequency": habit.targetFrequency.displayName
        ]
        
        AppLogger.shared.logUserAction("habit_completed", parameters: parameters, category: "Analytics")
    }
    
    // MARK: - Screen Tracking
    func trackScreenView(_ screenName: String) async {
        await trackEvent(.screenViewed(screenName))
        
        AppLogger.shared.log(
            "Screen viewed: \(screenName)",
            level: .debug,
            category: "Analytics"
        )
    }
    
    // MARK: - Error Tracking
    func trackError(_ error: Error, context: String) async {
        await trackEvent(.errorOccurred(error.localizedDescription, context: context))
        
        AppLogger.shared.logError(error, context: context, category: "Analytics")
    }
    
    // MARK: - Performance Analytics
    func trackPerformanceMetric(_ metric: PerformanceMetric) async {
        let parameters: [String: Any] = [
            "metric_name": metric.name,
            "value": metric.value,
            "unit": metric.unit,
            "context": metric.context
        ]
        
        AppLogger.shared.logUserAction("performance_metric", parameters: parameters, category: "Performance")
    }
    
    func trackAppPerformance() async {
        let metrics = await gatherPerformanceMetrics()
        
        for metric in metrics {
            await trackPerformanceMetric(metric)
        }
    }
    
    // MARK: - User Engagement Analytics
    func trackUserEngagement(_ engagement: UserEngagement) async {
        let parameters: [String: Any] = [
            "session_duration": engagement.sessionDuration,
            "screens_visited": engagement.screensVisited,
            "actions_performed": engagement.actionsPerformed,
            "routines_completed": engagement.routinesCompleted,
            "habits_completed": engagement.habitsCompleted,
            "meditation_minutes": engagement.meditationMinutes
        ]
        
        AppLogger.shared.logUserAction("user_engagement", parameters: parameters, category: "Engagement")
    }
    
    // MARK: - A/B Testing Support
    func trackExperiment(_ experiment: String, variant: String) async {
        await setUserProperty(variant, forName: "experiment_\(experiment)")
        
        let parameters: [String: Any] = [
            "experiment_name": experiment,
            "variant": variant
        ]
        
        AppLogger.shared.logUserAction("experiment_exposure", parameters: parameters, category: "Experiments")
    }
    
    // MARK: - Funnel Analytics
    func trackFunnelStep(_ funnel: String, step: String, additionalData: [String: Any] = [:]) async {
        var parameters = additionalData
        parameters["funnel_name"] = funnel
        parameters["step_name"] = step
        parameters["timestamp"] = Date().timeIntervalSince1970
        
        AppLogger.shared.logUserAction("funnel_step", parameters: parameters, category: "Funnels")
    }
    
    // MARK: - Private Methods
    private func getBreathingPatternName(_ pattern: BreathingPattern) -> String {
        switch pattern {
        case .boxBreathing:
            return "box_breathing"
        case .fourSevenEight:
            return "4_7_8_breathing"
        case .custom:
            return "custom_breathing"
        }
    }
    
    private func gatherPerformanceMetrics() async -> [PerformanceMetric] {
        var metrics: [PerformanceMetric] = []
        
        // App launch time
        if let launchTime = UserDefaults.standard.object(forKey: "app_launch_time") as? Date {
            let launchDuration = Date().timeIntervalSince(launchTime)
            metrics.append(PerformanceMetric(
                name: "app_launch_time",
                value: launchDuration,
                unit: "seconds",
                context: "app_startup"
            ))
        }
        
        // Memory usage
        let memoryUsage = getMemoryUsage()
        metrics.append(PerformanceMetric(
            name: "memory_usage",
            value: memoryUsage,
            unit: "MB",
            context: "runtime"
        ))
        
        // Core Data performance
        // This would require integration with Core Data stack
        
        return metrics
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0
        }
    }
}

// MARK: - Supporting Types
struct PerformanceMetric {
    let name: String
    let value: Double
    let unit: String
    let context: String
    
    init(name: String, value: Double, unit: String, context: String) {
        self.name = name
        self.value = value
        self.unit = unit
        self.context = context
    }
}

struct UserEngagement {
    let sessionDuration: TimeInterval
    let screensVisited: Int
    let actionsPerformed: Int
    let routinesCompleted: Int
    let habitsCompleted: Int
    let meditationMinutes: Double
    
    init(
        sessionDuration: TimeInterval = 0,
        screensVisited: Int = 0,
        actionsPerformed: Int = 0,
        routinesCompleted: Int = 0,
        habitsCompleted: Int = 0,
        meditationMinutes: Double = 0
    ) {
        self.sessionDuration = sessionDuration
        self.screensVisited = screensVisited
        self.actionsPerformed = actionsPerformed
        self.routinesCompleted = routinesCompleted
        self.habitsCompleted = habitsCompleted
        self.meditationMinutes = meditationMinutes
    }
}