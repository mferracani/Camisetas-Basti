# Decisions Log

Este archivo guarda decisiones durables. No registrar opiniones pasajeras; solo decisiones que afecten producto, arquitectura, validacion o handoff.

## 2026-05-15 - AGENTS.md es canonico para agentes

**Decision:** `AGENTS.md` pasa a ser la instruccion canonica de arranque para Codex/Claude/OpenCode/OpenClaw. La carpeta `.project/` contiene estado, backlog estructurado, validacion, handoff y decisiones.

**Rationale:** El repo ya tiene app funcional y varios documentos historicos. Un agente nuevo necesita saber que leer primero y que archivo manda cuando hay drift.

**Revisitar si:** Se migra a otra herramienta de agentes o aparece un archivo de autoridad superior acordado por el usuario.

## 2026-05-15 - `project.yml` manda para configuracion Xcode

**Decision:** Cambios de targets, signing, bundle id, sources o scheme deben hacerse primero en `project.yml` y despues regenerar con `xcodegen generate`.

**Rationale:** El repo ya contiene `project.yml` y `.xcodeproj`. Editar el `.pbxproj` manualmente aumenta el riesgo de drift.

**Revisitar si:** El proyecto deja de usar XcodeGen.

## 2026-05-15 - iPad landscape es la superficie principal

**Decision:** Las validaciones UX deben priorizar iPad horizontal, especialmente 10 y 12/13 pulgadas.

**Rationale:** El uso real es TestFlight en iPad para Bastian. Varias decisiones de UI previas se corrigieron por verse chicas o poco claras en iPad.

**Revisitar si:** Se crea y valida un target real para iPhone o macOS.

## 2026-05-15 - La app sigue siendo offline-first

**Decision:** No agregar dependencias de internet en runtime para camisetas, escudos, fixture, progreso o simulaciones.

**Rationale:** El producto esta pensado para ninos, viajes y uso sin WiFi. El PRD y el estado actual sostienen app local sin login/backend.

**Revisitar si:** El usuario pide sincronizacion multi-dispositivo o contenido remoto y aprueba un cambio de alcance.

## 2026-05-15 - TestFlight requiere evidencia separada

**Decision:** Build/tests verdes no equivalen a listo para TestFlight. Archive/upload requiere signing, certificados y App Store Connect.

**Rationale:** El bloqueo conocido esta en permisos/certificados durante codesign. Un agente no debe declarar release listo sin validar archive.

**Revisitar si:** Se automatiza signing o se documenta un pipeline reproducible.

## 2026-06-02 - Harness multi-runner con context budget explicito

**Decision:** El harness contempla explicitamente que la misma tarea puede ser tomada por distintos runners (`codex`, `opencode`, `openclaw`, `external`) y obliga a declarar `runner` y `context_level` (`quick`, `standard`, `deep`) antes de editar. La definicion vive en `.project/context-budget.md` y se referencia desde `AGENTS.md`, `.project/state.md` y `.project/feature-list.json` (campos `runner_compat`, `context_budget`, `active_session`).

**Rationale:** Codex y OpenCode cuestan tokens por lectura. Sin un tier explicito, cada agente leia el repo entero "por las dudas". El budget acota la lectura por defecto, deja escalado explicito y permite alternar runner sin perder estado.

**Revisitar si:** Aparece un runner nuevo que no encaja en la lista, o si los tiers `quick/standard/deep` resultan insuficientes para algun tipo de tarea recurrente.
