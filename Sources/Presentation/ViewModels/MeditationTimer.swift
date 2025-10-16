//
//  MeditationTimer.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import AVFoundation
import Combine
import UIKit

/// High-precision meditation timer with breathing guidance and audio support
final class MeditationTimer: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var timeRemaining: TimeInterval = 0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var currentPhase: BreathingPhase?
    @Published private(set) var phaseProgress: Double = 0
    @Published private(set) var cycleCount: Int = 0
    @Published private(set) var sessionProgress: Double = 0
    
    // MARK: - Properties
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var pausedTime: CFTimeInterval = 0
    private var lastUpdateTime: CFTimeInterval = 0
    
    private let breathingPattern: BreathingPattern
    private let audioService: AudioServiceProtocol
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    private let settings: MeditationSettings
    
    private var currentPhaseIndex: Int = 0
    private var phaseStartTime: CFTimeInterval = 0
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    private let completion: (TimeInterval) -> Void
    
    // MARK: - Initialization
    init(
        duration: TimeInterval,
        breathingPattern: BreathingPattern,
        settings: MeditationSettings,
        audioService: AudioServiceProtocol,
        completion: @escaping (TimeInterval) -> Void
    ) {
        self.totalDuration = duration
        self.timeRemaining = duration
        self.breathingPattern = breathingPattern
        self.audioService = audioService
        self.settings = settings
        self.completion = completion
        
        setupInitialPhase()
        prepareHapticFeedback()
    }
    
    // MARK: - Timer Control
    func start() async {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        
        if startTime == 0 {
            startTime = CACurrentMediaTime()
            lastUpdateTime = startTime
        } else {
            // Resuming from pause
            let pauseDuration = CACurrentMediaTime() - pausedTime
            startTime += pauseDuration
        }
        
        await startAmbientAudio()
        beginBackgroundTask()
        startDisplayLink()
        
        AppLogger.shared.log("Meditation timer started", level: .info, category: "Meditation")
        AnalyticsManager.shared.track(.meditationStarted(breathingPattern.description, duration: Int(totalDuration)))
    }
    
    func pause() async {
        guard isRunning && !isPaused else { return }
        
        isPaused = true
        pausedTime = CACurrentMediaTime()
        
        stopDisplayLink()
        await pauseAmbientAudio()
        
        AppLogger.shared.log("Meditation timer paused", level: .info, category: "Meditation")
    }
    
    func resume() async {
        guard isPaused else { return }
        
        isPaused = false
        
        let pauseDuration = CACurrentMediaTime() - pausedTime
        startTime += pauseDuration
        
        await resumeAmbientAudio()
        startDisplayLink()
        
        AppLogger.shared.log("Meditation timer resumed", level: .info, category: "Meditation")
    }
    
    func stop() async {
        let elapsedTime = totalDuration - timeRemaining
        
        isRunning = false
        isPaused = false
        
        stopDisplayLink()
        await stopAmbientAudio()
        endBackgroundTask()
        
        completion(elapsedTime)
        
        AppLogger.shared.log("Meditation timer stopped - Duration: \(elapsedTime)s", level: .info, category: "Meditation")
        AnalyticsManager.shared.track(.meditationCompleted(breathingPattern.description, duration: Int(elapsedTime)))
    }
    
    // MARK: - Display Link
    private func startDisplayLink() {
        stopDisplayLink()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateTimer))
        displayLink?.preferredFramesPerSecond = 60 // High precision for smooth animations
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateTimer() {
        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - startTime
        let newTimeRemaining = max(0, totalDuration - elapsedTime)
        
        // Update time remaining
        timeRemaining = newTimeRemaining
        sessionProgress = (totalDuration - timeRemaining) / totalDuration
        
        // Update breathing phase
        updateBreathingPhase(currentTime: currentTime, elapsedTime: elapsedTime)
        
        // Check if session is complete
        if timeRemaining <= 0 {
            Task {
                await stop()
            }
        }
        
        lastUpdateTime = currentTime
    }
    
    // MARK: - Breathing Phase Management
    private func setupInitialPhase() {
        let phases = breathingPattern.phases
        guard !phases.isEmpty else { return }
        
        currentPhase = phases[0]
        currentPhaseIndex = 0
        phaseProgress = 0
    }
    
    private func updateBreathingPhase(currentTime: CFTimeInterval, elapsedTime: TimeInterval) {
        let phases = breathingPattern.phases
        guard !phases.isEmpty else { return }
        
        let cycleDuration = breathingPattern.totalCycleDuration
        let currentCycleTime = elapsedTime.truncatingRemainder(dividingBy: cycleDuration)
        
        // Calculate current cycle count
        let newCycleCount = Int(elapsedTime / cycleDuration)
        if newCycleCount != cycleCount {
            cycleCount = newCycleCount
            triggerHapticFeedback()
        }
        
        // Find current phase within the cycle
        var phaseStartTime: TimeInterval = 0
        var foundPhase = false
        
        for (index, phase) in phases.enumerated() {
            let phaseEndTime = phaseStartTime + TimeInterval(phase.duration)
            
            if currentCycleTime >= phaseStartTime && currentCycleTime < phaseEndTime {
                // Update phase if changed
                if currentPhaseIndex != index {
                    let previousPhase = currentPhase
                    currentPhase = phase
                    currentPhaseIndex = index
                    self.phaseStartTime = currentTime
                    
                    Task {
                        await handlePhaseTransition(from: previousPhase, to: phase)
                    }
                }
                
                // Calculate phase progress
                let phaseElapsed = currentCycleTime - phaseStartTime
                phaseProgress = phaseElapsed / TimeInterval(phase.duration)
                
                foundPhase = true
                break
            }
            
            phaseStartTime = phaseEndTime
        }
        
        if !foundPhase {
            // Shouldn't happen, but handle gracefully
            currentPhase = phases[0]
            currentPhaseIndex = 0
            phaseProgress = 0
        }
    }
    
    private func handlePhaseTransition(from previousPhase: BreathingPhase?, to newPhase: BreathingPhase) async {
        // Play breathing cue sound
        if settings.soundSettings.breathingCues.isEnabled {
            try? await audioService.playBreathingCue(
                settings.soundSettings.breathingCues.cueType,
                volume: settings.soundSettings.breathingCues.volume
            )
        }
        
        // Trigger haptic feedback
        if settings.hapticSettings.isEnabled {
            triggerHapticFeedback()
        }
        
        AppLogger.shared.log(
            "Breathing phase transition: \(previousPhase?.type.rawValue ?? "none") → \(newPhase.type.rawValue)",
            level: .debug,
            category: "Meditation"
        )
    }
    
    // MARK: - Audio Management
    private func startAmbientAudio() async {
        guard settings.soundSettings.isEnabled,
              let ambientSound = settings.soundSettings.ambientSound else { return }
        
        do {
            try await audioService.playAmbientSound(ambientSound, volume: settings.soundSettings.volume)
        } catch {
            AppLogger.shared.logError(error, context: "Failed to start ambient audio", category: "Meditation")
        }
    }
    
    private func pauseAmbientAudio() async {
        // Implementation would pause the current audio
        await audioService.stopAmbientSound()
    }
    
    private func resumeAmbientAudio() async {
        await startAmbientAudio()
    }
    
    private func stopAmbientAudio() async {
        await audioService.stopAmbientSound()
        await audioService.stopBellTimer()
    }
    
    // MARK: - Haptic Feedback
    private func prepareHapticFeedback() {
        guard settings.hapticSettings.isEnabled else { return }
        hapticFeedback.prepare()
    }
    
    private func triggerHapticFeedback() {
        guard settings.hapticSettings.isEnabled else { return }
        
        switch settings.hapticSettings.intensity {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .strong:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    // MARK: - Background Task Management
    private func beginBackgroundTask() {
        endBackgroundTask()
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "MeditationTimer") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
    
    // Get formatted time for display
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formattedElapsedTime() -> String {
        let elapsed = totalDuration - timeRemaining
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        stopDisplayLink()
        endBackgroundTask()
    }
}

// MARK: - Breathing Pattern Extensions
extension BreathingPattern {
    var description: String {
        switch self {
        case .boxBreathing:
            return "box_breathing"
        case .fourSevenEight:
            return "4_7_8_breathing"
        case .custom:
            return "custom_breathing"
        }
    }
}

// MARK: - Preset Breathing Patterns
extension BreathingPattern {
    static var defaultBoxBreathing: BreathingPattern {
        return .boxBreathing(inhale: 4, hold: 4, exhale: 4, pause: 4)
    }
    
    static var defaultFourSevenEight: BreathingPattern {
        return .fourSevenEight(inhale: 4, hold: 7, exhale: 8)
    }
    
    static func customBoxBreathing(
        inhale: Int,
        hold: Int,
        exhale: Int,
        pause: Int
    ) -> BreathingPattern {
        return .boxBreathing(inhale: inhale, hold: hold, exhale: exhale, pause: pause)
    }
    
    static func customFourSevenEight(
        inhale: Int,
        hold: Int,
        exhale: Int
    ) -> BreathingPattern {
        return .fourSevenEight(inhale: inhale, hold: hold, exhale: exhale)
    }
}