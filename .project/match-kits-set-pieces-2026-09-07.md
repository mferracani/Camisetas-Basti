# Camisetas y pelota parada — 2026-09-07

## Pedido y alcance

Mati validó la animación anterior y pidió respetar camisetas reales de todos los equipos y mostrar tiros libres/penales. Se reutilizó el alcance aprobado del Agent Kit: mismo modal, 22 jugadores, offline, cámara fija y 90–110 segundos. Rama reutilizada: `codex/feat-realistic-match-simulation`; cambios locales previos preservados, incluido `AGENTS.md` ajeno a esta iteración. Sin commit, push ni release.

## Camisetas

- Alcance real: 139 equipos jugables / 278 kits: 104 equipos del álbum y 35 selecciones adicionales del fixture/sorteo. Las 35 adicionales antes podían usar colores invertidos o gris genérico.
- `MatchKitStyle` selecciona sólo entre titular/suplente del catálogo. No fabrica un tercer kit para aumentar contraste; usa contornos externos cuando hace falta.
- Geometría explícita para rayas, bandas de distintos anchos, mitades, mangas contrastantes, damero croata, V de Vélez y bandas tricolores.
- Mismo helper en partido y pateador de la tanda final. No se recortan PNG al torso: contienen rótulos, dorsales fijos, distintas composiciones y algunos escudos erróneos.
- `CAMI_DATA` corrige colores/patrones y desasocia imágenes equivocadas, sin borrar originales ni cambiar IDs/progreso guardado. `worldCupKits` cubre explícitamente las selecciones adicionales.
- Auditoría y fuentes por equipo: `kit-audit-2026-09-07.md`. **No se certifica una colección completa 2026/27:** el catálogo mezcla ediciones sin procedencia. Se conserva la colección salvo errores probados; los gaps de temporada se registran, no se dan por verificados.

## Pelota parada

- Secuencia: falta → preparación → tiro → desenlace → reposición. Un tiro libre por partido; penal ocasional (máximo uno), no uno obligatorio en cada encuentro.
- El tiro libre arma barrera de tres defensores y un remate curvo/elevado. El penal usa punto de penal, carrera y arquero en línea hasta el contacto, con los demás jugadores fuera del área y detrás del balón. Base visual simplificada, no motor reglamentario completo: [IFAB, tiros libres](https://www.theifab.com/laws/latest/free-kicks/) y [IFAB, penal](https://www.theifab.com/laws/latest/the-penalty-kick/).
- Las oportunidades de pelota parada reemplazan remates existentes. Se conserva exactamente el resultado previamente generado; no hay goles extra. Los penales durante el partido nunca son bloqueados por un defensor.
- `MatchPresentation.shotImpactProgress = 0.78` coordina bola, marcador y relato; la tanda final también se corrigió para no contar goles en 0.76 antes de llegar la pelota.
- Pelota quieta en preparación; carrera sin llevar la pelota; barrera salta después del golpeo; piernas se detienen al llegar a su posición. Reducir movimiento conserva preparación/desenlace sin trail ni salto.

## Verificación reproducible

Los comandos se ejecutan desde la raíz del repo. Los directorios `build/` y DerivedData contienen evidencia local ignorada por Git. Sólo se seleccionan pruebas de interfaz relacionadas con partidos; no se afirma que el resto histórico del flujo de pintura haya sido validado.

```sh
xcodebuild -project CamisetasBasti.xcodeproj -scheme CamisetasBasti -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,id=3856E7A0-2084-45B1-AF45-9D5C7743BA68' -derivedDataPath /private/tmp/CamisetasBastiSetPiecesQA CODE_SIGNING_ALLOWED=NO build-for-testing
```

Vista Debug reproducible (excluida de Release): `--match-preview`, `--match-preview-still`, `--match-reduce-motion`. Variable `MATCH_PREVIEW_MOMENT`:

- `free-kick-start`, `free-kick`, `free-kick-shot`, `free-kick-result`.
- `penalty-start`, `penalty`, `penalty-shot`, `penalty-result`.
- `before-goal`, `goal`.
- `shootout-before-goal`, `shootout-goal`, `shootout-finished`.

Se buscan simulaciones seeded normales que contengan el momento, sin inyectar goles artificiales. `-start` permite grabar falta/preparación/remate en tiempo real; sin `--match-preview-still` la reproducción continúa a velocidad normal.

## Riesgos y handoff

- Mantener identidad estilizada no equivale a autenticar cada temporada, patrocinador, escudo o textura. La edición objetivo quedó consultada a Mati, no asumida.
- Las fuentes Nunito y sonidos que faltaban en el baseline no se agregaron; la UI nueva usa system rounded. No se agregaron dependencias, red, analytics ni permisos.
- Sin medición FPS ni prueba física con Basti; pendiente validación subjetiva del ritmo. Antes de TestFlight usar el proceso de release desde `main` limpio, no este checkout local sin publicar.
- Handoff: QA focal y revisión visual; después revisión de Mati/publicación sólo si la solicita.

## Resultados

- 64 unit tests, cero fallos (3.281 s), incluyendo todos los pares de los 139 equipos.
- Repetición tras las últimas correcciones de paleta: los mismos 64 tests pasaron, cero fallos (3.289 s), en `catalog-final.xcresult`.
- Tres XCUITests de presentación, cero fallos (100.675 s): pelota parada normal/Reduce Motion, gol y marcador, tanda y cierre.
- Un XCUITest del flujo real: Splash → Home → Mundial → Partidos → MEX/RSA → partido completo → cierre → fixture con el mismo 0–1 y no rejugable. Pasó en 126.782 s.
- Build Debug para pruebas y Release generic iOS Simulator, ambos correctos; sin firma, archive ni upload.
- `git diff --check` correcto. Revisión independiente corrigió dos detalles: trote residual tras llegar a la posición y marcador/arquero adelantados al contacto en la tanda anterior.
- Evidencia: `build/match-kits-set-pieces/`: `ui-verified.xcresult`, `final-tests.xcresult`, `release-build.log`, capturas de preparación y video real `tiro-libre-y-penal.mp4` (19 s, dos jugadas distintas, velocidad normal; sólo recortado el letterbox negro del dispositivo).
- Un primer intento de Xcode devolvió cero pruebas de interfaz y no se considera validación. La enumeración confirmó los métodos; una nueva compilación `build-for-testing` y posterior `test-without-building` ejecutaron los casos reales. No se estableció la causa exacta del estado transitorio anterior.
