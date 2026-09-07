# Experiencia de partidos — 2026-09-07

## Current State

Implementado localmente en `codex/feat-realistic-match-simulation`, sobre `d2cd2bd`. Sin commit, push, merge ni publicación. El cambio previo del usuario en `AGENTS.md` se conserva.

Pedido: hacer los partidos menos toscos y más entretenidos. El framework de contexto en Obsidian estaba accesible, pero no se encontró una ficha específica de Camisetas Basti. Se usaron el PRD, los gates y las decisiones vigentes de `.project/state.md`.

## Decisiones y experiencia

- Conservar cámara fija, 22 jugadores, juego automático, reglas y partidos de 90–110 segundos.
- Cambiar fichas rígidas por jugadores con camiseta, dorsal, cabeza, brazos, piernas y sombra. Zancada según velocidad, contacto al patear, arquero que se estira y jugadores que festejan.
- Interpolar el movimiento sin frenar a todo el equipo en cada microjugada. Un muestreador comparte las coordenadas de pie, vuelo, recepción y estela; se corrigen los saltos al soltar y recibir.
- Mostrar altura y sombra en centros/remates, red en los arcos, césped con franjas y tribuna con reacciones. Gol con cartel del equipo, salto de jugadores, partículas, red y pulso del marcador.
- Acortar el inicio de ocho a tres pases por equipo. Antes había aproximadamente 30–33 beats hasta el primer remate; ahora el test sobre 24 semillas exige que llegue dentro del primer 30% del partido. El resultado se calcula antes de construir la timeline y la duración total no cambia.
- Los goles terminan detrás de la línea (`x: -0.018/1.018`), dentro de las redes. Jugadores y arqueros conservan sus límites.
- Evaluar las cuatro combinaciones de camisetas cuando los titulares chocan. Bélgica/Corea se distingue con Bélgica alternativa negra y Corea roja; el fallback de representación es efímero.
- Mantener Reduce Motion con posiciones discretas, sin giro/altura de pelota, partículas, zancadas ni rebotes. El resultado coincide con la versión animada.

## Architecture & Stack

SwiftUI y Canvas; sin dependencias nuevas, red, permisos ni cambios de persistencia.

- `Models/MatchPresentation.swift`: frame puro y comprobable de jugadores, pelota, altura, dueño, opacidad y trayectoria corta. Impacto compartido en `0.78` de la microjugada.
- `Views/MatchPitchView.swift`: estadio, jugadores articulados y momentos destacados en una superficie de dibujo.
- `Views/TournamentSimulatorView.swift`: integra la presentación, marcador/relato y pausa del reloj en segundo plano; conserva el cierre y el contrato de resultado.
- `CamisetasBastiApp.swift`: vista reproducible sólo en Debug, sin cambiar el lanzamiento normal.
- Modelos de torneo, progreso y motor de resultados mantienen su contrato. `project.pbxproj` registra ambos archivos nuevos.

El nuevo marcador y los textos principales usan la tipografía redondeada del sistema: las fuentes Nunito referenciadas por el proyecto siguen faltando en Resources. No se agrega audio: los cuatro archivos de sonido también son un faltante previo y la UX no los exige para esta iteración.

## Verificación

- Debug y Release para iOS Simulator compilaron (sin firma).
- 48 tests unitarios pasaron en iPad (A16), iOS 26.4: simulación, continuidad de frames, entrada de goles al arco, ritmo inicial, Reduce Motion, penales, progreso y fixture.
- XCUITest `testWorldCupMatchPlaysToCompletionAndSavesGroupScore` pasó: lanzamiento normal → Mundial → Partidos → México/Sudáfrica → partido completo → CERRAR → mismo marcador en zona. Duración del test: 127.2 s. Ejecutado antes del último ajuste de arranque y objetivo espacial de gol.
- XCUITest `testGoalPresentationAndReducedMotionKeepTheSameScore` pasó con la versión final: antes del gol no hay anuncio; después del impacto sube el marcador; Reduce Motion conserva el mismo resultado. Incluye capturas de ambas variantes en horizontal.
- Verificación visual adicional en iPad Pro 13 pulgadas. La Mac se bloqueó durante la revisión y limitó el control manual de la ventana de Simulator; las pruebas XCUITest continuaron y pasaron.
- Revisión independiente corrigió dos hallazgos: objetivo de gol antes de la línea y selección alternativa de camisetas sin contraste. Sin nuevos hallazgos estáticos de privacidad, lifecycle o continuidad.

Evidencia local (ignorada por Git): `build/match-experience/` contiene logs, xcresults, capturas y video de muestra. `partido-preview.mp4` es un recorte de 24 segundos a velocidad normal de la grabación real del Simulator; sólo se quitaron las franjas negras del dispositivo y se ajustó la resolución. Se ejecutó toda la suite unitaria y los dos tests de interfaz indicados; no toda la suite UI heredada.

## Reproducción

Comando de verificación (fijo, ejecutar en la raíz del repo):

```sh
xcodebuild -project CamisetasBasti.xcodeproj -scheme CamisetasBasti \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=3856E7A0-2084-45B1-AF45-9D5C7743BA68' \
  -derivedDataPath /private/tmp/CamisetasBastiMatchExperience \
  -only-testing:CamisetasBastiTests \
  -only-testing:CamisetasBastiUITests/CamisetasBastiUITests/testWorldCupMatchPlaysToCompletionAndSavesGroupScore \
  -only-testing:CamisetasBastiUITests/CamisetasBastiUITests/testGoalPresentationAndReducedMotionKeepTheSameScore \
  CODE_SIGNING_ALLOWED=NO test
```

La ID identifica el iPad A16 local. En otra máquina se reemplaza por una ID disponible en `xcrun simctl list devices available`.

Vista de revisión con la build Debug instalada:

```sh
xcrun simctl launch 3856E7A0-2084-45B1-AF45-9D5C7743BA68 com.camisetasbasti.app --match-preview
```

Opciones Debug: `--match-preview-still` congela la escena, `--match-reduce-motion` aplica la variante accesible. La variable de entorno del proceso `MATCH_PREVIEW_MOMENT` acepta `before-goal` o `goal`; `MATCH_PREVIEW_PROGRESS` permite otro punto entre 0 y 1. Todo el mecanismo de selección por argumentos está excluido de Release.

## Pendientes y riesgos

- Validar con Basti si el nuevo ritmo y la legibilidad sostienen mejor su atención; no se midió entretenimiento con usuarios ni FPS en iPad físico.
- Mantener el pendiente previo de XCUITest de eliminación directa/avance de llave y prueba manual completa con VoiceOver. Esta iteración verifica automáticamente guardado en zona y conservación del resultado con Reduce Motion.
- Revisar y aprobar el diff antes de publicar. TestFlight y firma siguen fuera de esta entrega.

## Handoff

Mati puede revisar la experiencia y decidir publicación. Commit sugerido: `feat(matches): anima jugadores y mejora el ritmo de los partidos`. Las decisiones y verificaciones de esta nota pueden incorporarse a una ficha futura del proyecto en Project framework.
