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
                    guard let frame else { return }
                    let painter = MatchPitchPainter(field: field, scale: min(1.15, max(0.72, size.width / 1000)))
                    painter.drawCrowd(in: &context, size: size, time: reduceMotion ? 0 : elapsed, moment: moment,
                                      home: styles.0.primary, away: styles.1.primary)
                    painter.drawGoalNets(in: &context, moment: reduceMotion ? nil : moment)
                    painter.drawSetPiece(in: &context, frame: frame)
                    for side in [MatchSide.home, .away] {
                        let positions = side == .home ? frame.homePositions : frame.awayPositions
                        for index in positions.indices {
                            painter.drawPlayer(in: &context, player: MatchPlayerRef(side: side, index: index),
                                               point: positions[index], frame: frame,
                                               kit: side == .home ? styles.0 : styles.1,
                                               time: elapsed, duration: duration, moment: moment,
                                               reduceMotion: reduceMotion)
                        }
                    }
                    painter.drawBall(in: &context, frame: frame, time: reduceMotion ? 0 : elapsed)
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
                    moment: MatchGoalMoment?, reduceMotion: Bool) {
        let start = player.side == .home ? frame.beat.homeStartPositions : frame.beat.awayStartPositions
        let end = player.side == .home ? frame.beat.homeEndPositions : frame.beat.awayEndPositions
        let distance = start[player.index].distance(to: end[player.index])
        let seconds = max(0.1, (frame.beat.endProgress - frame.beat.startProgress) * duration)
        let movementActive: Bool
        if case .setPieceSetup = frame.beat.action {
            movementActive = frame.localProgress < 0.72
        } else if frame.beat.setPiece != nil && frame.beat.action.isShot {
            movementActive = frame.beat.action.primaryPlayer == player ? frame.localProgress < 0.26
                : (frame.localProgress > 0.26 && frame.localProgress < MatchPresentation.shotImpactProgress)
        } else {
            movementActive = true
        }
        let running = reduceMotion || !movementActive ? 0 : min(1, distance / seconds * 30)
        let phase = time * 13 + Double(player.index) * 1.9 + (player.side == .home ? 0 : 1.2)
        let stride = sin(phase) * running
        let owner = frame.ballOwner
        let active = owner == player
        let isKeeper = player.index == 0
        let celebrating = moment?.side == player.side
        let inWall = frame.beat.setPiece == .freeKick && (1...3).contains(player.index)
            && frame.beat.action.primaryPlayer?.side != player.side
        let wallJump = frame.beat.action.isShot && inWall
            ? max(0, sin(min(1, max(0, (frame.localProgress - 0.24) / 0.43)) * .pi)) * 8 : 0
        let celebrationJump = celebrating ? max(0, sin((moment?.age ?? 0) * 12 + Double(player.index))) * 6 : 0
        let jump = reduceMotion ? 0 : max(wallJump, celebrationJump)
        let direction = player.side.attackDirection
        let contact = frame.beat.action.isShot ? 0.26 : frame.beat.action.isCross ? 0.16 : 0.22
        let kick = frame.beat.action.primaryPlayer == player && (frame.beat.action.isPass || frame.beat.action.isShot)
            ? max(0, 1 - abs(frame.localProgress - contact) / 0.13) : 0
        let diving = isKeeper && frame.beat.action.isShot && frame.beat.action.primaryPlayer?.side != player.side
        let dive = reduceMotion || !diving ? 0 : sin(min(1, max(0, (frame.localProgress - 0.34) / 0.52)) * .pi / 2)
        let rotation = reduceMotion ? 0 : stride * 0.04 + kick * direction * -0.18
            + dive * (frame.beat.ballEnd.y < 0.5 ? -0.95 : 0.95)
        var ctx = context
        let center = point(position)
        ctx.translateBy(x: center.x, y: center.y)
        ctx.scaleBy(x: scale, y: scale)
        ctx.fill(Path(ellipseIn: CGRect(x: -12, y: -1, width: 24, height: 8)), with: .color(.black.opacity(0.23)))
        if kit.requiresTeamOutline && !isKeeper {
            // Distinguish the sides without painting a fictional kit.
            ctx.stroke(Path(ellipseIn: CGRect(x: -14, y: -3, width: 28, height: 11)),
                       with: .color(player.side == .home ? .white : Color(hex: "#FFC93C")),
                       style: StrokeStyle(lineWidth: 1.8, dash: player.side == .home ? [] : [2, 3]))
        }
        if active || frame.beat.action.receiver == player || frame.beat.action.defender == player {
            let color: Color = active ? .white : frame.beat.action.defender == player ? Color(hex: "#FF7B3D") : Color(hex: "#FFC93C")
            ctx.stroke(Path(ellipseIn: CGRect(x: -16, y: -4, width: 32, height: 12)),
                       with: .color(color.opacity(active ? 0.95 : 0.65)),
                       style: StrokeStyle(lineWidth: active ? 2.3 : 1.5, dash: active ? [] : [3, 3]))
        }
        ctx.translateBy(x: 0, y: -jump - abs(stride) * 1.3)
        ctx.rotate(by: .radians(rotation))
        let skin = ["#E8B58C", "#B97850", "#815238", "#F2CCA7"][player.index % 4]
        let limbColor = Color(hex: skin)
        for left in [true, false] {
            let side = left ? -1.0 : 1.0
            let foot = side * stride * 3.8
            var leg = Path()
            leg.move(to: CGPoint(x: side * 3.3, y: -8))
            leg.addLine(to: CGPoint(x: side * 4.3 + (left ? 0 : kick * direction * 8), y: foot))
            ctx.stroke(leg, with: .color(kit.secondary), style: StrokeStyle(lineWidth: 3.7, lineCap: .round))
            ctx.fill(Path(roundedRect: CGRect(x: side * 4.3 - 2 + (left ? 0 : kick * direction * 8),
                                              y: foot - 1, width: 5.5, height: 3.5), cornerRadius: 1.5),
                     with: .color(Color(hex: "#152B35")))
            var arm = Path()
            arm.move(to: CGPoint(x: side * 7, y: -20))
            arm.addLine(to: CGPoint(x: side * (celebrating || diving ? 15 : 11),
                                   y: celebrating ? -30 : diving ? -24 : -13 + side * stride * 4))
            ctx.stroke(arm, with: .color(isKeeper ? .white : limbColor),
                       style: StrokeStyle(lineWidth: isKeeper ? 4.5 : 3.5, lineCap: .round))
            if !isKeeper {
                var sleeve = Path()
                sleeve.move(to: CGPoint(x: side * 7, y: -20))
                sleeve.addLine(to: CGPoint(x: side * (celebrating || diving ? 10 : 9),
                                          y: celebrating ? -24 : -18 + side * stride * 1.3))
                ctx.stroke(sleeve, with: .color(kit.sleeveColor),
                           style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
        let shirt = Path(roundedRect: CGRect(x: -7.5, y: -24, width: 15, height: 17), cornerRadius: 3)
        ctx.fill(shirt, with: .color(isKeeper ? Color(hex: "#FFC93C") : kit.primary))
        var shirtContext = ctx
        shirtContext.clip(to: shirt)
        if !isKeeper {
            kit.drawPattern(in: &shirtContext)
        }
        ctx.stroke(shirt, with: .color(.white.opacity(0.85)), lineWidth: 1)
        ctx.fill(Path(roundedRect: CGRect(x: -7, y: -9, width: 14, height: 4), cornerRadius: 1),
                 with: .color(Color(hex: "#183447")))
        ctx.draw(Text("\(player.index + 1)").font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundColor(isKeeper ? Color(hex: "#172D37") : kit.ink), at: CGPoint(x: 0, y: -16))
        ctx.fill(Path(ellipseIn: CGRect(x: -4.5, y: -33, width: 9, height: 9)), with: .color(limbColor))
        ctx.fill(Path(roundedRect: CGRect(x: -4.5, y: -33.5, width: 9, height: 4), cornerRadius: 2),
                 with: .color(Color(hex: player.index.isMultiple(of: 3) ? "#674831" : "#28303A")))
    }

    func drawBall(in context: inout GraphicsContext, frame: MatchPresentationFrame, time: Double) {
        var ctx = context
        ctx.opacity = frame.ballOpacity
        if frame.trail.count > 1 {
            for index in 1..<frame.trail.count {
                var segment = Path()
                segment.move(to: point(frame.trail[index - 1]))
                segment.addLine(to: point(frame.trail[index]))
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
        ctx.rotate(by: .radians(time * 5))
        let ball = Path(ellipseIn: CGRect(x: -7, y: -7, width: 14, height: 14))
        ctx.fill(ball, with: .color(.white))
        ctx.stroke(ball, with: .color(Color(hex: "#16343B")), lineWidth: 1.1)
        ctx.draw(Image(systemName: "soccerball").resizable(), in: CGRect(x: -6.5, y: -6.5, width: 13, height: 13))
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
