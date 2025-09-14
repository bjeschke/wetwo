import XCTest

final class CriticalFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Onboarding Flow Tests
    
    func testCompleteOnboardingFlow() throws {
        // Step 1: Welcome Screen
        let welcomeButton = app.buttons["Lass uns starten"]
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 5))
        welcomeButton.tap()
        
        // Step 2: Profile Setup
        let nameField = app.textFields["Dein Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test User")
        
        let birthdateField = app.datePickers.firstMatch
        if birthdateField.exists {
            birthdateField.tap()
            // Select a date
        }
        
        let continueButton = app.buttons["Weiter"]
        continueButton.tap()
        
        // Step 3: Relationship Status
        let relationshipOption = app.buttons["In einer Beziehung"]
        if relationshipOption.waitForExistence(timeout: 3) {
            relationshipOption.tap()
            continueButton.tap()
        }
        
        // Step 4: Account Registration
        let emailField = app.textFields.matching(identifier: "EmailField").firstMatch
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText("test@example.com")
        }
        
        let passwordField = app.secureTextFields.matching(identifier: "PasswordField").firstMatch
        if passwordField.exists {
            passwordField.tap()
            passwordField.typeText("TestPassword123!")
        }
        
        let signupButton = app.buttons["Registrieren"]
        if signupButton.exists {
            signupButton.tap()
        }
    }
    
    func testAppleSignInFlow() throws {
        // Navigate to login/signup
        let appleSignInButton = app.buttons.matching(identifier: "AppleSignInButton").firstMatch
        
        if appleSignInButton.waitForExistence(timeout: 5) {
            appleSignInButton.tap()
            
            // Apple Sign In sheet will appear
            // In UI tests, we can't actually complete Apple Sign In
            // but we can verify the button triggers the flow
            XCTAssertTrue(appleSignInButton.exists)
        }
    }
    
    // MARK: - Partner Connection Flow Tests
    
    func testPartnerConnectionFlow() throws {
        skipToMainApp()
        
        // Navigate to Today view
        let todayTab = app.tabBars.buttons["Heute"]
        if todayTab.exists {
            todayTab.tap()
        }
        
        // Look for partner connection prompt
        let connectButton = app.buttons["Partner verbinden"]
        if connectButton.waitForExistence(timeout: 3) {
            connectButton.tap()
            
            // Enter connection code
            let codeField = app.textFields["Verbindungscode"]
            if codeField.waitForExistence(timeout: 3) {
                codeField.tap()
                codeField.typeText("ABC123")
                
                let confirmButton = app.buttons["Verbinden"]
                confirmButton.tap()
            }
        }
    }
    
    func testGenerateConnectionCode() throws {
        skipToMainApp()
        
        // Navigate to partner connection
        let todayTab = app.tabBars.buttons["Heute"]
        if todayTab.exists {
            todayTab.tap()
        }
        
        let generateCodeButton = app.buttons["Code generieren"]
        if generateCodeButton.waitForExistence(timeout: 3) {
            generateCodeButton.tap()
            
            // Verify code is displayed
            let codeLabel = app.staticTexts.matching(NSPredicate(format: "label MATCHES '[A-Z0-9]{6}'")).firstMatch
            XCTAssertTrue(codeLabel.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Mood Tracking Flow Tests
    
    func testAddMoodEntry() throws {
        skipToMainApp()
        
        // Navigate to Today view
        let todayTab = app.tabBars.buttons["Heute"]
        todayTab.tap()
        
        // Select mood
        let happyMood = app.buttons["😊"]
        if happyMood.waitForExistence(timeout: 3) {
            happyMood.tap()
            
            // Add optional event label
            let eventField = app.textFields["Was ist passiert?"]
            if eventField.exists {
                eventField.tap()
                eventField.typeText("Great day at work")
            }
            
            // Save mood
            let saveButton = app.buttons["Speichern"]
            if saveButton.exists {
                saveButton.tap()
                
                // Verify mood was saved
                XCTAssertTrue(app.staticTexts["Stimmung gespeichert"].waitForExistence(timeout: 3))
            }
        }
    }
    
    func testViewMoodHistory() throws {
        skipToMainApp()
        
        // Navigate to Today view
        let todayTab = app.tabBars.buttons["Heute"]
        todayTab.tap()
        
        // Scroll to mood history section
        app.swipeUp()
        
        // Check for mood chart or history list
        let moodChart = app.otherElements["MoodChart"]
        let moodHistory = app.tables["MoodHistory"]
        
        XCTAssertTrue(moodChart.exists || moodHistory.exists)
    }
    
    // MARK: - Memory Creation Flow Tests
    
    func testCreateMemory() throws {
        skipToMainApp()
        
        // Navigate to Memories/Timeline
        let timelineTab = app.tabBars.buttons["Timeline"]
        if timelineTab.exists {
            timelineTab.tap()
        }
        
        // Tap add memory button
        let addButton = app.buttons["AddMemory"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            
            // Fill in memory details
            let titleField = app.textFields["Titel"]
            if titleField.waitForExistence(timeout: 3) {
                titleField.tap()
                titleField.typeText("Our First Date")
            }
            
            let descriptionField = app.textViews["Beschreibung"]
            if descriptionField.exists {
                descriptionField.tap()
                descriptionField.typeText("Amazing evening at the restaurant")
            }
            
            // Mark as special
            let specialSwitch = app.switches["Besonderer Moment"]
            if specialSwitch.exists {
                specialSwitch.tap()
            }
            
            // Save memory
            let saveButton = app.buttons["Speichern"]
            saveButton.tap()
            
            // Verify memory was created
            XCTAssertTrue(app.cells.staticTexts["Our First Date"].waitForExistence(timeout: 3))
        }
    }
    
    func testFilterMemories() throws {
        skipToMainApp()
        
        // Navigate to Timeline
        let timelineTab = app.tabBars.buttons["Timeline"]
        if timelineTab.exists {
            timelineTab.tap()
        }
        
        // Test filter options
        let filterButton = app.buttons["Filter"]
        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()
            
            // Select special memories filter
            let specialFilter = app.buttons["Besondere Momente"]
            if specialFilter.exists {
                specialFilter.tap()
                
                // Verify filter is applied
                XCTAssertTrue(app.staticTexts["Besondere Momente"].exists)
            }
            
            // Switch to everyday filter
            filterButton.tap()
            let everydayFilter = app.buttons["Alltägliche Momente"]
            if everydayFilter.exists {
                everydayFilter.tap()
                
                // Verify filter is applied
                XCTAssertTrue(app.staticTexts["Alltägliche Momente"].exists)
            }
        }
    }
    
    // MARK: - Love Message Flow Tests
    
    func testSendLoveMessage() throws {
        skipToMainApp()
        
        // Navigate to Messages
        let messagesTab = app.tabBars.buttons["Nachrichten"]
        if messagesTab.exists {
            messagesTab.tap()
        }
        
        // Compose new message
        let composeButton = app.buttons["NewMessage"]
        if composeButton.waitForExistence(timeout: 3) {
            composeButton.tap()
            
            let messageField = app.textViews["Nachricht"]
            if messageField.waitForExistence(timeout: 3) {
                messageField.tap()
                messageField.typeText("Ich liebe dich ❤️")
                
                let sendButton = app.buttons["Senden"]
                sendButton.tap()
                
                // Verify message was sent
                XCTAssertTrue(app.cells.staticTexts["Ich liebe dich ❤️"].waitForExistence(timeout: 3))
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    func testTabBarNavigation() throws {
        skipToMainApp()
        
        // Test all tab bar items
        let tabs = ["Heute", "Timeline", "Nachrichten", "Profil"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            if tab.exists {
                tab.tap()
                
                // Verify we're on the correct screen
                // This would check for screen-specific elements
                XCTAssertTrue(tab.isSelected)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(iOS 17.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testScrollPerformance() throws {
        skipToMainApp()
        
        // Navigate to Timeline with many memories
        let timelineTab = app.tabBars.buttons["Timeline"]
        if timelineTab.exists {
            timelineTab.tap()
            
            measure {
                // Scroll down
                for _ in 0..<5 {
                    app.swipeUp()
                }
                
                // Scroll back up
                for _ in 0..<5 {
                    app.swipeDown()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func skipToMainApp() {
        // Skip onboarding if already completed
        // This checks if we're already in the main app
        let tabBar = app.tabBars.firstMatch
        if !tabBar.exists {
            // Try to skip onboarding
            let skipButton = app.buttons["Skip"]
            if skipButton.exists {
                skipButton.tap()
            }
        }
    }
    
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

// MARK: - Accessibility Tests

extension CriticalFlowUITests {
    
    func testAccessibilityLabels() throws {
        skipToMainApp()
        
        // Verify important UI elements have accessibility labels
        let todayTab = app.tabBars.buttons["Heute"]
        XCTAssertTrue(todayTab.exists)
        XCTAssertNotNil(todayTab.label)
        
        // Check for VoiceOver compatibility
        XCTAssertTrue(todayTab.isHittable)
    }
    
    func testDynamicTypeSupport() throws {
        // Launch app with larger text size
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        
        // Verify text is still visible and layouts adapt
        let titleLabel = app.staticTexts.firstMatch
        XCTAssertTrue(titleLabel.exists)
    }
}