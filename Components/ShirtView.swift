import SwiftUI

enum ShirtMode {
    case color, gray, partial
}

struct ShirtView: View {
    let team: Team
    let kit: String
    let size: CGFloat
    let mode: ShirtMode
    var revealPct: Double = 0
    
    private var kitData: Kit {
        kit == "away" ? team.away : team.home
    }
    
    private var aspectRatio: CGFloat { 280.0 / 240.0 }
    
    var body: some View {
        let height = size * aspectRatio
        ZStack {
            // Base layer
            if mode == .gray {
                grayShirt
            } else if mode == .partial {
                grayShirt
                PatternFill(pattern: kitData.pattern, colors: kitData.colors, size: size)
                    .clipShape(ShirtShape())
                    .mask(partialMask)
            } else {
                PatternFill(pattern: kitData.pattern, colors: kitData.colors, size: size)
                    .clipShape(ShirtShape())
            }
            
            // Costuras laterales (sutiles)
            if mode != .gray {
                SideSeams(size: size, height: height)
            }
            
            // Dobladillo
            BottomHem(size: size, height: height, mode: mode, kitData: kitData, kit: kit)
            
            // Puños de manga
            SleeveCuffs(size: size, height: height, mode: mode, kitData: kitData, kit: kit)
            
            // Crest (solo en color mode, o partial si > 50%)
            if mode == .color || (mode == .partial && revealPct > 0.5) {
                CrestView(crest: team.crest, size: size * 0.18)
                    .position(x: size * 0.625, y: height * 0.38)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .opacity(mode == .partial ? min(1, (revealPct - 0.5) / 0.3) : 1)
            }
            
            // Cuello con ribete
            if mode == .color || (mode == .partial && revealPct > 0.3) {
                CollarDetail(size: size, height: height, kitData: kitData, kit: kit, mode: mode)
                    .opacity(mode == .partial ? min(1, revealPct / 0.3) : 1)
            }
            
            // Outline principal
            ShirtShape()
                .stroke(mode == .gray ? Color.black.opacity(0.12) : Color.black.opacity(0.15), lineWidth: 1.2)
                .frame(width: size, height: height)
            
            // Sombra sutil para profundidad
            if mode != .gray {
                ShirtShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.clear, Color.black.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size, height: height)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: height)
    }
    
    private var grayShirt: some View {
        ShirtShape()
            .fill(Color(hex: "#D9D5CE"))
            .frame(width: size, height: size * aspectRatio)
    }
    
    private var partialMask: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Rectangle().fill(Color.black)
                RevealBlobs(pct: revealPct, w: w, h: h)
                    .fill(Color.white)
            }
        }
    }
}

// MARK: - Shirt Shape

struct ShirtShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 240
        let scaleY = rect.height / 280
        var transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        transform = transform.translatedBy(x: rect.minX / scaleX, y: rect.minY / scaleY)
        return ShirtPath.master.applying(transform)
    }
}

// MARK: - Collar Detail

struct CollarDetail: View {
    let size: CGFloat
    let height: CGFloat
    let kitData: Kit
    let kit: String
    let mode: ShirtMode
    
    var body: some View {
        ZStack {
            // Cuello base
            CollarShape()
                .fill(mode == .gray ? Color(hex: "#C8C3B9") : collarColor)
            
            // Ribete del cuello
            CollarShape()
                .stroke(
                    mode == .gray ? Color(hex: "#B0ABA0") : ribeteColor,
                    lineWidth: 1.5
                )
            
            // Interior del cuello (línea más fina)
            InnerCollarShape()
                .stroke(
                    mode == .gray ? Color(hex: "#B0ABA0") : ribeteColor.opacity(0.7),
                    lineWidth: 0.8
                )
        }
        .frame(width: size, height: height)
    }
    
    private var collarColor: Color {
        Color(hex: kitData.colors[kit == "home" ? min(1, kitData.colors.count - 1) : 0])
    }
    
    private var ribeteColor: Color {
        if kitData.colors.count > 1 {
            return Color(hex: kitData.colors[kit == "home" ? 0 : min(1, kitData.colors.count - 1)])
        }
        return Color(hex: kitData.colors[0]).opacity(0.7)
    }
}

struct CollarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 240
        let scaleY = rect.height / 280
        var path = Path()
        
        let sx = scaleX
        let sy = scaleY
        
        path.move(to: CGPoint(x: 92 * sx, y: 18 * sy))
        path.addCurve(
            to: CGPoint(x: 105 * sx, y: 14 * sy),
            control1: CGPoint(x: 96 * sx, y: 16 * sy),
            control2: CGPoint(x: 100 * sx, y: 14 * sy)
        )
        path.addLine(to: CGPoint(x: 135 * sx, y: 14 * sy))
        path.addCurve(
            to: CGPoint(x: 148 * sx, y: 18 * sy),
            control1: CGPoint(x: 140 * sx, y: 14 * sy),
            control2: CGPoint(x: 144 * sx, y: 16 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 120 * sx, y: 28 * sy),
            control1: CGPoint(x: 140 * sx, y: 22 * sy),
            control2: CGPoint(x: 132 * sx, y: 28 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 92 * sx, y: 18 * sy),
            control1: CGPoint(x: 108 * sx, y: 28 * sy),
            control2: CGPoint(x: 100 * sx, y: 22 * sy)
        )
        path.closeSubpath()
        return path
    }
}

struct InnerCollarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 240
        let scaleY = rect.height / 280
        var path = Path()
        
        let sx = scaleX
        let sy = scaleY
        
        path.move(to: CGPoint(x: 98 * sx, y: 18 * sy))
        path.addCurve(
            to: CGPoint(x: 108 * sx, y: 16 * sy),
            control1: CGPoint(x: 102 * sx, y: 17 * sy),
            control2: CGPoint(x: 105 * sx, y: 16 * sy)
        )
        path.addLine(to: CGPoint(x: 132 * sx, y: 16 * sy))
        path.addCurve(
            to: CGPoint(x: 142 * sx, y: 18 * sy),
            control1: CGPoint(x: 135 * sx, y: 16 * sy),
            control2: CGPoint(x: 138 * sx, y: 17 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 120 * sx, y: 24 * sy),
            control1: CGPoint(x: 136 * sx, y: 20 * sy),
            control2: CGPoint(x: 128 * sx, y: 24 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 98 * sx, y: 18 * sy),
            control1: CGPoint(x: 112 * sx, y: 24 * sy),
            control2: CGPoint(x: 104 * sx, y: 20 * sy)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Side Seams

struct SideSeams: View {
    let size: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Costura derecha
            Path { path in
                let sx = size / 240
                let sy = height / 280
                path.move(to: CGPoint(x: 178 * sx, y: 120 * sy))
                path.addCurve(
                    to: CGPoint(x: 172 * sx, y: 248 * sy),
                    control1: CGPoint(x: 182 * sx, y: 155 * sy),
                    control2: CGPoint(x: 174 * sx, y: 238 * sy)
                )
            }
            .stroke(Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))
            
            // Costura izquierda
            Path { path in
                let sx = size / 240
                let sy = height / 280
                path.move(to: CGPoint(x: 62 * sx, y: 120 * sy))
                path.addCurve(
                    to: CGPoint(x: 68 * sx, y: 248 * sy),
                    control1: CGPoint(x: 58 * sx, y: 155 * sy),
                    control2: CGPoint(x: 66 * sx, y: 238 * sy)
                )
            }
            .stroke(Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))
        }
    }
}

// MARK: - Bottom Hem

struct BottomHem: View {
    let size: CGFloat
    let height: CGFloat
    let mode: ShirtMode
    let kitData: Kit
    let kit: String
    
    var body: some View {
        Path { path in
            let sx = size / 240
            let sy = height / 280
            path.move(to: CGPoint(x: 68 * sx, y: 248 * sy))
            path.addCurve(
                to: CGPoint(x: 78 * sx, y: 268 * sy),
                control1: CGPoint(x: 70 * sx, y: 260 * sy),
                control2: CGPoint(x: 74 * sx, y: 266 * sy)
            )
            path.addLine(to: CGPoint(x: 162 * sx, y: 268 * sy))
            path.addCurve(
                to: CGPoint(x: 172 * sx, y: 248 * sy),
                control1: CGPoint(x: 166 * sx, y: 266 * sy),
                control2: CGPoint(x: 170 * sx, y: 260 * sy)
            )
        }
        .stroke(
            mode == .gray ? Color(hex: "#B0ABA0") : hemColor,
            lineWidth: 1.5
        )
    }
    
    private var hemColor: Color {
        if kitData.colors.count > 1 {
            return Color(hex: kitData.colors[kit == "home" ? min(1, kitData.colors.count - 1) : 0])
        }
        return Color(hex: kitData.colors[0]).opacity(0.7)
    }
}

// MARK: - Sleeve Cuffs

struct SleeveCuffs: View {
    let size: CGFloat
    let height: CGFloat
    let mode: ShirtMode
    let kitData: Kit
    let kit: String
    
    var body: some View {
        ZStack {
            // Puño manga izquierda
            Path { path in
                let sx = size / 240
                let sy = height / 280
                path.move(to: CGPoint(x: 25 * sx, y: 82 * sy))
                path.addCurve(
                    to: CGPoint(x: 20 * sx, y: 58 * sy),
                    control1: CGPoint(x: 21 * sx, y: 76 * sy),
                    control2: CGPoint(x: 18 * sx, y: 68 * sy)
                )
            }
            .stroke(
                mode == .gray ? Color(hex: "#B0ABA0") : cuffColor,
                lineWidth: 2
            )
            
            // Puño manga derecha
            Path { path in
                let sx = size / 240
                let sy = height / 280
                path.move(to: CGPoint(x: 215 * sx, y: 82 * sy))
                path.addCurve(
                    to: CGPoint(x: 220 * sx, y: 58 * sy),
                    control1: CGPoint(x: 219 * sx, y: 76 * sy),
                    control2: CGPoint(x: 222 * sx, y: 68 * sy)
                )
            }
            .stroke(
                mode == .gray ? Color(hex: "#B0ABA0") : cuffColor,
                lineWidth: 2
            )
        }
    }
    
    private var cuffColor: Color {
        if kitData.colors.count > 1 {
            return Color(hex: kitData.colors[kit == "home" ? min(1, kitData.colors.count - 1) : 0])
        }
        return Color(hex: kitData.colors[0]).opacity(0.7)
    }
}

// MARK: - Reveal Mask

struct RevealBlobs: Shape {
    let pct: Double
    let w: CGFloat
    let h: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let total = 28
        let visible = Int(Double(total) * pct)
        for i in 0..<visible {
            let cx = 30 + rand(i) * 180
            let cy = 30 + rand(i + 100) * 220
            let r = 28 + rand(i + 200) * 18
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }
        return path
    }
    
    private func rand(_ n: Int) -> CGFloat {
        let seed = 42
        let x = sin(Double(seed + n) * 13.37) * 10000
        return CGFloat(x - floor(x))
    }
}

// MARK: - Pattern Fill

struct PatternFill: View {
    let pattern: Pattern
    let colors: [String]
    let size: CGFloat
    
    private var c1: Color { Color(hex: colors[0]) }
    private var c2: Color { colors.count > 1 ? Color(hex: colors[1]) : c1 }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                switch pattern {
                case .solid:
                    c1
                    
                case .stripesV:
                    HStack(spacing: 0) {
                        ForEach(0..<Int(w/22)+1, id: \.self) { i in
                            Rectangle()
                                .fill(i % 2 == 0 ? c1 : c2)
                                .frame(width: 22)
                        }
                    }
                    
                case .stripesH, .hoops:
                    VStack(spacing: 0) {
                        ForEach(0..<Int(h/24)+1, id: \.self) { i in
                            Rectangle()
                                .fill(i % 2 == 0 ? c1 : c2)
                                .frame(height: 24)
                        }
                    }
                    
                case .splitV:
                    HStack(spacing: 0) {
                        Rectangle().fill(c1)
                        Rectangle().fill(c2)
                    }
                    
                case .splitD:
                    ZStack {
                        c1
                        Triangle()
                            .fill(c2)
                    }
                    
                case .sashD:
                    ZStack {
                        c1
                        SashD()
                            .fill(c2)
                    }
                    
                case .sashH, .sashHThick, .sashHThin:
                    ZStack {
                        c1
                        let bandH: CGFloat = pattern == .sashHThin ? 36 : (pattern == .sashHThick ? 68 : 56)
                        let bandY: CGFloat = pattern == .sashHThin ? 110 : (pattern == .sashHThick ? 80 : 100)
                        Rectangle()
                            .fill(c2)
                            .frame(height: bandH)
                            .position(x: w/2, y: bandY)
                    }
                    
                case .sashV:
                    ZStack {
                        c1
                        SashV()
                            .fill(c2)
                    }
                    
                case .sashVFat:
                    ZStack {
                        c1
                        Rectangle()
                            .fill(c2)
                            .frame(width: 56)
                            .position(x: w/2, y: h/2)
                    }
                    
                case .sleevesW:
                    c1
                    
                case .splitVBlueClaret:
                    ZStack {
                        c1
                        Rectangle()
                            .fill(c2)
                            .frame(width: 68)
                            .position(x: w * 0.358, y: h/2)
                    }
                }
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SashD: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 20, y: 260))
        path.addLine(to: CGPoint(x: 60, y: 260))
        path.addLine(to: CGPoint(x: 220, y: 40))
        path.addLine(to: CGPoint(x: 180, y: 40))
        path.closeSubpath()
        return path
    }
}

struct SashV: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 48, y: 16))
        path.addLine(to: CGPoint(x: 108, y: 16))
        path.addLine(to: CGPoint(x: 168, y: 260))
        path.addLine(to: CGPoint(x: 108, y: 260))
        path.closeSubpath()
        return path
    }
}
