import SwiftUI

struct ConfettiView: View {
    @Binding var trigger: Bool
    @State private var particles: [Particle] = []
    let colors: [Color] = [
        Color(hex: "#FFC93C"),
        Color(hex: "#FF7B3D"),
        Color(hex: "#6BCBFF"),
        Color(hex: "#7DDB8B"),
        Color(hex: "#E84A5F"),
        Color(hex: "#9B59B6"),
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(
                        particle: particle,
                        size: geo.size
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { newValue in
            if newValue {
                burst(count: 50)
                trigger = false
            }
        }
    }
    
    func burst(count: Int = 40) {
        let newParticles = (0..<count).map { i in
            Particle(
                id: UUID(),
                x: 0.5 + Double.random(in: -0.2...0.2),
                y: 0.3 + Double.random(in: -0.1...0.1),
                vx: Double.random(in: -3...3),
                vy: Double.random(in: -8...(-4)),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -10...10),
                color: colors.randomElement()!,
                size: Double.random(in: 8...16),
                shape: Bool.random() ? .rect : .circle
            )
        }
        particles.append(contentsOf: newParticles)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                particles.removeAll()
            }
        }
    }
    
    struct Particle: Identifiable {
        let id: UUID
        let x: Double
        let y: Double
        let vx: Double
        let vy: Double
        let rotation: Double
        let rotationSpeed: Double
        let color: Color
        let size: Double
        let shape: ShapeType
    }
    
    enum ShapeType { case rect, circle }
    
    struct ConfettiPiece: View {
        let particle: Particle
        let size: CGSize
        @State private var posX: CGFloat = 0
        @State private var posY: CGFloat = 0
        @State private var rot: Double = 0
        @State private var opacity: Double = 1
        
        var body: some View {
            let shape: AnyView = {
                switch particle.shape {
                case .rect:
                    return AnyView(
                        Rectangle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size * 0.6)
                    )
                case .circle:
                    return AnyView(
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size)
                    )
                }
            }()
            
            shape
                .position(x: posX, y: posY)
                .rotationEffect(.degrees(rot))
                .opacity(opacity)
                .onAppear {
                    posX = CGFloat(particle.x) * size.width
                    posY = CGFloat(particle.y) * size.height
                    rot = particle.rotation
                    
                    withAnimation(.easeOut(duration: 3)) {
                        posX += CGFloat(particle.vx * 40)
                        posY += CGFloat(particle.vy * 40 + 200)
                        rot += particle.rotationSpeed * 30
                        opacity = 0
                    }
                }
        }
    }
}
