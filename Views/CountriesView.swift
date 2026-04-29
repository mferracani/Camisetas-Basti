import SwiftUI

struct CountriesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountry: Country?
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "#FEF9E7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackButton {
                        dismiss()
                    }
                    Spacer()
                    Text("ELIGE UN PAÍS")
                        .font(.custom("Nunito-Black", size: 28))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    Spacer()
                    // Spacer para balancear el back button
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 64, height: 64)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(CAMI_DATA.countries) { country in
                            CountryCard(country: country) {
                                SoundManager.shared.playTap()
                                selectedCountry = country
                            }
                        }
                    }
                    .padding(24)
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
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                FlagView(
                    country: country,
                    width: 100,
                    height: 70,
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
