import XCTest
import SwiftUI
@testable import Camisetas_Basti

final class MatchKitStyleTests: XCTestCase {
    func testAllPlayableTeamsIncludingFixtureAndRandomDrawHaveExplicitKits() {
        let catalog = CAMI_DATA.teams.values.flatMap { $0 }
        let fixtures = WorldCup2026Fixture.randomTeamPool
        let catalogIDs = Set(catalog.map(\.id))
        let additional = fixtures.filter { !catalogIDs.contains("sel_\($0.id)") }
        XCTAssertEqual(additional.count, 35)
        for fixture in additional {
            XCTAssertNotNil(worldCupKits[fixture.id], "Missing explicit kit: \(fixture.id)")
        }
        let all = catalog + additional.map { worldCupTeam(for: $0) }
        XCTAssertEqual(Set(all.map(\.id)).count, 139)
        for home in all {
            XCTAssertFalse(home.home.colors.contains("#5B6B7B"), home.id)
            XCTAssertNotEqual(home.home, home.away, home.id)
            for away in all where home.id != away.id {
                let pair = MatchKitStyle.pair(home: home, away: away)
                XCTAssertTrue([home.home, home.away].contains(pair.0.kit), home.id)
                XCTAssertTrue([away.home, away.away].contains(pair.1.kit), away.id)
            }
        }
    }

    func testEveryMatchUsesOnlyTheTeamsActualHomeOrAwayKits() {
        let teams = CAMI_DATA.teams.values.flatMap { $0 }
        XCTAssertEqual(teams.count, 104)
        for home in teams {
            for away in teams where home.id != away.id {
                let pair = MatchKitStyle.pair(home: home, away: away)
                XCTAssertTrue([home.home, home.away].contains(pair.0.kit), home.id)
                XCTAssertTrue([away.home, away.away].contains(pair.1.kit), away.id)
            }
        }
    }

    func testIdenticalAvailableColorsUseAnOutlineNotAnInventedKit() {
        let red = Kit(pattern: .solid, colors: ["#E4002B", "#FFFFFF"])
        let first = makeTeam(id: "one", home: red, away: red)
        let second = makeTeam(id: "two", home: red, away: red)
        let pair = MatchKitStyle.pair(home: first, away: second)
        XCTAssertEqual(pair.0.kit, red)
        XCTAssertEqual(pair.1.kit, red)
        XCTAssertTrue(pair.0.requiresTeamOutline)
        XCTAssertTrue(pair.1.requiresTeamOutline)
    }

    func testContrastingHomeKitsArePreserved() {
        let black = Kit(pattern: .solid, colors: ["#111111", "#FFFFFF"])
        let white = Kit(pattern: .solid, colors: ["#FFFFFF", "#111111"])
        let pair = MatchKitStyle.pair(
            home: makeTeam(id: "one", home: black, away: white),
            away: makeTeam(id: "two", home: white, away: black)
        )
        XCTAssertEqual(pair.0.kit, black)
        XCTAssertEqual(pair.1.kit, white)
        XCTAssertFalse(pair.0.requiresTeamOutline)
    }

    func testStripesAndHoopsRemainMultipleBandsAndSolidHasNoInventedBand() {
        XCTAssertEqual(regions(.solid).count, 0)
        XCTAssertGreaterThanOrEqual(regions(.stripesV).count, 3)
        XCTAssertGreaterThanOrEqual(regions(.stripesH).count, 3)
        XCTAssertGreaterThanOrEqual(regions(.hoops).count, 3)
        XCTAssertEqual(regions(.sashH).count, 1)
        XCTAssertEqual(regions(.sashVFat).count, 1)
    }

    func testBandWidthsAndDiagonalSplitAreNotCollapsedIntoOneStripe() throws {
        let thin = try XCTUnwrap(regions(.sashHThin).first).boundingRect.height
        let medium = try XCTUnwrap(regions(.sashH).first).boundingRect.height
        let thick = try XCTUnwrap(regions(.sashHThick).first).boundingRect.height
        XCTAssertLessThan(thin, medium)
        XCTAssertLessThan(medium, thick)
        let diagonalHalf = try XCTUnwrap(regions(.splitD).first)
        XCTAssertTrue(diagonalHalf.contains(CGPoint(x: 90, y: 90)))
        XCTAssertFalse(diagonalHalf.contains(CGPoint(x: 10, y: 10)))
        let diagonalBand = try XCTUnwrap(regions(.sashD).first)
        XCTAssertFalse(diagonalBand.contains(CGPoint(x: 90, y: 90)))
        XCTAssertTrue(diagonalBand.contains(CGPoint(x: 50, y: 50)))
    }

    func testWhiteSleevesDoNotAddABandAcrossTheTorso() {
        let style = MatchKitStyle(kit: Kit(pattern: .sleevesW, colors: ["#FF0000", "#FFFFFF"]))
        XCTAssertEqual(style.sleeveColor, Color(hex: "#FFFFFF"))
        XCTAssertEqual(regions(.sleevesW).count, 0)
        let claret = MatchKitStyle(kit: Kit(pattern: .splitVBlueClaret, colors: ["#7A263A", "#59CBE8"]))
        XCTAssertEqual(claret.primary, Color(hex: "#7A263A"))
        XCTAssertEqual(claret.sleeveColor, Color(hex: "#59CBE8"))
        XCTAssertEqual(regions(.splitVBlueClaret).count, 0)
    }

    func testCheckerboardAlternatesInBothDirections() {
        let squares = regions(.checkerboard)
        func filled(_ x: CGFloat, _ y: CGFloat) -> Bool {
            squares.contains { $0.contains(CGPoint(x: x, y: y)) }
        }
        XCTAssertEqual(squares.count, 8)
        XCTAssertFalse(filled(12.5, 12.5))
        XCTAssertTrue(filled(37.5, 12.5))
        XCTAssertTrue(filled(12.5, 37.5))
        XCTAssertFalse(filled(37.5, 37.5))
    }

    func testEveryCatalogKitHasAnExplicitRenderablePattern() {
        let kits = CAMI_DATA.teams.values.flatMap { $0 }.flatMap { [$0.home, $0.away] }
        XCTAssertEqual(kits.count, 208)
        for kit in kits {
            let style = MatchKitStyle(kit: kit)
            XCTAssertEqual(style.kit, kit)
            XCTAssertFalse(kit.colors.isEmpty)
            XCTAssertTrue(Pattern.allCases.contains(kit.pattern))
            if ![Pattern.solid, .sleevesW, .splitVBlueClaret].contains(kit.pattern) {
                XCTAssertFalse(style.patternRegions(in: CGRect(x: 0, y: 0, width: 100, height: 100)).isEmpty)
            }
        }
    }

    func testThreeColorBandsRetainTheirBordersOrTwoDistinctHalves() throws {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let bordered = MatchKitStyle(kit: Kit(pattern: .sashVBordered, colors: ["#000040", "#FF0000", "#FFFFFF"]))
        XCTAssertEqual(bordered.accentRegions(in: rect).count, 2)
        XCTAssertFalse(bordered.accentRegions(in: rect).contains { $0.contains(CGPoint(x: 50, y: 50)) })
        let dual = MatchKitStyle(kit: Kit(pattern: .sashVDual, colors: ["#FFFFFF", "#FF0000", "#0000FF"]))
        let half = try XCTUnwrap(dual.accentRegions(in: rect).first)
        XCTAssertFalse(half.contains(CGPoint(x: 40, y: 50)))
        XCTAssertTrue(half.contains(CGPoint(x: 60, y: 50)))
        XCTAssertEqual(half.boundingRect.width, 20, accuracy: 0.001)
    }

    func testVelezChevronHasTwoShouldersAndAChestPoint() throws {
        let chevron = try XCTUnwrap(regions(.chevron).first)
        XCTAssertTrue(chevron.contains(CGPoint(x: 5, y: 30)))
        XCTAssertTrue(chevron.contains(CGPoint(x: 95, y: 30)))
        XCTAssertTrue(chevron.contains(CGPoint(x: 50, y: 58)))
        XCTAssertFalse(chevron.contains(CGPoint(x: 50, y: 20)))
        XCTAssertFalse(chevron.contains(CGPoint(x: 50, y: 85)))
    }

    private func regions(_ pattern: Pattern) -> [Path] {
        MatchKitStyle(kit: Kit(pattern: pattern, colors: ["#FFFFFF", "#FF0000"]))
            .patternRegions(in: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    private func makeTeam(id: String, home: Kit, away: Kit) -> Team {
        Team(id: id, name: id, short: id, home: home, away: away,
             crest: Crest(shape: .round, text: id, colors: ["#FFFFFF"]))
    }
}
