import SwiftUI

struct TeamDetailView: View {
    let country: Country
    let team: Team
    @Environment(\.dismiss) private var dismiss
    @State private var showPaint = false
    @State private var selectedKit: String = "home"

    private var homeProgress: ShirtProgress {
        ProgressStore.shared.progress(for: team.id, kit: "home")
    }
    private var awayProgress: ShirtProgress {
        ProgressStore.shared.progress(for: team.id, kit: "away")
    }

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
                        Text(team.name.uppercased())
                            .font(.custom("Nunito-Black", size: min(geo.size.width * 0.032, 40)))
                            .foregroundColor(Color(hex: "#3D2A1F"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Circle().fill(Color.clear).frame(width: 64, height: 64)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)

                    TeamIdentityHeader(country: country, team: team, size: identitySize(for: geo.size))
                        .padding(.top, 12)

                    HStack(spacing: 72) {
                        KitOption(
                            team: team,
                            kit: "home",
                            label: "LOCAL",
                            isSelected: selectedKit == "home",
                            progress: homeProgress,
                            shirtSize: detailShirtSize(for: geo.size)
                        ) {
                            selectedKit = "home"
                            SoundManager.shared.playTap()
                            showPaint = true
                        }

                        KitOption(
                            team: team,
                            kit: "away",
                            label: "VISITANTE",
                            isSelected: selectedKit == "away",
                            progress: awayProgress,
                            shirtSize: detailShirtSize(for: geo.size)
                        ) {
                            selectedKit = "away"
                            SoundManager.shared.playTap()
                            showPaint = true
                        }
                    }
                    .frame(maxWidth: 1100, maxHeight: .infinity)

                    Text("TOCÁ UNA CAMISETA PARA PINTAR")
                        .font(.custom("Nunito-Black", size: 20))
                        .foregroundColor(Color(hex: "#7A4E1B").opacity(0.6))
                        .padding(.bottom, 44)
                }
            }
        }
        .fullScreenCover(isPresented: $showPaint) {
            PaintView(team: team, kit: selectedKit)
        }
    }
}

struct TeamIdentityHeader: View {
    let country: Country
    let team: Team
    let size: CGFloat

    private var isWorldCup: Bool {
        country.id == "wc26"
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)

                if isWorldCup {
                    Text(nationalFlag(for: team))
                        .font(.system(size: size * 0.56))
                } else {
                    CrestView(crest: team.crest, size: size * 0.76)
                }
            }
            .frame(width: size, height: size)

            Text(isWorldCup ? "SELECCIÓN" : "ESCUDO")
                .font(.custom("Nunito-Black", size: 13))
                .foregroundColor(Color(hex: "#7A4E1B").opacity(0.55))
        }
    }
}

struct KitOption: View {
    let team: Team
    let kit: String
    let label: String
    let isSelected: Bool
    let progress: ShirtProgress
    let shirtSize: CGFloat
    let action: () -> Void

    private var isCompleted: Bool { progress.pct >= 1.0 }
    private var isStarted: Bool { progress.revealed > 0 }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    if isCompleted {
                        ShirtView(team: team, kit: kit, size: shirtSize, mode: .color)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#7DDB8B"))
                            .background(Circle().fill(Color.white))
                            .offset(x: 52, y: -52)
                    } else if isStarted {
                        ShirtView(team: team, kit: kit, size: shirtSize, mode: .partial, revealPct: Double(progress.revealed) / Double(progress.total))
                    } else {
                        ShirtView(team: team, kit: kit, size: shirtSize, mode: .gray)
                    }
                }
                .frame(height: shirtSize * 1.2)
                .padding(28)
                .background(isSelected ? Color(hex: "#FFF8E1") : Color.white)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color(hex: "#FF7B3D") : Color.clear, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                .scaleEffect(isSelected ? 1.04 : 1)
                .animation(.easeOut(duration: 0.18), value: isSelected)

                Text(label)
                    .font(.custom("Nunito-Black", size: 20))
                    .foregroundColor(isSelected ? Color(hex: "#FF7B3D") : Color(hex: "#7A4E1B"))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private func detailShirtSize(for size: CGSize) -> CGFloat {
    min(max(size.height * 0.34, 210), 330)
}

private func identitySize(for size: CGSize) -> CGFloat {
    min(max(size.height * 0.11, 72), 110)
}
