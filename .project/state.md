# Project State

## Fase actual
liga-argentina-verified

## Gate status
- [x] Gate 1: PRD aprobado
- [x] Gate 2: UX aprobado
- [x] Gate 3: Build completo

## Decisiones tomadas
- Liga Argentina 2026 ampliada a los 30 clubes de Primera División publicados por LPF/AFA. En `SIMULAR TORNEO` usa una llave de 32 plazas, con dos pases libres distribuidos entre ambos lados; las ligas de hasta 16 equipos conservan su llave anterior. Se agregaron 14 clubes al catálogo argentino, manteniendo funcionamiento offline y camisetas estilizadas. Verificación: 67 tests unitarios, un XCUITest focal y build Release correctos. Detalle en `.project/liga-argentina-2026.md`.
- Verificación del incremento camisetas/pelota parada: 139 equipos jugables y 278 kits con selección explícita sin recolor sintético; tiros libres con barrera y penales dentro del partido; mismo kit en tanda final. 64 unit tests y cuatro XCUITests focales pasaron, builds Debug/Release correctos, sin publicar. Fuentes/gaps de camisetas en `.project/kit-audit-2026-09-07.md`; no implica autenticación de temporada de todas las ediciones.
- Iteración siguiente 2026-09-07: Mati aprobó la presentación anterior ("quedo muy bien") y pidió verificar colores/diseños reales de todos los equipos y simular tiros libres y penales. Se continúa dentro del modal y timeline aprobados, sin controles nuevos, física 3D ni cambios de resultado/duración. La fidelidad se verifica sobre las ediciones existentes; una actualización de temporada requiere definir la edición, porque el catálogo mezcla assets sin procedencia.
- Iteración 2026-09-07 solicitada por Mati e implementada: jugadores articulados, movimiento sin frenadas sincronizadas, pelota continua con sombra/altura, estadio y festejos coordinados. Se reutilizaron los gates del flujo aprobado (90–110 segundos, 22 jugadores, cámara fija, offline).
- Ritmo 2026-09-07: arranque de tres pases por equipo para llegar antes al primer remate, conservando resultados y duración total. Gol detrás de línea y camisetas alternativas con contraste. Verificación: 48 tests unitarios y dos XCUITests focales pasaron; detalle y límites en `.project/match-experience-2026-09-07.md`.
- La seccion torneos tendra dos modalidades: avance manual actual y nueva simulacion automatica por partido.
- La simulacion debe funcionar offline y estar optimizada para iPad 10 y 12/13 pulgadas en horizontal.
- Cada partido simulado durara entre 90 y 110 segundos con resultados plausibles y aleatorios.
- UX define un control segmentado Manual/Partidos y modal full-screen de partido con marcador, cancha, eventos y cierre final.
- Implementacion completada: modo Manual/Partidos, modal de partido animado, resultados plausibles, penales y avance automatico del ganador.
- Ajuste de realismo: la simulacion ahora usa pases entre jugadores, remates visibles al arco, pelota entrando al arco y camisetas con colores mas distinguibles.
- Realismo narrativo v2 (2026-08-22): cada partido usa una unica timeline deterministica de saque, conduccion, pases, presion, duelos, intercepciones, quites, remates y reposiciones; la pelota y las posiciones son continuas entre eventos.
- La cancha usa 11 jugadores por equipo en formación 4-3-3, con marcadores compactos numerados; roles visuales de poseedor/receptor/defensor, reacción del arquero y separación corregida por aspecto durante toda la trayectoria.
- Los remates distinguen gol, atajada, afuera y bloqueo; solo los goles de la timeline modifican el marcador y coinciden con el resultado final.
- Resultado y timeline se conservan juntos en un unico `MatchSimulation` para evitar desincronizacion ante reconstrucciones SwiftUI.
- Los reinicios nacen desde posiciones futbolisticas validas, `Reduce Motion` usa estados discretos y VoiceOver recibe un unico relato de minuto, marcador y jugada.
- Ajuste de ritmo (2026-08-24): el partido dura 90-110 segundos, `Reduce Motion` usa 100 segundos y las tandas duran 70 segundos para que cada jugada se lea con mayor claridad.
- Ajuste de cancha (2026-08-24): la simulación muestra 22 jugadores y hace circular el balón por toda la línea de campo; los marcadores se redujeron para sostener lectura realista en iPad.
- Realismo táctico v3 (2026-08-24): las jugadas progresan por líneas (defensa, mediocampo, extremos y 9), la presión y los quites comienzan cerca de la pelota, los jugadores no se rearman de golpe entre beats y los desbordes terminan en centros curvos hacia el delantero. Los marcadores ahora son mini-camisetas con dorsales de mayor tamaño y el solver preserva separación visual durante toda la transición.
- Verificación de realismo táctico v3 (2026-08-24): `MatchSimulationFactoryTests` pasa 15/15 en iPad (A16), incluyendo continuidad de timeline, pases por líneas, presiones locales, centros al 9, tiros afuera y separación de 22 jugadores durante la interpolación.
- Nueva seccion en Mundial 2026: Fixture Mundial con zonas, carga manual de resultados, tablas, mejores terceros y llaves desde 16avos hasta final.
- Build de simulador y suite unitaria pasan: 36 tests, 0 fallos, en iPad (A16) iOS 26.4 el 2026-08-22.
- La simulacion de partidos ahora pondera equipos por calidad/ranking local offline: favoritos tienen mas chances de ganar, pero siguen existiendo empates, penales y sorpresas.
- En llaves, los empates definidos por penales ahora muestran una tanda visual de 5 penales por equipo, alternados, con pateador, pelota viajando al arco, arquero, gol/atajada y tribuna de fondo.
- La vista de llaves del Mundial ahora usa un bracket horizontal simetrico con 16avos/octavos/cuartos/semifinales convergiendo en la final central, copa generada como asset local y celebracion de campeon con confeti y fuegos artificiales.
- El sorteo aleatorio del Mundial permite editar equipos antes de mezclar zonas; Argentina, Brasil, Espana, Francia e Inglaterra quedan fijos y los demas pueden entrar/salir desde una grilla con banderas y nombres en mayusculas.
- Correccion 2026-07-17: los controles `EQUIPOS` y `ALEATORIO` se muestran dentro de `SIMULAR TORNEO > MUNDIAL 2026`, que es el flujo real de juego. Mantienen las simulaciones de partidos y el bracket existente.
- `SIMULAR TORNEO` abre por defecto en `MUNDIAL 2026` y muestra opciones explicitas `ORIGINAL`, `ALEATORIO`, `EQUIPOS` y `SIMULAR TODO` para que el flujo no dependa de descubrir el selector.
- Diagnostico build 13: se archivo desde el checkout `task/project-harness-runner-toggle`, cuyo `TournamentSimulatorView` filtraba `wc26`; por eso TestFlight no mostraba el Mundial aunque la correccion ya estaba en `main`.
- Los releases ahora deben usar `scripts/archive-testflight.sh`, que exige `main` limpio y sincronizado y valida los marcadores funcionales del Mundial antes de archivar.

## Handoffs pendientes
- Liga Argentina implementada y verificada en `codex/feat-liga-argentina`; pendiente revisión de Mati y decisión de commit/publicación. Replicar el formato oficial de dos zonas del Apertura/Clausura queda fuera de este incremento: la pantalla mantiene eliminación directa.
- Incremento camisetas/pelota parada implementado y verificado localmente; siguiente paso: revisión visual de Mati y decisión sobre temporadas sin referencia/publicación. Video real de dos jugadas y detalles en `.project/match-kits-set-pieces-2026-09-07.md`. No requiere repetir gates del mismo alcance; commit/push sólo cuando se soliciten.
- Iteración de presentación 2026-09-07: cambios locales verificados en `codex/feat-realistic-match-simulation`, pendientes de revisión del usuario y publicación; sin commit/push/merge. Vista Debug `--match-preview` para revisar en Simulator. Documentación: `.project/match-experience-2026-09-07.md`.
- Mejora de simulacion v2 publicada en `codex/feat-realistic-match-simulation`; pendiente revision/merge por el usuario. No se hizo merge ni deploy.
- Antes del proximo TestFlight: smoke manual especifico con `Reduce Motion` y agregar cobertura XCUITest del flujo torneo → partido → cerrar → avance de llave.
- Build 2 subido a App Store Connect/TestFlight el 2026-06-20.
- Build 3 archivado localmente el 2026-06-20 en `build/TestFlight/CamisetasBasti-build3.xcarchive`.
- Build 11 subido a App Store Connect/TestFlight el 2026-07-16 desde commit `852ee85`; App Store Connect lo muestra `Finalizado` y `Lista para enviar`.
- Pendiente: subir el build 14 o posterior desde `main`. El archive correcto compila hasta `CodeSign`, pero el llavero requiere autorizacion local de la clave privada; los builds 12 y 13 existentes se generaron desde el checkout equivocado y no contienen la entrada al Mundial en `SIMULAR TORNEO`.

## Open questions
- Si se quiere probar en TestFlight externo, asignar build 11 al grupo de testers que corresponda.
