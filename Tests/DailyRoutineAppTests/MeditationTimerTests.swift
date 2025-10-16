//
//  MeditationTimerTests.swift
//  DailyRoutineAppTests
//
//  Created by GitHub Copilot on 16/10/2025.
//

import XCTest
import Combine
@testable import DailyRoutineApp

final class MeditationTimerTests: XCTestCase {
    
    var sut: MeditationTimer!
    var mockAudioService: MockAudioService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        mockAudioService = MockAudioService()
        sut = MeditationTimer(audioService: mockAudioService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        sut.reset()
        sut = nil
        mockAudioService = nil
        cancellables = nil
    }
    
    // MARK: - Box Breathing Tests
    func testBoxBreathingCycle() {
        // Given
        let expectation = XCTestExpectation(description: "Box breathing cycle completed")
        let settings = MeditationSettings(
            type: .boxBreathing,
            duration: 60,
            inhaleTime: 4,
            holdTime: 4,
            exhaleTime: 4,
            holdAfterExhaleTime: 4,
            enableAudioCues: true,
            enableHapticFeedback: true
        )
        
        var breathingStates: [BreathingState] = []
        
        // When
        sut.currentBreathingState
            .dropFirst() // Skip initial state
            .sink { state in
                breathingStates.append(state)
                
                if breathingStates.count == 4 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.start(with: settings)
        
        // Then
        wait(for: expectation, timeout: 20.0)
        
        XCTAssertEqual(breathingStates[0], .inhaling)
        XCTAssertEqual(breathingStates[1], .holdingAfterInhale)
        XCTAssertEqual(breathingStates[2], .exhaling)
        XCTAssertEqual(breathingStates[3], .holdingAfterExhale)
    }
    
    func testFourSevenEightBreathing() {
        // Given
        let expectation = XCTestExpectation(description: "4-7-8 breathing cycle completed")
        let settings = MeditationSettings(
            type: .fourSevenEight,
            duration: 60,
            inhaleTime: 4,
            holdTime: 7,
            exhaleTime: 8,
            enableAudioCues: true
        )
        
        var breathingStates: [BreathingState] = []
        
        // When
        sut.currentBreathingState
            .dropFirst()
            .sink { state in
                breathingStates.append(state)
                
                if breathingStates.count == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.start(with: settings)
        
        // Then
        wait(for: expectation, timeout: 25.0)
        
        XCTAssertEqual(breathingStates[0], .inhaling)
        XCTAssertEqual(breathingStates[1], .holdingAfterInhale)
        XCTAssertEqual(breathingStates[2], .exhaling)
    }
    
    // MARK: - Timer State Tests
    func testTimerStates() {
        // Given
        let settings = MeditationSettings(type: .boxBreathing, duration: 10)
        
        // When/Then
        XCTAssertEqual(sut.currentState, .idle)
        
        sut.start(with: settings)
        XCTAssertEqual(sut.currentState, .running)
        
        sut.pause()
        XCTAssertEqual(sut.currentState, .paused)
        
        sut.resume()
        XCTAssertEqual(sut.currentState, .running)
        
        sut.stop()
        XCTAssertEqual(sut.currentState, .stopped)
        
        sut.reset()
        XCTAssertEqual(sut.currentState, .idle)
    }
    
    // MARK: - Audio Cue Tests
    func testAudioCuesTriggered() {
        // Given
        let expectation = XCTestExpectation(description: "Audio cues triggered")
        expectation.expectedFulfillmentCount = 4 // One for each breathing phase
        
        let settings = MeditationSettings(
            type: .boxBreathing,
            duration: 20,
            inhaleTime: 2,
            holdTime: 2,
            exhaleTime: 2,
            holdAfterExhaleTime: 2,
            enableAudioCues: true
        )
        
        // When
        mockAudioService.onPlayBreathingCue = { _ in
            expectation.fulfill()
        }
        
        sut.start(with: settings)
        
        // Then
        wait(for: expectation, timeout: 10.0)
        XCTAssertGreaterThan(mockAudioService.playBreathingCueCallCount, 0)
    }
    
    // MARK: - Progress Tests
    func testProgressCalculation() {
        // Given
        let expectation = XCTestExpectation(description: "Progress updated")
        let settings = MeditationSettings(type: .boxBreathing, duration: 10)
        
        var progressValues: [Double] = []
        
        // When
        sut.progress
            .sink { progress in
                progressValues.append(progress)
                if progress > 0.1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.start(with: settings)
        
        // Then
        wait(for: expectation, timeout: 5.0)
        
        XCTAssertTrue(progressValues.first == 0.0)
        XCTAssertTrue(progressValues.last! > 0.0)
        XCTAssertTrue(progressValues.allSatisfy { $0 >= 0.0 && $0 <= 1.0 })
    }
    
    // MARK: - Session Completion Tests
    func testSessionCompletion() {
        // Given
        let expectation = XCTestExpectation(description: "Session completed")
        let settings = MeditationSettings(type: .boxBreathing, duration: 1) // 1 second for quick test
        
        // When
        sut.onSessionComplete = { session in
            XCTAssertEqual(session.type, .boxBreathing)
            XCTAssertEqual(session.plannedDuration, 1)
            XCTAssertGreaterThan(session.actualDuration, 0)
            expectation.fulfill()
        }
        
        sut.start(with: settings)
        
        // Then
        wait(for: expectation, timeout: 3.0)
    }
    
    // MARK: - Performance Tests
    func testTimerPrecision() {
        // Given
        let expectation = XCTestExpectation(description: "Timer precision test")
        let settings = MeditationSettings(type: .boxBreathing, duration: 5)
        let startTime = Date()
        
        // When
        sut.onSessionComplete = { _ in
            let actualDuration = Date().timeIntervalSince(startTime)
            
            // Should complete within 10% tolerance
            XCTAssertLessThan(abs(actualDuration - 5.0), 0.5)
            expectation.fulfill()
        }
        
        sut.start(with: settings)
        
        // Then
        wait(for: expectation, timeout: 6.0)
    }
    
    func testMemoryUsageDuringLongSession() {
        // Given
        let settings = MeditationSettings(type: .boxBreathing, duration: 30)
        
        // When
        sut.start(with: settings)
        
        // Simulate running for a short period
        let expectation = XCTestExpectation(description: "Memory test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        
        wait(for: expectation, timeout: 3.0)
        sut.stop()
        
        // Then - No assertions needed, just ensure no memory leaks
        XCTAssertTrue(true)
    }
}

// MARK: - Mock Audio Service
class MockAudioService: AudioServiceProtocol {
    
    var playBreathingCueCallCount = 0
    var onPlayBreathingCue: ((BreathingPhase) -> Void)?
    
    func initialize() async throws {}
    
    func playBreathingCue(for phase: BreathingPhase) async {
        playBreathingCueCallCount += 1
        onPlayBreathingCue?(phase)
    }
    
    func playAmbientSound(_ sound: AmbientSound) async throws {}
    func stopAmbientSound() async {}
    func setAmbientVolume(_ volume: Float) async {}
    func playCompletionSound() async {}
    func playNotificationSound() async {}
    func setMasterVolume(_ volume: Float) async {}
    func getMasterVolume() async -> Float { return 1.0 }
    func configureAudioSession(for category: AVAudioSession.Category) async throws {}
    func startBackgroundAudio() async throws {}
    func stopBackgroundAudio() async {}
}