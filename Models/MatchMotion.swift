import Foundation

struct MatchPlayerMotion: Equatable {
    let heading: Double
    let speed: Double
    let gaitPhase: Double
    let turn: Double

    static let still = MatchPlayerMotion(heading: 0, speed: 0, gaitPhase: 0, turn: 0)
}

/// Immutable, small trajectory cache. Built once per match, never per display tick.
/// Tracks share velocity and zero acceleration at beat boundaries. Short smooth
/// ramps lead into a steady cruise; arc length, not render ticks, drives feet.
struct MatchMotionTimeline {
    static let playbackDuration = 110.0
    let beats: [MatchBeat]
    private var tracks: [[Curve]] = []
    private static let samples = 24

    init(beats: [MatchBeat]) {
        self.beats = beats
        var distance = Array(repeating: 0.0, count: 22)
        var heading = (0..<22).map { $0 < 11 ? 0.0 : Double.pi }
        for (beatIndex, beat) in beats.enumerated() {
            var players: [Curve] = []
            for slot in 0..<22 {
                let player = MatchPlayerRef(side: slot < 11 ? .home : .away, index: slot % 11)
                let ends = Self.endpoints(beat, player: player)
                let window = Self.window(beat, player: player)
                let span = beat.endProgress - beat.startProgress
                let startVelocity = beatIndex > 0
                    ? Self.join(beats[beatIndex - 1], beat, player: player) : PitchPoint(x: 0, y: 0)
                let endVelocity = beatIndex + 1 < beats.count
                    ? Self.join(beat, beats[beatIndex + 1], player: player) : PitchPoint(x: 0, y: 0)
                players.append(Curve(start: ends.0, end: ends.1,
                                  tangentStart: PitchPoint(x: startVelocity.x * span, y: startVelocity.y * span),
                                  tangentEnd: PitchPoint(x: endVelocity.x * span, y: endVelocity.y * span),
                                  window: window, span: span))
            }
            Self.planPassingLanes(&players, owner: beat.action.endingBallOwner)
            for slot in players.indices {
                players[slot].limitBendSpeed(duration: Self.playbackDuration)
            }
            for slot in 0..<22 {
                let player = MatchPlayerRef(side: slot < 11 ? .home : .away, index: slot % 11)
                var curve = players[slot]
                let span = curve.span
                var last = curve.point(0)
                for step in 0...Self.samples {
                    let local = Double(step) / Double(Self.samples)
                    let point = curve.point(local)
                    distance[slot] += MatchPitchLayout.visualDistance(last, point)
                    let velocity = curve.derivative(local)
                    var target = hypot(velocity.x, velocity.y) > 0.00001
                        ? atan2(velocity.y / MatchPitchLayout.aspectRatio, velocity.x) : heading[slot]
                    // The body opens toward the pass/shot before contact; stationary
                    // defenders watch the ball rather than marching in attack direction.
                    if beat.action.primaryPlayer == player, let contact = Self.contact(beat.action),
                       local < contact + 0.12 {
                        target = atan2((beat.ballEnd.y - point.y) / MatchPitchLayout.aspectRatio,
                                       beat.ballEnd.x - point.x)
                    } else if case .setPieceSetup = beat.action, local > 0.72 {
                        let aim = beat.action.primaryPlayer == player ? beat.ballEnd : beat.ballStart
                        if point.distance(to: aim) > 0.005 {
                            target = atan2((aim.y - point.y) / MatchPitchLayout.aspectRatio, aim.x - point.x)
                        }
                    }
                    if step > 0 {
                        let dt = span * 100 / Double(Self.samples)
                        heading[slot] += Self.angleDelta(heading[slot], target) * (1 - exp(-dt / 0.12))
                    }
                    curve.distances.append(distance[slot])
                    curve.headings.append(heading[slot])
                    last = point
                }
                players[slot] = curve
            }
            tracks.append(players)
        }
    }

    func positions(beatIndex: Int, side: MatchSide, local: Double) -> [PitchPoint] {
        let offset = side == .home ? 0 : 11
        let raw = (0..<11).map { tracks[beatIndex][offset + $0].point(local) }
        let beat = beats[beatIndex]
        let owner = beat.action.endingBallOwner
        var result = MatchPitchLayout.resolvedPositions(raw, protectedIndex: owner?.side == side ? owner?.index : nil)
        if beat.setPiece == .penalty, beat.action.primaryPlayer?.side != side,
           (beat.action.isShot || { if case .setPieceSetup = beat.action { return true }; return false }()) {
            result[0] = raw[0] // Lawful line position, not the outfield clamp.
        }
        return result
    }

    func player(_ player: MatchPlayerRef, beatIndex: Int, local: Double, duration: Double) -> MatchPlayerMotion {
        let slot = (player.side == .home ? 0 : 11) + player.index
        let curve = tracks[beatIndex][slot]
        let velocity = curve.derivative(local)
        let speed = hypot(velocity.x, velocity.y / MatchPitchLayout.aspectRatio) / max(0.00001, curve.span * duration)
        let heading = curve.sample(curve.headings, local)
        let turn = (curve.sample(curve.headings, min(1, local + 0.025))
                    - curve.sample(curve.headings, max(0, local - 0.025))) / max(0.05, curve.span * duration * 0.05)
        return MatchPlayerMotion(heading: heading, speed: speed,
                                 gaitPhase: curve.sample(curve.distances, local) / 0.055 * .pi * 2 + Double(slot) * 1.71,
                                 turn: min(1, max(-1, turn * 0.12)))
    }

    static func contact(_ action: MatchAction) -> Double? {
        switch action {
        case .shot: return 0.26
        case .cross: return 0.16
        case .pass, .kickoff: return 0.22
        case .restart: return 0.58
        default: return nil
        }
    }

    static func smooth(_ value: Double) -> Double {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }

    /// Plan a small passing lane before playback. Resolving a crossing only at
    /// the current frame can abruptly push a teammate to the other side. These
    /// bends anticipate the crossing, with zero offset/velocity at both ends.
    private static func planPassingLanes(_ curves: inout [Curve], owner: MatchPlayerRef?) {
        for offset in [0, 11] {
            let protected = owner.map { ($0.side == .home ? 0 : 11) + $0.index }
            for _ in 0..<16 {
                var changed = false
                for first in offset..<(offset + 10) {
                    for second in (first + 1)..<(offset + 11) {
                        var closest = Double.greatestFiniteMagnitude, at = 0.5
                        for step in 1..<60 {
                            let t = Double(step) / 60
                            guard curves[first].bend(t) + curves[second].bend(t) > 0.15 else { continue }
                            let d = MatchPitchLayout.visualDistance(curves[first].point(t), curves[second].point(t))
                            if d < closest { closest = d; at = t }
                        }
                        guard closest < MatchPitchLayout.minimumVisualDistance - 0.0005 else { continue }
                        let va = curves[first].derivative(at, excludingBend: true)
                        let vb = curves[second].derivative(at, excludingBend: true)
                        var nx = -(va.y - vb.y) / MatchPitchLayout.aspectRatio, ny = va.x - vb.x
                        if hypot(nx, ny) < 0.0001 { nx = 0; ny = 1 }
                        let length = hypot(nx, ny)
                        nx /= length; ny /= length
                        let bumpA = curves[first].bend(at), bumpB = curves[second].bend(at)
                        let correction = min(0.035, (MatchPitchLayout.minimumVisualDistance + 0.003 - closest)
                            / max(0.15, bumpA + bumpB))
                        var bestA = curves[first], bestB = curves[second], bestClearance = closest
                        // Try both shoulders and field axes. The ball receiver is
                        // protected in playback, so teammates must yield here too.
                        // Score the WHOLE crossing after applying the speed budget;
                        // shrinking a bend afterwards used to invalidate its route.
                        for vector in [(nx, ny), (-nx, -ny), (1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0)] {
                            var a = curves[first], b = curves[second]
                            let shareA = first == protected ? 0.0 : (second == protected ? 2.0 : 1.0)
                            let shareB = second == protected ? 0.0 : (first == protected ? 2.0 : 1.0)
                            a.avoidance = a.avoidance.addingBend(x: vector.0 * correction * shareA,
                                y: vector.1 * correction * shareA * MatchPitchLayout.aspectRatio, limit: 0.055)
                            b.avoidance = b.avoidance.addingBend(x: -vector.0 * correction * shareB,
                                y: -vector.1 * correction * shareB * MatchPitchLayout.aspectRatio, limit: 0.055)
                            a.limitBendSpeed(duration: playbackDuration)
                            b.limitBendSpeed(duration: playbackDuration)
                            var clearance = Double.greatestFiniteMagnitude
                            for step in 1..<60 {
                                let t = Double(step) / 60
                                guard a.bend(t) + b.bend(t) > 0.15 else { continue }
                                clearance = min(clearance, MatchPitchLayout.visualDistance(a.point(t), b.point(t)))
                            }
                            if clearance > bestClearance + 0.00001 {
                                bestA = a; bestB = b; bestClearance = clearance
                            }
                        }
                        if bestClearance > closest + 0.00001 {
                            curves[first] = bestA; curves[second] = bestB
                            changed = true
                        }
                    }
                }
                if !changed { break }
            }
        }
    }

    private static func angleDelta(_ from: Double, _ to: Double) -> Double {
        atan2(sin(to - from), cos(to - from))
    }

    private static func endpoints(_ beat: MatchBeat, player: MatchPlayerRef) -> (PitchPoint, PitchPoint) {
        var start = (player.side == .home ? beat.homeStartPositions : beat.awayStartPositions)[player.index]
        var end = (player.side == .home ? beat.homeEndPositions : beat.awayEndPositions)[player.index]
        if player.index == 0, beat.setPiece == .penalty, let taker = beat.action.primaryPlayer, taker.side != player.side {
            let line = PitchPoint(x: taker.side == .home ? 1 : 0, y: 0.5)
            if case .setPieceSetup = beat.action { end = line }
            if beat.action.isShot { start = line }
        }
        return (start, end)
    }

    private static func window(_ beat: MatchBeat, player: MatchPlayerRef) -> (Double, Double) {
        if case .setPieceSetup = beat.action { return (0, 0.72) }
        if beat.setPiece != nil, beat.action.isShot {
            return beat.action.primaryPlayer == player ? (0, 0.26) : (0.26, MatchPresentation.shotImpactProgress)
        }
        if case let .restart(from, _, _) = beat.action, from == player { return (0, 0.5) }
        return (0, 1)
    }

    private static func join(_ before: MatchBeat, _ after: MatchBeat, player: MatchPlayerRef) -> PitchPoint {
        let zero = PitchPoint(x: 0, y: 0)
        guard window(before, player: player) == (0, 1), window(after, player: player) == (0, 1) else { return zero }
        let a = endpoints(before, player: player), b = endpoints(after, player: player)
        let da = max(0.00001, before.endProgress - before.startProgress)
        let db = max(0.00001, after.endProgress - after.startProgress)
        let vx = (a.1.x - a.0.x) / da, vy = (a.1.y - a.0.y) / da
        let wx = (b.1.x - b.0.x) / db, wy = (b.1.y - b.0.y) / db
        let va = hypot(vx, vy), vb = hypot(wx, wy)
        guard min(va, vb) > 0.00001 else { return zero }
        let alignment = (vx * wx + vy * wy) / (va * vb)
        guard alignment > -0.5 else { return zero } // Plant to reverse, don't loop around.
        let x = (vx + wx) * 0.5, y = (vy + wy) * 0.5
        let limit = min(1, min(va, vb) * 1.2 / max(0.00001, hypot(x, y)))
        return PitchPoint(x: x * limit, y: y * limit)
    }

    private struct Curve {
        let start: PitchPoint
        let end: PitchPoint
        let tangentStart: PitchPoint
        let tangentEnd: PitchPoint
        let window: (Double, Double)
        let span: Double
        var avoidance = PitchPoint(x: 0, y: 0)
        var distances: [Double] = []
        var headings: [Double] = []

        func point(_ local: Double) -> PitchPoint {
            let base = basePoint(local), amount = bend(local)
            // Plan against the same touchlines used by the renderer. An outward
            // bend cannot provide clearance when both players are on the wing.
            return PitchPoint(x: min(max(0.96, start.x, end.x), max(min(0.04, start.x, end.x), base.x + avoidance.x * amount)),
                              y: min(0.84, max(0.16, base.y + avoidance.y * amount)))
        }

        func bend(_ local: Double) -> Double {
            let t = min(1, max(0, (local - window.0) / (window.1 - window.0)))
            return 64 * t * t * t * pow(1 - t, 3)
        }

        private func basePoint(_ local: Double) -> PitchPoint {
            let t = min(1, max(0, (local - window.0) / (window.1 - window.0)))
            let cruise = cruiseVelocity
            if t < ramp {
                let area = ramp * integratedRamp(t / ramp)
                return PitchPoint(x: start.x + tangentStart.x * t + (cruise.x - tangentStart.x) * area,
                                  y: start.y + tangentStart.y * t + (cruise.y - tangentStart.y) * area)
            }
            if t > 1 - ramp {
                let remaining = 1 - t, area = ramp * integratedRamp(remaining / ramp)
                return PitchPoint(x: end.x - tangentEnd.x * remaining - (cruise.x - tangentEnd.x) * area,
                                  y: end.y - tangentEnd.y * remaining - (cruise.y - tangentEnd.y) * area)
            }
            return PitchPoint(x: start.x + tangentStart.x * ramp / 2 + cruise.x * (t - ramp / 2),
                              y: start.y + tangentStart.y * ramp / 2 + cruise.y * (t - ramp / 2))
        }

        func derivative(_ local: Double, excludingBend: Bool = false) -> PitchPoint {
            guard local >= window.0, local <= window.1 else { return PitchPoint(x: 0, y: 0) }
            let t = (local - window.0) / (window.1 - window.0)
            let cruise = cruiseVelocity
            let velocity = t < ramp ? tangentStart.interpolated(to: cruise, progress: MatchMotionTimeline.smooth(t / ramp))
                : t > 1 - ramp ? tangentEnd.interpolated(to: cruise, progress: MatchMotionTimeline.smooth((1 - t) / ramp))
                : cruise
            let scale = 1 / (window.1 - window.0)
            let bendRate = excludingBend ? 0 : 192 * t * t * (1 - t) * (1 - t) * (1 - 2 * t)
            return PitchPoint(x: (velocity.x + avoidance.x * bendRate) * scale,
                              y: (velocity.y + avoidance.y * bendRate) * scale)
        }

        private var ramp: Double { 0.14 }
        private var cruiseVelocity: PitchPoint {
            PitchPoint(x: (end.x - start.x - ramp * (tangentStart.x + tangentEnd.x) / 2) / (1 - ramp),
                       y: (end.y - start.y - ramp * (tangentStart.y + tangentEnd.y) / 2) / (1 - ramp))
        }
        private func integratedRamp(_ t: Double) -> Double { t * t * t - 0.5 * t * t * t * t }

        mutating func limitBendSpeed(duration: Double) {
            guard hypot(avoidance.x, avoidance.y) > 0.00001 else { return }
            // A sidestep cannot turn into a sprint of its own. Reduce the actual
            // bend (not merely the reported speed); endpoints and shared velocity
            // stay unchanged. The final spacing solver handles the small remainder.
            for _ in 0..<10 {
                let peak = (0...40).map { sample -> Double in
                    let v = derivative(Double(sample) / 40)
                    return hypot(v.x, v.y / MatchPitchLayout.aspectRatio) / max(0.00001, span * duration)
                }.max() ?? 0
                if peak <= 0.097 { return }
                avoidance = PitchPoint(x: avoidance.x * 0.8, y: avoidance.y * 0.8)
            }
        }

        func sample(_ values: [Double], _ local: Double) -> Double {
            let sample = min(Double(values.count - 1), max(0, local * Double(values.count - 1)))
            let index = min(values.count - 2, Int(sample))
            return values[index] + (values[index + 1] - values[index]) * (sample - Double(index))
        }
    }
}

private extension PitchPoint {
    func addingBend(x: Double, y: Double, limit: Double) -> PitchPoint {
        let point = PitchPoint(x: self.x + x, y: self.y + y)
        let length = hypot(point.x, point.y / MatchPitchLayout.aspectRatio)
        let scale = min(1, limit / max(0.00001, length))
        return PitchPoint(x: point.x * scale, y: point.y * scale)
    }
}
