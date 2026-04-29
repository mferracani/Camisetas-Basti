import SwiftUI

struct BigKidButton: View {
    enum Variant {
        case primary, secondary, sun, sky, grass
        
        var bg: Color {
            switch self {
            case .primary: return Color(hex: "#FF7B3D")
            case .secondary: return .white
            case .sun: return Color(hex: "#FFC93C")
            case .sky: return Color(hex: "#6BCBFF")
            case .grass: return Color(hex: "#7DDB8B")
            }
        }
        
        var fg: Color {
            switch self {
            case .secondary: return Color(hex: "#3D2A1F")
            default: return .white
            }
        }
        
        var shadowColor: Color {
            switch self {
            case .primary: return Color(hex: "#FF7B3D").opacity(0.4)
            case .secondary: return Color(hex: "#3D2A1F").opacity(0.12)
            case .sun: return Color(hex: "#E89F00").opacity(0.35)
            case .sky: return Color(hex: "#6BCBFF").opacity(0.4)
            case .grass: return Color(hex: "#7DDB8B").opacity(0.4)
            }
        }
    }
    
    enum Size {
        case sm, md, lg
        
        var padY: CGFloat {
            switch self { case .sm: return 14; case .md: return 18; case .lg: return 24 }
        }
        var padX: CGFloat {
            switch self { case .sm: return 22; case .md: return 28; case .lg: return 36 }
        }
        var fontSize: CGFloat {
            switch self { case .sm: return 16; case .md: return 22; case .lg: return 28 }
        }
        var minH: CGFloat {
            switch self { case .sm: return 56; case .md: return 80; case .lg: return 104 }
        }
    }
    
    let title: String
    let icon: String?
    let variant: Variant
    let size: Size
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            SoundManager.shared.playTap()
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: size.fontSize * 1.2))
                }
                Text(title)
                    .font(.custom("Nunito-Black", size: size.fontSize))
                    .tracking(0.5)
            }
            .foregroundColor(variant.fg)
            .padding(.vertical, size.padY)
            .padding(.horizontal, size.padX)
            .frame(minHeight: size.minH)
            .background(variant.bg)
            .cornerRadius(28)
            .shadow(
                color: variant.shadowColor,
                radius: isPressed ? 4 : 0,
                x: 0,
                y: isPressed ? 4 : 8
            )
            .shadow(
                color: variant.shadowColor.opacity(0.5),
                radius: isPressed ? 6 : 12,
                x: 0,
                y: isPressed ? 6 : 24
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
