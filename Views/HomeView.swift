import SwiftUI

struct HomeView: View {
    @State private var showAlbum = false
    @State private var showGames = false
    @State private var showCountries = false
    @State private var trophyBounce = false
    
    var body: some View {
        ZStack {
            Color(hex: "#FEF9E7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: {
                        SoundManager.shared.playTap()
                        showGames = true
                    }) {
                        Text("🏆")
                            .font(.system(size: 40))
                            .frame(width: 64, height: 64)
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
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Title
                VStack(spacing: 4) {
                    Text("CAMISETAS")
                        .font(.custom("Nunito-Black", size: 56))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    Text("BASTI")
                        .font(.custom("Nunito-Black", size: 56))
                        .foregroundColor(Color(hex: "#FF7B3D"))
                }
                .padding(.bottom, 60)
                
                // Buttons
                VStack(spacing: 24) {
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
                }
                
                Spacer()
                Spacer()
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
    }
}
