import XCTest
@testable import Camisetas_Basti

final class MatchSimulationFactoryTests: XCTestCase {
    func testPlaybackUsesEvenDisplayStepsAndDoesNotCatchUpAfterPause() {
        var clock = MatchPlaybackTime()
        clock.advance(to: 10)
        for tick in 1...60 { clock.advance(to: 10 + Double(tick) / 60) }
        XCTAssertEqual(clock.elapsed, 1, accuracy: 0.000001)
        clock.suspend()
        clock.advance(to: 900)
        XCTAssertEqual(clock.elapsed, 1, accuracy: 0.000001)
        clock.advance(to: 900 + 1.0 / 60.0)
        XCTAssertEqual(clock.elapsed, 1 + 1.0 / 60.0, accuracy: 0.000001)
        clock.advance(to: 902) // A stalled frame does not teleport players.
        XCTAssertEqual(clock.elapsed, 1 + 1.0 / 60.0 + 1.0 / 15.0, accuracy: 0.000001)
        clock.advance(to: 901) // Reject stale and non-finite timestamps.
        clock.advance(to: .nan)
        XCTAssertEqual(clock.elapsed, 1 + 1.0 / 60.0 + 1.0 / 15.0, accuracy: 0.000001)
        clock.seek(to: 42)
        clock.advance(to: 1000)
        XCTAssertEqual(clock.elapsed, 42)
    }

    func testOutfieldRunningSpeedHasAReadableLimit() throws {
        for seed in Array(0..<24) + [31, 73, 2026] {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            let motion = MatchMotionTimeline(beats: beats)
            let duration = MatchMotionTimeline.playbackDuration
            var peak = 0.0
            var worst = ""
            var visiblePeak = 0.0
            var visibleWorst = ""
            for (index, beat) in beats.enumerated() {
                for step in 0...30 {
                    for side in [MatchSide.home, .away] {
                        let t = Double(step) / 30
                        let halfFrame = 1.0 / 120 / ((beat.endProgress - beat.startProgress) * duration)
                        let before = motion.positions(beatIndex: index, side: side, local: max(0, t - halfFrame))
                        let after = motion.positions(beatIndex: index, side: side, local: min(1, t + halfFrame))
                        let dt = (min(1, t + halfFrame) - max(0, t - halfFrame)) * (beat.endProgress - beat.startProgress) * duration
                        for slot in 1..<11 {
                            let speed = motion.player(MatchPlayerRef(side: side, index: slot), beatIndex: index,
                                                      local: Double(step) / 30, duration: duration).speed
                            let visible = MatchPitchLayout.visualDistance(before[slot], after[slot]) / dt
                            if visible > visiblePeak {
                                visiblePeak = visible
                                visibleWorst = "\(beat.id) \(beat.action), player=\(side)/\(slot), local=\(t)"
                            }
                            if speed > peak { peak = speed; worst = "\(beat.action)" }
                        }
                    }
                }
            }
            print("RUN-SPEED seed=\(seed) peak=\(peak) visible-peak=\(visiblePeak) worst=\(worst)")
            XCTAssertLessThanOrEqual(peak, 0.10, "A sprint must remain readable even when there are many chances")
            XCTAssertLessThanOrEqual(visiblePeak, 0.14, "Spacing must not add a speed spike: \(visibleWorst)")
        }
    }

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
            XCTAssertEqual(beat.homeStartPositions.count, 11)
            XCTAssertEqual(beat.homeEndPositions.count, 11)
            XCTAssertEqual(beat.awayStartPositions.count, 11)
            XCTAssertEqual(beat.awayEndPositions.count, 11)
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
                    XCTAssertTrue((1...10).contains(shooter.index))
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

    func testEveryMatchReachesAFirstShotWithinTheOpeningThirtyPercent() throws {
        for seed in 0..<24 {
            let simulation = try presentationSimulation(seed: UInt64(seed))
            let firstShot = try XCTUnwrap(simulation.beats.first { $0.action.isShot })
            XCTAssertLessThanOrEqual(
                firstShot.startProgress, 0.30,
                "Seed \(seed) leaves the opening without a shot until \(firstShot.startProgress * 100)%"
            )
        }
    }

    func testOpenPlayConnectsDefenceMidfieldAndAttack() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: 73)
        let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats

        let homeParticipants = Set(beats.flatMap { beat -> [Int] in
            switch beat.action {
            case let .kickoff(from, to), let .pass(from, to), let .cross(from, to), let .restart(from, to, _):
                return [from, to].filter { $0.side == .home }.map(\.index)
            case let .carry(player), let .shot(player, _), let .setPieceSetup(player, _):
                return player.side == .home ? [player.index] : []
            case let .pressure(carrier, defender), let .duel(carrier, defender, _), let .tackle(carrier, defender), let .foul(carrier, defender):
                return [carrier, defender].filter { $0.side == .home }.map(\.index)
            case let .interception(passer, intendedReceiver, defender):
                return [passer, intendedReceiver, defender].filter { $0.side == .home }.map(\.index)
            case .finalWhistle:
                return []
            }
        })

        XCTAssertFalse(homeParticipants.isDisjoint(with: Set(1...4)))
        XCTAssertFalse(homeParticipants.isDisjoint(with: Set(5...7)))
        XCTAssertFalse(homeParticipants.isDisjoint(with: Set(8...10)))
    }

    func testEverySimulationIncludesAWideCrossForTheStriker() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))

        for seed in 0..<16 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats
            let crosses = beats.compactMap { beat -> (from: MatchPlayerRef, to: MatchPlayerRef)? in
                guard case let .cross(from, to) = beat.action else { return nil }
                return (from, to)
            }

            XCTAssertTrue(crosses.contains {
                [8, 10].contains($0.from.index) && $0.to.index == 9 && $0.from.side == $0.to.side
            })
        }
    }

    func testPassiveTeammatesMoveAsACompactBlockDuringPasses() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: 109)
        let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats

        for beat in beats {
            guard case let .pass(from, to) = beat.action else { continue }
            for side in [MatchSide.home, .away] {
                let start = side == .home ? beat.homeStartPositions : beat.awayStartPositions
                let end = side == .home ? beat.homeEndPositions : beat.awayEndPositions
                for index in start.indices where !(from.side == side && from.index == index) && !(to.side == side && to.index == index) {
                    XCTAssertLessThanOrEqual(
                        start[index].distance(to: end[index]),
                        0.09,
                        "A passive player travelled too far during a pass at beat \(beat.id)"
                    )
                }
            }
        }
    }

    func testPressuresUseTheClosestAvailableDefender() throws {
        let argentina = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let curacao = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))

        for seed in 10..<18 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let beats = MatchSimulationFactory.makeSimulation(home: argentina, away: curacao, rng: &rng).beats

            for beat in beats {
                guard case let .pressure(_, defender) = beat.action else { continue }

                let positions = defender.side == .home ? beat.homeStartPositions : beat.awayStartPositions
                let closestDistance = positions.dropFirst().map { $0.distance(to: beat.ballStart) }.min() ?? .greatestFiniteMagnitude
                XCTAssertEqual(
                    positions[defender.index].distance(to: beat.ballStart),
                    closestDistance,
                    accuracy: 0.000_001,
                    "The pressing player was not the closest defender at beat \(beat.id)"
                )
            }
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
            // At a dead ball the taker starts a run-up behind the stationary ball.
            if beat.setPiece != nil && beat.action.isShot { continue }
            guard let owner = beat.action.ballOwner(at: 0) else { continue }
            let positions = owner.side == .home ? beat.homeStartPositions : beat.awayStartPositions
            XCTAssertLessThanOrEqual(
                positions[owner.index].distance(to: beat.ballStart),
                0.02,
                "The controlled action starts outside its visual touch radius at beat \(beat.id), action \(beat.action)"
            )
        }
    }

    func testMotionCarriesVelocityAndStrideAcrossOpenPlayBoundaries() throws {
        let simulation = try presentationSimulation(seed: 73)
        let motion = MatchMotionTimeline(beats: simulation.beats)
        var movingJoins = 0
        for (index, next) in simulation.beats.enumerated().dropFirst() {
            let previous = simulation.beats[index - 1]
            guard previous.setPiece == nil, next.setPiece == nil,
                  !previous.action.isRestart, !next.action.isRestart else { continue }
            for side in [MatchSide.home, .away] {
                for playerIndex in 1..<11 {
                    let player = MatchPlayerRef(side: side, index: playerIndex)
                    let before = motion.player(player, beatIndex: index - 1, local: 0.99999, duration: 100)
                    let after = motion.player(player, beatIndex: index, local: 0.00001, duration: 100)
                    XCTAssertEqual(before.gaitPhase, after.gaitPhase, accuracy: 0.004)
                    XCTAssertEqual(before.heading, after.heading, accuracy: 0.004)
                    XCTAssertEqual(before.speed, after.speed, accuracy: 0.003)
                    if min(before.speed, after.speed) > 0.005 { movingJoins += 1 }
                }
            }
        }
        XCTAssertGreaterThan(movingJoins, 20, "Continuity must not be achieved by stopping everyone")
    }

    func testSettledSetPieceStopsFeetAndBallRotation() throws {
        let simulation = try presentationSimulation(seed: 31)
        let motion = MatchMotionTimeline(beats: simulation.beats)
        let index = try XCTUnwrap(simulation.beats.firstIndex { if case .setPieceSetup = $0.action { return true }; return false })
        let beat = simulation.beats[index]
        for side in [MatchSide.home, .away] {
            for indexInTeam in 0..<11 {
                let player = MatchPlayerRef(side: side, index: indexInTeam)
                let before = motion.player(player, beatIndex: index, local: 0.8, duration: 100)
                let after = motion.player(player, beatIndex: index, local: 0.95, duration: 100)
                XCTAssertEqual(before.speed, 0, accuracy: 0.00001)
                XCTAssertEqual(after.speed, 0, accuracy: 0.00001)
                XCTAssertEqual(before.gaitPhase, after.gaitPhase, accuracy: 0.00001)
            }
        }
        let before = try presentationFrame(beat, local: 0.8)
        let after = try presentationFrame(beat, local: 0.95)
        XCTAssertEqual(before.ballRotation, after.ballRotation)
    }

    func testShotHasItsImpulseAtContactRatherThanAcceleratingInFlight() throws {
        let beat = try XCTUnwrap(try presentationSimulation(seed: 31).beats.first { $0.action.shotOutcome == .goal && $0.setPiece == nil })
        let release = try presentationFrame(beat, local: 0.26)
        let early = try presentationFrame(beat, local: 0.36)
        let late = try presentationFrame(beat, local: 0.66)
        let nearImpact = try presentationFrame(beat, local: 0.76)
        XCTAssertGreaterThan(release.ball.distance(to: early.ball), late.ball.distance(to: nearImpact.ball))
    }

    func testMotionSamplingIsIndependentOfRenderCadenceAndDuration() throws {
        let beats = try presentationSimulation(seed: 73).beats
        let motion = MatchMotionTimeline(beats: beats)
        let player = MatchPlayerRef(side: .home, index: 8)
        let expected = motion.player(player, beatIndex: 2, local: 0.5, duration: 100)
        for sample in 0..<240 { _ = motion.player(player, beatIndex: 2, local: Double(sample) / 240, duration: 90) }
        let actual = motion.player(player, beatIndex: 2, local: 0.5, duration: 100)
        XCTAssertEqual(expected, actual)
        let slower = motion.player(player, beatIndex: 2, local: 0.5, duration: 110)
        XCTAssertEqual(expected.gaitPhase, slower.gaitPhase)
        XCTAssertEqual(expected.speed * 100, slower.speed * 110, accuracy: 0.00001)
    }

    func testCachedMatchPreservesRenderedContactsAndBeatBoundaries() throws {
        for seed in 0..<8 {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            let motion = MatchMotionTimeline(beats: beats)
            for beat in beats {
                // Test the actual multi-beat cache used by Canvas, not isolated beats.
                let touchTimes = [0.0, 0.16, 0.22, 0.26, 0.28, 0.70, 0.78, 0.84, 1.0]
                for local in touchTimes {
                    let progress = beat.startProgress + (beat.endProgress - beat.startProgress) * local
                    let before = try XCTUnwrap(MatchPresentation.frame(beats: beats, progress: max(0, progress - 0.00000001), motion: motion))
                    let after = try XCTUnwrap(MatchPresentation.frame(beats: beats, progress: min(1, progress + 0.00000001), motion: motion))
                    // Restarts intentionally transfer the invisible ball.
                    if before.ballOpacity > 0.01 && after.ballOpacity > 0.01 {
                        XCTAssertLessThan(before.ball.distance(to: after.ball), 0.0005, "Ball discontinuity: seed \(seed), beat \(beat.id), local \(local)")
                    }
                    for (a, b) in zip(before.homePositions + before.awayPositions, after.homePositions + after.awayPositions) {
                        XCTAssertLessThan(a.distance(to: b), 0.0005)
                    }
                    for positions in [after.homePositions, after.awayPositions] {
                        XCTAssertGreaterThanOrEqual(minimumVisualDistance(in: positions), MatchPitchLayout.minimumVisualDistance - 0.000001)
                    }
                }
            }
        }
    }

    func testReducedMotionHasNoBallSpinOrAirborneTrail() throws {
        let beats = try presentationSimulation(seed: 73).beats
        let motion = MatchMotionTimeline(beats: beats)
        for step in 0...100 {
            let frame = try XCTUnwrap(MatchPresentation.frame(beats: beats, progress: Double(step) / 100,
                                                             reducedMotion: true, motion: motion))
            XCTAssertEqual(frame.ballRotation, 0)
            XCTAssertEqual(frame.ballHeight, 0)
            XCTAssertTrue(frame.trail.isEmpty)
            XCTAssertTrue(frame.trailHeights.isEmpty)
        }
    }

    func testCachedPresentationSamplingPerformance() throws {
        let beats = try presentationSimulation(seed: 73).beats
        let motion = MatchMotionTimeline(beats: beats)
        measure {
            for step in 0..<120 {
                _ = MatchPresentation.frame(beats: beats, progress: Double(step) / 120, motion: motion)
            }
        }
    }

    func testPresentationBallRemainsContinuousWhenReleasedAndReceived() throws {
        let simulation = try presentationSimulation(seed: 73)
        var checkedActions = Set<String>()

        for beat in simulation.beats {
            let touchTimes: [Double]
            switch beat.action {
            case .pass:
                checkedActions.insert("pass")
                touchTimes = [0.22, 0.84]
            case .cross:
                checkedActions.insert("cross")
                touchTimes = [0.16, 0.84]
            case .tackle, .interception:
                checkedActions.insert("recovery")
                touchTimes = [0.28, 0.70]
            case .shot:
                checkedActions.insert("shot")
                touchTimes = [0.26, MatchPresentation.shotImpactProgress]
            default:
                continue
            }

            for local in touchTimes {
                let before = try presentationFrame(beat, local: local - 0.000_001)
                let after = try presentationFrame(beat, local: local + 0.000_001)
                XCTAssertLessThan(
                    before.ball.distance(to: after.ball), 0.000_5,
                    "Visible ball jumps at touch \(local), beat \(beat.id): \(beat.action)"
                )
            }
        }
        XCTAssertEqual(checkedActions, Set(["pass", "cross", "recovery", "shot"]))
    }

    func testPresentationConnectsBallAndPlayersAcrossBeatBoundaries() throws {
        for seed in 0..<8 {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            for (previous, next) in zip(beats, beats.dropFirst()) {
                let end = try presentationFrame(previous, local: 1)
                let start = try presentationFrame(next, local: 0)
                XCTAssertLessThan(end.ball.distance(to: start.ball), 0.000_001,
                                  "Ball jumps between beats \(previous.id) and \(next.id)")
                for (before, after) in zip(end.homePositions + end.awayPositions,
                                           start.homePositions + start.awayPositions) {
                    XCTAssertLessThan(before.distance(to: after), 0.000_001)
                }
            }
        }
    }

    func testPresentationPreservesTwentyTwoReadablePlayersWhileMoving() throws {
        for seed in 10..<14 {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            for beat in beats {
                for local in [0.0, 0.16, 0.28, 0.42, 0.58, 0.70, 0.84, 1.0] {
                    let frame = try presentationFrame(beat, local: local)
                    for positions in [frame.homePositions, frame.awayPositions] {
                        XCTAssertEqual(positions.count, 11)
                        XCTAssertGreaterThanOrEqual(minimumVisualDistance(in: positions),
                                                    MatchPitchLayout.minimumVisualDistance - 0.000_001)
                        for (index, point) in positions.enumerated() {
                            let isPenaltyKeeper = index == 0 && beat.setPiece == .penalty
                            XCTAssertTrue((isPenaltyKeeper ? 0.0...1.0 : 0.04...0.96).contains(point.x))
                            XCTAssertTrue((0.16...0.84).contains(point.y))
                        }
                    }
                }
            }
        }
    }

    func testPresentationCrossHasHeightAndTrailFollowsTheVisibleBall() throws {
        let beats = try presentationSimulation(seed: 73).beats
        let cross = try XCTUnwrap(beats.first { $0.action.isCross })
        let midFlight = try presentationFrame(cross, local: 0.5)
        XCTAssertGreaterThan(midFlight.ballHeight, 0)
        XCTAssertFalse(midFlight.trail.isEmpty)
        XCTAssertLessThanOrEqual(midFlight.trail.count, 7)
        XCTAssertEqual(midFlight.trail.last, midFlight.ball)
        XCTAssertEqual(midFlight.trailHeights.last, midFlight.ballHeight)
        XCTAssertEqual(try presentationFrame(cross, local: 0).ballHeight, 0)
        XCTAssertEqual(try presentationFrame(cross, local: 1).ballHeight, 0)

        let receiver = try XCTUnwrap(cross.action.receiver)
        let received = try presentationFrame(cross, local: 0.90)
        let positions = receiver.side == .home ? received.homePositions : received.awayPositions
        XCTAssertLessThan(received.ball.distance(to: positions[receiver.index]), 0.026,
                          "Reception stays within a foot's reach, not inside the torso")
    }

    func testPresentationResolvesShotsAtTheSharedImpactTime() throws {
        let beats = try presentationSimulation(seed: 31).beats
        let goals = beats.filter { $0.action.shotOutcome == .goal }
        XCTAssertFalse(goals.isEmpty)
        for beat in goals {
            let before = try presentationFrame(beat, local: MatchPresentation.shotImpactProgress - 0.01)
            let impact = try presentationFrame(beat, local: MatchPresentation.shotImpactProgress)
            XCTAssertGreaterThan(before.ball.distance(to: beat.ballEnd), 0.000_001)
            XCTAssertEqual(impact.ball.x, beat.ballEnd.x, accuracy: 0.000_001)
            XCTAssertEqual(impact.ball.y, beat.ballEnd.y, accuracy: 0.000_001)
            XCTAssertEqual(impact.ballHeight, 0, accuracy: 0.000_001)
        }
    }

    func testGoalsEnterTheNetAndConnectToTheFollowingKickoff() throws {
        var checkedGoals = 0
        for seed in 0..<16 {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            for (shot, next) in zip(beats, beats.dropFirst()) {
                guard case let .shot(shooter, .goal) = shot.action else { continue }
                checkedGoals += 1
                let impact = try presentationFrame(shot, local: MatchPresentation.shotImpactProgress)
                if shooter.side == .home {
                    XCTAssertGreaterThan(shot.ballEnd.x, 1, "A home goal must cross the right goal line")
                    XCTAssertGreaterThan(impact.ball.x, 1)
                } else {
                    XCTAssertLessThan(shot.ballEnd.x, 0, "An away goal must cross the left goal line")
                    XCTAssertLessThan(impact.ball.x, 0)
                }
                XCTAssertTrue((-0.04...1.04).contains(shot.ballEnd.x))
                XCTAssertTrue((0.41...0.59).contains(shot.ballEnd.y), "Goals must enter between the posts")
                guard case .restart(_, _, .kickoffAfterGoal) = next.action else {
                    XCTFail("A goal must be followed by a center kickoff")
                    continue
                }
                XCTAssertEqual(shot.ballEnd, next.ballStart)
                let final = try presentationFrame(shot, local: 1)
                let restart = try presentationFrame(next, local: 0)
                XCTAssertLessThan(final.ball.distance(to: restart.ball), 0.000_001)
                XCTAssertEqual(try presentationFrame(next, local: 0.50).ballOpacity, 0,
                               "Returning the ball from the net to midfield must be hidden")
                for position in impact.homePositions + impact.awayPositions {
                    XCTAssertTrue((0.04...0.96).contains(position.x), "Players stay inside the field during goals")
                }
            }
        }
        XCTAssertGreaterThan(checkedGoals, 0)
    }

    func testPresentationReducedMotionKeepsDiscreteResultsAndHidesRestartTransfer() throws {
        let beats = try presentationSimulation(seed: 31).beats
        for beat in beats {
            let final = try presentationFrame(beat, local: 1)
            let reducedFinal = try presentationFrame(beat, local: 1, reducedMotion: true)
            XCTAssertEqual(final.ball, reducedFinal.ball)
            XCTAssertEqual(final.homePositions, reducedFinal.homePositions)
            XCTAssertEqual(final.awayPositions, reducedFinal.awayPositions)
            XCTAssertEqual(reducedFinal.ballHeight, 0)
            XCTAssertTrue(reducedFinal.trail.isEmpty)

            if beat.action.isShot {
                let before = try presentationFrame(beat, local: 0.77, reducedMotion: true)
                let impact = try presentationFrame(beat, local: 0.78, reducedMotion: true)
                XCTAssertLessThan(before.localProgress, MatchPresentation.shotImpactProgress)
                XCTAssertEqual(impact.localProgress, 1)
            }
            if beat.action.isRestart {
                XCTAssertEqual(try presentationFrame(beat, local: 0.50).ballOpacity, 0)
                XCTAssertEqual(try presentationFrame(beat, local: 0.50, reducedMotion: true).ballOpacity, 0)
            }
        }
    }

    func testSetPiecesAppearForBothSidesWithoutForcingAPenaltyInEveryMatch() throws {
        var freeKickSides = Set<MatchSide>()
        var penaltySides = Set<MatchSide>()
        var matchesWithPenalty = 0
        for seed in 0..<48 {
            let simulation = try presentationSimulation(seed: UInt64(seed))
            let shots = simulation.beats.filter { $0.action.isShot }
            let penalties = shots.filter { $0.setPiece == .penalty }
            if !penalties.isEmpty { matchesWithPenalty += 1 }
            XCTAssertLessThanOrEqual(penalties.count, 1)
            for shot in shots {
                let shooter = try XCTUnwrap(shot.action.primaryPlayer)
                if shot.setPiece == .freeKick { freeKickSides.insert(shooter.side) }
                if shot.setPiece == .penalty {
                    penaltySides.insert(shooter.side)
                    XCTAssertNotEqual(shot.action.shotOutcome, .blocked)
                }
            }
            XCTAssertEqual(shots.filter { $0.action.shotOutcome == .goal && $0.possessionBefore == .home }.count,
                           simulation.result.homeGoals)
            XCTAssertEqual(shots.filter { $0.action.shotOutcome == .goal && $0.possessionBefore == .away }.count,
                           simulation.result.awayGoals)
        }
        XCTAssertEqual(freeKickSides, Set([.home, .away]))
        XCTAssertEqual(penaltySides, Set([.home, .away]))
        XCTAssertGreaterThan(matchesWithPenalty, 0)
        XCTAssertLessThan(matchesWithPenalty, 48)
    }

    func testEverySetPieceHasAVisibleFoulSetupShotAndValidRestart() throws {
        var checked = 0
        for seed in 0..<20 {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            for index in beats.indices {
                let setup = beats[index]
                guard case let .setPieceSetup(taker, kind) = setup.action else { continue }
                checked += 1
                XCTAssertGreaterThan(index, 0)
                XCTAssertLessThan(index + 2, beats.count)
                guard case let .foul(carrier, defender) = beats[index - 1].action else {
                    XCTFail("Set piece must visibly follow a foul"); continue
                }
                XCTAssertEqual(carrier.side, taker.side)
                XCTAssertEqual(defender.side, taker.side.opponent)
                XCTAssertEqual(setup.setPiece, kind)
                XCTAssertEqual(setup.ballStart, setup.ballEnd)
                let shot = beats[index + 1]
                XCTAssertEqual(shot.setPiece, kind)
                XCTAssertEqual(shot.action.primaryPlayer, taker)
                XCTAssertTrue(shot.action.isShot)
                XCTAssertTrue(beats[index + 2].action.isRestart)
                for local in [0.0, 0.25, 0.5, 0.75, 1.0] {
                    let frame = try presentationFrame(setup, local: local)
                    XCTAssertEqual(frame.ball, setup.ballStart, "Ball remains at the foul/penalty spot during setup")
                    XCTAssertNil(frame.ballOwner)
                    XCTAssertEqual(frame.ballHeight, 0)
                    XCTAssertTrue(frame.trail.isEmpty)
                }
                let preKick = try presentationFrame(shot, local: 0.20)
                XCTAssertEqual(preKick.ball, setup.ballEnd)
                XCTAssertNil(preKick.ballOwner)
                let reduced = try presentationFrame(shot, local: 0.5, reducedMotion: true)
                XCTAssertEqual(reduced.ballHeight, 0)
                XCTAssertTrue(reduced.trail.isEmpty)
            }
        }
        XCTAssertGreaterThan(checked, 0)
    }

    func testSetPiecesPreserveTheGeneratedResultAndUseTheSharedGoalImpactTime() throws {
        let home = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let away = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var goalKinds = Set<MatchSetPiece>()
        for seed in 0..<48 {
            var resultRNG = SeededGenerator(seed: UInt64(seed))
            var simulationRNG = SeededGenerator(seed: UInt64(seed))
            let originalResult = MatchSimulationFactory.makeResult(home: home, away: away, rng: &resultRNG)
            let simulation = MatchSimulationFactory.makeSimulation(home: home, away: away, rng: &simulationRNG)
            XCTAssertEqual(simulation.result, originalResult, "Presentation cannot change an already-generated result")
            for beat in simulation.beats where beat.action.shotOutcome == .goal {
                guard let kind = beat.setPiece else { continue }
                goalKinds.insert(kind)
                let before = try presentationFrame(beat, local: 0.77)
                let impact = try presentationFrame(beat, local: 0.78)
                XCTAssertGreaterThan(before.ball.distance(to: beat.ballEnd), 0.000_001)
                XCTAssertLessThan(impact.ball.distance(to: beat.ballEnd), 0.000_001)
                let reducedBefore = try presentationFrame(beat, local: 0.77, reducedMotion: true)
                let reducedImpact = try presentationFrame(beat, local: 0.78, reducedMotion: true)
                XCTAssertLessThan(reducedBefore.localProgress, MatchPresentation.shotImpactProgress)
                XCTAssertEqual(reducedImpact.localProgress, 1)
                XCTAssertEqual(reducedImpact.ball.x, impact.ball.x, accuracy: 0.000_000_01)
                XCTAssertEqual(reducedImpact.ball.y, impact.ball.y, accuracy: 0.000_000_01)
            }
        }
        XCTAssertEqual(goalKinds, Set([.freeKick, .penalty]))
    }

    func testPenaltySetupPlacesBallOnSpotAndOtherPlayersOutsideArea() throws {
        var checked = 0
        for seed in 0..<40 {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            for setup in beats where setup.setPiece == .penalty {
                guard case let .setPieceSetup(taker, _) = setup.action else { continue }
                checked += 1
                XCTAssertEqual(setup.ballEnd.x, taker.side == .home ? 0.89 : 0.11, accuracy: 0.000_001)
                XCTAssertEqual(setup.ballEnd.y, 0.5)
                let frame = try presentationFrame(setup, local: 1)
                let opponents = taker.side == .home ? frame.awayPositions : frame.homePositions
                XCTAssertEqual(opponents[0].x, taker.side == .home ? 1 : 0, accuracy: 0.000_001)
                XCTAssertEqual(opponents[0].y, 0.5, accuracy: 0.000_001)
                let shot = try XCTUnwrap(beats.first { $0.id == setup.id + 1 && $0.action.isShot })
                for local in [0.0, 0.10, 0.20, 0.26] {
                    let beforeContact = try presentationFrame(shot, local: local)
                    let defending = taker.side == .home ? beforeContact.awayPositions : beforeContact.homePositions
                    XCTAssertEqual(defending[0].x, taker.side == .home ? 1 : 0, accuracy: 0.000_000_01,
                                   "The keeper cannot leave the goal line before the kick")
                    XCTAssertEqual(defending[0].y, 0.5, accuracy: 0.000_000_01)
                }
                for side in [MatchSide.home, .away] {
                    let positions = side == .home ? frame.homePositions : frame.awayPositions
                    for index in positions.indices where index != 0 && !(side == taker.side && index == taker.index) {
                        let attackX = taker.side == .home ? positions[index].x : 1 - positions[index].x
                        XCTAssertLessThan(attackX, 0.84, "Non-takers wait outside the penalty area")
                        XCTAssertLessThan(attackX, 0.89, "Non-takers wait behind the ball")
                        XCTAssertGreaterThanOrEqual(MatchPitchLayout.visualDistance(positions[index], frame.ball), 0.087)
                    }
                }
            }
        }
        XCTAssertGreaterThan(checked, 0)
    }

    func testFreeKickWallStaysTogetherAndBallArcsOverIt() throws {
        var checked = 0
        for seed in 0..<16 {
            let beats = try presentationSimulation(seed: UInt64(seed)).beats
            for (setup, shot) in zip(beats, beats.dropFirst()) {
                guard case let .setPieceSetup(taker, .freeKick) = setup.action else { continue }
                checked += 1
                let frame = try presentationFrame(setup, local: 1)
                let opponents = taker.side == .home ? frame.awayPositions : frame.homePositions
                let wall = Array(opponents[1...3])
                XCTAssertLessThan(abs(wall[0].x - wall[2].x), 0.000_001)
                XCTAssertGreaterThanOrEqual(abs(wall[0].x - setup.ballEnd.x), 0.087)
                XCTAssertGreaterThanOrEqual(minimumVisualDistance(in: wall), MatchPitchLayout.minimumVisualDistance)
                let flight = try presentationFrame(shot, local: 0.52)
                XCTAssertGreaterThan(flight.ballHeight, 0.50)
                XCTAssertFalse(flight.trail.isEmpty)
                XCTAssertEqual(flight.trail.last, flight.ball)
                let impact = try presentationFrame(shot, local: MatchPresentation.shotImpactProgress)
                XCTAssertEqual(impact.ballHeight, 0, accuracy: 0.000_001)
                if shot.action.shotOutcome == .goal {
                    XCTAssertLessThan(impact.ball.distance(to: shot.ballEnd), 0.000_001)
                }
            }
        }
        XCTAssertGreaterThan(checked, 0)
    }

    private func presentationSimulation(seed: UInt64) throws -> MatchSimulation {
        let home = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_argentina"))
        let away = try XCTUnwrap(CAMI_DATA.team(countryId: "wc26", teamId: "sel_curacao"))
        var rng = SeededGenerator(seed: seed)
        return MatchSimulationFactory.makeSimulation(home: home, away: away, rng: &rng)
    }

    private func presentationFrame(_ beat: MatchBeat, local: Double, reducedMotion: Bool = false) throws -> MatchPresentationFrame {
        let progress = beat.startProgress + (beat.endProgress - beat.startProgress) * local
        return try XCTUnwrap(MatchPresentation.frame(beats: [beat], progress: progress, reducedMotion: reducedMotion))
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

final class ArgentinaTournamentTests: XCTestCase {
    private let officialLPF2026TeamIds: Set<String> = [
        "aldosivi", "argentinos", "atletico_tucuman", "banfield", "barracas_central",
        "belgrano", "boca", "central_cordoba", "defensa_justicia", "riestra",
        "estudiantes_rc", "estu", "gimnasia_lp", "gimnasia_mendoza", "hura",
        "inde", "independiente_rivadavia", "instituto", "lanus", "newells",
        "platense", "racing", "river", "rosa", "sanlo", "sarmiento",
        "talleres", "tigre", "union", "velez"
    ]

    func testArgentinaCatalogContainsEveryLPF2026ClubExactlyOnce() {
        let teams = CAMI_DATA.teams(for: "arg")

        XCTAssertEqual(teams.count, 30)
        XCTAssertEqual(Set(teams.map(\.id)), officialLPF2026TeamIds)
        XCTAssertEqual(Set(teams.map(\.id)).count, teams.count)
    }

    func testArgentinaBracketSeedsAllThirtyClubs() {
        let teams = CAMI_DATA.teams(for: "arg")
        let seedPlan = TournamentSeedPlan(teams: teams)

        XCTAssertTrue(seedPlan.usesRoundOf32)
        XCTAssertEqual(Set(seedPlan.seededTeamIds), officialLPF2026TeamIds)
        XCTAssertEqual(seedPlan.seededTeamIds.count, 30)
        XCTAssertEqual(seedPlan.openingSlots.count, 32)
        XCTAssertEqual(seedPlan.openingSlots.filter { $0 == nil }.count, 2)
    }

    func testSixteenTeamLeagueKeepsExistingBracketShape() {
        let teams = Array(CAMI_DATA.teams(for: "eng").prefix(16))
        let seedPlan = TournamentSeedPlan(teams: teams)

        XCTAssertFalse(seedPlan.usesRoundOf32)
        XCTAssertEqual(seedPlan.seededTeamIds.count, 16)
        XCTAssertEqual(seedPlan.openingSlots.count, 16)
        XCTAssertFalse(seedPlan.openingSlots.contains { $0 == nil })
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
