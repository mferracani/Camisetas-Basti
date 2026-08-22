import XCTest
@testable import Camisetas_Basti

final class MatchSimulationFactoryTests: XCTestCase {
    func testSameSeedProducesIdenticalOpenPlayTimeline() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var firstRNG = SeededGenerator(seed: 2026)
        var secondRNG = SeededGenerator(seed: 2026)

        let first = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &firstRNG)
        let second = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &secondRNG)

        XCTAssertEqual(first, second)
    }

    func testOpenPlayTimelineIsContinuousForBallAndPlayers() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: 31)

        let simulation = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng)
        let beats = simulation.beats

        XCTAssertGreaterThan(beats.count, 20)
        XCTAssertEqual(beats.first?.startProgress ?? -1, 0, accuracy: 0.000_001)
        XCTAssertEqual(beats.last?.endProgress ?? -1, 1, accuracy: 0.000_001)

        for beat in beats {
            XCTAssertLessThan(beat.startProgress, beat.endProgress)
            XCTAssertEqual(beat.homeStartPositions.count, 6)
            XCTAssertEqual(beat.homeEndPositions.count, 6)
            XCTAssertEqual(beat.awayStartPositions.count, 6)
            XCTAssertEqual(beat.awayEndPositions.count, 6)
        }

        for (current, next) in zip(beats, beats.dropFirst()) {
            XCTAssertEqual(current.endProgress, next.startProgress, accuracy: 0.000_001)
            XCTAssertEqual(current.ballEnd, next.ballStart)
            XCTAssertEqual(current.homeEndPositions, next.homeStartPositions)
            XCTAssertEqual(current.awayEndPositions, next.awayStartPositions)
            XCTAssertEqual(current.possessionAfter, next.possessionBefore)
        }
    }

    func testEverySimulationHasPassingRecoveriesAndMissedShots() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))

        for seed in 0..<24 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats
            var passSides = Set<MatchSide>()
            var recoverySides = Set<MatchSide>()
            var shotOutcomes = Set<MatchShotOutcome>()

            for beat in beats {
                switch beat.action {
                case let .pass(from, to):
                    XCTAssertEqual(from.side, to.side)
                    XCTAssertNotEqual(from.index, to.index)
                    passSides.insert(from.side)
                case let .interception(_, _, defender):
                    recoverySides.insert(defender.side)
                case let .tackle(_, defender):
                    recoverySides.insert(defender.side)
                case let .shot(shooter, outcome):
                    XCTAssertTrue((1...5).contains(shooter.index))
                    shotOutcomes.insert(outcome)
                default:
                    break
                }
            }

            XCTAssertEqual(passSides, Set([.home, .away]))
            XCTAssertEqual(recoverySides, Set([.home, .away]))
            XCTAssertTrue(shotOutcomes.isSuperset(of: [.wide, .saved, .blocked]))
        }
    }

    func testTimelineGoalsExactlyMatchFinalScore() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))

        for seed in 50..<90 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let simulation = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng)
            let goalSides = simulation.beats.compactMap { beat -> MatchSide? in
                guard case let .shot(shooter, outcome) = beat.action, outcome == .goal else { return nil }
                return shooter.side
            }

            XCTAssertEqual(goalSides.filter { $0 == .home }.count, simulation.result.homeGoals)
            XCTAssertEqual(goalSides.filter { $0 == .away }.count, simulation.result.awayGoals)
        }
    }

    func testTeammatesKeepReadableSpacingDuringOpenPlay() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))

        for seed in 100..<116 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats

            for beat in beats {
                for localProgress in [0.0, 0.25, 0.5, 0.75, 1.0] {
                    let easedProgress = smooth(localProgress)
                    let owner = beat.action.ballOwner(at: localProgress)
                    let homePositions = beat.playerPositions(
                        for: .home,
                        progress: easedProgress,
                        protectedIndex: owner?.side == .home ? owner?.index : nil
                    )
                    let awayPositions = beat.playerPositions(
                        for: .away,
                        progress: easedProgress,
                        protectedIndex: owner?.side == .away ? owner?.index : nil
                    )

                    XCTAssertGreaterThanOrEqual(
                        minimumVisualDistance(in: homePositions),
                        MatchPitchLayout.minimumVisualDistance,
                        "Home players overlap at beat \(beat.id), progress \(localProgress), action \(beat.action)"
                    )
                    XCTAssertGreaterThanOrEqual(
                        minimumVisualDistance(in: awayPositions),
                        MatchPitchLayout.minimumVisualDistance,
                        "Away players overlap at beat \(beat.id), progress \(localProgress), action \(beat.action)"
                    )
                }
            }
        }
    }

    func testPlayersRemainInsidePlayableAreaDuringRestarts() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))

        for seed in 200..<224 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats

            for beat in beats {
                let positions = beat.homeEndPositions + beat.awayEndPositions
                for position in positions {
                    XCTAssertTrue(
                        (0.04...0.96).contains(position.x) && (0.16...0.84).contains(position.y),
                        "Player leaves the playable area at beat \(beat.id), action \(beat.action): \(position)"
                    )
                }
            }
        }
    }

    func testBallOwnerStartsEachControlledActionAtTheBall() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: 20260822)
        let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats

        for beat in beats {
            guard let owner = beat.action.ballOwner(at: 0) else { continue }
            let positions = owner.side == .home ? beat.homeStartPositions : beat.awayStartPositions
            XCTAssertLessThanOrEqual(
                positions[owner.index].distance(to: beat.ballStart),
                0.005,
                "The controlled action starts without its owner on the ball at beat \(beat.id), action \(beat.action)"
            )
        }
    }

    private func minimumVisualDistance(in positions: [PitchPoint]) -> Double {
        var minimum = Double.greatestFiniteMagnitude
        for first in positions.indices {
            for second in positions.indices where second > first {
                minimum = min(
                    minimum,
                    MatchPitchLayout.visualDistance(positions[first], positions[second])
                )
            }
        }
        return minimum
    }

    private func smooth(_ value: Double) -> Double {
        value * value * (3 - 2 * value)
    }

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
