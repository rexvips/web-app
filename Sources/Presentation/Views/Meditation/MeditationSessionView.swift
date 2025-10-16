//
//  MeditationSessionView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct MeditationSessionView: View {
    let meditationType: MeditationType
    
    @EnvironmentObject private var appDependencies: AppDependencies
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @StateObject private var meditationTimer: MeditationTimer
    @State private var showSettings = false
    @State private var isSessionComplete = false
    
    init(meditationType: MeditationType) {
        self.meditationType = meditationType
        
        // Initialize timer with default settings
        let defaultSettings = MeditationSettings()
        let breathingPattern: BreathingPattern
        
        switch meditationType {
        case .boxBreathing:
            breathingPattern = .defaultBoxBreathing
        case .fourSevenEight:
            breathingPattern = .defaultFourSevenEight
        default:
            breathingPattern = .defaultBoxBreathing
        }
        
        self._meditationTimer = StateObject(wrapping: MeditationTimer(
            duration: meditationType.defaultDuration,
            breathingPattern: breathingPattern,
            settings: defaultSettings,
            audioService: AudioService()
        ) { _ in })
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                BackgroundView(colorTheme: meditationTimer.settings.visualSettings.colorTheme)
                
                VStack(spacing: 30) {
                    // Header
                    headerView
                    
                    Spacer()
                    
                    // Main breathing guide
                    breathingGuideView(geometry: geometry)
                    
                    Spacer()
                    
                    // Timer and controls
                    timerControlsView
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupSession()
        }
        .sheet(isPresented: $showSettings) {
            MeditationSettingsView()
        }
        .sheet(isPresented: $isSessionComplete) {
            SessionCompleteView(
                meditationType: meditationType,
                actualDuration: meditationTimer.totalDuration - meditationTimer.timeRemaining
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                appCoordinator.navigateBack()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text(meditationType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let currentPhase = meditationTimer.currentPhase {
                    Text(currentPhase.instruction)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.3), value: currentPhase.instruction)
                }
            }
            
            Spacer()
            
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Breathing Guide View
    private func breathingGuideView(geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.6
        
        return ZStack {
            // Breathing circle
            BreathingCircleView(
                progress: meditationTimer.phaseProgress,
                phase: meditationTimer.currentPhase,
                size: size,
                colorTheme: meditationTimer.settings.visualSettings.colorTheme
            )
            
            // Center content
            VStack(spacing: 16) {
                // Current phase instruction
                if let currentPhase = meditationTimer.currentPhase {
                    Text(currentPhase.instruction)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .animation(.easeInOut(duration: 0.3), value: currentPhase.instruction)
                }
                
                // Cycle count
                if meditationTimer.cycleCount > 0 {
                    Text("Cycle \(meditationTimer.cycleCount + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Timer Controls View
    private var timerControlsView: some View {
        VStack(spacing: 20) {
            // Progress bar
            ProgressView(value: meditationTimer.sessionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(y: 2)
            
            // Time display
            HStack {
                VStack(alignment: .leading) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(meditationTimer.formattedTimeRemaining())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Elapsed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(meditationTimer.formattedElapsedTime())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
            
            // Control buttons
            HStack(spacing: 40) {
                // Stop button
                Button(action: {
                    Task {
                        await stopSession()
                    }
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .frame(width: 60, height: 60)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Play/Pause button
                Button(action: {
                    Task {
                        await togglePlayPause()
                    }
                }) {
                    Image(systemName: meditationTimer.isRunning && !meditationTimer.isPaused ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .scaleEffect(meditationTimer.isRunning ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: meditationTimer.isRunning)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupSession() {
        // Track session start
        AnalyticsManager.shared.track(.screenViewed("meditation_session_\(meditationType.rawValue)"))
    }
    
    private func togglePlayPause() async {
        if meditationTimer.isRunning && !meditationTimer.isPaused {
            await meditationTimer.pause()
        } else if meditationTimer.isPaused {
            await meditationTimer.resume()
        } else {
            await meditationTimer.start()
        }
    }
    
    private func stopSession() async {
        await meditationTimer.stop()
        isSessionComplete = true
    }
}

// MARK: - Breathing Circle View
struct BreathingCircleView: View {
    let progress: Double
    let phase: BreathingPhase?
    let size: CGFloat
    let colorTheme: ColorTheme
    
    private var circleScale: CGFloat {
        switch phase?.type {
        case .inhale:
            return 0.6 + (0.4 * progress)
        case .hold:
            return 1.0
        case .exhale:
            return 1.0 - (0.4 * progress)
        case .pause:
            return 0.6
        default:
            return 0.8
        }
    }
    
    private var circleColor: Color {
        switch colorTheme {
        case .calm:
            return .blue
        case .nature:
            return .green
        case .sunset:
            return .orange
        case .ocean:
            return .teal
        case .minimal:
            return .gray
        }
    }
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(circleColor.opacity(0.2), lineWidth: 2)
                .frame(width: size, height: size)
            
            // Breathing circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            circleColor.opacity(0.6),
                            circleColor.opacity(0.2)
                        ]),
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size * circleScale, height: size * circleScale)
                .animation(
                    .easeInOut(duration: phase?.duration != nil ? TimeInterval(phase!.duration) : 1.0),
                    value: circleScale
                )
            
            // Phase indicator dots
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(circleColor.opacity(getCurrentPhaseIndex() == index ? 1.0 : 0.3))
                    .frame(width: 8, height: 8)
                    .offset(y: -size * 0.6)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .animation(.easeInOut(duration: 0.3), value: getCurrentPhaseIndex())
            }
        }
    }
    
    private func getCurrentPhaseIndex() -> Int {
        switch phase?.type {
        case .inhale: return 0
        case .hold: return 1
        case .exhale: return 2
        case .pause: return 3
        default: return 0
        }
    }
}

// MARK: - Background View
struct BackgroundView: View {
    let colorTheme: ColorTheme
    
    private var backgroundColor: Color {
        switch colorTheme {
        case .calm:
            return Color.blue.opacity(0.05)
        case .nature:
            return Color.green.opacity(0.05)
        case .sunset:
            return Color.orange.opacity(0.05)
        case .ocean:
            return Color.teal.opacity(0.05)
        case .minimal:
            return Color.gray.opacity(0.03)
        }
    }
    
    var body: some View {
        backgroundColor
            .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    MeditationSessionView(meditationType: .boxBreathing)
        .environmentObject(AppDependencies())
        .environmentObject(AppCoordinator())
}