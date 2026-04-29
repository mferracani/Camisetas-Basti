import SwiftUI

struct TeamDetailView: View {
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
        ZStack {
            Color(hex: "#FEF9E7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackButton {
                        dismiss()
                    }
                    Spacer()
                    Text(team.name.uppercased())
                        .font(.custom("Nunito-Black", size: 26))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Circle().fill(Color.clear).frame(width: 64, height: 64)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Shirt selector
                HStack(spacing: 60) {
                    KitOption(
                        team: team,
                        kit: "home",
                        label: "LOCAL",
                        isSelected: selectedKit == "home",
                        progress: homeProgress
                    ) {
                        selectedKit = "home"
                        SoundManager.shared.playTap()
                    }
                    
                    KitOption(
                        team: team,
                        kit: "away",
                        label: "VISITANTE",
                        isSelected: selectedKit == "away",
                        progress: awayProgress
                    ) {
                        selectedKit = "away"
                        SoundManager.shared.playTap()
                    }
                }
                
                Spacer()
                
                // Paint button
                BigKidButton(
                    title: "PINTAR",
                    icon: "🖌️",
                    variant: .primary,
                    size: .lg,
                    action: {
                        SoundManager.shared.playTap()
                        showPaint = true
                    }
                )
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showPaint) {
            PaintView(team: team, kit: selectedKit)
        }
    }
}

struct KitOption: View {
    let team: Team
    let kit: String
    let label: String
    let isSelected: Bool
    let progress: ShirtProgress
    let action: () -> Void
    
    private var isCompleted: Bool { progress.pct >= 1.0 }
    private var isStarted: Bool { progress.revealed > 0 }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    if isCompleted {
                        ShirtView(team: team, kit: kit, size: 140, mode: .color)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#7DDB8B"))
                            .background(Circle().fill(Color.white))
                            .offset(x: 52, y: -52)
                    } else if isStarted {
                        ShirtView(team: team, kit: kit, size: 140, mode: .partial, revealPct: Double(progress.revealed) / Double(progress.total))
                    } else {
                        ShirtView(team: team, kit: kit, size: 140, mode: .gray)
                    }
                }
                .frame(height: 164)
                .padding(20)
                .background(isSelected ? Color(hex: "#FFF8E1") : Color.white)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color(hex: "#FF7B3D") : Color.clear, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                
                Text(label)
                    .font(.custom("Nunito-Black", size: 20))
                    .foregroundColor(isSelected ? Color(hex: "#FF7B3D") : Color(hex: "#7A4E1B"))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
