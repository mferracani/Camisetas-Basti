import SwiftUI

struct WorldCupFixtureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: WorldCupFixtureSection = .groups
    @State private var scores: [String: FixtureScore] = [:]

    private let tournament = WorldCup2026Fixture()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#FEF9E7").ignoresSafeArea()

                VStack(spacing: 18) {
                    header(width: geo.size.width)

                    WorldCupFixturePicker(selection: $selectedSection)

                    ScrollView {
                        if selectedSection == .groups {
                            groupStage(width: geo.size.width)
                        } else {
                            knockoutStage(width: geo.size.width)
                        }
                    }
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 18)
            }
        }
    }

    private func header(width: CGFloat) -> some View {
        HStack {
            BackButton { dismiss() }
            Spacer()
            VStack(spacing: 4) {
                Text("FIXTURE MUNDIAL")
                    .font(.custom("Nunito-Black", size: min(width * 0.036, 44)))
                    .foregroundColor(Color(hex: "#3D2A1F"))
                Text("MARCÁ RESULTADOS Y SE ARMA LA LLAVE")
                    .font(.custom("Nunito-Bold", size: 14))
                    .foregroundColor(Color(hex: "#A88C6A"))
            }
            Spacer()
            Button {
                SoundManager.shared.playTap()
                scores.removeAll()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#8B5E2B"))
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color.white))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 20)
    }

    private func groupStage(width: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: width >= 1180 ? 3 : 2)

        return LazyVGrid(columns: columns, spacing: 18) {
            ForEach(tournament.groups) { group in
                WorldCupGroupCard(
                    group: group,
                    standings: tournament.standings(for: group, scores: scores),
                    scores: $scores
                )
            }
        }
        .padding(.vertical, 10)
    }

    private func knockoutStage(width: CGFloat) -> some View {
        let bracket = tournament.knockoutBracket(scores: scores)

        return VStack(spacing: 22) {
            if let message = bracket.message {
                Text(message)
                    .font(.custom("Nunito-Black", size: 18))
                    .foregroundColor(Color(hex: "#8B5E2B"))
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(18)
            }

            ForEach(bracket.rounds) { round in
                VStack(alignment: .leading, spacing: 12) {
                    Text(round.title)
                        .font(.custom("Nunito-Black", size: 24))
                        .foregroundColor(Color(hex: "#3D2A1F"))

                    LazyVGrid(columns: knockoutColumns(width: width, matchCount: round.matches.count), spacing: 12) {
                        ForEach(round.matches) { match in
                            WorldCupKnockoutMatchCard(match: match, scores: $scores)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }

    private func knockoutColumns(width: CGFloat, matchCount: Int) -> [GridItem] {
        let count: Int
        if matchCount <= 2 {
            count = min(matchCount, 2)
        } else if width >= 1180 {
            count = 4
        } else {
            count = 2
        }
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: max(count, 1))
    }
}

private enum WorldCupFixtureSection: String, CaseIterable {
    case groups = "ZONAS"
    case knockout = "LLAVES"
}

private struct WorldCupFixturePicker: View {
    @Binding var selection: WorldCupFixtureSection

    var body: some View {
        HStack(spacing: 8) {
            ForEach(WorldCupFixtureSection.allCases, id: \.self) { section in
                Button {
                    SoundManager.shared.playTap()
                    selection = section
                } label: {
                    Text(section.rawValue)
                        .font(.custom("Nunito-Black", size: 16))
                        .foregroundColor(selection == section ? .white : Color(hex: "#8B5E2B"))
                        .frame(width: 148, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(selection == section ? Color(hex: "#FF7B3D") : Color.white)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WorldCupGroupCard: View {
    let group: FixtureGroup
    let standings: [FixtureStanding]
    @Binding var scores: [String: FixtureScore]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GRUPO \(group.letter)")
                    .font(.custom("Nunito-Black", size: 20))
                    .foregroundColor(Color(hex: "#3D2A1F"))
                Spacer()
                Text("\(standings.filter { $0.played == 3 }.count)/4")
                    .font(.custom("Nunito-Bold", size: 13))
                    .foregroundColor(Color(hex: "#A88C6A"))
            }

            VStack(spacing: 7) {
                standingsHeader
                ForEach(Array(standings.enumerated()), id: \.element.team.id) { index, standing in
                    WorldCupStandingRow(index: index, standing: standing)
                }
            }

            Divider()

            VStack(spacing: 8) {
                ForEach(group.matches) { match in
                    WorldCupScoreRow(match: match, scores: $scores)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    private var standingsHeader: some View {
        HStack {
            Text("SEL")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PTS").frame(width: 36)
            Text("DG").frame(width: 30)
            Text("GF").frame(width: 30)
        }
        .font(.custom("Nunito-Black", size: 10))
        .foregroundColor(Color(hex: "#A88C6A"))
    }
}

private struct WorldCupStandingRow: View {
    let index: Int
    let standing: FixtureStanding

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.custom("Nunito-Black", size: 12))
                .foregroundColor(Color(hex: index < 2 ? "#22A06B" : index == 2 ? "#F2A900" : "#B0AAA1"))
                .frame(width: 20)
            Text(standing.team.flag)
                .font(.system(size: 18))
            Text(standing.team.name)
                .font(.custom("Nunito-Bold", size: 12))
                .foregroundColor(Color(hex: "#3D2A1F"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(standing.points)").frame(width: 36)
            Text(standing.goalDifferenceText).frame(width: 30)
            Text("\(standing.goalsFor)").frame(width: 30)
        }
        .font(.custom("Nunito-Bold", size: 12))
        .foregroundColor(Color(hex: "#3D2A1F"))
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(index < 2 ? Color(hex: "#E9F9F1") : index == 2 ? Color(hex: "#FFF4D8") : Color(hex: "#F7F4EC"))
        )
    }
}

private struct WorldCupScoreRow: View {
    let match: FixtureMatch
    @Binding var scores: [String: FixtureScore]

    var body: some View {
        HStack(spacing: 8) {
            FixtureTeamLabel(team: match.home)
            ScoreBox(value: homeBinding)
            Text("-")
                .font(.custom("Nunito-Black", size: 16))
                .foregroundColor(Color(hex: "#A88C6A"))
            ScoreBox(value: awayBinding)
            FixtureTeamLabel(team: match.away, alignment: .trailing)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FEF9E7")))
    }

    private var homeBinding: Binding<Int?> {
        Binding(
            get: { scores[match.id]?.home },
            set: { newValue in
                var score = scores[match.id] ?? FixtureScore()
                score.home = newValue
                scores[match.id] = score.isEmpty ? nil : score
            }
        )
    }

    private var awayBinding: Binding<Int?> {
        Binding(
            get: { scores[match.id]?.away },
            set: { newValue in
                var score = scores[match.id] ?? FixtureScore()
                score.away = newValue
                scores[match.id] = score.isEmpty ? nil : score
            }
        )
    }
}

private struct WorldCupKnockoutMatchCard: View {
    let match: KnockoutFixtureMatch
    @Binding var scores: [String: FixtureScore]

    private var winner: FixtureTeam? {
        match.winner(scores: scores)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("M\(match.number)")
                    .font(.custom("Nunito-Black", size: 13))
                    .foregroundColor(Color(hex: "#FF7B3D"))
                Spacer()
                Text(match.venue)
                    .font(.custom("Nunito-Bold", size: 10))
                    .foregroundColor(Color(hex: "#A88C6A"))
                    .lineLimit(1)
            }

            knockoutScoreRow(team: match.home, score: homeBinding, isWinner: winner?.id == match.home?.id)
            knockoutScoreRow(team: match.away, score: awayBinding, isWinner: winner?.id == match.away?.id)

            if let winner {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.forward.circle.fill")
                    Text("PASA \(winner.short)")
                }
                .font(.custom("Nunito-Black", size: 12))
                .foregroundColor(Color(hex: "#22A06B"))
            } else if match.home != nil && match.away != nil {
                Text("CARGÁ UN GANADOR")
                    .font(.custom("Nunito-Black", size: 11))
                    .foregroundColor(Color(hex: "#A88C6A"))
            } else {
                Text(match.placeholder)
                    .font(.custom("Nunito-Bold", size: 11))
                    .foregroundColor(Color(hex: "#B0AAA1"))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func knockoutScoreRow(team: FixtureTeam?, score: Binding<Int?>, isWinner: Bool) -> some View {
        HStack(spacing: 8) {
            if let team {
                Text(team.flag)
                    .font(.system(size: 20))
                Text(team.short)
                    .font(.custom("Nunito-Black", size: 13))
                    .foregroundColor(Color(hex: "#3D2A1F"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                ScoreBox(value: score)
            } else {
                Text("POR DEFINIR")
                    .font(.custom("Nunito-Bold", size: 12))
                    .foregroundColor(Color(hex: "#B0AAA1"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScoreBox(value: .constant(nil))
                    .disabled(true)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWinner ? Color(hex: "#E9F9F1") : Color(hex: "#F7F4EC"))
        )
    }

    private var homeBinding: Binding<Int?> {
        Binding(
            get: { scores[match.id]?.home },
            set: { newValue in
                var score = scores[match.id] ?? FixtureScore()
                score.home = newValue
                scores[match.id] = score.isEmpty ? nil : score
            }
        )
    }

    private var awayBinding: Binding<Int?> {
        Binding(
            get: { scores[match.id]?.away },
            set: { newValue in
                var score = scores[match.id] ?? FixtureScore()
                score.away = newValue
                scores[match.id] = score.isEmpty ? nil : score
            }
        )
    }
}

private struct FixtureTeamLabel: View {
    let team: FixtureTeam
    var alignment: Alignment = .leading

    var body: some View {
        HStack(spacing: 6) {
            if alignment == .trailing {
                Text(team.short)
                    .lineLimit(1)
                Text(team.flag)
            } else {
                Text(team.flag)
                Text(team.short)
                    .lineLimit(1)
            }
        }
        .font(.custom("Nunito-Bold", size: 12))
        .foregroundColor(Color(hex: "#3D2A1F"))
        .frame(maxWidth: .infinity, alignment: alignment)
    }
}

private struct ScoreBox: View {
    @Binding var value: Int?

    var body: some View {
        TextField("", value: $value, format: .number)
            .keyboardType(.numberPad)
            .font(.custom("Nunito-Black", size: 18))
            .multilineTextAlignment(.center)
            .foregroundColor(Color(hex: "#3D2A1F"))
            .frame(width: 44, height: 42)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E8E4DB"), lineWidth: 2)
            )
            .cornerRadius(12)
    }
}

private struct WorldCup2026Fixture {
    let groups: [FixtureGroup]

    init() {
        groups = WorldCup2026Fixture.makeGroups()
    }

    func standings(for group: FixtureGroup, scores: [String: FixtureScore]) -> [FixtureStanding] {
        var table = Dictionary(uniqueKeysWithValues: group.teams.map { ($0.id, FixtureStanding(team: $0)) })

        for match in group.matches {
            guard let score = scores[match.id], let home = score.home, let away = score.away else { continue }
            table[match.home.id]?.played += 1
            table[match.away.id]?.played += 1
            table[match.home.id]?.goalsFor += home
            table[match.home.id]?.goalsAgainst += away
            table[match.away.id]?.goalsFor += away
            table[match.away.id]?.goalsAgainst += home

            if home > away {
                table[match.home.id]?.points += 3
            } else if away > home {
                table[match.away.id]?.points += 3
            } else {
                table[match.home.id]?.points += 1
                table[match.away.id]?.points += 1
            }
        }

        return table.values.sorted(by: sortStandings)
    }

    func knockoutBracket(scores: [String: FixtureScore]) -> KnockoutBracket {
        let completeGroups = groups.allSatisfy { group in
            group.matches.allSatisfy { scores[$0.id]?.isComplete == true }
        }
        let standingsByGroup = Dictionary(uniqueKeysWithValues: groups.map { ($0.letter, standings(for: $0, scores: scores)) })

        let thirdAssignment = assignThirdPlaces(standingsByGroup: standingsByGroup)
        var resolved: [Int: KnockoutFixtureMatch] = [:]

        for definition in roundOf32Definitions {
            let home = team(for: definition.homeSlot, standingsByGroup: standingsByGroup, thirds: thirdAssignment)
            let away = team(for: definition.awaySlot, standingsByGroup: standingsByGroup, thirds: thirdAssignment)
            resolved[definition.number] = KnockoutFixtureMatch(
                number: definition.number,
                id: "wc26_m\(definition.number)",
                venue: definition.venue,
                home: completeGroups ? home : nil,
                away: completeGroups ? away : nil,
                placeholder: "\(definition.homeSlot.label) vs \(definition.awaySlot.label)"
            )
        }

        var rounds: [KnockoutRoundViewModel] = [
            KnockoutRoundViewModel(title: "16AVOS", matches: roundOf32Definitions.compactMap { resolved[$0.number] })
        ]

        let roundOf16 = makeWinnerRound(
            title: "OCTAVOS",
            numbers: [(89, 74, 77, "Philadelphia"), (90, 73, 75, "Houston"), (91, 76, 78, "New York/New Jersey"), (92, 79, 80, "Ciudad de México"), (93, 83, 84, "Dallas"), (94, 81, 82, "Seattle"), (95, 86, 88, "Atlanta"), (96, 85, 87, "Vancouver")],
            resolved: resolved,
            scores: scores
        )
        for match in roundOf16.matches { resolved[match.number] = match }
        rounds.append(roundOf16)

        let quarters = makeWinnerRound(
            title: "CUARTOS",
            numbers: [(97, 89, 90, "Boston"), (98, 93, 94, "Los Angeles"), (99, 91, 92, "Miami"), (100, 95, 96, "Kansas City")],
            resolved: resolved,
            scores: scores
        )
        for match in quarters.matches { resolved[match.number] = match }
        rounds.append(quarters)

        let semis = makeWinnerRound(
            title: "SEMIFINALES",
            numbers: [(101, 97, 98, "Dallas"), (102, 99, 100, "Atlanta")],
            resolved: resolved,
            scores: scores
        )
        for match in semis.matches { resolved[match.number] = match }
        rounds.append(semis)

        let final = makeWinnerRound(
            title: "FINAL",
            numbers: [(104, 101, 102, "New York/New Jersey")],
            resolved: resolved,
            scores: scores
        )
        rounds.append(final)

        let message = completeGroups ? nil : "Completá todos los partidos de zona para abrir los 16avos."
        return KnockoutBracket(rounds: rounds, message: message)
    }

    private func makeWinnerRound(
        title: String,
        numbers: [(Int, Int, Int, String)],
        resolved: [Int: KnockoutFixtureMatch],
        scores: [String: FixtureScore]
    ) -> KnockoutRoundViewModel {
        let matches = numbers.map { number, homeSource, awaySource, venue in
            let home = resolved[homeSource]?.winner(scores: scores)
            let away = resolved[awaySource]?.winner(scores: scores)
            return KnockoutFixtureMatch(
                number: number,
                id: "wc26_m\(number)",
                venue: venue,
                home: home,
                away: away,
                placeholder: "Ganador M\(homeSource) vs Ganador M\(awaySource)"
            )
        }
        return KnockoutRoundViewModel(title: title, matches: matches)
    }

    private func assignThirdPlaces(standingsByGroup: [String: [FixtureStanding]]) -> [Int: FixtureTeam] {
        let thirds = groups.compactMap { group -> FixtureStanding? in
            standingsByGroup[group.letter]?[safe: 2]
        }
        .sorted(by: sortStandings)
        .prefix(8)

        var thirdByGroup: [String: FixtureTeam] = [:]
        for standing in thirds {
            thirdByGroup[standing.team.group] = standing.team
        }

        let slots = thirdPlaceSlots
        var assignment: [Int: FixtureTeam] = [:]
        var usedGroups: Set<String> = []

        func backtrack(_ index: Int) -> Bool {
            guard index < slots.count else { return true }
            let slot = slots[index]
            let candidates = slot.allowedGroups
                .compactMap { group in thirdByGroup[group] }
                .filter { !usedGroups.contains($0.group) }

            for team in candidates {
                assignment[slot.matchNumber] = team
                usedGroups.insert(team.group)
                if backtrack(index + 1) { return true }
                usedGroups.remove(team.group)
                assignment[slot.matchNumber] = nil
            }

            return false
        }

        _ = backtrack(0)
        return assignment
    }

    private func team(for slot: FixtureSlot, standingsByGroup: [String: [FixtureStanding]], thirds: [Int: FixtureTeam]) -> FixtureTeam? {
        switch slot {
        case .winner(let group):
            return standingsByGroup[group]?[safe: 0]?.team
        case .runnerUp(let group):
            return standingsByGroup[group]?[safe: 1]?.team
        case .thirdPlace(_, let matchNumber):
            return thirds[matchNumber]
        }
    }

    private func sortStandings(_ lhs: FixtureStanding, _ rhs: FixtureStanding) -> Bool {
        if lhs.points != rhs.points { return lhs.points > rhs.points }
        if lhs.goalDifference != rhs.goalDifference { return lhs.goalDifference > rhs.goalDifference }
        if lhs.goalsFor != rhs.goalsFor { return lhs.goalsFor > rhs.goalsFor }
        return lhs.team.name < rhs.team.name
    }

    private static func makeGroups() -> [FixtureGroup] {
        let data: [(String, [FixtureTeam])] = [
            ("A", [team("mexico", "México", "MEX", "🇲🇽", "A"), team("south_africa", "Sudáfrica", "RSA", "🇿🇦", "A"), team("south_korea", "Corea del Sur", "KOR", "🇰🇷", "A"), team("czechia", "Chequia", "CZE", "🇨🇿", "A")]),
            ("B", [team("canada", "Canadá", "CAN", "🇨🇦", "B"), team("switzerland", "Suiza", "SUI", "🇨🇭", "B"), team("qatar", "Qatar", "QAT", "🇶🇦", "B"), team("bosnia", "Bosnia y Herzegovina", "BIH", "🇧🇦", "B")]),
            ("C", [team("brazil", "Brasil", "BRA", "🇧🇷", "C"), team("morocco", "Marruecos", "MAR", "🇲🇦", "C"), team("haiti", "Haití", "HAI", "🇭🇹", "C"), team("scotland", "Escocia", "SCO", "🏴", "C")]),
            ("D", [team("usa", "Estados Unidos", "USA", "🇺🇸", "D"), team("paraguay", "Paraguay", "PAR", "🇵🇾", "D"), team("australia", "Australia", "AUS", "🇦🇺", "D"), team("turkiye", "Turquía", "TUR", "🇹🇷", "D")]),
            ("E", [team("germany", "Alemania", "GER", "🇩🇪", "E"), team("curacao", "Curazao", "CUW", "🇨🇼", "E"), team("ivory_coast", "Costa de Marfil", "CIV", "🇨🇮", "E"), team("ecuador", "Ecuador", "ECU", "🇪🇨", "E")]),
            ("F", [team("netherlands", "Países Bajos", "NED", "🇳🇱", "F"), team("japan", "Japón", "JPN", "🇯🇵", "F"), team("tunisia", "Túnez", "TUN", "🇹🇳", "F"), team("sweden", "Suecia", "SWE", "🇸🇪", "F")]),
            ("G", [team("belgium", "Bélgica", "BEL", "🇧🇪", "G"), team("egypt", "Egipto", "EGY", "🇪🇬", "G"), team("iran", "Irán", "IRN", "🇮🇷", "G"), team("new_zealand", "Nueva Zelanda", "NZL", "🇳🇿", "G")]),
            ("H", [team("spain", "España", "ESP", "🇪🇸", "H"), team("cape_verde", "Cabo Verde", "CPV", "🇨🇻", "H"), team("saudi_arabia", "Arabia Saudita", "KSA", "🇸🇦", "H"), team("uruguay", "Uruguay", "URU", "🇺🇾", "H")]),
            ("I", [team("france", "Francia", "FRA", "🇫🇷", "I"), team("senegal", "Senegal", "SEN", "🇸🇳", "I"), team("norway", "Noruega", "NOR", "🇳🇴", "I"), team("iraq", "Irak", "IRQ", "🇮🇶", "I")]),
            ("J", [team("argentina", "Argentina", "ARG", "🇦🇷", "J"), team("algeria", "Argelia", "ALG", "🇩🇿", "J"), team("austria", "Austria", "AUT", "🇦🇹", "J"), team("jordan", "Jordania", "JOR", "🇯🇴", "J")]),
            ("K", [team("portugal", "Portugal", "POR", "🇵🇹", "K"), team("uzbekistan", "Uzbekistán", "UZB", "🇺🇿", "K"), team("colombia", "Colombia", "COL", "🇨🇴", "K"), team("dr_congo", "RD Congo", "COD", "🇨🇩", "K")]),
            ("L", [team("england", "Inglaterra", "ENG", "🏴", "L"), team("croatia", "Croacia", "CRO", "🇭🇷", "L"), team("ghana", "Ghana", "GHA", "🇬🇭", "L"), team("panama", "Panamá", "PAN", "🇵🇦", "L")])
        ]

        return data.map { letter, teams in
            FixtureGroup(letter: letter, teams: teams, matches: makeMatches(group: letter, teams: teams))
        }
    }

    private static func makeMatches(group: String, teams: [FixtureTeam]) -> [FixtureMatch] {
        let pairs = [(0, 1), (2, 3), (0, 2), (1, 3), (0, 3), (1, 2)]
        return pairs.enumerated().map { index, pair in
            FixtureMatch(id: "wc26_g\(group)_m\(index + 1)", group: group, home: teams[pair.0], away: teams[pair.1])
        }
    }

    private static func team(_ id: String, _ name: String, _ short: String, _ flag: String, _ group: String) -> FixtureTeam {
        FixtureTeam(id: id, name: name, short: short, flag: flag, group: group)
    }
}

private let roundOf32Definitions: [KnockoutDefinition] = [
    KnockoutDefinition(73, .runnerUp("A"), .runnerUp("B"), "Los Angeles"),
    KnockoutDefinition(74, .winner("E"), .thirdPlace(["A", "B", "C", "D", "F"], 74), "Boston"),
    KnockoutDefinition(75, .winner("F"), .runnerUp("C"), "Monterrey"),
    KnockoutDefinition(76, .winner("C"), .runnerUp("F"), "Houston"),
    KnockoutDefinition(77, .winner("I"), .thirdPlace(["C", "D", "F", "G", "H"], 77), "New York/New Jersey"),
    KnockoutDefinition(78, .runnerUp("E"), .runnerUp("I"), "Dallas"),
    KnockoutDefinition(79, .winner("A"), .thirdPlace(["C", "E", "F", "H", "I"], 79), "Ciudad de México"),
    KnockoutDefinition(80, .winner("L"), .thirdPlace(["E", "H", "I", "J", "K"], 80), "Atlanta"),
    KnockoutDefinition(81, .winner("D"), .thirdPlace(["B", "E", "F", "I", "J"], 81), "San Francisco"),
    KnockoutDefinition(82, .winner("G"), .thirdPlace(["A", "E", "H", "I", "J"], 82), "Seattle"),
    KnockoutDefinition(83, .runnerUp("K"), .runnerUp("L"), "Toronto"),
    KnockoutDefinition(84, .winner("H"), .runnerUp("J"), "Los Angeles"),
    KnockoutDefinition(85, .winner("B"), .thirdPlace(["E", "F", "G", "I", "J"], 85), "Vancouver"),
    KnockoutDefinition(86, .winner("J"), .runnerUp("H"), "Miami"),
    KnockoutDefinition(87, .winner("K"), .thirdPlace(["D", "E", "I", "J", "L"], 87), "Kansas City"),
    KnockoutDefinition(88, .runnerUp("D"), .runnerUp("G"), "Dallas")
]

private let thirdPlaceSlots: [ThirdPlaceSlot] = roundOf32Definitions.compactMap { definition in
    if case .thirdPlace(let allowedGroups, let number) = definition.awaySlot {
        return ThirdPlaceSlot(matchNumber: number, allowedGroups: allowedGroups)
    }
    return nil
}

private struct FixtureTeam: Identifiable, Hashable {
    let id: String
    let name: String
    let short: String
    let flag: String
    let group: String
}

private struct FixtureGroup: Identifiable {
    let letter: String
    let teams: [FixtureTeam]
    let matches: [FixtureMatch]
    var id: String { letter }
}

private struct FixtureMatch: Identifiable {
    let id: String
    let group: String
    let home: FixtureTeam
    let away: FixtureTeam
}

private struct FixtureScore: Equatable {
    var home: Int?
    var away: Int?

    var isEmpty: Bool { home == nil && away == nil }
    var isComplete: Bool { home != nil && away != nil }
}

private struct FixtureStanding {
    let team: FixtureTeam
    var played = 0
    var goalsFor = 0
    var goalsAgainst = 0
    var points = 0

    var goalDifference: Int { goalsFor - goalsAgainst }
    var goalDifferenceText: String { goalDifference > 0 ? "+\(goalDifference)" : "\(goalDifference)" }
}

private enum FixtureSlot {
    case winner(String)
    case runnerUp(String)
    case thirdPlace([String], Int)

    var label: String {
        switch self {
        case .winner(let group): return "1° Grupo \(group)"
        case .runnerUp(let group): return "2° Grupo \(group)"
        case .thirdPlace(let groups, _): return "3° \(groups.joined(separator: "/"))"
        }
    }
}

private struct KnockoutDefinition {
    let number: Int
    let homeSlot: FixtureSlot
    let awaySlot: FixtureSlot
    let venue: String

    init(_ number: Int, _ homeSlot: FixtureSlot, _ awaySlot: FixtureSlot, _ venue: String) {
        self.number = number
        self.homeSlot = homeSlot
        self.awaySlot = awaySlot
        self.venue = venue
    }
}

private struct ThirdPlaceSlot {
    let matchNumber: Int
    let allowedGroups: [String]
}

private struct KnockoutFixtureMatch: Identifiable {
    let number: Int
    let id: String
    let venue: String
    let home: FixtureTeam?
    let away: FixtureTeam?
    let placeholder: String

    func winner(scores: [String: FixtureScore]) -> FixtureTeam? {
        guard let home, let away, let score = scores[id], let homeGoals = score.home, let awayGoals = score.away, homeGoals != awayGoals else {
            return nil
        }
        return homeGoals > awayGoals ? home : away
    }
}

private struct KnockoutRoundViewModel: Identifiable {
    let title: String
    let matches: [KnockoutFixtureMatch]
    var id: String { title }
}

private struct KnockoutBracket {
    let rounds: [KnockoutRoundViewModel]
    let message: String?
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
