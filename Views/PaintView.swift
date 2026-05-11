import SwiftUI

struct PaintView: View {
    let team: Team
    let kit: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = PaintEngine()
    @State private var showConfetti = false
    @State private var showFicha = false
    @State private var showGhost = false
    @State private var ghostOffset: CGFloat = 0

    private var kitData: Kit { kit == "away" ? team.away : team.home }
    private let threshold: Double = 0.85
    private let brushSize: CGFloat = 44
    private let shirtAspectRatio: CGFloat = 280.0 / 240.0

    var body: some View {
        GeometryReader { geo in
            let currentShirtSize = shirtSize(for: geo.size)
            let currentShirtHeight = currentShirtSize * shirtAspectRatio

            ZStack {
                Color(hex: "#FEF9E7").ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        BackButton {
                            saveProgress()
                            dismiss()
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "#E8E4DB"))
                                        .frame(height: 24)

                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(progressGradient)
                                        .frame(width: max(0, barGeo.size.width * CGFloat(engine.revealPct)), height: 24)
                                        .animation(.easeOut(duration: 0.3), value: engine.revealPct)
                                }
                            }
                            .frame(height: 24)
                            .frame(maxWidth: min(geo.size.width * 0.4, 520))

                            Text("\(Int(engine.revealPct * 100))%")
                                .font(.custom("Nunito-Black", size: 16))
                                .foregroundColor(Color(hex: "#7A4E1B"))
                        }

                        Spacer()

                        Button(action: {
                            SoundManager.shared.playTap()
                            engine.reset()
                        }) {
                            Text("🔄")
                                .font(.system(size: 30))
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(Color.white))
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 20)

                    ZStack {
                        ShirtView(team: team, kit: kit, size: currentShirtSize, mode: .gray)

                        ShirtView(team: team, kit: kit, size: currentShirtSize, mode: .color)
                            .mask(
                                PaintMaskView(engine: engine, size: currentShirtSize)
                            )

                        PaintCanvas(engine: engine, brushSize: brushSize)
                            .frame(width: currentShirtSize, height: currentShirtHeight)
                            .contentShape(Rectangle())

                        if showGhost && engine.revealPct < threshold {
                            Text("👆")
                                .font(.system(size: 56))
                                .offset(x: ghostOffset, y: 40)
                                .opacity(0.5)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: ghostOffset)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text("DESLIZÁ TU DEDO PARA PINTAR")
                        .font(.custom("Nunito-Black", size: 22))
                        .foregroundColor(Color(hex: "#7A4E1B").opacity(0.6))
                        .padding(.bottom, 26)
                }

                ConfettiView(trigger: $showConfetti)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            engine.setup(gridSize: ShirtGrid.size)
            startGhostTimer()
        }
        .onChange(of: engine.revealPct) { newPct in
            if newPct >= threshold && !showConfetti {
                completePainting()
            }
        }
        .fullScreenCover(isPresented: $showFicha) {
            FichaView(team: team, kit: kit) {
                dismiss()
            }
        }
    }

    private func shirtSize(for size: CGSize) -> CGFloat {
        min(max(size.height * 0.66, 440), 760)
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#FF7B3D"), Color(hex: "#FFC93C")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func completePainting() {
        showConfetti = true
        SoundManager.shared.playCelebrate()
        saveProgress()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showFicha = true
        }
    }

    private func saveProgress() {
        let progress = ShirtProgress(
            teamId: team.id,
            kit: kit,
            revealed: Int(engine.revealPct * Double(ShirtGrid.size * ShirtGrid.size)),
            total: ShirtGrid.size * ShirtGrid.size
        )
        ProgressStore.shared.save(progress: progress)
    }

    private func startGhostTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if engine.revealPct < 0.1 {
                showGhost = true
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    ghostOffset = 60
                }
            }
        }
    }
}

// MARK: - Paint Engine
class PaintEngine: ObservableObject, @unchecked Sendable {
    @Published var revealPct: Double = 0
    @Published var maskImage: UIImage?

    private var grid: [[Bool]] = []
    private var gridSize: Int = 0

    func setup(gridSize: Int) {
        self.gridSize = gridSize
        self.grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        updateMask()
    }

    func paint(at point: CGPoint, in size: CGSize, brushSize: CGFloat) {
        let cellW = size.width / CGFloat(gridSize)
        let cellH = size.height / CGFloat(gridSize)
        let brushCells = Int(brushSize / min(cellW, cellH)) + 2
        let centerX = Int(point.x / cellW)
        let centerY = Int(point.y / cellH)

        var changed = false
        for dy in -brushCells...brushCells {
            for dx in -brushCells...brushCells {
                let x = centerX + dx
                let y = centerY + dy
                if x >= 0, x < gridSize, y >= 0, y < gridSize {
                    let cellCenter = CGPoint(x: (CGFloat(x) + 0.5) * cellW, y: (CGFloat(y) + 0.5) * cellH)
                    let dist = hypot(cellCenter.x - point.x, cellCenter.y - point.y)
                    if dist < brushSize * 0.6, !grid[y][x] {
                        grid[y][x] = true
                        changed = true
                    }
                }
            }
        }

        if changed {
            updateProgress()
            updateMask()
        }
    }

    func reset() {
        grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        revealPct = 0
        updateMask()
    }

    private func updateProgress() {
        let total = gridSize * gridSize
        let revealed = grid.flatMap { $0 }.filter { $0 }.count
        revealPct = Double(revealed) / Double(total)
    }

    private func updateMask() {
        let gridSnapshot = grid
        let gSize = gridSize
        let image = Self.renderMask(grid: gridSnapshot, gridSize: gSize)
        if Thread.isMainThread {
            maskImage = image
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.maskImage = image
            }
        }
    }

    private static func renderMask(grid: [[Bool]], gridSize: Int) -> UIImage? {
        guard gridSize > 0 else { return nil }
        let size = CGSize(width: 600, height: 700)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        let cellW = size.width / CGFloat(gridSize)
        let cellH = size.height / CGFloat(gridSize)

        ctx.setFillColor(UIColor.white.cgColor)
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                if grid[y][x] {
                    let rect = CGRect(x: CGFloat(x) * cellW, y: CGFloat(y) * cellH, width: cellW + 1, height: cellH + 1)
                    ctx.fillEllipse(in: rect)
                }
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

enum ShirtGrid {
    static let size = 40
}

// MARK: - Paint Mask View
struct PaintMaskView: View {
    @ObservedObject var engine: PaintEngine
    let size: CGFloat

    var body: some View {
        if let maskImage = engine.maskImage {
            Image(uiImage: maskImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size * (280.0/240.0))
        } else {
            Color.clear
                .frame(width: size, height: size * (280.0/240.0))
        }
    }
}

// MARK: - Paint Canvas (Touch handling)
struct PaintCanvas: UIViewRepresentable {
    @ObservedObject var engine: PaintEngine
    let brushSize: CGFloat

    func makeUIView(context: Context) -> PaintCanvasView {
        let view = PaintCanvasView()
        view.engine = engine
        view.brushSize = brushSize
        return view
    }

    func updateUIView(_ uiView: PaintCanvasView, context: Context) {}
}

class PaintCanvasView: UIView {
    var engine: PaintEngine?
    var brushSize: CGFloat = 44

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches.first)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches.first)
    }

    private func handleTouch(_ touch: UITouch?) {
        guard let touch = touch, let engine = engine else { return }
        let point = touch.location(in: self)
        engine.paint(at: point, in: bounds.size, brushSize: brushSize)
    }
}
