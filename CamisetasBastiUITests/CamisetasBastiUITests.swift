import XCTest

final class CamisetasBastiUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Critical Flow
    
    func testCriticalFlowSplashToPaint() {
        // 1. Splash screen visible
        XCTAssertTrue(app.staticTexts["CAMISETAS"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["BASTI"].exists)
        
        // 2. Tap splash to dismiss
        app.tap()
        
        // 3. Home screen
        XCTAssertTrue(app.buttons["JUGAR 🎨"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["ÁLBUM 📘"].exists)
        
        // 4. Tap JUGAR
        app.buttons["JUGAR 🎨"].tap()
        
        // 5. Countries screen
        XCTAssertTrue(app.staticTexts["ELIGE UNA SECCIÓN"].waitForExistence(timeout: 2))
        
        // Tap first country (Argentina)
        let argentinaCard = app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "ARGENTINA"))
        XCTAssertTrue(argentinaCard.waitForExistence(timeout: 2))
        argentinaCard.tap()
        
        // 6. Teams screen
        XCTAssertTrue(app.staticTexts["ARGENTINA"].waitForExistence(timeout: 2))
        
        // Tap first team
        let firstTeam = app.buttons.element(boundBy: 0)
        XCTAssertTrue(firstTeam.waitForExistence(timeout: 2))
        firstTeam.tap()
        
        // 7. Team detail
        XCTAssertTrue(app.staticTexts["LOCAL"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["VISITANTE"].exists)
        
        // Tap LOCAL to open paint
        app.buttons["LOCAL"].tap()
        
        // 8. Paint screen
        XCTAssertTrue(app.staticTexts["DESLIZÁ TU DEDO PARA PINTAR"].waitForExistence(timeout: 2))
        
        // Paint aggressively to complete
        let paintArea = app.otherElements.element(boundBy: 0)
        let start = paintArea.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let end = paintArea.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        
        // Draw multiple strokes
        for i in 0..<5 {
            let offset = CGVector(dx: Double(i) * 0.1, dy: Double(i) * 0.1)
            let from = paintArea.coordinate(withNormalizedOffset: CGVector(dx: 0.2 + offset.dx, dy: 0.2 + offset.dy))
            let to = paintArea.coordinate(withNormalizedOffset: CGVector(dx: 0.8 - offset.dx, dy: 0.8 - offset.dy))
            from.press(forDuration: 0.1, thenDragTo: to)
        }
        
        // Wait for completion (ficha screen)
        XCTAssertTrue(app.staticTexts["¡GENIAL!"].waitForExistence(timeout: 5))
        
        // 9. Ficha screen
        XCTAssertTrue(app.staticTexts["DESCUBRISTE LA CAMISETA"].exists)
        
        // Tap SEGUIR to finish
        app.buttons["SEGUIR 👍"].tap()
        
        // Should return to team detail
        XCTAssertTrue(app.staticTexts["LOCAL"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Navigation back
    
    func testBackButtonNavigation() {
        // Dismiss splash
        app.tap()
        
        // Go to JUGAR
        app.buttons["JUGAR 🎨"].tap()
        XCTAssertTrue(app.staticTexts["ELIGE UNA SECCIÓN"].waitForExistence(timeout: 2))
        
        // Back to home
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["JUGAR 🎨"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Album screen
    
    func testAlbumScreenLoads() {
        // Dismiss splash
        app.tap()
        
        // Tap ÁLBUM
        app.buttons["ÁLBUM 📘"].tap()
        
        // Album header visible
        XCTAssertTrue(app.staticTexts["ÁLBUM"].waitForExistence(timeout: 2))
        
        // Country tabs visible
        XCTAssertTrue(app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "ARGENTINA")).exists)
    }
    
    // MARK: - Tournament match playback

    @MainActor
    func testArgentinaTournamentShowsAllThirtyLPFTeams() {
        XCUIDevice.shared.orientation = .landscapeLeft

        let splashPrompt = app.staticTexts["TOCA PARA JUGAR"]
        XCTAssertTrue(splashPrompt.waitForExistence(timeout: 10))
        splashPrompt.tap()

        let tournamentButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "SIMULAR TORNEO")
        ).firstMatch
        XCTAssertTrue(tournamentButton.waitForExistence(timeout: 10))
        tournamentButton.tap()

        let leaguePicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "MUNDIAL 2026")
        ).firstMatch
        XCTAssertTrue(leaguePicker.waitForExistence(timeout: 10))
        leaguePicker.tap()

        let argentinaOption = app.buttons["ARGENTINA"]
        XCTAssertTrue(argentinaOption.waitForExistence(timeout: 5))
        argentinaOption.tap()

        XCTAssertTrue(app.staticTexts["RONDA DE 32"].firstMatch.waitForExistence(timeout: 10))
        let expectedIds = [
            "aldosivi", "argentinos", "atletico_tucuman", "banfield", "barracas_central",
            "belgrano", "boca", "central_cordoba", "defensa_justicia", "riestra",
            "estudiantes_rc", "estu", "gimnasia_lp", "gimnasia_mendoza", "hura",
            "inde", "independiente_rivadavia", "instituto", "lanus", "newells",
            "platense", "racing", "river", "rosa", "sanlo", "sarmiento",
            "talleres", "tigre", "union", "velez"
        ]
        for teamId in expectedIds {
            XCTAssertTrue(app.buttons["tournament.team.\(teamId)"].exists, "Missing \(teamId) from Argentina bracket")
        }

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Liga Argentina - 30 equipos"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testWorldCupMatchPlaysToCompletionAndSavesGroupScore() throws {
        XCUIDevice.shared.orientation = .landscapeLeft

        let splashPrompt = app.staticTexts["TOCA PARA JUGAR"]
        XCTAssertTrue(splashPrompt.waitForExistence(timeout: 10))
        splashPrompt.tap()

        let tournamentButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "SIMULAR TORNEO")
        ).firstMatch
        XCTAssertTrue(tournamentButton.waitForExistence(timeout: 10))
        tournamentButton.tap()

        let worldCupPicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "MUNDIAL 2026")
        ).firstMatch
        XCTAssertTrue(worldCupPicker.waitForExistence(timeout: 10))
        let simulatedMode = app.buttons["Partidos"]
        XCTAssertTrue(simulatedMode.waitForExistence(timeout: 5))
        simulatedMode.tap()

        // The two team names identify one group fixture before and after scoring.
        let fixtureQuery = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "MEX", "RSA")
        )
        let fixture = fixtureQuery.firstMatch
        XCTAssertTrue(fixture.waitForExistence(timeout: 10))
        XCTAssertEqual(fixtureQuery.count, 1)
        XCTAssertTrue(fixture.isEnabled)
        XCTAssertTrue(fixture.label.contains("VS"))
        fixture.tap()
        let startedAt = Date()

        let scoreboard = app.descendants(matching: .any).matching(identifier: "match.scoreboard").firstMatch
        let event = app.descendants(matching: .any).matching(identifier: "match.event").firstMatch
        let close = app.buttons["match.close"]
        XCTAssertTrue(scoreboard.waitForExistence(timeout: 10))
        XCTAssertTrue(event.waitForExistence(timeout: 5))
        XCTAssertFalse(close.exists)

        // Wait on live match state, keeping the real playback speed and duration.
        let secondHalf = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label MATCHES %@", "^Minuto (4[5-9]|[5-8][0-9])\\..*"),
            object: event
        )
        XCTAssertEqual(XCTWaiter.wait(for: [secondHalf], timeout: 75), .completed)
        XCTAssertFalse(close.exists)
        let playingScreenshot = XCTAttachment(screenshot: app.screenshot())
        playingScreenshot.name = "MEX-RSA partido en juego"
        playingScreenshot.lifetime = .keepAlways
        add(playingScreenshot)

        let remainingTimeout = max(1, 130 - Date().timeIntervalSince(startedAt))
        XCTAssertTrue(close.waitForExistence(timeout: remainingTimeout))
        let finalGoals = scoreboard.label.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap(Int.init)
        XCTAssertEqual(finalGoals.count, 2, "Expected both final scores in \(scoreboard.label)")
        let finishedScreenshot = XCTAttachment(screenshot: app.screenshot())
        finishedScreenshot.name = "MEX-RSA resultado final"
        finishedScreenshot.lifetime = .keepAlways
        add(finishedScreenshot)
        close.tap()

        XCTAssertTrue(fixture.waitForExistence(timeout: 10))
        XCTAssertFalse(fixture.isEnabled, "A finished group fixture must not be playable again")
        XCTAssertFalse(fixture.label.contains("VS"))
        let savedGoals = fixture.label.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap(Int.init)
        XCTAssertEqual(savedGoals, finalGoals, "The group fixture must keep the displayed final score")
        XCTAssertFalse(close.exists)
    }

    @MainActor
    func testMatchPlaybackAdvancesAndResumesWithoutBackgroundCatchUp() {
        app.terminate()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchArguments = ["--match-preview"]
        app.launchEnvironment = ["MATCH_PREVIEW_PROGRESS": "0.15"]
        app.launch()
        let event = app.descendants(matching: .any).matching(identifier: "match.event").firstMatch
        XCTAssertTrue(event.waitForExistence(timeout: 10))
        let initial = event.label
        let advances = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", initial), object: event)
        XCTAssertEqual(XCTWaiter.wait(for: [advances], timeout: 5), .completed)
        func minute(_ label: String) -> Int {
            label.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init).first ?? -1
        }
        let before = minute(event.label)
        XCUIDevice.shared.press(.home)
        // This is elapsed background time, not accelerated game time.
        let background = expectation(description: "Background interval")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { background.fulfill() }
        wait(for: [background], timeout: 7)
        app.activate()
        XCTAssertTrue(event.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(minute(event.label) - before, 3, "Background time must not advance the match")
        let resumed = event.label
        let continues = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", resumed), object: event)
        XCTAssertEqual(XCTWaiter.wait(for: [continues], timeout: 5), .completed)
    }

    @MainActor
    func testSetPiecesShowPreparationShotAndOutcomeWithoutEarlyGoals() {
        app.terminate()
        XCUIDevice.shared.orientation = .landscapeLeft
        for kind in ["free-kick", "penalty"] {
            var normalScores: [String] = []
            for reduced in [false, true] {
                for (index, moment) in [kind, "\(kind)-shot", "\(kind)-result"].enumerated() {
                    app.launchArguments = ["--match-preview", "--match-preview-still"]
                        + (reduced ? ["--match-reduce-motion"] : [])
                    app.launchEnvironment = ["MATCH_PREVIEW_MOMENT": moment]
                    app.launch()
                    let event = app.descendants(matching: .any).matching(identifier: "match.event").firstMatch
                    let score = app.descendants(matching: .any).matching(identifier: "match.scoreboard").firstMatch
                    XCTAssertTrue(event.waitForExistence(timeout: 10))
                    XCTAssertTrue(score.exists)
                    if index == 0 {
                        XCTAssertTrue(event.label.contains(kind == "penalty" ? "PENAL" : "BARRERA"), event.label)
                    } else if index == 1 {
                        XCTAssertTrue(event.label.contains("PATEA"), event.label)
                        XCTAssertEqual(score.label, normalScores[0], "No goal before the ball arrives")
                    } else {
                        XCTAssertTrue(["GOOOL", "ATAJAD", "AFUERA", "BLOQUEA"].contains(where: event.label.contains), event.label)
                    }
                    if reduced {
                        XCTAssertEqual(score.label, normalScores[index], "Reduced Motion must preserve score")
                    } else {
                        normalScores.append(score.label)
                    }
                    let capture = XCTAttachment(screenshot: app.screenshot())
                    capture.name = "\(moment)-\(reduced ? "reduced" : "normal")"
                    capture.lifetime = .keepAlways
                    add(capture)
                    app.terminate()
                }
            }
        }
    }

    @MainActor
    func testShootoutShowsGoalOnlyAtImpactAndCanClose() {
        app.terminate()
        XCUIDevice.shared.orientation = .landscapeLeft
        for moment in ["shootout-before-goal", "shootout-goal", "shootout-finished"] {
            app.launchArguments = ["--match-preview", "--match-preview-still"]
            app.launchEnvironment = ["MATCH_PREVIEW_MOMENT": moment]
            app.launch()
            let event = app.descendants(matching: .any).matching(identifier: "match.event").firstMatch
            XCTAssertTrue(event.waitForExistence(timeout: 10))
            if moment == "shootout-before-goal" {
                XCTAssertTrue(event.label.contains("VIAJA LA PELOTA"), event.label)
                XCTAssertFalse(event.label.contains("GOOOL"))
            } else if moment == "shootout-goal" {
                XCTAssertTrue(event.label.contains("GOOOL"), event.label)
            } else {
                XCTAssertTrue(event.label.contains("FINAL POR PENALES"), event.label)
                XCTAssertTrue(app.buttons["match.close"].exists)
                app.buttons["match.close"].tap()
                XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "SIMULAR TORNEO")).firstMatch.waitForExistence(timeout: 10))
            }
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = moment
            capture.lifetime = .keepAlways
            add(capture)
            app.terminate()
        }
    }

    @MainActor
    func testGoalPresentationAndReducedMotionKeepTheSameScore() {
        app.terminate()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchArguments = ["--match-preview", "--match-preview-still"]
        app.launchEnvironment = ["MATCH_PREVIEW_MOMENT": "before-goal"]
        app.launch()
        let scoreboard = app.descendants(matching: .any).matching(identifier: "match.scoreboard").firstMatch
        let event = app.descendants(matching: .any).matching(identifier: "match.event").firstMatch
        XCTAssertTrue(scoreboard.waitForExistence(timeout: 10))
        XCTAssertTrue(event.waitForExistence(timeout: 5))
        XCTAssertFalse(event.label.contains("GOOOL"))
        let beforeScore = scoreboard.label

        app.terminate()
        app.launchEnvironment = ["MATCH_PREVIEW_MOMENT": "goal"]
        app.launch()
        XCTAssertTrue(event.waitForExistence(timeout: 10))
        XCTAssertTrue(event.label.contains("GOOOL"))
        XCTAssertNotEqual(scoreboard.label, beforeScore)
        let goalScore = scoreboard.label
        let regular = XCTAttachment(screenshot: app.screenshot())
        regular.name = "Gol y festejo - iPad horizontal"
        regular.lifetime = .keepAlways
        add(regular)

        app.terminate()
        app.launchArguments.append("--match-reduce-motion")
        app.launch()
        XCTAssertTrue(event.waitForExistence(timeout: 10))
        XCTAssertTrue(event.label.contains("GOOOL"))
        XCTAssertEqual(scoreboard.label, goalScore)
        XCTAssertFalse(app.buttons["match.close"].exists)
        let reduced = XCTAttachment(screenshot: app.screenshot())
        reduced.name = "Gol con Reduce Motion - iPad horizontal"
        reduced.lifetime = .keepAlways
        add(reduced)
    }

    // MARK: - Accessibility
    
    func testHomeButtonsHaveMinimumSize() {
        // Dismiss splash
        app.tap()
        
        let jugadorButton = app.buttons["JUGAR 🎨"]
        XCTAssertTrue(jugadorButton.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(jugadorButton.frame.width, 200)
        XCTAssertGreaterThanOrEqual(jugadorButton.frame.height, 80)
    }
}
