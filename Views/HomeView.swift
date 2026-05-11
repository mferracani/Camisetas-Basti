import SwiftUI

struct HomeView: View {
    @State private var showAlbum = false
    @State private var showGames = false
    @State private var showCountries = false
    @State private var showTournament = false
    @State private var trophyBounce = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#FEF9E7").ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            SoundManager.shared.playTap()
                            showGames = true
                        }) {
                            Text("🏆")
                                .font(.system(size: 42))
                                .frame(width: 72, height: 72)
                                .background(Circle().fill(Color.white))
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                .scaleEffect(trophyBounce ? 1.15 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                trophyBounce = true
                            }
                        }
                    }
                    .padding(.horizontal, 44)
                    .padding(.top, 24)

                    HStack(spacing: 64) {
                        ShirtView(
                            team: Team(
                                id: "home-preview",
                                name: "",
                                short: "",
                                home: Kit(pattern: .stripesV, colors: ["#75AADB", "#FFFFFF"]),
                                away: Kit(pattern: .solid, colors: ["#2C3E50"]),
                                crest: Crest(shape: .round, text: "CB", colors: ["#FFC93C", "#3D2A1F"])
                            ),
                            kit: "home",
                            size: min(geo.size.height * 0.42, 340),
                            mode: .color
                        )
                        .shadow(color: Color(hex: "#3D2A1F").opacity(0.14), radius: 24, x: 0, y: 18)

                        VStack(alignment: .leading, spacing: 32) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("CAMISETAS")
                                    .font(.custom("Nunito-Black", size: min(geo.size.width * 0.055, 76)))
                                    .foregroundColor(Color(hex: "#3D2A1F"))
                                Text("BASTI")
                                    .font(.custom("Nunito-Black", size: min(geo.size.width * 0.055, 76)))
                                    .foregroundColor(Color(hex: "#FF7B3D"))
                            }

                            VStack(alignment: .leading, spacing: 22) {
                                BigKidButton(
                                    title: "JUGAR",
                                    icon: "🎨",
                                    variant: .primary,
                                    size: .lg,
                                    action: {
                                        SoundManager.shared.playTap()
                                        showCountries = true
                                    }
                                )

                                BigKidButton(
                                    title: "ÁLBUM",
                                    icon: "📘",
                                    variant: .secondary,
                                    size: .md,
                                    action: {
                                        SoundManager.shared.playTap()
                                        showAlbum = true
                                    }
                                )

                                BigKidButton(
                                    title: "SIMULAR TORNEO",
                                    icon: "🏆",
                                    variant: .sky,
                                    size: .md,
                                    action: {
                                        SoundManager.shared.playTap()
                                        showTournament = true
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: 1100, maxHeight: .infinity)
                    .padding(.horizontal, 56)
                    .padding(.bottom, 72)
                }
            }
        }
        .fullScreenCover(isPresented: $showCountries) {
            CountriesView()
        }
        .fullScreenCover(isPresented: $showAlbum) {
            AlbumView()
        }
        .fullScreenCover(isPresented: $showGames) {
            GamesView()
        }
        .fullScreenCover(isPresented: $showTournament) {
            TournamentSimulatorView()
        }
    }
}
