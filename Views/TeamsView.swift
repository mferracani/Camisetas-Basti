import SwiftUI

struct TeamsView: View {
    let country: Country
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeam: Team?
    @State private var selectedKit: String?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#FEF9E7").ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        BackButton {
                            dismiss()
                        }
                        Spacer()
                        Text(country.name.uppercased())
                            .font(.custom("Nunito-Black", size: min(geo.size.width * 0.034, 42)))
                            .foregroundColor(Color(hex: "#3D2A1F"))
                        Spacer()
                        Circle().fill(Color.clear).frame(width: 64, height: 64)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)

                    ScrollView {
                        LazyVGrid(columns: teamGridColumns(for: geo.size.width), spacing: 24) {
                            ForEach(CAMI_DATA.teams(for: country.id)) { team in
                                TeamCard(country: country, team: team, shirtSize: teamShirtSize(for: geo.size.width)) {
                                    SoundManager.shared.playTap()
                                    selectedTeam = team
                                }
                            }
                        }
                        .frame(maxWidth: 1180)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 30)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedTeam) { team in
            TeamDetailView(country: country, team: team)
        }
    }
}

struct TeamCard: View {
    let country: Country
    let team: Team
    let shirtSize: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    private var homeCompleted: Bool {
        ProgressStore.shared.progress(for: team.id, kit: "home").pct >= 1.0
    }
    private var awayCompleted: Bool {
        ProgressStore.shared.progress(for: team.id, kit: "away").pct >= 1.0
    }
    private var isWorldCup: Bool {
        country.id == "wc26"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if homeCompleted {
                        ShirtView(team: team, kit: "home", size: shirtSize, mode: .color)
                    } else {
                        ShirtView(team: team, kit: "home", size: shirtSize, mode: .gray)
                    }

                    // Kit indicator dots
                    HStack(spacing: 6) {
                        Circle()
                            .fill(homeCompleted ? Color(hex: "#7DDB8B") : Color(hex: "#D9D5CE"))
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        Circle()
                            .fill(awayCompleted ? Color(hex: "#7DDB8B") : Color(hex: "#D9D5CE"))
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                    .offset(y: shirtSize * 0.58)

                    teamBadge
                        .offset(x: shirtSize * 0.42, y: -shirtSize * 0.42)
                }
                .frame(height: shirtSize * 1.22)

                Text(team.name.uppercased())
                    .font(.custom("Nunito-Bold", size: 12))
                    .foregroundColor(Color(hex: "#3D2A1F"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(height: 32)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(
                color: Color.black.opacity(0.06),
                radius: isPressed ? 4 : 0,
                x: 0,
                y: isPressed ? 4 : 8
            )
            .offset(y: isPressed ? 4 : 0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var teamBadge: some View {
        if isWorldCup {
            Text(nationalFlag(for: team))
                .font(.system(size: max(30, shirtSize * 0.32)))
                .frame(width: shirtSize * 0.42, height: shirtSize * 0.42)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Color(hex: "#E8E4DB"), lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 3)
        } else {
            CrestView(crest: team.crest, size: shirtSize * 0.46)
                .padding(shirtSize * 0.05)
                .background(Circle().fill(Color.white))
                .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 3)
        }
    }
}

private func teamGridColumns(for width: CGFloat) -> [GridItem] {
    let count = width >= 1200 ? 5 : width >= 900 ? 4 : 3
    return Array(repeating: GridItem(.flexible(), spacing: 24), count: count)
}

private func teamShirtSize(for width: CGFloat) -> CGFloat {
    min(max(width * 0.085, 92), 132)
}

func nationalFlag(for team: Team) -> String {
    switch team.id {
    case "sel_argentina": return "🇦🇷"
    case "sel_brazil": return "🇧🇷"
    case "sel_uruguay": return "🇺🇾"
    case "sel_mexico": return "🇲🇽"
    case "sel_usa": return "🇺🇸"
    case "sel_saudi_arabia": return "🇸🇦"
    case "sel_algeria": return "🇩🇿"
    case "sel_australia": return "🇦🇺"
    case "sel_austria": return "🇦🇹"
    case "sel_spain": return "🇪🇸"
    case "sel_england": return "🏴"
    case "sel_france": return "🇫🇷"
    case "sel_germany": return "🇩🇪"
    case "sel_italy": return "🇮🇹"
    case "sel_south_korea": return "🇰🇷"
    case "sel_bosnia": return "🇧🇦"
    case "sel_cape_verde": return "🇨🇻"
    case "sel_canada": return "🇨🇦"
    case "sel_colombia": return "🇨🇴"
    case "sel_curacao": return "🇨🇼"
    case "sel_egypt": return "🇪🇬"
    case "sel_ecuador": return "🇪🇨"
    case "sel_ghana": return "🇬🇭"
    case "sel_japan": return "🇯🇵"
    case "sel_jordan": return "🇯🇴"
    case "sel_netherlands": return "🇳🇱"
    case "sel_croatia": return "🇭🇷"
    case "sel_belgium": return "🇧🇪"
    case "sel_portugal": return "🇵🇹"
    default: return "🏳️"
    }
}
