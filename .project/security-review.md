# Security Review — Camisetas Basti

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
