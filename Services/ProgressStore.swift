import Foundation
import Combine

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    private let defaults = UserDefaults.standard
    private let key = "com.camisetasbasti.appstate"
    
    @Published var state: AppState
    
    private init() {
        self.state = Self.load()
    }
    
    private static func load() -> AppState {
        guard let data = UserDefaults.standard.data(forKey: "com.camisetasbasti.appstate"),
              let state = try? JSONDecoder().decode(AppState.self, from: data) else {
            return AppState()
        }
        return state
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
    
    // MARK: - New API (used by Views)
    
    func progress(for teamId: String, kit: String) -> ShirtProgress {
        let key = "\(teamId).\(kit)"
        guard let legacy = state.progress[key] else {
            return ShirtProgress(teamId: teamId, kit: kit, revealed: 0, total: 1600)
        }
        // Migrate from legacy format if needed
        let revealed = Int((legacy.revealPct ?? 0) * 1600)
        return ShirtProgress(teamId: teamId, kit: kit, revealed: revealed, total: 1600)
    }
    
    func save(progress: ShirtProgress) {
        let key = progress.storageKey
        let wasCompleted = state.progress[key]?.status == 2
        let legacy = ShirtProgressLegacy(key: key, status: progress.isCompleted ? 2 : 1, revealPct: progress.pct)
        state.progress[key] = legacy
        
        if progress.isCompleted && !wasCompleted {
            state.totalStars += 1
            
            // Find country for trophy/sticker logic
            if let countryId = countryId(for: progress.teamId) {
                state.lastCountryId = countryId
                state.lastTeamId = progress.teamId
                
                let teams = CAMI_DATA.teams(for: countryId)
                let discovered = state.discoveredShirts(for: countryId, teams: teams)
                if discovered >= AppState.shirtsPerCountry {
                    state.trophies[countryId] = true
                }
                
                let teamDiscovered = state.discoveredShirts(for: countryId, teamId: progress.teamId)
                if teamDiscovered >= 2 {
                    state.stickers[progress.teamId] = true
                }
            }
        }
        
        save()
    }
    
    func resetShirt(teamId: String, kit: String) {
        let key = "\(teamId).\(kit)"
        state.progress[key] = ShirtProgressLegacy(key: key, status: 0, revealPct: 0.0)
        state.totalStars = max(0, state.totalStars - 1)
        save()
    }
    
    private func countryId(for teamId: String) -> String? {
        for country in CAMI_DATA.countries {
            if CAMI_DATA.teams(for: country.id).contains(where: { $0.id == teamId }) {
                return country.id
            }
        }
        return nil
    }
    
    // MARK: - Legacy API
    
    func setShirtComplete(countryId: String, teamId: String, kit: String) {
        let key = "\(countryId).\(teamId).\(kit)"
        state.progress[key] = ShirtProgressLegacy(key: key, status: 2, revealPct: 1.0)
        state.totalStars += 1
        state.lastCountryId = countryId
        state.lastTeamId = teamId
        
        let teams = CAMI_DATA.teams(for: countryId)
        let discovered = state.discoveredShirts(for: countryId, teams: teams)
        if discovered >= AppState.shirtsPerCountry {
            state.trophies[countryId] = true
        }
        
        let teamDiscovered = state.discoveredShirts(for: countryId, teamId: teamId)
        if teamDiscovered >= 2 {
            state.stickers[teamId] = true
        }
        
        save()
    }
    
    func resetShirt(countryId: String, teamId: String, kit: String) {
        let key = "\(countryId).\(teamId).\(kit)"
        state.progress[key] = ShirtProgressLegacy(key: key, status: 0, revealPct: 0.0)
        state.totalStars = max(0, state.totalStars - 1)
        save()
    }
    
    func setShirtPartial(countryId: String, teamId: String, kit: String, pct: Double) {
        let key = "\(countryId).\(teamId).\(kit)"
        state.progress[key] = ShirtProgressLegacy(key: key, status: 1, revealPct: pct)
        save()
    }
    
    func shirtStatus(countryId: String, teamId: String, kit: String) -> Int {
        let key = "\(countryId).\(teamId).\(kit)"
        return state.progress[key]?.status ?? 0
    }
    
    func shirtRevealPct(countryId: String, teamId: String, kit: String) -> Double {
        let key = "\(countryId).\(teamId).\(kit)"
        return state.progress[key]?.revealPct ?? 0.0
    }
    
    func resetAll() {
        state = AppState()
        save()
    }
    
    func migrateIfNeeded(currentVersion: Int) {
        guard state.contentVersion < currentVersion else { return }
        state.contentVersion = currentVersion
        save()
    }
}


