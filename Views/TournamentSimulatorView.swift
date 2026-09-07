import Foundation
import SwiftUI

struct TournamentSimulatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountryId = "wc26"
    @State private var bracket = TournamentBracket.empty
    @State private var mode: TournamentPlayMode = .manual
    @State private var activeSimulation: MatchSimulationContext?
    @State private var wcScores: [String: FixtureScore] = [:]
    @State private var wcCover: WCCover?
    @State private var worldCup = WorldCup2026Fixture()
    @State private var selectedRandomTeamIds = WorldCup2026Fixture.defaultRandomTeamIds
    @State private var isWorldCupRandomized = false
    @State private var showingWorldCupTeamEditor = false

    private var tournaments: [Country] {
        CAMI_DATA.countries
    }

    private var isWorldCup: Bool {
        selectedCountryId == "wc26"
    }

    private var selectedCountry: Country {
        CAMI_DATA.country(id: selectedCountryId) ?? tournaments[0]
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
                        LeaguePicker(leagues: tournaments, selectedCountryId: $selectedCountryId) {
                            onTournamentChange()
                        }

                        TournamentModePicker(mode: $mode)

                        Button {
                            SoundManager.shared.playTap()
                            if isWorldCup { simulateAllWC() } else { generateBracket() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: isWorldCup ? "dice.fill" : "shuffle")
                                Text(isWorldCup ? "SIMULAR TODO" : "ARMAR LLAVES")
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

                    if isWorldCup {
                        WorldCupTournamentBoard(
                            mode: mode,
                            size: geo.size,
                            tournament: worldCup,
                            scores: wcScores,
                            onPlay: { context in
                                SoundManager.shared.playTap()
                                wcCover = .sim(context)
                            },
                            onManualPick: { matchId, side in
                                manualPickWC(matchId: matchId, side: side)
                            }
                        )
                        .frame(maxWidth: 1220, maxHeight: .infinity)
                    } else {
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
                }
                .padding(.horizontal, 34)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            if !isWorldCup, bracket.roundOf16.allSatisfy({ $0.home == nil && $0.away == nil }) {
                generateBracket()
            }
        }
        .fullScreenCover(item: $activeSimulation) { context in
            if let home = context.match.home, let away = context.match.away {
                MatchSimulationModal(home: home, away: away) { result in
                    bracket.applySimulation(context: context, result: result)
                    activeSimulation = nil
                }
            }
        }
        .fullScreenCover(item: $wcCover) { cover in
            switch cover {
            case .sim(let context):
                MatchSimulationModal(
                    home: context.homeTeam,
                    away: context.awayTeam,
                    homeFlag: context.homeFlag,
                    awayFlag: context.awayFlag,
                    showsPenaltyShootout: context.isKnockout
                ) { result in
                    finishWCSim(context, result: result)
                }
            case .champion(let team, let flag):
                WCChampionCover(champion: team, flag: flag) { wcCover = nil }
            }
        }
        .sheet(isPresented: $showingWorldCupTeamEditor) {
            WorldCupTeamEditorSheet(
                selectedTeamIds: $selectedRandomTeamIds,
                lockedTeamIds: WorldCup2026Fixture.lockedRandomTeamIds,
                teams: WorldCup2026Fixture.randomTeamPool
            )
        }
        .onChange(of: selectedRandomTeamIds) { _ in
            guard isWorldCup && isWorldCupRandomized else { return }
            worldCup = WorldCup2026Fixture(randomTeamIds: selectedRandomTeamIds)
            wcScores.removeAll()
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
            if isWorldCup {
                HStack(spacing: 10) {
                    Button {
                        SoundManager.shared.playTap()
                        showingWorldCupTeamEditor = true
                    } label: {
                        Label("EQUIPOS", systemImage: "person.2.badge.gearshape.fill")
                    }
                    .buttonStyle(WorldCupHeaderButtonStyle(isPrimary: false))
                    .accessibilityLabel("Cambiar equipos del sorteo aleatorio")

                    Button {
                        randomizeWorldCupGroups()
                    } label: {
                        Label(isWorldCupRandomized ? "NUEVO SORTEO" : "ALEATORIO", systemImage: "shuffle")
                    }
                    .buttonStyle(WorldCupHeaderButtonStyle(isPrimary: isWorldCupRandomized))
                    .accessibilityLabel("Mezclar grupos de forma aleatoria")

                    Button {
                        resetWorldCupFixture()
                    } label: {
                        Label("ORIGINAL", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(WorldCupHeaderButtonStyle(isPrimary: !isWorldCupRandomized))
                    .accessibilityLabel(isWorldCupRandomized ? "Volver al fixture real" : "Limpiar resultados")
                }
            } else {
                Circle().fill(Color.clear).frame(width: 64, height: 64)
            }
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

    // MARK: - World Cup

    private func onTournamentChange() {
        if isWorldCup {
            wcScores.removeAll()
        } else {
            resetBracket()
        }
    }

    private func randomizeWorldCupGroups() {
        SoundManager.shared.playTap()
        worldCup = WorldCup2026Fixture(randomTeamIds: selectedRandomTeamIds)
        wcScores.removeAll()
        isWorldCupRandomized = true
    }

    private func resetWorldCupFixture() {
        SoundManager.shared.playTap()
        worldCup = WorldCup2026Fixture()
        wcScores.removeAll()
        isWorldCupRandomized = false
    }

    private func manualPickWC(matchId: String, side: MatchSide) {
        SoundManager.shared.playTap()
        wcScores[matchId] = FixtureScore(home: side == .home ? 1 : 0, away: side == .home ? 0 : 1)
        crownWorldCupChampionIfNeeded(matchId: matchId)
    }

    private func finishWCSim(_ context: WorldCupSimContext, result: MatchSimulationResult) {
        var score = FixtureScore(home: result.homeGoals, away: result.awayGoals)
        if context.isKnockout && result.homeGoals == result.awayGoals {
            score.penaltyWinnerId = (result.winner.id == context.homeTeam.id) ? context.homeFixtureId : context.awayFixtureId
        }
        wcScores[context.matchId] = score
        if context.matchId == "wc26_m104", let champion = worldCup.champion(scores: wcScores) {
            wcCover = .champion(team: worldCupTeam(for: champion), flag: champion.flag)
        } else {
            wcCover = nil
        }
    }

    private func crownWorldCupChampionIfNeeded(matchId: String) {
        guard matchId == "wc26_m104", let champion = worldCup.champion(scores: wcScores) else { return }
        wcCover = .champion(team: worldCupTeam(for: champion), flag: champion.flag)
    }

    private func simulateAllWC() {
        var newScores = wcScores

        for group in worldCup.groups {
            for match in group.matches where newScores[match.id]?.isComplete != true {
                let result = MatchSimulationFactory.makeResult(
                    home: worldCupTeam(for: match.home),
                    away: worldCupTeam(for: match.away)
                )
                newScores[match.id] = FixtureScore(home: result.homeGoals, away: result.awayGoals)
            }
        }

        // Each pass resolves one knockout round; five rounds need at most five passes.
        for _ in 0..<6 {
            let bracket = worldCup.knockoutBracket(scores: newScores)
            var changed = false
            for round in bracket.rounds {
                for match in round.matches {
                    guard let home = match.home, let away = match.away else { continue }
                    if newScores[match.id]?.isComplete == true { continue }
                    let homeTeam = worldCupTeam(for: home)
                    let awayTeam = worldCupTeam(for: away)
                    let result = MatchSimulationFactory.makeResult(home: homeTeam, away: awayTeam)
                    var score = FixtureScore(home: result.homeGoals, away: result.awayGoals)
                    if result.homeGoals == result.awayGoals {
                        score.penaltyWinnerId = (result.winner.id == homeTeam.id) ? home.id : away.id
                    }
                    newScores[match.id] = score
                    changed = true
                }
            }
            if !changed { break }
        }

        wcScores = newScores
        if let champion = worldCup.champion(scores: newScores) {
            wcCover = .champion(team: worldCupTeam(for: champion), flag: champion.flag)
        }
    }
}

private struct WorldCupHeaderButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Nunito-Black", size: 13))
            .foregroundColor(isPrimary ? .white : Color(hex: "#263645"))
            .padding(.horizontal, 15)
            .frame(height: 50)
            .background(Capsule().fill(isPrimary ? Color(hex: "#FF7B3D") : .white))
            .opacity(configuration.isPressed ? 0.72 : 1)
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

    private func advance(_ round: TournamentRound, matchIndex: Int = 0, slot: MatchSide) {
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
    let onPick: (MatchSide) -> Void
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

struct ChampionGloryOverlay: View {
    let champion: Team
    var flag: String? = nil
    var useWorldCupTrophy = false
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            if useWorldCupTrophy {
                ChampionConfettiRain(animate: animate)
                ChampionFireworksLayer(animate: animate)
            }

            ForEach(0..<18, id: \.self) { index in
                GloryRay(index: index, animate: animate)
            }

            ForEach(0..<44, id: \.self) { index in
                GloryParticle(index: index, animate: animate)
            }

            VStack(spacing: 14) {
                if useWorldCupTrophy {
                    Image("WorldCupTrophy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 156, height: 220)
                        .shadow(color: Color(hex: "#FFC93C").opacity(0.9), radius: animate ? 34 : 12, x: 0, y: 0)
                        .scaleEffect(animate ? 1.06 : 0.82)
                } else {
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
                }

                Group {
                    if let flag {
                        Text(flag).font(.system(size: 96))
                    } else {
                        CrestView(crest: champion.crest, size: 112)
                    }
                }
                .padding(18)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color(hex: "#FFC93C").opacity(0.85), radius: animate ? 30 : 10, x: 0, y: 0)
                )
                .scaleEffect(animate ? 1 : 0.72)

                Text("CAMPEÓN")
                    .font(.custom("Nunito-Black", size: useWorldCupTrophy ? 62 : 54))
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
            .padding(useWorldCupTrophy ? 44 : 38)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(hex: "#1C2833").opacity(useWorldCupTrophy ? 0.72 : 0.82))
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

private struct ChampionFireworksLayer: View {
    let animate: Bool

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                ChampionFireworkBurst(index: index, animate: animate)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct ChampionFireworkBurst: View {
    let index: Int
    let animate: Bool

    private var x: CGFloat {
        [0.14, 0.32, 0.68, 0.86, 0.48, 0.22, 0.78][index % 7]
    }

    private var y: CGFloat {
        [0.16, 0.24, 0.18, 0.30, 0.12, 0.42, 0.42][index % 7]
    }

    private var baseColor: Color {
        [Color(hex: "#FFC93C"), Color(hex: "#FF7B3D"), Color(hex: "#6BCBFF"), Color(hex: "#7DDB8B")][index % 4]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<18, id: \.self) { ray in
                    let angle = Double(ray) * 20
                    Circle()
                        .fill(baseColor)
                        .frame(width: 8, height: 8)
                        .offset(
                            x: animate ? cos(angle * .pi / 180) * CGFloat(58 + index * 8) : 0,
                            y: animate ? sin(angle * .pi / 180) * CGFloat(58 + index * 8) : 0
                        )
                        .opacity(animate ? 0 : 0.95)
                }
                Circle()
                    .stroke(baseColor.opacity(0.65), lineWidth: 3)
                    .frame(width: animate ? 148 : 14, height: animate ? 148 : 14)
                    .opacity(animate ? 0 : 0.86)
            }
            .position(x: geo.size.width * x, y: geo.size.height * y)
            .animation(.easeOut(duration: 1.45).repeatForever(autoreverses: false).delay(Double(index) * 0.18), value: animate)
        }
    }
}

private struct ChampionConfettiRain: View {
    let animate: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<90, id: \.self) { index in
                    ChampionRainPiece(index: index, animate: animate, size: geo.size)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct ChampionRainPiece: View {
    let index: Int
    let animate: Bool
    let size: CGSize

    private var color: Color {
        [Color(hex: "#FFC93C"), Color(hex: "#FF7B3D"), Color(hex: "#6BCBFF"), Color.white, Color(hex: "#7DDB8B")][index % 5]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: CGFloat(7 + index % 5), height: CGFloat(12 + index % 7))
            .rotationEffect(.degrees(animate ? Double(index * 37 + 280) : Double(index * 13)))
            .position(
                x: CGFloat((index * 53) % 100) / 100 * size.width,
                y: animate ? size.height + CGFloat((index % 12) * 34) : -CGFloat((index % 18) * 26)
            )
            .opacity(0.92)
            .animation(.linear(duration: Double(3 + index % 4)).repeatForever(autoreverses: false).delay(Double(index % 16) * 0.08), value: animate)
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

struct MatchSimulationModal: View {
    let home: Team
    let away: Team
    let homeFlag: String?
    let awayFlag: String?
    let showsPenaltyShootout: Bool
    let onFinish: (MatchSimulationResult) -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private var reduceMotion: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--match-preview") &&
            ProcessInfo.processInfo.arguments.contains("--match-reduce-motion") { return true }
        #endif
        return systemReduceMotion
    }
    @State private var elapsed: TimeInterval = 0
    @State private var stage: MatchSimulationStage = .match
    @State private var penaltyElapsed: TimeInterval = 0
    @State private var simulation: MatchSimulation
    @State private var penaltyShootout: PenaltyShootout?
    @State private var duration: TimeInterval
    @State private var lastTickDate: Date?

    private var result: MatchSimulationResult { simulation.result }
    private var beats: [MatchBeat] { simulation.beats }

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    init(
        home: Team,
        away: Team,
        homeFlag: String? = nil,
        awayFlag: String? = nil,
        showsPenaltyShootout: Bool = true,
        simulation suppliedSimulation: MatchSimulation? = nil,
        onFinish: @escaping (MatchSimulationResult) -> Void
    ) {
        self.home = home
        self.away = away
        self.homeFlag = homeFlag
        self.awayFlag = awayFlag
        self.showsPenaltyShootout = showsPenaltyShootout
        self.onFinish = onFinish
        let simulation = suppliedSimulation ?? MatchSimulationFactory.makeSimulation(home: home, away: away)
        _simulation = State(initialValue: simulation)
        if showsPenaltyShootout && simulation.result.decidedByPenalties {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--match-preview") {
                var generator = MatchPreviewGenerator()
                _penaltyShootout = State(initialValue: PenaltyShootoutFactory.makeShootout(
                    home: home, away: away, winner: simulation.result.winner, rng: &generator))
            } else {
                _penaltyShootout = State(initialValue: PenaltyShootoutFactory.makeShootout(home: home, away: away, winner: simulation.result.winner))
            }
            #else
            _penaltyShootout = State(initialValue: PenaltyShootoutFactory.makeShootout(home: home, away: away, winner: simulation.result.winner))
            #endif
        } else {
            _penaltyShootout = State(initialValue: nil)
        }
        _duration = State(initialValue: 100)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#132D38"), Color(hex: "#132722")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    scoreboard
                        .frame(maxWidth: 980)

                    Group {
                        if showPenaltyScene, let penaltyShootout {
                            PenaltyShootoutView(
                                home: home,
                                away: away,
                                homeFlag: homeFlag,
                                awayFlag: awayFlag,
                                shootout: penaltyShootout,
                                elapsed: min(penaltyElapsed, penaltyDuration),
                                duration: penaltyDuration,
                                reduceMotion: reduceMotion
                            )
                        } else {
                            MatchPitchView(
                                home: home,
                                away: away,
                                frame: MatchPresentation.frame(beats: beats, progress: progress, reducedMotion: reduceMotion),
                                beats: beats,
                                progress: progress,
                                elapsed: elapsed,
                                duration: duration,
                                reduceMotion: reduceMotion
                            )
                        }
                    }
                    .frame(maxWidth: 1180, maxHeight: geo.size.height * 0.72)
                    .aspectRatio(1.72, contentMode: .fit)
                    .padding(.horizontal, 18)

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
        .statusBarHidden(true)
        .onAppear {
            duration = reduceMotion ? 100 : Double.random(in: 90...110)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--match-preview") {
                duration = 100
                if let value = ProcessInfo.processInfo.environment["MATCH_PREVIEW_PROGRESS"], let initial = Double(value) {
                    elapsed = min(1, max(0, initial)) * duration
                }
                if let moment = ProcessInfo.processInfo.environment["MATCH_PREVIEW_MOMENT"] {
                    if moment.hasPrefix("shootout"), let penaltyShootout {
                        let index = penaltyShootout.shots.firstIndex(where: { $0.outcome == .goal }) ?? 0
                        elapsed = duration
                        stage = moment == "shootout-finished" ? .finished : .penalties
                        let local = moment == "shootout-before-goal" ? 0.74 : 0.82
                        penaltyElapsed = stage == .finished ? penaltyDuration : (Double(index) + local) * penaltyShotDuration
                    }
                    let kind: MatchSetPiece? = moment.hasPrefix("free-kick") ? .freeKick
                        : moment.hasPrefix("penalty") ? .penalty : nil
                    let previewBeat = beats.first { beat in
                        if let kind {
                            guard beat.setPiece == kind else { return false }
                            if moment.hasSuffix("start") {
                                if case .foul = beat.action { return true }
                                return false
                            }
                            if moment.hasSuffix("shot") || moment.hasSuffix("result") { return beat.action.isShot }
                            if case .setPieceSetup = beat.action { return true }
                            return false
                        }
                        return beat.action.shotOutcome == .goal
                    }
                    if let previewBeat, !moment.hasPrefix("shootout") {
                        let local = kind != nil
                            ? (moment.hasSuffix("start") ? 0.05 : moment.hasSuffix("shot") ? 0.64 : moment.hasSuffix("result") ? 0.86 : 0.96)
                            : (moment == "before-goal" ? 0.74 : 0.82)
                        elapsed = (previewBeat.startProgress + (previewBeat.endProgress - previewBeat.startProgress) * local) * duration
                    }
                }
            }
            #endif
            lastTickDate = Date()
        }
        .onReceive(timer) { tickDate in
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--match-preview-still") { return }
            #endif
            guard stage != .finished else { return }
            guard scenePhase == .active else {
                lastTickDate = tickDate
                return
            }
            let tickDuration = lastTickDate.map {
                min(0.1, max(0, tickDate.timeIntervalSince($0)))
            } ?? (1.0 / 30.0)
            lastTickDate = tickDate
            switch stage {
            case .match:
                elapsed = min(duration, elapsed + tickDuration)
                if elapsed >= duration {
                    if shouldShowPenaltyShootout {
                        penaltyElapsed = 0
                        if reduceMotion {
                            stage = .penalties
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                                stage = .penalties
                            }
                        }
                    } else {
                        if reduceMotion {
                            stage = .finished
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                                stage = .finished
                            }
                        }
                    }
                }
            case .penalties:
                penaltyElapsed = min(penaltyDuration, penaltyElapsed + tickDuration)
                if penaltyElapsed >= penaltyDuration {
                    if reduceMotion {
                        stage = .finished
                    } else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                            stage = .finished
                        }
                    }
                }
            case .finished:
                return
            }
        }
    }

    private var isFinished: Bool {
        stage == .finished
    }

    private var shouldShowPenaltyShootout: Bool {
        showsPenaltyShootout && result.decidedByPenalties && penaltyShootout != nil
    }

    private var showPenaltyScene: Bool {
        stage == .penalties || (stage == .finished && shouldShowPenaltyShootout)
    }

    private var isDrawWithoutPenalty: Bool {
        result.homeGoals == result.awayGoals && !shouldShowPenaltyShootout
    }

    private var penaltyDuration: TimeInterval {
        70
    }

    private var penaltyShotDuration: TimeInterval {
        guard let penaltyShootout else { return 3.2 }
        return penaltyDuration / Double(max(1, penaltyShootout.shots.count))
    }

    private var currentPenaltyIndex: Int {
        guard let penaltyShootout else { return 0 }
        if stage == .finished { return max(0, penaltyShootout.shots.count - 1) }
        return min(max(0, penaltyShootout.shots.count - 1), Int(penaltyElapsed / penaltyShotDuration))
    }

    private var currentPenaltyLocalProgress: CGFloat {
        guard stage == .penalties else { return 1 }
        let shotStart = Double(currentPenaltyIndex) * penaltyShotDuration
        return min(1, max(0, CGFloat((penaltyElapsed - shotStart) / penaltyShotDuration)))
    }

    private var visiblePenaltyShotCount: Int {
        guard let penaltyShootout else { return 0 }
        if stage == .finished { return penaltyShootout.shots.count }
        let completed = Int(penaltyElapsed / penaltyShotDuration)
        let includeCurrent = currentPenaltyLocalProgress >= MatchPresentation.shotImpactProgress ? 1 : 0
        return min(penaltyShootout.shots.count, completed + includeCurrent)
    }

    private var livePenaltyScore: (home: Int, away: Int) {
        penaltyShootout?.score(after: visiblePenaltyShotCount) ?? (0, 0)
    }

    private var finalPenaltyScore: (home: Int, away: Int)? {
        penaltyShootout?.score(after: penaltyShootout?.shots.count ?? 0)
    }

    private var progress: Double {
        guard duration > 0 else { return 1 }
        return min(1, elapsed / duration)
    }

    private var matchMinute: Int {
        min(90, Int(progress * 90))
    }

    private var liveHomeGoals: Int {
        liveGoals(for: .home)
    }

    private var liveAwayGoals: Int {
        liveGoals(for: .away)
    }

    private var currentEvent: String {
        if stage == .penalties, let shot = currentPenaltyShot {
            let teamName = team(for: shot.side).short.uppercased()
            if currentPenaltyLocalProgress < 0.25 { return "\(teamName) TOMA CARRERA" }
            if currentPenaltyLocalProgress < 0.52 { return "PATEA \(teamName)" }
            if currentPenaltyLocalProgress < MatchPresentation.shotImpactProgress { return "VIAJA LA PELOTA" }
            return shot.outcome == .goal ? "GOOOL DE \(teamName)" : "ATAJÓ EL ARQUERO"
        }
        if isFinished {
            if shouldShowPenaltyShootout { return "FINAL POR PENALES" }
            if isDrawWithoutPenalty { return "EMPATE FINAL" }
            return "FINAL DEL PARTIDO"
        }
        guard let beat = currentOpenPlayBeat else { return "ARRANCA EL PARTIDO" }
        return eventCopy(for: beat)
    }

    private var currentPenaltyShot: PenaltyShot? {
        guard let penaltyShootout, penaltyShootout.shots.indices.contains(currentPenaltyIndex) else { return nil }
        return penaltyShootout.shots[currentPenaltyIndex]
    }

    private var currentOpenPlayBeat: MatchBeat? {
        beats.first {
            progress >= $0.startProgress && (progress < $0.endProgress || $0.id == beats.last?.id)
        } ?? beats.last
    }

    private func liveGoals(for side: MatchSide) -> Int {
        beats.filter { beat in
            guard case let .shot(shooter, outcome) = beat.action,
                  shooter.side == side,
                  outcome == .goal else { return false }
            let goalCrossing = beat.startProgress + (beat.endProgress - beat.startProgress) * MatchPresentation.shotImpactProgress
            return progress >= goalCrossing
        }.count
    }

    private func eventCopy(for beat: MatchBeat) -> String {
        let local = beat.localProgress(at: progress)
        switch beat.action {
        case .kickoff:
            return "ARRANCA EL PARTIDO"
        case let .carry(player):
            return "AVANZA \(team(for: player.side).short.uppercased())"
        case let .pass(from, _):
            return local < 0.34
                ? "LEVANTA LA CABEZA \(team(for: from.side).short.uppercased())"
                : "PASE DE \(team(for: from.side).short.uppercased())"
        case let .cross(from, _):
            return local < 0.28
                ? "DESBORDA \(team(for: from.side).short.uppercased())"
                : local < 0.76
                    ? "TIRA EL CENTRO \(team(for: from.side).short.uppercased())"
                    : "LLEGA EL DELANTERO"
        case let .pressure(_, defender):
            return "PRESIONA \(team(for: defender.side).short.uppercased())"
        case let .duel(carrier, _, retained):
            if local < 0.58 { return "DUELO POR LA PELOTA" }
            return retained
                ? "SIGUE \(team(for: carrier.side).short.uppercased())"
                : "PELOTA DIVIDIDA"
        case let .interception(_, _, defender):
            return local < 0.52
                ? "LEE EL PASE \(team(for: defender.side).short.uppercased())"
                : "INTERCEPTA \(team(for: defender.side).short.uppercased())"
        case let .tackle(_, defender):
            return local < 0.5
                ? "VA AL CRUCE \(team(for: defender.side).short.uppercased())"
                : "RECUPERA \(team(for: defender.side).short.uppercased())"
        case let .foul(carrier, _):
            return "¡FALTA! A FAVOR DE \(team(for: carrier.side).short.uppercased())"
        case let .setPieceSetup(taker, kind):
            let teamName = team(for: taker.side).short.uppercased()
            return kind == .penalty ? "PENAL PARA \(teamName) · TOMA CARRERA"
                : "TIRO LIBRE PARA \(teamName) · SE ARMA LA BARRERA"
        case let .shot(shooter, outcome):
            let teamName = team(for: shooter.side).short.uppercased()
            if local < 0.34 {
                if let kind = beat.setPiece {
                    return "\(kind == .penalty ? "PENAL" : "TIRO LIBRE") · TOMA CARRERA \(teamName)"
                }
                return "ARMA EL REMATE \(teamName)"
            }
            if local < MatchPresentation.shotImpactProgress { return "PATEA \(teamName)" }
            switch outcome {
            case .goal: return "GOOOL DE \(teamName)"
            case .saved: return "ATAJADÓN DEL ARQUERO"
            case .wide: return "AFUERA"
            case .blocked: return "BLOQUEA LA DEFENSA"
            }
        case let .restart(_, _, reason):
            switch reason {
            case .kickoffAfterGoal: return "SACA DEL MEDIO"
            case .goalkeeperPossession: return "SALE JUGANDO EL ARQUERO"
            case .goalKick: return "SAQUE DE ARCO"
            case .clearance: return "DESPEJA LA DEFENSA"
            }
        case .finalWhistle:
            return "FINAL DEL PARTIDO"
        }
    }

    private var scoreboard: some View {
        VStack(spacing: 0) {
          HStack(spacing: 16) {
            scoreTeam(
                team: home,
                flag: homeFlag,
                score: displayHomeGoals,
                penaltyScore: homePenaltyDisplay,
                reverse: false
            )
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: "#7DDB8B")).frame(width: 5, height: 5)
                    Text(stage == .finished ? "FINAL" : "EN JUEGO")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.2).foregroundColor(.white.opacity(0.65))
                }
                Text(scoreboardTitle)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Color(hex: "#FFC93C"))
                Text(scoreboardSubtitle)
                    .font(.custom("Nunito-Black", size: 10))
                    .foregroundColor(.white.opacity(0.52))
            }
            scoreTeam(
                team: away,
                flag: awayFlag,
                score: displayAwayGoals,
                penaltyScore: awayPenaltyDisplay,
                reverse: true
            )
          }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
          GeometryReader { geometry in
              Rectangle().fill(.white.opacity(0.08))
              Rectangle().fill(Color(hex: "#7DDB8B"))
                  .frame(width: geometry.size.width * progress)
          }.frame(height: 3)
        }
        .background(Color(hex: "#10242E").opacity(0.95))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(home.short) \(displayHomeGoals), \(away.short) \(displayAwayGoals)")
        .accessibilityIdentifier("match.scoreboard")
    }

    private var displayHomeGoals: Int {
        stage == .match ? liveHomeGoals : result.homeGoals
    }

    private var displayAwayGoals: Int {
        stage == .match ? liveAwayGoals : result.awayGoals
    }

    private var homePenaltyDisplay: Int? {
        showPenaltyScene ? livePenaltyScore.home : nil
    }

    private var awayPenaltyDisplay: Int? {
        showPenaltyScene ? livePenaltyScore.away : nil
    }

    private var scoreboardTitle: String {
        if stage == .penalties, let penaltyShootout {
            return "PEN \(min(currentPenaltyIndex + 1, penaltyShootout.shots.count))/\(penaltyShootout.shots.count)"
        }
        if showPenaltyScene { return "PENALES" }
        return "\(matchMinute)'"
    }

    private var scoreboardSubtitle: String {
        showPenaltyScene ? "DEFINICIÓN" : "PARTIDO"
    }

    private func scoreTeam(team: Team?, flag: String?, score: Int, penaltyScore: Int?, reverse: Bool) -> some View {
        HStack(spacing: 12) {
            if reverse {
                scoreNumber(score, side: .away)
                Spacer(minLength: 0)
            }
            if let flag {
                Text(flag).font(.system(size: 40))
            } else if let team {
                CrestView(crest: team.crest, size: 46)
            }
            if let team {
                Text(team.short.uppercased())
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            if !reverse { Spacer(minLength: 0) }
            if let penaltyScore {
                Text("P \(penaltyScore)")
                    .font(.custom("Nunito-Black", size: 15))
                    .foregroundColor(Color(hex: "#FFC93C"))
                    .monospacedDigit()
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            if !reverse { scoreNumber(score, side: .home) }
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreNumber(_ score: Int, side: MatchSide) -> some View {
        let age = goalAge(for: side)
        return Text("\(score)")
            .font(.system(size: 46, weight: .black, design: .rounded))
            .foregroundColor(age == nil ? .white : Color(hex: "#FFC93C")).monospacedDigit()
            .frame(minWidth: 54)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
            .scaleEffect(reduceMotion ? 1 : 1 + (age.map { 0.16 * exp(-$0 * 4) * sin($0 * 16) } ?? 0))
    }

    private func goalAge(for side: MatchSide) -> Double? {
        guard stage == .match, let beat = beats.last(where: {
            $0.action.shotOutcome == .goal && $0.action.primaryPlayer?.side == side &&
            progress >= $0.startProgress + ($0.endProgress - $0.startProgress) * MatchPresentation.shotImpactProgress
        }) else { return nil }
        let impact = beat.startProgress + (beat.endProgress - beat.startProgress) * MatchPresentation.shotImpactProgress
        let age = (progress - impact) * duration
        return age < 2.4 ? age : nil
    }

    private var winnerFlag: String? {
        result.winner.id == home.id ? homeFlag : awayFlag
    }

    private var bottomEvent: some View {
        HStack(spacing: 14) {
            Image(systemName: eventIcon)
                .font(.system(size: 23, weight: .bold))
                .frame(width: 44, height: 40)
                .foregroundColor(Color(hex: "#FFC93C"))
            Text(currentEvent)
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundColor((currentEvent.contains("GOOOL") || currentEvent.contains("ATAJAD")) ? Color(hex: "#FFC93C") : .white)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            Spacer(minLength: 0)
        }
            .padding(.horizontal, 18)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.26))
            .cornerRadius(20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Minuto \(matchMinute). \(home.short) \(displayHomeGoals), \(away.short) \(displayAwayGoals). \(currentEvent)"
            )
            .accessibilityAddTraits(.updatesFrequently)
            .accessibilityIdentifier("match.event")
    }

    private var eventIcon: String {
        if isFinished { return "flag.checkered" }
        if currentEvent.contains("GOOOL") { return "star.fill" }
        if currentEvent.contains("ATAJA") { return "hand.raised.fill" }
        if currentEvent.contains("FALTA") { return "hand.raised.fill" }
        if currentOpenPlayBeat?.setPiece != nil { return "scope" }
        guard let action = currentOpenPlayBeat?.action else { return "soccerball" }
        if action.isShot { return "scope" }
        if action.defender != nil { return "shield.fill" }
        if action.isPass || action.isCross { return "arrow.triangle.branch" }
        return "soccerball"
    }

    private var finishedPanel: some View {
        VStack(spacing: 16) {
            Text(finishedTitle)
                .font(.custom("Nunito-Black", size: 24))
                .foregroundColor(Color(hex: "#FFC93C"))
            Group {
                if isDrawWithoutPenalty {
                    HStack(spacing: 20) {
                        teamMark(team: home, flag: homeFlag, size: 74)
                        Text("-")
                            .font(.custom("Nunito-Black", size: 36))
                            .foregroundColor(Color(hex: "#FFC93C"))
                        teamMark(team: away, flag: awayFlag, size: 74)
                    }
                } else if let winnerFlag {
                    Text(winnerFlag).font(.system(size: 84))
                } else {
                    CrestView(crest: result.winner.crest, size: 96)
                }
            }
            .padding(14)
            .background(Circle().fill(Color.white))
            .shadow(color: Color(hex: "#FFC93C").opacity(0.75), radius: 22, x: 0, y: 0)
            Text(isDrawWithoutPenalty ? "EMPATE" : result.winner.name.uppercased())
                .font(.custom("Nunito-Black", size: 34))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(result.homeGoals) - \(result.awayGoals)")
                .font(.custom("Nunito-Black", size: 48))
                .foregroundColor(.white)
                .monospacedDigit()
            if let finalPenaltyScore, shouldShowPenaltyShootout {
                Text("PENALES \(home.short.uppercased()) \(finalPenaltyScore.home) - \(finalPenaltyScore.away) \(away.short.uppercased())")
                    .font(.custom("Nunito-Black", size: 17))
                    .foregroundColor(Color(hex: "#FFC93C"))
                    .monospacedDigit()
            }
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
            .accessibilityIdentifier("match.close")
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

    private var finishedTitle: String {
        if shouldShowPenaltyShootout { return "GANÓ POR PENALES" }
        if isDrawWithoutPenalty { return "EMPATE FINAL" }
        return "FINAL DEL PARTIDO"
    }

    @ViewBuilder
    private func teamMark(team: Team, flag: String?, size: CGFloat) -> some View {
        if let flag {
            Text(flag).font(.system(size: size * 0.9))
        } else {
            CrestView(crest: team.crest, size: size)
        }
    }

    private func team(for side: MatchSide) -> Team {
        switch side {
        case .home: return home
        case .away: return away
        }
    }
}

private enum MatchSimulationStage {
    case match
    case penalties
    case finished
}

struct PenaltyShootout: Equatable {
    let shots: [PenaltyShot]

    func score(after visibleShots: Int) -> (home: Int, away: Int) {
        let visible = shots.prefix(max(0, min(visibleShots, shots.count)))
        let homeGoals = visible.filter { $0.side == .home && $0.outcome == .goal }.count
        let awayGoals = visible.filter { $0.side == .away && $0.outcome == .goal }.count
        return (homeGoals, awayGoals)
    }

    var finalWinnerSide: MatchSide? {
        let final = score(after: shots.count)
        if final.home > final.away { return .home }
        if final.away > final.home { return .away }
        return nil
    }
}

struct PenaltyShot: Equatable, Identifiable {
    let id = UUID()
    let side: MatchSide
    let outcome: PenaltyShotOutcome
    let target: CGPoint
    let keeperTarget: CGPoint
}

enum PenaltyShotOutcome: Equatable {
    case goal
    case save
}

enum PenaltyShootoutFactory {
    static func makeShootout(home: Team, away: Team, winner: Team) -> PenaltyShootout {
        var rng = SystemRandomNumberGenerator()
        return makeShootout(home: home, away: away, winner: winner, rng: &rng)
    }

    static func makeShootout<R: RandomNumberGenerator>(
        home: Team,
        away: Team,
        winner: Team,
        rng: inout R
    ) -> PenaltyShootout {
        let winnerSide: MatchSide = winner.id == home.id ? .home : .away
        let winnerGoals = Int.random(in: 4...5, using: &rng)
        let loserGoals = max(1, winnerGoals - Int.random(in: 1...2, using: &rng))
        let homeGoalTarget = winnerSide == .home ? winnerGoals : loserGoals
        let awayGoalTarget = winnerSide == .away ? winnerGoals : loserGoals
        let homeOutcomes = outcomes(goalCount: homeGoalTarget, rng: &rng)
        let awayOutcomes = outcomes(goalCount: awayGoalTarget, rng: &rng)
        var shots: [PenaltyShot] = []

        for round in 0..<5 {
            shots.append(makeShot(side: .home, outcome: homeOutcomes[round], round: round, rng: &rng))
            shots.append(makeShot(side: .away, outcome: awayOutcomes[round], round: round, rng: &rng))
        }

        return PenaltyShootout(shots: shots)
    }

    private static func outcomes<R: RandomNumberGenerator>(goalCount: Int, rng: inout R) -> [PenaltyShotOutcome] {
        let clampedGoals = max(0, min(5, goalCount))
        var outcomes = Array(repeating: PenaltyShotOutcome.goal, count: clampedGoals)
        outcomes += Array(repeating: PenaltyShotOutcome.save, count: 5 - clampedGoals)
        outcomes.shuffle(using: &rng)
        return outcomes
    }

    private static func makeShot<R: RandomNumberGenerator>(
        side: MatchSide,
        outcome: PenaltyShotOutcome,
        round: Int,
        rng: inout R
    ) -> PenaltyShot {
        let columns: [CGFloat] = [0.40, 0.50, 0.60]
        let heights: [CGFloat] = [0.22, 0.29, 0.36]
        let target = CGPoint(
            x: columns[Int.random(in: 0..<columns.count, using: &rng)],
            y: heights[(round + Int.random(in: 0..<heights.count, using: &rng)) % heights.count]
        )
        let wrongSideX: CGFloat = target.x < 0.5 ? 0.62 : 0.38
        let keeperTarget = outcome == .save
            ? CGPoint(x: target.x, y: min(0.39, max(0.23, target.y)))
            : CGPoint(x: wrongSideX, y: min(0.39, max(0.24, target.y + CGFloat.random(in: -0.03...0.03, using: &rng))))

        return PenaltyShot(side: side, outcome: outcome, target: target, keeperTarget: keeperTarget)
    }
}

private struct PenaltyShootoutView: View {
    let home: Team
    let away: Team
    let homeFlag: String?
    let awayFlag: String?
    let shootout: PenaltyShootout
    let elapsed: TimeInterval
    let duration: TimeInterval
    let reduceMotion: Bool

    private var shotDuration: TimeInterval {
        duration / Double(max(1, shootout.shots.count))
    }

    private var currentIndex: Int {
        min(max(0, shootout.shots.count - 1), Int(elapsed / shotDuration))
    }

    private var currentShot: PenaltyShot {
        shootout.shots[currentIndex]
    }

    private var localProgress: CGFloat {
        let shotStart = Double(currentIndex) * shotDuration
        return min(1, max(0, CGFloat((elapsed - shotStart) / shotDuration)))
    }

    private var visibleShotCount: Int {
        let completed = Int(elapsed / shotDuration)
        let includeCurrent = localProgress >= MatchPresentation.shotImpactProgress ? 1 : 0
        return min(shootout.shots.count, completed + includeCurrent)
    }

    private var visibleScore: (home: Int, away: Int) {
        shootout.score(after: visibleShotCount)
    }

    private var motionProgress: CGFloat {
        guard reduceMotion else { return localProgress }
        if localProgress < 0.44 { return 0 }
        if localProgress < 0.78 { return 0.62 }
        return 1
    }

    var body: some View {
        GeometryReader { geo in
            let shot = currentShot
            let ball = ballPoint(for: shot)
            let kicker = kickerPoint(for: shot.side)
            let keeper = keeperPoint(for: shot)
            let keeperTeam = team(for: shot.side == .home ? .away : .home)
            let kits = MatchKitStyle.pair(home: home, away: away)
            let kickerStyle = shot.side == .home ? kits.0 : kits.1
            let keeperStyle = jerseyStyle(for: keeperTeam, fallback: ("#263645", "#FFC93C"))

            ZStack {
                PenaltyStadiumBackdrop()

                PenaltyGoalView()
                    .frame(width: geo.size.width * 0.48, height: geo.size.height * 0.3)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.28)

                PenaltyKeeperView(style: keeperStyle, progress: motionProgress, outcome: shot.outcome)
                    .frame(width: 86, height: 72)
                    .rotationEffect(.degrees(keeperRotation(for: shot)))
                    .position(point(keeper, in: geo.size))
                    .animation(reduceMotion ? nil : .interactiveSpring(response: 0.22, dampingFraction: 0.72), value: localProgress)

                if !reduceMotion && motionProgress > 0.42 && motionProgress < 0.78 {
                    BallTrail(from: CGPoint(x: 0.5, y: 0.72), to: ball, isShot: true, isCross: false)
                        .stroke(Color(hex: "#FFC93C").opacity(0.86), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: geo.size.width, height: geo.size.height)
                }

                FootballView(isShot: true, spin: reduceMotion ? 0 : elapsed * 1.7)
                    .scaleEffect(ballScale)
                    .position(point(ball, in: geo.size))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.08), value: localProgress)

                PenaltyKickerView(
                    style: kickerStyle,
                    number: currentIndex + 1,
                    isKicking: motionProgress > 0.34 && motionProgress < 0.78
                )
                .frame(width: 92, height: 138)
                .scaleEffect(1 + min(0.12, motionProgress * 0.12))
                .rotationEffect(.degrees(shot.side == .home ? -3 : 3))
                .position(point(kicker, in: geo.size))
                .animation(reduceMotion ? nil : .interactiveSpring(response: 0.24, dampingFraction: 0.76), value: localProgress)

                if localProgress > 0.78 {
                    PenaltyOutcomeFlash(outcome: shot.outcome)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.51)
                        .transition(.scale.combined(with: .opacity))
                }

                VStack {
                    Spacer()
                    PenaltyShootoutStrip(
                        home: home,
                        away: away,
                        homeFlag: homeFlag,
                        awayFlag: awayFlag,
                        shots: shootout.shots,
                        visibleShotCount: visibleShotCount,
                        score: visibleScore
                    )
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
            )
        }
    }

    private var ballScale: CGFloat {
        if motionProgress < 0.46 { return 1 }
        if motionProgress < 0.78 { return 1.18 }
        return currentShot.outcome == .goal ? 0.82 : 1.05
    }

    private func ballPoint(for shot: PenaltyShot) -> CGPoint {
        let spot = CGPoint(x: 0.5, y: 0.72)
        if motionProgress < 0.44 { return spot }
        if motionProgress < 0.78 {
            let travel = smooth((motionProgress - 0.44) / 0.34)
            return interpolate(from: spot, to: shot.target, progress: travel)
        }
        if shot.outcome == .save {
            let deflection = CGPoint(x: shot.target.x + (shot.target.x < 0.5 ? -0.13 : 0.13), y: 0.45)
            return interpolate(from: shot.target, to: deflection, progress: smooth((motionProgress - 0.78) / 0.22))
        }
        let net = CGPoint(x: shot.target.x, y: max(0.18, shot.target.y - 0.05))
        return interpolate(from: shot.target, to: net, progress: smooth((motionProgress - 0.78) / 0.22))
    }

    private func kickerPoint(for side: MatchSide) -> CGPoint {
        let offset: CGFloat = side == .home ? -0.028 : 0.028
        if motionProgress < 0.42 {
            let run = smooth(motionProgress / 0.42)
            return interpolate(from: CGPoint(x: 0.5 + offset, y: 0.94), to: CGPoint(x: 0.5 + offset * 0.35, y: 0.76), progress: run)
        }
        return CGPoint(x: 0.5 + offset * 0.18, y: 0.76)
    }

    private func keeperPoint(for shot: PenaltyShot) -> CGPoint {
        let base = CGPoint(x: 0.5, y: 0.315)
        guard motionProgress > 0.44 else { return base }
        let dive = smooth((motionProgress - 0.44) / 0.34)
        return interpolate(from: base, to: shot.keeperTarget, progress: dive)
    }

    private func keeperRotation(for shot: PenaltyShot) -> Double {
        guard motionProgress > 0.44 else { return 0 }
        let direction = shot.keeperTarget.x < 0.5 ? -1.0 : 1.0
        return direction * (shot.outcome == .save ? 28 : 18)
    }

    private func team(for side: MatchSide) -> Team {
        side == .home ? home : away
    }

    private func jerseyStyle(for team: Team, fallback: (String, String)) -> JerseyStyle {
        let colors = team.home.colors
        let primary = colors.first ?? fallback.0
        let secondary = colors.dropFirst().first ?? fallback.1
        return JerseyStyle(primaryHex: primary, secondaryHex: secondary)
    }

    private func point(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    private func interpolate(from: CGPoint, to: CGPoint, progress: CGFloat) -> CGPoint {
        CGPoint(x: from.x + (to.x - from.x) * progress, y: from.y + (to.y - from.y) * progress)
    }

    private func smooth(_ value: CGFloat) -> CGFloat {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }
}

private struct PenaltyStadiumBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#111B24"), Color(hex: "#1D3421"), Color(hex: "#2B7A39")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                crowdTier(color: Color(hex: "#263645"), rows: 3)
                    .frame(height: 88)
                crowdTier(color: Color(hex: "#1C2833"), rows: 4)
                    .frame(height: 120)
                Spacer()
            }

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 130, height: 130)
                    .blur(radius: 32)
                    .offset(x: CGFloat(index - 2) * 170, y: -130)
            }

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#2F9A48"), Color(hex: "#1F7A36")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 290)
            }

            PenaltyBoxLines()
                .stroke(Color.white.opacity(0.78), lineWidth: 3)
                .padding(.top, 112)
                .padding(.horizontal, 150)
                .padding(.bottom, 42)
        }
    }

    private func crowdTier(color: Color, rows: Int) -> some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(color.opacity(0.92))
            )

            for index in 0..<(rows * 42) {
                let dotSize = CGFloat(4 + index % 4)
                let x = CGFloat((index * 29) % 1180)
                let y = CGFloat(16 + ((index / 42) * 22) + (index % 3) * 3)
                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: rect), with: .color(crowdColor(index)))
            }
        }
    }

    private func crowdColor(_ index: Int) -> Color {
        switch index % 4 {
        case 0:
            return Color.white.opacity(0.72)
        case 1:
            return Color(hex: "#FFC93C").opacity(0.7)
        case 2:
            return Color(hex: "#75AADB").opacity(0.65)
        default:
            return Color(hex: "#FF7B3D").opacity(0.64)
        }
    }
}

private struct PenaltyBoxLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let box = CGRect(x: rect.midX - rect.width * 0.28, y: rect.minY + rect.height * 0.22, width: rect.width * 0.56, height: rect.height * 0.56)
        path.addRect(box)
        path.addEllipse(in: CGRect(x: rect.midX - 5, y: rect.maxY - rect.height * 0.22, width: 10, height: 10))
        path.addArc(center: CGPoint(x: rect.midX, y: box.maxY), radius: rect.width * 0.11, startAngle: .degrees(205), endAngle: .degrees(335), clockwise: false)
        return path
    }
}

private struct PenaltyGoalView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white, lineWidth: 8)
                .background(Color.white.opacity(0.06))

            ForEach(1..<6, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 1.6)
                    .offset(x: CGFloat(index - 3) * 42)
            }

            ForEach(1..<4, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1.6)
                    .offset(y: CGFloat(index - 2) * 28)
            }

            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.black.opacity(0.24), lineWidth: 2)
                .offset(y: 7)
        }
        .shadow(color: Color.black.opacity(0.34), radius: 10, x: 0, y: 9)
    }
}

private struct PenaltyKeeperView: View {
    let style: JerseyStyle
    let progress: CGFloat
    let outcome: PenaltyShotOutcome

    var body: some View {
        ZStack {
            Capsule()
                .fill(style.secondary.opacity(0.95))
                .frame(width: 82, height: 12)
                .rotationEffect(.degrees(outcome == .save && progress > 0.48 ? -8 : 0))
                .offset(y: -8)
            RoundedRectangle(cornerRadius: 14)
                .fill(style.primary)
                .frame(width: 48, height: 50)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(style.border, lineWidth: 3))
            Circle()
                .fill(Color(hex: "#F2C39A"))
                .frame(width: 24, height: 24)
                .offset(y: -38)
            HStack(spacing: 16) {
                Capsule().fill(style.secondary).frame(width: 12, height: 34).rotationEffect(.degrees(18))
                Capsule().fill(style.secondary).frame(width: 12, height: 34).rotationEffect(.degrees(-18))
            }
            .offset(y: 35)
        }
        .shadow(color: Color.black.opacity(0.36), radius: 8, x: 0, y: 5)
    }
}

private struct PenaltyKickerView: View {
    let style: MatchKitStyle
    let number: Int
    let isKicking: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#DCA57C"))
                .frame(width: 30, height: 30)
                .offset(y: -56)
            Canvas { context, size in
                style.drawShirt(in: &context, rect: CGRect(origin: .zero, size: size))
            }
                .frame(width: 54, height: 66)
                .overlay(
                    Text("\(number)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(style.ink)
                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.9), lineWidth: 2))
            HStack(spacing: 18) {
                Capsule()
                    .fill(style.secondary)
                    .frame(width: 14, height: 50)
                    .rotationEffect(.degrees(isKicking ? -38 : 10))
                    .offset(y: 46)
                Capsule()
                    .fill(style.secondary)
                    .frame(width: 14, height: 50)
                    .rotationEffect(.degrees(isKicking ? 44 : -8))
                    .offset(y: 46)
            }
            Capsule()
                .fill(style.sleeveColor)
                .frame(width: 14, height: 44)
                .rotationEffect(.degrees(isKicking ? -42 : -18))
                .offset(x: -34, y: -18)
            Capsule()
                .fill(style.sleeveColor)
                .frame(width: 14, height: 44)
                .rotationEffect(.degrees(isKicking ? 38 : 18))
                .offset(x: 34, y: -18)
        }
        .shadow(color: Color.black.opacity(0.34), radius: 10, x: 0, y: 8)
    }
}

private struct PenaltyOutcomeFlash: View {
    let outcome: PenaltyShotOutcome

    var body: some View {
        Text(outcome == .goal ? "GOOOL" : "ATAJÓ")
            .font(.custom("Nunito-Black", size: 48))
            .foregroundColor(outcome == .goal ? Color(hex: "#FFC93C") : .white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.black.opacity(0.46)))
            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 7)
    }
}

private struct PenaltyShootoutStrip: View {
    let home: Team
    let away: Team
    let homeFlag: String?
    let awayFlag: String?
    let shots: [PenaltyShot]
    let visibleShotCount: Int
    let score: (home: Int, away: Int)

    var body: some View {
        VStack(spacing: 9) {
            row(side: .home, team: home, flag: homeFlag, goals: score.home)
            row(side: .away, team: away, flag: awayFlag, goals: score.away)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.38))
        .cornerRadius(22)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.14), lineWidth: 1))
    }

    private func row(side: MatchSide, team: Team, flag: String?, goals: Int) -> some View {
        HStack(spacing: 10) {
            if let flag {
                Text(flag).font(.system(size: 26))
            } else {
                CrestView(crest: team.crest, size: 30)
            }
            Text(team.short.uppercased())
                .font(.custom("Nunito-Black", size: 15))
                .foregroundColor(.white)
                .frame(width: 48, alignment: .leading)
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    penaltyDot(for: sideShots(side)[index], globalIndex: globalIndex(side: side, localIndex: index))
                }
            }
            Spacer()
            Text("\(goals)")
                .font(.custom("Nunito-Black", size: 24))
                .foregroundColor(Color(hex: "#FFC93C"))
                .monospacedDigit()
        }
    }

    private func penaltyDot(for shot: PenaltyShot, globalIndex: Int) -> some View {
        let isVisible = globalIndex < visibleShotCount
        return Circle()
            .fill(isVisible ? (shot.outcome == .goal ? Color(hex: "#7DDB8B") : Color(hex: "#FF7B6B")) : Color.white.opacity(0.18))
            .frame(width: 17, height: 17)
            .overlay(Circle().stroke(Color.white.opacity(isVisible ? 0.72 : 0.22), lineWidth: 1.5))
            .shadow(color: isVisible ? Color.black.opacity(0.28) : .clear, radius: 4, x: 0, y: 2)
    }

    private func sideShots(_ side: MatchSide) -> [PenaltyShot] {
        shots.filter { $0.side == side }
    }

    private func globalIndex(side: MatchSide, localIndex: Int) -> Int {
        localIndex * 2 + (side == .home ? 0 : 1)
    }
}

private struct BallTrail: Shape {
    let from: CGPoint
    let to: CGPoint
    let isShot: Bool
    let isCross: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: from.x * rect.width, y: from.y * rect.height)
        let end = CGPoint(x: to.x * rect.width, y: to.y * rect.height)
        let control: CGPoint
        if isCross {
            control = CGPoint(
                x: start.x >= end.x ? min(rect.width * 0.96, max(start.x, end.x) + 34) : max(rect.width * 0.04, min(start.x, end.x) - 34),
                y: (start.y + end.y) / 2
            )
        } else {
            control = CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - (isShot ? 34 : 16))
        }
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


extension Team {
    var matchQualityScore: Double {
        TeamQuality.score(for: self)
    }
}

private enum TeamQuality {
    static func score(for team: Team) -> Double {
        teamScores[normalizedId(team.id)] ?? teamScores[team.short.lowercased()] ?? 72
    }

    private static func normalizedId(_ id: String) -> String {
        if id.hasPrefix("sel_") {
            return String(id.dropFirst(4))
        }
        return id
    }

    /// Offline quality tiers for the World Cup simulator. They are FIFA-ranking inspired,
    /// but intentionally local so match simulation keeps working without network access.
    private static let teamScores: [String: Double] = [
        "argentina": 96,
        "france": 95,
        "spain": 94,
        "brazil": 93,
        "portugal": 93,
        "england": 92,
        "germany": 90,
        "netherlands": 90,
        "belgium": 86,
        "croatia": 86,
        "uruguay": 86,
        "morocco": 84,
        "colombia": 84,
        "japan": 82,
        "switzerland": 82,
        "austria": 82,
        "senegal": 81,
        "mexico": 80,
        "turkiye": 80,
        "sweden": 80,
        "usa": 78,
        "ecuador": 78,
        "norway": 78,
        "south_korea": 76,
        "paraguay": 76,
        "algeria": 76,
        "czechia": 75,
        "ivory_coast": 75,
        "egypt": 75,
        "iran": 75,
        "scotland": 74,
        "ghana": 74,
        "canada": 73,
        "australia": 73,
        "tunisia": 70,
        "saudi_arabia": 70,
        "bosnia": 69,
        "dr_congo": 68,
        "south_africa": 67,
        "qatar": 66,
        "cape_verde": 66,
        "uzbekistan": 65,
        "jordan": 63,
        "iraq": 62,
        "panama": 62,
        "new_zealand": 58,
        "curacao": 55,
        "haiti": 54,
        "italy": 86
    ]
}

enum MatchSimulationFactory {
    static func makeResult(home: Team, away: Team) -> MatchSimulationResult {
        var rng = SystemRandomNumberGenerator()
        return makeResult(home: home, away: away, rng: &rng)
    }

    static func makeResult<R: RandomNumberGenerator>(home: Team, away: Team, rng: inout R) -> MatchSimulationResult {
        let profile = MatchupProfile(homeScore: home.matchQualityScore, awayScore: away.matchQualityScore)
        let outcome = pickOutcome(profile: profile, rng: &rng)
        let score = makeScore(outcome: outcome, profile: profile, rng: &rng)
        let homeGoals = score.0
        let awayGoals = score.1
        let decidedByPenalties = homeGoals == awayGoals
        let winner: Team
        if homeGoals > awayGoals {
            winner = home
        } else if awayGoals > homeGoals {
            winner = away
        } else {
            winner = Double.random(in: 0..<1, using: &rng) < profile.homePenaltyProbability ? home : away
        }

        var events: [MatchGoalEvent] = []
        let totalGoals = homeGoals + awayGoals
        if totalGoals > 0 {
            let minutes = uniqueGoalMinutes(count: totalGoals, rng: &rng)
            var sides: [MatchSide] = Array(repeating: .home, count: homeGoals) + Array(repeating: .away, count: awayGoals)
            sides.shuffle(using: &rng)
            events = zip(minutes, sides).map { MatchGoalEvent(minute: $0.0, side: $0.1) }.sorted { $0.minute < $1.minute }
        }
        let chances = makeChances(goalEvents: events, homeChanceProbability: profile.homeChanceProbability, rng: &rng)

        return MatchSimulationResult(
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            winner: winner,
            decidedByPenalties: decidedByPenalties,
            goalEvents: events,
            chanceEvents: chances
        )
    }

    private static func pickOutcome<R: RandomNumberGenerator>(profile: MatchupProfile, rng: inout R) -> MatchOutcome {
        let roll = Double.random(in: 0..<1, using: &rng)
        if roll < profile.homeWinProbability { return .homeWin }
        if roll < profile.homeWinProbability + profile.drawProbability { return .draw }
        return .awayWin
    }

    private static func makeScore<R: RandomNumberGenerator>(
        outcome: MatchOutcome,
        profile: MatchupProfile,
        rng: inout R
    ) -> (Int, Int) {
        switch outcome {
        case .homeWin:
            return winningScore(winnerEdge: profile.homeScore - profile.awayScore, rng: &rng)
        case .awayWin:
            let score = winningScore(winnerEdge: profile.awayScore - profile.homeScore, rng: &rng)
            return (score.1, score.0)
        case .draw:
            let goals = drawGoals(rng: &rng)
            return (goals, goals)
        }
    }

    private static func winningScore<R: RandomNumberGenerator>(winnerEdge: Double, rng: inout R) -> (Int, Int) {
        let close = [(1, 0), (2, 1), (3, 2)]
        let controlled = [(2, 0), (3, 1), (3, 0)]
        let rare = [(4, 0), (4, 1), (5, 2)]
        let roll = Int.random(in: 0..<100, using: &rng)

        if winnerEdge < -10 {
            if roll < 86 { return random(close, rng: &rng) }
            if roll < 99 { return random(controlled, rng: &rng) }
            return random(rare, rng: &rng)
        }
        if winnerEdge > 24 {
            if roll < 42 { return random(close, rng: &rng) }
            if roll < 90 { return random(controlled, rng: &rng) }
            return random(rare, rng: &rng)
        }
        if winnerEdge > 10 {
            if roll < 58 { return random(close, rng: &rng) }
            if roll < 95 { return random(controlled, rng: &rng) }
            return random(rare, rng: &rng)
        }
        if roll < 72 { return random(close, rng: &rng) }
        if roll < 97 { return random(controlled, rng: &rng) }
        return random(rare, rng: &rng)
    }

    private static func drawGoals<R: RandomNumberGenerator>(rng: inout R) -> Int {
        let roll = Int.random(in: 0..<100, using: &rng)
        if roll < 22 { return 0 }
        if roll < 88 { return 1 }
        return 2
    }

    private static func random<R: RandomNumberGenerator>(_ scores: [(Int, Int)], rng: inout R) -> (Int, Int) {
        scores.randomElement(using: &rng) ?? (1, 0)
    }

    private static func uniqueGoalMinutes<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Int] {
        guard count > 0 else { return [] }
        var minutes: Set<Int> = []
        while minutes.count < count {
            minutes.insert(Int.random(in: 8...86, using: &rng))
        }
        return Array(minutes).sorted()
    }

    private static func makeChances<R: RandomNumberGenerator>(
        goalEvents: [MatchGoalEvent],
        homeChanceProbability: Double,
        rng: inout R
    ) -> [MatchChanceEvent] {
        var chances = goalEvents.map {
            MatchChanceEvent(minute: $0.minute, side: $0.side, outcome: .goal)
        }
        let extraCount = Int.random(in: 4...6, using: &rng)
        var used = Set(goalEvents.map(\.minute))
        var attempts = 0
        while chances.count < goalEvents.count + extraCount && attempts < 160 {
            attempts += 1
            let minute = Int.random(in: 6...88, using: &rng)
            guard !used.contains(where: { abs($0 - minute) < 5 }) else { continue }
            used.insert(minute)
            let side: MatchSide = Double.random(in: 0..<1, using: &rng) < homeChanceProbability ? .home : .away
            let outcome: MatchChanceOutcome = Int.random(in: 0..<100, using: &rng) < 68 ? .save : .wide
            chances.append(MatchChanceEvent(minute: minute, side: side, outcome: outcome))
        }
        return chances.sorted { $0.minute < $1.minute }
    }
}

private struct MatchupProfile {
    let homeScore: Double
    let awayScore: Double

    var drawProbability: Double {
        let gap = min(abs(homeScore - awayScore), 40)
        return clamp(0.27 - (gap / 40 * 0.12), min: 0.13, max: 0.27)
    }

    var homeWinProbability: Double {
        (1 - drawProbability) * homeNonDrawShare
    }

    var homePenaltyProbability: Double {
        clamp(0.5 + ((homeScore - awayScore) / 100), min: 0.38, max: 0.62)
    }

    var homeChanceProbability: Double {
        clamp(0.5 + ((homeScore - awayScore) / 120), min: 0.32, max: 0.68)
    }

    private var homeNonDrawShare: Double {
        clamp(1 / (1 + exp(-(homeScore - awayScore) / 12)), min: 0.18, max: 0.82)
    }

    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}

private enum MatchOutcome {
    case homeWin
    case awayWin
    case draw
}

enum MatchSide: Equatable, Hashable {
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

struct MatchSimulationResult: Equatable {
    let homeGoals: Int
    let awayGoals: Int
    let winner: Team
    let decidedByPenalties: Bool
    let goalEvents: [MatchGoalEvent]
    let chanceEvents: [MatchChanceEvent]
}

struct MatchGoalEvent: Equatable, Identifiable {
    let minute: Int
    let side: MatchSide

    var id: String {
        "goal-\(minute)-\(side == .home ? "home" : "away")"
    }
}

struct MatchChanceEvent: Equatable, Identifiable {
    let minute: Int
    let side: MatchSide
    let outcome: MatchChanceOutcome

    var id: String {
        "chance-\(minute)-\(side == .home ? "home" : "away")-\(outcome.idComponent)"
    }
}

enum MatchChanceOutcome: Equatable {
    case goal
    case save
    case wide

    fileprivate var idComponent: String {
        switch self {
        case .goal: return "goal"
        case .save: return "save"
        case .wide: return "wide"
        }
    }
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

    mutating func advance(round: TournamentRound, matchIndex: Int, slot: MatchSide) {
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

    private func selectedTeam(in match: TournamentMatch, slot: MatchSide) -> Team? {
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

// MARK: - World Cup tournament (groups + knockouts) inside SIMULAR TORNEO

private struct WorldCupSimContext: Identifiable {
    let id = UUID()
    let matchId: String
    let homeFixtureId: String
    let awayFixtureId: String
    let homeTeam: Team
    let awayTeam: Team
    let homeFlag: String
    let awayFlag: String
    let isKnockout: Bool
}

private enum WCCover: Identifiable {
    case sim(WorldCupSimContext)
    case champion(team: Team, flag: String)

    var id: String {
        switch self {
        case .sim(let context): return "sim_\(context.id)"
        case .champion(let team, _): return "champion_\(team.id)"
        }
    }
}

private enum WCSection: String, CaseIterable {
    case groups = "ZONAS"
    case knockout = "LLAVES"
}

private struct WorldCupTournamentBoard: View {
    let mode: TournamentPlayMode
    let size: CGSize
    let tournament: WorldCup2026Fixture
    let scores: [String: FixtureScore]
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    @State private var section: WCSection = .groups

    private var crestSize: CGFloat {
        min(max(size.width * 0.026, 26), 38)
    }

    private var groupColumns: [GridItem] {
        let count = size.width >= 1180 ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        VStack(spacing: 14) {
            WCSectionToggle(section: $section)

            ScrollView {
                if section == .groups {
                    LazyVGrid(columns: groupColumns, spacing: 14) {
                        ForEach(tournament.groups) { group in
                            WCGroupCard(
                                group: group,
                                standings: tournament.standings(for: group, scores: scores),
                                scores: scores,
                                mode: mode,
                                crestSize: crestSize,
                                onPlay: onPlay,
                                onManualPick: onManualPick
                            )
                        }
                    }
                    .padding(.vertical, 6)
                } else {
                    knockoutView
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var knockoutView: some View {
        let bracket = tournament.knockoutBracket(scores: scores)
        let champion = tournament.champion(scores: scores)
        return VStack(spacing: 18) {
            if let message = bracket.message {
                Text(message)
                    .font(.custom("Nunito-Black", size: 15))
                    .foregroundColor(Color(hex: "#FFC93C"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
            }

            ScrollView(.horizontal, showsIndicators: true) {
                WCBracketBoardView(
                    bracket: bracket,
                    scores: scores,
                    mode: mode,
                    crestSize: crestSize,
                    champion: champion,
                    minWidth: max(size.width - 64, 1620),
                    onPlay: onPlay,
                    onManualPick: onManualPick
                )
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct WCBracketBoardView: View {
    let bracket: KnockoutBracket
    let scores: [String: FixtureScore]
    let mode: TournamentPlayMode
    let crestSize: CGFloat
    let champion: FixtureTeam?
    let minWidth: CGFloat
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    private let leftRoundOf32 = [74, 77, 73, 75, 83, 84, 81, 82]
    private let leftRoundOf16 = [89, 90, 93, 94]
    private let leftQuarters = [97, 98]
    private let leftSemi = [101]

    private let rightSemi = [102]
    private let rightQuarters = [99, 100]
    private let rightRoundOf16 = [91, 92, 95, 96]
    private let rightRoundOf32 = [76, 78, 79, 80, 86, 88, 85, 87]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#08111B"), Color(hex: "#101B26"), Color(hex: "#071018")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "#C8A95A").opacity(0.22), lineWidth: 1.4)
                )

            HStack(alignment: .center, spacing: 16) {
                WCBracketWingView(
                    side: .left,
                    columns: [
                        column("16AVOS", leftRoundOf32),
                        column("OCTAVOS", leftRoundOf16),
                        column("CUARTOS", leftQuarters),
                        column("SEMIFINAL", leftSemi)
                    ],
                    scores: scores,
                    mode: mode,
                    crestSize: crestSize,
                    onPlay: onPlay,
                    onManualPick: onManualPick
                )

                WCFinalConnectorLine(side: .left)
                    .frame(width: 38, height: 620)

                WCBracketCenterView(
                    finalMatch: match(number: 104),
                    score: score(number: 104),
                    champion: champion,
                    mode: mode,
                    crestSize: crestSize,
                    onPlay: onPlay,
                    onManualPick: onManualPick
                )

                WCFinalConnectorLine(side: .right)
                    .frame(width: 38, height: 620)

                WCBracketWingView(
                    side: .right,
                    columns: [
                        column("SEMIFINAL", rightSemi),
                        column("CUARTOS", rightQuarters),
                        column("OCTAVOS", rightRoundOf16),
                        column("16AVOS", rightRoundOf32)
                    ],
                    scores: scores,
                    mode: mode,
                    crestSize: crestSize,
                    onPlay: onPlay,
                    onManualPick: onManualPick
                )
            }
            .padding(22)
        }
        .frame(minWidth: minWidth, minHeight: 780)
    }

    private func column(_ title: String, _ numbers: [Int]) -> WCBracketColumnModel {
        WCBracketColumnModel(title: title, matches: numbers.compactMap(match(number:)))
    }

    private func match(number: Int) -> KnockoutFixtureMatch? {
        bracket.rounds.flatMap(\.matches).first { $0.number == number }
    }

    private func score(number: Int) -> FixtureScore? {
        scores["wc26_m\(number)"]
    }
}

private enum WCBracketSide {
    case left
    case right
}

private struct WCBracketColumnModel: Identifiable {
    let title: String
    let matches: [KnockoutFixtureMatch]
    var id: String { "\(title)-\(matches.map(\.number))" }
}

private struct WCBracketWingView: View {
    let side: WCBracketSide
    let columns: [WCBracketColumnModel]
    let scores: [String: FixtureScore]
    let mode: TournamentPlayMode
    let crestSize: CGFloat
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ForEach(Array(columns.enumerated()), id: \.element.id) { index, column in
                WCBracketRoundColumn(
                    column: column,
                    scores: scores,
                    mode: mode,
                    crestSize: crestSize,
                    onPlay: onPlay,
                    onManualPick: onManualPick
                )

                if index < columns.count - 1 {
                    let nextCount = columns[index + 1].matches.count
                    WCBracketConnectorColumn(side: side, groups: max(nextCount, 1))
                        .frame(width: 34, height: 650)
                }
            }
        }
    }
}

private struct WCBracketRoundColumn: View {
    let column: WCBracketColumnModel
    let scores: [String: FixtureScore]
    let mode: TournamentPlayMode
    let crestSize: CGFloat
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    private var cardWidth: CGFloat {
        switch column.matches.count {
        case 0...1: return 210
        case 2: return 198
        case 3...4: return 188
        default: return 178
        }
    }

    private var cardHeight: CGFloat {
        switch column.matches.count {
        case 0...1: return 128
        case 2: return 108
        case 3...4: return 92
        default: return 74
        }
    }

    private var cardSpacing: CGFloat {
        switch column.matches.count {
        case 0...1: return 0
        case 2: return 176
        case 3...4: return 58
        default: return 10
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(column.title)
                .font(.custom("Nunito-Black", size: 13))
                .foregroundColor(Color(hex: "#D8BF72"))
                .tracking(1.6)

            VStack(spacing: cardSpacing) {
                ForEach(column.matches) { match in
                    WCBracketMatchCard(
                        match: match,
                        score: scores[match.id],
                        mode: mode,
                        crestSize: crestSize,
                        compact: column.matches.count > 4,
                        onPlay: onPlay,
                        onManualPick: onManualPick
                    )
                    .frame(width: cardWidth, height: cardHeight)
                }
            }
            .frame(height: 660)
        }
    }
}

private struct WCBracketConnectorColumn: View {
    let side: WCBracketSide
    let groups: Int

    var body: some View {
        Canvas { context, size in
            let inputCount = max(groups * 2, 2)
            let stroke = StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            let color = Color(hex: "#C8A95A").opacity(0.7)

            for index in 0..<groups {
                let yTop = CGFloat(index * 2 + 1) / CGFloat(inputCount + 1) * size.height
                let yBottom = CGFloat(index * 2 + 2) / CGFloat(inputCount + 1) * size.height
                let yMid = (yTop + yBottom) / 2
                let branchX = side == .left ? size.width * 0.58 : size.width * 0.42
                let startX = side == .left ? 0 : size.width
                let endX = side == .left ? size.width : 0

                var path = Path()
                path.move(to: CGPoint(x: startX, y: yTop))
                path.addLine(to: CGPoint(x: branchX, y: yTop))
                path.addLine(to: CGPoint(x: branchX, y: yBottom))
                path.move(to: CGPoint(x: branchX, y: yMid))
                path.addLine(to: CGPoint(x: endX, y: yMid))
                context.stroke(path, with: .color(color), style: stroke)

                let flare = CGRect(x: branchX - 2, y: yMid - 16, width: 4, height: 32)
                context.fill(Path(ellipseIn: flare), with: .color(Color(hex: "#FFC93C").opacity(0.62)))
            }
        }
    }
}

private struct WCFinalConnectorLine: View {
    let side: WCBracketSide

    var body: some View {
        Canvas { context, size in
            let y = size.height * 0.5
            var path = Path()
            path.move(to: CGPoint(x: side == .left ? 0 : size.width, y: y))
            path.addLine(to: CGPoint(x: side == .left ? size.width : 0, y: y))
            context.stroke(
                path,
                with: .color(Color(hex: "#C8A95A").opacity(0.82)),
                style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
            )

            let centerX = side == .left ? size.width - 4 : 4
            context.fill(
                Path(ellipseIn: CGRect(x: centerX - 3, y: y - 34, width: 6, height: 68)),
                with: .color(Color(hex: "#FFC93C").opacity(0.58))
            )
        }
    }
}

private struct WCBracketCenterView: View {
    let finalMatch: KnockoutFixtureMatch?
    let score: FixtureScore?
    let champion: FixtureTeam?
    let mode: TournamentPlayMode
    let crestSize: CGFloat
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            Text(champion == nil ? "CAMINO AL CAMPEÓN" : "GRAN CAMPEÓN")
                .font(.custom("Nunito-Black", size: 15))
                .foregroundColor(Color(hex: "#F3D582"))
                .tracking(2)
                .padding(.horizontal, 20)
                .frame(height: 36)
                .background(Capsule().fill(Color(hex: "#F3D582").opacity(0.1)))
                .overlay(Capsule().stroke(Color(hex: "#F3D582").opacity(0.42), lineWidth: 1.4))

            ZStack {
                Circle()
                    .fill(Color(hex: "#FFC93C").opacity(pulse ? 0.22 : 0.09))
                    .frame(width: 268, height: 268)
                    .blur(radius: 26)
                Image("WorldCupTrophy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 188, height: 280)
                    .shadow(color: Color(hex: "#FFC93C").opacity(pulse ? 0.82 : 0.42), radius: pulse ? 30 : 14, x: 0, y: 10)
                    .scaleEffect(pulse ? 1.03 : 0.98)
            }
            .frame(width: 300, height: 300)

            if let champion {
                VStack(spacing: 6) {
                    Text(champion.flag)
                        .font(.system(size: 48))
                    Text(champion.name.uppercased())
                        .font(.custom("Nunito-Black", size: 20))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.56)
                    Text("LEVANTA LA COPA")
                        .font(.custom("Nunito-Black", size: 11))
                        .foregroundColor(Color(hex: "#F3D582"))
                        .tracking(1.3)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(width: 280)
                .background(Color.white.opacity(0.08))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "#F3D582").opacity(0.5), lineWidth: 1.5))
            }

            Text("FINAL")
                .font(.custom("Nunito-Black", size: 18))
                .foregroundColor(Color(hex: "#F3D582"))
                .tracking(2.5)

            if let finalMatch {
                WCBracketMatchCard(
                    match: finalMatch,
                    score: score,
                    mode: mode,
                    crestSize: crestSize + 2,
                    compact: false,
                    onPlay: onPlay,
                    onManualPick: onManualPick
                )
                .frame(width: 286, height: 132)
            }
        }
        .frame(width: 330, height: 700)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct WCBracketMatchCard: View {
    let match: KnockoutFixtureMatch
    let score: FixtureScore?
    let mode: TournamentPlayMode
    let crestSize: CGFloat
    let compact: Bool
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    private var ready: Bool { match.home != nil && match.away != nil }
    private var played: Bool { score?.isComplete == true }

    private var winnerSide: MatchSide? {
        guard let score, let homeGoals = score.home, let awayGoals = score.away else { return nil }
        if homeGoals > awayGoals { return .home }
        if awayGoals > homeGoals { return .away }
        if let penalty = score.penaltyWinnerId {
            if penalty == match.home?.id { return .home }
            if penalty == match.away?.id { return .away }
        }
        return nil
    }

    var body: some View {
        if mode == .simulated {
            Button {
                guard ready, !played, let context = makeContext() else { return }
                SoundManager.shared.playTap()
                onPlay(context)
            } label: {
                cardContent(allowsManualPick: false)
            }
            .buttonStyle(.plain)
            .disabled(!ready || played)
        } else {
            cardContent(allowsManualPick: true)
        }
    }

    private func cardContent(allowsManualPick: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack(spacing: 6) {
                Text(played ? "RESUELTO" : ready ? "PRÓXIMO" : "A DEFINIR")
                    .font(.custom("Nunito-Black", size: compact ? 8 : 10))
                    .foregroundColor(played ? Color(hex: "#7DDB8B") : ready ? Color(hex: "#6BCBFF") : .white.opacity(0.45))
                    .padding(.horizontal, compact ? 7 : 9)
                    .frame(height: compact ? 18 : 22)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                Spacer(minLength: 0)
                Text("M\(match.number)")
                    .font(.custom("Nunito-Black", size: compact ? 8 : 10))
                    .foregroundColor(Color(hex: "#D8BF72").opacity(0.82))
            }

            VStack(spacing: compact ? 3 : 5) {
                teamLine(match.home, side: .home, goals: score?.home, winner: winnerSide == .home, allowsManualPick: allowsManualPick)
                teamLine(match.away, side: .away, goals: score?.away, winner: winnerSide == .away, allowsManualPick: allowsManualPick)
            }

            if !compact {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                Text("\(match.schedule.argentinaText) · \(match.venue)")
                    .font(.custom("Nunito-Bold", size: 10))
                    .foregroundColor(.white.opacity(0.48))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 7 : 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardBackground)
        .cornerRadius(compact ? 16 : 18)
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 16 : 18)
                .stroke(cardBorder, lineWidth: played ? 1.7 : 1.2)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 7)
    }

    @ViewBuilder
    private func teamLine(_ team: FixtureTeam?, side: MatchSide, goals: Int?, winner: Bool, allowsManualPick: Bool) -> some View {
        if allowsManualPick {
            Button {
                guard ready else { return }
                SoundManager.shared.playTap()
                onManualPick(match.id, side)
            } label: {
                teamLineContent(team, goals: goals, winner: winner)
            }
            .buttonStyle(.plain)
            .disabled(!ready)
        } else {
            teamLineContent(team, goals: goals, winner: winner)
        }
    }

    private func teamLineContent(_ team: FixtureTeam?, goals: Int?, winner: Bool) -> some View {
        HStack(spacing: compact ? 5 : 7) {
            if let team {
                WCFlag(flag: team.flag, size: compact ? crestSize * 0.58 : crestSize * 0.7)
                Text(team.short)
                    .font(.custom("Nunito-Black", size: compact ? 10 : 12))
                    .foregroundColor(winner ? Color(hex: "#7DDB8B") : .white.opacity(ready ? 0.9 : 0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                    .frame(width: compact ? 23 : 30, height: compact ? 18 : 22)
                Text(placeholderText)
                    .font(.custom("Nunito-Bold", size: compact ? 9 : 11))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            Spacer(minLength: 0)
            if let goals {
                HStack(spacing: 3) {
                    Text("\(goals)")
                    if score?.isTied == true && winner {
                        Text("P")
                            .font(.custom("Nunito-Black", size: compact ? 8 : 9))
                            .foregroundColor(Color(hex: "#FFC93C"))
                    }
                }
                .font(.custom("Nunito-Black", size: compact ? 13 : 16))
                .foregroundColor(.white)
                .monospacedDigit()
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .frame(height: compact ? 22 : 30)
        .background(winner ? Color(hex: "#7DDB8B").opacity(0.18) : Color.white.opacity(0.055))
        .cornerRadius(compact ? 8 : 10)
    }

    private var placeholderText: String {
        match.placeholder.replacingOccurrences(of: "Ganador ", with: "G. ")
    }

    private var cardBackground: some ShapeStyle {
        if played {
            return AnyShapeStyle(Color(hex: "#123021").opacity(0.9))
        }
        if ready {
            return AnyShapeStyle(Color(hex: "#131B28").opacity(0.96))
        }
        return AnyShapeStyle(Color(hex: "#121821").opacity(0.68))
    }

    private var cardBorder: Color {
        if played { return Color(hex: "#7DDB8B").opacity(0.54) }
        if ready { return Color(hex: "#6BCBFF").opacity(0.36) }
        return Color.white.opacity(0.12)
    }

    private func makeContext() -> WorldCupSimContext? {
        guard let home = match.home, let away = match.away else { return nil }
        return WorldCupSimContext(
            matchId: match.id,
            homeFixtureId: home.id,
            awayFixtureId: away.id,
            homeTeam: worldCupTeam(for: home),
            awayTeam: worldCupTeam(for: away),
            homeFlag: home.flag,
            awayFlag: away.flag,
            isKnockout: true
        )
    }
}

private struct WCSectionToggle: View {
    @Binding var section: WCSection

    var body: some View {
        HStack(spacing: 4) {
            ForEach(WCSection.allCases, id: \.self) { value in
                Button {
                    SoundManager.shared.playTap()
                    section = value
                } label: {
                    Text(value.rawValue)
                        .font(.custom("Nunito-Black", size: 15))
                        .foregroundColor(section == value ? Color(hex: "#263645") : .white.opacity(0.72))
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(section == value ? Color.white : Color.clear)
                        .cornerRadius(13)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 1))
    }
}

private struct WCGroupCard: View {
    let group: FixtureGroup
    let standings: [FixtureStanding]
    let scores: [String: FixtureScore]
    let mode: TournamentPlayMode
    let crestSize: CGFloat
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ZONA \(group.letter)")
                    .font(.custom("Nunito-Black", size: 17))
                    .foregroundColor(.white)
                Spacer()
                Text("\(standings.filter { $0.played == 3 }.count)/4")
                    .font(.custom("Nunito-Black", size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            VStack(spacing: 4) {
                ForEach(Array(standings.enumerated()), id: \.element.team.id) { index, standing in
                    WCStandingRow(index: index, standing: standing, crestSize: crestSize * 0.78)
                }
            }

            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)

            VStack(spacing: 6) {
                ForEach(group.matches) { match in
                    WCMatchCell(
                        matchId: match.id,
                        home: match.home,
                        away: match.away,
                        score: scores[match.id],
                        isKnockout: false,
                        mode: mode,
                        crestSize: crestSize,
                        onPlay: onPlay,
                        onManualPick: onManualPick
                    )
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

private struct WCFlag: View {
    let flag: String
    let size: CGFloat

    var body: some View {
        Text(flag)
            .font(.system(size: size))
            .frame(width: size * 1.18, height: size, alignment: .center)
    }
}

private struct WCStandingRow: View {
    let index: Int
    let standing: FixtureStanding
    let crestSize: CGFloat

    private var posColor: Color {
        index < 2 ? Color(hex: "#7DDB8B") : index == 2 ? Color(hex: "#FFC93C") : .white.opacity(0.4)
    }

    var body: some View {
        HStack(spacing: 7) {
            Text("\(index + 1)")
                .font(.custom("Nunito-Black", size: 11))
                .foregroundColor(posColor)
                .frame(width: 13)
            WCFlag(flag: standing.team.flag, size: crestSize)
            Text(standing.team.short)
                .font(.custom("Nunito-Black", size: 11))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(standing.goalDifferenceText)
                .font(.custom("Nunito-Bold", size: 10))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 26, alignment: .trailing)
            Text("\(standing.points)")
                .font(.custom("Nunito-Black", size: 12))
                .foregroundColor(.white)
                .frame(width: 20, alignment: .trailing)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(index < 2 ? Color(hex: "#7DDB8B").opacity(0.12) : Color.clear)
        )
    }
}

private struct WCMatchCell: View {
    let matchId: String
    let home: FixtureTeam?
    let away: FixtureTeam?
    let score: FixtureScore?
    let isKnockout: Bool
    let mode: TournamentPlayMode
    let crestSize: CGFloat
    let onPlay: (WorldCupSimContext) -> Void
    let onManualPick: (String, MatchSide) -> Void

    private var ready: Bool { home != nil && away != nil }
    private var played: Bool { score?.isComplete == true }

    private var winnerSide: MatchSide? {
        guard let score, let homeGoals = score.home, let awayGoals = score.away else { return nil }
        if homeGoals > awayGoals { return .home }
        if awayGoals > homeGoals { return .away }
        if let penalty = score.penaltyWinnerId {
            if penalty == home?.id { return .home }
            if penalty == away?.id { return .away }
        }
        return nil
    }

    var body: some View {
        if mode == .simulated {
            simulatedCell
        } else {
            manualCell
        }
    }

    private var simulatedCell: some View {
        Button {
            guard ready, !played, let context = makeContext() else { return }
            onPlay(context)
        } label: {
            HStack(spacing: 5) {
                teamRow(home, goals: score?.home, winner: winnerSide == .home)
                Text(played ? "-" : "VS")
                    .font(.custom("Nunito-Black", size: 10))
                    .foregroundColor(.white.opacity(0.45))
                teamRow(away, goals: score?.away, winner: winnerSide == .away)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity)
            .background(cellBackground)
            .cornerRadius(11)
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(cellBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!ready || played)
    }

    private var manualCell: some View {
        HStack(spacing: 5) {
            manualChip(home, side: .home, winner: winnerSide == .home)
            Text("-")
                .font(.custom("Nunito-Black", size: 10))
                .foregroundColor(.white.opacity(0.4))
            manualChip(away, side: .away, winner: winnerSide == .away)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 7)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(11)
    }

    private func manualChip(_ team: FixtureTeam?, side: MatchSide, winner: Bool) -> some View {
        Button {
            guard ready else { return }
            onManualPick(matchId, side)
        } label: {
            HStack(spacing: 5) {
                if let team {
                    WCFlag(flag: team.flag, size: crestSize * 0.74)
                    Text(team.short)
                        .font(.custom("Nunito-Black", size: 10))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                } else {
                    Text("POR DEFINIR")
                        .font(.custom("Nunito-Bold", size: 9))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(winner ? Color(hex: "#7DDB8B").opacity(0.24) : Color.white.opacity(0.08))
            .cornerRadius(9)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(winner ? Color(hex: "#7DDB8B") : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!ready)
    }

    private func teamRow(_ team: FixtureTeam?, goals: Int?, winner: Bool) -> some View {
        HStack(spacing: 4) {
            if let team {
                WCFlag(flag: team.flag, size: crestSize * 0.74)
                Text(team.short)
                    .font(.custom("Nunito-Black", size: 9))
                    .foregroundColor(winner ? Color(hex: "#7DDB8B") : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let goals {
                    Text("\(goals)")
                        .font(.custom("Nunito-Black", size: 12))
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: crestSize * 0.66, height: crestSize * 0.66)
                Text("?")
                    .font(.custom("Nunito-Black", size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer(minLength: 0)
        }
    }

    private var cellBackground: Color {
        if played { return Color(hex: "#2B5840").opacity(0.5) }
        if ready { return Color.white.opacity(0.1) }
        return Color.white.opacity(0.04)
    }

    private var cellBorder: Color {
        if played { return Color(hex: "#7DDB8B").opacity(0.4) }
        return Color.white.opacity(ready ? 0.14 : 0.06)
    }

    private func makeContext() -> WorldCupSimContext? {
        guard let home, let away else { return nil }
        return WorldCupSimContext(
            matchId: matchId,
            homeFixtureId: home.id,
            awayFixtureId: away.id,
            homeTeam: worldCupTeam(for: home),
            awayTeam: worldCupTeam(for: away),
            homeFlag: home.flag,
            awayFlag: away.flag,
            isKnockout: isKnockout
        )
    }
}

private struct WCChampionCover: View {
    let champion: Team
    let flag: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1C2833"), Color(hex: "#0E1620")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ChampionGloryOverlay(champion: champion, flag: flag, useWorldCupTrophy: true)

            VStack {
                Spacer()
                Button {
                    SoundManager.shared.playTap()
                    onClose()
                } label: {
                    Text("CERRAR")
                        .font(.custom("Nunito-Black", size: 20))
                        .foregroundColor(Color(hex: "#263645"))
                        .padding(.horizontal, 44)
                        .frame(height: 58)
                        .background(Color(hex: "#FFC93C"))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 44)
            }
        }
    }
}

/// Uses the collection when available, then an explicit home/away pair. Flag
/// colors and automatic color inversion are not football-kit specifications.
/// These are stylized identities; edition/source gaps are recorded in the kit audit.
func worldCupTeam(for fixtureTeam: FixtureTeam) -> Team {
    let selId = "sel_\(fixtureTeam.id)"
    if let real = CAMI_DATA.team(countryId: "wc26", teamId: selId) {
        return real
    }
    let neutral = Kit(pattern: .solid, colors: ["#AEB4BA", "#FFFFFF"])
    let kits = worldCupKits[fixtureTeam.id] ?? (home: neutral, away: neutral)
    return Team(
        id: selId,
        name: fixtureTeam.name,
        short: fixtureTeam.short,
        home: kits.home,
        away: kits.away,
        crest: Crest(shape: .shield, text: fixtureTeam.short, colors: kits.home.colors)
    )
}

/// All 35 playable selections outside the album, including random-draw extras.
/// No album entries or progress keys are added. Source: kit-audit-2026-09-07.md.
let worldCupKits: [String: (home: Kit, away: Kit)] = [
    "south_africa": (Kit(pattern: .solid, colors: ["#FFB81C", "#007749"]), Kit(pattern: .solid, colors: ["#007749", "#FFB81C"])),
    "czechia": (Kit(pattern: .solid, colors: ["#D7141A", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#184783"])),
    "switzerland": (Kit(pattern: .solid, colors: ["#DA291C", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#DA291C"])),
    "qatar": (Kit(pattern: .solid, colors: ["#8A1538", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#8A1538"])),
    "morocco": (Kit(pattern: .solid, colors: ["#C1272D", "#006233"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#006233", "#C1272D"])),
    "haiti": (Kit(pattern: .solid, colors: ["#00209F", "#D21034"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#00209F", "#D21034"])),
    "scotland": (Kit(pattern: .solid, colors: ["#172B4D", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#F17878", "#FFFFFF"])),
    "paraguay": (Kit(pattern: .stripesV, colors: ["#FFFFFF", "#D52B1E"]), Kit(pattern: .solid, colors: ["#15294B", "#55B7D9"])),
    "turkiye": (Kit(pattern: .sashH, colors: ["#FFFFFF", "#E30A17"]), Kit(pattern: .solid, colors: ["#E30A17", "#FFFFFF"])),
    "ivory_coast": (Kit(pattern: .solid, colors: ["#FF7900", "#007A45"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#007A45", "#FF7900"])),
    "tunisia": (Kit(pattern: .solid, colors: ["#FFFFFF", "#E70013"]), Kit(pattern: .solid, colors: ["#E70013", "#FFFFFF"])),
    "sweden": (Kit(pattern: .solid, colors: ["#FECC00", "#005293"]), Kit(pattern: .solid, colors: ["#005293", "#FECC00"])),
    "iran": (Kit(pattern: .solid, colors: ["#FFFFFF", "#239F40", "#DA291C"]), Kit(pattern: .solid, colors: ["#DA291C", "#FFFFFF"])),
    "new_zealand": (Kit(pattern: .solid, colors: ["#FFFFFF", "#1A1A1A"]), Kit(pattern: .solid, colors: ["#1A1A1A", "#FFFFFF"])),
    "senegal": (Kit(pattern: .solid, colors: ["#FFFFFF", "#00853F"]), Kit(pattern: .solid, colors: ["#00853F", "#FFCE00"])),
    "norway": (Kit(pattern: .solid, colors: ["#BA0C2F", "#00205B"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#00205B"])),
    "iraq": (Kit(pattern: .solid, colors: ["#FFFFFF", "#007A3D"]), Kit(pattern: .solid, colors: ["#007A3D", "#FFFFFF"])),
    "uzbekistan": (Kit(pattern: .solid, colors: ["#146EB4", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#146EB4"])),
    "dr_congo": (Kit(pattern: .solid, colors: ["#007FFF", "#FCD116"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#007FFF", "#FCD116"])),
    "panama": (Kit(pattern: .solid, colors: ["#D21034", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#142B50"])),
    "chile": (Kit(pattern: .solid, colors: ["#D52B1E", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#1E355E"])),
    "peru": (Kit(pattern: .sashD, colors: ["#FFFFFF", "#D91023"]), Kit(pattern: .solid, colors: ["#111111", "#D91023"])),
    "venezuela": (Kit(pattern: .solid, colors: ["#6B1939", "#D5B884"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#6B1939"])),
    "bolivia": (Kit(pattern: .solid, colors: ["#007A3D", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#007A3D"])),
    "nigeria": (Kit(pattern: .solid, colors: ["#008751", "#154A38"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#008751"])),
    "cameroon": (Kit(pattern: .solid, colors: ["#007A5E", "#FCD116", "#CE1126"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#007A5E", "#CE1126"])),
    "mali": (Kit(pattern: .solid, colors: ["#FFFFFF", "#14A24A", "#FCD116"]), Kit(pattern: .solid, colors: ["#14A24A", "#FCD116"])),
    "poland": (Kit(pattern: .solid, colors: ["#FFFFFF", "#DC143C"]), Kit(pattern: .solid, colors: ["#DC143C", "#FFFFFF"])),
    "denmark": (Kit(pattern: .solid, colors: ["#C8102E", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#C8102E"])),
    "serbia": (Kit(pattern: .solid, colors: ["#C6363C", "#FFFFFF"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#244680"])),
    "ukraine": (Kit(pattern: .solid, colors: ["#FFDD00", "#0057B7"]), Kit(pattern: .solid, colors: ["#0057B7", "#FFDD00"])),
    "greece": (Kit(pattern: .solid, colors: ["#FFFFFF", "#005BAA"]), Kit(pattern: .solid, colors: ["#005BAA", "#FFFFFF"])),
    "wales": (Kit(pattern: .solid, colors: ["#C8102E", "#006A44"]), Kit(pattern: .solid, colors: ["#F5F2E8", "#006A44"])),
    "ireland": (Kit(pattern: .solid, colors: ["#007A49", "#FFFFFF", "#FF883E"]), Kit(pattern: .solid, colors: ["#FFFFFF", "#152D44", "#A8C9A3"])),
    "slovenia": (Kit(pattern: .chevron, colors: ["#FFFFFF", "#1558B0"]), Kit(pattern: .chevron, colors: ["#3595D2", "#1558B0", "#FFFFFF"]))
]
