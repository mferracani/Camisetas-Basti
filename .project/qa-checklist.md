# QA Checklist — Camisetas Basti

**Fecha:** 2026-04-29
**QA Engineer:** Agent Kit QA
**Plataforma:** iOS 16+ / iPadOS 16+ / macOS 13+
**Orientación principal:** iPad Landscape
**Público objetivo:** Niños de 4 años

---

## 1. Flujo Crítico (Smoke Test)

| # | Paso | Criterio de aceptación | Estado |
|---|------|------------------------|--------|
| 1.1 | Abrir app | Splash muestra camiseta gris que se pinta sola en ~1.5s | ⬜ |
| 1.2 | Tap en splash | Transición suave a HomeView | ⬜ |
| 1.3 | Home: tap "JUGAR" | Navega a CountriesView con 6 países visibles | ⬜ |
| 1.4 | Seleccionar país | Navega a TeamsView con 10 equipos del país | ⬜ |
| 1.5 | Seleccionar equipo | Navega a TeamDetailView con home/away selector | ⬜ |
| 1.6 | Tap "PINTAR" | Navega a PaintView con camiseta gris + barra 0% | ⬜ |
| 1.7 | Pintar con dedo | La camiseta se revela; barra de progreso aumenta | ⬜ |
| 1.8 | Alcanzar 85% | Confetti + sonido celebrate; navega a FichaView | ⬜ |
| 1.9 | Ficha: tap "SEGUIR" | Vuelve a TeamDetailView; kit ahora tiene check verde | ⬜ |
| 1.10 | Home: tap "ÁLBUM" | Muestra grid de camisetas con estado correcto | ⬜ |

**Resultado esperado:** 10/10 pasos ✅ para aprobar build.

---

## 2. Usabilidad Infantil (4 años)

### Targets táctiles

| Elemento | Tamaño mínimo requerido | Estado |
|----------|------------------------|--------|
| Botón "JUGAR" | 200×104pt | ⬜ |
| Botón "ÁLBUM" | 160×80pt | ⬜ |
| Tarjeta de país | 120×140pt | ⬜ |
| Tarjeta de equipo | 100×120pt | ⬜ |
| Botón "PINTAR" | 200×104pt | ⬜ |
| Botón Back | 64×64pt | ⬜ |
| Botón repintar (🔄) | 56×56pt | ⬜ |
| Área de pintura | Mínimo 300×350pt | ⬜ |

### Feedback inmediato

| Acción | Feedback esperado | Estado |
|--------|-------------------|--------|
| Tap cualquier botón | Sonido "tap" + animación de presión | ⬜ |
| Pintar en camiseta | Sonido continuo (V2) + progreso visual | ⬜ |
| Completar camiseta | Sonido "celebrate" + confetti + vibración (V2) | ⬜ |
| Repintar (🔄) | Reset inmediato a 0% | ⬜ |
| Seleccionar kit en TeamDetail | Anillo naranja alrededor del seleccionado | ⬜ |

### Texto legible

| Requisito | Criterio | Estado |
|-----------|----------|--------|
| Todo en MAYÚSCULAS | Verificado en todas las vistas | ⬜ |
| Fuente Nunito Black cargada | Sin fallback a system font | ⬜ |
| Tamaño mínimo 11pt para labels | Verificado en AlbumCell/TeamCard | ⬜ |
| Tamaño 18pt+ para botones principales | Verificado | ⬜ |
| Alto contraste | Texto marrón (#3D2A1F) sobre crema (#FEF9E7) | ⬜ |

---

## 3. PaintView — Funcionalidad Core

| # | Escenario | Pasos | Resultado esperado | Estado |
|---|-----------|-------|-------------------|--------|
| 3.1 | Pintar normal | Deslizar dedo por la camiseta | Pixels se revelan; % sube | ⬜ |
| 3.2 | Pintar rápido | Movimientos rápidos del dedo | No se pierden strokes | ⬜ |
| 3.3 | Pintar fuera de área | Tocar fuera de la silueta | No afecta progreso; no crashea | ⬜ |
| 3.4 | Progreso persistente | Pintar 50%, salir, volver a entrar | Muestra 50% (o estado guardado) | ⬜ |
| 3.5 | Repintar | Tap en 🔄 | Reset a 0% inmediato | ⬜ |
| 3.6 | Completar | Pintar hasta 85%+ | Confetti + navigate a Ficha | ⬜ |
| 3.7 | Ghost finger | Esperar 3s sin pintar (si 0%) | Aparece 👆 animado | ⬜ |
| 3.8 | Múltiples touches | Intentar con 2 dedos simultáneos | Solo registra 1 (isMultipleTouchEnabled=false) | ⬜ |
| 3.9 | Performance | Pintar durante 30s seguidos | FPS > 55; sin lag | ⬜ |

---

## 4. Progreso y Persistencia

| # | Escenario | Pasos | Resultado esperado | Estado |
|---|-----------|-------|-------------------|--------|
| 4.1 | Guardado automático | Completar camiseta → home → album | Camiseta aparece en color con check | ⬜ |
| 4.2 | Kill app | Pintar 30% → kill app → reabrir | Vuelve a PaintView con 30% | ⬜ |
| 4.3 | Reset individual | Repintar camiseta ya completada | Vuelve a 0%; estrella se resta | ⬜ |
| 4.4 | Reset total | 5 taps en escudo favorito | Confirmar reset → todo vuelve a 0 | ⬜ |
| 4.5 | Trofeo país | Completar las 20 camisetas de un país | Trofeo aparece en GamesView | ⬜ |
| 4.6 | Sticker equipo | Completar home + away de un equipo | Sticker desbloqueado | ⬜ |

---

## 5. Audio

| # | Escenario | Resultado esperado | Estado |
|---|-----------|-------------------|--------|
| 5.1 | Tap en botón | Suena "tap.m4a" | ⬜ |
| 5.2 | Completar camiseta | Suena "celebrate.m4a" | ⬜ |
| 5.3 | Ficha aparece | Suena "success.m4a" | ⬜ |
| 5.4 | Silencio del dispositivo ON | Ningún sonido suena (modo ambient) | ⬜ |
| 5.5 | Volumen bajo | Sonidos se escuchan proporcionalmente | ⬜ |
| 5.6 | Auriculares conectados | Sonidos salen por auriculares | ⬜ |
| 5.7 | Archivo .m4a faltante | App no crashea; sonido simplemente no suena | ⬜ |

---

## 6. Orientación y Dispositivos

| Dispositivo | Orientación | Estado |
|-------------|-------------|--------|
| iPad Pro 12.9" | Landscape | ⬜ |
| iPad Air | Landscape | ⬜ |
| iPad mini | Landscape | ⬜ |
| iPad (base) | Landscape | ⬜ |
| iPhone 15 Pro Max | Portrait | ⬜ |
| iPhone SE | Portrait | ⬜ |
| macOS (Designed for iPad) | Ventana adaptable | ⬜ |

**Nota:** En portrait los grids pueden mostrar 2-3 columnas en lugar de 3-4. Verificar que no haya overflow.

---

## 7. Edge Cases

| # | Escenario | Resultado esperado | Estado |
|---|-----------|-------------------|--------|
| 7.1 | Doble tap rápido en botón | No navega 2 veces | ⬜ |
| 7.2 | Tap durante transición de confetti | Ignorado; sin crash | ⬜ |
| 7.3 | Memoria baja (simulado) | UserDefaults se guarda; no se pierde progreso | ⬜ |
| 7.4 | Modo oscuro del sistema | App mantiene tema claro (fondo crema) | ⬜ |
| 7.5 | Texto dinámico grande (AX) | Layout no se rompe; scroll funciona | ⬜ |
| 7.6 | VoiceOver activado | Labels descriptivos en botones principales | ⬜ |
| 7.7 | Sin fuentes Nunito instaladas | Fallback a system bold (aceptable pero no ideal) | ⬜ |

---

## 8. Rendimiento

| Métrica | Target | Herramienta | Estado |
|---------|--------|-------------|--------|
| Tiempo de lanzamiento | < 2s | Xcode Instruments | ⬜ |
| Uso de memoria (peak) | < 150MB | Xcode Memory Graph | ⬜ |
| FPS en PaintView | > 55fps | Xcode FPS Gauge | ⬜ |
| Tamaño de bundle | < 50MB | App Thinning Report | ⬜ |
| Binary size (ipa) | < 30MB | Organizer | ⬜ |

---

## 9. Tests Automatizados

| Suite | Archivo | Casos | Estado |
|-------|---------|-------|--------|
| Unit — ProgressStore | `ProgressStoreTests.swift` | 11 tests | ⬜ Pass |
| Unit — PaintEngine | `PaintEngineTests.swift` | 9 tests | ⬜ Pass |
| UI — Critical Flow | `CamisetasBastiUITests.swift` | 4 tests | ⬜ Pass |

**Comando para ejecutar:**
```bash
xcodebuild test -scheme CamisetasBasti -destination 'platform=iOS Simulator,name=iPad Air'
```

---

## 10. Assets Faltantes (Bloqueantes para Submit)

| Asset | Ubicación | Estado |
|-------|-----------|--------|
| Nunito-Black.ttf | `Fonts/Nunito-Black.ttf` + Info.plist `UIAppFonts` | 🔴 Faltante |
| Nunito-Bold.ttf | `Fonts/Nunito-Bold.ttf` + Info.plist `UIAppFonts` | 🔴 Faltante |
| tap.m4a | `Sounds/tap.m4a` | 🔴 Faltante |
| success.m4a | `Sounds/success.m4a` | 🔴 Faltante |
| celebrate.m4a | `Sounds/celebrate.m4a` | 🔴 Faltante |
| error-soft.m4a | `Sounds/error-soft.m4a` | 🔴 Faltante |
| App Icon (1024×1024) | `Assets.xcassets/AppIcon.appiconset` | 🔴 Faltante |
| Launch Screen | `LaunchScreen.storyboard` o SwiftUI | 🔴 Faltante |

---

## Resumen de Aprobación

| Categoría | Items | Aprobados | Estado |
|-----------|-------|-----------|--------|
| Flujo crítico | 10 | 0 | ⬜ |
| Usabilidad infantil | 16 | 0 | ⬜ |
| PaintView | 9 | 0 | ⬜ |
| Progreso | 6 | 0 | ⬜ |
| Audio | 7 | 0 | ⬜ |
| Orientaciones | 7 | 0 | ⬜ |
| Edge cases | 7 | 0 | ⬜ |
| Rendimiento | 5 | 0 | ⬜ |
| Tests | 3 suites | 0 | ⬜ |
| Assets | 8 | 0 | 🔴 |

**Veredicto provisional:** ⬜ **NO APROBADO para submit** — faltan assets esenciales (fuentes, sonidos, icono, launch screen).

**Una vez agregados los assets:** Ejecutar tests y completar checklist manual.

---

## Handoff

Próximo paso: **SwiftUI Engineer / Product Manager**
- Agregar assets faltantes (fuentes, sonidos, iconos)
- Generar proyecto Xcode `.xcodeproj` con targets correctos
- Correr tests con `Cmd+U`
