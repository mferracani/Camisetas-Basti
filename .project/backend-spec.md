# Backend Spec — Camisetas Basti

> Especificación de datos local, persistencia, assets y sonidos para app iOS/macOS nativa (SwiftUI). No hay backend remoto. Todo vive en el dispositivo.

---

## 1. STACK

| Capa | Tecnología | Versión mínima |
|------|-----------|----------------|
| Plataforma | iOS / iPadOS / macOS | 16+ / 16+ / 13+ |
| Framework UI | SwiftUI | — |
| Framework complementario | UIKit (CALayer, AVAudioPlayer, UIBezierPath) | — |
| Persistencia | UserDefaults + Codable | — |
| Sonidos | AVAudioPlayer | — |
| Assets | Bundle Resources (vectores nativos, fuentes, sonidos) | — |
| Build tool | Xcode | 15+ |

**Sin backend remoto. Sin auth. Sin APIs. Sin base de datos remota.**

---

## 2. MODELO DE DATOS (SWIFT)

### 2.1 Estructura estática (contenido empaquetado)

Estos datos nunca cambian en runtime. Viven en `CAMI_DATA.swift` como constantes.

```swift
// MARK: - Country

struct Country: Codable, Identifiable, Hashable {
    let id: String       // ej: "arg", "eng", "esp", "ita", "fra", "ger"
    let name: String     // ej: "ARGENTINA"
    let flagColors: [String]  // Hex array para renderizar bandera nativamente
    let emoji: String    // ej: "🇦🇷"
}

// MARK: - Team

struct Team: Codable, Identifiable, Hashable {
    let id: String       // ej: "boca", "mci"
    let name: String     // ej: "BOCA JUNIORS"
    let short: String    // ej: "BOCA" — nombre corto para grids pequeños
    let home: Kit
    let away: Kit
    let crest: Crest
}

// MARK: - Kit

struct Kit: Codable, Hashable {
    let pattern: Pattern
    let colors: [String] // Hex array ["#0A2A6C", "#FFD700"]
}

// MARK: - Pattern

enum Pattern: String, Codable, CaseIterable {
    case solid
    case stripesV = "stripes-v"
    case stripesH = "stripes-h"
    case hoops
    case splitV = "split-v"
    case splitD = "split-d"
    case sashD = "sash-d"
    case sashH = "sash-h"
    case sashHThin = "sash-h-thin"
    case sashHThick = "sash-h-thick"
    case sashV = "sash-v"
    case sashVFat = "sash-v-fat"
    case sleevesW = "sleeves-w"
    case splitVBlueClaret = "split-v-blue-claret"
}

// MARK: - Crest

struct Crest: Codable, Hashable {
    enum Shape: String, Codable {
        case round, shield, diamond
    }
    let shape: Shape
    let text: String       // ej: "CABJ"
    let colors: [String]   // [fill, stroke]
}
```

### 2.2 Estructura mutable (progreso del usuario)

Estos datos cambian durante el uso de la app y se persisten en `UserDefaults`.

```swift
// MARK: - ShirtProgress

struct ShirtProgress: Codable, Equatable {
    let key: String        // Composite: "{countryId}.{teamId}.{kit}"
                           // ej: "arg.boca.home"
    var status: Int        // 0 = locked (gris)
                           // 1 = partial (pintada parcialmente)
                           // 2 = complete (descubierta)
    var revealPct: Double? // 0.0 ... 1.0. Último % revelado (para reanudar)
}

// MARK: - GamesStats

struct GamesStats: Codable, Equatable {
    var guessPlayed: Int = 0
    var memoryPlayed: Int = 0
    var guessWon: Int = 0
}

// MARK: - AppState (root de persistencia)

struct AppState: Codable {
    // Progreso por camiseta
    var progress: [String: ShirtProgress] = [:]
    
    // Progreso global
    var totalStars: Int = 0
    
    // Última visita (para reanudar)
    var lastCountryId: String? = nil
    var lastTeamId: String? = nil
    
    // Recompensas
    var trophies: [String: Bool] = [:]   // countryId -> true si desbloqueado
    var stickers: [String: Bool] = [:]   // teamId -> true si desbloqueado
    
    // Stats de juegos
    var gamesPlayed: GamesStats = GamesStats()
    
    // Metadata
    var contentVersion: Int = 1
    var onboardingCompleted: Bool = true  // Siempre true (sin onboarding)
}
```

### 2.3 Clave compuesta para progreso

```
{countryId}.{teamId}.{kit}

ejemplos:
- "arg.boca.home"      → Boca Juniors, camiseta titular
- "arg.boca.away"      → Boca Juniors, camiseta suplente
- "eng.mci.home"       → Manchester City, camiseta titular
- "esp.fcb.away"       → Barcelona, camiseta suplente
```

### 2.4 Helpers de progreso

```swift
extension AppState {
    /// Calcula cuántas camisetas descubiertas tiene un país
    func discoveredShirts(for countryId: String, teams: [Team]) -> Int {
        var count = 0
        for team in teams where team.home != nil || team.away != nil {
            let homeKey = "\(countryId).\(team.id).home"
            let awayKey = "\(countryId).\(team.id).away"
            if progress[homeKey]?.status == 2 { count += 1 }
            if progress[awayKey]?.status == 2 { count += 1 }
        }
        return count
    }
    
    /// Calcula cuántas camisetas descubiertas tiene un equipo
    func discoveredShirts(for countryId: String, teamId: String) -> Int {
        let homeKey = "\(countryId).\(teamId).home"
        let awayKey = "\(countryId).\(teamId).away"
        var count = 0
        if progress[homeKey]?.status == 2 { count += 1 }
        if progress[awayKey]?.status == 2 { count += 1 }
        return count
    }
    
    /// Total posible de camisetas por país
    static let shirtsPerCountry = 20  // 10 equipos × 2 camisetas
    
    /// Total posible global
    static let totalShirts = 120      // 6 países × 10 equipos × 2 camisetas
}
```

---

## 3. PERSISTENCIA (USERDEFAULTS)

### 3.1 Estrategia

| Aspecto | Decisión |
|---------|----------|
| Mecanismo | `UserDefaults` con `JSONEncoder` / `JSONDecoder` |
| Key principal | `"com.camisetasbasti.appstate"` |
| Actualización | Inmediata al completar cada camiseta (no batch) |
| Backup | Automático por iCloud (UserDefaults incluido en backups) |
| Migración | Por `contentVersion` en `AppState` |

### 3.2 Implementación de ProgressStore

```swift
import Foundation

final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    private let defaults = UserDefaults.standard
    private let key = "com.camisetasbasti.appstate"
    
    @Published var state: AppState
    
    private init() {
        self.state = Self.load()
    }
    
    // MARK: - Load
    
    private static func load() -> AppState {
        guard let data = UserDefaults.standard.data(forKey: "com.camisetasbasti.appstate"),
              let state = try? JSONDecoder().decode(AppState.self, from: data) else {
            return AppState()
        }
        return state
    }
    
    // MARK: - Save
    
    func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
        defaults.synchronize() // Forzar escritura inmediata
    }
    
    // MARK: - Convenience
    
    func setShirtComplete(countryId: String, teamId: String, kit: String) {
        let key = "\(countryId).\(teamId).\(kit)"
        state.progress[key] = ShirtProgress(key: key, status: 2, revealPct: 1.0)
        state.totalStars += 1
        
        // Check trofeo por país
        let discovered = state.discoveredShirts(for: countryId, teams: CAMI_DATA.teams(for: countryId))
        if discovered == AppState.shirtsPerCountry {
            state.trophies[countryId] = true
        }
        
        // Check sticker por equipo
        let teamDiscovered = state.discoveredShirts(for: countryId, teamId: teamId)
        if teamDiscovered == 2 {
            state.stickers[teamId] = true
        }
        
        save()
    }
    
    func resetShirt(countryId: String, teamId: String, kit: String) {
        let key = "\(countryId).\(teamId).\(kit)"
        state.progress[key] = ShirtProgress(key: key, status: 0, revealPct: 0.0)
        state.totalStars = max(0, state.totalStars - 1)
        save()
    }
    
    func setShirtPartial(countryId: String, teamId: String, kit: String, pct: Double) {
        let key = "\(countryId).\(teamId).\(kit)"
        state.progress[key] = ShirtProgress(key: key, status: 1, revealPct: pct)
        save()
    }
    
    // MARK: - Reset everything (parental gate)
    
    func resetAll() {
        state = AppState()
        save()
    }
}
```

### 3.3 Migración de contenido

```swift
extension ProgressStore {
    /// Llamar al iniciar la app después de cargar state
    func migrateIfNeeded(currentContentVersion: Int) {
        guard state.contentVersion < currentContentVersion else { return }
        
        // Estrategia: preservar progreso de keys existentes,
        // inicializar a 0 las nuevas keys
        // (esto sucede automáticamente porque AppState.progress
        //  es un diccionario sparse — keys faltantes = status 0)
        
        state.contentVersion = currentContentVersion
        save()
    }
}
```

---

## 4. ASSETS BUNDLE

### 4.1 Estructura de Resources

```
Camisetas.app/
├── Info.plist
├── Assets.xcassets/
│   └── (vacío o solo app icon)
├── Nunito/
│   ├── Nunito-ExtraBold.ttf      (weight 800)
│   ├── Nunito-Black.ttf          (weight 900)
│   └── OFL.txt                   (licencia)
└── Sounds/
    ├── tap.m4a                   (botón)
    ├── success.m4a               (acierto)
    ├── celebrate.m4a             (completar camiseta)
    └── error-soft.m4a            (fallo suave)
```

### 4.2 Registro de fuente

En `Info.plist`:
```xml
<key>UIAppFonts</key>
<array>
    <string>Nunito-ExtraBold.ttf</string>
    <string>Nunito-Black.ttf</string>
</array>
```

En SwiftUI:
```swift
.font(.custom("Nunito-Black", size: 28))
```

### 4.3 Sonidos

| Archivo | Evento | Duración estimada | Volumen |
|---------|--------|------------------|---------|
| `tap.m4a` | Tap en cualquier botón | 50-100ms | 0.7 |
| `success.m4a` | Acierto en ADIVINAR | 300-500ms | 0.8 |
| `celebrate.m4a` | Completar camiseta / trofeo país | 800-1200ms | 0.9 |
| `error-soft.m4a` | Fallo suave en ADIVINAR | 200-300ms | 0.6 |

### 4.4 Implementación de SoundManager

```swift
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    private let volume: Float = 0.7
    
    enum Sound: String {
        case tap = "tap"
        case success = "success"
        case celebrate = "celebrate"
        case errorSoft = "error-soft"
    }
    
    private init() {
        preloadAll()
    }
    
    private func preloadAll() {
        for sound in Sound.allCases {
            load(sound)
        }
    }
    
    private func load(_ sound: Sound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") else {
            print("⚠️ Sound not found: \(sound.rawValue).m4a")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players[sound.rawValue] = player
        } catch {
            print("⚠️ Failed to load sound: \(sound.rawValue)")
        }
    }
    
    func play(_ sound: Sound) {
        guard let player = players[sound.rawValue] else { return }
        player.currentTime = 0
        player.play()
    }
    
    func playCelebrate() {
        play(.celebrate)
    }
    
    func playTap() {
        play(.tap)
    }
    
    func playSuccess() {
        play(.success)
    }
    
    func playError() {
        play(.errorSoft)
    }
}

extension SoundManager.Sound: CaseIterable {}
```

### 4.5 Configuración de sesión de audio

```swift
import AVFoundation

func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print("⚠️ Failed to configure audio session: \(error)")
    }
}
```

> **Importante:** `.ambient` permite que la música del sistema continúe sonando y respeta el switch de silencio del dispositivo.

---

## 5. DATA ESTÁTICA (CAMI_DATA)

### 5.1 Contrato

```swift
enum CAMI_DATA {
    static let countries: [Country] = [
        Country(id: "arg", name: "ARGENTINA", flagColors: ["#75AADB", "#FFFFFF", "#75AADB"], emoji: "🇦🇷"),
        Country(id: "eng", name: "INGLATERRA", flagColors: ["#FFFFFF", "#CE1124"], emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿"),
        Country(id: "esp", name: "ESPAÑA", flagColors: ["#AA151B", "#F1BF00", "#AA151B"], emoji: "🇪🇸"),
        Country(id: "ita", name: "ITALIA", flagColors: ["#008C45", "#F4F5F0", "#CD212A"], emoji: "🇮🇹"),
        Country(id: "fra", name: "FRANCIA", flagColors: ["#0055A4", "#FFFFFF", "#EF4135"], emoji: "🇫🇷"),
        Country(id: "ger", name: "ALEMANIA", flagColors: ["#000000", "#DD0000", "#FFCE00"], emoji: "🇩🇪"),
    ]
    
    static let teams: [String: [Team]] = [
        "arg": [ /* 10 equipos */ ],
        "eng": [ /* 10 equipos */ ],
        "esp": [ /* 10 equipos */ ],
        "ita": [ /* 10 equipos */ ],
        "fra": [ /* 10 equipos */ ],
        "ger": [ /* 10 equipos */ ],
    ]
    
    static func teams(for countryId: String) -> [Team] {
        teams[countryId] ?? []
    }
    
    static func team(countryId: String, teamId: String) -> Team? {
        teams(for: countryId).first { $0.id == teamId }
    }
    
    static func country(id: String) -> Country? {
        countries.first { $0.id == id }
    }
}
```

### 5.2 Mapeo de nombres de colores (hex → español)

```swift
enum ColorName {
    static let map: [String: String] = [
        "#FFFFFF": "BLANCO",
        "#0A2A6C": "AZUL",
        "#FFD700": "AMARILLO",
        "#E2272F": "ROJO",
        "#FFE600": "AMARILLO",
        "#1A1A1A": "NEGRO",
        "#74ACDF": "CELESTE",
        "#C8102E": "ROJO",
        "#A50044": "GRANATE",
        "#004D98": "AZUL",
        "#FEBE10": "DORADO",
        "#CB3524": "ROJO",
        "#EE2523": "ROJO",
        "#0067B1": "AZUL",
        "#D9001A": "ROJO",
        "#F18E00": "NARANJA",
        "#005EB8": "AZUL",
        "#0BB363": "VERDE",
        "#6CABDD": "CELESTE",
        "#DA291C": "ROJO",
        "#EF0107": "ROJO",
        "#034694": "AZUL",
        "#7A003C": "GRANATE",
        "#86C5FF": "CELESTE",
        "#1BB1E7": "CELESTE",
        "#003399": "AZUL",
        "#12A0D7": "CELESTE",
        "#8E1F2F": "GRANATE",
        "#F2A93B": "DORADO",
        "#87CEEB": "CELESTE",
        "#5B2D88": "VIOLETA",
        "#2FAEE0": "CELESTE",
        "#DC052D": "ROJO",
        "#0066B2": "AZUL",
        "#FDE100": "AMARILLO",
        "#E32219": "ROJO",
        "#DD0741": "ROJO",
        "#65B32E": "VERDE",
        "#1D9053": "VERDE",
        "#CE1124": "ROJO",
        "#7FE3D9": "TURQUESA",
        "#FCBF49": "DORADO",
        "#0055A4": "AZUL",
        "#EF4135": "ROJO",
        "#FFCE00": "AMARILLO",
    ]
    
    static func name(for hex: String) -> String {
        map[hex.uppercased()] ?? "COLOR"
    }
    
    static func names(for colors: [String]) -> String {
        colors.prefix(2).map { name(for: $0) }.joined(separator: " Y ")
    }
}
```

---

## 6. SCAFFOLDING PROPUESTO

```
Camisetas/
├── App/
│   ├── CamisetasApp.swift          // @main, configureAudioSession
│   └── Info.plist                  // UIAppFonts, orientations
│
├── Views/
│   ├── SplashView.swift
│   ├── HomeView.swift
│   ├── CountriesView.swift
│   ├── TeamsView.swift
│   ├── TeamDetailView.swift
│   ├── PaintView.swift             // UIViewRepresentable + CALayer mask
│   ├── FichaView.swift
│   ├── AlbumView.swift
│   ├── GamesView.swift
│   ├── GuessView.swift             // V1
│   ├── MemoryView.swift            // V1
│   └── RewardsView.swift           // V1
│
├── Components/
│   ├── BigKidButton.swift          // Botón grande con sombra
│   ├── BackButton.swift            // Círculo 64pt con flecha
│   ├── ProgressStars.swift         // Estrellas de progreso
│   ├── ShirtView.swift             // Camiseta vectorial nativa
│   ├── CrestView.swift             // Escudo vectorial nativo
│   ├── FlagView.swift              // Bandera vectorial nativa
│   ├── ConfettiView.swift          // CAEmitterLayer o particles
│   ├── AlbumCell.swift             // Celda del álbum
│   └── HelpOverlay.swift           // Modal de ayuda en PINTAR
│
├── Models/
│   ├── Country.swift
│   ├── Team.swift
│   ├── Kit.swift
│   ├── Crest.swift
│   ├── Pattern.swift
│   ├── ShirtProgress.swift
│   ├── AppState.swift
│   └── GamesStats.swift
│
├── Data/
│   ├── CAMI_DATA.swift             // 60 equipos estáticos
│   └── ColorName.swift             // hex → español
│
├── Services/
│   ├── ProgressStore.swift         // UserDefaults + Codable
│   └── SoundManager.swift          // AVAudioPlayer
│
├── Utils/
│   └── ShirtPath.swift             // UIBezierPath de silueta de camiseta
│
└── Resources/
    ├── Nunito/
    │   ├── Nunito-ExtraBold.ttf
    │   ├── Nunito-Black.ttf
    │   └── OFL.txt
    └── Sounds/
        ├── tap.m4a
        ├── success.m4a
        ├── celebrate.m4a
        └── error-soft.m4a
```

---

## 7. SILUETA DE CAMISETA (PATH)

```swift
import UIKit

enum ShirtPath {
    /// Path maestro de camiseta en viewBox 240×280
    static let path = UIBezierPath()
    
    static func create() -> UIBezierPath {
        let path = UIBezierPath()
        // M 60 28
        path.move(to: CGPoint(x: 60, y: 28))
        // L 92 14
        path.addLine(to: CGPoint(x: 92, y: 14))
        // C 100 30, 140 30, 148 14
        path.addCurve(to: CGPoint(x: 148, y: 14),
                      controlPoint1: CGPoint(x: 100, y: 30),
                      controlPoint2: CGPoint(x: 140, y: 30))
        // L 180 28
        path.addLine(to: CGPoint(x: 180, y: 28))
        // L 220 56
        path.addLine(to: CGPoint(x: 220, y: 56))
        // L 200 96
        path.addLine(to: CGPoint(x: 200, y: 96))
        // L 178 86
        path.addLine(to: CGPoint(x: 178, y: 86))
        // L 178 252
        path.addLine(to: CGPoint(x: 178, y: 252))
        // C 178 262, 172 268, 162 268
        path.addCurve(to: CGPoint(x: 162, y: 268),
                      controlPoint1: CGPoint(x: 178, y: 262),
                      controlPoint2: CGPoint(x: 172, y: 268))
        // L 78 268
        path.addLine(to: CGPoint(x: 78, y: 268))
        // C 68 268, 62 262, 62 252
        path.addCurve(to: CGPoint(x: 62, y: 252),
                      controlPoint1: CGPoint(x: 68, y: 268),
                      controlPoint2: CGPoint(x: 62, y: 262))
        // L 62 86
        path.addLine(to: CGPoint(x: 62, y: 86))
        // L 40 96
        path.addLine(to: CGPoint(x: 40, y: 96))
        // L 20 56
        path.addLine(to: CGPoint(x: 20, y: 56))
        // Z (close)
        path.close()
        return path
    }
    
    /// Escalar path a cualquier tamaño manteniendo aspect ratio
    static func scaledPath(to size: CGFloat) -> UIBezierPath {
        let originalSize: CGFloat = 240
        let scale = size / originalSize
        let path = create()
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        path.apply(transform)
        return path
    }
}
```

---

## 8. VERSIONADO DE CONTENIDO

```swift
enum ContentVersion {
    static let current = 1
    
    /// Llamar en CamisetasApp.init o .onAppear de Splash
    static func migrate(store: ProgressStore) {
        store.migrateIfNeeded(currentContentVersion: current)
    }
}
```

**Reglas de migración:**
- Si `state.contentVersion == current`: sin cambios.
- Si `state.contentVersion < current`: actualizar a `current`, preservar todo el progreso existente. Las nuevas camisetas (keys que no existen en `progress`) se consideran automáticamente `status: 0`.
- Si `state.contentVersion > current`: situación anómala (rollback de app). Preservar progreso, actualizar `contentVersion` a `current`.

---

## 9. CHECKLIST TÉCNICO PRE-IMPLEMENTACIÓN

- [ ] Xcode 15+ instalado
- [ ] Proyecto SwiftUI App creado (iOS + macOS)
- [ ] Target iPadOS 16+, macOS 13+
- [ ] Fuente Nunito agregada a Bundle + Info.plist
- [ ] Sonidos .m4a agregados a Bundle
- [ ] Orientación iPad bloqueada a landscape
- [ ] `ProgressStore` singleton implementado
- [ ] `SoundManager` singleton implementado
- [ ] `configureAudioSession()` llamado al iniciar
- [ ] `CAMI_DATA` con los 60 equipos completos
- [ ] `ShirtPath` con silueta exacta
- [ ] `ColorName` cubre todos los hex usados en data
- [ ] Modelos `Codable` con tests de encode/decode
- [ ] `UserDefaults` guarda y recupera `AppState` sin pérdida
- [ ] Botón RESET oculto implementado (5 taps en escudo)

---

## 10. HANDOFF A SWIFTUI ENGINEER

Los contratos de arriba son la fuente de verdad. El engineer puede empezar con:

1. **Scaffolding:** crear carpetas `Views/`, `Components/`, `Models/`, `Data/`, `Services/`, `Utils/`, `Resources/`.
2. **Modelos:** copiar los structs de la sección 2.
3. **Data:** crear `CAMI_DATA.swift` con los 60 equipos del prototipo (`data.jsx`).
4. **Servicios:** implementar `ProgressStore` y `SoundManager`.
5. **Utils:** crear `ShirtPath` y `ColorName`.
6. **Components:** empezar por `BigKidButton`, `BackButton`, `ShirtView`.
7. **Views:** Splash → Home → Countries → Teams → TeamDetail → Paint → Ficha → Album.

**Puntos de atención:**
- `PaintView` requiere `UIViewRepresentable` con `CALayer` máscara o `Canvas` con `BlendMode.clear`. Es la vista más compleja.
- `ShirtView` renderiza vectores nativos, no imágenes. Cada patrón (stripes, sash, split, etc.) es un `Shape` o `Path` diferente.
- `UserDefaults` debe guardar **inmediatamente** al completar cada camiseta (niño puede cerrar la app en cualquier momento).
- Sonidos deben respetar el silencio del dispositivo (`.ambient` + switch de silencio).

---

*Backend Spec generado desde PRD.md y ux-spec.md · Estado: LISTO PARA APROBACIÓN*

**Próximo paso:** Si el usuario aprueba este Backend Spec, actualizar `.project/state.md` (fase = "frontend") y handoff a `@swiftui-engineer`.
