# Project State

Ultima actualizacion: 2026-06-02

## Sesion activa

- `runner`: opencode
- `context_level`: quick
- `task_slug`: task/project-harness-runner-toggle
- `task_id`: project-harness
- `started`: 2026-06-02
- `scope`: Soporte multi-runner (Codex/OpenCode) y context budget en harness sin tocar codigo Swift.
- `escalated_from`: ninguno. La lectura excedio quick para entender un WIP previo sin commit (state.md, handoff.md, decisions.md, validation.md); el costo fue de sincronizacion defensiva, no de la tarea.

## Snapshot

- Proyecto: Camisetas Basti
- Superficie principal: iPad landscape, iOS/iPadOS 16+
- Stack: SwiftUI, XcodeGen, UserDefaults, assets locales
- Repo real: `Camisetas-Basti`
- Branch esperada: `main`
- Estado de producto: app funcional con pintura de camisetas, equipos, Mundial 2026, torneo simulado, fixture mundial y preparacion TestFlight.

## Fase actual

`ready-for-testflight-validation`

La app compila y los tests pasan en simulador. El archive/subida TestFlight sigue dependiendo de signing, certificados y permisos de Xcode/App Store Connect.

## Estado reciente

- PRD, UX spec, backend/local data spec, security review y QA checklist existen.
- `project.yml` define el target principal y debe ser fuente para cambios de configuracion Xcode.
- Simulador de torneos tiene modo manual y modo partido simulado.
- Simulacion de partido fue mejorada con jugadores mas activos, pases, remates, atajadas y goles visibles.
- Fixture Mundial 2026 existe con grupos, resultados manuales, tablas y llaves.
- Contenido de camisetas y escudos fue actualizado en varias tandas.

## Validacion conocida

- Build simulador: OK el 2026-05-15.
- Tests: OK el 2026-05-15, 22 tests ejecutados, 0 fallas.
- JSON harness: OK el 2026-06-02 (revalidado tras incorporar `context_budget` y `runner_compat`).
- Archive/TestFlight: pendiente por signing/certificados.

## Active focus

Mantener la app estable para pruebas en TestFlight y seguir iterando:

1. UX/motion de simulacion de partidos.
2. Fixture Mundial 2026 y reglas de clasificacion.
3. Carga incremental de camisetas/escudos.
4. Ajustes de pintura y progreso para que Bastian no encuentre fricciones.

## Proxima accion recomendada

Para cambios de producto posteriores, actualizar `.project/feature-list.json` y `.project/handoff.md` antes de cerrar.

## Blockers / unknowns

- Signing y archive para TestFlight requieren permisos/certificados locales.
- `ASSETS.md` menciona fuentes y sonidos faltantes, pero el estado real debe verificarse contra `Resources/` antes de tocar release.
- README/PRD historicos todavia describen macOS como parte de la vision; `project.yml` actual solo declara target iOS. Tratar macOS como TODO/unknown hasta que exista target real.
- No hay comando de lint dedicado.
