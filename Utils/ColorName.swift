import SwiftUI

enum ColorName {
    static let map: [String: String] = [
        "#FFFFFF": "BLANCO", "#0A2A6C": "AZUL", "#FFD700": "AMARILLO",
        "#E2272F": "ROJO", "#FFE600": "AMARILLO", "#1A1A1A": "NEGRO",
        "#74ACDF": "CELESTE", "#C8102E": "ROJO", "#A50044": "GRANATE",
        "#004D98": "AZUL", "#FEBE10": "DORADO", "#CB3524": "ROJO",
        "#EE2523": "ROJO", "#0067B1": "AZUL", "#D9001A": "ROJO",
        "#F18E00": "NARANJA", "#005EB8": "AZUL", "#0BB363": "VERDE",
        "#6CABDD": "CELESTE", "#DA291C": "ROJO", "#EF0107": "ROJO",
        "#034694": "AZUL", "#7A003C": "GRANATE", "#86C5FF": "CELESTE",
        "#1BB1E7": "CELESTE", "#003399": "AZUL", "#12A0D7": "CELESTE",
        "#8E1F2F": "GRANATE", "#F2A93B": "DORADO", "#87CEEB": "CELESTE",
        "#5B2D88": "VIOLETA", "#2FAEE0": "CELESTE", "#DC052D": "ROJO",
        "#0066B2": "AZUL", "#FDE100": "AMARILLO", "#E32219": "ROJO",
        "#DD0741": "ROJO", "#65B32E": "VERDE", "#1D9053": "VERDE",
        "#CE1124": "ROJO", "#7FE3D9": "TURQUESA", "#FCBF49": "DORADO",
        "#0055A4": "AZUL", "#EF4135": "ROJO", "#FFCE00": "AMARILLO",
    ]
    
    static func name(for hex: String) -> String {
        map[hex.uppercased()] ?? "COLOR"
    }
    
    static func spanishName(for hex: String) -> String {
        name(for: hex)
    }
    
    static func names(for colors: [String]) -> String {
        colors.prefix(2).map { name(for: $0) }.joined(separator: " Y ")
    }
}
