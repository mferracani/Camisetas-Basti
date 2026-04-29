import SwiftUI

enum ShirtPath {
    static let master = createPath()
    
    static func createPath() -> Path {
        var path = Path()
        
        // Dimensiones base: 240×280
        // Cuerpo principal + mangas en una sola path
        
        // Punto de inicio: hombro izquierdo interno
        path.move(to: CGPoint(x: 92, y: 18))
        
        // Cuello izquierdo (curva hacia adentro)
        path.addCurve(
            to: CGPoint(x: 105, y: 14),
            control1: CGPoint(x: 96, y: 16),
            control2: CGPoint(x: 100, y: 14)
        )
        
        // Cuello base
        path.addLine(to: CGPoint(x: 135, y: 14))
        
        // Cuello derecho
        path.addCurve(
            to: CGPoint(x: 148, y: 18),
            control1: CGPoint(x: 140, y: 14),
            control2: CGPoint(x: 144, y: 16)
        )
        
        // Hombro derecho (curva suave)
        path.addCurve(
            to: CGPoint(x: 180, y: 28),
            control1: CGPoint(x: 158, y: 20),
            control2: CGPoint(x: 170, y: 24)
        )
        
        // Manga derecha - borde superior
        path.addCurve(
            to: CGPoint(x: 220, y: 58),
            control1: CGPoint(x: 200, y: 38),
            control2: CGPoint(x: 212, y: 48)
        )
        
        // Manga derecha - puño exterior
        path.addCurve(
            to: CGPoint(x: 215, y: 82),
            control1: CGPoint(x: 222, y: 68),
            control2: CGPoint(x: 219, y: 76)
        )
        
        // Manga derecha - puño interior
        path.addCurve(
            to: CGPoint(x: 190, y: 94),
            control1: CGPoint(x: 208, y: 88),
            control2: CGPoint(x: 198, y: 92)
        )
        
        // Sisa derecha
        path.addCurve(
            to: CGPoint(x: 182, y: 120),
            control1: CGPoint(x: 186, y: 102),
            control2: CGPoint(x: 184, y: 110)
        )
        
        // Costado derecho (ligera curva hacia adentro)
        path.addCurve(
            to: CGPoint(x: 178, y: 200),
            control1: CGPoint(x: 184, y: 155),
            control2: CGPoint(x: 182, y: 178)
        )
        
        // Cadera derecha
        path.addCurve(
            to: CGPoint(x: 172, y: 248),
            control1: CGPoint(x: 176, y: 225),
            control2: CGPoint(x: 174, y: 238)
        )
        
        // Dobladillo derecho (redondeado)
        path.addCurve(
            to: CGPoint(x: 162, y: 268),
            control1: CGPoint(x: 170, y: 260),
            control2: CGPoint(x: 166, y: 266)
        )
        
        // Dobladillo base
        path.addLine(to: CGPoint(x: 78, y: 268))
        
        // Dobladillo izquierdo (redondeado)
        path.addCurve(
            to: CGPoint(x: 68, y: 248),
            control1: CGPoint(x: 74, y: 266),
            control2: CGPoint(x: 70, y: 260)
        )
        
        // Cadera izquierda
        path.addCurve(
            to: CGPoint(x: 62, y: 200),
            control1: CGPoint(x: 66, y: 238),
            control2: CGPoint(x: 64, y: 225)
        )
        
        // Costado izquierdo
        path.addCurve(
            to: CGPoint(x: 58, y: 120),
            control1: CGPoint(x: 56, y: 178),
            control2: CGPoint(x: 54, y: 155)
        )
        
        // Sisa izquierda
        path.addCurve(
            to: CGPoint(x: 50, y: 94),
            control1: CGPoint(x: 56, y: 110),
            control2: CGPoint(x: 54, y: 102)
        )
        
        // Manga izquierda - puño interior
        path.addCurve(
            to: CGPoint(x: 25, y: 82),
            control1: CGPoint(x: 42, y: 92),
            control2: CGPoint(x: 32, y: 88)
        )
        
        // Manga izquierda - puño exterior
        path.addCurve(
            to: CGPoint(x: 20, y: 58),
            control1: CGPoint(x: 21, y: 76),
            control2: CGPoint(x: 18, y: 68)
        )
        
        // Manga izquierda - borde superior
        path.addCurve(
            to: CGPoint(x: 60, y: 28),
            control1: CGPoint(x: 28, y: 48),
            control2: CGPoint(x: 40, y: 38)
        )
        
        // Hombro izquierdo
        path.addCurve(
            to: CGPoint(x: 92, y: 18),
            control1: CGPoint(x: 70, y: 24),
            control2: CGPoint(x: 82, y: 20)
        )
        
        path.closeSubpath()
        return path
    }
    
    static func scaled(to size: CGFloat) -> Path {
        let scale = size / 240
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        return master.applying(transform)
    }
}
