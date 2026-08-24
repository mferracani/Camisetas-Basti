import Foundation

struct MatchSimulation: Equatable {
    let result: MatchSimulationResult
    let beats: [MatchBeat]
}

struct MatchBeat: Equatable, Identifiable {
    let id: Int
    let startProgress: Double
    let endProgress: Double
    let action: MatchAction
    let possessionBefore: MatchSide
    let possessionAfter: MatchSide
    let ballStart: PitchPoint
    let ballEnd: PitchPoint
    let homeStartPositions: [PitchPoint]
    let homeEndPositions: [PitchPoint]
    let awayStartPositions: [PitchPoint]
    let awayEndPositions: [PitchPoint]

    func localProgress(at matchProgress: Double) -> Double {
        guard endProgress > startProgress else { return 1 }
        return min(1, max(0, (matchProgress - startProgress) / (endProgress - startProgress)))
    }

    func playerPositions(
        for side: MatchSide,
        progress: Double,
        protectedIndex: Int?
    ) -> [PitchPoint] {
        let start = side == .home ? homeStartPositions : awayStartPositions
        let end = side == .home ? homeEndPositions : awayEndPositions
        let interpolated = zip(start, end).map {
            $0.interpolated(to: $1, progress: progress)
        }
        return MatchPitchLayout.resolvedPositions(
            interpolated,
            protectedIndex: protectedIndex
        )
    }
}

struct PitchPoint: Equatable {
    let x: Double
    let y: Double

    static let center = PitchPoint(x: 0.5, y: 0.5)

    func interpolated(to other: PitchPoint, progress: Double) -> PitchPoint {
        PitchPoint(
            x: x + (other.x - x) * progress,
            y: y + (other.y - y) * progress
        )
    }

    func moved(x deltaX: Double, y deltaY: Double = 0) -> PitchPoint {
        PitchPoint(x: x + deltaX, y: y + deltaY).clampedToPitch()
    }

    func clampedToPitch() -> PitchPoint {
        PitchPoint(
            x: min(1.04, max(-0.04, x)),
            y: min(0.86, max(0.14, y))
        )
    }

    func distance(to other: PitchPoint) -> Double {
        hypot(other.x - x, other.y - y)
    }
}

enum MatchPitchLayout {
    static let aspectRatio = 1.72
    // The jersey marker is compact, so this keeps a readable separation without
    // forcing players into visibly artificial positions near the touchline.
    static let minimumVisualDistance = 0.051

    static func visualDistance(_ first: PitchPoint, _ second: PitchPoint) -> Double {
        hypot(second.x - first.x, (second.y - first.y) / aspectRatio)
    }

    static func resolvedPositions(
        _ source: [PitchPoint],
        protectedIndex: Int?
    ) -> [PitchPoint] {
        var positions = source.map(clampedPlayerPoint)

        // Interpolated paths can create a brief three-player cluster even when
        // both endpoints are clear. With 11 players, correcting one pair can
        // affect a pair already visited, so let the solver converge instead of
        // cutting it off at the old fixed number of passes.
        for iteration in 0..<max(24, positions.count * positions.count) {
            var adjustedPair = false

            for firstIndex in positions.indices {
                for secondIndex in positions.indices where secondIndex > firstIndex {
                    let first = positions[firstIndex]
                    let second = positions[secondIndex]
                    let deltaX = second.x - first.x
                    let scaledDeltaY = (second.y - first.y) / aspectRatio
                    let distance = hypot(deltaX, scaledDeltaY)
                    guard distance < minimumVisualDistance else { continue }

                    adjustedPair = true
                    let direction: (x: Double, y: Double)
                    if distance > 0.000_001 {
                        direction = (deltaX / distance, scaledDeltaY / distance)
                    } else {
                        let sign = (firstIndex + secondIndex + iteration).isMultiple(of: 2) ? 1.0 : -1.0
                        direction = (0.32 * sign, 0.947)
                    }

                    let correction = minimumVisualDistance - distance + 0.000_5
                    let firstIsProtected = firstIndex == protectedIndex
                    let secondIsProtected = secondIndex == protectedIndex
                    let firstShare = firstIsProtected ? 0 : (secondIsProtected ? 1 : 0.5)
                    let secondShare = secondIsProtected ? 0 : (firstIsProtected ? 1 : 0.5)

                    positions[firstIndex] = clampedPlayerPoint(
                        PitchPoint(
                            x: first.x - direction.x * correction * firstShare,
                            y: first.y - direction.y * correction * firstShare * aspectRatio
                        )
                    )
                    positions[secondIndex] = clampedPlayerPoint(
                        PitchPoint(
                            x: second.x + direction.x * correction * secondShare,
                            y: second.y + direction.y * correction * secondShare * aspectRatio
                        )
                    )
                }
            }

            if !adjustedPair { break }
        }

        return positions
    }

    private static func clampedPlayerPoint(_ point: PitchPoint) -> PitchPoint {
        PitchPoint(
            x: min(0.96, max(0.04, point.x)),
            y: min(0.84, max(0.16, point.y))
        )
    }
}

struct MatchPlayerRef: Equatable {
    let side: MatchSide
    let index: Int
}

enum MatchShotOutcome: Equatable, Hashable {
    case goal
    case saved
    case wide
    case blocked
}

enum MatchRestartReason: Equatable {
    case kickoffAfterGoal
    case goalkeeperPossession
    case goalKick
    case clearance
}

enum MatchAction: Equatable {
    case kickoff(from: MatchPlayerRef, to: MatchPlayerRef)
    case carry(player: MatchPlayerRef)
    case pass(from: MatchPlayerRef, to: MatchPlayerRef)
    case cross(from: MatchPlayerRef, to: MatchPlayerRef)
    case pressure(carrier: MatchPlayerRef, defender: MatchPlayerRef)
    case duel(carrier: MatchPlayerRef, defender: MatchPlayerRef, retained: Bool)
    case interception(passer: MatchPlayerRef, intendedReceiver: MatchPlayerRef, defender: MatchPlayerRef)
    case tackle(carrier: MatchPlayerRef, defender: MatchPlayerRef)
    case shot(shooter: MatchPlayerRef, outcome: MatchShotOutcome)
    case restart(from: MatchPlayerRef, to: MatchPlayerRef, reason: MatchRestartReason)
    case finalWhistle(possession: MatchSide)
}

extension MatchAction {
    var shotOutcome: MatchShotOutcome? {
        guard case let .shot(_, outcome) = self else { return nil }
        return outcome
    }

    var primaryPlayer: MatchPlayerRef? {
        switch self {
        case let .kickoff(from, _), let .pass(from, _), let .cross(from, _), let .restart(from, _, _): return from
        case let .carry(player): return player
        case let .pressure(carrier, _), let .duel(carrier, _, _), let .tackle(carrier, _): return carrier
        case let .interception(passer, _, _): return passer
        case let .shot(shooter, _): return shooter
        case .finalWhistle: return nil
        }
    }

    var receiver: MatchPlayerRef? {
        switch self {
        case let .kickoff(_, to), let .pass(_, to), let .cross(_, to), let .restart(_, to, _): return to
        case let .interception(_, intendedReceiver, _): return intendedReceiver
        default: return nil
        }
    }

    var defender: MatchPlayerRef? {
        switch self {
        case let .pressure(_, defender), let .duel(_, defender, _), let .tackle(_, defender): return defender
        case let .interception(_, _, defender): return defender
        default: return nil
        }
    }

    var isPass: Bool {
        switch self {
        case .pass, .cross: return true
        default: return false
        }
    }

    var isCross: Bool {
        if case .cross = self { return true }
        return false
    }

    var isShot: Bool {
        if case .shot = self { return true }
        return false
    }

    var isRestart: Bool {
        if case .restart = self { return true }
        return false
    }

    var endingBallOwner: MatchPlayerRef? {
        switch self {
        case let .kickoff(_, to), let .pass(_, to), let .cross(_, to), let .restart(_, to, _):
            return to
        case let .carry(player):
            return player
        case let .pressure(carrier, _), let .duel(carrier, _, _):
            return carrier
        case let .interception(_, _, defender), let .tackle(_, defender):
            return defender
        case let .shot(shooter, outcome):
            switch outcome {
            case .saved:
                return MatchPlayerRef(side: shooter.side.opponent, index: 0)
            case .blocked:
                return MatchPlayerRef(side: shooter.side.opponent, index: 3)
            case .goal, .wide:
                return nil
            }
        case .finalWhistle:
            return nil
        }
    }

    func ballOwner(at localProgress: Double) -> MatchPlayerRef? {
        switch self {
        case let .kickoff(from, to), let .pass(from, to), let .cross(from, to):
            if localProgress < 0.22 { return from }
            if localProgress > 0.84 { return to }
            return nil
        case let .carry(player):
            return player
        case let .pressure(carrier, _), let .duel(carrier, _, _):
            return carrier
        case let .interception(passer, _, defender), let .tackle(passer, defender):
            if localProgress < 0.28 { return passer }
            if localProgress > 0.70 { return defender }
            return nil
        case let .shot(shooter, _):
            return localProgress < 0.30 ? shooter : nil
        case let .restart(from, to, _):
            if localProgress >= 0.42 && localProgress < 0.82 { return from }
            if localProgress > 0.88 { return to }
            return nil
        case .finalWhistle:
            return nil
        }
    }

    var restartOrigin: PitchPoint? {
        guard case let .restart(from, _, reason) = self else { return nil }
        switch reason {
        case .kickoffAfterGoal:
            return .center
        case .goalkeeperPossession, .goalKick, .clearance:
            return MatchFormation.basePosition(for: from)
        }
    }
}

extension MatchSimulationFactory {
    static func makeSimulation(home: Team, away: Team) -> MatchSimulation {
        var rng = SystemRandomNumberGenerator()
        return makeSimulation(home: home, away: away, rng: &rng)
    }

    static func makeSimulation<R: RandomNumberGenerator>(
        home: Team,
        away: Team,
        rng: inout R
    ) -> MatchSimulation {
        let result = makeResult(home: home, away: away, rng: &rng)
        var builder = MatchTimelineBuilder(result: result, rng: rng)
        let beats = builder.build()
        rng = builder.rng
        return MatchSimulation(result: result, beats: beats)
    }
}

private struct MatchTimelineBuilder<R: RandomNumberGenerator> {
    var rng: R

    private let result: MatchSimulationResult
    private var possession: MatchSide = .home
    private var carrier = MatchPlayerRef(side: .home, index: 6)
    private var ball = PitchPoint.center
    private var homePositions = MatchFormation.positions(for: .home, possession: .home, ball: .center)
    private var awayPositions = MatchFormation.positions(for: .away, possession: .home, ball: .center)
    private var drafts: [DraftBeat] = []
    private var passIndex = 0
    private var recoveryIndex = 0

    init(result: MatchSimulationResult, rng: R) {
        self.result = result
        self.rng = rng
    }

    mutating func build() -> [MatchBeat] {
        addKickoff(side: .home)

        // Establish both teams as real participants before the first highlight.
        addPassSequence(side: .home, count: 8, destination: nil)
        addRecovery(winner: .away, kind: .interception)
        addPassSequence(side: .away, count: 8, destination: nil)
        addRecovery(winner: .home, kind: .tackle)

        for (index, shot) in shotPlans().enumerated() {
            if possession != shot.side {
                addRecovery(
                    winner: shot.side,
                    kind: index.isMultiple(of: 2) ? .interception : .tackle
                )
            }
            let shooter = addAttackBuildUp(for: shot.side, sequenceIndex: index, shot: shot)
            addShot(shot, preferredShooter: shooter)
            addRestart(after: shot)

            if index.isMultiple(of: 2) {
                addPassSequence(side: possession, count: 2, destination: nil)
                addRecovery(
                    winner: possession.opponent,
                    kind: recoveryIndex.isMultiple(of: 2) ? .tackle : .interception
                )
            }
        }

        // A final short exchange prevents the animation from ending on a frozen restart.
        addPassSequence(side: possession, count: 2, destination: nil)
        addFinalWhistle()
        return normalizedBeats()
    }

    private mutating func shotPlans() -> [ShotPlan] {
        var plans = result.chanceEvents.map { chance in
            ShotPlan(
                minute: Double(chance.minute),
                side: chance.side,
                outcome: shotOutcome(for: chance.outcome)
            )
        }

        if !plans.contains(where: { $0.outcome == .wide }) {
            plans.append(randomExtraShot(outcome: .wide, minuteRange: 14...76))
        }
        if !plans.contains(where: { $0.outcome == .saved }) {
            plans.append(randomExtraShot(outcome: .saved, minuteRange: 20...82))
        }
        plans.append(randomExtraShot(outcome: .blocked, minuteRange: 10...84))
        return plans.sorted { $0.minute < $1.minute }
    }

    private mutating func randomExtraShot(outcome: MatchShotOutcome, minuteRange: ClosedRange<Int>) -> ShotPlan {
        ShotPlan(
            minute: Double(Int.random(in: minuteRange, using: &rng)),
            side: Bool.random(using: &rng) ? .home : .away,
            outcome: outcome
        )
    }

    private func shotOutcome(for chanceOutcome: MatchChanceOutcome) -> MatchShotOutcome {
        switch chanceOutcome {
        case .goal: return .goal
        case .save: return .saved
        case .wide: return .wide
        }
    }

    private mutating func addKickoff(side: MatchSide) {
        possession = side
        let from = MatchPlayerRef(side: side, index: 5)
        let to = MatchPlayerRef(side: side, index: 6)
        let destination = PitchPoint(x: side == .home ? 0.54 : 0.46, y: 0.5)
        setPosition(from, point: ball, home: &homePositions, away: &awayPositions)
        addBeat(
            action: .kickoff(from: from, to: to),
            weight: 0.85,
            ballEnd: destination,
            possessionAfter: side
        )
        carrier = to
    }

    private mutating func addPassSequence(side: MatchSide, count: Int, destination: PitchPoint?) {
        guard possession == side else { return }
        for step in 0..<count {
            let targetIndex = nextPassingTarget(after: carrier.index, step: step)
            let receiver = MatchPlayerRef(side: side, index: targetIndex)
            let end: PitchPoint
            if let destination {
                let remaining = Double(max(1, count - step))
                end = ball.interpolated(to: destination, progress: 1 / remaining)
            } else {
                end = naturalPassDestination(for: receiver, side: side)
            }
            addBeat(
                action: .pass(from: carrier, to: receiver),
                weight: ball.distance(to: end) > 0.20 ? 1.04 : 0.76,
                ballEnd: end,
                possessionAfter: side
            )
            carrier = receiver
            passIndex += 1

            if step < count - 1 && (passIndex + step).isMultiple(of: 3) {
                addCarry(side: side)
            }
        }
    }

    private mutating func addCarry(side: MatchSide) {
        let direction = side.attackDirection
        let laneNudge = (carrier.index + passIndex).isMultiple(of: 2) ? 0.035 : -0.035
        let end = ball.moved(x: direction * 0.055, y: laneNudge)
        addBeat(
            action: .carry(player: carrier),
            weight: 0.66,
            ballEnd: end,
            possessionAfter: side
        )
    }

    private mutating func addAttackBuildUp(
        for side: MatchSide,
        sequenceIndex: Int,
        shot: ShotPlan
    ) -> MatchPlayerRef {
        if sequenceIndex % 3 == 1 {
            return addWideCrossAttack(for: side, sequenceIndex: sequenceIndex, shot: shot)
        }

        let lane = [0.34, 0.66, 0.43, 0.57][sequenceIndex % 4]
        let origin = PitchPoint(x: side == .home ? 0.79 : 0.21, y: lane)
        addPassSequence(side: side, count: 2 + (sequenceIndex % 2), destination: origin)

        let defender = nearestOutfieldPlayer(on: side.opponent, to: ball)
        let pressureEnd = ball.moved(x: side.attackDirection * 0.018)
        addBeat(
            action: .pressure(carrier: carrier, defender: defender),
            weight: 0.52,
            ballEnd: pressureEnd,
            possessionAfter: side
        )

        if sequenceIndex.isMultiple(of: 2) {
            let duelEnd = pressureEnd.moved(
                x: side.attackDirection * 0.032,
                y: sequenceIndex.isMultiple(of: 4) ? 0.018 : -0.018
            )
            addBeat(
                action: .duel(carrier: carrier, defender: defender, retained: true),
                weight: 0.62,
                ballEnd: duelEnd,
                possessionAfter: side
            )
        }

        return MatchPlayerRef(side: side, index: [8, 9, 10][sequenceIndex % 3])
    }

    private mutating func addWideCrossAttack(
        for side: MatchSide,
        sequenceIndex: Int,
        shot: ShotPlan
    ) -> MatchPlayerRef {
        let winger = MatchPlayerRef(side: side, index: sequenceIndex.isMultiple(of: 2) ? 8 : 10)
        let striker = MatchPlayerRef(side: side, index: 9)
        let wingY = winger.index == 8 ? 0.20 : 0.80
        let wideReceivingPoint = PitchPoint(x: side == .home ? 0.72 : 0.28, y: wingY)
        let bylinePoint = PitchPoint(x: side == .home ? 0.88 : 0.12, y: winger.index == 8 ? 0.17 : 0.83)

        addPassSequence(side: side, count: 2, destination: wideReceivingPoint)
        if carrier != winger {
            addBeat(
                action: .pass(from: carrier, to: winger),
                weight: 0.92,
                ballEnd: wideReceivingPoint,
                possessionAfter: side
            )
            carrier = winger
        }

        addBeat(
            action: .carry(player: winger),
            weight: 0.72,
            ballEnd: bylinePoint,
            possessionAfter: side
        )

        let arrival = shotOrigin(for: shot)
        addBeat(
            action: .cross(from: winger, to: striker),
            weight: 1.14,
            ballEnd: arrival,
            possessionAfter: side
        )
        carrier = striker

        let defender = nearestOutfieldPlayer(on: side.opponent, to: arrival)
        addBeat(
            action: .duel(carrier: striker, defender: defender, retained: true),
            weight: 0.48,
            ballEnd: arrival,
            possessionAfter: side
        )

        return striker
    }

    private mutating func addRecovery(winner: MatchSide, kind: RecoveryKind) {
        guard possession != winner else { return }
        let loser = possession
        let oldCarrier = carrier
        let defender = nearestOutfieldPlayer(on: winner, to: ball)
        let pressureEnd = ball.moved(
            x: loser.attackDirection * 0.012,
            y: recoveryIndex.isMultiple(of: 2) ? 0.012 : -0.012
        )
        addBeat(
            action: .pressure(carrier: oldCarrier, defender: defender),
            weight: 0.42,
            ballEnd: pressureEnd,
            possessionAfter: loser
        )

        let end = pressureEnd.moved(
            x: winner.attackDirection * 0.045,
            y: recoveryIndex.isMultiple(of: 2) ? 0.028 : -0.028
        )
        let action: MatchAction
        switch kind {
        case .interception:
            let intended = MatchPlayerRef(side: loser, index: nextPassingTarget(after: oldCarrier.index, step: recoveryIndex))
            action = .interception(passer: oldCarrier, intendedReceiver: intended, defender: defender)
        case .tackle:
            action = .tackle(carrier: oldCarrier, defender: defender)
        }
        addBeat(
            action: action,
            weight: 0.68,
            ballEnd: end,
            possessionAfter: winner
        )
        possession = winner
        carrier = defender
        recoveryIndex += 1
    }

    private mutating func addShot(_ shot: ShotPlan, preferredShooter: MatchPlayerRef) {
        let shooter = preferredShooter
        if carrier != shooter {
            addBeat(
                action: .pass(from: carrier, to: shooter),
                weight: 0.64,
                ballEnd: shotOrigin(for: shot),
                possessionAfter: shot.side
            )
            carrier = shooter
        }

        let end = shotTarget(for: shot)
        addBeat(
            action: .shot(shooter: shooter, outcome: shot.outcome),
            weight: shot.outcome == .goal ? 1.32 : 0.92,
            ballEnd: end,
            possessionAfter: shot.side.opponent
        )
        possession = shot.side.opponent
        carrier = MatchPlayerRef(side: possession, index: 0)
    }

    private mutating func addRestart(after shot: ShotPlan) {
        let side = shot.side.opponent
        let from: MatchPlayerRef
        let to: MatchPlayerRef
        let reason: MatchRestartReason
        let destination: PitchPoint

        switch shot.outcome {
        case .goal:
            from = MatchPlayerRef(side: side, index: 5)
            to = MatchPlayerRef(side: side, index: 6)
            reason = .kickoffAfterGoal
            destination = PitchPoint(x: side == .home ? 0.54 : 0.46, y: 0.5)
        case .saved:
            from = MatchPlayerRef(side: side, index: 0)
            to = MatchPlayerRef(side: side, index: 3)
            reason = .goalkeeperPossession
            destination = MatchFormation.basePosition(for: to)
        case .wide:
            from = MatchPlayerRef(side: side, index: 0)
            to = MatchPlayerRef(side: side, index: 2)
            reason = .goalKick
            destination = MatchFormation.basePosition(for: to)
        case .blocked:
            from = MatchPlayerRef(side: side, index: 3)
            to = MatchPlayerRef(side: side, index: 5)
            reason = .clearance
            destination = MatchFormation.basePosition(for: to)
        }

        addBeat(
            action: .restart(from: from, to: to, reason: reason),
            weight: shot.outcome == .goal ? 1.05 : 0.78,
            ballEnd: destination,
            possessionAfter: side
        )
        carrier = to
    }

    private mutating func addFinalWhistle() {
        addBeat(
            action: .finalWhistle(possession: possession),
            weight: 0.72,
            ballEnd: ball,
            possessionAfter: possession
        )
    }

    private mutating func addBeat(
        action: MatchAction,
        weight: Double,
        ballEnd: PitchPoint,
        possessionAfter: MatchSide
    ) {
        let startHome = homePositions
        let startAway = awayPositions
        var endHome = MatchFormation.advancedPositions(
            from: homePositions,
            for: .home,
            possession: possessionAfter,
            ball: ballEnd
        )
        var endAway = MatchFormation.advancedPositions(
            from: awayPositions,
            for: .away,
            possession: possessionAfter,
            ball: ballEnd
        )
        applyActionPositions(
            action: action,
            ballStart: ball,
            ballEnd: ballEnd,
            home: &endHome,
            away: &endAway
        )
        let endingOwner = action.endingBallOwner
        endHome = MatchPitchLayout.resolvedPositions(
            endHome,
            protectedIndex: endingOwner?.side == .home ? endingOwner?.index : nil
        )
        endAway = MatchPitchLayout.resolvedPositions(
            endAway,
            protectedIndex: endingOwner?.side == .away ? endingOwner?.index : nil
        )

        drafts.append(
            DraftBeat(
                weight: weight,
                action: action,
                possessionBefore: possession,
                possessionAfter: possessionAfter,
                ballStart: ball,
                ballEnd: ballEnd,
                homeStartPositions: startHome,
                homeEndPositions: endHome,
                awayStartPositions: startAway,
                awayEndPositions: endAway
            )
        )
        ball = ballEnd
        homePositions = endHome
        awayPositions = endAway
        possession = possessionAfter
    }

    private func applyActionPositions(
        action: MatchAction,
        ballStart: PitchPoint,
        ballEnd: PitchPoint,
        home: inout [PitchPoint],
        away: inout [PitchPoint]
    ) {
        switch action {
        case let .kickoff(from, to), let .pass(from, to), let .cross(from, to):
            setPosition(from, point: ballStart, home: &home, away: &away)
            setPosition(to, point: ballEnd, home: &home, away: &away)
        case let .carry(player):
            setPosition(player, point: ballEnd, home: &home, away: &away)
        case let .pressure(carrier, defender):
            setPosition(carrier, point: ballEnd, home: &home, away: &away)
            setPosition(
                defender,
                point: ballEnd.moved(x: -carrier.side.attackDirection * 0.034, y: 0.026),
                home: &home,
                away: &away
            )
        case let .duel(carrier, defender, _):
            setPosition(carrier, point: ballEnd, home: &home, away: &away)
            setPosition(
                defender,
                point: ballEnd.moved(x: -carrier.side.attackDirection * 0.020, y: 0.020),
                home: &home,
                away: &away
            )
        case let .interception(passer, intendedReceiver, defender):
            setPosition(passer, point: ballStart, home: &home, away: &away)
            setPosition(
                intendedReceiver,
                point: ballEnd.moved(x: passer.side.attackDirection * 0.055, y: 0.035),
                home: &home,
                away: &away
            )
            setPosition(defender, point: ballEnd, home: &home, away: &away)
        case let .tackle(carrier, defender):
            setPosition(
                carrier,
                point: ballEnd.moved(x: carrier.side.attackDirection * 0.025, y: -0.022),
                home: &home,
                away: &away
            )
            setPosition(defender, point: ballEnd, home: &home, away: &away)
        case let .shot(shooter, outcome):
            setPosition(shooter, point: ballStart, home: &home, away: &away)
            let goalkeeper = MatchPlayerRef(side: shooter.side.opponent, index: 0)
            switch outcome {
            case .saved:
                setPosition(goalkeeper, point: ballEnd, home: &home, away: &away)
            case .blocked:
                let blocker = MatchPlayerRef(side: shooter.side.opponent, index: 3)
                setPosition(blocker, point: ballEnd, home: &home, away: &away)
            case .goal, .wide:
                let diveDirection = ballEnd.y >= 0.5 ? 1.0 : -1.0
                setPosition(
                    goalkeeper,
                    point: MatchFormation.basePosition(for: goalkeeper).moved(x: 0, y: diveDirection * 0.075),
                    home: &home,
                    away: &away
                )
            }
        case let .restart(from, to, _):
            setPosition(
                from,
                point: action.restartOrigin ?? MatchFormation.basePosition(for: from),
                home: &home,
                away: &away
            )
            setPosition(to, point: ballEnd, home: &home, away: &away)
        case .finalWhistle:
            break
        }
    }

    private func setPosition(
        _ player: MatchPlayerRef,
        point: PitchPoint,
        home: inout [PitchPoint],
        away: inout [PitchPoint]
    ) {
        guard (0..<MatchFormation.playerCount).contains(player.index) else { return }
        if player.side == .home {
            home[player.index] = point.clampedToPitch()
        } else {
            away[player.index] = point.clampedToPitch()
        }
    }

    private func naturalPassDestination(for receiver: MatchPlayerRef, side: MatchSide) -> PitchPoint {
        let tacticalTarget = MatchFormation.position(
            for: receiver,
            possession: side,
            ball: ball
        )
        let distance = ball.distance(to: tacticalTarget)
        guard distance >= 0.075 else {
            return tacticalTarget.moved(
                x: side.attackDirection * 0.055,
                y: tacticalTarget.y < 0.5 ? -0.025 : 0.025
            )
        }
        return tacticalTarget
    }

    private func nextPassingTarget(after current: Int, step: Int) -> Int {
        let connections: [Int: [Int]] = [
            0: [2, 3, 5],
            1: [5, 6, 8],
            2: [5, 6, 1],
            3: [5, 7, 4],
            4: [5, 7, 10],
            5: [6, 7, 2, 3],
            6: [8, 9, 5, 1],
            7: [10, 9, 5, 4],
            8: [9, 6, 5],
            9: [8, 10, 6, 7],
            10: [9, 7, 5]
        ]
        let candidates = connections[current] ?? [5, 6, 7]
        return candidates[(passIndex + step) % candidates.count]
    }

    private func nearestOutfieldPlayer(on side: MatchSide, to point: PitchPoint) -> MatchPlayerRef {
        let positions = side == .home ? homePositions : awayPositions
        let index = positions.indices.dropFirst().min { first, second in
            positions[first].distance(to: point) < positions[second].distance(to: point)
        } ?? 1
        return MatchPlayerRef(side: side, index: index)
    }

    private func shotOrigin(for shot: ShotPlan) -> PitchPoint {
        PitchPoint(
            x: shot.side == .home ? 0.80 : 0.20,
            y: min(0.68, max(0.32, ball.y))
        )
    }

    private func shotTarget(for shot: ShotPlan) -> PitchPoint {
        let goalX = shot.side == .home ? 0.985 : 0.015
        let keeperX = shot.side == .home ? 0.94 : 0.06
        let blockX = shot.side == .home ? 0.88 : 0.12
        let laneOffset = Double((Int(shot.minute) % 5) - 2) * 0.035
        switch shot.outcome {
        case .goal:
            return PitchPoint(x: goalX, y: 0.50 + laneOffset)
        case .saved:
            return PitchPoint(x: keeperX, y: 0.50 + laneOffset)
        case .wide:
            return PitchPoint(x: goalX, y: Int(shot.minute).isMultiple(of: 2) ? 0.27 : 0.73)
        case .blocked:
            return PitchPoint(x: blockX, y: 0.50 + laneOffset)
        }
    }

    private func normalizedBeats() -> [MatchBeat] {
        let totalWeight = drafts.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return [] }
        var cursor = 0.0
        return drafts.enumerated().map { index, draft in
            let start = cursor / totalWeight
            cursor += draft.weight
            let end = index == drafts.count - 1 ? 1 : cursor / totalWeight
            return MatchBeat(
                id: index,
                startProgress: start,
                endProgress: end,
                action: draft.action,
                possessionBefore: draft.possessionBefore,
                possessionAfter: draft.possessionAfter,
                ballStart: draft.ballStart,
                ballEnd: draft.ballEnd,
                homeStartPositions: draft.homeStartPositions,
                homeEndPositions: draft.homeEndPositions,
                awayStartPositions: draft.awayStartPositions,
                awayEndPositions: draft.awayEndPositions
            )
        }
    }
}

private struct ShotPlan {
    let minute: Double
    let side: MatchSide
    let outcome: MatchShotOutcome
}

private enum RecoveryKind {
    case interception
    case tackle
}

private struct DraftBeat {
    let weight: Double
    let action: MatchAction
    let possessionBefore: MatchSide
    let possessionAfter: MatchSide
    let ballStart: PitchPoint
    let ballEnd: PitchPoint
    let homeStartPositions: [PitchPoint]
    let homeEndPositions: [PitchPoint]
    let awayStartPositions: [PitchPoint]
    let awayEndPositions: [PitchPoint]
}

private enum MatchFormation {
    static let playerCount = 11

    private static let homeBase: [PitchPoint] = [
        PitchPoint(x: 0.07, y: 0.50),
        PitchPoint(x: 0.22, y: 0.20),
        PitchPoint(x: 0.18, y: 0.39),
        PitchPoint(x: 0.18, y: 0.61),
        PitchPoint(x: 0.22, y: 0.80),
        PitchPoint(x: 0.40, y: 0.50),
        PitchPoint(x: 0.44, y: 0.31),
        PitchPoint(x: 0.44, y: 0.69),
        PitchPoint(x: 0.70, y: 0.21),
        PitchPoint(x: 0.78, y: 0.50),
        PitchPoint(x: 0.70, y: 0.79)
    ]

    static func positions(for side: MatchSide, possession: MatchSide, ball: PitchPoint) -> [PitchPoint] {
        let base = side == .home
            ? homeBase
            : homeBase.map { PitchPoint(x: 1 - $0.x, y: $0.y) }
        let isAttacking = side == possession
        let horizontalShift = (ball.x - 0.5) * (isAttacking ? 0.38 : 0.28)
        let verticalCenter = 0.5 + (ball.y - 0.5) * (isAttacking ? 0.22 : 0.16)
        let verticalSpread = isAttacking ? 0.96 : 0.84

        return base.enumerated().map { index, point in
            if index == 0 {
                return point.moved(
                    x: horizontalShift * 0.28,
                    y: (ball.y - 0.5) * 0.08
                )
            }
            return PitchPoint(
                x: point.x + horizontalShift,
                y: verticalCenter + (point.y - 0.5) * verticalSpread
            ).clampedToPitch()
        }
    }

    static func position(for player: MatchPlayerRef, possession: MatchSide, ball: PitchPoint) -> PitchPoint {
        let positions = positions(for: player.side, possession: possession, ball: ball)
        guard positions.indices.contains(player.index) else { return .center }
        return positions[player.index]
    }

    static func advancedPositions(
        from current: [PitchPoint],
        for side: MatchSide,
        possession: MatchSide,
        ball: PitchPoint
    ) -> [PitchPoint] {
        let target = positions(for: side, possession: possession, ball: ball)
        return zip(current, target).enumerated().map { index, pair in
            let maxTravel = index == 0 ? 0.018 : 0.044
            return move(pair.0, toward: pair.1, maximumDistance: maxTravel)
        }
    }

    private static func move(
        _ source: PitchPoint,
        toward destination: PitchPoint,
        maximumDistance: Double
    ) -> PitchPoint {
        let deltaX = destination.x - source.x
        let deltaY = destination.y - source.y
        let distance = hypot(deltaX, deltaY)
        guard distance > maximumDistance, distance > 0.000_001 else { return destination }
        return source.moved(
            x: deltaX / distance * maximumDistance,
            y: deltaY / distance * maximumDistance
        )
    }

    static func basePosition(for player: MatchPlayerRef) -> PitchPoint {
        let points = player.side == .home
            ? homeBase
            : homeBase.map { PitchPoint(x: 1 - $0.x, y: $0.y) }
        guard points.indices.contains(player.index) else { return .center }
        return points[player.index]
    }
}

extension MatchSide {
    var opponent: MatchSide {
        self == .home ? .away : .home
    }

    var attackDirection: Double {
        self == .home ? 1 : -1
    }
}
