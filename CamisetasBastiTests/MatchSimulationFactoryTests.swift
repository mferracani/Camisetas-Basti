import XCTest
@testable import Camisetas_Basti

final class MatchSimulationFactoryTests: XCTestCase {
    func testWorldCupQualityRanksArgentinaAboveCuracao() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))

        XCTAssertGreaterThan(argentina.matchQualityScore, curacao.matchQualityScore)
    }

    func testWeightedSimulationFavorsStrongerTeamButAllowsUpsets() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: 42)

        let results = (0..<300).map { _ in
            MatchSimulationFactory.makeResult(home: argentina, away: curacao, rng: &rng)
        }
        let argentinaWins = results.filter { $0.winner.id == argentina.id }.count
        let curacaoWins = results.filter { $0.winner.id == curacao.id }.count

        XCTAssertGreaterThan(argentinaWins, curacaoWins)
        XCTAssertGreaterThan(argentinaWins, 190)
        XCTAssertGreaterThan(curacaoWins, 0)
    }

    func testPenaltyShootoutUsesFiveAlternatingPenaltiesPerTeam() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: 99)

        let shootout = PenaltyShootoutFactory.makeShootout(home: argentina, away: curacao, winner: argentina, rng: &rng)

        XCTAssertEqual(shootout.shots.count, 10)
        XCTAssertEqual(shootout.shots.filter { $0.side == .home }.count, 5)
        XCTAssertEqual(shootout.shots.filter { $0.side == .away }.count, 5)

        for round in 0..<5 {
            XCTAssertEqual(shootout.shots[round * 2].side, .home)
            XCTAssertEqual(shootout.shots[round * 2 + 1].side, .away)
        }
    }

    func testPenaltyShootoutWinnerMatchesSimulatedWinner() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: 7)

        let shootout = PenaltyShootoutFactory.makeShootout(home: argentina, away: curacao, winner: curacao, rng: &rng)
        let finalScore = shootout.score(after: shootout.shots.count)

        XCTAssertEqual(shootout.finalWinnerSide, .away)
        XCTAssertGreaterThan(finalScore.away, finalScore.home)
    }
}

final class WorldCupFixtureTests: XCTestCase {
    func testWorldCupIsAvailableInTournamentCatalog() {
        XCTAssertEqual(CAMI_DATA.countries.first?.id, "wc26")
        XCTAssertEqual(CAMI_DATA.country(id: "wc26")?.name, "MUNDIAL 2026")
    }

    func testRandomRosterAlwaysKeepsProtectedCountries() {
        let fixture = WorldCup2026Fixture(randomTeamIds: [])
        let teamIds = Set(fixture.groups.flatMap(\.teams).map(\.id))

        XCTAssertEqual(fixture.groups.count, 12)
        XCTAssertEqual(teamIds.count, 48)
        XCTAssertTrue(WorldCup2026Fixture.lockedRandomTeamIds.isSubset(of: teamIds))
    }

    func testRandomRosterPoolIncludesAdditionalCountries() {
        let poolIds = Set(WorldCup2026Fixture.randomTeamPool.map(\.id))

        XCTAssertTrue(poolIds.isSuperset(of: ["italy", "chile", "peru", "nigeria", "denmark", "ukraine"]))
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}
