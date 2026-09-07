import Foundation

struct MatchPresentationFrame {
    let beat: MatchBeat
    let localProgress: Double
    let homePositions: [PitchPoint]
    let awayPositions: [PitchPoint]
    let ball: PitchPoint
    let ballOwner: MatchPlayerRef?
    let ballHeight: Double
    let ballOpacity: Double
    let trail: [PitchPoint]
    let trailHeights: [Double]
    let homeMotion: [MatchPlayerMotion]
    let awayMotion: [MatchPlayerMotion]
    let ballRotation: Double
}

/// Pure visual sampling: playback, the ball trail and tests share the same path.
/// This never changes a generated event, its timing or its result.
enum MatchPresentation {
    static let shotImpactProgress = 0.78

    static func frame(
        beats: [MatchBeat],
        progress: Double,
        reducedMotion: Bool = false,
        motion suppliedMotion: MatchMotionTimeline? = nil,
        duration: Double = 100
    ) -> MatchPresentationFrame? {
        guard !beats.isEmpty else { return nil }
        let index = beats.firstIndex(where: {
            progress >= $0.startProgress && progress < $0.endProgress
        }) ?? (progress < beats[0].startProgress ? 0 : beats.count - 1)
        let beat = beats[index]
        let motion = suppliedMotion ?? MatchMotionTimeline(beats: beats)
        let sampledLocal = beat.localProgress(at: progress)
        let rawLocal = sampledLocal < 0.000_000_001 ? 0 : (sampledLocal > 0.999_999_999 ? 1 : sampledLocal)
        let local = reducedMotion ? discreteProgress(rawLocal, action: beat.action) : rawLocal
        let home = motion.positions(beatIndex: index, side: .home, local: local)
        let away = motion.positions(beatIndex: index, side: .away, local: local)
        let owner = ballOwner(beat, local: local)
        let flight = owner == nil ? flightPath(beat, motion: motion, index: index) : nil
        let ball: PitchPoint
        if let owner {
            ball = position(owner, motion: motion, index: index, local: local)
        } else if case .setPieceSetup = beat.action {
            ball = beat.ballStart
        } else if beat.setPiece != nil && beat.action.isShot && local < 0.26 {
            ball = beat.ballStart
        } else if beat.action.isRestart && local < 0.42 {
            ball = beat.ballStart
        } else {
            ball = flight?.point(at: local) ?? beat.ballStart
        }

        let trailPoints = reducedMotion ? [] : trail(beat, local: local, flight: flight)
        return MatchPresentationFrame(
            beat: beat,
            localProgress: local,
            homePositions: home,
            awayPositions: away,
            ball: ball,
            ballOwner: owner,
            ballHeight: reducedMotion ? 0 : ballHeight(beat, local: local),
            ballOpacity: ballOpacity(beat.action, local: local),
            trail: trailPoints,
            trailHeights: trailPoints.indices.map { sample in
                let start = max(flight?.release ?? local, local - 0.12)
                return ballHeight(beat, local: start + (local - start) * Double(sample) / 6)
            },
            homeMotion: (0..<11).map { motion.player(MatchPlayerRef(side: .home, index: $0), beatIndex: index, local: local, duration: duration) },
            awayMotion: (0..<11).map { motion.player(MatchPlayerRef(side: .away, index: $0), beatIndex: index, local: local, duration: duration) },
            ballRotation: reducedMotion ? 0 : ball.x * 150 + ball.y * 85
        )
    }

    private static func position(_ player: MatchPlayerRef, motion: MatchMotionTimeline, index: Int, local: Double) -> PitchPoint {
        let base = motion.positions(beatIndex: index, side: player.side, local: local)[player.index]
        let pose = motion.player(player, beatIndex: index, local: local, duration: 100)
        // Preserve the same contact point across uninterrupted possession. A foul
        // or restart settles the ball onto its explicit stationary timeline anchor.
        let previousOwner = index > 0 ? motion.beats[index - 1].action.endingBallOwner : nil
        let nextOwner = index + 1 < motion.beats.count ? ballOwner(motion.beats[index + 1], local: 0) : nil
        let from = previousOwner == player && ballOwner(motion.beats[index], local: 0) == player
            ? 1 : MatchMotionTimeline.smooth(local / 0.14)
        let to = nextOwner == player && motion.beats[index].action.endingBallOwner == player
            ? 1 : MatchMotionTimeline.smooth((1 - local) / 0.14)
        let touch = (0.008 + 0.003 * (1 - cos(pose.gaitPhase * 2))) * from * to
        return PitchPoint(x: base.x + cos(pose.heading) * touch,
                          y: base.y + sin(pose.heading) * touch * MatchPitchLayout.aspectRatio)
    }

    private static func ballOwner(_ beat: MatchBeat, local: Double) -> MatchPlayerRef? {
        let action = beat.action
        switch action {
        case let .kickoff(from, to), let .pass(from, to):
            return local < 0.22 ? from : (local >= 0.84 ? to : nil)
        case let .cross(from, to):
            return local < 0.16 ? from : (local >= 0.84 ? to : nil)
        case let .carry(player), let .pressure(player, _), let .duel(player, _, _), let .foul(player, _):
            return player
        case let .tackle(from, defender), let .interception(from, _, defender):
            return local < 0.28 ? from : (local >= 0.70 ? defender : nil)
        case let .shot(shooter, _):
            if beat.setPiece != nil {
                return local >= shotImpactProgress ? action.endingBallOwner : nil
            }
            if local < 0.26 { return shooter }
            return local >= shotImpactProgress ? action.endingBallOwner : nil
        case let .restart(from, to, _):
            if local >= 0.90 { return to }
            return local >= 0.42 && local < 0.58 ? from : nil
        case .setPieceSetup, .finalWhistle:
            return nil
        }
    }

    private static func flightPath(_ beat: MatchBeat, motion: MatchMotionTimeline, index: Int) -> FlightPath? {
        switch beat.action {
        case let .kickoff(from, to), let .pass(from, to):
            return flight(beat, motion: motion, index: index, from: from, to: to, release: 0.22, arrival: 0.84)
        case let .cross(from, to):
            return flight(beat, motion: motion, index: index, from: from, to: to, release: 0.16, arrival: 0.84, curved: true)
        case let .tackle(from, defender), let .interception(from, _, defender):
            return flight(beat, motion: motion, index: index, from: from, to: defender, release: 0.28, arrival: 0.70)
        case let .shot(shooter, _):
            let start = beat.setPiece == nil ? position(shooter, motion: motion, index: index, local: 0.26) : beat.ballStart
            let end = beat.action.endingBallOwner.map {
                position($0, motion: motion, index: index, local: shotImpactProgress)
            } ?? beat.ballEnd
            let control = beat.setPiece == .freeKick ? PitchPoint(
                x: (start.x + end.x) / 2,
                y: (start.y + end.y) / 2 + (start.y < 0.5 ? -0.085 : 0.085)
            ) : nil
            return FlightPath(start: start, end: end, release: 0.26,
                              arrival: shotImpactProgress, control: control, drag: 0.32)
        case let .restart(from, to, _):
            return flight(beat, motion: motion, index: index, from: from, to: to, release: 0.58, arrival: 0.90)
        case .carry, .pressure, .duel, .foul, .setPieceSetup, .finalWhistle:
            return nil
        }
    }

    private static func flight(
        _ beat: MatchBeat,
        motion: MatchMotionTimeline,
        index: Int,
        from: MatchPlayerRef,
        to: MatchPlayerRef,
        release: Double,
        arrival: Double,
        curved: Bool = false
    ) -> FlightPath {
        let start = position(from, motion: motion, index: index, local: release)
        let end = position(to, motion: motion, index: index, local: arrival)
        let controlX = from.side == .home
            ? min(0.96, max(start.x, end.x) + 0.07)
            : max(0.04, min(start.x, end.x) - 0.07)
        let control: PitchPoint? = curved ? PitchPoint(
            x: controlX,
            y: (start.y + end.y) / 2
        ) : nil
        return FlightPath(start: start, end: end, release: release, arrival: arrival, control: control)
    }

    private static func ballHeight(_ beat: MatchBeat, local: Double) -> Double {
        let travel: Double
        let height: Double
        switch beat.action {
        case .cross:
            travel = phase(local, from: 0.16, to: 0.84)
            height = 1
        case .shot:
            travel = phase(local, from: 0.26, to: shotImpactProgress)
            height = beat.setPiece == .freeKick ? 0.82 : (beat.setPiece == .penalty ? 0.18 : 0.28)
        default:
            return 0
        }
        guard travel > 0, travel < 1 else { return 0 }
        return sin(travel * .pi) * height
    }

    private static func ballOpacity(_ action: MatchAction, local: Double) -> Double {
        guard action.isRestart else { return 1 }
        if local < 0.42 { return 1 - local / 0.42 }
        if local < 0.58 { return 0 }
        return min(1, (local - 0.58) / 0.32)
    }

    private static func trail(_ beat: MatchBeat, local: Double, flight: FlightPath?) -> [PitchPoint] {
        guard let flight else { return [] }
        switch beat.action {
        case .pass where beat.ballStart.distance(to: beat.ballEnd) > 0.13:
            break
        case .cross, .shot:
            break
        default:
            return []
        }
        guard local > flight.release, local < flight.arrival else { return [] }
        let start = max(flight.release, local - 0.12)
        return (0..<7).map { index in
            flight.point(at: index == 6 ? local : start + (local - start) * Double(index) / 6)
        }
    }

    private static func discreteProgress(_ local: Double, action: MatchAction) -> Double {
        if action.isShot {
            if local < 0.26 { return 0 }
            return local + 0.000_000_001 < shotImpactProgress ? 0.52 : 1
        }
        if action.isRestart {
            if local < 0.42 { return 0 }
            return local < 0.74 ? 0.50 : 1
        }
        if local < 0.34 { return 0 }
        return local < 0.84 ? 0.55 : 1
    }

    private static func phase(_ value: Double, from start: Double, to end: Double) -> Double {
        min(1, max(0, (value - start) / (end - start)))
    }

    private struct FlightPath {
        let start: PitchPoint
        let end: PitchPoint
        let release: Double
        let arrival: Double
        var control: PitchPoint? = nil
        var drag = 0.16

        func point(at local: Double) -> PitchPoint {
            let phase = MatchPresentation.phase(local, from: release, to: arrival)
            // Impulse is at the foot; rolling/flight loses speed, never gains it.
            let travel = phase + drag * phase * (1 - phase)
            guard let control else { return start.interpolated(to: end, progress: travel) }
            let inverse = 1 - travel
            return PitchPoint(
                x: inverse * inverse * start.x + 2 * inverse * travel * control.x + travel * travel * end.x,
                y: inverse * inverse * start.y + 2 * inverse * travel * control.y + travel * travel * end.y
            )
        }
    }
}
