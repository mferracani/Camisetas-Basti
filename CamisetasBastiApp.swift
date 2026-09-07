import SwiftUI

@main
struct CamisetasBastiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--match-preview") {
                MatchPreviewHarness()
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
    }

    private var appContent: some View {
        ZStack {
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            } else {
                HomeView()
            }
        }
    }
}

#if DEBUG
/// Reproducible visual QA of the actual match view; excluded from release builds.
private struct MatchPreviewHarness: View {
    @State private var finished = false

    var body: some View {
        if !finished,
           let home = CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"),
           let away = CAMI_DATA.team(countryId: "wc26", teamId: "sel_france") {
            MatchSimulationModal(home: home, away: away, homeFlag: "🇦🇷", awayFlag: "🇫🇷",
                                 simulation: simulation(home: home, away: away)) { _ in finished = true }
        } else {
            HomeView()
        }
    }

    private func simulation(home: Team, away: Team) -> MatchSimulation {
        var generator = MatchPreviewGenerator()
        let moment = ProcessInfo.processInfo.environment["MATCH_PREVIEW_MOMENT"] ?? ""
        let kind: MatchSetPiece? = moment.hasPrefix("free-kick") ? .freeKick
            : moment.hasPrefix("penalty") ? .penalty : nil
        var simulation = MatchSimulationFactory.makeSimulation(home: home, away: away, rng: &generator)
        // Search normal seeded matches, rather than injecting a fake event/result.
        for _ in 0..<256 {
            let needsAnother = moment.hasPrefix("shootout") ? !simulation.result.decidedByPenalties
                : kind.map { kind in !simulation.beats.contains(where: { $0.setPiece == kind }) } ?? false
            guard needsAnother else { break }
            simulation = MatchSimulationFactory.makeSimulation(home: home, away: away, rng: &generator)
        }
        return simulation
    }
}

struct MatchPreviewGenerator: RandomNumberGenerator {
    var state: UInt64 = 2026
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure audio session early
        SoundManager.shared.playTap() // Trigger initialization
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Ensure any pending progress is saved
        ProgressStore.shared.save()
    }
}
