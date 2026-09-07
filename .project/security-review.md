# Security Review — Camisetas Basti

## Revisión incremental: juego colectivo — 2026-09-07

Revisión estática de generador táctico, planificación de cruces y relato del modal. El incremento no agrega red, URLs, analytics, identificadores, permisos, dependencias ni escritura en UserDefaults. `MatchPlayPattern` y las posiciones son datos efímeros del partido. Los nuevos puntos de entrada de QA quedan dentro del harness `#if DEBUG`; capturas/videos son artefactos locales, fuera del bundle. Sin hallazgos bloqueantes en este diff. Esta revisión técnica no certifica cumplimiento legal ni autoriza una publicación.

## Revisión incremental: motion natural — 2026-09-07

Revisión estática acotada a curvas/poses, renderer Canvas, reloj visual y tanda final. No incorpora red, URLs, analytics, logs de usuario, permisos, persistencia ni paquetes. El nuevo modelo importa únicamente Foundation. Los videos de QA son artefactos locales de desarrollo y no se incorporan al bundle. Sin hallazgos bloqueantes en este diff; no constituye certificación legal ni aprobación de publicación.

## Revisión incremental: camisetas y pelota parada — 2026-09-07

Alcance: cambios de catálogo, renderer compartido, microeventos de tiros libres/penales y harness Debug. Revisión estática del diff: sin conexiones de red, permisos nuevos, analytics, dependencias ni persistencia nueva. Las fuentes web quedan en documentación de desarrollo, no como enlaces de navegación infantil. Los PNG mal asociados dejan de referenciarse, pero no se borran. El harness reproducible queda bajo `#if DEBUG` y no registra datos del usuario.

Sin hallazgos bloqueantes en este incremento. Esto no es una certificación legal COPPA, aprobación de App Store ni autorización de uso comercial de marcas/escudos; tampoco revalida todos los veredictos históricos del documento.

**Fecha:** 2026-04-29
**Revisor:** Security Reviewer (Agent Kit)
**Scope:** Código fuente Swift, modelo de datos, dependencias, permisos
**Estándar:** COPPA (Children's Online Privacy Protection Rule), App Store Kids Category

---

## Executive Summary

**VEREDICTO: ✅ APROBADO para categoría Kids (Made for Ages 4+)

La app **Camisetas Basti** cumple con los requisitos de privacidad infantil de Apple y COPPA. No hay código de red, no hay rastreo, no hay datos personales, y todo el estado se mantiene localmente en UserDefaults.

---

## 1. Revisión de Dependencias y Frameworks

### Frameworks importados (auditoría completa)

| Framework | Uso | Riesgo |
|-----------|-----|--------|
| `SwiftUI` | UI nativa | ✅ Ninguno |
| `Foundation` | Codable, UserDefaults | ✅ Ninguno |
| `Combine` | @Published en ProgressStore | ✅ Ninguno |
| `AVFoundation` | Reproducción local de .m4a | ✅ Ninguno |

### Ausencias verificadas ✅

- ❌ `URLSession` / `URLRequest` / `Alamofire` — Sin conexiones de red
- ❌ `Firebase` / `FirebaseAnalytics` / `Crashlytics` — Sin SDKs de terceros
- ❌ `Mixpanel` / `Adjust` / `AppsFlyer` — Sin analytics ni atribución
- ❌ `AdSupport` / `ASIdentifierManager` — Sin IDFA ni publicidad
- ❌ `StoreKit` — Sin compras dentro de la app
- ❌ `GameKit` / `GameCenter` — Sin servicios sociales
- ❌ `WebKit` / `SFSafariViewController` — Sin navegador web
- ❌ `CoreLocation` / `CLLocationManager` — Sin geolocalización
- ❌ `AVFoundation` (cámara) — Sin acceso a cámara/micrófono
- ❌ `Photos` / `PHPhotoLibrary` — Sin acceso a fotos
- ❌ `Contacts` / `EventKit` / `HealthKit` — Sin acceso a datos personales

**Conclusión:** Stack puramente nativo Apple. Cero dependencias externas.

---

## 2. Almacenamiento de Datos

### UserDefaults (`com.camisetasbasti.appstate`)

| Dato almacenado | Tipo | ¿PII? | Notas |
|-----------------|------|-------|-------|
| Progreso de pintura (pixels revelados) | Int | ❌ No | Por camiseta |
| Estado completado (0/1/2) | Int | ❌ No | Por camiseta |
| Total de estrellas | Int | ❌ No | Contador agregado |
| Último país/team visitado | String? | ❌ No | IDs estáticos de CAMI_DATA |
| Trofeos por país | [String: Bool] | ❌ No | Flags booleanos |
| Stickers por equipo | [String: Bool] | ❌ No | Flags booleanos |
| Estadísticas de juegos | Int | ❌ No | Contadores |
| Versión de contenido | Int | ❌ No | Para migraciones |

**No se almacena:**
- Nombre del niño
- Edad
- Fotos
- Ubicación
- Identificador de dispositivo (IDFV/IDFA)
- Cualquier dato derivado del comportamiento para perfilado

### Estrategia de persistencia

```swift
// UserDefaults Codable — local únicamente
let defaults = UserDefaults.standard
let key = "com.camisetasbasti.appstate"
```

- ✅ Datos nunca salen del dispositivo
- ✅ Sin sincronización iCloud (por diseño — el niño no pierde progreso si el padre no tiene iCloud)
- ✅ Sin copia de seguridad automática expuesta (UserDefaults se respalda en backups locales cifrados del dispositivo)

---

## 3. Comunicación de Red

### Resultado: ✅ SIN CONECTIVIDAD

Búsqueda de patrones de red en 25 archivos `.swift`:

```
URLSession       → 0 ocurrencias
URLRequest       → 0 ocurrencias
Alamofire        → 0 ocurrencias
http / https     → 0 ocurrencias (excepto comentarios en hex colors)
API endpoints     → 0 ocurrencias
```

**Bundle.main.url** aparece únicamente para cargar archivos de sonido embebidos:
```swift
Bundle.main.url(forResource: "tap", withExtension: "m4a")
```

---

## 4. Permisos del Sistema (Info.plist)

### Requeridos para esta app

| Clave | Valor recomendado | Justificación |
|-------|-------------------|---------------|
| `UIRequiresFullScreen` | `YES` | Kids Category requiere fullscreen en iPad |
| `UISupportedInterfaceOrientations~ipad` | `UIInterfaceOrientationLandscapeLeft`, `UIInterfaceOrientationLandscapeRight` | App diseñada para landscape |
| `ITSAppUsesNonExemptEncryption` | `NO` | Sin criptografía custom |

### Claves que NO deben aparecer

| Clave | Estado |
|-------|--------|
| `NSLocationWhenInUseUsageDescription` | ✅ No requerido |
| `NSCameraUsageDescription` | ✅ No requerido |
| `NSPhotoLibraryUsageDescription` | ✅ No requerido |
| `NSMicrophoneUsageDescription` | ✅ No requerido |
| `NSUserTrackingUsageDescription` | ✅ No requerido |
| `NSAppTransportSecurity` (Allow Arbitrary Loads) | ✅ No requerido |
| `GADApplicationIdentifier` | ✅ No requerido |

---

## 5. Mecanismos de Protección Infantil

### 5.1 Sin onboarding obligatorio
- ✅ El niño aprende explorando. Sin formularios, sin permisos, sin interrupciones.

### 5.2 Sin enlaces externos
- ✅ No hay `openURL`, `UIApplication.shared.open`, `Link`, `WKWebView`, ni `SFSafariViewController`.
- ✅ No hay botones "Compartir", "Calificar", "Más apps", ni redes sociales.

### 5.3 Sin publicidad
- ✅ Sin AdMob, sin banners, sin intersticiales, sin rewarded ads.
- ✅ Sin identificadores de publicidad (IDFA).

### 5.4 Sin compras dentro de la app
- ✅ Sin `StoreKit`, sin productos, sin suscripciones.

### 5.5 Sin analytics ni crash reporting
- ✅ Sin Firebase, sin Crashlytics, sin telemetry.
- ✅ El único "estadístico" son contadores locales en UserDefaults (cuántas veces jugó a adivinar/memoria).

### 5.6 Reset oculto (protección parental)
- ✅ El reset completo requiere 5 toques consecutivos en el escudo del equipo favorito.
- ✅ No hay botón visible de "Borrar todo" que un niño pueda tocar accidentalmente.

---

## 6. Seguridad de los Assets

### Sonidos (.m4a)
- Cargados desde `Bundle.main` (archivos locales embebidos)
- Categoría de audio: `.ambient` (respeta el interruptor de silencio del dispositivo)
- Sin descarga de audio remoto

### Fuentes (Nunito)
- Fuente local embebida en el bundle
- Sin carga de fuentes web (Google Fonts, etc.)

### Imágenes
- Todas las camisetas, escudos y banderas son vectores nativos Swift (Shapes/Path)
- Sin imágenes raster, sin descarga de assets remotos

---

## 7. Resiliencia

### Manejo de estado corrupto
- `ProgressStore.load()` retorna `AppState()` por defecto si el JSON de UserDefaults está corrupto o no existe.
- No hay crash si los datos están malformados.

### Migración de datos
- `AppState.contentVersion` permite futuras migraciones sin perder progreso.
- Actualmente en versión 1 (sin migraciones necesarias).

---

## 8. Checklist App Store — Kids Category

| Requisito de Apple | Estado |
|--------------------|--------|
| Sin publicidad de terceros | ✅ |
| Sin analytics de terceros | ✅ |
| Sin enlaces a fuera de la app | ✅ |
| Sin compras dentro de la app | ✅ |
| Sin solicitud de datos personales | ✅ |
| Sin acceso a hardware sensitivo (cámara, micrófono, GPS) | ✅ |
| Sin acceso a redes sociales | ✅ |
| Sin rastreo cross-app | ✅ |
| Parental gate para acciones destructivas (reset) | ✅ |
| Cumple con COPPA | ✅ |

---

## 9. Recomendaciones Previas al Submit

### Info.plist (obligatorio antes de compilar)
```xml
<key>UIRequiresFullScreen</key>
<true/>
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### App Store Connect — Declaración de privacidad

| Categoría de datos | Valor |
|--------------------|-------|
| Datos de contacto | No recopilamos |
| Datos de salud y fitness | No recopilamos |
| Datos financieros | No recopilamos |
| Ubicación | No recopilamos |
| Información sensible | No recopilamos |
| Contactos | No recopilamos |
| Contenido generado por el usuario | No recopilamos |
| Historial de navegación | No recopilamos |
| Identificadores | No recopilamos |
| Compras | No recopilamos |
| Datos de uso | No recopilamos |
| Diagnósticos | No recopilamos |

**Tracking:** No rastreamos actividad del usuario en apps o sitios web de terceros.

---

## 10. Hallazgos y Riesgos

| # | Hallazgo | Severidad | Acción |
|---|----------|-----------|--------|
| H1 | UserDefaults no está encriptado | Baja | Aceptable: datos son puramente de progreso de juego, sin PII. Para fortalecer, considerar `NSFileProtectionComplete` en futuras versiones. |
| H2 | `SoundManager` fuerza `AVAudioSession.setActive(true)` en `init()` | Info | Categoría `.ambient` es correcta. No captura micrófono. |
| H3 | No hay rate limiting en reset oculto | Baja | 5 taps consecutivos es suficiente como barrera para un niño de 4 años. Considerar requerir 5 taps en < 3 segundos en V2. |

**Sin hallazgos críticos, altos o medios.**

---

## 11. Veredicto Final

**✅ APROBADO para merge y submit a App Store en categoría Kids (Made for Ages 4+).**

La app es offline-first, no recolecta datos, no se comunica con servidores, no incluye publicidad ni analytics, y todos los permisos de sistema están justificados y documentados.

---

## Handoff

Próximo agente: **QA Engineer**
- Generar tests unitarios (XCTest) para `ProgressStore` y `PaintEngine`
- Generar tests de UI (XCUITest) para flujo crítico: Splash → Home → País → Equipo → Pintar → Ficha
- Checklist manual de usabilidad infantil (tamaños de botón, feedback táctil, sonidos)

---

## 12. Delta review — Simulación de partidos v2 (2026-08-22)

**Veredicto:** ✅ Gate 3 aprobado sin hallazgos críticos, altos ni medios.

- La nueva timeline sigue siendo completamente local y efímera.
- No incorpora red, backend, analytics, telemetría, PII, identificadores infantiles ni persistencia adicional.
- `MatchSimulation` conserva resultado y eventos como una sola unidad de estado, evitando desincronización al reconstruir vistas SwiftUI.
- El resolver de posiciones es determinístico y acotado a 24 pasadas sobre 6 jugadores; no introduce riesgo práctico de DoS.
- Todos los índices generados están en `0...5` y la vista itera los índices reales de los arreglos.
- Los reinicios reposicionan la pelota mientras está oculta y mantienen jugadores dentro de la cancha.
- Al finalizar, el timer deja de mutar estado y renderizar detrás del panel de cierre.
- `Reduce Motion` evita springs, giro continuo y pulsaciones sin alterar la lógica del resultado.
- La cancha decorativa se oculta a VoiceOver y el relato expone minuto, marcador y evento como una sola actualización accesible.

No se requieren cambios de privacidad ni declaraciones nuevas en App Store Connect por esta mejora.

## Delta de presentación — 2026-09-07

Revisión estática acotada al diff de partidos (incluidos archivos nuevos), sin reevaluación legal ni de distribución. No se agregan red, permisos, identificadores, analytics ni persistencia. El renderer Canvas y su muestreador son locales; los argumentos de QA están detrás de `#if DEBUG`. No se alteran datos de progreso.

La revisión independiente detectó y se corrigieron dos problemas visuales: gol que finalizaba antes de la línea y alternativas de camisetas que aún podían confundirse. Sin otros hallazgos accionables en el alcance revisado. Las afirmaciones históricas de seis jugadores en la revisión v2 corresponden a la versión anterior: el estado vigente utiliza once por equipo.

Handoff: revisión del usuario de la experiencia local, y proceso habitual de release si solicita publicarla. Este delta no aprueba por sí mismo merge ni submit.

## Delta de reloj y carreras — 2026-09-07

Revisión estática focal del reloj, trayectorias y pruebas: no se agregan red, permisos, servicios externos, identificadores ni datos persistentes. CADisplayLink usa un proxy débil, se pausa al salir de la escena y se invalida al cerrar el modal. `--motion-diagnostics` registra únicamente tiempos de dibujo y progreso técnico agregados dentro de `#if DEBUG`; no está incluido en Release. Kits, catálogo y almacenamiento de progreso quedan intactos. Sin hallazgos de seguridad nuevos en este alcance; no sustituye revisión de distribución ni aprobación de publicación.
