import SwiftUI

struct GamesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGame: GameType?
    
    enum GameType: String, Identifiable {
        case guess = "guess"
        case memory = "memory"
        var id: String { rawValue }
    }
    
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
                    Text("JUEGOS")
                        .font(.custom("Nunito-Black", size: 28))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    Spacer()
                    Circle().fill(Color.clear).frame(width: 64, height: 64)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                VStack(spacing: 32) {
                    GameCard(
                        icon: "🔍",
                        title: "ADIVINA",
                        subtitle: "¿DE QUÉ EQUIPO ES?",
                        color: .sky
                    ) {
                        SoundManager.shared.playTap()
                        selectedGame = .guess
                    }
                    
                    GameCard(
                        icon: "🧠",
                        title: "MEMORIA",
                        subtitle: "EMPAREJA LAS CAMISETAS",
                        color: .grass
                    ) {
                        SoundManager.shared.playTap()
                        selectedGame = .memory
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .fullScreenCover(item: $selectedGame) { game in
            switch game {
            case .guess:
                GuessGameView()
            case .memory:
                MemoryGameView()
            }
        }
    }
}

struct GameCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: BigKidButton.Variant
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Text(icon)
                    .font(.system(size: 48))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Nunito-Black", size: 24))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.custom("Nunito-Bold", size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [color.bg, color.bg.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(24)
            .shadow(
                color: color.bg.opacity(0.4),
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
}

// MARK: - Placeholder game views
struct GuessGameView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "#FEF9E7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    BackButton { dismiss() }
                    Spacer()
                    Text("ADIVINA")
                        .font(.custom("Nunito-Black", size: 28))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    Spacer()
                    Circle().fill(Color.clear).frame(width: 64, height: 64)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                Text("PRÓXIMAMENTE")
                    .font(.custom("Nunito-Black", size: 32))
                    .foregroundColor(Color(hex: "#7A4E1B").opacity(0.5))
                
                Spacer()
            }
        }
    }
}

struct MemoryGameView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "#FEF9E7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    BackButton { dismiss() }
                    Spacer()
                    Text("MEMORIA")
                        .font(.custom("Nunito-Black", size: 28))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    Spacer()
                    Circle().fill(Color.clear).frame(width: 64, height: 64)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                Text("PRÓXIMAMENTE")
                    .font(.custom("Nunito-Black", size: 32))
                    .foregroundColor(Color(hex: "#7A4E1B").opacity(0.5))
                
                Spacer()
            }
        }
    }
}
