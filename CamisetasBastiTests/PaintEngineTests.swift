import XCTest
@testable import Camisetas_Basti

final class PaintEngineTests: XCTestCase {
    
    var engine: PaintEngine!
    
    override func setUp() {
        super.setUp()
        engine = PaintEngine()
        engine.setup(gridSize: 40)
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Grid initialization
    
    func testInitialRevealIsZero() {
        XCTAssertEqual(engine.revealPct, 0.0)
    }
    
    func testInitialMaskExists() {
        XCTAssertNotNil(engine.maskImage)
    }
    
    // MARK: - Painting
    
    func testSinglePaintIncreasesReveal() {
        let size = CGSize(width: 400, height: 466)
        let center = CGPoint(x: 200, y: 233)
        
        engine.paint(at: center, in: size, brushSize: 44)
        
        XCTAssertGreaterThan(engine.revealPct, 0.0)
    }
    
    func testPaintOutsideBoundsDoesNotCrash() {
        let size = CGSize(width: 400, height: 466)
        let outside = CGPoint(x: -100, y: -100)
        
        engine.paint(at: outside, in: size, brushSize: 44)
        
        // Should not crash; reveal should remain 0 or minimal
        XCTAssertGreaterThanOrEqual(engine.revealPct, 0.0)
    }
    
    func testMultiplePaintsAccumulate() {
        let size = CGSize(width: 400, height: 466)
        let points = [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 200, y: 200),
            CGPoint(x: 300, y: 300),
        ]
        
        var previousPct = engine.revealPct
        for point in points {
            engine.paint(at: point, in: size, brushSize: 44)
            XCTAssertGreaterThanOrEqual(engine.revealPct, previousPct)
            previousPct = engine.revealPct
        }
    }
    
    func testPaintDoesNotExceedOneHundredPercent() {
        let size = CGSize(width: 400, height: 466)
        
        // Paint every cell aggressively
        for y in stride(from: 0, to: Int(size.height), by: 20) {
            for x in stride(from: 0, to: Int(size.width), by: 20) {
                engine.paint(at: CGPoint(x: x, y: y), in: size, brushSize: 60)
            }
        }
        
        XCTAssertLessThanOrEqual(engine.revealPct, 1.0)
    }
    
    // MARK: - Reset
    
    func testResetClearsReveal() {
        let size = CGSize(width: 400, height: 466)
        engine.paint(at: CGPoint(x: 200, y: 233), in: size, brushSize: 44)
        XCTAssertGreaterThan(engine.revealPct, 0.0)
        
        engine.reset()
        
        XCTAssertEqual(engine.revealPct, 0.0)
    }
    
    func testResetGeneratesNewMask() {
        let beforeMask = engine.maskImage
        engine.reset()
        let afterMask = engine.maskImage
        
        XCTAssertNotNil(afterMask)
        XCTAssertNotEqual(beforeMask?.pngData(), afterMask?.pngData())
    }
    
    // MARK: - Completion threshold
    
    func testRevealReachesThreshold() {
        let size = CGSize(width: 400, height: 466)
        let threshold = 0.85
        
        // Paint grid densely
        for y in stride(from: 0, to: Int(size.height), by: 15) {
            for x in stride(from: 0, to: Int(size.width), by: 15) {
                engine.paint(at: CGPoint(x: x, y: y), in: size, brushSize: 50)
            }
        }
        
        XCTAssertGreaterThanOrEqual(engine.revealPct, threshold)
    }
}
