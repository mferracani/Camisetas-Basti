# Context Budget

Ultima actualizacion: 2026-06-02

## Principio

El repo se trabaja indistintamente desde varios runners (Codex CLI, OpenCode, OpenClaw u otros). Cada lectura cuesta tokens. Antes de empezar, cada agente elige un `contextLevel` y lee solo lo permitido por ese tier. Si la tarea cambia de alcance, se sube de tier explicitamente y se anota.

No es un techo duro: es un default. Excederlo esta permitido cuando hay evidencia (un blocker, un conflicto entre documentos, un pedido nuevo). En ese caso registrar el motivo en `.project/handoff.md` o en la sesion activa de `.project/state.md`.

## Runners soportados

| runner       | uso tipico                                       | notas de coste                                |
|--------------|--------------------------------------------------|-----------------------------------------------|
| `codex`      | Codex CLI                                        | tokens caros; preferir `quick` o `standard`   |
| `opencode`   | OpenCode CLI                                     | tokens caros; preferir `quick` o `standard`   |
| `openclaw`   | runner local autonomo del proyecto               | sin coste de tokens externos                  |
| `external`   | humano en Xcode/CLI sin agente LLM               | sin coste de tokens                           |
| `any`        | cualquiera de los anteriores puede tomarla       | metadata de feature, no de sesion             |

Una sesion activa siempre declara un runner concreto (`codex`, `opencode`, `openclaw` o `external`). `any` solo aparece como compatibilidad declarada en la feature.

## Tiers

### quick

**Cuando usar:** docs/harness, content tweaks chicos, fixes obvios de una sola feature ya conocida, decisiones de rutas o naming, mantenimiento de `.project/`.

**Lectura permitida:**

- `AGENTS.md`
- `.project/state.md`
- `.project/feature-list.json` (solo la feature activa; el resto se hojea si hace falta)
- `.project/context-budget.md`

**No leer en quick:** PRD.md, ux-spec.md, backend-spec.md, qa-checklist.md, security-review.md, README.md, ASSETS.md, TESTFLIGHT.md, codigo Swift, assets.

**Excepcion permitida:** abrir el `source_of_truth` declarado por la feature activa solo si el cambio toca ese archivo directamente.

### standard

**Cuando usar:** cambios acotados de codigo dentro de una sola feature, ajustes de UI/UX que no rediseñan flujo, correcciones de datos en `Data/CAMI_DATA.swift`, fixes de tests existentes.

**Lectura permitida:** todo lo de `quick` mas:

- `.project/validation.md`
- `.project/handoff.md`
- `.project/decisions.md`
- `source_of_truth` completo de la feature activa
- `allowed_write_areas` completos de la feature activa
- Tests relacionados (`CamisetasBastiTests/`, `CamisetasBastiUITests/`) si la feature los lista

**No leer en standard:** documentos historicos (PRD, README, ASSETS, TESTFLIGHT), specs de otras features, codigo de areas no listadas en la feature.

### deep

**Cuando usar:** cambios cross-feature, refactors estructurales, decisiones de producto, releases, auditorias de privacidad, debugging que requiere ver toda la cadena, cualquier cosa que reescriba el harness.

**Lectura permitida:** todo lo anterior mas:

- `PRD.md` y `.project/prd.md`
- `.project/ux-spec.md`
- `.project/backend-spec.md`
- `.project/qa-checklist.md`
- `.project/security-review.md`
- `README.md`, `ASSETS.md`, `TESTFLIGHT.md`
- Codigo Swift segun necesidad

En `deep` igual conviene leer en orden y parar cuando alcance: no leer todo el repo por defecto.

## Como elegir el tier

1. Releer la instruccion de la tarea.
2. Identificar la feature afectada en `.project/feature-list.json`.
3. Mapear el cambio:
   - solo docs/harness o un archivo de `.project/` -> `quick`
   - codigo dentro de `allowed_write_areas` de una sola feature -> `standard`
   - varias features, refactor o release -> `deep`
4. Si dudas entre dos tiers, empezar por el menor. Subir cuando aparezca evidencia (conflicto, blocker, archivo no permitido pero necesario).

## Como registrar la sesion

Al elegir el tier, registrar antes de empezar a editar:

1. En `.project/state.md`, bloque `## Sesion activa`:
   - `runner`: codex | opencode | openclaw | external
   - `context_level`: quick | standard | deep
   - `task_slug`: rama o slug
   - `started`: fecha ISO
   - `scope`: una linea
2. En `.project/feature-list.json`, campo `active_session` a nivel raiz con los mismos datos.
3. Si la sesion sube de tier durante el trabajo, anotar el motivo en la misma seccion (`escalated_from`).

Al cerrar, mover el contenido de `active_session` a un breve resumen en `.project/handoff.md` o limpiarlo si la tanda no dejo trabajo pendiente.

## Reglas de escalado

- Si una tarea declarada `quick` necesita leer codigo Swift o specs, subir a `standard` antes de leer y anotar el motivo.
- Si una tarea `standard` necesita tocar varias features o documentos de producto, subir a `deep` antes de leer.
- Bajar de tier no esta permitido durante la sesion: una vez que se leyo algo no se "des-lee". Si la siguiente tanda puede arrancar mas chica, dejarlo registrado en handoff.

## Anti-patrones

- Leer `PRD.md` o `README.md` "por las dudas" antes de saber la tarea.
- Leer todo `.project/` en tareas de codigo sin tocar el harness.
- Recorrer `Data/CAMI_DATA.swift` entero para cambiar un solo equipo.
- Abrir varios `Views/*.swift` sin que la feature activa los liste.
- No registrar runner ni contextLevel y dejar al siguiente agente adivinando que se leyo.
