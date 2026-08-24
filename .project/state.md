# Project State

## Fase actual
ready-for-testflight

## Gate status
- [x] Gate 1: PRD aprobado
- [x] Gate 2: UX aprobado
- [x] Gate 3: Build completo

## Decisiones tomadas
- La seccion torneos tendra dos modalidades: avance manual actual y nueva simulacion automatica por partido.
- La simulacion debe funcionar offline y estar optimizada para iPad 10 y 12/13 pulgadas en horizontal.
- Cada partido simulado durara entre 90 y 110 segundos con resultados plausibles y aleatorios.
- UX define un control segmentado Manual/Partidos y modal full-screen de partido con marcador, cancha, eventos y cierre final.
- Implementacion completada: modo Manual/Partidos, modal de partido animado, resultados plausibles, penales y avance automatico del ganador.
- Ajuste de realismo: la simulacion ahora usa pases entre jugadores, remates visibles al arco, pelota entrando al arco y camisetas con colores mas distinguibles.
- Realismo narrativo v2 (2026-08-22): cada partido usa una unica timeline deterministica de saque, conduccion, pases, presion, duelos, intercepciones, quites, remates y reposiciones; la pelota y las posiciones son continuas entre eventos.
- La cancha usa 6 jugadores por equipo, roles visuales de poseedor/receptor/defensor, reaccion del arquero y separacion corregida por aspecto durante toda la trayectoria.
- Los remates distinguen gol, atajada, afuera y bloqueo; solo los goles de la timeline modifican el marcador y coinciden con el resultado final.
- Resultado y timeline se conservan juntos en un unico `MatchSimulation` para evitar desincronizacion ante reconstrucciones SwiftUI.
- Los reinicios nacen desde posiciones futbolisticas validas, `Reduce Motion` usa estados discretos y VoiceOver recibe un unico relato de minuto, marcador y jugada.
- Ajuste de ritmo (2026-08-24): el partido dura 90-110 segundos, `Reduce Motion` usa 100 segundos y las tandas duran 70 segundos para que cada jugada se lea con mayor claridad.
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
- Mejora de simulacion v2 publicada en `codex/feat-realistic-match-simulation`; pendiente revision/merge por el usuario. No se hizo merge ni deploy.
- Antes del proximo TestFlight: smoke manual especifico con `Reduce Motion` y agregar cobertura XCUITest del flujo torneo → partido → cerrar → avance de llave.
- Build 2 subido a App Store Connect/TestFlight el 2026-06-20.
- Build 3 archivado localmente el 2026-06-20 en `build/TestFlight/CamisetasBasti-build3.xcarchive`.
- Build 11 subido a App Store Connect/TestFlight el 2026-07-16 desde commit `852ee85`; App Store Connect lo muestra `Finalizado` y `Lista para enviar`.
- Pendiente: subir el build 14 o posterior desde `main`. El archive correcto compila hasta `CodeSign`, pero el llavero requiere autorizacion local de la clave privada; los builds 12 y 13 existentes se generaron desde el checkout equivocado y no contienen la entrada al Mundial en `SIMULAR TORNEO`.

## Open questions
- Si se quiere probar en TestFlight externo, asignar build 11 al grupo de testers que corresponda.
