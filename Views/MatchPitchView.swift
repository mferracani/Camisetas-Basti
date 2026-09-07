import SwiftUI

/// A single drawing surface keeps the 22 articulated players and their effects
/// on the same clock, without a separate animation or timer per player.
struct MatchPitchView: View {
    let home: Team
    let away: Team
    let frame: MatchPresentationFrame?
    let beats: [MatchBeat]
    let progress: Double
    let elapsed: TimeInterval
    let duration: TimeInterval
    let reduceMotion: Bool

    private var moment: MatchGoalMoment? {
        guard let beat = beats.last(where: {
            $0.action.shotOutcome == .goal && progress >= $0.startProgress
                + ($0.endProgress - $0.startProgress) * MatchPresentation.shotImpactProgress
        }), let scorer = beat.action.primaryPlayer else { return nil }
        let impact = beat.startProgress + (beat.endProgress - beat.startProgress) * MatchPresentation.shotImpactProgress
        let age = (progress - impact) * duration
        guard age < 2.4 else { return nil }
        return MatchGoalMoment(side: scorer.side, age: age)
    }

    var body: some View {
        GeometryReader { geo in
            let field = CGRect(x: geo.size.width * 0.075, y: geo.size.height * 0.075,
                               width: geo.size.width * 0.85, height: geo.size.height * 0.85)
            let styles = MatchKitStyle.pair(home: home, away: away)
            ZStack {
                MatchStadium(homeColor: styles.0.primary, awayColor: styles.1.primary)
                Canvas { context, size in
                    #if DEBUG
                    let drawStart = CFAbsoluteTimeGetCurrent()
                    defer { MatchRenderProbe.shared.record(start: drawStart, progress: progress) }
                    #endif
                    guard let frame else { return }
                    let painter = MatchPitchPainter(field: field, scale: min(1.15, max(0.72, size.width / 1000)))
                    painter.drawCrowd(in: &context, size: size, time: reduceMotion ? 0 : elapsed, moment: moment,
                                      home: styles.0.primary, away: styles.1.primary)
                    painter.drawGoalNets(in: &context, moment: reduceMotion ? nil : moment)
                    painter.drawSetPiece(in: &context, frame: frame)
                    let players = [MatchSide.home, .away].flatMap { side in
                        (0..<11).map { MatchPlayerRef(side: side, index: $0) }
                    }.sorted { a, b in
                        let aY = (a.side == .home ? frame.homePositions : frame.awayPositions)[a.index].y
                        let bY = (b.side == .home ? frame.homePositions : frame.awayPositions)[b.index].y
                        return aY < bY
                    }
                    for player in players {
                        let positions = player.side == .home ? frame.homePositions : frame.awayPositions
                        painter.drawPlayer(in: &context, player: player, point: positions[player.index], frame: frame,
                                           kit: player.side == .home ? styles.0 : styles.1,
                                           time: elapsed, duration: duration, beats: beats, moment: moment,
                                           reduceMotion: reduceMotion)
                    }
                    painter.drawBall(in: &context, frame: frame)
                    if !reduceMotion, let moment {
                        painter.drawCelebration(in: &context, moment: moment,
                                                color: moment.side == .home ? styles.0.primary : styles.1.primary)
                    }
                }
                if let moment {
                    goalBanner(moment)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.20)
                } else if let frame, let outcome = frame.beat.action.shotOutcome,
                          frame.localProgress >= MatchPresentation.shotImpactProgress {
                    outcomeBadge(outcome)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.15)
                } else if let frame, let label = setPieceLabel(frame) {
                    Label(label, systemImage: frame.beat.setPiece == .penalty ? "scope" : "hand.raised.fill")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#FFC93C"))
                        .padding(.horizontal, 22).padding(.vertical, 11)
                        .background(Capsule().fill(Color(hex: "#142936").opacity(0.96)))
                        .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 1))
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.13)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.16), lineWidth: 1))
            .shadow(color: .black.opacity(0.32), radius: 18, y: 12)
        }
        .accessibilityHidden(true)
    }

    private func goalBanner(_ moment: MatchGoalMoment) -> some View {
        let team = moment.side == .home ? home : away
        return HStack(spacing: 14) {
            CrestView(crest: team.crest, size: 44)
                .padding(8).background(Circle().fill(.white))
            VStack(alignment: .leading, spacing: -3) {
                Text("¡GOOOL!").font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#FFC93C"))
                Text(team.short.uppercased()).font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 10)
        .background(Capsule().fill(Color(hex: "#142936").opacity(0.96)))
        .overlay(Capsule().stroke(Color(hex: "#FFC93C"), lineWidth: 2))
        .scaleEffect(reduceMotion ? 1 : 1 + 0.10 * exp(-moment.age * 5) * sin(moment.age * 18))
        .opacity(reduceMotion ? 1 : min(1, max(0, (2.4 - moment.age) / 0.35)))
    }

    private func outcomeBadge(_ outcome: MatchShotOutcome) -> some View {
        let label: String = outcome == .saved ? "¡QUÉ ATAJADA!" : outcome == .wide ? "¡CERQUITA!" : "¡BLOQUEÓ!"
        let icon = outcome == .saved ? "hand.raised.fill" : outcome == .wide ? "arrow.up.right" : "shield.fill"
        return Label(label, systemImage: icon)
            .font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 11)
            .background(Capsule().fill(Color(hex: "#142936").opacity(0.94)))
            .overlay(Capsule().stroke(.white.opacity(0.30), lineWidth: 1))
    }

    private func setPieceLabel(_ frame: MatchPresentationFrame) -> String? {
        switch frame.beat.action {
        case .foul: return "¡FALTA!"
        case let .setPieceSetup(_, kind): return kind == .penalty ? "¡PENAL!" : "TIRO LIBRE · BARRERA LISTA"
        case .shot where frame.beat.setPiece != nil && frame.localProgress < 0.34:
            return frame.beat.setPiece == .penalty ? "RESPIRA… Y PATEA" : "¡VA EL TIRO LIBRE!"
        default: return nil
        }
    }
}

#if DEBUG
/// Opt-in aggregate render diagnostics, never included in Release or user data.
private final class MatchRenderProbe: @unchecked Sendable {
    static let shared = MatchRenderProbe()
    // All mutable diagnostic state is protected by this lock.
    private var last: Double?
    private var intervals: [Double] = []
    private var drawTimes: [Double] = []
    private let lock = NSLock()

    func record(start: Double, progress: Double) {
        guard ProcessInfo.processInfo.arguments.contains("--motion-diagnostics") else { return }
        lock.lock()
        defer { lock.unlock() }
        if let last, start > last, start - last < 1 { intervals.append(start - last) }
        last = start
        drawTimes.append(CFAbsoluteTimeGetCurrent() - start)
        if intervals.count >= 240 {
            let ordered = intervals.sorted()
            let fps = Double(intervals.count) / intervals.reduce(0, +)
            let p95 = ordered[Int(Double(ordered.count - 1) * 0.95)] * 1000
            let draw = drawTimes.reduce(0, +) / Double(drawTimes.count) * 1000
            print(String(format: "MATCH-RENDER progress=%.3f fps=%.1f p95-gap-ms=%.1f draw-ms=%.2f", progress, fps, p95, draw))
            intervals.removeAll(keepingCapacity: true)
            drawTimes.removeAll(keepingCapacity: true)
        }
    }
}
#endif

private struct MatchGoalMoment {
    let side: MatchSide
    let age: Double
}

private struct MatchStadium: View {
    let homeColor: Color
    let awayColor: Color

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(Path(bounds), with: .color(Color(hex: "#142A2C")))
            let field = CGRect(x: size.width * 0.075, y: size.height * 0.075,
                               width: size.width * 0.85, height: size.height * 0.85)
            context.fill(Path(roundedRect: field.insetBy(dx: -12, dy: -12), cornerRadius: 12),
                         with: .color(Color(hex: "#23533E")))
            context.fill(Path(field), with: .linearGradient(
                Gradient(colors: [Color(hex: "#389753"), Color(hex: "#267747")]),
                startPoint: CGPoint(x: field.minX, y: field.minY), endPoint: CGPoint(x: field.maxX, y: field.maxY)))
            for stripe in 0..<12 where stripe.isMultiple(of: 2) {
                let rect = CGRect(x: field.minX + CGFloat(stripe) * field.width / 12,
                                  y: field.minY, width: field.width / 12, height: field.height)
                context.fill(Path(rect), with: .color(.white.opacity(0.045)))
            }
            // Field markings and the ball use precisely the same pitch rectangle.
            var lines = Path(field)
            lines.move(to: CGPoint(x: field.midX, y: field.minY))
            lines.addLine(to: CGPoint(x: field.midX, y: field.maxY))
            let radius = field.width * 0.087
            lines.addEllipse(in: CGRect(x: field.midX - radius, y: field.midY - radius,
                                       width: radius * 2, height: radius * 2))
            for right in [false, true] {
                let x = right ? field.maxX - field.width * 0.16 : field.minX
                lines.addRect(CGRect(x: x, y: field.midY - field.height * 0.24,
                                     width: field.width * 0.16, height: field.height * 0.48))
                lines.addRect(CGRect(x: right ? field.maxX - field.width * 0.055 : field.minX,
                                     y: field.midY - field.height * 0.13,
                                     width: field.width * 0.055, height: field.height * 0.26))
                let spot = CGPoint(x: right ? field.maxX - field.width * 0.11 : field.minX + field.width * 0.11,
                                   y: field.midY)
                context.fill(Path(ellipseIn: CGRect(x: spot.x - 2.5, y: spot.y - 2.5, width: 5, height: 5)),
                             with: .color(.white.opacity(0.8)))
            }
            context.stroke(lines, with: .color(.white.opacity(0.74)), lineWidth: 2)
            context.fill(Path(ellipseIn: CGRect(x: field.midX - 3, y: field.midY - 3, width: 6, height: 6)),
                         with: .color(.white))
            for right in [false, true] {
                for bottom in [false, true] {
                    let x = right ? field.maxX : field.minX
                    let y = bottom ? field.maxY : field.minY
                    var flag = Path()
                    flag.move(to: CGPoint(x: x, y: y + 2))
                    flag.addLine(to: CGPoint(x: x, y: y - 12))
                    context.stroke(flag, with: .color(.white), lineWidth: 1.6)
                    flag.addLine(to: CGPoint(x: x + (right ? -9 : 9), y: y - 9))
                    flag.addLine(to: CGPoint(x: x, y: y - 6))
                    context.fill(flag, with: .color(Color(hex: "#FFC93C")))
                }
            }
            for right in [false, true] {
                let board = CGRect(x: right ? size.width * 0.62 : size.width * 0.17,
                                   y: size.height * 0.949, width: size.width * 0.21, height: size.height * 0.032)
                context.fill(Path(roundedRect: board, cornerRadius: 4),
                             with: .color((right ? awayColor : homeColor).opacity(0.7)))
                context.draw(Text("CAMISETAS BASTI").font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white), at: CGPoint(x: board.midX, y: board.midY))
            }
        }
    }
}

private struct MatchPitchPainter {
    let field: CGRect
    let scale: CGFloat

    func point(_ p: PitchPoint) -> CGPoint {
        CGPoint(x: field.minX + p.x * field.width, y: field.minY + p.y * field.height)
    }

    func drawSetPiece(in context: inout GraphicsContext, frame: MatchPresentationFrame) {
        guard case let .setPieceSetup(taker, kind) = frame.beat.action else { return }
        let ball = point(frame.beat.ballEnd)
        context.stroke(Path(ellipseIn: CGRect(x: ball.x - 11, y: ball.y - 7, width: 22, height: 14)),
                       with: .color(.white.opacity(0.7)), lineWidth: 1.5)
        if kind == .freeKick {
            let defenders = taker.side == .home ? frame.awayPositions : frame.homePositions
            guard defenders.count > 3 else { return }
            // A short vanishing-spray line makes the three-player wall easy to read.
            var spray = Path()
            let wall = (1...3).map { point(defenders[$0]) }.sorted { $0.y < $1.y }
            spray.move(to: CGPoint(x: wall[0].x - taker.side.attackDirection * 9, y: wall[0].y - 9))
            for player in wall {
                spray.addLine(to: CGPoint(x: player.x - taker.side.attackDirection * 9, y: player.y + 9))
            }
            context.stroke(spray, with: .color(.white.opacity(frame.localProgress)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [3, 3]))
        }
    }

    func drawCrowd(in context: inout GraphicsContext, size: CGSize, time: Double,
                   moment: MatchGoalMoment?, home: Color, away: Color) {
        for row in 0..<3 {
            for seat in 0..<76 {
                let phase = Double(seat) * 0.71 + Double(row) * 1.8
                let cheer = moment == nil ? 0.4 : 2.0
                let bounce = time == 0 ? 0 : sin(time * (moment == nil ? 1.8 : 10) + phase) * cheer
                let x = size.width * (0.085 + Double(seat) * 0.011)
                let y = size.height * 0.018 + Double(row) * 6 + bounce
                let color = seat.isMultiple(of: 5) ? Color(hex: "#F2D8B5") : (seat < 38 ? home : away)
                context.fill(Path(roundedRect: CGRect(x: x, y: y, width: 5, height: 5), cornerRadius: 2),
                             with: .color(color.opacity(row == 2 ? 0.85 : 0.52)))
            }
        }
    }

    func drawGoalNets(in context: inout GraphicsContext, moment: MatchGoalMoment?) {
        for right in [false, true] {
            let ripple = moment.map { goal -> Double in
                guard (goal.side == .home) == right else { return 0 }
                return sin(goal.age * 28) * exp(-goal.age * 5) * 5
            } ?? 0
            let rect = CGRect(x: right ? field.maxX : field.minX - 24 * scale,
                              y: field.midY - field.height * 0.105,
                              width: 24 * scale, height: field.height * 0.21)
            context.fill(Path(rect), with: .color(.white.opacity(0.12)))
            var net = Path()
            for column in 0...4 {
                let x = rect.minX + Double(column) * rect.width / 4
                net.move(to: CGPoint(x: x, y: rect.minY))
                net.addQuadCurve(to: CGPoint(x: x, y: rect.maxY), control: CGPoint(x: x + ripple, y: rect.midY))
            }
            for row in 0...10 {
                let y = rect.minY + Double(row) * rect.height / 10
                net.move(to: CGPoint(x: rect.minX, y: y))
                net.addLine(to: CGPoint(x: rect.maxX + ripple, y: y))
            }
            context.stroke(net, with: .color(.white.opacity(0.28)), lineWidth: 0.8)
            context.stroke(Path(rect), with: .color(.white.opacity(0.90)), lineWidth: 2.4)
        }
    }

    func drawPlayer(in context: inout GraphicsContext, player: MatchPlayerRef, point position: PitchPoint,
                    frame: MatchPresentationFrame, kit: MatchKitStyle, time: Double, duration: Double,
                    beats: [MatchBeat], moment: MatchGoalMoment?, reduceMotion: Bool) {
        let pose = (player.side == .home ? frame.homeMotion : frame.awayMotion)[player.index]
        let running = reduceMotion ? 0 : min(1, pose.speed / 0.07)
        let heading = pose.heading
        let forward = CGPoint(x: cos(heading), y: sin(heading))
        let width = 0.72 + 0.28 * abs(sin(heading))
        let active = frame.ballOwner == player
        let isKeeper = player.index == 0
        let seconds = max(0.1, (frame.beat.endProgress - frame.beat.startProgress) * duration)
        let contact = MatchMotionTimeline.contact(frame.beat.action)
        let kickAge = contact.map { (frame.localProgress - $0) * seconds } ?? 10
        let isKicker = frame.beat.action.primaryPlayer == player && contact != nil && !reduceMotion
        let plant = isKicker ? MatchMotionTimeline.smooth((kickAge + 0.27) / 0.12)
            * (1 - MatchMotionTimeline.smooth((kickAge - 0.09) / 0.25)) : 0
        let swing: Double = !isKicker ? 0 : kickAge < -0.10
            ? -MatchMotionTimeline.smooth((kickAge + 0.27) / 0.17)
            : kickAge < 0.04 ? -1 + 2 * MatchMotionTimeline.smooth((kickAge + 0.10) / 0.14)
            : 1 - MatchMotionTimeline.smooth((kickAge - 0.04) / 0.28)
        let inWall = frame.beat.setPiece == .freeKick && (1...3).contains(player.index)
            && frame.beat.action.primaryPlayer?.side != player.side && frame.beat.action.isShot
        let wallAge = (frame.localProgress - 0.29) * seconds
        let wallJump = inWall && wallAge > 0 && wallAge < 0.55 ? sin(wallAge / 0.55 * .pi) * 6 : 0
        let celebrates = moment?.side == player.side && player.index >= 8
        let celebrationAge = max(0, (moment?.age ?? 0) - Double(10 - player.index) * 0.13)
        let celebrationJump = celebrates && celebrationAge < 0.7 ? sin(celebrationAge / 0.7 * .pi) * 5 : 0
        let jump = reduceMotion ? 0 : max(wallJump, celebrationJump)

        // Carry the keeper's landing into the next beat instead of snapping upright.
        let recentShot = isKeeper ? beats.last(where: {
            $0.action.isShot && $0.action.primaryPlayer?.side != player.side
                && $0.startProgress * duration <= time
        }) : nil
        var dive = 0.0
        var diveDirection = 1.0
        if !reduceMotion, let shot = recentShot, shot.action.shotOutcome != .blocked {
            let shotSeconds = (shot.endProgress - shot.startProgress) * duration
            let contactTime = (shot.startProgress + (shot.endProgress - shot.startProgress) * 0.30) * duration
            let impactTime = (shot.startProgress + (shot.endProgress - shot.startProgress) * MatchPresentation.shotImpactProgress) * duration
            dive = MatchMotionTimeline.smooth((time - contactTime) / max(0.12, shotSeconds * 0.42))
                * (1 - MatchMotionTimeline.smooth((time - impactTime - 0.18) / 0.85))
            diveDirection = shot.ballEnd.y < 0.5 ? -1 : 1
        }
        let skin = Color(hex: ["#E8B58C", "#B97850", "#815238", "#F2CCA7"][player.index % 4])
        let shorts = Color(hex: "#183447")
        var ctx = context
        let center = point(position)
        ctx.translateBy(x: center.x, y: center.y)
        ctx.scaleBy(x: scale, y: scale)
        // Ground shadows and ownership cues do not bob with the torso.
        ctx.fill(Path(ellipseIn: CGRect(x: -10 - dive * 4, y: -1, width: 21 + dive * 8, height: 6)),
                 with: .color(.black.opacity(0.20 - jump * 0.012)))
        if kit.requiresTeamOutline && !isKeeper {
            ctx.stroke(Path(ellipseIn: CGRect(x: -13, y: -3, width: 26, height: 10)),
                       with: .color(player.side == .home ? .white : Color(hex: "#FFC93C")),
                       style: StrokeStyle(lineWidth: 1.4, dash: player.side == .home ? [] : [2, 3]))
        }
        if active || frame.beat.action.receiver == player || frame.beat.action.defender == player {
            let color: Color = active ? .white : frame.beat.action.defender == player
                ? Color(hex: "#FF7B3D") : Color(hex: "#FFC93C")
            ctx.stroke(Path(ellipseIn: CGRect(x: -14, y: -4, width: 28, height: 11)),
                       with: .color(color.opacity(active ? 0.72 : 0.40)),
                       style: StrokeStyle(lineWidth: active ? 1.6 : 1.1, dash: active ? [] : [2, 4]))
        }
        ctx.translateBy(x: diveDirection * dive * 5, y: dive * 7 - jump)
        ctx.rotate(by: .radians(dive * diveDirection * 1.15))
        let bob = reduceMotion ? 0 : (1 - cos(pose.gaitPhase * 2)) * 0.45 * running * (1 - plant)
        let lean = running * 1.8 + max(0, swing) * plant * 1.6
        func bodyPoint(_ lateral: Double, _ height: Double, _ reach: Double = 0) -> CGPoint {
            CGPoint(x: lateral * width + forward.x * (reach + lean),
                    y: -height - bob + forward.y * reach * 0.65 + lateral * cos(heading) * 0.10)
        }
        func stroke(_ points: [CGPoint], _ color: Color, _ lineWidth: Double) {
            var path = Path()
            path.addLines(points)
            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        // A swing foot lifts and comes forward; a planted foot travels backwards
        // relative to the body. Knees and elbows bend instead of rigid pendulums.
        let legs = [-1.0, 1.0].map { side -> (Double, CGPoint, CGPoint, CGPoint) in
            let phase = pose.gaitPhase + (side < 0 ? 0 : .pi)
            let gaitReach = -cos(phase) * 9.5 * running
            let reach = side > 0 ? gaitReach * (1 - plant) + swing * 12 * plant
                : gaitReach * (1 - plant)
            let lift = max(0, sin(phase)) * 5 * running * (1 - plant)
                + (side > 0 ? max(0, swing) * plant * 2 : 0)
            let hip = bodyPoint(side * 3, 9)
            let foot = CGPoint(x: side * 3.5 * width + forward.x * reach,
                               y: forward.y * reach * 0.7 - lift)
            let knee = CGPoint(x: (hip.x + foot.x) * 0.5 + forward.x * 1.5,
                               y: (hip.y + foot.y) * 0.5 - 1.5 - lift * 0.3)
            return (side, hip, knee, foot)
        }.sorted { $0.3.y < $1.3.y }
        for (_, hip, knee, foot) in legs {
            stroke([hip, knee], skin, 3.4)
            stroke([hip, CGPoint(x: hip.x + (knee.x - hip.x) * 0.35, y: hip.y + (knee.y - hip.y) * 0.35)], shorts, 4.2)
            stroke([knee, foot], isKeeper ? Color(hex: "#FFD865") : kit.secondary, 2.7)
            stroke([foot, CGPoint(x: foot.x + forward.x * 3, y: foot.y + forward.y * 1.8)], Color(hex: "#18252C"), 3.5)
        }

        func arm(_ side: Double) {
            let phase = pose.gaitPhase + (side < 0 ? .pi : 0)
            let reach = -cos(phase) * 5 * running * (1 - plant) - side * plant * 3
            let raised = celebrates ? MatchMotionTimeline.smooth(celebrationAge / 0.2) : dive
            let shoulder = bodyPoint(side * 5.8, 19)
            let elbow = bodyPoint(side * (8 + raised * 3), 14 + raised * 9, reach * 0.4)
            let hand = bodyPoint(side * (7.5 + raised * 7), 11 + raised * 16, reach)
            stroke([shoulder, elbow, hand], skin, 2.9)
            stroke([shoulder, CGPoint(x: shoulder.x + (elbow.x - shoulder.x) * 0.60,
                                     y: shoulder.y + (elbow.y - shoulder.y) * 0.60)],
                   isKeeper ? Color(hex: "#FFC93C") : kit.sleeveColor, 4.4)
            if isKeeper {
                ctx.fill(Path(ellipseIn: CGRect(x: hand.x - 2.1, y: hand.y - 2.1, width: 4.2, height: 4.2)),
                         with: .color(.white))
            }
        }
        let farArm = cos(heading) > 0 ? -1.0 : 1.0
        arm(farArm)
        var torso = ctx
        let torsoOrigin = bodyPoint(0, 0)
        torso.translateBy(x: torsoOrigin.x, y: torsoOrigin.y)
        torso.rotate(by: .radians(reduceMotion ? 0 : pose.turn * running * 0.06))
        torso.scaleBy(x: width, y: 1)
        let shirtRect = CGRect(x: -6.4, y: -22, width: 12.8, height: 13.5)
        let shirt = Path { p in
            p.move(to: CGPoint(x: -3, y: -22.5))
            p.addQuadCurve(to: CGPoint(x: -6.8, y: -19), control: CGPoint(x: -7, y: -22))
            p.addLine(to: CGPoint(x: -5.6, y: -8.5))
            p.addQuadCurve(to: CGPoint(x: 5.6, y: -8.5), control: CGPoint(x: 0, y: -7))
            p.addLine(to: CGPoint(x: 6.8, y: -19))
            p.addQuadCurve(to: CGPoint(x: 3, y: -22.5), control: CGPoint(x: 7, y: -22))
            p.closeSubpath()
        }
        torso.fill(shirt, with: .color(isKeeper ? Color(hex: "#FFC93C") : kit.primary))
        var cloth = torso
        cloth.clip(to: shirt)
        if !isKeeper { kit.drawPattern(in: &cloth, rect: shirtRect) }
        cloth.fill(Path(CGRect(x: 3.5, y: -22, width: 4, height: 15)), with: .color(.black.opacity(0.13)))
        torso.stroke(shirt, with: .color(.black.opacity(0.24)), lineWidth: 0.6)
        torso.fill(Path(roundedRect: CGRect(x: -5.8, y: -10, width: 11.6, height: 3.8), cornerRadius: 1.1),
                   with: .color(shorts))
        torso.draw(Text("\(player.index + 1)").font(.system(size: sin(heading) < 0 ? 8.5 : 7.5, weight: .black, design: .rounded))
            .foregroundColor(isKeeper ? Color(hex: "#172D37") : kit.ink), at: CGPoint(x: 0, y: -15.2))
        arm(-farArm)

        // Head/nose/hair disclose the facing direction even at rest.
        let head = bodyPoint(cos(heading) * 1.1, 26.3, running * 0.4)
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - 3.7, y: head.y - 4.3, width: 7.4, height: 8.3)), with: .color(skin))
        let hair = Color(hex: player.index.isMultiple(of: 3) ? "#674831" : "#28303A")
        ctx.fill(Path(roundedRect: CGRect(x: head.x - 3.8, y: head.y - 4.6, width: 7.6,
                                         height: sin(heading) < -0.25 ? 6.8 : 3.6), cornerRadius: 2.8), with: .color(hair))
        if sin(heading) > -0.35 {
            ctx.fill(Path(ellipseIn: CGRect(x: head.x + cos(heading) * 3.5 - 1, y: head.y - 0.8, width: 2.4, height: 2.6)),
                     with: .color(skin))
        }
    }

    func drawBall(in context: inout GraphicsContext, frame: MatchPresentationFrame) {
        var ctx = context
        ctx.opacity = frame.ballOpacity
        if frame.trail.count > 1 {
            for index in 1..<frame.trail.count {
                var segment = Path()
                let from = point(frame.trail[index - 1])
                let to = point(frame.trail[index])
                segment.move(to: CGPoint(x: from.x, y: from.y - frame.trailHeights[index - 1] * 28 * scale - 2 * scale))
                segment.addLine(to: CGPoint(x: to.x, y: to.y - frame.trailHeights[index] * 28 * scale - 2 * scale))
                ctx.stroke(segment, with: .color((frame.beat.action.isShot ? Color(hex: "#FFC93C") : .white)
                    .opacity(Double(index) / Double(frame.trail.count) * 0.48)),
                    style: StrokeStyle(lineWidth: 2 + CGFloat(index) * 0.3, lineCap: .round))
            }
        }
        let ground = point(frame.ball)
        let height = frame.ballHeight * 28 * scale
        ctx.fill(Path(ellipseIn: CGRect(x: ground.x - 6 * scale, y: ground.y - 2 * scale,
                                        width: 12 * scale, height: 6 * scale)),
                 with: .color(.black.opacity(0.3 - frame.ballHeight * 0.12)))
        ctx.translateBy(x: ground.x, y: ground.y - height - 2 * scale)
        ctx.scaleBy(x: scale, y: scale)
        ctx.rotate(by: .radians(frame.ballRotation))
        let ball = Path(ellipseIn: CGRect(x: -5.5, y: -5.5, width: 11, height: 11))
        ctx.fill(ball, with: .color(.white))
        ctx.stroke(ball, with: .color(Color(hex: "#16343B")), lineWidth: 1.1)
        ctx.draw(Image(systemName: "soccerball").resizable(), in: CGRect(x: -5, y: -5, width: 10, height: 10))
    }

    func drawCelebration(in context: inout GraphicsContext, moment: MatchGoalMoment, color: Color) {
        guard moment.age < 1.9 else { return }
        let origin = CGPoint(x: moment.side == .home ? field.maxX : field.minX, y: field.midY)
        for index in 0..<32 {
            let angle = Double(index) * 2.399
            let speed = 35 + Double(index % 7) * 13
            let t = moment.age
            var ctx = context
            ctx.opacity = max(0, 1 - t / 1.9)
            ctx.translateBy(x: origin.x + cos(angle) * speed * t,
                            y: origin.y + sin(angle) * speed * t + 24 * t * t)
            ctx.rotate(by: .radians(angle + t * 5))
            let colors = [color, .white, Color(hex: "#FFC93C")]
            ctx.fill(Path(CGRect(x: -3, y: -2, width: 6, height: 4)), with: .color(colors[index % 3]))
        }
    }
}
