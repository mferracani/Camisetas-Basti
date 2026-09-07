# QA Checklist — Camisetas Basti

## Distribución TestFlight build 16 — 2026-09-07

- [x] `main` limpio, sincronizado en `9d780a3`; preflight oficial de Mundial correcto.
- [x] Archive de `1.0.0 (16)` firmado y exportado con destino App Store Connect.
- [x] Xcode confirmó la carga exitosa y el estado inicial de procesamiento.
- [ ] Confirmar en App Store Connect que Apple finalizó el procesamiento; recién entonces habilitar el grupo interno que corresponda.
- [ ] Smoke manual en iPad de Reduce Motion y revisión perceptual de las carreras; el test automatizado no reemplaza esta instancia.

## Integración Git — 2026-09-07

- [x] Reejecución pre-merge: 76 unitarios sin fallos, en `/private/tmp/camisetas-premerge-20260907-unit.xcresult`.
- [x] Build Release para iOS Simulator correcto, en `/private/tmp/camisetas-premerge-20260907-release.log`.
- [x] Verificación completa anterior: 76 unitarios y cinco XCUITests, 81/81, en `/private/tmp/camisetas-running-fluidity-final.xcresult`; no se presentan los cinco de UI como reejecutados durante el merge.
- [x] Código probado en `35ff0eb`; el merge `9853908` sólo agrega `AGENTS.md`. Ramas publicadas, integración fast-forward a `main` y SHA remoto comprobado.
- [ ] QA de dispositivo físico y gaps manuales indicados en la corrección de carreras. No se realizó archive ni upload a TestFlight.

## Incremento motion natural — 2026-09-07

- [x] 74 unit tests, 0 fallos; incluye curvas/velocidad y zancada continuas, pausas reales, independencia del refresco y contacto del balón con el caché multijugada.
- [x] 22 jugadores legibles, separación dentro de cada equipo y continuidad renderizada en ocho semillas completas.
- [x] Reduce Motion sin giro, altura ni estela; conserva resultados e impacto.
- [x] Cuatro XCUITests: goles/Reduce Motion; tiro libre/penal en tres momentos normales y reducidos; tanda/cierre; partido completo y persistencia del resultado en fixture.
- [x] Reejecución posterior al refinamiento final del pateador: 74 unitarios + XCUITest de tanda/cierre, sin fallos.
- [x] Build Debug de pruebas y build Release para iOS Simulator, sin firma.
- [x] Inspección y grabaciones de la app real en iPad Pro 13 (M5); XCUITests en iPad A16, horizontal.
- [x] Muestreo del caché: promedio ~8 ms por 120 frames (~0,06 ms/frame) en test de Simulator. No mide Canvas/GPU ni certifica 60 FPS en hardware.
- [ ] FPS, temperatura, batería y legibilidad de la silueta compacta en iPad físico con Basti.

Evidencia: `/private/tmp/camisetas-motion-verification.xcresult` (74 + 4), `/private/tmp/camisetas-motion-final.xcresult` (74 + 1) y `match-natural-motion-2026-09-07.md`.

## Incremento Liga Argentina 2026 — 2026-09-07

- [x] Los 30 clubes oficiales LPF 2026 existen una sola vez en `CAMI_DATA.teams["arg"]`.
- [x] Los 30 clubes quedan sembrados en una llave de 32 plazas con dos pases libres.
- [x] Las ligas de 16 equipos mantienen el formato existente.
- [x] XCUITest abre `SIMULAR TORNEO`, selecciona Argentina y encuentra los 30 clubes.
- [x] Suite unitaria completa: 67 tests, 0 fallos.
- [x] Build Release para iOS Simulator correcto.
- [ ] Smoke manual en iPad físico.


## Incremento: camisetas y pelota parada — 2026-09-07

- [x] 139 equipos jugables / 278 kits cubiertos por selección explícita; todas las combinaciones conservan un kit original, sin recolor sintético.
- [x] Tests de rayas, damero, bandas, mitades, mangas, V y tres colores; referencias erróneas desasociadas sin borrar assets ni progreso.
- [x] 64 unit tests sin fallos: resultado determinista, continuidad, preparación/barrera, penal desde punto correcto, arquero en línea y mismo impacto en movimiento normal/reducido.
- [x] XCUITest de tiro libre y penal en preparación/remate/desenlace, con y sin Reducir movimiento.
- [x] XCUITest de gol y marcador con Reducir movimiento.
- [x] XCUITest de tanda: pelota en vuelo antes del gol, desenlace y cierre a Home.
- [x] Inspección real en Simulator iPad Pro 13: barrera y penal; grabación de dos jugadas normales en `build/match-kits-set-pieces/tiro-libre-y-penal.mp4`.
- [x] Reejecución final del partido completo desde fixture y persistencia del resultado: MEX 0–RSA 1, cierre y fixture no rejugable; 126.782 segundos.
- [x] Build Release final de este incremento (generic iOS Simulator, sin firma).
- [ ] Validación en iPad físico con Basti, FPS y autenticación de temporada de todas las camisetas heredadas.

Cuatro pruebas de interfaz focales pasaron: tres de presentación (100.675 segundos) y una del partido completo (126.782 segundos). El primer intento que informó cero tests se descarta; los resultados válidos están en `ui-verified.xcresult` y `final-tests.xcresult`. Límites/fuentes: `match-kits-set-pieces-2026-09-07.md` y `kit-audit-2026-09-07.md`.

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
| Unit — ProgressStore | `ProgressStoreTests.swift` | 12 tests | ✅ Pass 2026-08-22 |
| Unit — PaintEngine | `PaintEngineTests.swift` | 10 tests | ✅ Pass 2026-08-22 |
| Unit — MatchSimulation | `MatchSimulationFactoryTests.swift` | 11 tests de motor + 3 de fixture | ✅ Pass 2026-08-22 |
| UI — Critical Flow | `CamisetasBastiUITests.swift` | 4 tests | ⚠️ No incluidos en el scheme actual; no cubren torneo |

**Comando para ejecutar:**
```bash
xcodebuild test -scheme CamisetasBasti -destination 'platform=iOS Simulator,name=iPad Air'
```

---

## 10. Simulación de partidos v2

### Cobertura automatizada

- [x] Misma semilla produce el mismo resultado y timeline.
- [x] Continuidad de pelota, jugadores, posesión y progreso entre beats.
- [x] Pases y recuperaciones de ambos equipos en todas las semillas probadas.
- [x] Presencia de remate afuera, atajada y bloqueo.
- [x] Goles de timeline iguales al marcador final.
- [x] Separación entre compañeros corregida por aspecto en `t = 0, 0.25, 0.5, 0.75, 1`.
- [x] Jugadores dentro del área jugable durante los reinicios.
- [x] Dueño de cada acción controlada ubicado sobre la pelota al comenzar.
- [x] Distribución ponderada favorece al equipo fuerte sin eliminar sorpresas.
- [x] Tanda de penales alterna 5 remates por equipo y respeta al ganador.

### Smoke visual en iPad (A16) horizontal — 2026-08-22

- [x] Navegación `Splash → Home → SIMULAR TORNEO → Partidos → partido`.
- [x] 6 jugadores por equipo, camiseta distinguible y pelota rastreable.
- [x] Pases, presión y duelo sin saltos de pelota.
- [x] Remate afuera visible, con feedback dentro de la cancha y posterior saque de arco.
- [x] Marcador, minuto, banda de relato y panel final legibles sin recortes.
- [x] VoiceOver recibe un único resumen de minuto, marcador y jugada; la cancha no expone 12 elementos decorativos.
- [ ] Ejecutar smoke manual específico con `Reduce Motion` antes del próximo TestFlight.
- [ ] Agregar un XCUITest determinístico del flujo torneo → partido → `CERRAR` → avance de llave.

---

## 11. Assets Faltantes (Bloqueantes para Submit)

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
| Tests unitarios | 36 casos | 36 | ✅ |
| UI automatizada de torneo | 1 flujo requerido | 0 | ⚠️ Pendiente |
| Assets | 8 | 0 | 🔴 |

**Veredicto provisional:** ⬜ **NO APROBADO para submit** — faltan assets esenciales (fuentes, sonidos, icono, launch screen).

**Una vez agregados los assets:** Ejecutar tests y completar checklist manual.

## Iteración de partidos — 2026-09-07

- [x] Debug y Release para Simulator compilan; 48 tests unitarios pasan en iPad (A16), iOS 26.4.
- [x] Continuidad de pelota al soltar/recibir y entre beats; separación de 22 jugadores; altura y estela coherentes.
- [x] Gol termina dentro de la red y conserva continuidad con la reposición.
- [x] Primer remate dentro del primer 30% sobre 24 semillas, sin cambiar la duración total.
- [x] XCUITest de navegación normal, partido completo, cierre y guardado del marcador en zona.
- [x] XCUITest de gol antes/después de impacto y mismo resultado con Reduce Motion.
- [x] Revisión visual de jugadores, estadio y festejo; captura adicional en iPad de 13 pulgadas.
- [ ] Validación con Basti y medición de rendimiento en dispositivo físico.
- [ ] Pendiente previo: prueba completa de avance de llave en eliminación directa y VoiceOver manual.

Evidencia y comandos: `.project/match-experience-2026-09-07.md`. No se ejecutó toda la suite UI heredada. El bloqueo de pantalla de la Mac limitó el control manual final de Simulator; los XCUITests sí completaron. Esta verificación no equivale a aprobación de submit ni publicación.

---

## Handoff

Próximo paso: **SwiftUI Engineer / Product Manager**
- Agregar assets faltantes (fuentes, sonidos, iconos)
- Generar proyecto Xcode `.xcodeproj` con targets correctos
- Correr tests con `Cmd+U`

## Corrección de carreras y fluidez — 2026-09-07

- [x] 76 unitarios y 5 XCUITests focales, 81 pruebas sin fallos.
- [x] Velocidad de curva y de posiciones resueltas, 27 partidos deterministas; sin picos de separación fuera del límite del test.
- [x] Continuidad de poses, gait, balón, contactos e impacto; 22 jugadores y límites del campo.
- [x] Reloj monotónico, pausas, seek y fotogramas demorados; UI real en segundo plano cinco segundos y reanudación.
- [x] Tiros libres y penales: preparación, remate, resultado y marcador sin goles anticipados; equivalencia con Reduce Motion.
- [x] Tanda: impacto y cierre. Partido completo MEX–RSA: navegación, 110 s de juego, cierre y resultado persistido en la zona (129.501 s de test total).
- [x] Build Release para Simulator y `git diff --check` correctos.
- [x] Video real y revisión de secuencia de movimiento en iPad Pro 13 M5; muestra de cadencia de Canvas sin otras pruebas/compilación.
- [ ] FPS/GPU y temperatura en iPad físico; validación perceptual con Mati/Basti.
- [ ] Gaps previos: VoiceOver manual y flujo completo de avance de eliminación directa, no añadidos por este cambio.

Reporte: `.project/match-running-fluidity-2026-09-07.md`. Resultado verificable: `/private/tmp/camisetas-running-fluidity-final.xcresult`. Esto no autoriza publicación ni submit.
