# Validation Contract

Ultima actualizacion: 2026-05-15

## Principio

No declarar una tarea lista sin evidencia. Si una validacion no se puede correr por permisos, certificados o entorno, dejarlo explicito en el cierre y en `.project/handoff.md` si afecta al siguiente agente.

## Entorno esperado

- macOS con Xcode instalado.
- XcodeGen disponible como `xcodegen` para regenerar `CamisetasBasti.xcodeproj` desde `project.yml`.
- Simulador iPad disponible. El destino usado hasta ahora es `iPad Pro 13-inch (M5)`.
- No se requiere internet para ejecutar la app. GitHub/TestFlight si requieren red o credenciales.

## Comandos

### Ver estado antes de editar

```bash
git status --short --branch
```

### Validar harness/docs

```bash
python3 -m json.tool .project/feature-list.json
git diff --check
```

Usar para cambios en `AGENTS.md`, `.project/*`, `README.md`, `TESTFLIGHT.md`, `ASSETS.md`.

### Regenerar proyecto Xcode

```bash
xcodegen generate
```

Usar cuando cambia `project.yml`. Despues revisar el diff de `CamisetasBasti.xcodeproj/project.pbxproj` y correr build.

### Build de simulador

```bash
xcodebuild -project CamisetasBasti.xcodeproj -scheme CamisetasBasti -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build
```

Usar para cambios Swift, assets, datos, Info.plist o configuracion del proyecto.

### Tests

```bash
xcodebuild test -project CamisetasBasti.xcodeproj -scheme CamisetasBasti -configuration Debug -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -derivedDataPath build/DerivedData
```

Usar para cambios en:

- `Services/ProgressStore.swift`
- `Views/PaintView.swift`
- `Views/TournamentSimulatorView.swift`
- `Views/WorldCupFixtureView.swift`
- modelos/datos compartidos
- tests

Evidencia esperada: `** TEST SUCCEEDED **` y cantidad de tests ejecutados.

### Archive / TestFlight

Ver `TESTFLIGHT.md`.

No correr archive como validacion automatica si falta acceso a certificados, llavero o App Store Connect. Si se intenta, documentar el comando exacto y el error.

## Que cuenta como evidencia

- Comando ejecutado y resultado.
- Para tests, cantidad de tests y fallas.
- Para cambios visuales, captura o descripcion concreta de smoke manual si se uso simulador/Xcode.
- Para assets, build exitoso y lista de assets faltantes si aplica.

## Gaps conocidos

- No hay lint dedicado.
- No hay test automatizado especifico del flujo completo de torneo/fixture; se valida por build y smoke manual cuando sea posible.
- `ASSETS.md` puede estar desactualizado respecto de assets reales cargados; verificar `Resources/` antes de afirmar faltantes.
- Archive/TestFlight depende de signing local y no es validacion reproducible para todos los agentes.
