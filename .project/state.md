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
- Cada partido simulado durara entre 30 y 45 segundos con resultados plausibles y aleatorios.
- UX define un control segmentado Manual/Partidos y modal full-screen de partido con marcador, cancha, eventos y cierre final.
- Implementacion completada: modo Manual/Partidos, modal de partido animado, resultados plausibles, penales y avance automatico del ganador.
- Ajuste de realismo: la simulacion ahora usa pases entre jugadores, remates visibles al arco, pelota entrando al arco y camisetas con colores mas distinguibles.
- Nueva seccion en Mundial 2026: Fixture Mundial con zonas, carga manual de resultados, tablas, mejores terceros y llaves desde 16avos hasta final.
- Build de simulador y tests pasan.
- La simulacion de partidos ahora pondera equipos por calidad/ranking local offline: favoritos tienen mas chances de ganar, pero siguen existiendo empates, penales y sorpresas.
- En llaves, los empates definidos por penales ahora muestran una tanda visual de 5 penales por equipo, alternados, con pateador, pelota viajando al arco, arquero, gol/atajada y tribuna de fondo.
- La vista de llaves del Mundial ahora usa un bracket horizontal simetrico con 16avos/octavos/cuartos/semifinales convergiendo en la final central, copa generada como asset local y celebracion de campeon con confeti y fuegos artificiales.
- El sorteo aleatorio del Mundial permite editar equipos antes de mezclar zonas; Argentina, Brasil, Espana, Francia e Inglaterra quedan fijos y los demas pueden entrar/salir desde una grilla con banderas y nombres en mayusculas.
- Correccion 2026-07-17: los controles `EQUIPOS` y `ALEATORIO` se muestran dentro de `SIMULAR TORNEO > MUNDIAL 2026`, que es el flujo real de juego. Mantienen las simulaciones de partidos y el bracket existente.
- `SIMULAR TORNEO` abre por defecto en `MUNDIAL 2026` y muestra opciones explicitas `ORIGINAL`, `ALEATORIO`, `EQUIPOS` y `SIMULAR TODO` para que el flujo no dependa de descubrir el selector.
- Diagnostico build 13: se archivo desde el checkout `task/project-harness-runner-toggle`, cuyo `TournamentSimulatorView` filtraba `wc26`; por eso TestFlight no mostraba el Mundial aunque la correccion ya estaba en `main`.
- Los releases ahora deben usar `scripts/archive-testflight.sh`, que exige `main` limpio y sincronizado y valida los marcadores funcionales del Mundial antes de archivar.

## Handoffs pendientes
- Build 2 subido a App Store Connect/TestFlight el 2026-06-20.
- Build 3 archivado localmente el 2026-06-20 en `build/TestFlight/CamisetasBasti-build3.xcarchive`.
- Build 11 subido a App Store Connect/TestFlight el 2026-07-16 desde commit `852ee85`; App Store Connect lo muestra `Finalizado` y `Lista para enviar`.
- Pendiente: subir el build 14 o posterior desde `main`. El archive correcto compila hasta `CodeSign`, pero el llavero requiere autorizacion local de la clave privada; los builds 12 y 13 existentes se generaron desde el checkout equivocado y no contienen la entrada al Mundial en `SIMULAR TORNEO`.

## Open questions
- Si se quiere probar en TestFlight externo, asignar build 11 al grupo de testers que corresponda.
