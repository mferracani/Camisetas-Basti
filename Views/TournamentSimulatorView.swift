import SwiftUI

struct TournamentSimulatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountryId = "arg"
    @State private var bracket = TournamentBracket.empty
    @State private var mode: TournamentPlayMode = .manual
    @State private var activeSimulation: MatchSimulationContext?

    private var leagues: [Country] {
        CAMI_DATA.countries.filter { $0.id != "wc26" }
    }

    private var selectedCountry: Country {
        CAMI_DATA.country(id: selectedCountryId) ?? leagues[0]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#263645"), Color(hex: "#1C2833")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    header(width: geo.size.width)

                    HStack(spacing: 14) {
                        LeaguePicker(leagues: leagues, selectedCountryId: $selectedCountryId) {
                            resetBracket()
                        }

                        TournamentModePicker(mode: $mode)

                        Button {
                            SoundManager.shared.playTap()
                            generateBracket()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "shuffle")
                                Text("ARMAR LLAVES")
                            }
                            .font(.custom("Nunito-Black", size: 18))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .frame(height: 56)
                            .background(Color(hex: "#FF7B3D"))
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: 1120)

                    TournamentBracketBoard(
                        bracket: $bracket,
                        title: selectedCountry.name,
                        size: geo.size,
                        mode: mode
                    ) { context in
                        activeSimulation = context
                    }
                    .frame(maxWidth: 1220, maxHeight: .infinity)
                }
                .padding(.horizontal, 34)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            if bracket.roundOf16.allSatisfy({ $0.home == nil && $0.away == nil }) {
                generateBracket()
            }
        }
        .fullScreenCover(item: $activeSimulation) { context in
            MatchSimulationModal(context: context) { result in
                bracket.applySimulation(context: context, result: result)
                activeSimulation = nil
            }
        }
    }

    private func header(width: CGFloat) -> some View {
        HStack {
            BackButton {
                dismiss()
            }
            Spacer()
            VStack(spacing: 2) {
                Text("SIMULAR TORNEO")
                    .font(.custom("Nunito-Black", size: min(width * 0.034, 42)))
                    .foregroundColor(.white)
                Text(mode.subtitle)
                    .font(.custom("Nunito-Black", size: 14))
                    .foregroundColor(.white.opacity(0.62))
            }
            Spacer()
            Circle().fill(Color.clear).frame(width: 64, height: 64)
        }
    }

    private func generateBracket() {
        let teams = CAMI_DATA.teams(for: selectedCountryId).shuffled()
        bracket = TournamentBracket(seedTeams: teams)
    }

    private func resetBracket() {
        bracket = .empty
        generateBracket()
    }
}

private struct LeaguePicker: View {
    let leagues: [Country]
    @Binding var selectedCountryId: String
    let onChange: () -> Void

    var body: some View {
        Menu {
            ForEach(leagues) { league in
                Button(league.name) {
                    selectedCountryId = league.id
                    onChange()
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(leagues.first(where: { $0.id == selectedCountryId })?.flag ?? "")
                    .font(.system(size: 24))
                Text(leagues.first(where: { $0.id == selectedCountryId })?.name ?? "")
                    .font(.custom("Nunito-Black", size: 18))
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .black))
            }
            .foregroundColor(Color(hex: "#263645"))
            .padding(.horizontal, 22)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(18)
        }
    }
}

private struct TournamentModePicker: View {
    @Binding var mode: TournamentPlayMode

    var body: some View {
        HStack(spacing: 4) {
            modeButton(.manual)
            modeButton(.simulated)
        }
        .padding(4)
        .frame(height: 56)
        .background(Color.white.opacity(0.12))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func modeButton(_ value: TournamentPlayMode) -> some View {
        Button {
            SoundManager.shared.playTap()
            mode = value
        } label: {
            HStack(spacing: 8) {
                Image(systemName: value.icon)
                Text(value.title)
            }
            .font(.custom("Nunito-Black", size: 15))
            .foregroundColor(mode == value ? Color(hex: "#263645") : .white.opacity(0.72))
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(mode == value ? Color.white : Color.clear)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

private struct TournamentBracketBoard: View {
    @Binding var bracket: TournamentBracket
    let title: String
    let size: CGSize
    let mode: TournamentPlayMode
    let onSimulate: (MatchSimulationContext) -> Void

    private var crestSize: CGFloat {
        min(max(size.width * 0.03, 32), 48)
    }

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                bracketColumn(title: "OCTAVOS", matches: $bracket.roundOf16, round: .roundOf16)
                connectorColumn(lines: 8)
                bracketColumn(title: "CUARTOS", matches: $bracket.quarterFinals, round: .quarterFinals)
                connectorColumn(lines: 4)
                bracketColumn(title: "SEMIS", matches: $bracket.semiFinals, round: .semiFinals)
                connectorColumn(lines: 2)

                VStack(spacing: 18) {
                    Text(title)
                        .font(.custom("Nunito-Black", size: 22))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(bracket.champion == nil ? Color(hex: "#D9DEE6") : Color(hex: "#FFC93C"))
                        .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 8)

                    finalMatch
                }
                .frame(width: min(max(size.width * 0.13, 142), 184))

                connectorColumn(lines: 2)
                bracketColumn(title: "SEMIS", matches: $bracket.semiFinalsRight, round: .semiFinalsRight)
                connectorColumn(lines: 4)
                bracketColumn(title: "CUARTOS", matches: $bracket.quarterFinalsRight, round: .quarterFinalsRight)
                connectorColumn(lines: 8)
                bracketColumn(title: "OCTAVOS", matches: $bracket.roundOf16Right, round: .roundOf16Right)
            }
            .padding(18)
            .background(Color.white.opacity(0.06))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            if let champion = bracket.champion {
                ChampionGloryOverlay(champion: champion)
                    .transition(.scale(scale: 0.86).combined(with: .opacity))
                    .zIndex(5)
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: bracket.champion)
    }

    private var finalMatch: some View {
        VStack(spacing: 12) {
            if mode == .simulated {
                SimulatedMatchCard(
                    match: bracket.final,
                    crestSize: crestSize + 8,
                    isRecommended: bracket.isRecommended(round: .final, matchIndex: 0),
                    title: "FINAL"
                ) {
                    startSimulation(round: .final, matchIndex: 0, match: bracket.final)
                }
            } else {
                BracketSlot(team: bracket.final.home, crestSize: crestSize + 6) {
                    advance(.final, slot: .home)
                }
                Text("FINAL")
                    .font(.custom("Nunito-Black", size: 13))
                    .foregroundColor(.white.opacity(0.62))
                BracketSlot(team: bracket.final.away, crestSize: crestSize + 6) {
                    advance(.final, slot: .away)
                }
            }
            if let champion = bracket.champion {
                VStack(spacing: 8) {
                    Text("CAMPEÓN")
                        .font(.custom("Nunito-Black", size: 13))
                        .foregroundColor(Color(hex: "#FFC93C"))
                    CrestView(crest: champion.crest, size: crestSize + 18)
                }
                .padding(.top, 8)
            }
        }
    }

    private func bracketColumn(title: String, matches: Binding<[TournamentMatch]>, round: TournamentRound) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.custom("Nunito-Black", size: 13))
                .foregroundColor(.white.opacity(0.7))
            ForEach(matches.indices, id: \.self) { index in
                MatchView(
                    match: matches[index],
                    crestSize: crestSize,
                    mode: mode,
                    isRecommended: bracket.isRecommended(round: round, matchIndex: index)
                ) { slot in
                    advance(round, matchIndex: index, slot: slot)
                } onSimulate: {
                    startSimulation(round: round, matchIndex: index, match: matches[index].wrappedValue)
                }
            }
        }
        .frame(width: min(max(size.width * 0.08, 84), 118))
    }

    private func connectorColumn(lines: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<lines, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 18, height: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 20)
    }

    private func advance(_ round: TournamentRound, matchIndex: Int = 0, slot: BracketSlotSide) {
        SoundManager.shared.playTap()
        bracket.advance(round: round, matchIndex: matchIndex, slot: slot)
    }

    private func startSimulation(round: TournamentRound, matchIndex: Int, match: TournamentMatch) {
        guard match.isPlayable, match.result == nil else { return }
        SoundManager.shared.playTap()
        onSimulate(MatchSimulationContext(round: round, matchIndex: matchIndex, match: match))
    }
}

private struct MatchView: View {
    @Binding var match: TournamentMatch
    let crestSize: CGFloat
    let mode: TournamentPlayMode
    let isRecommended: Bool
    let onPick: (BracketSlotSide) -> Void
    let onSimulate: () -> Void

    var body: some View {
        Group {
            if mode == .simulated {
                SimulatedMatchCard(
                    match: match,
                    crestSize: crestSize,
                    isRecommended: isRecommended,
                    title: nil,
                    action: onSimulate
                )
            } else {
                VStack(spacing: 4) {
                    BracketSlot(team: match.home, crestSize: crestSize) {
                        onPick(.home)
                    }
                    BracketSlot(team: match.away, crestSize: crestSize) {
                        onPick(.away)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SimulatedMatchCard: View {
    let match: TournamentMatch
    let crestSize: CGFloat
    let isRecommended: Bool
    let title: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                if let title {
                    Text(title)
                        .font(.custom("Nunito-Black", size: 11))
                        .foregroundColor(.white.opacity(0.62))
                }
                HStack(spacing: 6) {
                    teamRow(team: match.home, score: match.result?.homeGoals)
                    Text(match.result == nil ? "VS" : "-")
                        .font(.custom("Nunito-Black", size: 10))
                        .foregroundColor(.white.opacity(0.52))
                    teamRow(team: match.away, score: match.result?.awayGoals)
                }
                Text(statusText)
                    .font(.custom("Nunito-Black", size: 9))
                    .foregroundColor(statusColor)
                    .lineLimit(1)
            }
            .padding(7)
            .frame(height: title == nil ? crestSize * 2 + 20 : crestSize * 2 + 40)
            .background(backgroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: isRecommended ? 2 : 1)
            )
            .shadow(color: isRecommended ? Color(hex: "#FFC93C").opacity(0.26) : Color.clear, radius: 10, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .disabled(!match.isPlayable || match.result != nil)
    }

    private func teamRow(team: Team?, score: Int?) -> some View {
        HStack(spacing: 5) {
            if let team {
                CrestView(crest: team.crest, size: crestSize * 0.72)
                Text(team.short.uppercased())
                    .font(.custom("Nunito-Black", size: 9))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let score {
                    Text("\(score)")
                        .font(.custom("Nunito-Black", size: 13))
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: crestSize * 0.72, height: crestSize * 0.72)
                Text("LIBRE")
                    .font(.custom("Nunito-Black", size: 8))
                    .foregroundColor(.white.opacity(0.35))
            }
            Spacer(minLength: 0)
        }
    }

    private var statusText: String {
        if match.result != nil { return "FINALIZADO" }
        if !match.isPlayable { return "FALTA RIVAL" }
        return isRecommended ? "JUGAR AHORA" : "PENDIENTE"
    }

    private var statusColor: Color {
        if match.result != nil { return Color(hex: "#7DDB8B") }
        if !match.isPlayable { return .white.opacity(0.34) }
        return isRecommended ? Color(hex: "#FFC93C") : .white.opacity(0.6)
    }

    private var backgroundColor: Color {
        if match.result != nil { return Color(hex: "#2B5840").opacity(0.55) }
        if !match.isPlayable { return Color.white.opacity(0.04) }
        return Color.white.opacity(isRecommended ? 0.16 : 0.1)
    }

    private var borderColor: Color {
        if isRecommended && match.result == nil && match.isPlayable { return Color(hex: "#FFC93C") }
        return Color.white.opacity(match.isPlayable ? 0.16 : 0.08)
    }
}

private struct BracketSlot: View {
    let team: Team?
    let crestSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let team {
                    CrestView(crest: team.crest, size: crestSize)
                    Text(team.short.uppercased())
                        .font(.custom("Nunito-Black", size: 11))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.28), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .frame(width: crestSize, height: crestSize)
                    Text("LIBRE")
                        .font(.custom("Nunito-Black", size: 10))
                        .foregroundColor(.white.opacity(0.42))
                }
                Spacer(minLength: 0)
            }
            .padding(6)
            .frame(height: crestSize + 12)
            .background(Color.white.opacity(team == nil ? 0.04 : 0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(team == nil)
    }
}

private struct ChampionGloryOverlay: View {
    let champion: Team
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            ForEach(0..<18, id: \.self) { index in
                GloryRay(index: index, animate: animate)
            }

            ForEach(0..<44, id: \.self) { index in
                GloryParticle(index: index, animate: animate)
            }

            VStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 104, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFF3A3"), Color(hex: "#FFC93C"), Color(hex: "#FF7B3D")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "#FFC93C").opacity(0.8), radius: animate ? 28 : 8, x: 0, y: 0)
                    .scaleEffect(animate ? 1.08 : 0.86)

                CrestView(crest: champion.crest, size: 112)
                    .padding(18)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color(hex: "#FFC93C").opacity(0.85), radius: animate ? 30 : 10, x: 0, y: 0)
                    )
                    .scaleEffect(animate ? 1 : 0.72)

                Text("CAMPEÓN")
                    .font(.custom("Nunito-Black", size: 54))
                    .foregroundColor(Color(hex: "#FFC93C"))
                    .shadow(color: Color.black.opacity(0.42), radius: 8, x: 0, y: 6)

                Text(champion.name.uppercased())
                    .font(.custom("Nunito-Black", size: 30))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
            }
            .padding(38)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(hex: "#1C2833").opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color(hex: "#FFC93C").opacity(0.75), lineWidth: 2)
                    )
            )
            .scaleEffect(animate ? 1 : 0.78)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.66)) {
                animate = true
            }
        }
    }
}

private struct GloryRay: View {
    let index: Int
    let animate: Bool

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#FFC93C").opacity(0.0), Color(hex: "#FFC93C").opacity(0.52), Color(hex: "#FF7B3D").opacity(0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: animate ? 460 : 120, height: 10)
            .rotationEffect(.degrees(Double(index) * 20))
            .opacity(animate ? 1 : 0)
            .animation(.easeOut(duration: 0.75).delay(Double(index) * 0.018), value: animate)
    }
}

private struct GloryParticle: View {
    let index: Int
    let animate: Bool

    private var angle: Double { Double(index) * 137.5 }
    private var distance: CGFloat { CGFloat(140 + (index % 9) * 28) }
    private var color: Color {
        [Color(hex: "#FFC93C"), Color(hex: "#FF7B3D"), Color.white, Color(hex: "#7DDB8B")][index % 4]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: CGFloat(8 + (index % 4) * 3), height: CGFloat(14 + (index % 3) * 5))
            .rotationEffect(.degrees(animate ? angle + 260 : angle))
            .offset(
                x: animate ? cos(angle * .pi / 180) * distance : 0,
                y: animate ? sin(angle * .pi / 180) * distance : 0
            )
            .opacity(animate ? 0 : 1)
            .animation(.easeOut(duration: 1.35).delay(Double(index % 10) * 0.035), value: animate)
    }
}

private struct MatchSimulationModal: View {
    let context: MatchSimulationContext
    let onFinish: (MatchSimulationResult) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var elapsed: TimeInterval = 0
    @State private var isFinished = false
    @State private var result: MatchSimulationResult
    @State private var duration: TimeInterval

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    init(context: MatchSimulationContext, onFinish: @escaping (MatchSimulationResult) -> Void) {
        self.context = context
        self.onFinish = onFinish
        let generated = MatchSimulationFactory.makeResult(for: context.match)
        _result = State(initialValue: generated)
        _duration = State(initialValue: 36)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#132413"), Color(hex: "#1E3B20")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    scoreboard
                        .frame(maxWidth: 980)

                    SoccerPitchView(
                        context: context,
                        result: result,
                        progress: progress,
                        homeScore: liveHomeGoals,
                        awayScore: liveAwayGoals,
                        reduceMotion: reduceMotion
                    )
                    .frame(maxWidth: 1080, maxHeight: geo.size.height * 0.68)
                    .aspectRatio(1.72, contentMode: .fit)
                    .padding(.horizontal, geo.size.width < 1100 ? 20 : 42)

                    bottomEvent
                        .frame(maxWidth: 980)
                }
                .padding(.top, 24)
                .padding(.bottom, 22)

                if isFinished {
                    finishedPanel
                        .transition(.scale(scale: 0.86).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            duration = reduceMotion ? 18 : Double.random(in: 30...45)
        }
        .onReceive(timer) { _ in
            guard !isFinished else { return }
            elapsed = min(duration, elapsed + 0.05)
            if elapsed >= duration {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                    isFinished = true
                }
            }
        }
    }

    private var progress: Double {
        guard duration > 0 else { return 1 }
        return min(1, elapsed / duration)
    }

    private var matchMinute: Int {
        min(90, Int(progress * 90))
    }

    private var liveHomeGoals: Int {
        result.goalEvents.filter { $0.side == .home && $0.minute <= matchMinute }.count
    }

    private var liveAwayGoals: Int {
        result.goalEvents.filter { $0.side == .away && $0.minute <= matchMinute }.count
    }

    private var currentEvent: String {
        if isFinished {
            return result.decidedByPenalties ? "SE DEFINE POR PENALES" : "FINAL DEL PARTIDO"
        }
        if let chance = currentChance {
            let local = normalizedChanceProgress(for: chance)
            let teamName = team(for: chance.side).short.uppercased()
            if chance.outcome == .goal && local > 0.86 {
                return "GOOOL DE \(teamName)"
            }
            if chance.outcome == .save && local > 0.76 {
                return "ATAJADÓN DEL ARQUERO"
            }
            if chance.outcome == .wide && local > 0.78 {
                return "PASÓ CERCA \(teamName)"
            }
            if local > 0.54 {
                return "REMATE DE \(teamName)"
            }
            return "ATACA \(teamName)"
        }
        let events = ["ARRANCA EL PARTIDO", "PASE DE \(context.match.home?.short.uppercased() ?? "LOCAL")", "PRESIONA \(context.match.away?.short.uppercased() ?? "VISITANTE")", "CAMBIO DE FRENTE", "RECUPERA \(context.match.away?.short.uppercased() ?? "VISITANTE")", "TOCA Y VA \(context.match.home?.short.uppercased() ?? "LOCAL")"]
        return events[min(events.count - 1, Int(progress * Double(events.count)))]
    }

    private var currentChance: MatchChanceEvent? {
        result.chanceEvents.first { chance in
            let chanceProgress = Double(chance.minute) / 90
            return progress >= chanceProgress - 0.075 && progress <= chanceProgress + 0.035
        }
    }

    private func normalizedChanceProgress(for chance: MatchChanceEvent) -> Double {
        let chanceProgress = Double(chance.minute) / 90
        return min(1, max(0, (progress - (chanceProgress - 0.075)) / 0.095))
    }

    private var scoreboard: some View {
        HStack(spacing: 16) {
            scoreTeam(team: context.match.home, score: liveHomeGoals, reverse: false)
            VStack(spacing: 3) {
                Text("\(matchMinute)'")
                    .font(.custom("Nunito-Black", size: 18))
                    .foregroundColor(Color(hex: "#FFC93C"))
                Text("PARTIDO")
                    .font(.custom("Nunito-Black", size: 10))
                    .foregroundColor(.white.opacity(0.52))
            }
            scoreTeam(team: context.match.away, score: liveAwayGoals, reverse: true)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.32))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func scoreTeam(team: Team?, score: Int, reverse: Bool) -> some View {
        HStack(spacing: 12) {
            if reverse { Spacer(minLength: 0) }
            if let team {
                CrestView(crest: team.crest, size: 46)
                Text(team.short.uppercased())
                    .font(.custom("Nunito-Black", size: 18))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            Text("\(score)")
                .font(.custom("Nunito-Black", size: 38))
                .foregroundColor(.white)
                .monospacedDigit()
            if !reverse { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomEvent: some View {
        Text(currentEvent)
            .font(.custom("Nunito-Black", size: 24))
            .foregroundColor((currentEvent.contains("GOOOL") || currentEvent.contains("ATAJAD")) ? Color(hex: "#FFC93C") : .white)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, 28)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.26))
            .cornerRadius(20)
    }

    private var finishedPanel: some View {
        VStack(spacing: 16) {
            Text(result.decidedByPenalties ? "GANÓ POR PENALES" : "FINAL DEL PARTIDO")
                .font(.custom("Nunito-Black", size: 24))
                .foregroundColor(Color(hex: "#FFC93C"))
            CrestView(crest: result.winner.crest, size: 96)
                .padding(14)
                .background(Circle().fill(Color.white))
                .shadow(color: Color(hex: "#FFC93C").opacity(0.75), radius: 22, x: 0, y: 0)
            Text(result.winner.name.uppercased())
                .font(.custom("Nunito-Black", size: 34))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(result.homeGoals) - \(result.awayGoals)")
                .font(.custom("Nunito-Black", size: 48))
                .foregroundColor(.white)
                .monospacedDigit()
            Button {
                SoundManager.shared.playTap()
                onFinish(result)
            } label: {
                Text("CERRAR")
                    .font(.custom("Nunito-Black", size: 20))
                    .foregroundColor(Color(hex: "#263645"))
                    .padding(.horizontal, 42)
                    .frame(height: 58)
                    .background(Color(hex: "#FFC93C"))
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(36)
        .frame(maxWidth: 540)
        .background(Color(hex: "#172330").opacity(0.94))
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color(hex: "#FFC93C").opacity(0.72), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 30, x: 0, y: 18)
    }

    private func team(for side: BracketSlotSide) -> Team {
        switch side {
        case .home: return context.match.home ?? result.winner
        case .away: return context.match.away ?? result.winner
        }
    }
}

private struct SoccerPitchView: View {
    let context: MatchSimulationContext
    let result: MatchSimulationResult
    let progress: Double
    let homeScore: Int
    let awayScore: Int
    let reduceMotion: Bool

    private let homeBases: [CGPoint] = [
        CGPoint(x: 0.08, y: 0.50),
        CGPoint(x: 0.24, y: 0.28),
        CGPoint(x: 0.25, y: 0.72),
        CGPoint(x: 0.43, y: 0.34),
        CGPoint(x: 0.43, y: 0.66),
        CGPoint(x: 0.61, y: 0.42),
        CGPoint(x: 0.64, y: 0.58)
    ]
    private let awayBases: [CGPoint] = [
        CGPoint(x: 0.92, y: 0.50),
        CGPoint(x: 0.76, y: 0.28),
        CGPoint(x: 0.75, y: 0.72),
        CGPoint(x: 0.57, y: 0.34),
        CGPoint(x: 0.57, y: 0.66),
        CGPoint(x: 0.39, y: 0.42),
        CGPoint(x: 0.36, y: 0.58)
    ]

    var body: some View {
        GeometryReader { geo in
            let play = visualPlay
            let homeStyle = jerseyStyle(for: context.match.home, fallback: ("#75AADB", "#FFFFFF"), opponent: context.match.away)
            let awayStyle = jerseyStyle(for: context.match.away, fallback: ("#E2272F", "#111111"), opponent: context.match.home)

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#2C8A42"), Color(hex: "#1F7236")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                SoccerPitchLines()
                    .stroke(Color.white.opacity(0.82), lineWidth: 3)
                    .padding(24)

                ForEach(homeBases.indices, id: \.self) { index in
                    PlayerDot(
                        style: homeStyle,
                        label: index == 0 ? "1" : context.match.home?.short.prefix(1).uppercased() ?? "L",
                        isActive: play.side == .home && (play.playerIndex == index || play.receiverIndex == index),
                        isGoalkeeper: index == 0
                    )
                    .scaleEffect(play.side == .home && play.playerIndex == index ? 1.16 : 1)
                    .rotationEffect(.degrees(playerLean(index: index, home: true, play: play)))
                    .position(playerPosition(index: index, home: true, play: play, size: geo.size))
                    .animation(reduceMotion ? nil : .interactiveSpring(response: 0.34, dampingFraction: 0.76), value: progress)
                }

                ForEach(awayBases.indices, id: \.self) { index in
                    PlayerDot(
                        style: awayStyle,
                        label: index == 0 ? "1" : context.match.away?.short.prefix(1).uppercased() ?? "V",
                        isActive: play.side == .away && (play.playerIndex == index || play.receiverIndex == index),
                        isGoalkeeper: index == 0
                    )
                    .scaleEffect(play.side == .away && play.playerIndex == index ? 1.16 : 1)
                    .rotationEffect(.degrees(playerLean(index: index, home: false, play: play)))
                    .position(playerPosition(index: index, home: false, play: play, size: geo.size))
                    .animation(reduceMotion ? nil : .interactiveSpring(response: 0.34, dampingFraction: 0.76), value: progress)
                }

                BallTrail(from: play.from, to: play.ball, isShot: play.isShot)
                    .stroke(
                        play.isShot ? Color(hex: "#FFC93C").opacity(0.82) : Color.white.opacity(0.34),
                        style: StrokeStyle(lineWidth: play.isShot ? 5 : 3, lineCap: .round, dash: play.isShot ? [] : [7, 7])
                    )
                    .frame(width: geo.size.width, height: geo.size.height)

                FootballView(isShot: play.isShot, spin: progress)
                    .position(x: play.ball.x * geo.size.width, y: play.ball.y * geo.size.height)
                    .animation(reduceMotion ? nil : .easeInOut(duration: play.isShot ? 0.11 : 0.32), value: progress)

                if play.isShot {
                    ShotBurst(side: play.side, outcome: play.outcome)
                        .position(x: play.from.x * geo.size.width, y: play.from.y * geo.size.height)
                        .transition(.scale.combined(with: .opacity))
                }

                if play.outcome == .save && play.localProgress > 0.76 {
                    SaveFlash()
                        .position(x: play.ball.x * geo.size.width, y: play.ball.y * geo.size.height)
                        .transition(.scale.combined(with: .opacity))
                }

                if recentGoal {
                    Text("GOOOL")
                        .font(.custom("Nunito-Black", size: 54))
                        .foregroundColor(Color(hex: "#FFC93C"))
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 5)
                        .scaleEffect(1 + CGFloat(sin(progress * 90)) * 0.06)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
            )
        }
    }

    private var recentGoal: Bool {
        guard let chance = currentChanceMoment, chance.outcome == .goal else { return false }
        return normalizedChanceProgress(for: chance) > 0.86
    }

    private var visualPlay: MatchVisualPlay {
        if reduceMotion {
            let side: BracketSlotSide = progress < 0.5 ? .home : .away
            let base = point(for: side, index: progress < 0.5 ? 3 : 4)
            return MatchVisualPlay(side: side, playerIndex: 3, receiverIndex: 4, ball: base, from: base, isShot: false, localProgress: 0, outcome: nil)
        }

        if let chance = currentChanceMoment {
            return chancePlay(chance)
        }

        let segmentCount = 34
        let raw = progress * Double(segmentCount)
        let segment = Int(raw) % segmentCount
        let local = CGFloat(raw - floor(raw))
        let side: BracketSlotSide = segment % 4 < 2 ? .home : .away
        let routes = side == .home
            ? [[1, 3, 5, 6], [2, 4, 6, 5], [3, 4, 5, 3]]
            : [[1, 3, 5, 6], [2, 4, 6, 5], [3, 4, 5, 3]]
        let route = routes[segment % routes.count]
        let fromIndex = route[segment % route.count]
        let toIndex = route[(segment + 1) % route.count]
        let from = point(for: side, index: fromIndex)
        let to = point(for: side, index: toIndex)
        let eased = local * local * (3 - 2 * local)
        return MatchVisualPlay(
            side: side,
            playerIndex: local < 0.55 ? fromIndex : toIndex,
            receiverIndex: toIndex,
            ball: interpolate(from: from, to: to, progress: eased),
            from: from,
            isShot: false,
            localProgress: local,
            outcome: nil
        )
    }

    private var currentChanceMoment: MatchChanceEvent? {
        result.chanceEvents.first { chance in
            let chanceProgress = Double(chance.minute) / 90
            return progress >= chanceProgress - 0.075 && progress <= chanceProgress + 0.035
        }
    }

    private func normalizedChanceProgress(for chance: MatchChanceEvent) -> CGFloat {
        let chanceProgress = Double(chance.minute) / 90
        return min(1, max(0, CGFloat((progress - (chanceProgress - 0.075)) / 0.095)))
    }

    private func chancePlay(_ chance: MatchChanceEvent) -> MatchVisualPlay {
        let local = normalizedChanceProgress(for: chance)
        let carrier = local < 0.28 ? 3 : (local < 0.52 ? 5 : 6)
        let receiver = local < 0.28 ? 5 : 6
        let p0 = point(for: chance.side, index: 3)
        let p1 = point(for: chance.side, index: 5)
        let p2 = point(for: chance.side, index: 6)
        let shotStart = advanceTowardGoal(from: p2, side: chance.side, amount: 0.08)
        let target = shotTarget(for: chance)
        let ball: CGPoint
        let from: CGPoint
        let isShot = local > 0.58

        if local < 0.28 {
            let t = local / 0.28
            ball = interpolate(from: p0, to: p1, progress: smooth(t))
            from = p0
        } else if local < 0.52 {
            let t = (local - 0.28) / 0.24
            ball = interpolate(from: p1, to: shotStart, progress: smooth(t))
            from = p1
        } else if local < 0.72 {
            let t = (local - 0.52) / 0.20
            ball = interpolate(from: shotStart, to: target, progress: smooth(t))
            from = shotStart
        } else if chance.outcome == .save {
            let t = (local - 0.72) / 0.28
            ball = interpolate(from: target, to: saveDeflectionPoint(for: chance), progress: smooth(t))
            from = shotStart
        } else {
            let t = (local - 0.72) / 0.28
            ball = interpolate(from: target, to: target, progress: smooth(t))
            from = shotStart
        }

        return MatchVisualPlay(
            side: chance.side,
            playerIndex: carrier,
            receiverIndex: receiver,
            ball: ball,
            from: from,
            isShot: isShot,
            localProgress: local,
            outcome: chance.outcome
        )
    }

    private func playerPosition(index: Int, home: Bool, play: MatchVisualPlay, size: CGSize) -> CGPoint {
        let base = home ? homeBases[index] : awayBases[index]
        let isHomeAttack = play.side == .home
        let sideMatches = (home && isHomeAttack) || (!home && !isHomeAttack)
        let isGoalkeeper = index == 0
        let chaseStrength: CGFloat
        if sideMatches {
            chaseStrength = index == play.playerIndex ? 0.34 : (index == play.receiverIndex ? 0.24 : 0.10)
        } else {
            chaseStrength = isGoalkeeper && play.isShot ? 0.52 : 0.16
        }
        var pressure = interpolate(from: base, to: play.ball, progress: chaseStrength)
        if sideMatches {
            pressure.x += play.side == .home ? 0.035 : -0.035
        } else {
            pressure.x += play.side == .home ? 0.018 : -0.018
        }
        if isGoalkeeper && !sideMatches && play.isShot {
            pressure = goalkeeperDivePosition(home: home, play: play)
        }
        let tempo = progress * .pi * 36
        let motionX = reduceMotion ? 0 : CGFloat(sin(tempo + Double(index) * 0.72)) * (sideMatches ? 10 : 6)
        let motionY = reduceMotion ? 0 : CGFloat(cos(tempo * 0.82 + Double(index) * 1.1)) * (sideMatches ? 8 : 5)
        return CGPoint(
            x: pressure.x * size.width + motionX,
            y: pressure.y * size.height + motionY
        )
    }

    private func playerLean(index: Int, home: Bool, play: MatchVisualPlay) -> Double {
        guard !reduceMotion else { return 0 }
        let sideMatches = (home && play.side == .home) || (!home && play.side == .away)
        let direction = home ? 1.0 : -1.0
        if index == 0 && !sideMatches && play.isShot {
            return direction * (play.outcome == .save ? -24 : -12)
        }
        return direction * (sideMatches ? 7 : -4) * sin(progress * 22 + Double(index))
    }

    private func goalkeeperDivePosition(home: Bool, play: MatchVisualPlay) -> CGPoint {
        let base = home ? homeBases[0] : awayBases[0]
        let goalLineX: CGFloat = home ? 0.08 : 0.92
        let targetY = min(0.68, max(0.32, play.ball.y))
        let dive = play.outcome == .save ? min(1, max(0, (play.localProgress - 0.58) / 0.24)) : min(0.55, max(0, (play.localProgress - 0.62) / 0.28))
        return interpolate(
            from: base,
            to: CGPoint(x: goalLineX, y: targetY),
            progress: smooth(dive)
        )
    }

    private func point(for side: BracketSlotSide, index: Int) -> CGPoint {
        switch side {
        case .home: return homeBases[index]
        case .away: return awayBases[index]
        }
    }

    private func interpolate(from: CGPoint, to: CGPoint, progress: CGFloat) -> CGPoint {
        CGPoint(
            x: from.x + (to.x - from.x) * progress,
            y: from.y + (to.y - from.y) * progress
        )
    }

    private func advanceTowardGoal(from point: CGPoint, side: BracketSlotSide, amount: CGFloat) -> CGPoint {
        CGPoint(x: point.x + (side == .home ? amount : -amount), y: point.y)
    }

    private func shotTarget(for chance: MatchChanceEvent) -> CGPoint {
        let direction: CGFloat = chance.side == .home ? 1 : -1
        let goalX: CGFloat = chance.side == .home ? 1.012 : -0.012
        let keeperX: CGFloat = chance.side == .home ? 0.94 : 0.06
        let lane = CGFloat((chance.minute % 5) - 2) * 0.045
        switch chance.outcome {
        case .goal:
            return CGPoint(x: goalX, y: 0.50 + lane)
        case .save:
            return CGPoint(x: keeperX, y: 0.50 + lane)
        case .wide:
            return CGPoint(x: goalX + direction * 0.01, y: chance.minute % 2 == 0 ? 0.29 : 0.71)
        }
    }

    private func saveDeflectionPoint(for chance: MatchChanceEvent) -> CGPoint {
        let direction: CGFloat = chance.side == .home ? -1 : 1
        let y: CGFloat = chance.minute % 2 == 0 ? 0.22 : 0.78
        return CGPoint(x: shotTarget(for: chance).x + direction * 0.13, y: y)
    }

    private func smooth(_ value: CGFloat) -> CGFloat {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }

    private func jerseyStyle(for team: Team?, fallback: (String, String), opponent: Team?) -> JerseyStyle {
        let colors = team?.home.colors ?? [fallback.0, fallback.1]
        let opponentColors = opponent?.home.colors ?? []
        let primary = colors.first ?? fallback.0
        let secondary = colors.dropFirst().first ?? fallback.1
        let resolvedPrimary = colorsAreTooClose(primary, opponentColors.first) && colors.count > 1 ? secondary : primary
        let resolvedSecondary = resolvedPrimary == secondary ? primary : secondary
        return JerseyStyle(primaryHex: resolvedPrimary, secondaryHex: resolvedSecondary)
    }

    private func colorsAreTooClose(_ first: String, _ second: String?) -> Bool {
        guard let second else { return false }
        let a = RGB(hex: first)
        let b = RGB(hex: second)
        let distance = abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b)
        return distance < 0.42
    }
}

private struct PlayerDot: View {
    let style: JerseyStyle
    let label: String
    let isActive: Bool
    let isGoalkeeper: Bool

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .stroke(Color.white.opacity(0.42), lineWidth: 5)
                    .frame(width: isGoalkeeper ? 42 : 48, height: isGoalkeeper ? 42 : 48)
                    .blur(radius: 0.4)
            }
            Circle()
                .fill(style.primary)
            Rectangle()
                .fill(style.secondary)
                .frame(width: isGoalkeeper ? 18 : 12)
                .rotationEffect(.degrees(isGoalkeeper ? 0 : -18))
                .offset(x: 1)
                .clipShape(Circle())
            Circle()
                .stroke(style.border, lineWidth: 3)
            Text(label)
                .font(.custom("Nunito-Black", size: 12))
                .foregroundColor(style.text)
                .shadow(color: style.textShadow, radius: 1, x: 0, y: 1)
        }
        .frame(width: isGoalkeeper ? 38 : 34, height: isGoalkeeper ? 38 : 34)
        .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 3)
    }
}

private struct MatchVisualPlay {
    let side: BracketSlotSide
    let playerIndex: Int
    let receiverIndex: Int
    let ball: CGPoint
    let from: CGPoint
    let isShot: Bool
    let localProgress: CGFloat
    let outcome: MatchChanceOutcome?
}

private struct BallTrail: Shape {
    let from: CGPoint
    let to: CGPoint
    let isShot: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: from.x * rect.width, y: from.y * rect.height)
        let end = CGPoint(x: to.x * rect.width, y: to.y * rect.height)
        let control = CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - (isShot ? 34 : 16))
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        return path
    }
}

private struct FootballView: View {
    let isShot: Bool
    let spin: Double

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: isShot ? 22 : 18, height: isShot ? 22 : 18)
            .overlay(
                Image(systemName: "soccerball")
                    .font(.system(size: isShot ? 16 : 13, weight: .black))
                    .foregroundColor(Color.black.opacity(0.72))
                    .rotationEffect(.degrees(spin * 1440))
            )
            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 3)
    }
}

private struct ShotBurst: View {
    let side: BracketSlotSide
    let outcome: MatchChanceOutcome?

    var body: some View {
        Image(systemName: side == .home ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
            .font(.system(size: 34, weight: .black))
            .foregroundColor(outcome == .save ? Color.white : Color(hex: "#FFC93C"))
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 3)
    }
}

private struct SaveFlash: View {
    var body: some View {
        Image(systemName: "hand.raised.fill")
            .font(.system(size: 34, weight: .black))
            .foregroundColor(.white)
            .padding(10)
            .background(Circle().fill(Color(hex: "#263645").opacity(0.76)))
            .shadow(color: Color.black.opacity(0.32), radius: 6, x: 0, y: 4)
    }
}

private struct JerseyStyle {
    let primaryHex: String
    let secondaryHex: String

    var primary: Color { Color(hex: primaryHex) }
    var secondary: Color { Color(hex: secondaryHex) }
    var border: Color { luminance(primaryHex) > 0.72 ? Color(hex: secondaryHex) : Color.white }
    var text: Color { luminance(primaryHex) > 0.62 ? Color(hex: "#1C2833") : .white }
    var textShadow: Color { luminance(primaryHex) > 0.62 ? .white.opacity(0.5) : .black.opacity(0.45) }
}

private struct RGB {
    let r: Double
    let g: Double
    let b: Double

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        if cleaned.count == 3 {
            r = Double((int >> 8) * 17) / 255
            g = Double((int >> 4 & 0xF) * 17) / 255
            b = Double((int & 0xF) * 17) / 255
        } else {
            r = Double(int >> 16 & 0xFF) / 255
            g = Double(int >> 8 & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        }
    }
}

private func luminance(_ hex: String) -> Double {
    let rgb = RGB(hex: hex)
    return 0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b
}

private struct SoccerPitchLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))

        let centerCircle = CGRect(
            x: rect.midX - rect.width * 0.075,
            y: rect.midY - rect.height * 0.15,
            width: rect.width * 0.15,
            height: rect.height * 0.3
        )
        path.addEllipse(in: centerCircle)

        path.addRect(CGRect(x: rect.minX, y: rect.midY - rect.height * 0.23, width: rect.width * 0.16, height: rect.height * 0.46))
        path.addRect(CGRect(x: rect.maxX - rect.width * 0.16, y: rect.midY - rect.height * 0.23, width: rect.width * 0.16, height: rect.height * 0.46))
        path.addRect(CGRect(x: rect.minX - rect.width * 0.015, y: rect.midY - rect.height * 0.09, width: rect.width * 0.015, height: rect.height * 0.18))
        path.addRect(CGRect(x: rect.maxX, y: rect.midY - rect.height * 0.09, width: rect.width * 0.015, height: rect.height * 0.18))
        return path
    }
}

private enum MatchSimulationFactory {
    static func makeResult(for match: TournamentMatch) -> MatchSimulationResult {
        guard let home = match.home, let away = match.away else {
            preconditionFailure("A simulated match needs two teams")
        }

        let score = plausibleScore()
        let homeGoals = score.0
        let awayGoals = score.1
        let decidedByPenalties = homeGoals == awayGoals
        let winner: Team
        if homeGoals > awayGoals {
            winner = home
        } else if awayGoals > homeGoals {
            winner = away
        } else {
            winner = Bool.random() ? home : away
        }

        var events: [MatchGoalEvent] = []
        let totalGoals = homeGoals + awayGoals
        if totalGoals > 0 {
            let minutes = uniqueGoalMinutes(count: totalGoals)
            var sides: [BracketSlotSide] = Array(repeating: .home, count: homeGoals) + Array(repeating: .away, count: awayGoals)
            sides.shuffle()
            events = zip(minutes, sides).map { MatchGoalEvent(minute: $0.0, side: $0.1) }.sorted { $0.minute < $1.minute }
        }
        let chances = makeChances(goalEvents: events)

        return MatchSimulationResult(
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            winner: winner,
            decidedByPenalties: decidedByPenalties,
            goalEvents: events,
            chanceEvents: chances
        )
    }

    private static func plausibleScore() -> (Int, Int) {
        let common = [(0, 0), (1, 0), (0, 1), (1, 1), (2, 1), (1, 2), (2, 0), (0, 2)]
        let medium = [(3, 1), (1, 3), (2, 2), (3, 2), (2, 3)]
        let rare = [(4, 0), (0, 4), (4, 1), (1, 4), (5, 2), (2, 5)]
        let roll = Int.random(in: 0..<100)
        if roll < 74 { return common.randomElement() ?? (1, 0) }
        if roll < 94 { return medium.randomElement() ?? (2, 1) }
        return rare.randomElement() ?? (4, 1)
    }

    private static func uniqueGoalMinutes(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        var minutes: Set<Int> = []
        while minutes.count < count {
            minutes.insert(Int.random(in: 8...86))
        }
        return Array(minutes).sorted()
    }

    private static func makeChances(goalEvents: [MatchGoalEvent]) -> [MatchChanceEvent] {
        var chances = goalEvents.map {
            MatchChanceEvent(minute: $0.minute, side: $0.side, outcome: .goal)
        }
        let extraCount = Int.random(in: 4...6)
        var used = Set(goalEvents.map(\.minute))
        var attempts = 0
        while chances.count < goalEvents.count + extraCount && attempts < 160 {
            attempts += 1
            let minute = Int.random(in: 6...88)
            guard !used.contains(where: { abs($0 - minute) < 5 }) else { continue }
            used.insert(minute)
            let side: BracketSlotSide = Bool.random() ? .home : .away
            let outcome: MatchChanceOutcome = Int.random(in: 0..<100) < 68 ? .save : .wide
            chances.append(MatchChanceEvent(minute: minute, side: side, outcome: outcome))
        }
        return chances.sorted { $0.minute < $1.minute }
    }
}

private enum BracketSlotSide: Equatable {
    case home, away
}

private enum TournamentPlayMode: String {
    case manual
    case simulated

    var title: String {
        switch self {
        case .manual: return "Manual"
        case .simulated: return "Partidos"
        }
    }

    var icon: String {
        switch self {
        case .manual: return "hand.tap.fill"
        case .simulated: return "play.circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .manual: return "TOCÁ UN ESCUDO PARA HACERLO AVANZAR"
        case .simulated: return "TOCÁ UN PARTIDO PARA JUGARLO"
        }
    }
}

private enum TournamentRound: String {
    case roundOf16, roundOf16Right, quarterFinals, quarterFinalsRight, semiFinals, semiFinalsRight, final
}

private struct TournamentMatch: Equatable {
    var home: Team?
    var away: Team?

    var winner: Team?
    var result: MatchSimulationResult?

    var isPlayable: Bool {
        home != nil && away != nil
    }
}

private struct MatchSimulationContext: Identifiable {
    let id = UUID()
    let round: TournamentRound
    let matchIndex: Int
    let match: TournamentMatch
}

private struct MatchSimulationResult: Equatable {
    let homeGoals: Int
    let awayGoals: Int
    let winner: Team
    let decidedByPenalties: Bool
    let goalEvents: [MatchGoalEvent]
    let chanceEvents: [MatchChanceEvent]
}

private struct MatchGoalEvent: Equatable, Identifiable {
    let id = UUID()
    let minute: Int
    let side: BracketSlotSide
}

private struct MatchChanceEvent: Equatable, Identifiable {
    let id = UUID()
    let minute: Int
    let side: BracketSlotSide
    let outcome: MatchChanceOutcome
}

private enum MatchChanceOutcome: Equatable {
    case goal
    case save
    case wide
}

private struct TournamentBracket: Equatable {
    var roundOf16: [TournamentMatch]
    var roundOf16Right: [TournamentMatch]
    var quarterFinals: [TournamentMatch]
    var quarterFinalsRight: [TournamentMatch]
    var semiFinals: [TournamentMatch]
    var semiFinalsRight: [TournamentMatch]
    var final: TournamentMatch
    var champion: Team?

    static let empty = TournamentBracket(
        roundOf16: Array(repeating: TournamentMatch(), count: 4),
        roundOf16Right: Array(repeating: TournamentMatch(), count: 4),
        quarterFinals: Array(repeating: TournamentMatch(), count: 2),
        quarterFinalsRight: Array(repeating: TournamentMatch(), count: 2),
        semiFinals: Array(repeating: TournamentMatch(), count: 1),
        semiFinalsRight: Array(repeating: TournamentMatch(), count: 1),
        final: TournamentMatch(),
        champion: nil
    )

    init(seedTeams teams: [Team]) {
        var slots = Array(teams.prefix(16)).map(Optional.some)
        while slots.count < 16 { slots.append(nil) }

        roundOf16 = stride(from: 0, to: 8, by: 2).map {
            TournamentMatch(home: slots[$0], away: slots[$0 + 1])
        }
        roundOf16Right = stride(from: 8, to: 16, by: 2).map {
            TournamentMatch(home: slots[$0], away: slots[$0 + 1])
        }
        quarterFinals = Array(repeating: TournamentMatch(), count: 2)
        quarterFinalsRight = Array(repeating: TournamentMatch(), count: 2)
        semiFinals = Array(repeating: TournamentMatch(), count: 1)
        semiFinalsRight = Array(repeating: TournamentMatch(), count: 1)
        final = TournamentMatch()
        champion = nil

        autoAdvanceByes()
    }

    private init(
        roundOf16: [TournamentMatch],
        roundOf16Right: [TournamentMatch],
        quarterFinals: [TournamentMatch],
        quarterFinalsRight: [TournamentMatch],
        semiFinals: [TournamentMatch],
        semiFinalsRight: [TournamentMatch],
        final: TournamentMatch,
        champion: Team?
    ) {
        self.roundOf16 = roundOf16
        self.roundOf16Right = roundOf16Right
        self.quarterFinals = quarterFinals
        self.quarterFinalsRight = quarterFinalsRight
        self.semiFinals = semiFinals
        self.semiFinalsRight = semiFinalsRight
        self.final = final
        self.champion = champion
    }

    mutating func advance(round: TournamentRound, matchIndex: Int, slot: BracketSlotSide) {
        switch round {
        case .roundOf16:
            guard let winner = selectedTeam(in: roundOf16[matchIndex], slot: slot) else { return }
            roundOf16[matchIndex].winner = winner
            roundOf16[matchIndex].result = nil
            setQuarterWinner(winner, sourceIndex: matchIndex, rightSide: false)
        case .roundOf16Right:
            guard let winner = selectedTeam(in: roundOf16Right[matchIndex], slot: slot) else { return }
            roundOf16Right[matchIndex].winner = winner
            roundOf16Right[matchIndex].result = nil
            setQuarterWinner(winner, sourceIndex: matchIndex, rightSide: true)
        case .quarterFinals:
            guard let winner = selectedTeam(in: quarterFinals[matchIndex], slot: slot) else { return }
            quarterFinals[matchIndex].winner = winner
            quarterFinals[matchIndex].result = nil
            setSemiWinner(winner, sourceIndex: matchIndex, rightSide: false)
        case .quarterFinalsRight:
            guard let winner = selectedTeam(in: quarterFinalsRight[matchIndex], slot: slot) else { return }
            quarterFinalsRight[matchIndex].winner = winner
            quarterFinalsRight[matchIndex].result = nil
            setSemiWinner(winner, sourceIndex: matchIndex, rightSide: true)
        case .semiFinals:
            guard let winner = selectedTeam(in: semiFinals[matchIndex], slot: slot) else { return }
            semiFinals[matchIndex].winner = winner
            semiFinals[matchIndex].result = nil
            final.home = winner
            final.winner = nil
            final.result = nil
            champion = nil
        case .semiFinalsRight:
            guard let winner = selectedTeam(in: semiFinalsRight[matchIndex], slot: slot) else { return }
            semiFinalsRight[matchIndex].winner = winner
            semiFinalsRight[matchIndex].result = nil
            final.away = winner
            final.winner = nil
            final.result = nil
            champion = nil
        case .final:
            guard let winner = selectedTeam(in: final, slot: slot) else { return }
            final.winner = winner
            final.result = nil
            champion = winner
        }
    }

    mutating func applySimulation(context: MatchSimulationContext, result: MatchSimulationResult) {
        switch context.round {
        case .roundOf16:
            guard roundOf16.indices.contains(context.matchIndex) else { return }
            roundOf16[context.matchIndex].winner = result.winner
            roundOf16[context.matchIndex].result = result
            setQuarterWinner(result.winner, sourceIndex: context.matchIndex, rightSide: false)
        case .roundOf16Right:
            guard roundOf16Right.indices.contains(context.matchIndex) else { return }
            roundOf16Right[context.matchIndex].winner = result.winner
            roundOf16Right[context.matchIndex].result = result
            setQuarterWinner(result.winner, sourceIndex: context.matchIndex, rightSide: true)
        case .quarterFinals:
            guard quarterFinals.indices.contains(context.matchIndex) else { return }
            quarterFinals[context.matchIndex].winner = result.winner
            quarterFinals[context.matchIndex].result = result
            setSemiWinner(result.winner, sourceIndex: context.matchIndex, rightSide: false)
        case .quarterFinalsRight:
            guard quarterFinalsRight.indices.contains(context.matchIndex) else { return }
            quarterFinalsRight[context.matchIndex].winner = result.winner
            quarterFinalsRight[context.matchIndex].result = result
            setSemiWinner(result.winner, sourceIndex: context.matchIndex, rightSide: true)
        case .semiFinals:
            guard semiFinals.indices.contains(context.matchIndex) else { return }
            semiFinals[context.matchIndex].winner = result.winner
            semiFinals[context.matchIndex].result = result
            final.home = result.winner
            final.winner = nil
            final.result = nil
            champion = nil
        case .semiFinalsRight:
            guard semiFinalsRight.indices.contains(context.matchIndex) else { return }
            semiFinalsRight[context.matchIndex].winner = result.winner
            semiFinalsRight[context.matchIndex].result = result
            final.away = result.winner
            final.winner = nil
            final.result = nil
            champion = nil
        case .final:
            final.winner = result.winner
            final.result = result
            champion = result.winner
        }
    }

    func isRecommended(round: TournamentRound, matchIndex: Int) -> Bool {
        guard let first = firstPlayableMatchWithoutResult() else { return false }
        return first.round == round && first.matchIndex == matchIndex
    }

    private func firstPlayableMatchWithoutResult() -> (round: TournamentRound, matchIndex: Int)? {
        let groups: [(TournamentRound, [TournamentMatch])] = [
            (.roundOf16, roundOf16),
            (.roundOf16Right, roundOf16Right),
            (.quarterFinals, quarterFinals),
            (.quarterFinalsRight, quarterFinalsRight),
            (.semiFinals, semiFinals),
            (.semiFinalsRight, semiFinalsRight),
            (.final, [final])
        ]
        for group in groups {
            if let index = group.1.firstIndex(where: { $0.isPlayable && $0.result == nil }) {
                return (group.0, index)
            }
        }
        return nil
    }

    private mutating func setQuarterWinner(_ winner: Team, sourceIndex: Int, rightSide: Bool) {
        let targetIndex = sourceIndex / 2
        let isHome = sourceIndex % 2 == 0
        if rightSide {
            if isHome { quarterFinalsRight[targetIndex].home = winner } else { quarterFinalsRight[targetIndex].away = winner }
            quarterFinalsRight[targetIndex].winner = nil
            quarterFinalsRight[targetIndex].result = nil
        } else {
            if isHome { quarterFinals[targetIndex].home = winner } else { quarterFinals[targetIndex].away = winner }
            quarterFinals[targetIndex].winner = nil
            quarterFinals[targetIndex].result = nil
        }
        clearFromQuarterChange(rightSide: rightSide)
    }

    private mutating func setSemiWinner(_ winner: Team, sourceIndex: Int, rightSide: Bool) {
        let isHome = sourceIndex == 0
        if rightSide {
            if isHome { semiFinalsRight[0].home = winner } else { semiFinalsRight[0].away = winner }
            semiFinalsRight[0].winner = nil
            semiFinalsRight[0].result = nil
            final.away = nil
        } else {
            if isHome { semiFinals[0].home = winner } else { semiFinals[0].away = winner }
            semiFinals[0].winner = nil
            semiFinals[0].result = nil
            final.home = nil
        }
        final = TournamentMatch(home: final.home, away: final.away, winner: nil)
        champion = nil
    }

    private mutating func clearFromQuarterChange(rightSide: Bool) {
        if rightSide {
            semiFinalsRight = Array(repeating: TournamentMatch(), count: 1)
            final.away = nil
        } else {
            semiFinals = Array(repeating: TournamentMatch(), count: 1)
            final.home = nil
        }
        final.winner = nil
        final.result = nil
        champion = nil
    }

    private func selectedTeam(in match: TournamentMatch, slot: BracketSlotSide) -> Team? {
        switch slot {
        case .home: return match.home
        case .away: return match.away
        }
    }

    private mutating func autoAdvanceByes() {
        for index in roundOf16.indices {
            if roundOf16[index].home != nil && roundOf16[index].away == nil {
                advance(round: .roundOf16, matchIndex: index, slot: .home)
            } else if roundOf16[index].home == nil && roundOf16[index].away != nil {
                advance(round: .roundOf16, matchIndex: index, slot: .away)
            }
        }
        for index in roundOf16Right.indices {
            if roundOf16Right[index].home != nil && roundOf16Right[index].away == nil {
                advance(round: .roundOf16Right, matchIndex: index, slot: .home)
            } else if roundOf16Right[index].home == nil && roundOf16Right[index].away != nil {
                advance(round: .roundOf16Right, matchIndex: index, slot: .away)
            }
        }
    }
}
