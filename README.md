# CAMISETAS — iOS & macOS App

> App para niños de 4 años. Descubrí camisetas de fútbol pasando el dedo, coleccionalas y jugá sin internet.

## Plataforma
- **iOS / iPadOS 16+** (principal, landscape)
- **macOS 13+** (SwiftUI adaptable a ventana)
- **Tecnología:** Swift nativo, SwiftUI, AVFoundation (sonidos), UserDefaults (persistencia)

## Setup del proyecto

```bash
# 1. Clonar / crear proyecto Xcode
# 2. Crear proyecto "App" con interface SwiftUI, lifecycle SwiftUI App
# 3. Agregar fuente Nunito al target (copiar a Bundle, registrar en Info.plist)
# 4. Agregar archivos de sonido .m4a a Resources:
#    - tap.m4a
#    - success.m4a
#    - celebrate.m4a
#    - error-soft.m4a
# 5. Configurar orientación: iPad = Landscape only
# 6. Build & Run
```

## Estructura recomendada

```
Camisetas/
├── App/
│   └── CamisetasApp.swift
├── Views/
│   ├── SplashView.swift
│   ├── HomeView.swift
│   ├── CountriesView.swift
│   ├── TeamsView.swift
│   ├── TeamDetailView.swift
│   ├── PaintView.swift
│   ├── FichaView.swift
│   ├── AlbumView.swift
│   ├── GamesView.swift
│   ├── GuessView.swift
│   ├── MemoryView.swift
│   └── RewardsView.swift
├── Components/
│   ├── BigKidButton.swift
│   ├── BackButton.swift
│   ├── ProgressStars.swift
│   ├── ShirtView.swift
│   ├── CrestView.swift
│   ├── FlagView.swift
│   ├── ConfettiView.swift
│   └── AlbumCell.swift
├── Models/
│   ├── Country.swift
│   ├── Team.swift
│   ├── Kit.swift
│   ├── Crest.swift
│   ├── Pattern.swift
│   └── AppState.swift
├── Data/
│   └── CAMI_DATA.swift          # 6 países × 10 equipos × 2 camisetas
├── Services/
│   ├── ProgressStore.swift      # UserDefaults Codable
│   └── SoundManager.swift       # AVAudioPlayer
├── Utils/
│   └── ColorNameMapper.swift    # hex → nombre en español
└── Resources/
    ├── Nunito/
    └── Sounds/
```

## Reglas de implementación

1. **Todo el texto visible para el niño va en MAYÚSCULAS**
2. **Botones mínimo 56pt de altura**, targets táctiles no solapados
3. **Sin internet**, sin analytics, sin login, sin compras, sin anuncios
4. **Persistencia inmediata** al completar cada camiseta (`UserDefaults`)
5. **Repintar** desde FichaView resetea el progreso de esa camiseta a 0
6. **Reset oculto:** 5 taps rápidos en escudo del equipo favorito para borrar todo
7. **Sonidos embebidos** en formato `.m4a`, respetan silencio del dispositivo
8. **Landscape en iPad**, macOS adaptable a ventana

## Decisiones de producto

| Tema | Decisión |
|------|----------|
| Camisetas reales | No. Vectores nativos estilizados (patrones + colores casi idénticos, sin logos) |
| Onboarding | No. El niño aprende explorando |
| Sonidos | Sí, 4 efectos: tap, success, celebrate, error-soft |
| Splash | Sí, camiseta gris que se pinta sola en 1.5s |
| Tecnología | Swift nativo (SwiftUI), no React Native ni PWA |
| Multiplataforma | iOS + macOS desde mismo codebase SwiftUI |
| Trofeos por país | Sí, al completar las 20 camisetas de un país |
| Juegos (adivinar/memoria) | V1, con generación aleatoria desde data local |

## Data de contenido

6 países × 10 equipos × 2 camisetas = **120 camisetas** totales.

Países: ARGENTINA · INGLATERRA · ESPAÑA · ITALIA · FRANCIA · ALEMANIA

## Paleta de colores

| Token | Hex | Uso |
|-------|-----|-----|
| BG | `#FFF7EC` | Fondo principal |
| Card | `#FFFFFF` | Tarjetas |
| Primario | `#FF7B3D` | Botones principales, acentos |
| Sol | `#FFC93C` | Botones secundarios, estrellas |
| Cielo | `#6BCBFF` | Botones de juego |
| Pasto | `#7DDB8B` | Álbum, éxito |
| Error | `#FF7B6B` | Fallo suave |
| Texto | `#3D2A1F` | Todo el texto |

## Dependencias externas

Ninguna. App 100% nativa, sin CocoaPods / SPM / Carthage.

## Compilación

```bash
# Xcode 15+
# Seleccionar target iPad o "My Mac"
# Cmd + R
```

## QA rápido

- [ ] Flujo HOME → PAÍSES → EQUIPOS → DETALLE → PINTAR → FICHA → ÁLBUM
- [ ] Repintar resetea progreso
- [ ] Sonidos en todos los eventos clave
- [ ] Progreso persiste al cerrar y reabrir
- [ ] Reset oculto funciona
- [ ] 60fps en pintura
- [ ] Sin requests de red

---

*Documento derivado del PRD. Para especificación completa ver `PRD.md`.*
