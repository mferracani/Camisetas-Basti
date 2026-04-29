import XCTest
@testable import Camisetas_Basti

final class ProgressStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        ProgressStore.shared.resetAll()
    }
    
    override func tearDown() {
        ProgressStore.shared.resetAll()
        super.tearDown()
    }
    
    // MARK: - Progress lifecycle
    
    func testInitialProgressIsZero() {
        let progress = ProgressStore.shared.progress(for: "boca", kit: "home")
        XCTAssertEqual(progress.revealed, 0)
        XCTAssertEqual(progress.total, 1600)
        XCTAssertEqual(progress.pct, 0.0)
        XCTAssertFalse(progress.isCompleted)
    }
    
    func testSavePartialProgress() {
        let partial = ShirtProgress(teamId: "river", kit: "away", revealed: 400, total: 1600)
        ProgressStore.shared.save(progress: partial)
        
        let loaded = ProgressStore.shared.progress(for: "river", kit: "away")
        XCTAssertEqual(loaded.revealed, 400)
        XCTAssertEqual(loaded.pct, 0.25, accuracy: 0.01)
        XCTAssertFalse(loaded.isCompleted)
    }
    
    func testSaveCompletedProgress() {
        let completed = ShirtProgress(teamId: "boca", kit: "home", revealed: 1600, total: 1600)
        ProgressStore.shared.save(progress: completed)
        
        let loaded = ProgressStore.shared.progress(for: "boca", kit: "home")
        XCTAssertTrue(loaded.isCompleted)
        XCTAssertEqual(loaded.pct, 1.0)
    }
    
    func testTotalStarsIncrementOnComplete() {
        let initialStars = ProgressStore.shared.state.totalStars
        
        let completed = ShirtProgress(teamId: "boca", kit: "home", revealed: 1600, total: 1600)
        ProgressStore.shared.save(progress: completed)
        
        XCTAssertEqual(ProgressStore.shared.state.totalStars, initialStars + 1)
    }
    
    func testDuplicateCompleteDoesNotIncrementStars() {
        let completed = ShirtProgress(teamId: "boca", kit: "home", revealed: 1600, total: 1600)
        ProgressStore.shared.save(progress: completed)
        let starsAfterFirst = ProgressStore.shared.state.totalStars
        
        ProgressStore.shared.save(progress: completed)
        let starsAfterSecond = ProgressStore.shared.state.totalStars
        
        XCTAssertEqual(starsAfterFirst, starsAfterSecond)
    }
    
    func testResetShirtClearsProgress() {
        let completed = ShirtProgress(teamId: "boca", kit: "home", revealed: 1600, total: 1600)
        ProgressStore.shared.save(progress: completed)
        
        ProgressStore.shared.resetShirt(teamId: "boca", kit: "home")
        
        let loaded = ProgressStore.shared.progress(for: "boca", kit: "home")
        XCTAssertEqual(loaded.revealed, 0)
        XCTAssertFalse(loaded.isCompleted)
    }
    
    func testResetAllClearsEverything() {
        let completed = ShirtProgress(teamId: "boca", kit: "home", revealed: 1600, total: 1600)
        ProgressStore.shared.save(progress: completed)
        
        ProgressStore.shared.resetAll()
        
        XCTAssertEqual(ProgressStore.shared.state.totalStars, 0)
        XCTAssertTrue(ProgressStore.shared.state.progress.isEmpty)
    }
    
    // MARK: - Persistence
    
    func testProgressSurvivesStoreRecreation() {
        let completed = ShirtProgress(teamId: "river", kit: "home", revealed: 1600, total: 1600)
        ProgressStore.shared.save(progress: completed)
        
        // Simulate app restart by reloading from UserDefaults
        let freshState = ProgressStore.loadState()
        let loaded = freshState.progress["river.home"]
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.status, 2)
    }
    
    // MARK: - Trophy & Sticker logic
    
    func testCompletingAllShirtsInCountryUnlocksTrophy() {
        let teams = CAMI_DATA.teams(for: "arg")
        for team in teams {
            ProgressStore.shared.save(progress: ShirtProgress(teamId: team.id, kit: "home", revealed: 1600, total: 1600))
            ProgressStore.shared.save(progress: ShirtProgress(teamId: team.id, kit: "away", revealed: 1600, total: 1600))
        }
        
        XCTAssertTrue(ProgressStore.shared.state.trophies["arg"] == true)
    }
    
    func testCompletingBothKitsUnlocksSticker() {
        ProgressStore.shared.save(progress: ShirtProgress(teamId: "boca", kit: "home", revealed: 1600, total: 1600))
        ProgressStore.shared.save(progress: ShirtProgress(teamId: "boca", kit: "away", revealed: 1600, total: 1600))
        
        XCTAssertTrue(ProgressStore.shared.state.stickers["boca"] == true)
    }
}

extension ProgressStore {
    static func loadState() -> AppState {
        guard let data = UserDefaults.standard.data(forKey: "com.camisetasbasti.appstate"),
              let state = try? JSONDecoder().decode(AppState.self, from: data) else {
            return AppState()
        }
        return state
    }
}
