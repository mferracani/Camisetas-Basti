# Project Harness - Camisetas Basti

Este archivo es la instruccion canonica para agentes que trabajen en este repo. El objetivo es que cualquier agente pueda arrancar rapido, entender el estado real y cerrar con evidencia.

## Proyecto

**Camisetas Basti** es una app iPad-first en SwiftUI para que un nino pinte, descubra y coleccione camisetas de futbol sin internet. El repo actual contiene la app iOS, datos locales, tests, torneo simulado, fixture mundial y preparacion para TestFlight.

## Orden de lectura al arrancar

1. `AGENTS.md`
2. `.project/state.md`
3. `.project/feature-list.json`
4. `.project/context-budget.md`
5. `.project/validation.md` (segun tier)
6. `.project/handoff.md` (segun tier)
7. `.project/decisions.md` (segun tier)
8. Documentos fuente segun la tarea: `PRD.md`, `.project/ux-spec.md`, `.project/backend-spec.md`, `.project/qa-checklist.md`, `TESTFLIGHT.md`, `ASSETS.md`, `README.md`

Cada lectura cuesta tokens. Antes de abrir nada mas alla del item 4, elegir el `context_level` segun `.project/context-budget.md` y leer solo lo permitido por ese tier.

Si hay contradiccion entre documentos, gana el codigo actual y despues `.project/state.md`. Si sigue habiendo conflicto, marcarlo como blocker antes de inventar.

## Runners y presupuesto de contexto

El repo se trabaja desde varios runners. Una sesion siempre declara cual:

- `codex` - Codex CLI
- `opencode` - OpenCode CLI
- `openclaw` - runner autonomo local
- `external` - humano en Xcode/CLI sin LLM

Tiers de contexto: `quick`, `standard`, `deep`. Definicion completa en `.project/context-budget.md`.

Antes de editar, registrar `runner` y `context_level` en:

1. `.project/state.md` -> seccion `## Sesion activa`.
2. `.project/feature-list.json` -> campo `active_session`.

Si la sesion necesita subir de tier (por ejemplo, una tarea declarada `quick` requiere leer codigo Swift), subir antes de leer y anotar el motivo (`escalated_from`).

## Stack real

- SwiftUI app iOS/iPadOS 16+, iPad landscape como superficie principal.
- Proyecto Xcode generado por `project.yml` con XcodeGen.
- Scheme principal: `CamisetasBasti`.
- Persistencia local con `UserDefaults` via `ProgressStore`.
- Sin backend, login, analytics, ads ni dependencias remotas de runtime.
- Tests: `CamisetasBastiTests` y `CamisetasBastiUITests`.

## Comandos base

Regenerar proyecto si cambia `project.yml`:

```bash
xcodegen generate
```

Build de simulador:

```bash
xcodebuild -project CamisetasBasti.xcodeproj -scheme CamisetasBasti -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build
```

Tests unitarios/UI configurados en scheme:

```bash
xcodebuild test -project CamisetasBasti.xcodeproj -scheme CamisetasBasti -configuration Debug -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -derivedDataPath build/DerivedData
```

Archive/TestFlight: ver `TESTFLIGHT.md`. No declarar listo para TestFlight si no se valido signing/archive.

## Reglas de autonomia

- Avanzar sin preguntar cuando el pedido sea claro y el cambio sea reversible.
- No revertir cambios ajenos. Revisar `git status --short --branch` antes de editar.
- Mantener el alcance chico: no refactors amplios si el pedido es de contenido, UI o harness.
- No tocar signing, bundle id, versionado de build, assets de produccion o reglas de TestFlight sin validar impacto.
- No usar internet ni servicios externos como dependencia de app. La experiencia debe funcionar offline.
- No borrar, renombrar ni mover carpetas grandes sin aprobacion.
- Para UI de Bastian, priorizar iPad landscape, targets tactiles grandes, feedback visual inmediato y cero friccion lectora.

## Areas de escritura habituales

- Codigo Swift: `Views/`, `Components/`, `Models/`, `Data/`, `Services/`, `Utils/`, `CamisetasBastiApp.swift`
- Tests: `CamisetasBastiTests/`, `CamisetasBastiUITests/`
- Assets: `Resources/Assets.xcassets/`, `Resources/Info.plist` cuando corresponda
- Harness/docs: `.project/`, `AGENTS.md`, `README.md`, `TESTFLIGHT.md`, `ASSETS.md`

Evitar tocar archivos generados de `CamisetasBasti.xcodeproj` manualmente si el cambio corresponde a `project.yml`.

## Validacion antes de cerrar

Elegir la validacion minima segun el cambio:

- Docs/harness: validar Markdown por lectura y JSON con `python3 -m json.tool .project/feature-list.json`.
- Cambios Swift: correr build de simulador.
- Cambios en persistencia, pintura, torneo o fixture: correr build + tests.
- Cambios en `project.yml`: correr `xcodegen generate`, revisar diff del `.xcodeproj`, build.
- TestFlight/signing: validar en Xcode o con `xcodebuild archive` solo si hay certificados/permisos disponibles.

El cierre debe decir que se corrio, que paso y que quedo pendiente.

## Handoff limpio

Antes de terminar una tarea con cambios:

1. Actualizar `.project/state.md` si cambio el estado real. Limpiar o resumir `## Sesion activa` cuando la tanda termina.
2. Actualizar `.project/feature-list.json` si cambia una feature o task conocida. Vaciar o resumir `active_session` al cerrar.
3. Agregar decision durable en `.project/decisions.md` si se tomo una decision de producto/arquitectura.
4. Registrar contexto breve en `.project/handoff.md` si queda trabajo pendiente o hay una pista importante para el siguiente agente. Anotar `runner`, `context_level` usado y si hubo escalado de tier.
5. Dejar `git status` limpio si el usuario pidio commit/push; si no, reportar archivos modificados.

## Contrato para nuevas tareas

Cuando se agregue una tarea al harness o backlog, escribirla con estos campos:

- `objective`: resultado esperado.
- `source_of_truth`: archivos, screenshots o instrucciones que mandan.
- `deliverables`: archivos o comportamientos a entregar.
- `definition_of_done`: evidencia necesaria para cerrar.
- `allowed_write_areas`: rutas permitidas.
- `out_of_scope`: lo que no se toca.
- `validation_loop`: comandos/checks a correr.
- `execution_mode`: `autonomous`, `external-runner` o `either`.
- `runner_compat`: lista de runners que pueden tomarla (`codex`, `opencode`, `openclaw`, `external`, `any`).
- `context_budget`: `quick`, `standard` o `deep` sugerido para esa tarea.
- `recommended_owner`: PM, UX, SwiftUI, Data, Security o QA.
- `dependencies`: datos, assets, permisos o decisiones necesarias.
- `escalation_rule`: cuando frenar y pedir confirmacion.

## Agent Kit local

El repo conserva un kit de agentes en `.claude/agents/` y `.cursor/rules/`. Usarlo como especializacion, no como burocracia:

- Product Manager: alcance, decisiones y priorizacion.
- UX Designer: flujos, layout iPad landscape, microinteracciones.
- Local Data Designer: modelo local, assets, persistencia offline.
- SwiftUI Engineer: implementacion app.
- Security Reviewer: privacidad infantil, offline, datos locales.
- QA Engineer: test plan, regresiones y evidencia.

Los gates originales ya no reflejan el estado inicial del proyecto: PRD, UX y build base existen. El estado actual vive en `.project/state.md`.

## Escalar o pausar si

- Hay que borrar/renombrar archivos mayores.
- Hay conflicto entre documentos fuente que cambia producto.
- La validacion requiere credenciales, certificados, llavero, App Store Connect o deploy.
- Un cambio afecta privacidad infantil, datos persistidos o contenido licenciado.
- El repo aparece con multiples cambios ajenos que pisan el area de trabajo.
