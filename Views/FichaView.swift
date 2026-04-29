import SwiftUI

struct FichaView: View {
    let team: Team
    let kit: String
    let onFinish: () -> Void
    @State private var showContent = false
    @State private var showConfetti = false
    
    private var kitData: Kit { kit == "away" ? team.away : team.home }
    private var colorName: String { ColorName.spanishName(for: kitData.colors[0]) }
    private var kitLabel: String { kit == "home" ? "LOCAL" : "VISITANTE" }
    
    var body: some View {
        ZStack {
            Color(hex: "#FEF9E7").ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success message
                VStack(spacing: 8) {
                    Text("¡GENIAL!")
                        .font(.custom("Nunito-Black", size: 48))
                        .foregroundColor(Color(hex: "#FF7B3D"))
                    
                    Text("DESCUBRISTE LA CAMISETA")
                        .font(.custom("Nunito-Black", size: 20))
                        .foregroundColor(Color(hex: "#7A4E1B"))
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Shirt
                ShirtView(team: team, kit: kit, size: 200, mode: .color)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .rotationEffect(.degrees(showContent ? 0 : -10))
                
                // Info card
                VStack(spacing: 16) {
                    Text(team.name.uppercased())
                        .font(.custom("Nunito-Black", size: 28))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    
                    HStack(spacing: 24) {
                        InfoPill(label: "KIT", value: kitLabel)
                        InfoPill(label: "COLOR", value: colorName.uppercased())
                    }
                    
                    Text(team.id.uppercased())
                        .font(.custom("Nunito-Black", size: 14))
                        .foregroundColor(Color(hex: "#7A4E1B").opacity(0.5))
                        .padding(.top, 4)
                }
                .padding(28)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                Spacer()
                
                // Continue button
                BigKidButton(
                    title: "SEGUIR",
                    icon: "👍",
                    variant: .primary,
                    size: .lg,
                    action: {
                        SoundManager.shared.playTap()
                        onFinish()
                    }
                )
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
            .padding(.horizontal, 32)
            
            // Confetti
            ConfettiView(trigger: $showConfetti)
                .allowsHitTesting(false)
        }
        .onAppear {
            SoundManager.shared.playSuccess()
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showConfetti = true
            }
        }
    }
}

struct InfoPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.custom("Nunito-Bold", size: 12))
                .foregroundColor(Color(hex: "#7A4E1B").opacity(0.6))
            Text(value)
                .font(.custom("Nunito-Black", size: 16))
                .foregroundColor(Color(hex: "#3D2A1F"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#F5F0E6"))
        .cornerRadius(12)
    }
}
