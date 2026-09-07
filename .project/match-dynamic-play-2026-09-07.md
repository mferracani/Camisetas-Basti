# Juego colectivo y variedad de jugadas · 2026-09-07

## Pedido / diagnóstico

Mati probó la versión anterior y aceptó el movimiento individual, pero consideró aburrida la simulación. La causa no era sólo la animación: los ataques repetían pases → presión → remate, los duelos conservaban siempre la posesión, el pasador se detenía al soltar la pelota y los demás jugadores seguían un bloque de formación casi uniforme.

Se trabajó desde `3f6b0d8` en `codex/feat-dynamic-match-play`, reutilizando los gates del mismo flujo. No se cambian kits, cámara, controles, catálogo, resultados, persistencia ni duración total: 110 segundos normales, 100 con Reduce Motion y 70 para la tanda.

## Implementación

- Secuencias variadas: pared con devolución al jugador que sigue corriendo, pase adelantado al espacio, cambio de frente, desborde/centro, conducción y gambeta. Se mezclan sin reemplazar los goles/remates previstos por el resultado local.
- Selección del apoyo según posiciones actuales, espacio del receptor, avance y línea de pase. Los pases cortos liberan al pasador hacia un costado; no lo mandan a correr a través del receptor.
- Robos causales: la intercepción corta un segmento de pase real antes del receptor. El quite se prepara con presión y una pelota dividida. Hay duelos ganados y perdidos.
- Tras recuperar, el poseedor conduce y lanza la contra; al menos dos compañeros atacan espacios. Los apoyos forman triángulos y amplitud; un defensor presiona, otro cubre y otros toman amenazas distintas.
- Los jugadores de apoyo conservan espacios fuera del área chica; el receptor concreto es quien entra al último espacio. Esto evita juntar todos los delanteros junto al arco.
- El planificador comprueba los cruces completos dentro de los límites del campo y del presupuesto de velocidad. Respeta al receptor protegido también durante la planificación, no sólo en el dibujado. El reparto temporal contempla el rodeo, además de la distancia entre puntos.
- Relato breve y accesible diferenciado por jugada. Sin nueva pantalla ni exigencia de controles para el niño.

## Verificación

Las cuatro pruebas de comportamiento iniciales fallaron sobre la base anterior (76 aserciones), reproduciendo la falta de pared, pase en movimiento, intercepción geométrica y contraataque apoyado. Se implementó después de esa comprobación. Durante el incremento, la prueba de velocidad detectó cruces que provocaban tirones; se corrigieron las trayectorias y su presupuesto temporal sin relajar los límites del test.

Suite completa revalidada: **81 unitarios sin fallos**. Incluye cinco tests nuevos de comportamiento y la suite previa de camisetas, pelota parada, resultado, continuidad y persistencia. Se amplió además la comprobación del caché renderizado a doce semillas y a los instantes intermedios de cruce (0.40/0.50), conservando los límites existentes.

- Velocidad: 27 partidos, 20 jugadores de campo, 31 muestras por beat, duración 110 s. Máximo de trayectoria **0.096899 anchos/s**; máximo de posiciones realmente resueltas, medido con paso de 1/60 s: **0.134144 anchos/s**. Límites originales: 0.10 y 0.14, sin relajarlos.
- Muestreo del caché: aproximadamente **7 ms para 120 frames** en el test de CPU. No mide GPU ni certifica FPS en hardware.
- Build Release para iOS Simulator correcto, sin firma; sólo advertencia de extracción de App Intents no aplicable.
- Inspección y grabación de la app real en iPad Pro 13 (M5) Simulator: apoyos, intercepción → conducción → contraataque, pared, amplitud, pelota parada, goles y final ARG 2–FRA 3. Video normal, sin acelerar, exportado a 1600×1200/60 fps en `build/match-dynamic-play/partido-dinamico-2026-09-07.mp4` (107 s, comienza pocos segundos después del saque). Los fps del archivo no son una medición de rendimiento de la app.
- **Seis XCUITests sin fallos**: goles normal/Reduce Motion, pausa/reanudación, tiro libre/penal, tanda/cierre, cuatro relatos tácticos accesibles y partido completo de 110 s desde el fixture con cierre y resultado guardado. Revalidación total: **87 tests correctos** (81 unitarios + seis de interfaz), sin presentar evidencia anterior como ejecución nueva.

Evidencia: `/private/tmp/camisetas-dynamic-final.xcresult`, `/private/tmp/camisetas-dynamic-final.log` y `/private/tmp/camisetas-dynamic-release.log`. El log anterior `/private/tmp/camisetas-dynamic-tempo.log` también conserva las mediciones de velocidad sobre el mismo código de producción.

Para reproducir el flujo normal: **Home → SIMULAR TORNEO → Partidos → tocar un encuentro sin resultado**; esperar el partido, cerrar y comprobar el resultado en el fixture. Para revisión determinista local, la build Debug admite `--match-preview` y `MATCH_PREVIEW_MOMENT` con `one-two`, `through-ball`, `switch-play` o `counterattack`; se usa el modal real, no una maqueta.

## Límites / siguiente rol

Sigue siendo una representación 2D estilizada de un resultado local, no física 3D, captura de movimiento ni un motor reglamentario profesional. La evaluación perceptual de Mati/Basti y el rendimiento térmico/GPU en iPad físico no se sustituyen con XCTest o video de Simulator.

Siguiente rol: revisión perceptual de Mati/Basti en iPad físico. Implementación y QA local completas. Este pedido no publica una build nueva: sin commit, push, merge ni carga a TestFlight en esta iteración. Commit sugerido: `feat: add varied match plays and coordinated movement`.
