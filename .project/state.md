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

## Handoffs pendientes
- Build 2 subido a App Store Connect/TestFlight el 2026-06-20.
- Build 3 archivado localmente el 2026-06-20 en `build/TestFlight/CamisetasBasti-build3.xcarchive`.
- Subir build 3 a App Store Connect/TestFlight si se quiere publicar esta tanda de cambios.

## Open questions
- Confirmar si build 3 reemplaza al build 2 para testers de TestFlight.
