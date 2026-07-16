import SwiftUI

struct WorldCupFixtureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: WorldCupFixtureSection = .groups
    @State private var scores: [String: FixtureScore] = [:]
    @State private var isRandomized: Bool = false
    @State private var tournament = WorldCup2026Fixture()
    @State private var selectedRandomTeamIds = WorldCup2026Fixture.defaultRandomTeamIds
    @State private var showingTeamEditor = false

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
        .sheet(isPresented: $showingTeamEditor) {
            WorldCupTeamEditorSheet(
                selectedTeamIds: $selectedRandomTeamIds,
                lockedTeamIds: WorldCup2026Fixture.lockedRandomTeamIds,
                teams: WorldCup2026Fixture.randomTeamPool
            )
        }
        .onChange(of: selectedRandomTeamIds) { _ in
            guard isRandomized else { return }
            tournament = WorldCup2026Fixture(randomTeamIds: selectedRandomTeamIds)
            scores.removeAll()
            selectedSection = .groups
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
                HStack(spacing: 6) {
                    if isRandomized {
                        Text("🎲")
                            .font(.system(size: 13))
                        Text("SORTEO ALEATORIO")
                            .font(.custom("Nunito-Bold", size: 14))
                            .foregroundColor(Color(hex: "#FF7B3D"))
                    } else {
                        Text("MARCÁ RESULTADOS Y SE ARMA LA LLAVE")
                            .font(.custom("Nunito-Bold", size: 14))
                            .foregroundColor(Color(hex: "#A88C6A"))
                    }
                }
            }
            Spacer()
            HStack(spacing: 10) {
                Button {
                    SoundManager.shared.playTap()
                    showingTeamEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("EQUIPOS")
                            .font(.custom("Nunito-Black", size: 13))
                    }
                    .foregroundColor(Color(hex: "#8B5E2B"))
                    .frame(height: 54)
                    .padding(.horizontal, 14)
                    .background(Capsule().fill(Color.white))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cambiar equipos del sorteo aleatorio")

                Button {
                    randomizeGroups()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 17, weight: .bold))
                        Text(isRandomized ? "NUEVO SORTEO" : "ALEATORIO")
                            .font(.custom("Nunito-Black", size: 13))
                    }
                    .foregroundColor(isRandomized ? .white : Color(hex: "#8B5E2B"))
                    .frame(height: 54)
                    .padding(.horizontal, 16)
                    .background(Capsule().fill(isRandomized ? Color(hex: "#FF7B3D") : Color.white))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mezclar grupos de forma aleatoria")

                Button {
                    resetTournament()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "#8B5E2B"))
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(Color.white))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRandomized ? "Volver al fixture real" : "Limpiar resultados")
            }
        }
        .padding(.top, 20)
    }

    private func randomizeGroups() {
        SoundManager.shared.playTap()
        tournament = WorldCup2026Fixture(randomTeamIds: selectedRandomTeamIds)
        scores.removeAll()
        isRandomized = true
        selectedSection = .groups
    }

    private func resetTournament() {
        SoundManager.shared.playTap()
        if isRandomized {
            tournament = WorldCup2026Fixture()
            isRandomized = false
        }
        scores.removeAll()
        selectedSection = .groups
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

private struct WorldCupTeamEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTeamIds: Set<String>
    let lockedTeamIds: Set<String>
    let teams: [FixtureTeam]

    private var sortedTeams: [FixtureTeam] {
        teams.sorted { lhs, rhs in
            let lhsRank = rank(for: lhs)
            let rhsRank = rank(for: rhs)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.displayName < rhs.displayName
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#FEF9E7").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EQUIPOS DEL SORTEO")
                            .font(.custom("Nunito-Black", size: 32))
                            .foregroundColor(Color(hex: "#3D2A1F"))
                        Text("ELEGÍ 48. LOS GRANDES QUEDAN FIJOS.")
                            .font(.custom("Nunito-Bold", size: 14))
                            .foregroundColor(Color(hex: "#A88C6A"))
                    }

                    HStack(spacing: 12) {
                        Text("\(selectedTeamIds.count)/48")
                            .font(.custom("Nunito-Black", size: 24))
                            .foregroundColor(selectedTeamIds.count == 48 ? Color(hex: "#22A06B") : Color(hex: "#FF7B3D"))
                        Text(selectedTeamIds.count == 48 ? "LISTO PARA SORTEAR" : "SACÁ O AGREGÁ EQUIPOS")
                            .font(.custom("Nunito-Black", size: 13))
                            .foregroundColor(Color(hex: "#3D2A1F"))
                        Spacer()
                        Button {
                            SoundManager.shared.playTap()
                            selectedTeamIds = WorldCup2026Fixture.defaultRandomTeamIds
                        } label: {
                            Label("REALES 2026", systemImage: "arrow.counterclockwise")
                                .font(.custom("Nunito-Black", size: 13))
                                .foregroundColor(Color(hex: "#8B5E2B"))
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .background(Capsule().fill(Color.white))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.9)))

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                            ForEach(sortedTeams) { team in
                                WorldCupTeamToggleCard(
                                    team: team,
                                    isSelected: selectedTeamIds.contains(team.id),
                                    isLocked: lockedTeamIds.contains(team.id),
                                    canAdd: selectedTeamIds.count < WorldCup2026Fixture.randomTeamLimit,
                                    action: { toggle(team) }
                                )
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("LISTO") {
                        dismiss()
                    }
                    .font(.custom("Nunito-Black", size: 15))
                }
            }
        }
    }

    private func rank(for team: FixtureTeam) -> Int {
        if lockedTeamIds.contains(team.id) { return 0 }
        if selectedTeamIds.contains(team.id) { return 1 }
        return 2
    }

    private func toggle(_ team: FixtureTeam) {
        guard !lockedTeamIds.contains(team.id) else { return }
        SoundManager.shared.playTap()

        if selectedTeamIds.contains(team.id) {
            selectedTeamIds.remove(team.id)
        } else if selectedTeamIds.count < WorldCup2026Fixture.randomTeamLimit {
            selectedTeamIds.insert(team.id)
        }
    }
}

private struct WorldCupTeamToggleCard: View {
    let team: FixtureTeam
    let isSelected: Bool
    let isLocked: Bool
    let canAdd: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(team.flag)
                    .font(.system(size: 24))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(team.displayName)
                        .font(.custom("Nunito-Black", size: 13))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                        .lineLimit(1)
                    Text(statusText)
                        .font(.custom("Nunito-Black", size: 10))
                        .foregroundColor(statusColor)
                }
                Spacer(minLength: 6)
                Image(systemName: statusIcon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(statusColor)
            }
            .padding(12)
            .frame(minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? statusColor.opacity(0.35) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked || (!isSelected && !canAdd))
    }

    private var statusText: String {
        if isLocked { return "FIJO" }
        if isSelected { return "SALE" }
        return canAdd ? "ENTRA" : "SACÁ UNO"
    }

    private var statusIcon: String {
        if isLocked { return "lock.fill" }
        if isSelected { return "minus.circle.fill" }
        return canAdd ? "plus.circle.fill" : "circle"
    }

    private var statusColor: Color {
        if isLocked { return Color(hex: "#8B5E2B") }
        if isSelected { return Color(hex: "#22A06B") }
        return canAdd ? Color(hex: "#FF7B3D") : Color(hex: "#B0AAA1")
    }

    private var backgroundColor: Color {
        if isLocked { return Color(hex: "#FFF4D8") }
        if isSelected { return Color(hex: "#E9F9F1") }
        return Color.white
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
            Text(standing.team.displayName)
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
        VStack(spacing: 6) {
            FixtureScheduleLabel(schedule: match.schedule)

            HStack(spacing: 8) {
                FixtureTeamLabel(team: match.home)
                ScoreBox(value: homeBinding)
                Text("-")
                    .font(.custom("Nunito-Black", size: 16))
                    .foregroundColor(Color(hex: "#A88C6A"))
                ScoreBox(value: awayBinding)
                FixtureTeamLabel(team: match.away, alignment: .trailing)
            }
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

            FixtureScheduleLabel(schedule: match.schedule)

            knockoutScoreRow(team: match.home, score: homeBinding, isWinner: winner?.id == match.home?.id)
            knockoutScoreRow(team: match.away, score: awayBinding, isWinner: winner?.id == match.away?.id)

            if match.isTied(scores: scores), match.home != nil, match.away != nil {
                penaltyPicker
            }

            if let winner {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.forward.circle.fill")
                    Text(match.isTied(scores: scores) ? "PASA \(winner.short) POR PENALES" : "PASA \(winner.short)")
                }
                .font(.custom("Nunito-Black", size: 12))
                .foregroundColor(Color(hex: "#22A06B"))
            } else if match.home != nil && match.away != nil {
                Text(match.isTied(scores: scores) ? "ELEGÍ QUIÉN GANÓ POR PENALES" : "CARGÁ UN GANADOR")
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

    private var penaltyPicker: some View {
        HStack(spacing: 8) {
            Text("PENALES")
                .font(.custom("Nunito-Black", size: 10))
                .foregroundColor(Color(hex: "#A88C6A"))

            if let home = match.home {
                penaltyButton(team: home)
            }
            if let away = match.away {
                penaltyButton(team: away)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF4D8")))
    }

    private func penaltyButton(team: FixtureTeam) -> some View {
        Button {
            SoundManager.shared.playTap()
            var score = scores[match.id] ?? FixtureScore()
            score.penaltyWinnerId = team.id
            scores[match.id] = score
        } label: {
            Text(team.short)
                .font(.custom("Nunito-Black", size: 11))
                .foregroundColor(scorePenaltyWinnerId == team.id ? .white : Color(hex: "#8B5E2B"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(scorePenaltyWinnerId == team.id ? Color(hex: "#FF7B3D") : Color.white)
                )
        }
        .buttonStyle(.plain)
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
                score.clearPenaltiesIfNeeded()
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
                score.clearPenaltiesIfNeeded()
                scores[match.id] = score.isEmpty ? nil : score
            }
        )
    }

    private var scorePenaltyWinnerId: String? {
        scores[match.id]?.penaltyWinnerId
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

private struct FixtureScheduleLabel: View {
    let schedule: FixtureScheduleInfo

    var body: some View {
        HStack(spacing: 8) {
            Label(schedule.argentinaText, systemImage: "calendar")
                .labelStyle(.titleAndIcon)
            if let spainText = schedule.spainText {
                Text("ESP \(spainText)")
            }
            Spacer(minLength: 0)
        }
        .font(.custom("Nunito-Black", size: 10))
        .foregroundColor(Color(hex: "#8B5E2B"))
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

struct WorldCup2026Fixture {
    static let randomTeamLimit = 48
    static let lockedRandomTeamIds: Set<String> = ["argentina", "brazil", "spain", "france", "england"]
    static var defaultRandomTeamIds: Set<String> {
        Set(makeGroups().flatMap { $0.teams }.map(\.id))
    }
    static var randomTeamPool: [FixtureTeam] {
        makeGroups().flatMap { $0.teams } + extraRandomTeams
    }

    let groups: [FixtureGroup]

    init(randomized: Bool = false) {
        groups = randomized ? WorldCup2026Fixture.makeRandomizedGroups(selectedTeamIds: WorldCup2026Fixture.defaultRandomTeamIds) : WorldCup2026Fixture.makeGroups()
    }

    init(randomTeamIds: Set<String>) {
        groups = WorldCup2026Fixture.makeRandomizedGroups(selectedTeamIds: randomTeamIds)
    }

    static func makeRandomizedGroups(selectedTeamIds: Set<String>) -> [FixtureGroup] {
        let allTeams = selectedRandomTeams(from: selectedTeamIds).shuffled()
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]
        return letters.enumerated().map { index, letter in
            let slice = Array(allTeams[index * 4 ..< (index + 1) * 4])
            let teams = slice.map { t in t.withGroup(letter) }
            return FixtureGroup(letter: letter, teams: teams, matches: makeRoundRobinMatches(group: letter, teams: teams))
        }
    }

    static func selectedRandomTeams(from selectedTeamIds: Set<String>) -> [FixtureTeam] {
        let pool = randomTeamPool
        let poolIds = Set(pool.map(\.id))
        var ids = selectedTeamIds.intersection(poolIds).union(lockedRandomTeamIds)

        if ids.count > randomTeamLimit {
            let removable = pool
                .map(\.id)
                .filter { ids.contains($0) && !lockedRandomTeamIds.contains($0) }
                .dropLast(randomTeamLimit - lockedRandomTeamIds.count)
            for id in removable {
                ids.remove(id)
            }
        }

        if ids.count < randomTeamLimit {
            for team in pool where !ids.contains(team.id) {
                ids.insert(team.id)
                if ids.count == randomTeamLimit { break }
            }
        }

        return pool.filter { ids.contains($0.id) }.prefix(randomTeamLimit).map { $0 }
    }

    static func makeRoundRobinMatches(group: String, teams: [FixtureTeam]) -> [FixtureMatch] {
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (0, 2), (1, 3), (0, 3), (1, 2)]
        return pairs.enumerated().map { index, pair in
            FixtureMatch(
                id: "wc26r_g\(group)_m\(index + 1)",
                group: group,
                home: teams[pair.0],
                away: teams[pair.1],
                schedule: FixtureScheduleInfo(dateArgentina: "JORNADA \(index < 2 ? 1 : index < 4 ? 2 : 3)", timeArgentina: "", spainText: nil)
            )
        }
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
                schedule: definition.schedule,
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
            definitions: [
                WinnerRoundDefinition(89, 74, 77, "Philadelphia", schedule("04/07", "18:00", "23:00")),
                WinnerRoundDefinition(90, 73, 75, "Houston", schedule("04/07", "14:00", "19:00")),
                WinnerRoundDefinition(91, 76, 78, "New York/New Jersey", schedule("05/07", "17:00", "22:00")),
                WinnerRoundDefinition(92, 79, 80, "Ciudad de México", schedule("05/07", "21:00", "06/07 02:00")),
                WinnerRoundDefinition(93, 83, 84, "Dallas", schedule("06/07", "16:00", "21:00")),
                WinnerRoundDefinition(94, 81, 82, "Seattle", schedule("06/07", "21:00", "07/07 02:00")),
                WinnerRoundDefinition(95, 86, 88, "Atlanta", schedule("07/07", "13:00", "18:00")),
                WinnerRoundDefinition(96, 85, 87, "Vancouver", schedule("07/07", "17:00", "22:00"))
            ],
            resolved: resolved,
            scores: scores
        )
        for match in roundOf16.matches { resolved[match.number] = match }
        rounds.append(roundOf16)

        let quarters = makeWinnerRound(
            title: "CUARTOS",
            definitions: [
                WinnerRoundDefinition(97, 89, 90, "Boston", schedule("09/07", "17:00", "22:00")),
                WinnerRoundDefinition(98, 93, 94, "Los Angeles", schedule("10/07", "16:00")),
                WinnerRoundDefinition(99, 91, 92, "Miami", schedule("11/07", "18:00")),
                WinnerRoundDefinition(100, 95, 96, "Kansas City", schedule("11/07", "22:00"))
            ],
            resolved: resolved,
            scores: scores
        )
        for match in quarters.matches { resolved[match.number] = match }
        rounds.append(quarters)

        let semis = makeWinnerRound(
            title: "SEMIFINALES",
            definitions: [
                WinnerRoundDefinition(101, 97, 98, "Dallas", schedule("14/07", "21:00")),
                WinnerRoundDefinition(102, 99, 100, "Atlanta", schedule("15/07", "21:00"))
            ],
            resolved: resolved,
            scores: scores
        )
        for match in semis.matches { resolved[match.number] = match }
        rounds.append(semis)

        let final = makeWinnerRound(
            title: "FINAL",
            definitions: [
                WinnerRoundDefinition(104, 101, 102, "New York/New Jersey", schedule("19/07", "16:00"))
            ],
            resolved: resolved,
            scores: scores
        )
        rounds.append(final)

        let message = completeGroups ? nil : "Completá todos los partidos de zona para abrir los 16avos."
        return KnockoutBracket(rounds: rounds, message: message)
    }

    func champion(scores: [String: FixtureScore]) -> FixtureTeam? {
        knockoutBracket(scores: scores).rounds.last?.matches.first?.winner(scores: scores)
    }

    private func makeWinnerRound(
        title: String,
        definitions: [WinnerRoundDefinition],
        resolved: [Int: KnockoutFixtureMatch],
        scores: [String: FixtureScore]
    ) -> KnockoutRoundViewModel {
        let matches = definitions.map { definition in
            let home = resolved[definition.homeSource]?.winner(scores: scores)
            let away = resolved[definition.awaySource]?.winner(scores: scores)
            return KnockoutFixtureMatch(
                number: definition.number,
                id: "wc26_m\(definition.number)",
                venue: definition.venue,
                schedule: definition.schedule,
                home: home,
                away: away,
                placeholder: "Ganador M\(definition.homeSource) vs Ganador M\(definition.awaySource)"
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
            ("C", [team("brazil", "Brasil", "BRA", "🇧🇷", "C"), team("morocco", "Marruecos", "MAR", "🇲🇦", "C"), team("haiti", "Haití", "HAI", "🇭🇹", "C"), team("scotland", "Escocia", "SCO", "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "C")]),
            ("D", [team("usa", "Estados Unidos", "USA", "🇺🇸", "D"), team("paraguay", "Paraguay", "PAR", "🇵🇾", "D"), team("australia", "Australia", "AUS", "🇦🇺", "D"), team("turkiye", "Turquía", "TUR", "🇹🇷", "D")]),
            ("E", [team("germany", "Alemania", "GER", "🇩🇪", "E"), team("curacao", "Curazao", "CUW", "🇨🇼", "E"), team("ivory_coast", "Costa de Marfil", "CIV", "🇨🇮", "E"), team("ecuador", "Ecuador", "ECU", "🇪🇨", "E")]),
            ("F", [team("netherlands", "Países Bajos", "NED", "🇳🇱", "F"), team("japan", "Japón", "JPN", "🇯🇵", "F"), team("tunisia", "Túnez", "TUN", "🇹🇳", "F"), team("sweden", "Suecia", "SWE", "🇸🇪", "F")]),
            ("G", [team("belgium", "Bélgica", "BEL", "🇧🇪", "G"), team("egypt", "Egipto", "EGY", "🇪🇬", "G"), team("iran", "Irán", "IRN", "🇮🇷", "G"), team("new_zealand", "Nueva Zelanda", "NZL", "🇳🇿", "G")]),
            ("H", [team("spain", "España", "ESP", "🇪🇸", "H"), team("cape_verde", "Cabo Verde", "CPV", "🇨🇻", "H"), team("saudi_arabia", "Arabia Saudita", "KSA", "🇸🇦", "H"), team("uruguay", "Uruguay", "URU", "🇺🇾", "H")]),
            ("I", [team("france", "Francia", "FRA", "🇫🇷", "I"), team("senegal", "Senegal", "SEN", "🇸🇳", "I"), team("norway", "Noruega", "NOR", "🇳🇴", "I"), team("iraq", "Irak", "IRQ", "🇮🇶", "I")]),
            ("J", [team("argentina", "Argentina", "ARG", "🇦🇷", "J"), team("algeria", "Argelia", "ALG", "🇩🇿", "J"), team("austria", "Austria", "AUT", "🇦🇹", "J"), team("jordan", "Jordania", "JOR", "🇯🇴", "J")]),
            ("K", [team("portugal", "Portugal", "POR", "🇵🇹", "K"), team("uzbekistan", "Uzbekistán", "UZB", "🇺🇿", "K"), team("colombia", "Colombia", "COL", "🇨🇴", "K"), team("dr_congo", "RD Congo", "COD", "🇨🇩", "K")]),
            ("L", [team("england", "Inglaterra", "ENG", "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "L"), team("croatia", "Croacia", "CRO", "🇭🇷", "L"), team("ghana", "Ghana", "GHA", "🇬🇭", "L"), team("panama", "Panamá", "PAN", "🇵🇦", "L")])
        ]

        return data.map { letter, teams in
            FixtureGroup(letter: letter, teams: teams, matches: makeMatches(group: letter, teams: teams))
        }
    }

    private static func makeMatches(group: String, teams: [FixtureTeam]) -> [FixtureMatch] {
        let teamsById = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0) })
        guard let definitions = groupMatchDefinitions[group] else { return [] }

        return definitions.enumerated().compactMap { index, definition in
            guard let home = teamsById[definition.homeId], let away = teamsById[definition.awayId] else {
                return nil
            }
            return FixtureMatch(
                id: "wc26_g\(group)_m\(index + 1)",
                group: group,
                home: home,
                away: away,
                schedule: definition.schedule
            )
        }
    }

    private static func team(_ id: String, _ name: String, _ short: String, _ flag: String, _ group: String) -> FixtureTeam {
        FixtureTeam(id: id, name: name, short: short, flag: flag, group: group)
    }

    private static let extraRandomTeams: [FixtureTeam] = [
        team("italy", "ITALIA", "ITA", "🇮🇹", "EXTRA"),
        team("chile", "CHILE", "CHI", "🇨🇱", "EXTRA"),
        team("peru", "PERU", "PER", "🇵🇪", "EXTRA"),
        team("venezuela", "VENEZUELA", "VEN", "🇻🇪", "EXTRA"),
        team("bolivia", "BOLIVIA", "BOL", "🇧🇴", "EXTRA"),
        team("nigeria", "NIGERIA", "NGA", "🇳🇬", "EXTRA"),
        team("cameroon", "CAMERUN", "CMR", "🇨🇲", "EXTRA"),
        team("mali", "MALI", "MLI", "🇲🇱", "EXTRA"),
        team("poland", "POLONIA", "POL", "🇵🇱", "EXTRA"),
        team("denmark", "DINAMARCA", "DEN", "🇩🇰", "EXTRA"),
        team("serbia", "SERBIA", "SRB", "🇷🇸", "EXTRA"),
        team("ukraine", "UCRANIA", "UKR", "🇺🇦", "EXTRA"),
        team("greece", "GRECIA", "GRE", "🇬🇷", "EXTRA"),
        team("wales", "GALES", "WAL", "🏴", "EXTRA"),
        team("ireland", "IRLANDA", "IRL", "🇮🇪", "EXTRA"),
        team("slovenia", "ESLOVENIA", "SVN", "🇸🇮", "EXTRA")
    ]
}

private let roundOf32Definitions: [KnockoutDefinition] = [
    KnockoutDefinition(73, .runnerUp("A"), .runnerUp("B"), "Los Angeles", schedule("28/06", "16:00", "22:00")),
    KnockoutDefinition(74, .winner("E"), .thirdPlace(["A", "B", "C", "D", "F"], 74), "Boston", schedule("29/06", "17:30", "22:30")),
    KnockoutDefinition(75, .winner("F"), .runnerUp("C"), "Monterrey", schedule("29/06", "22:00", "30/06 03:00")),
    KnockoutDefinition(76, .winner("C"), .runnerUp("F"), "Houston", schedule("29/06", "14:00", "19:00")),
    KnockoutDefinition(77, .winner("I"), .thirdPlace(["C", "D", "F", "G", "H"], 77), "New York/New Jersey", schedule("30/06", "18:00", "23:00")),
    KnockoutDefinition(78, .runnerUp("E"), .runnerUp("I"), "Dallas", schedule("30/06", "14:00", "19:00")),
    KnockoutDefinition(79, .winner("A"), .thirdPlace(["C", "E", "F", "H", "I"], 79), "Ciudad de México", schedule("30/06", "22:00", "01/07 03:00")),
    KnockoutDefinition(80, .winner("L"), .thirdPlace(["E", "H", "I", "J", "K"], 80), "Atlanta", schedule("01/07", "13:00", "18:00")),
    KnockoutDefinition(81, .winner("D"), .thirdPlace(["B", "E", "F", "I", "J"], 81), "San Francisco", schedule("01/07", "21:00", "02/07 02:00")),
    KnockoutDefinition(82, .winner("G"), .thirdPlace(["A", "E", "H", "I", "J"], 82), "Seattle", schedule("01/07", "17:00", "22:00")),
    KnockoutDefinition(83, .runnerUp("K"), .runnerUp("L"), "Toronto", schedule("02/07", "20:00", "03/07 01:00")),
    KnockoutDefinition(84, .winner("H"), .runnerUp("J"), "Los Angeles", schedule("02/07", "16:00", "21:00")),
    KnockoutDefinition(85, .winner("B"), .thirdPlace(["E", "F", "G", "I", "J"], 85), "Vancouver", schedule("03/07", "00:00", "05:00")),
    KnockoutDefinition(86, .winner("J"), .runnerUp("H"), "Miami", schedule("03/07", "19:00", "04/07 00:00")),
    KnockoutDefinition(87, .winner("K"), .thirdPlace(["D", "E", "I", "J", "L"], 87), "Kansas City", schedule("03/07", "22:30", "04/07 03:30")),
    KnockoutDefinition(88, .runnerUp("D"), .runnerUp("G"), "Dallas", schedule("03/07", "15:00", "20:00"))
]

private let thirdPlaceSlots: [ThirdPlaceSlot] = roundOf32Definitions.compactMap { definition in
    if case .thirdPlace(let allowedGroups, let number) = definition.awaySlot {
        return ThirdPlaceSlot(matchNumber: number, allowedGroups: allowedGroups)
    }
    return nil
}

private let groupMatchDefinitions: [String: [GroupMatchDefinition]] = [
    "A": [
        GroupMatchDefinition("mexico", "south_africa", schedule("11/06", "16:00")),
        GroupMatchDefinition("south_korea", "czechia", schedule("11/06", "23:00")),
        GroupMatchDefinition("czechia", "south_africa", schedule("18/06", "13:00")),
        GroupMatchDefinition("mexico", "south_korea", schedule("18/06", "22:00")),
        GroupMatchDefinition("czechia", "mexico", schedule("24/06", "22:00", "25/06 03:00")),
        GroupMatchDefinition("south_africa", "south_korea", schedule("24/06", "22:00", "25/06 03:00"))
    ],
    "B": [
        GroupMatchDefinition("canada", "bosnia", schedule("12/06", "16:00")),
        GroupMatchDefinition("qatar", "switzerland", schedule("13/06", "16:00")),
        GroupMatchDefinition("switzerland", "bosnia", schedule("18/06", "16:00")),
        GroupMatchDefinition("canada", "qatar", schedule("18/06", "19:00")),
        GroupMatchDefinition("switzerland", "canada", schedule("24/06", "16:00", "21:00")),
        GroupMatchDefinition("bosnia", "qatar", schedule("24/06", "16:00", "21:00"))
    ],
    "C": [
        GroupMatchDefinition("brazil", "morocco", schedule("13/06", "19:00")),
        GroupMatchDefinition("haiti", "scotland", schedule("13/06", "22:00")),
        GroupMatchDefinition("scotland", "morocco", schedule("19/06", "19:00")),
        GroupMatchDefinition("brazil", "haiti", schedule("19/06", "21:30")),
        GroupMatchDefinition("scotland", "brazil", schedule("24/06", "19:00", "25/06 00:00")),
        GroupMatchDefinition("morocco", "haiti", schedule("24/06", "19:00", "25/06 00:00"))
    ],
    "D": [
        GroupMatchDefinition("usa", "paraguay", schedule("12/06", "22:00")),
        GroupMatchDefinition("australia", "turkiye", schedule("14/06", "01:00")),
        GroupMatchDefinition("turkiye", "paraguay", schedule("20/06", "00:00")),
        GroupMatchDefinition("usa", "australia", schedule("19/06", "16:00")),
        GroupMatchDefinition("turkiye", "usa", schedule("25/06", "23:00", "26/06 04:00")),
        GroupMatchDefinition("paraguay", "australia", schedule("25/06", "23:00", "26/06 04:00"))
    ],
    "E": [
        GroupMatchDefinition("ivory_coast", "ecuador", schedule("14/06", "20:00")),
        GroupMatchDefinition("germany", "curacao", schedule("14/06", "14:00")),
        GroupMatchDefinition("germany", "ivory_coast", schedule("20/06", "17:00")),
        GroupMatchDefinition("ecuador", "curacao", schedule("20/06", "21:00")),
        GroupMatchDefinition("curacao", "ivory_coast", schedule("25/06", "17:00", "22:00")),
        GroupMatchDefinition("ecuador", "germany", schedule("25/06", "17:00", "22:00"))
    ],
    "F": [
        GroupMatchDefinition("netherlands", "japan", schedule("14/06", "17:00")),
        GroupMatchDefinition("sweden", "tunisia", schedule("14/06", "23:00")),
        GroupMatchDefinition("netherlands", "sweden", schedule("20/06", "14:00")),
        GroupMatchDefinition("tunisia", "japan", schedule("21/06", "01:00")),
        GroupMatchDefinition("japan", "sweden", schedule("25/06", "20:00", "26/06 01:00")),
        GroupMatchDefinition("tunisia", "netherlands", schedule("25/06", "20:00", "26/06 01:00"))
    ],
    "G": [
        GroupMatchDefinition("iran", "new_zealand", schedule("15/06", "22:00")),
        GroupMatchDefinition("belgium", "egypt", schedule("15/06", "16:00")),
        GroupMatchDefinition("belgium", "iran", schedule("21/06", "16:00")),
        GroupMatchDefinition("new_zealand", "egypt", schedule("21/06", "22:00")),
        GroupMatchDefinition("egypt", "iran", schedule("27/06", "00:00", "05:00")),
        GroupMatchDefinition("new_zealand", "belgium", schedule("27/06", "00:00", "05:00"))
    ],
    "H": [
        GroupMatchDefinition("saudi_arabia", "uruguay", schedule("15/06", "19:00")),
        GroupMatchDefinition("spain", "cape_verde", schedule("15/06", "13:00")),
        GroupMatchDefinition("uruguay", "cape_verde", schedule("21/06", "19:00")),
        GroupMatchDefinition("spain", "saudi_arabia", schedule("21/06", "13:00")),
        GroupMatchDefinition("cape_verde", "saudi_arabia", schedule("26/06", "21:00", "27/06 02:00")),
        GroupMatchDefinition("uruguay", "spain", schedule("26/06", "21:00", "27/06 02:00"))
    ],
    "I": [
        GroupMatchDefinition("france", "senegal", schedule("16/06", "16:00")),
        GroupMatchDefinition("iraq", "norway", schedule("16/06", "19:00")),
        GroupMatchDefinition("norway", "senegal", schedule("22/06", "21:00")),
        GroupMatchDefinition("france", "iraq", schedule("22/06", "18:00")),
        GroupMatchDefinition("norway", "france", schedule("26/06", "16:00", "21:00")),
        GroupMatchDefinition("senegal", "iraq", schedule("26/06", "16:00", "21:00"))
    ],
    "J": [
        GroupMatchDefinition("argentina", "algeria", schedule("16/06", "22:00")),
        GroupMatchDefinition("austria", "jordan", schedule("17/06", "01:00")),
        GroupMatchDefinition("argentina", "austria", schedule("22/06", "14:00")),
        GroupMatchDefinition("jordan", "algeria", schedule("23/06", "00:00")),
        GroupMatchDefinition("algeria", "austria", schedule("27/06", "23:00", "28/06 04:00")),
        GroupMatchDefinition("jordan", "argentina", schedule("27/06", "23:00", "28/06 04:00"))
    ],
    "K": [
        GroupMatchDefinition("portugal", "dr_congo", schedule("17/06", "14:00")),
        GroupMatchDefinition("uzbekistan", "colombia", schedule("17/06", "23:00")),
        GroupMatchDefinition("portugal", "uzbekistan", schedule("23/06", "14:00")),
        GroupMatchDefinition("colombia", "dr_congo", schedule("23/06", "23:00")),
        GroupMatchDefinition("colombia", "portugal", schedule("27/06", "20:30", "28/06 01:30")),
        GroupMatchDefinition("dr_congo", "uzbekistan", schedule("27/06", "20:30", "28/06 01:30"))
    ],
    "L": [
        GroupMatchDefinition("ghana", "panama", schedule("17/06", "20:00")),
        GroupMatchDefinition("england", "croatia", schedule("17/06", "17:00")),
        GroupMatchDefinition("england", "ghana", schedule("23/06", "17:00")),
        GroupMatchDefinition("panama", "croatia", schedule("23/06", "20:00")),
        GroupMatchDefinition("panama", "england", schedule("27/06", "18:00", "23:00")),
        GroupMatchDefinition("croatia", "ghana", schedule("27/06", "18:00", "23:00"))
    ]
]

struct FixtureTeam: Identifiable, Hashable {
    let id: String
    let name: String
    let short: String
    let flag: String
    let group: String

    var displayName: String { name.uppercased() }

    func withGroup(_ newGroup: String) -> FixtureTeam {
        FixtureTeam(id: id, name: name, short: short, flag: flag, group: newGroup)
    }
}

struct FixtureGroup: Identifiable {
    let letter: String
    let teams: [FixtureTeam]
    let matches: [FixtureMatch]
    var id: String { letter }
}

struct FixtureMatch: Identifiable {
    let id: String
    let group: String
    let home: FixtureTeam
    let away: FixtureTeam
    let schedule: FixtureScheduleInfo
}

private struct GroupMatchDefinition {
    let homeId: String
    let awayId: String
    let schedule: FixtureScheduleInfo

    init(_ homeId: String, _ awayId: String, _ schedule: FixtureScheduleInfo) {
        self.homeId = homeId
        self.awayId = awayId
        self.schedule = schedule
    }
}

struct FixtureScheduleInfo {
    let dateArgentina: String
    let timeArgentina: String
    let spainText: String?

    var argentinaText: String {
        timeArgentina.isEmpty ? dateArgentina : "\(dateArgentina) · ARG \(timeArgentina)"
    }
}

struct FixtureScore: Equatable {
    var home: Int?
    var away: Int?
    var penaltyWinnerId: String?

    var isEmpty: Bool { home == nil && away == nil && penaltyWinnerId == nil }
    var isComplete: Bool { home != nil && away != nil }
    var isTied: Bool {
        guard let home, let away else { return false }
        return home == away
    }

    mutating func clearPenaltiesIfNeeded() {
        if !isTied {
            penaltyWinnerId = nil
        }
    }
}

struct FixtureStanding {
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
    let schedule: FixtureScheduleInfo

    init(_ number: Int, _ homeSlot: FixtureSlot, _ awaySlot: FixtureSlot, _ venue: String, _ schedule: FixtureScheduleInfo) {
        self.number = number
        self.homeSlot = homeSlot
        self.awaySlot = awaySlot
        self.venue = venue
        self.schedule = schedule
    }
}

private struct WinnerRoundDefinition {
    let number: Int
    let homeSource: Int
    let awaySource: Int
    let venue: String
    let schedule: FixtureScheduleInfo

    init(_ number: Int, _ homeSource: Int, _ awaySource: Int, _ venue: String, _ schedule: FixtureScheduleInfo) {
        self.number = number
        self.homeSource = homeSource
        self.awaySource = awaySource
        self.venue = venue
        self.schedule = schedule
    }
}

private struct ThirdPlaceSlot {
    let matchNumber: Int
    let allowedGroups: [String]
}

struct KnockoutFixtureMatch: Identifiable {
    let number: Int
    let id: String
    let venue: String
    let schedule: FixtureScheduleInfo
    let home: FixtureTeam?
    let away: FixtureTeam?
    let placeholder: String

    func winner(scores: [String: FixtureScore]) -> FixtureTeam? {
        guard let home, let away, let score = scores[id], let homeGoals = score.home, let awayGoals = score.away else {
            return nil
        }
        if homeGoals > awayGoals { return home }
        if awayGoals > homeGoals { return away }
        if score.penaltyWinnerId == home.id { return home }
        if score.penaltyWinnerId == away.id { return away }
        return nil
    }

    func isTied(scores: [String: FixtureScore]) -> Bool {
        scores[id]?.isTied == true
    }
}

struct KnockoutRoundViewModel: Identifiable {
    let title: String
    let matches: [KnockoutFixtureMatch]
    var id: String { title }
}

struct KnockoutBracket {
    let rounds: [KnockoutRoundViewModel]
    let message: String?
}

private func schedule(_ dateArgentina: String, _ timeArgentina: String, _ spainText: String? = nil) -> FixtureScheduleInfo {
    FixtureScheduleInfo(dateArgentina: dateArgentina, timeArgentina: timeArgentina, spainText: spainText)
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
