# Assets Requeridos — Camisetas Basti

Esta guía lista todos los archivos binarios que faltan para compilar y subir la app. Los archivos de código Swift ya están completos.

---

## 1. Fuentes (Fonts/)

Descargar **Nunito** desde Google Fonts: https://fonts.google.com/specimen/Nunito

| Archivo | Peso | Dónde poner |
|---------|------|-------------|
| `Nunito-Black.ttf` | 900 | `CamisetasBasti/Fonts/Nunito-Black.ttf` |
| `Nunito-Bold.ttf` | 700 | `CamisetasBasti/Fonts/Nunito-Bold.ttf` |

**Importante:** Agregar a `Build Phases > Copy Bundle Resources`. Ya están referenciadas en `Info.plist` bajo `UIAppFonts`.

---

## 2. Sonidos (Sounds/)

Crear o conseguir 4 archivos `.m4a` (AAC, mono o stereo, ~0.5-2 segundos cada uno).

| Archivo | Uso | Duración sugerida | Volumen |
|---------|-----|-------------------|---------|
| `tap.m4a` | Tap en cualquier botón | 0.1s | Corto, percusivo (pop/plop) |
| `success.m4a` | Ficha descubierta | 1.0s | Alegre, campana/chime ascendente |
| `celebrate.m4a` | Camiseta completada | 2.0s | Fanfarria, aplausos cortos, confetti sound |
| `error-soft.m4a` | Acción inválida (V2) | 0.3s | Bump suave, no scary |

**Dónde poner:** `CamisetasBasti/Sounds/*.m4a`

**Importante:** Agregar a `Build Phases > Copy Bundle Resources`.

---

## 3. App Icon (Assets.xcassets/AppIcon.appiconset/)

Crear un icono cuadrado con fondo crema `#FEF9E7` y una camiseta estilizada.

**Tamaños requeridos (iOS):**

| Nombre | Tamaño | Uso |
|--------|--------|-----|
| `Icon-20@2x.png` | 40×40 | Notificaciones iPad |
| `Icon-20@3x.png` | 60×60 | Notificaciones iPhone |
| `Icon-29@2x.png` | 58×58 | Settings iPad |
| `Icon-29@3x.png` | 87×87 | Settings iPhone |
| `Icon-40@2x.png` | 80×80 | Spotlight iPad |
| `Icon-40@3x.png` | 120×120 | Spotlight iPhone |
| `Icon-60@2x.png` | 120×120 | App Store iPhone |
| `Icon-60@3x.png` | 180×180 | App Store iPhone |
| `Icon-76@2x.png` | 152×152 | App Store iPad |
| `Icon-83.5@2x.png` | 167×167 | App Store iPad Pro |
| `Icon-1024.png` | 1024×1024 | App Store Connect |

**Contents.json:** Xcode genera esto automáticamente al arrastrar el 1024×1024 si usas `New iOS App Icon` asset.

---

## 4. Launch Screen

**Opción A — SwiftUI (recomendada para iOS 14+):**

Crear `LaunchScreen.storyboard` en Xcode o usar la nueva API de launch screen en `Info.plist` (ya incluido).

El `LaunchBackground` color y `LaunchImage` deben crearse en `Assets.xcassets`:
- `LaunchBackground`: Color sólido `#FEF9E7`
- `LaunchImage`: Logo "CB" centrado, fondo transparente

**Opción B — Storyboard:**
Crear `Base.lproj/LaunchScreen.storyboard` con:
- Background color: `#FEF9E7`
- Label centrado: "CAMISETAS BASTI" en Nunito-Black

---

## 5. Colores en Assets.xcassets (opcional pero recomendado)

Para evitar hardcodear hex en SwiftUI, crear `Colors.xcassets`:

| Nombre | Hex |
|--------|-----|
| `Background` | `#FEF9E7` |
| `TextPrimary` | `#3D2A1F` |
| `TextSecondary` | `#7A4E1B` |
| `AccentOrange` | `#FF7B3D` |
| `AccentYellow` | `#FFC93C` |
| `AccentSky` | `#6BCBFF` |
| `AccentGrass` | `#7DDB8B` |
| `ShirtGray` | `#D9D5CE` |
| `SuccessGreen` | `#7DDB8B` |

---

## Checklist de integración

- [ ] Crear proyecto Xcode `.xcodeproj` con target iOS 16+
- [ ] Agregar todos los archivos `.swift` a `Compile Sources`
- [ ] Agregar `.ttf`, `.m4a` a `Copy Bundle Resources`
- [ ] Agregar `AppIcon` asset catalog
- [ ] Verificar que `Info.plist` tiene `UIAppFonts` correcto
- [ ] Probar en simulador iPad Air (Landscape)
- [ ] Ejecutar tests: `Cmd+U`
- [ ] Profile de memoria con Instruments
- [ ] Archive + Validate App para App Store Connect
