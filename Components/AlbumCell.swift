import SwiftUI

struct AlbumCell: View {
    let team: Team
    let kit: String
    let progress: ShirtProgress
    let onTap: () -> Void
    
    private var isCompleted: Bool { progress.pct >= 1.0 }
    private var isStarted: Bool { progress.revealed > 0 }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    if isCompleted {
                        ShirtView(team: team, kit: kit, size: 96, mode: .color)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "#7DDB8B"))
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 36, y: -36)
                            )
                    } else if isStarted {
                        ShirtView(team: team, kit: kit, size: 96, mode: .partial, revealPct: Double(progress.revealed) / Double(progress.total))
                    } else {
                        ShirtView(team: team, kit: kit, size: 96, mode: .gray)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: "#7A4E1B").opacity(0.4))
                            )
                    }
                }
                .frame(height: 112)
                
                Text(team.name.uppercased())
                    .font(.custom("Nunito-Bold", size: 11))
                    .foregroundColor(isCompleted ? Color(hex: "#3D2A1F") : Color(hex: "#7A4E1B").opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(height: 28)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isCompleted ? Color(hex: "#FFF8E1") : Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
