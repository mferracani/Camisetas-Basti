import SwiftUI

/// A small, faithful projection of a catalog kit. Contrast selection may change
/// home/away variants, never the colors or design stored in those variants.
struct MatchKitStyle {
    let kit: Kit
    var requiresTeamOutline = false

    var primary: Color { color(at: 0) }
    var secondary: Color { color(at: 1) }
    var sleeveColor: Color {
        [.sleevesW, .splitVBlueClaret].contains(kit.pattern) ? secondary : primary
    }
    var ink: Color {
        let rgb = Self.surfaceColor(kit)
        return rgb.0 * 0.2126 + rgb.1 * 0.7152 + rgb.2 * 0.0722 > 0.62
            ? Color(hex: "#122F3E") : .white
    }

    static func pair(home: Team, away: Team) -> (MatchKitStyle, MatchKitStyle) {
        let minimumDifference = 0.65
        var selected = (home: home.home, away: away.home)
        var bestDifference = difference(selected.home, selected.away)
        // Respect both home shirts when they already read clearly on the pitch.
        if bestDifference < minimumDifference {
            for homeKit in [home.home, home.away] {
                for awayKit in [away.home, away.away] {
                    let candidate = difference(homeKit, awayKit)
                    if candidate > bestDifference {
                        selected = (homeKit, awayKit)
                        bestDifference = candidate
                    }
                }
            }
        }
        // Similar official alternatives stay unchanged; the caller identifies
        // sides with an external ring, not a fabricated third shirt.
        let needsOutline = bestDifference < minimumDifference
        return (MatchKitStyle(kit: selected.home, requiresTeamOutline: needsOutline),
                MatchKitStyle(kit: selected.away, requiresTeamOutline: needsOutline))
    }

    func drawShirt(in context: inout GraphicsContext, rect: CGRect) {
        let shirt = Path(roundedRect: rect, cornerRadius: rect.width * 0.2)
        context.fill(shirt, with: .color(primary))
        var clipped = context
        clipped.clip(to: shirt)
        drawPattern(in: &clipped, rect: rect)
        if [.sleevesW, .splitVBlueClaret].contains(kit.pattern) {
            for x in [rect.minX, rect.maxX - rect.width * 0.19] {
                clipped.fill(Path(CGRect(x: x, y: rect.minY, width: rect.width * 0.19,
                                         height: rect.height * 0.3)), with: .color(sleeveColor))
            }
        }
    }

    func drawPattern(in context: inout GraphicsContext,
                     rect: CGRect = CGRect(x: -7.5, y: -24, width: 15, height: 17)) {
        for path in patternRegions(in: rect) {
            context.fill(path, with: .color(secondary))
        }
        for path in accentRegions(in: rect) {
            context.fill(path, with: .color(color(at: 2)))
        }
    }

    /// Geometry is independent of Canvas so every pattern can be regression-tested.
    func patternRegions(in rect: CGRect) -> [Path] {
        func rectangle(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> Path {
            Path(CGRect(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height,
                        width: width * rect.width, height: height * rect.height))
        }
        func polygon(_ vertices: [(CGFloat, CGFloat)]) -> Path {
            Path { path in
                for (index, vertex) in vertices.enumerated() {
                    let point = CGPoint(x: rect.minX + vertex.0 * rect.width, y: rect.minY + vertex.1 * rect.height)
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                path.closeSubpath()
            }
        }
        switch kit.pattern {
        case .solid, .sleevesW, .splitVBlueClaret:
            return []
        case .stripesV:
            return [1, 3, 5].map { rectangle(CGFloat($0) / 7, 0, 1 / 7, 1) }
        case .stripesH, .hoops:
            return [1, 3, 5, 7].map { rectangle(0, CGFloat($0) / 8, 1, 1 / 8) }
        case .checkerboard:
            return (0..<4).flatMap { row in
                (0..<4).compactMap { column in
                    (row + column).isMultiple(of: 2) ? nil
                        : rectangle(CGFloat(column) / 4, CGFloat(row) / 4, 0.25, 0.25)
                }
            }
        case .chevron:
            return [polygon([(0, 0.12), (0.5, 0.45), (1, 0.12),
                             (1, 0.33), (0.5, 0.70), (0, 0.33)])]
        case .splitV:
            return [rectangle(0.5, 0, 0.5, 1)]
        case .splitD:
            return [polygon([(0, 1), (1, 0), (1, 1)])]
        case .sashD:
            return [polygon([(-0.18, 1), (0.18, 1), (1.18, 0), (0.82, 0)])]
        case .sashHThin:
            return [rectangle(0, 0.36, 1, 0.14)]
        case .sashH:
            return [rectangle(0, 0.33, 1, 0.26)]
        case .sashHThick:
            return [rectangle(0, 0.28, 1, 0.38)]
        case .sashV:
            // This catalog pattern is an oblique stripe, not a V-shaped chevron.
            return [polygon([(0.12, 0), (0.40, 0), (0.88, 1), (0.60, 1)])]
        case .sashVFat, .sashVBordered, .sashVDual:
            return [rectangle(0.30, 0, 0.40, 1)]
        }
    }

    func accentRegions(in rect: CGRect) -> [Path] {
        guard kit.colors.count > 2 else { return [] }
        func stripe(_ x: CGFloat, width: CGFloat) -> Path {
            Path(CGRect(x: rect.minX + x * rect.width, y: rect.minY,
                        width: width * rect.width, height: rect.height))
        }
        switch kit.pattern {
        case .sashVBordered:
            return [stripe(0.27, width: 0.045), stripe(0.685, width: 0.045)]
        case .sashVDual:
            return [stripe(0.50, width: 0.20)]
        case .stripesV:
            return [1, 3, 5].map { stripe(CGFloat($0) / 7 + 0.048, width: 0.047) }
        default:
            return []
        }
    }

    private func color(at index: Int) -> Color {
        Color(hex: kit.colors.indices.contains(index) ? kit.colors[index] : kit.colors.first ?? "#FFFFFF")
    }

    private static func difference(_ first: Kit, _ second: Kit) -> Double {
        let a = surfaceColor(first)
        let b = surfaceColor(second)
        return abs(a.0 - b.0) + abs(a.1 - b.1) + abs(a.2 - b.2)
    }

    private static func surfaceColor(_ kit: Kit) -> (Double, Double, Double) {
        let first = rgb(kit.colors.first ?? "#FFFFFF")
        let second = rgb(kit.colors.dropFirst().first ?? kit.colors.first ?? "#FFFFFF")
        let coverage: Double
        switch kit.pattern {
        case .solid: coverage = 0
        case .sleevesW, .splitVBlueClaret: coverage = 0.12
        case .sashHThin: coverage = 0.14
        case .sashH, .sashD, .sashV, .chevron: coverage = 0.26
        case .sashHThick, .sashVFat, .sashVBordered, .sashVDual: coverage = 0.40
        case .stripesV, .stripesH, .hoops, .splitV, .splitD, .checkerboard: coverage = 0.5
        }
        return (first.0 * (1 - coverage) + second.0 * coverage,
                first.1 * (1 - coverage) + second.1 * coverage,
                first.2 * (1 - coverage) + second.2 * coverage)
    }

    private static func rgb(_ hex: String) -> (Double, Double, Double) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0
        return (Double(value >> 16 & 255) / 255, Double(value >> 8 & 255) / 255, Double(value & 255) / 255)
    }
}
