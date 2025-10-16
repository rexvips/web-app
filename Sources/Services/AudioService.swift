//
//  AudioService.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit

/// Production-grade audio service for meditation and background sounds
final class AudioService: NSObject, AudioServiceProtocol {
    
    // MARK: - Properties
    private var audioSession: AVAudioSession
    private var ambientPlayer: AVAudioPlayer?
    private var cuePlayer: AVAudioPlayer?
    private var bellTimer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    // Published properties for reactive UI
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentAmbientSound: AmbientSound?
    
    private var bellInterval: TimeInterval = 0
    private var bellDuration: TimeInterval = 0
    private var isInitialized = false
    
    // MARK: - Initialization
    override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        do {
            try await setupAudioSession()
            await preloadAudioAssets()
            setupRemoteTransportControls()
            setupNotifications()
            
            isInitialized = true
            AppLogger.shared.log("AudioService initialized", level: .info, category: "Audio")
        } catch {
            AppLogger.shared.logError(error, context: "Failed to initialize AudioService", category: "Audio")
            throw ServiceError.audioSessionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() async throws {
        try audioSession.setCategory(
            .playback,
            mode: .default,
            options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
        )
        
        try audioSession.setActive(true)
        
        AppLogger.shared.log("Audio session configured for meditation playback", level: .debug, category: "Audio")
    }
    
    func setupBackgroundAudio() async throws {
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetooth]
            )
            
            try audioSession.setActive(true)
            
            AppLogger.shared.log("Background audio configured", level: .info, category: "Audio")
        } catch {
            AppLogger.shared.logError(error, context: "Failed to setup background audio", category: "Audio")
            throw ServiceError.audioSessionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Ambient Sound Management
    func playAmbientSound(_ sound: AmbientSound, volume: Double) async throws {
        guard sound != .none else {
            await stopAmbientSound()
            return
        }
        
        // Stop current sound if playing
        await stopAmbientSound()
        
        guard let soundURL = getSoundURL(for: sound) else {
            throw ServiceError.audioSessionFailed("Sound file not found: \(sound.fileName ?? "unknown")")
        }
        
        do {
            ambientPlayer = try AVAudioPlayer(contentsOf: soundURL)
            ambientPlayer?.delegate = self
            ambientPlayer?.numberOfLoops = -1 // Loop indefinitely
            ambientPlayer?.volume = Float(volume)
            ambientPlayer?.prepareToPlay()
            
            let success = ambientPlayer?.play() ?? false
            
            if success {
                isPlaying = true
                currentAmbientSound = sound
                await updateNowPlayingInfo(for: sound)
                
                AppLogger.shared.log("Started playing ambient sound: \(sound.displayName)", level: .info, category: "Audio")
            } else {
                throw ServiceError.audioSessionFailed("Failed to start ambient sound playback")
            }
            
        } catch {
            AppLogger.shared.logError(error, context: "Failed to play ambient sound", category: "Audio")
            throw ServiceError.audioSessionFailed(error.localizedDescription)
        }
    }
    
    func stopAmbientSound() async {
        ambientPlayer?.stop()
        ambientPlayer = nil
        isPlaying = false
        currentAmbientSound = nil
        
        await clearNowPlayingInfo()
        
        AppLogger.shared.log("Stopped ambient sound", level: .debug, category: "Audio")
    }
    
    func setVolume(_ volume: Double) async {
        ambientPlayer?.volume = Float(volume)
        AppLogger.shared.log("Volume set to: \(volume)", level: .debug, category: "Audio")
    }
    
    // MARK: - Breathing Cue Sounds
    func playBreathingCue(_ cue: BreathingCueType, volume: Double) async throws {
        guard let cueURL = getCueURL(for: cue) else {
            throw ServiceError.audioSessionFailed("Cue sound file not found: \(cue.rawValue)")
        }
        
        do {
            // Create a new player for cue sounds (to not interfere with ambient sounds)
            let cueAudioPlayer = try AVAudioPlayer(contentsOf: cueURL)
            cueAudioPlayer.volume = Float(volume)
            cueAudioPlayer.prepareToPlay()
            cueAudioPlayer.play()
            
            AppLogger.shared.log("Played breathing cue: \(cue.displayName)", level: .debug, category: "Audio")
            
        } catch {
            AppLogger.shared.logError(error, context: "Failed to play breathing cue", category: "Audio")
            throw ServiceError.audioSessionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Bell Timer for Meditation
    func configureBellSound(interval: TimeInterval, duration: TimeInterval) async throws {
        bellInterval = interval
        bellDuration = duration
        
        AppLogger.shared.log(
            "Configured bell sound: interval=\(interval)s, duration=\(duration)s",
            level: .debug,
            category: "Audio"
        )
    }
    
    func startBellTimer() async {
        guard bellInterval > 0 else { return }
        
        await stopBellTimer()
        
        bellTimer = Timer.scheduledTimer(withTimeInterval: bellInterval, repeats: true) { [weak self] _ in
            Task {
                try? await self?.playBreathingCue(.bell, volume: 0.7)
            }
        }
        
        AppLogger.shared.log("Started bell timer with interval: \(bellInterval)s", level: .info, category: "Audio")
    }
    
    func stopBellTimer() async {
        bellTimer?.invalidate()
        bellTimer = nil
        
        AppLogger.shared.log("Stopped bell timer", level: .debug, category: "Audio")
    }
    
    // MARK: - Background Task Management
    private func beginBackgroundTask() {
        endBackgroundTask()
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "MeditationAudio") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
    
    // MARK: - Now Playing Info
    private func updateNowPlayingInfo(for sound: AmbientSound) async {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Meditation"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Daily Routine App"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = sound.displayName
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        // Add artwork if available
        if let artwork = getArtwork(for: sound) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func clearNowPlayingInfo() async {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Remote Control
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task {
                if let sound = self?.currentAmbientSound {
                    try? await self?.playAmbientSound(sound, volume: 0.7)
                }
            }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task {
                await self?.stopAmbientSound()
            }
            return .success
        }
        
        commandCenter.stopCommand.addTarget { [weak self] _ in
            Task {
                await self?.stopAmbientSound()
            }
            return .success
        }
        
        // Disable unused commands
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
    }
    
    // MARK: - Asset Management
    private func preloadAudioAssets() async {
        let soundsToPreload: [AmbientSound] = [.rain, .ocean, .forest, .whitenoise]
        
        for sound in soundsToPreload {
            if let url = getSoundURL(for: sound) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    
                    AppLogger.shared.log("Preloaded sound: \(sound.displayName)", level: .debug, category: "Audio")
                } catch {
                    AppLogger.shared.logError(error, context: "Failed to preload sound: \(sound.displayName)", category: "Audio")
                }
            }
        }
    }
    
    private func getSoundURL(for sound: AmbientSound) -> URL? {
        guard let fileName = sound.fileName else { return nil }
        
        // Try to find in main bundle first
        if let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") {
            return url
        }
        
        // Try alternative paths or generate programmatically for missing sounds
        return generateSoundURL(for: sound)
    }
    
    private func getCueURL(for cue: BreathingCueType) -> URL? {
        let fileName = "\(cue.rawValue)_cue"
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            return url
        }
        
        // Generate programmatically if needed
        return generateCueURL(for: cue)
    }
    
    private func generateSoundURL(for sound: AmbientSound) -> URL? {
        // This could generate synthetic sounds programmatically
        // For now, return a default sound URL or nil
        AppLogger.shared.log("Sound file not found, would generate: \(sound.displayName)", level: .warning, category: "Audio")
        return nil
    }
    
    private func generateCueURL(for cue: BreathingCueType) -> URL? {
        // This could generate synthetic cue sounds programmatically
        AppLogger.shared.log("Cue file not found, would generate: \(cue.displayName)", level: .warning, category: "Audio")
        return nil
    }
    
    private func getArtwork(for sound: AmbientSound) -> MPMediaItemArtwork? {
        // Load artwork for the ambient sound
        let imageName = "\(sound.rawValue)_artwork"
        
        if let image = UIImage(named: imageName) {
            return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        // Return default meditation artwork
        if let defaultImage = UIImage(named: "meditation_default") {
            return MPMediaItemArtwork(boundsSize: defaultImage.size) { _ in defaultImage }
        }
        
        return nil
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func audioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            AppLogger.shared.log("Audio session interrupted", level: .info, category: "Audio")
            Task {
                await stopAmbientSound()
                await stopBellTimer()
            }
            
        case .ended:
            AppLogger.shared.log("Audio session interruption ended", level: .info, category: "Audio")
            
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Resume playback if appropriate
                    Task {
                        if let sound = currentAmbientSound {
                            try? await playAmbientSound(sound, volume: 0.7)
                        }
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func audioSessionRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            AppLogger.shared.log("Audio device disconnected", level: .info, category: "Audio")
            Task {
                await stopAmbientSound()
            }
            
        case .newDeviceAvailable:
            AppLogger.shared.log("New audio device available", level: .info, category: "Audio")
            
        default:
            break
        }
    }
    
    @objc private func applicationWillResignActive() {
        beginBackgroundTask()
    }
    
    @objc private func applicationDidBecomeActive() {
        endBackgroundTask()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == ambientPlayer {
            isPlaying = false
            currentAmbientSound = nil
            
            AppLogger.shared.log("Ambient sound finished playing", level: .debug, category: "Audio")
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            AppLogger.shared.logError(error, context: "Audio player decode error", category: "Audio")
        }
        
        if player == ambientPlayer {
            isPlaying = false
            currentAmbientSound = nil
        }
    }
}