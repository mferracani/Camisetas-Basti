import SwiftUI

struct TournamentSimulatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountryId = "arg"
    @State private var bracket = TournamentBracket.empty

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
                        size: geo.size
                    )
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
                Text("TOCÁ UN ESCUDO PARA HACERLO AVANZAR")
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

private struct TournamentBracketBoard: View {
    @Binding var bracket: TournamentBracket
    let title: String
    let size: CGSize

    private var crestSize: CGFloat {
        min(max(size.width * 0.04, 42), 64)
    }

    var body: some View {
        HStack(spacing: 18) {
            bracketColumn(title: "OCTAVOS", matches: $bracket.roundOf16, round: .roundOf16)
            connectorColumn(lines: 8)
            bracketColumn(title: "CUARTOS", matches: $bracket.quarterFinals, round: .quarterFinals)
            connectorColumn(lines: 4)

            VStack(spacing: 18) {
                Text(title)
                    .font(.custom("Nunito-Black", size: 22))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundColor(Color(hex: "#D9DEE6"))
                    .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 8)

                finalMatch
            }
            .frame(width: min(max(size.width * 0.16, 150), 220))

            connectorColumn(lines: 4)
            bracketColumn(title: "CUARTOS", matches: $bracket.quarterFinalsRight, round: .quarterFinalsRight)
            connectorColumn(lines: 8)
            bracketColumn(title: "OCTAVOS", matches: $bracket.roundOf16Right, round: .roundOf16Right)
        }
        .padding(22)
        .background(Color.white.opacity(0.06))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var finalMatch: some View {
        VStack(spacing: 12) {
            BracketSlot(team: bracket.final.home, crestSize: crestSize + 6) {
                advance(.final, slot: .home)
            }
            Text("FINAL")
                .font(.custom("Nunito-Black", size: 13))
                .foregroundColor(.white.opacity(0.62))
            BracketSlot(team: bracket.final.away, crestSize: crestSize + 6) {
                advance(.final, slot: .away)
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
                MatchView(match: matches[index], crestSize: crestSize) { slot in
                    advance(round, matchIndex: index, slot: slot)
                }
            }
        }
        .frame(width: min(max(size.width * 0.12, 112), 150))
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
}

private struct MatchView: View {
    @Binding var match: TournamentMatch
    let crestSize: CGFloat
    let onPick: (BracketSlotSide) -> Void

    var body: some View {
        VStack(spacing: 4) {
            BracketSlot(team: match.home, crestSize: crestSize) {
                onPick(.home)
            }
            BracketSlot(team: match.away, crestSize: crestSize) {
                onPick(.away)
            }
        }
        .padding(.vertical, 4)
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

private enum BracketSlotSide {
    case home, away
}

private enum TournamentRound {
    case roundOf16, roundOf16Right, quarterFinals, quarterFinalsRight, final
}

private struct TournamentMatch: Equatable {
    var home: Team?
    var away: Team?

    var winner: Team?
}

private struct TournamentBracket: Equatable {
    var roundOf16: [TournamentMatch]
    var roundOf16Right: [TournamentMatch]
    var quarterFinals: [TournamentMatch]
    var quarterFinalsRight: [TournamentMatch]
    var final: TournamentMatch
    var champion: Team?

    static let empty = TournamentBracket(
        roundOf16: Array(repeating: TournamentMatch(), count: 4),
        roundOf16Right: Array(repeating: TournamentMatch(), count: 4),
        quarterFinals: Array(repeating: TournamentMatch(), count: 2),
        quarterFinalsRight: Array(repeating: TournamentMatch(), count: 2),
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
        final = TournamentMatch()
        champion = nil

        autoAdvanceByes()
    }

    private init(
        roundOf16: [TournamentMatch],
        roundOf16Right: [TournamentMatch],
        quarterFinals: [TournamentMatch],
        quarterFinalsRight: [TournamentMatch],
        final: TournamentMatch,
        champion: Team?
    ) {
        self.roundOf16 = roundOf16
        self.roundOf16Right = roundOf16Right
        self.quarterFinals = quarterFinals
        self.quarterFinalsRight = quarterFinalsRight
        self.final = final
        self.champion = champion
    }

    mutating func advance(round: TournamentRound, matchIndex: Int, slot: BracketSlotSide) {
        switch round {
        case .roundOf16:
            guard let winner = selectedTeam(in: roundOf16[matchIndex], slot: slot) else { return }
            roundOf16[matchIndex].winner = winner
            setQuarterWinner(winner, sourceIndex: matchIndex, rightSide: false)
        case .roundOf16Right:
            guard let winner = selectedTeam(in: roundOf16Right[matchIndex], slot: slot) else { return }
            roundOf16Right[matchIndex].winner = winner
            setQuarterWinner(winner, sourceIndex: matchIndex, rightSide: true)
        case .quarterFinals:
            guard let winner = selectedTeam(in: quarterFinals[matchIndex], slot: slot) else { return }
            quarterFinals[matchIndex].winner = winner
            if matchIndex == 0 { final.home = winner } else { final.away = winner }
            champion = nil
        case .quarterFinalsRight:
            guard let winner = selectedTeam(in: quarterFinalsRight[matchIndex], slot: slot) else { return }
            quarterFinalsRight[matchIndex].winner = winner
            if matchIndex == 0 { final.home = winner } else { final.away = winner }
            champion = nil
        case .final:
            guard let winner = selectedTeam(in: final, slot: slot) else { return }
            final.winner = winner
            champion = winner
        }
    }

    private mutating func setQuarterWinner(_ winner: Team, sourceIndex: Int, rightSide: Bool) {
        let targetIndex = sourceIndex / 2
        let isHome = sourceIndex % 2 == 0
        if rightSide {
            if isHome { quarterFinalsRight[targetIndex].home = winner } else { quarterFinalsRight[targetIndex].away = winner }
            quarterFinalsRight[targetIndex].winner = nil
        } else {
            if isHome { quarterFinals[targetIndex].home = winner } else { quarterFinals[targetIndex].away = winner }
            quarterFinals[targetIndex].winner = nil
        }
        final = TournamentMatch(home: final.home, away: final.away, winner: nil)
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
