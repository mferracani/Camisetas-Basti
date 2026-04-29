import SwiftUI

struct CrestView: View {
    let crest: Crest
    let size: CGFloat
    
    var body: some View {
        let fill = Color(hex: crest.colors[0])
        let stroke = Color(hex: crest.colors[1])
        
        ZStack {
            switch crest.shape {
            case .round:
                // Sombra
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 1, y: 2)
                // Borde exterior
                Circle()
                    .stroke(stroke, lineWidth: size * 0.08)
                // Fondo
                Circle()
                    .fill(fill)
                // Borde interior
                Circle()
                    .scale(0.82)
                    .stroke(stroke.opacity(0.5), lineWidth: size * 0.03)
                
            case .diamond:
                Diamond()
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 1, y: 2)
                Diamond()
                    .stroke(stroke, lineWidth: size * 0.08)
                Diamond()
                    .fill(fill)
                Diamond()
                    .scale(0.82)
                    .stroke(stroke.opacity(0.5), lineWidth: size * 0.03)
                
            case .shield:
                Shield()
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 1, y: 2)
                Shield()
                    .stroke(stroke, lineWidth: size * 0.08)
                Shield()
                    .fill(fill)
                Shield()
                    .scale(0.82)
                    .stroke(stroke.opacity(0.5), lineWidth: size * 0.03)
            }
            
            // Texto del escudo
            Text(crest.text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundColor(stroke)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
        .frame(width: size, height: size)
    }
    
    private var fontSize: CGFloat {
        let len = crest.text.count
        if len <= 2 { return size * 0.38 }
        if len <= 3 { return size * 0.30 }
        if len <= 4 { return size * 0.22 }
        return size * 0.18
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let pad = min(w, h) * 0.08
        
        path.move(to: CGPoint(x: w/2, y: pad))
        path.addLine(to: CGPoint(x: w - pad, y: h/2))
        path.addLine(to: CGPoint(x: w/2, y: h - pad))
        path.addLine(to: CGPoint(x: pad, y: h/2))
        path.closeSubpath()
        return path
    }
}

struct Shield: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let pad = min(w, h) * 0.06
        
        path.move(to: CGPoint(x: pad, y: pad + h * 0.12))
        path.addQuadCurve(
            to: CGPoint(x: w/2, y: pad),
            control: CGPoint(x: w * 0.25, y: pad - h * 0.02)
        )
        path.addQuadCurve(
            to: CGPoint(x: w - pad, y: pad + h * 0.12),
            control: CGPoint(x: w * 0.75, y: pad - h * 0.02)
        )
        path.addLine(to: CGPoint(x: w - pad, y: h * 0.55))
        path.addQuadCurve(
            to: CGPoint(x: w/2, y: h - pad),
            control: CGPoint(x: w * 0.82, y: h * 0.78)
        )
        path.addQuadCurve(
            to: CGPoint(x: pad, y: h * 0.55),
            control: CGPoint(x: w * 0.18, y: h * 0.78)
        )
        path.closeSubpath()
        return path
    }
}
