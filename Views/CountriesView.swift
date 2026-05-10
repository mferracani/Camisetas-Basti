import SwiftUI

struct CountriesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountry: Country?

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
                        Text("ELIGE UN PAÍS")
                            .font(.custom("Nunito-Black", size: min(geo.size.width * 0.034, 42)))
                            .foregroundColor(Color(hex: "#3D2A1F"))
                        Spacer()
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 64, height: 64)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)

                    ScrollView {
                        LazyVGrid(columns: gridColumns(for: geo.size.width), spacing: 28) {
                            ForEach(CAMI_DATA.countries) { country in
                                CountryCard(country: country, width: cardWidth(for: geo.size.width)) {
                                    SoundManager.shared.playTap()
                                    selectedCountry = country
                                }
                            }
                        }
                        .frame(maxWidth: 1180)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 32)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedCountry) { country in
            TeamsView(country: country)
        }
    }
}

struct CountryCard: View {
    let country: Country
    let width: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                FlagView(
                    country: country,
                    width: width,
                    height: width * 0.62,
                    rounded: 12
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                Text(country.name.uppercased())
                    .font(.custom("Nunito-Black", size: 16))
                    .foregroundColor(Color(hex: "#3D2A1F"))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                let teams = CAMI_DATA.teams(for: country.id)
                let completed = countryProgress(for: country)
                ProgressStars(count: completed, total: teams.count * 2, size: 16)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(
                color: Color(hex: "#3D2A1F").opacity(0.08),
                radius: isPressed ? 4 : 0,
                x: 0,
                y: isPressed ? 4 : 12
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

    private func countryProgress(for country: Country) -> Int {
        let store = ProgressStore.shared
        var count = 0
        for team in CAMI_DATA.teams(for: country.id) {
            if store.progress(for: team.id, kit: "home").pct >= 1.0 { count += 1 }
            if store.progress(for: team.id, kit: "away").pct >= 1.0 { count += 1 }
        }
        return count
    }
}

private func gridColumns(for width: CGFloat) -> [GridItem] {
    let count = width >= 1000 ? 3 : 2
    return Array(repeating: GridItem(.flexible(), spacing: 28), count: count)
}

private func cardWidth(for screenWidth: CGFloat) -> CGFloat {
    min(max(screenWidth * 0.16, 150), 220)
}
