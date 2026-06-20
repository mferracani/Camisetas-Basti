# TestFlight Checklist

## Estado del proyecto

- Abrir en Xcode: `CamisetasBasti.xcodeproj`
- Scheme: `CamisetasBasti`
- Target: iPad only
- Orientacion iPad: landscape left/right
- Bundle ID actual: `com.camisetasbasti.app`
- Version: `1.0.0`
- Build: `3`
- App icon: incluido en `Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png`

## Antes de archivar

1. En Xcode, seleccionar el target `CamisetasBasti`.
2. Entrar a `Signing & Capabilities`.
3. Activar `Automatically manage signing`.
4. Seleccionar el Apple Developer Team correcto.
5. Si App Store Connect rechaza el Bundle ID actual, cambiar `PRODUCT_BUNDLE_IDENTIFIER` en `project.yml` y regenerar con `xcodegen generate`.

## Archive

1. Seleccionar destino `Any iOS Device (arm64)` o un device real.
2. Usar `Product > Archive`.
3. Cuando termine, abrir Organizer.
4. Validar el archive.
5. Subir con `Distribute App > App Store Connect > Upload`.

## Notas

- El proyecto no usa backend, login, tracking ni ads.
- El contenido y progreso son locales.
- Para un nuevo build de TestFlight, incrementar `CURRENT_PROJECT_VERSION` en `project.yml` y regenerar el proyecto.
- Si `xcodebuild archive -allowProvisioningUpdates` falla con `PLA Update available`, aceptar el Program License Agreement pendiente en Apple Developer para el Team `Q2TG5FA7M7` y volver a correr el archive.

## Ultimo upload

- Build `2` subido a App Store Connect/TestFlight el 2026-06-20 con:

```bash
xcodebuild archive -project CamisetasBasti.xcodeproj -scheme CamisetasBasti -configuration Release -destination generic/platform=iOS -archivePath build/TestFlight/CamisetasBasti.xcarchive -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath build/TestFlight/CamisetasBasti.xcarchive -exportPath build/TestFlight/export -exportOptionsPlist ExportOptions-TestFlight.plist -allowProvisioningUpdates
```

## Ultimo archive local

- Build `3` archivado correctamente el 2026-06-20 en:

```bash
build/TestFlight/CamisetasBasti-build3.xcarchive
```
