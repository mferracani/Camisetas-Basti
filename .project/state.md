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
- Build de simulador y tests pasan.

## Handoffs pendientes
- Archive para TestFlight pendiente de permiso de llavero/certificado durante codesign.

## Open questions
- Desbloquear codesign en Xcode/Keychain y volver a correr Archive.
