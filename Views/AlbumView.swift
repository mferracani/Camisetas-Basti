import SwiftUI

struct AlbumView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountry: Country = CAMI_DATA.countries[0]
    @State private var selectedTeam: Team?
    @State private var selectedKit: String?
    
    private var countries: [Country] { CAMI_DATA.countries }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
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
                    Text("ÁLBUM")
                        .font(.custom("Nunito-Black", size: 28))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    Spacer()
                    Circle().fill(Color.clear).frame(width: 64, height: 64)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Country tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(countries) { country in
                            CountryTab(
                                country: country,
                                isSelected: selectedCountry.id == country.id
                            ) {
                                SoundManager.shared.playTap()
                                selectedCountry = country
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                
                // Stats
                HStack(spacing: 8) {
                    let teams = CAMI_DATA.teams(for: selectedCountry.id)
                    let total = teams.count * 2
                    let completed = countryProgress(for: selectedCountry)
                    ProgressStars(count: completed, total: total, size: 20)
                    Text("\(completed)/\(total)")
                        .font(.custom("Nunito-Black", size: 16))
                        .foregroundColor(Color(hex: "#7A4E1B"))
                }
                .padding(.bottom, 8)
                
                // Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(CAMI_DATA.teams(for: selectedCountry.id)) { team in
                            ForEach(["home", "away"], id: \.self) { kit in
                                AlbumCell(
                                    team: team,
                                    kit: kit,
                                    progress: ProgressStore.shared.progress(for: team.id, kit: kit)
                                ) {
                                    SoundManager.shared.playTap()
                                    selectedTeam = team
                                    selectedKit = kit
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .fullScreenCover(item: $selectedTeam) { team in
            if let kit = selectedKit {
                PaintView(team: team, kit: kit)
            }
        }
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

struct CountryTab: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(country.flag)
                    .font(.system(size: 20))
                Text(country.name.uppercased())
                    .font(.custom("Nunito-Black", size: 14))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#3D2A1F"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "#FF7B3D") : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
