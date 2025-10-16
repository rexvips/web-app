//
//  Meditation.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation

/// Core domain entity for meditation sessions
struct MeditationSession: Identifiable, Codable, Hashable {
    let id: UUID
    var type: MeditationType
    var duration: TimeInterval
    var actualDuration: TimeInterval?
    var startTime: Date?
    var endTime: Date?
    var isCompleted: Bool
    var settings: MeditationSettings
    var notes: String?
    var heartRateData: [HeartRateReading]?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: MeditationType,
        duration: TimeInterval,
        actualDuration: TimeInterval? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        isCompleted: Bool = false,
        settings: MeditationSettings = MeditationSettings(),
        notes: String? = nil,
        heartRateData: [HeartRateReading]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.duration = duration
        self.actualDuration = actualDuration
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted
        self.settings = settings
        self.notes = notes
        self.heartRateData = heartRateData
        self.createdAt = createdAt
    }
    
    /// Calculate completion percentage if session was interrupted
    var completionPercentage: Double {
        guard let actualDuration = actualDuration else { return 0 }
        return min(actualDuration / duration, 1.0)
    }
    
    /// Check if session is currently active
    var isActive: Bool {
        return startTime != nil && endTime == nil
    }
}

/// Types of meditation available in the app
enum MeditationType: String, CaseIterable, Codable {
    case boxBreathing = "boxBreathing"
    case fourSevenEight = "fourSevenEight"
    case customTimer = "customTimer"
    case guidedMeditation = "guidedMeditation"
    case mindfulness = "mindfulness"
    case bodyScanning = "bodyScanning"
    
    var displayName: String {
        switch self {
        case .boxBreathing: return "Box Breathing"
        case .fourSevenEight: return "4-7-8 Breathing"
        case .customTimer: return "Custom Timer"
        case .guidedMeditation: return "Guided Meditation"
        case .mindfulness: return "Mindfulness"
        case .bodyScanning: return "Body Scanning"
        }
    }
    
    var description: String {
        switch self {
        case .boxBreathing:
            return "Breathe in a square pattern to calm your mind and reduce stress"
        case .fourSevenEight:
            return "Inhale for 4, hold for 7, exhale for 8 to promote relaxation"
        case .customTimer:
            return "Set your own meditation duration with customizable ambient sounds"
        case .guidedMeditation:
            return "Follow along with guided meditation sessions"
        case .mindfulness:
            return "Practice present moment awareness and mindful breathing"
        case .bodyScanning:
            return "Progressive relaxation through body awareness"
        }
    }
    
    var icon: String {
        switch self {
        case .boxBreathing: return "square.dashed"
        case .fourSevenEight: return "waveform.path"
        case .customTimer: return "timer"
        case .guidedMeditation: return "person.wave.2"
        case .mindfulness: return "brain.head.profile"
        case .bodyScanning: return "figure.mind.and.body"
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .boxBreathing: return 300 // 5 minutes
        case .fourSevenEight: return 240 // 4 minutes
        case .customTimer: return 600 // 10 minutes
        case .guidedMeditation: return 900 // 15 minutes
        case .mindfulness: return 720 // 12 minutes
        case .bodyScanning: return 1200 // 20 minutes
        }
    }
}

/// Meditation-specific settings
struct MeditationSettings: Codable, Hashable {
    var breathingPattern: BreathingPattern
    var soundSettings: SoundSettings
    var visualSettings: VisualSettings
    var hapticSettings: HapticSettings
    var backgroundMode: BackgroundMode
    
    init(
        breathingPattern: BreathingPattern = .boxBreathing(inhale: 4, hold: 4, exhale: 4, pause: 4),
        soundSettings: SoundSettings = SoundSettings(),
        visualSettings: VisualSettings = VisualSettings(),
        hapticSettings: HapticSettings = HapticSettings(),
        backgroundMode: BackgroundMode = .allowBackground
    ) {
        self.breathingPattern = breathingPattern
        self.soundSettings = soundSettings
        self.visualSettings = visualSettings
        self.hapticSettings = hapticSettings
        self.backgroundMode = backgroundMode
    }
}

/// Breathing patterns for guided breathing exercises
enum BreathingPattern: Codable, Hashable {
    case boxBreathing(inhale: Int, hold: Int, exhale: Int, pause: Int)
    case fourSevenEight(inhale: Int, hold: Int, exhale: Int)
    case custom(phases: [BreathingPhase])
    
    var totalCycleDuration: TimeInterval {
        switch self {
        case .boxBreathing(let inhale, let hold, let exhale, let pause):
            return TimeInterval(inhale + hold + exhale + pause)
        case .fourSevenEight(let inhale, let hold, let exhale):
            return TimeInterval(inhale + hold + exhale)
        case .custom(let phases):
            return phases.reduce(0) { $0 + TimeInterval($1.duration) }
        }
    }
    
    var phases: [BreathingPhase] {
        switch self {
        case .boxBreathing(let inhale, let hold, let exhale, let pause):
            return [
                BreathingPhase(type: .inhale, duration: inhale),
                BreathingPhase(type: .hold, duration: hold),
                BreathingPhase(type: .exhale, duration: exhale),
                BreathingPhase(type: .pause, duration: pause)
            ]
        case .fourSevenEight(let inhale, let hold, let exhale):
            return [
                BreathingPhase(type: .inhale, duration: inhale),
                BreathingPhase(type: .hold, duration: hold),
                BreathingPhase(type: .exhale, duration: exhale)
            ]
        case .custom(let phases):
            return phases
        }
    }
}

/// Individual breathing phase
struct BreathingPhase: Codable, Hashable {
    let type: BreathingPhaseType
    let duration: Int // in seconds
    
    var instruction: String {
        switch type {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        case .pause: return "Pause"
        }
    }
}

enum BreathingPhaseType: String, CaseIterable, Codable {
    case inhale = "inhale"
    case hold = "hold"
    case exhale = "exhale"
    case pause = "pause"
}

/// Sound settings for meditation
struct SoundSettings: Codable, Hashable {
    var isEnabled: Bool
    var ambientSound: AmbientSound?
    var breathingCues: BreathingCueSettings
    var volume: Double
    
    init(
        isEnabled: Bool = true,
        ambientSound: AmbientSound? = .rain,
        breathingCues: BreathingCueSettings = BreathingCueSettings(),
        volume: Double = 0.7
    ) {
        self.isEnabled = isEnabled
        self.ambientSound = ambientSound
        self.breathingCues = breathingCues
        self.volume = volume
    }
}

/// Available ambient sounds
enum AmbientSound: String, CaseIterable, Codable {
    case none = "none"
    case rain = "rain"
    case ocean = "ocean"
    case forest = "forest"
    case whitenoise = "whitenoise"
    case bowlSinging = "bowlSinging"
    case natureSounds = "natureSounds"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .rain: return "Rain"
        case .ocean: return "Ocean Waves"
        case .forest: return "Forest"
        case .whitenoise: return "White Noise"
        case .bowlSinging: return "Singing Bowl"
        case .natureSounds: return "Nature Sounds"
        }
    }
    
    var fileName: String? {
        guard self != .none else { return nil }
        return "\(rawValue).mp3"
    }
}

/// Breathing cue sound settings
struct BreathingCueSettings: Codable, Hashable {
    var isEnabled: Bool
    var cueType: BreathingCueType
    var volume: Double
    
    init(
        isEnabled: Bool = true,
        cueType: BreathingCueType = .bell,
        volume: Double = 0.5
    ) {
        self.isEnabled = isEnabled
        self.cueType = cueType
        self.volume = volume
    }
}

enum BreathingCueType: String, CaseIterable, Codable {
    case bell = "bell"
    case chime = "chime"
    case tone = "tone"
    case voice = "voice"
    
    var displayName: String {
        switch self {
        case .bell: return "Bell"
        case .chime: return "Chime"
        case .tone: return "Tone"
        case .voice: return "Voice Guide"
        }
    }
}

/// Visual settings for meditation
struct VisualSettings: Codable, Hashable {
    var breathingGuide: BreathingGuideType
    var colorTheme: ColorTheme
    var showTimer: Bool
    var showProgress: Bool
    
    init(
        breathingGuide: BreathingGuideType = .circle,
        colorTheme: ColorTheme = .calm,
        showTimer: Bool = true,
        showProgress: Bool = true
    ) {
        self.breathingGuide = breathingGuide
        self.colorTheme = colorTheme
        self.showTimer = showTimer
        self.showProgress = showProgress
    }
}

enum BreathingGuideType: String, CaseIterable, Codable {
    case circle = "circle"
    case square = "square"
    case wave = "wave"
    case minimal = "minimal"
    
    var displayName: String {
        switch self {
        case .circle: return "Breathing Circle"
        case .square: return "Square Guide"
        case .wave: return "Wave Animation"
        case .minimal: return "Minimal"
        }
    }
}

enum ColorTheme: String, CaseIterable, Codable {
    case calm = "calm"
    case nature = "nature"
    case sunset = "sunset"
    case ocean = "ocean"
    case minimal = "minimal"
    
    var displayName: String {
        switch self {
        case .calm: return "Calm Blue"
        case .nature: return "Nature Green"
        case .sunset: return "Sunset Orange"
        case .ocean: return "Ocean Teal"
        case .minimal: return "Minimal Gray"
        }
    }
}

/// Haptic feedback settings
struct HapticSettings: Codable, Hashable {
    var isEnabled: Bool
    var intensity: HapticIntensity
    var patternType: HapticPatternType
    
    init(
        isEnabled: Bool = true,
        intensity: HapticIntensity = .medium,
        patternType: HapticPatternType = .gentle
    ) {
        self.isEnabled = isEnabled
        self.intensity = intensity
        self.patternType = patternType
    }
}

enum HapticIntensity: String, CaseIterable, Codable {
    case light = "light"
    case medium = "medium"
    case strong = "strong"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

enum HapticPatternType: String, CaseIterable, Codable {
    case gentle = "gentle"
    case rhythmic = "rhythmic"
    case pulse = "pulse"
    
    var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .rhythmic: return "Rhythmic"
        case .pulse: return "Pulse"
        }
    }
}

/// Background execution mode
enum BackgroundMode: String, CaseIterable, Codable {
    case allowBackground = "allowBackground"
    case foregroundOnly = "foregroundOnly"
    
    var displayName: String {
        switch self {
        case .allowBackground: return "Allow Background"
        case .foregroundOnly: return "Foreground Only"
        }
    }
}

/// Heart rate reading for HealthKit integration
struct HeartRateReading: Codable, Hashable {
    let timestamp: Date
    let value: Double // beats per minute
    
    init(timestamp: Date = Date(), value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
}