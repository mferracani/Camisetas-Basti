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
        XCTAssertTrue(app.staticTexts["ELIGE UN PAÍS"].waitForExistence(timeout: 2))
        
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
        
        // Tap PINTAR
        app.buttons["PINTAR 🖌️"].tap()
        
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
        XCTAssertTrue(app.staticTexts["ELIGE UN PAÍS"].waitForExistence(timeout: 2))
        
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
