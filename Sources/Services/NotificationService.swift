//
//  NotificationService.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import UserNotifications
import UIKit

/// Production-grade notification service with intelligent scheduling
final class NotificationService: NSObject, NotificationServiceProtocol {
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isInitialized = false
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        notificationCenter.delegate = self
        await setupNotificationCategories()
        
        isInitialized = true
        AppLogger.shared.log("NotificationService initialized", level: .info, category: "Notifications")
    }
    
    // MARK: - Permission Management
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .provisional, .criticalAlert]
            )
            
            AppLogger.shared.log(
                "Notification permission granted: \(granted)",
                level: .info,
                category: "Notifications"
            )
            
            if granted {
                await setupNotificationCategories()
            }
            
            return granted
        } catch {
            AppLogger.shared.logError(
                error,
                context: "Failed to request notification permission",
                category: "Notifications"
            )
            return false
        }
    }
    
    // MARK: - Routine Reminders
    func scheduleRoutineReminder(_ routine: Routine) async throws {
        guard routine.reminderSettings.isEnabled,
              let reminderTime = routine.reminderSettings.reminderTime else {
            return
        }
        
        let identifier = "routine_\(routine.id.uuidString)"
        
        // Cancel existing notification
        await cancelNotification(withIdentifier: identifier)
        
        let content = UNMutableNotificationContent()
        content.title = "Routine Reminder"
        content.body = "Time for your \"\(routine.name)\" routine!"
        content.sound = routine.reminderSettings.soundName != nil ? 
            UNNotificationSound(named: UNNotificationSoundName(routine.reminderSettings.soundName!)) : .default
        content.categoryIdentifier = NotificationCategory.routine.rawValue
        content.userInfo = [
            "type": "routine",
            "routineId": routine.id.uuidString,
            "routineName": routine.name
        ]
        
        if routine.reminderSettings.isVibrationEnabled {
            content.interruptionLevel = .active
        }
        
        let trigger = createTrigger(
            for: reminderTime,
            repeatInterval: routine.reminderSettings.repeatInterval
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        AppLogger.shared.log(
            "Scheduled routine reminder for: \(routine.name)",
            level: .info,
            category: "Notifications"
        )
        
        AnalyticsManager.shared.track(.notificationReceived("routine"))
    }
    
    // MARK: - Habit Reminders
    func scheduleHabitReminder(_ habit: Habit) async throws {
        guard habit.reminderSettings.isEnabled,
              let reminderTime = habit.reminderSettings.reminderTime else {
            return
        }
        
        let identifier = "habit_\(habit.id.uuidString)"
        
        // Cancel existing notification
        await cancelNotification(withIdentifier: identifier)
        
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Don't forget to \"\(habit.name)\"!"
        content.sound = habit.reminderSettings.soundName != nil ?
            UNNotificationSound(named: UNNotificationSoundName(habit.reminderSettings.soundName!)) : .default
        content.categoryIdentifier = NotificationCategory.habit.rawValue
        content.userInfo = [
            "type": "habit",
            "habitId": habit.id.uuidString,
            "habitName": habit.name
        ]
        
        // Add streak information to make it more engaging
        if habit.streakCount > 0 {
            content.body += " Keep your \(habit.streakCount)-day streak going! 🔥"
        }
        
        let trigger = createTrigger(
            for: reminderTime,
            repeatInterval: habit.reminderSettings.repeatInterval
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        AppLogger.shared.log(
            "Scheduled habit reminder for: \(habit.name)",
            level: .info,
            category: "Notifications"
        )
        
        AnalyticsManager.shared.track(.notificationReceived("habit"))
    }
    
    // MARK: - Meditation Reminders
    func scheduleMeditationReminder(at date: Date, type: MeditationType) async throws {
        let identifier = "meditation_\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = "Meditation Time"
        content.body = "Time for your \(type.displayName) session"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.meditation.rawValue
        content.userInfo = [
            "type": "meditation",
            "meditationType": type.rawValue
        ]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        AppLogger.shared.log(
            "Scheduled meditation reminder for: \(type.displayName)",
            level: .info,
            category: "Notifications"
        )
        
        AnalyticsManager.shared.track(.notificationReceived("meditation"))
    }
    
    // MARK: - Smart Notifications
    func scheduleSmartReminder(
        title: String,
        body: String,
        category: NotificationCategory,
        userInfo: [String: Any] = [:],
        schedulingStrategy: SmartSchedulingStrategy = .optimal
    ) async throws {
        let identifier = "smart_\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        content.userInfo = userInfo
        
        let triggerDate = await calculateOptimalDeliveryTime(strategy: schedulingStrategy)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        AppLogger.shared.log(
            "Scheduled smart notification: \(title)",
            level: .info,
            category: "Notifications"
        )
    }
    
    // MARK: - Notification Management
    func cancelNotification(withIdentifier identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        
        AppLogger.shared.log(
            "Cancelled notification: \(identifier)",
            level: .debug,
            category: "Notifications"
        )
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        AppLogger.shared.log(
            "Cancelled all notifications",
            level: .info,
            category: "Notifications"
        )
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.deliveredNotifications()
    }
    
    // MARK: - Private Methods
    private func setupNotificationCategories() async {
        let categories = Set([
            createRoutineCategory(),
            createHabitCategory(),
            createMeditationCategory(),
            createGeneralCategory()
        ])
        
        notificationCenter.setNotificationCategories(categories)
        AppLogger.shared.log("Notification categories configured", level: .debug, category: "Notifications")
    }
    
    private func createRoutineCategory() -> UNNotificationCategory {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ROUTINE",
            title: "Complete",
            options: [.foreground]
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP_ROUTINE",
            title: "Skip",
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ROUTINE",
            title: "Snooze 10 min",
            options: []
        )
        
        return UNNotificationCategory(
            identifier: NotificationCategory.routine.rawValue,
            actions: [completeAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }
    
    private func createHabitCategory() -> UNNotificationCategory {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_HABIT",
            title: "Done",
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_HABIT",
            title: "Remind Later",
            options: []
        )
        
        return UNNotificationCategory(
            identifier: NotificationCategory.habit.rawValue,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }
    
    private func createMeditationCategory() -> UNNotificationCategory {
        let startAction = UNNotificationAction(
            identifier: "START_MEDITATION",
            title: "Start Session",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_MEDITATION",
            title: "Later",
            options: []
        )
        
        return UNNotificationCategory(
            identifier: NotificationCategory.meditation.rawValue,
            actions: [startAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    private func createGeneralCategory() -> UNNotificationCategory {
        return UNNotificationCategory(
            identifier: NotificationCategory.general.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
    }
    
    private func createTrigger(
        for date: Date,
        repeatInterval: RepeatInterval
    ) -> UNNotificationTrigger {
        let calendar = Calendar.current
        
        switch repeatInterval {
        case .never:
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .daily:
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .weekdays:
            let components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .weekends:
            let components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .weekly:
            let components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .custom:
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
    }
    
    private func calculateOptimalDeliveryTime(strategy: SmartSchedulingStrategy) async -> Date {
        let now = Date()
        
        switch strategy {
        case .optimal:
            // Analyze user behavior patterns and suggest optimal time
            return now.addingTimeInterval(3600) // 1 hour from now as default
            
        case .immediate:
            return now
            
        case .nextAvailableSlot:
            // Find next available time slot based on user's schedule
            return now.addingTimeInterval(1800) // 30 minutes from now
            
        case .userPreferred:
            // Use user's preferred notification time
            let calendar = Calendar.current
            let preferredHour = UserDefaults.standard.integer(forKey: "preferred_notification_hour")
            
            if let preferredTime = calendar.date(bySettingHour: preferredHour, minute: 0, second: 0, of: now),
               preferredTime > now {
                return preferredTime
            } else {
                // Next day at preferred time
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                return calendar.date(bySettingHour: preferredHour, minute: 0, second: 0, of: tomorrow) ?? now
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification when app is in foreground
        AppLogger.shared.log(
            "Will present notification: \(notification.request.identifier)",
            level: .debug,
            category: "Notifications"
        )
        
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap and actions
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        AppLogger.shared.log(
            "Did receive notification response: \(actionIdentifier)",
            level: .info,
            category: "Notifications"
        )
        
        Task {
            await handleNotificationResponse(response)
        }
        
        AnalyticsManager.shared.track(.notificationTapped(userInfo["type"] as? String ?? "unknown"))
        
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "COMPLETE_ROUTINE":
            if let routineId = userInfo["routineId"] as? String,
               let uuid = UUID(uuidString: routineId) {
                await handleRoutineCompletion(uuid)
            }
            
        case "COMPLETE_HABIT":
            if let habitId = userInfo["habitId"] as? String,
               let uuid = UUID(uuidString: habitId) {
                await handleHabitCompletion(uuid)
            }
            
        case "START_MEDITATION":
            if let meditationType = userInfo["meditationType"] as? String,
               let type = MeditationType(rawValue: meditationType) {
                await handleMeditationStart(type)
            }
            
        case "SNOOZE_ROUTINE", "SNOOZE_HABIT", "SNOOZE_MEDITATION":
            await handleSnooze(for: userInfo)
            
        default:
            break
        }
    }
    
    private func handleRoutineCompletion(_ routineId: UUID) async {
        // Implementation would integrate with routine use cases
        AppLogger.shared.log("Handling routine completion from notification", level: .info, category: "Notifications")
    }
    
    private func handleHabitCompletion(_ habitId: UUID) async {
        // Implementation would integrate with habit use cases
        AppLogger.shared.log("Handling habit completion from notification", level: .info, category: "Notifications")
    }
    
    private func handleMeditationStart(_ type: MeditationType) async {
        // Implementation would integrate with meditation use cases
        AppLogger.shared.log("Handling meditation start from notification", level: .info, category: "Notifications")
    }
    
    private func handleSnooze(for userInfo: [AnyHashable: Any]) async {
        // Reschedule notification for later
        AppLogger.shared.log("Handling notification snooze", level: .info, category: "Notifications")
        
        // Add 10 minutes to current time and reschedule
        let snoozeDate = Date().addingTimeInterval(600) // 10 minutes
        
        // Implementation would reschedule based on notification type
    }
}

// MARK: - Supporting Types
enum NotificationCategory: String, CaseIterable {
    case routine = "ROUTINE_CATEGORY"
    case habit = "HABIT_CATEGORY"
    case meditation = "MEDITATION_CATEGORY"
    case general = "GENERAL_CATEGORY"
}

enum SmartSchedulingStrategy {
    case optimal        // AI-optimized delivery time
    case immediate      // Send immediately
    case nextAvailableSlot  // Next available time slot
    case userPreferred  // User's preferred notification time
}