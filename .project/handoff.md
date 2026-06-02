# Handoff

Ultima actualizacion: 2026-06-02

## Para el proximo agente

Arrancar leyendo:

1. `AGENTS.md`
2. `.project/state.md`
3. `.project/feature-list.json`
4. `.project/context-budget.md`
5. Resto segun el tier elegido

El repo esta en `main` y la app viene de varias iteraciones de contenido, torneo, fixture mundial, pintura y TestFlight. No asumir que `README.md` y `PRD.md` describen el estado exacto actual: son fuente historica/producto, pero el codigo y `.project/state.md` mandan para ejecucion.

Antes de editar, registrar `runner` y `context_level` en `state.md` y `feature-list.json.active_session`. Ver `.project/context-budget.md` para reglas y tiers.

## Estado actual

- Build y tests pasaron el 2026-05-15 antes de crear este harness.
- Ultimo commit funcional antes del harness: `99ca82a Improve simulated match motion`.
- El usuario suele pedir cambios y push a `main` para probar en Xcode/TestFlight.
- La app debe seguir funcionando offline.

## Pendiente operativo

- Si se modifica `project.yml`, correr `xcodegen generate`.
- Para TestFlight, resolver signing/certificados segun `TESTFLIGHT.md`.

## Contexto de producto

- Bastian es el usuario final principal. Las decisiones de UX tienen que priorizar claridad visual, tactilidad, iPad horizontal y baja frustracion.
- En pintura, la camiseta debe venir grisada y revelarse con el dedo; el fondo no debe contar como area pendiente.
- En torneo, la simulacion debe mostrar causa-efecto visible: jugadores, pelota, pase, remate, atajada/gol.
- En Mundial 2026, el fixture y reglas son datos sensibles a cambios reales; verificar fuente oficial antes de corregir horarios/reglas.

## Como dejar un nuevo handoff

Agregar una entrada breve debajo de esta linea con:

- Fecha
- Que cambio
- Validacion corrida
- Pendiente o blocker

## Log

### 2026-06-02 - Harness multi-runner + context budget

- Runner: opencode. Context level: quick.
- Rama: `task/project-harness-runner-toggle`.
- Se adopto como baseline un WIP del harness que estaba sin commit en `main` (autoria previa, posiblemente Codex u OpenClaw). Commit: `Adopt project harness WIP as baseline`.
- Se agrego `.project/context-budget.md` con tiers `quick`, `standard`, `deep` y lista de runners (`codex`, `opencode`, `openclaw`, `external`, `any`).
- `AGENTS.md` ahora pide registrar `runner` y `context_level` antes de editar, e incorpora el budget al orden de lectura.
- `feature-list.json` subio a `schema_version: 2`: agrega `runners`, `context_levels`, `runner_compat` y `context_budget` por feature, y un objeto raiz `active_session`. Se renombro `OpenClaw` -> `autonomous` en `execution_modes` (no estaba en uso en ninguna feature).
- Validacion: `python3 -m json.tool .project/feature-list.json` OK; `git diff --check` OK.
- Pendiente: commitear estos cambios si el usuario lo pide, y eventualmente pushear `task/project-harness-runner-toggle`.

### 2026-05-15 - Project Harness

- Se creo/actualizo harness canonico para agentes.
- Archivos principales: `AGENTS.md`, `.project/state.md`, `.project/feature-list.json`, `.project/validation.md`, `.project/handoff.md`, `.project/decisions.md`.
- Validacion: JSON valido, `git diff --check` OK, referencias principales existen.
- Pendiente: commitear/pushear si el usuario lo pide.
