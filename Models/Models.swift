import Foundation

// MARK: - Country

struct Country: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let flagColors: [String]
    let emoji: String
    
    var flag: String { emoji }
}

// MARK: - Team

struct Team: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let short: String
    let home: Kit
    let away: Kit
    let crest: Crest
}

// MARK: - Kit

struct Kit: Codable, Hashable {
    let pattern: Pattern
    let colors: [String]
}

// MARK: - Pattern

enum Pattern: String, Codable, CaseIterable {
    case solid
    case stripesV = "stripes-v"
    case stripesH = "stripes-h"
    case hoops
    case splitV = "split-v"
    case splitD = "split-d"
    case sashD = "sash-d"
    case sashH = "sash-h"
    case sashHThin = "sash-h-thin"
    case sashHThick = "sash-h-thick"
    case sashV = "sash-v"
    case sashVFat = "sash-v-fat"
    case sleevesW = "sleeves-w"
    case splitVBlueClaret = "split-v-blue-claret"
}

// MARK: - Crest

struct Crest: Codable, Hashable {
    enum Shape: String, Codable {
        case round, shield, diamond
    }
    let shape: Shape
    let text: String
    let colors: [String]
}

// MARK: - ShirtProgress

struct ShirtProgress: Codable, Equatable {
    let teamId: String
    let kit: String
    var revealed: Int
    let total: Int
    
    var pct: Double {
        guard total > 0 else { return 0 }
        return min(1.0, Double(revealed) / Double(total))
    }
    
    var isCompleted: Bool { pct >= 1.0 }
    
    /// Legacy key for storage compatibility
    var storageKey: String { "\(teamId).\(kit)" }
}

// MARK: - GamesStats

struct GamesStats: Codable, Equatable {
    var guessPlayed: Int = 0
    var memoryPlayed: Int = 0
    var guessWon: Int = 0
}

// MARK: - AppState

struct AppState: Codable {
    var progress: [String: ShirtProgressLegacy] = [:]
    var totalStars: Int = 0
    var lastCountryId: String? = nil
    var lastTeamId: String? = nil
    var trophies: [String: Bool] = [:]
    var stickers: [String: Bool] = [:]
    var gamesPlayed: GamesStats = GamesStats()
    var contentVersion: Int = 1
    var onboardingCompleted: Bool = true
}

// MARK: - Legacy Storage Model

struct ShirtProgressLegacy: Codable, Equatable {
    let key: String
    var status: Int
    var revealPct: Double?
}

// MARK: - Helpers

extension AppState {
    static let shirtsPerCountry = 20
    static let totalShirts = 120
    
    func discoveredShirts(for countryId: String, teams: [Team]) -> Int {
        var count = 0
        for team in teams {
            let homeKey = "\(countryId).\(team.id).home"
            let awayKey = "\(countryId).\(team.id).away"
            if progress[homeKey]?.status == 2 { count += 1 }
            if progress[awayKey]?.status == 2 { count += 1 }
        }
        return count
    }
    
    func discoveredShirts(for countryId: String, teamId: String) -> Int {
        let homeKey = "\(countryId).\(teamId).home"
        let awayKey = "\(countryId).\(teamId).away"
        var count = 0
        if progress[homeKey]?.status == 2 { count += 1 }
        if progress[awayKey]?.status == 2 { count += 1 }
        return count
    }
}
