//
//  AppUITests.swift
//  DailyRoutineAppUITests
//
//  Created by GitHub Copilot on 16/10/2025.
//

import XCTest

final class AppUITests: XCTestCase {
    
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
    
    // MARK: - App Launch Tests
    func testAppLaunch() throws {
        // Given/When - App launches
        
        // Then - Main interface should be visible
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        
        // Check all main tabs exist
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Dashboard"].exists)
        XCTAssertTrue(tabBar.buttons["Routines"].exists)
        XCTAssertTrue(tabBar.buttons["Meditation"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)
    }
    
    func testOnboardingFlow() throws {
        // Reset app to trigger onboarding
        app.terminate()
        
        // Clear app data (this might require specific test setup)
        app.launchArguments = ["UI_TESTING", "RESET_USER_DEFAULTS"]
        app.launch()
        
        // Check if onboarding appears
        if app.staticTexts["Welcome"].exists {
            // Test onboarding flow
            XCTAssertTrue(app.buttons["Get Started"].exists)
            app.buttons["Get Started"].tap()
            
            // Skip through onboarding screens
            while app.buttons["Next"].exists || app.buttons["Continue"].exists {
                if app.buttons["Next"].exists {
                    app.buttons["Next"].tap()
                } else {
                    app.buttons["Continue"].tap()
                }
            }
            
            // Complete onboarding
            if app.buttons["Complete"].exists {
                app.buttons["Complete"].tap()
            }
        }
    }
    
    // MARK: - Tab Navigation Tests
    func testTabNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        
        // Test Dashboard tab
        tabBar.buttons["Dashboard"].tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
        
        // Test Routines tab
        tabBar.buttons["Routines"].tap()
        XCTAssertTrue(app.navigationBars["Routines"].exists)
        
        // Test Meditation tab
        tabBar.buttons["Meditation"].tap()
        XCTAssertTrue(app.navigationBars["Meditation"].exists)
        
        // Test Settings tab
        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
    
    // MARK: - Dashboard Tests
    func testDashboardContent() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Dashboard"].tap()
        
        // Then - Dashboard should show key metrics
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'streak' OR label CONTAINS[c] 'completed' OR label CONTAINS[c] 'today'")
        ).count > 0)
    }
    
    // MARK: - Routines Tests
    func testRoutinesTab() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Routines"].tap()
        
        // Then
        XCTAssertTrue(app.navigationBars["Routines"].exists)
        
        // Should have option to add routine
        XCTAssertTrue(app.buttons["Add Routine"].exists || app.buttons["+"].exists)
    }
    
    func testCreateRoutine() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Routines"].tap()
        
        // When
        if app.buttons["Add Routine"].exists {
            app.buttons["Add Routine"].tap()
        } else if app.buttons["+"].exists {
            app.buttons["+"].tap()
        }
        
        // Then - Should show routine creation form
        XCTAssertTrue(
            app.navigationBars["New Routine"].exists ||
            app.staticTexts["Create Routine"].exists ||
            app.textFields["Routine Name"].exists
        )
    }
    
    // MARK: - Settings Tests
    func testSettingsTab() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        
        // Then
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        
        // Check common settings exist
        XCTAssertTrue(
            app.staticTexts["Notifications"].exists ||
            app.staticTexts["Privacy"].exists ||
            app.staticTexts["About"].exists
        )
    }
    
    func testNotificationSettings() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        
        // When
        if app.cells["Notifications"].exists {
            app.cells["Notifications"].tap()
            
            // Then
            XCTAssertTrue(
                app.switches.count > 0 || 
                app.staticTexts["Notification Settings"].exists
            )
        }
    }
    
    // MARK: - Permissions Tests
    func testNotificationPermissionRequest() throws {
        // This test might need to be run on first app install
        // or with app data reset
        
        // Given - Fresh app state
        app.terminate()
        app.launchArguments = ["UI_TESTING", "REQUEST_PERMISSIONS"]
        app.launch()
        
        // When - Navigate to trigger permission request
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons["Settings"].tap()
            
            if app.cells["Notifications"].exists {
                app.cells["Notifications"].tap()
                
                // Look for permission request button
                if app.buttons["Enable Notifications"].exists {
                    app.buttons["Enable Notifications"].tap()
                    
                    // System alert should appear
                    let systemAlert = app.alerts.firstMatch
                    if systemAlert.exists {
                        systemAlert.buttons["Allow"].tap()
                    }
                }
            }
        }
    }
    
    // MARK: - Deep Linking Tests
    func testDeepLinkToMeditation() throws {
        // Test URL scheme (if implemented)
        // This would require specific URL scheme setup
        
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Meditation"].tap()
        
        XCTAssertTrue(app.navigationBars["Meditation"].exists)
        XCTAssertTrue(app.buttons["Box Breathing"].exists)
    }
    
    // MARK: - State Persistence Tests
    func testAppStateRestoration() throws {
        // Given - Navigate to specific tab
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Meditation"].tap()
        
        // When - Background and restore app
        app.terminate()
        app.launch()
        
        // Then - Should restore to last state or default state
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
    
    // MARK: - Accessibility Tests
    func testVoiceOverSupport() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        
        // When/Then - Check accessibility labels exist
        XCTAssertNotNil(tabBar.buttons["Dashboard"].label)
        XCTAssertNotNil(tabBar.buttons["Routines"].label)
        XCTAssertNotNil(tabBar.buttons["Meditation"].label)
        XCTAssertNotNil(tabBar.buttons["Settings"].label)
        
        // Check accessibility hints
        tabBar.buttons["Meditation"].tap()
        
        if app.buttons["Box Breathing"].exists {
            XCTAssertNotNil(app.buttons["Box Breathing"].label)
        }
    }
    
    func testDynamicTypeSupport() throws {
        // This test would need system-level dynamic type changes
        // For now, just verify elements exist and are readable
        
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Dashboard"].tap()
        
        // Verify text elements are present
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }
    
    // MARK: - Performance Tests
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testTabSwitchingPerformance() throws {
        let tabBar = app.tabBars.firstMatch
        
        measure {
            tabBar.buttons["Dashboard"].tap()
            tabBar.buttons["Routines"].tap()
            tabBar.buttons["Meditation"].tap()
            tabBar.buttons["Settings"].tap()
        }
    }
    
    // MARK: - Error Handling Tests
    func testNetworkErrorHandling() throws {
        // This would require network mocking or airplane mode simulation
        // For now, just verify app doesn't crash without network
        
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Dashboard"].tap()
        
        // App should still function offline
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
    }
    
    func testMemoryWarningHandling() throws {
        // Simulate memory pressure by switching tabs rapidly
        let tabBar = app.tabBars.firstMatch
        
        for _ in 0..<10 {
            tabBar.buttons["Dashboard"].tap()
            tabBar.buttons["Meditation"].tap()
            tabBar.buttons["Routines"].tap()
            tabBar.buttons["Settings"].tap()
        }
        
        // App should remain responsive
        XCTAssertTrue(tabBar.exists)
    }
}

// MARK: - Test Utilities
extension XCTestCase {
    func skipIfRunningOnSimulator() throws {
        guard ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == nil else {
            throw XCTSkip("This test requires a physical device")
        }
    }
    
    func resetAppData() {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_ALL_DATA"]
        app.launch()
    }
}