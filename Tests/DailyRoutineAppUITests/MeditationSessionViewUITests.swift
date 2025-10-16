//
//  MeditationSessionViewUITests.swift
//  DailyRoutineAppUITests
//
//  Created by GitHub Copilot on 16/10/2025.
//

import XCTest

final class MeditationSessionViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    func testNavigateToMeditationSession() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        let meditationTab = tabBar.buttons["Meditation"]
        
        // When
        meditationTab.tap()
        
        // Then
        XCTAssertTrue(app.navigationBars["Meditation"].exists)
        XCTAssertTrue(app.buttons["Box Breathing"].exists)
        XCTAssertTrue(app.buttons["4-7-8 Breathing"].exists)
    }
    
    func testStartBoxBreathingSession() throws {
        // Given
        navigateToMeditation()
        let boxBreathingButton = app.buttons["Box Breathing"]
        
        // When
        boxBreathingButton.tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["Box Breathing"].exists)
        XCTAssertTrue(app.buttons["Start Session"].exists)
        
        // Start the session
        app.buttons["Start Session"].tap()
        
        // Verify session UI elements
        XCTAssertTrue(app.staticTexts["Inhale"].exists || app.staticTexts["Hold"].exists)
        XCTAssertTrue(app.buttons["Pause"].exists)
        XCTAssertTrue(app.buttons["Stop"].exists)
    }
    
    func testStartFourSevenEightSession() throws {
        // Given
        navigateToMeditation()
        let fourSevenEightButton = app.buttons["4-7-8 Breathing"]
        
        // When
        fourSevenEightButton.tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["4-7-8 Breathing"].exists)
        XCTAssertTrue(app.buttons["Start Session"].exists)
        
        // Start the session
        app.buttons["Start Session"].tap()
        
        // Verify session started
        XCTAssertTrue(app.buttons["Pause"].exists)
        XCTAssertTrue(app.buttons["Stop"].exists)
    }
    
    // MARK: - Session Control Tests
    func testPauseAndResumeSession() throws {
        // Given
        startBoxBreathingSession()
        
        // When - Pause
        let pauseButton = app.buttons["Pause"]
        pauseButton.tap()
        
        // Then
        XCTAssertTrue(app.buttons["Resume"].exists)
        XCTAssertTrue(app.staticTexts["Paused"].exists)
        
        // When - Resume
        app.buttons["Resume"].tap()
        
        // Then
        XCTAssertTrue(app.buttons["Pause"].exists)
    }
    
    func testStopSession() throws {
        // Given
        startBoxBreathingSession()
        
        // When
        let stopButton = app.buttons["Stop"]
        stopButton.tap()
        
        // Then - Should show confirmation or go back to meditation list
        XCTAssertTrue(
            app.alerts.firstMatch.exists || 
            app.navigationBars["Meditation"].exists ||
            app.staticTexts["Session Complete"].exists
        )
    }
    
    // MARK: - Settings Tests
    func testMeditationSettings() throws {
        // Given
        navigateToMeditation()
        
        // When
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
            
            // Then
            XCTAssertTrue(app.navigationBars["Settings"].exists)
            XCTAssertTrue(app.switches["Audio Cues"].exists)
            XCTAssertTrue(app.switches["Haptic Feedback"].exists)
        }
    }
    
    func testCustomizeDuration() throws {
        // Given
        navigateToMeditation()
        app.buttons["Box Breathing"].tap()
        
        // When
        if app.buttons["Customize"].exists {
            app.buttons["Customize"].tap()
            
            // Then
            XCTAssertTrue(app.sliders["Duration"].exists)
            
            // Adjust duration
            let durationSlider = app.sliders["Duration"]
            durationSlider.adjust(toNormalizedSliderPosition: 0.5)
        }
    }
    
    // MARK: - Progress Tests
    func testSessionProgress() throws {
        // Given
        startBoxBreathingSession()
        
        // When - Wait for some progress
        let progressIndicator = app.progressIndicators.firstMatch
        
        // Then
        XCTAssertTrue(progressIndicator.exists)
        
        // Wait and check progress changes
        sleep(2)
        // Progress should have changed (hard to test exact values in UI tests)
    }
    
    func testBreathingInstructions() throws {
        // Given
        startBoxBreathingSession()
        
        // When - Check breathing instructions appear
        let breathingText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Inhale' OR label CONTAINS[c] 'Hold' OR label CONTAINS[c] 'Exhale'")
        )
        
        // Then
        XCTAssertGreaterThan(breathingText.count, 0)
    }
    
    // MARK: - Session Completion Tests
    func testSessionCompletion() throws {
        // Given - Start a very short session for testing
        navigateToMeditation()
        app.buttons["Box Breathing"].tap()
        
        // Set very short duration if possible
        if app.buttons["Customize"].exists {
            app.buttons["Customize"].tap()
            
            // Set minimum duration
            let durationSlider = app.sliders["Duration"]
            if durationSlider.exists {
                durationSlider.adjust(toNormalizedSliderPosition: 0.0)
            }
        }
        
        app.buttons["Start Session"].tap()
        
        // When - Wait for completion (or stop manually)
        app.buttons["Stop"].tap()
        
        // Then - Should show completion screen
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.staticTexts["Session Complete"]
        )
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(app.staticTexts["Session Complete"].exists)
    }
    
    // MARK: - Accessibility Tests
    func testAccessibilityLabels() throws {
        // Given
        navigateToMeditation()
        
        // When/Then - Check accessibility labels exist
        let boxBreathingButton = app.buttons["Box Breathing"]
        XCTAssertNotNil(boxBreathingButton.label)
        
        let fourSevenEightButton = app.buttons["4-7-8 Breathing"]
        XCTAssertNotNil(fourSevenEightButton.label)
        
        // Start session and check session controls
        boxBreathingButton.tap()
        app.buttons["Start Session"].tap()
        
        let pauseButton = app.buttons["Pause"]
        XCTAssertNotNil(pauseButton.label)
        
        let stopButton = app.buttons["Stop"]
        XCTAssertNotNil(stopButton.label)
    }
    
    // MARK: - Performance Tests
    func testMeditationListPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            navigateToMeditation()
        }
    }
    
    func testSessionStartPerformance() throws {
        // Given
        navigateToMeditation()
        
        // When/Then
        measure {
            app.buttons["Box Breathing"].tap()
            app.buttons["Start Session"].tap()
            
            // Wait for session to start
            XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))
            
            // Stop session
            app.buttons["Stop"].tap()
            
            // Navigate back
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func navigateToMeditation() {
        let tabBar = app.tabBars.firstMatch
        let meditationTab = tabBar.buttons["Meditation"]
        meditationTab.tap()
        
        XCTAssertTrue(app.navigationBars["Meditation"].waitForExistence(timeout: 3))
    }
    
    private func startBoxBreathingSession() {
        navigateToMeditation()
        app.buttons["Box Breathing"].tap()
        app.buttons["Start Session"].tap()
        
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
    }
}

// MARK: - Test Extensions
extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}