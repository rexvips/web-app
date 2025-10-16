//
//  Habit.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation

/// Core domain entity for habit tracking
struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var category: HabitCategory
    var targetFrequency: HabitFrequency
    var reminderSettings: ReminderSettings
    var isActive: Bool
    var streakCount: Int
    var longestStreak: Int
    var completionHistory: [HabitCompletion]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        category: HabitCategory = .general,
        targetFrequency: HabitFrequency = .daily,
        reminderSettings: ReminderSettings = ReminderSettings(),
        isActive: Bool = true,
        streakCount: Int = 0,
        longestStreak: Int = 0,
        completionHistory: [HabitCompletion] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.targetFrequency = targetFrequency
        self.reminderSettings = reminderSettings
        self.isActive = isActive
        self.streakCount = streakCount
        self.longestStreak = longestStreak
        self.completionHistory = completionHistory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Check if habit is completed today
    var isCompletedToday: Bool {
        let today = Date()
        return completionHistory.contains { completion in
            Calendar.current.isDate(completion.completionDate, inSameDayAs: today) && completion.isCompleted
        }
    }
    
    /// Get completion percentage for the current period
    var completionPercentage: Double {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch targetFrequency {
        case .daily:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .weekly:
            startDate = calendar.date(byAdding: .weekOfYear, value: -12, to: now) ?? now
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .custom:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        }
        
        let relevantCompletions = completionHistory.filter { $0.completionDate >= startDate }
        let completedCount = relevantCompletions.filter { $0.isCompleted }.count
        
        return relevantCompletions.isEmpty ? 0 : Double(completedCount) / Double(relevantCompletions.count)
    }
    
    /// Calculate the current streak
    mutating func updateStreak() {
        let calendar = Calendar.current
        let sortedCompletions = completionHistory
            .filter { $0.isCompleted }
            .sorted { $0.completionDate > $1.completionDate }
        
        var currentStreak = 0
        var currentDate = Date()
        
        for completion in sortedCompletions {
            if calendar.isDate(completion.completionDate, inSameDayAs: currentDate) ||
               calendar.isDate(completion.completionDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate) {
                currentStreak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        streakCount = currentStreak
        longestStreak = max(longestStreak, streakCount)
    }
}

/// Habit categories for organization
enum HabitCategory: String, CaseIterable, Codable {
    case health = "health"
    case fitness = "fitness"
    case mindfulness = "mindfulness"
    case productivity = "productivity"
    case learning = "learning"
    case social = "social"
    case creativity = "creativity"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .fitness: return "Fitness"
        case .mindfulness: return "Mindfulness"
        case .productivity: return "Productivity"
        case .learning: return "Learning"
        case .social: return "Social"
        case .creativity: return "Creativity"
        case .general: return "General"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.walk"
        case .mindfulness: return "leaf.fill"
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .learning: return "book.fill"
        case .social: return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        case .general: return "circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .health: return "red"
        case .fitness: return "green"
        case .mindfulness: return "purple"
        case .productivity: return "blue"
        case .learning: return "orange"
        case .social: return "pink"
        case .creativity: return "yellow"
        case .general: return "gray"
        }
    }
}

/// Frequency patterns for habits
enum HabitFrequency: Codable, Hashable {
    case daily
    case weekly(days: Set<Weekday>)
    case monthly(dayOfMonth: Int)
    case custom(interval: TimeInterval)
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly(let days):
            if days.count == 7 {
                return "Daily"
            } else if days.count == 5 && !days.contains(.saturday) && !days.contains(.sunday) {
                return "Weekdays"
            } else if days.count == 2 && days.contains(.saturday) && days.contains(.sunday) {
                return "Weekends"
            } else {
                let dayNames = days.sorted().map { $0.shortName }.joined(separator: ", ")
                return "Weekly (\(dayNames))"
            }
        case .monthly(let day):
            return "Monthly (Day \(day))"
        case .custom(let interval):
            let days = Int(interval / 86400) // seconds to days
            return "Every \(days) days"
        }
    }
    
    /// Check if habit is due on a specific date
    func isDue(on date: Date) -> Bool {
        let calendar = Calendar.current
        
        switch self {
        case .daily:
            return true
        case .weekly(let days):
            let weekday = Weekday(from: calendar.component(.weekday, from: date))
            return days.contains(weekday)
        case .monthly(let dayOfMonth):
            return calendar.component(.day, from: date) == dayOfMonth
        case .custom(let interval):
            // Implementation for custom intervals would require reference date
            return true // Simplified for now
        }
    }
}

/// Weekday enumeration
enum Weekday: Int, CaseIterable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    init(from calendarWeekday: Int) {
        self = Weekday(rawValue: calendarWeekday) ?? .sunday
    }
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

extension Set where Element == Weekday {
    func sorted() -> [Weekday] {
        return self.sorted { $0.rawValue < $1.rawValue }
    }
}

/// Individual habit completion record
struct HabitCompletion: Identifiable, Codable, Hashable {
    let id: UUID
    let completionDate: Date
    let isCompleted: Bool
    let notes: String?
    let mood: MoodRating?
    let effort: EffortRating?
    
    init(
        id: UUID = UUID(),
        completionDate: Date = Date(),
        isCompleted: Bool,
        notes: String? = nil,
        mood: MoodRating? = nil,
        effort: EffortRating? = nil
    ) {
        self.id = id
        self.completionDate = completionDate
        self.isCompleted = isCompleted
        self.notes = notes
        self.mood = mood
        self.effort = effort
    }
}

/// Mood rating for habit completions
enum MoodRating: Int, CaseIterable, Codable {
    case veryPoor = 1
    case poor = 2
    case neutral = 3
    case good = 4
    case excellent = 5
    
    var displayName: String {
        switch self {
        case .veryPoor: return "Very Poor"
        case .poor: return "Poor"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryPoor: return "😞"
        case .poor: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .excellent: return "😊"
        }
    }
    
    var color: String {
        switch self {
        case .veryPoor: return "red"
        case .poor: return "orange"
        case .neutral: return "yellow"
        case .good: return "green"
        case .excellent: return "blue"
        }
    }
}

/// Effort rating for habit completions
enum EffortRating: Int, CaseIterable, Codable {
    case minimal = 1
    case low = 2
    case moderate = 3
    case high = 4
    case maximum = 5
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .maximum: return "Maximum"
        }
    }
    
    var icon: String {
        switch self {
        case .minimal: return "battery.25"
        case .low: return "battery.50"
        case .moderate: return "battery.75"
        case .high: return "battery.100"
        case .maximum: return "bolt.fill"
        }
    }
}