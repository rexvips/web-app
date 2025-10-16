//
//  Routine.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation

/// Core domain entity representing a daily routine
struct Routine: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var activities: [Activity]
    var scheduledTime: Date?
    var isActive: Bool
    var category: RoutineCategory
    var estimatedDuration: TimeInterval
    var priority: Priority
    var reminderSettings: ReminderSettings
    var streakCount: Int
    var completionHistory: [CompletionRecord]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        activities: [Activity] = [],
        scheduledTime: Date? = nil,
        isActive: Bool = true,
        category: RoutineCategory = .general,
        estimatedDuration: TimeInterval = 0,
        priority: Priority = .medium,
        reminderSettings: ReminderSettings = ReminderSettings(),
        streakCount: Int = 0,
        completionHistory: [CompletionRecord] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.activities = activities
        self.scheduledTime = scheduledTime
        self.isActive = isActive
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.priority = priority
        self.reminderSettings = reminderSettings
        self.streakCount = streakCount
        self.completionHistory = completionHistory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Calculate actual duration based on completion history
    var averageDuration: TimeInterval {
        let completedRecords = completionHistory.filter { $0.isCompleted }
        guard !completedRecords.isEmpty else { return estimatedDuration }
        
        let totalDuration = completedRecords.reduce(0) { $0 + $1.actualDuration }
        return totalDuration / Double(completedRecords.count)
    }
    
    /// Get completion percentage for current streak
    var completionPercentage: Double {
        guard !completionHistory.isEmpty else { return 0 }
        
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentHistory = completionHistory.filter { $0.completionDate >= last30Days }
        let completedCount = recentHistory.filter { $0.isCompleted }.count
        
        return recentHistory.isEmpty ? 0 : Double(completedCount) / Double(recentHistory.count)
    }
    
    /// Check if routine is due today
    var isDueToday: Bool {
        guard let scheduledTime = scheduledTime else { return false }
        return Calendar.current.isDateInToday(scheduledTime)
    }
    
    /// Check if routine was completed today
    var isCompletedToday: Bool {
        let today = Date()
        return completionHistory.contains { record in
            Calendar.current.isDate(record.completionDate, inSameDayAs: today) && record.isCompleted
        }
    }
}

/// Activity within a routine
struct Activity: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var estimatedDuration: TimeInterval
    var isCompleted: Bool
    var order: Int
    var type: ActivityType
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        estimatedDuration: TimeInterval,
        isCompleted: Bool = false,
        order: Int = 0,
        type: ActivityType = .general
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.estimatedDuration = estimatedDuration
        self.isCompleted = isCompleted
        self.order = order
        self.type = type
    }
}

/// Activity types with associated icons and colors
enum ActivityType: String, CaseIterable, Codable {
    case general = "general"
    case exercise = "exercise"
    case meditation = "meditation"
    case reading = "reading"
    case work = "work"
    case selfCare = "selfCare"
    case nutrition = "nutrition"
    case social = "social"
    
    var icon: String {
        switch self {
        case .general: return "checkmark.circle"
        case .exercise: return "figure.walk"
        case .meditation: return "leaf"
        case .reading: return "book"
        case .work: return "briefcase"
        case .selfCare: return "heart"
        case .nutrition: return "fork.knife"
        case .social: return "person.2"
        }
    }
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .exercise: return "Exercise"
        case .meditation: return "Meditation"
        case .reading: return "Reading"
        case .work: return "Work"
        case .selfCare: return "Self Care"
        case .nutrition: return "Nutrition"
        case .social: return "Social"
        }
    }
}

/// Routine categories for organization
enum RoutineCategory: String, CaseIterable, Codable {
    case morning = "morning"
    case evening = "evening"
    case workout = "workout"
    case wellness = "wellness"
    case productivity = "productivity"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .workout: return "Workout"
        case .wellness: return "Wellness"
        case .productivity: return "Productivity"
        case .general: return "General"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sun.max"
        case .evening: return "moon"
        case .workout: return "dumbbell"
        case .wellness: return "heart.circle"
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .general: return "list.bullet"
        }
    }
}

/// Priority levels for routines
enum Priority: Int, CaseIterable, Codable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

/// Reminder settings for routines
struct ReminderSettings: Codable, Hashable {
    var isEnabled: Bool
    var reminderTime: Date?
    var repeatInterval: RepeatInterval
    var soundName: String?
    var isVibrationEnabled: Bool
    
    init(
        isEnabled: Bool = false,
        reminderTime: Date? = nil,
        repeatInterval: RepeatInterval = .daily,
        soundName: String? = nil,
        isVibrationEnabled: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.reminderTime = reminderTime
        self.repeatInterval = repeatInterval
        self.soundName = soundName
        self.isVibrationEnabled = isVibrationEnabled
    }
}

/// Repeat intervals for reminders
enum RepeatInterval: String, CaseIterable, Codable {
    case never = "never"
    case daily = "daily"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case weekly = "weekly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }
}

/// Completion record for tracking routine history
struct CompletionRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let completionDate: Date
    let isCompleted: Bool
    let actualDuration: TimeInterval
    let completedActivities: [UUID] // Activity IDs
    let notes: String?
    
    init(
        id: UUID = UUID(),
        completionDate: Date = Date(),
        isCompleted: Bool,
        actualDuration: TimeInterval = 0,
        completedActivities: [UUID] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.completionDate = completionDate
        self.isCompleted = isCompleted
        self.actualDuration = actualDuration
        self.completedActivities = completedActivities
        self.notes = notes
    }
}