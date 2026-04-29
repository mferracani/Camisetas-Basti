# PRD — APP CAMISETAS

---

## 1. RESUMEN EJECUTIVO

App iPad-first para niños de 4 años que descubren camisetas de fútbol pintando con el dedo. El diseño detectado incluye 11 pantallas, camisetas renderizadas proceduralmente en SVG, mecánica de revelado con canvas 2D, álbum de colección, y tres minijuegos. Todo el contenido es local y offline. El prototipo funcional está construido en React con un design system cálido, infantil y tipográficamente redondeado. No requiere login, internet, ni backend remoto.

---

## 2. PROBLEMA, USUARIOS Y JTBD

### Problema principal
Un niño de 4 años no puede usar apps de fútbol existentes porque dependen de lectura, navegación compleja, publicidad, internet y contenido no curado para su edad. Necesita una experiencia segura, offline, visual y táctil que lo introduzca a equipos, países y colores sin frustración.

### Usuario principal
- **Niño de 4 años**
  - No lee fluidamente
  - Navega por imágenes, colores y formas
  - Usa el dedo como input principal
  - Tiene baja tolerancia a la frustración
  - Necesita feedback inmediato y positivo

### Usuario secundario
- **Adulto (padre/madre) que entrega el iPad**
  - Quiere contenido seguro y sin interacciones con extraños
  - Valora el uso offline (avión, viaje, sin WiFi)
  - No quiere compras accidentales ni anuncios
  - Quiere que el niño aprenda algo (equipos, países, colores)

### Jobs-to-be-done del niño
1. "Quiero ver una camiseta gris y descubrir de qué equipo es pasando mi dedo"
2. "Quiero ver muchas camisetas juntas como si fueran figuritas"
3. "Quiero jugar a adivinar cuál equipo es solo viendo un pedacito"
4. "Quiero encontrar pares iguales en un juego de memoria"
5. "Quiero ver mi progreso con estrellas y premios"

### Jobs-to-be-done del adulto
1. "Quiero que mi hijo se entretenga solo sin depender de internet"
2. "Quiero que lo que vea sea apropiado para su edad"
3. "Quiero que no pueda comprar nada ni salir de la app"
4. "Quiero que aprenda nombres de equipos y reconozca banderas"

---

## 3. ALCANCE

### MVP (3–4 semanas)
- Home, Países, Equipos, Detalle de equipo
- Pantalla PINTAR con revelado funcional (SwiftUI + Core Animation / UIKit con CALayer mask)
- Ficha final con animación de celebración
- Álbum con grid de camisetas descubiertas/bloqueadas
- Data local para 6 países × 10 equipos × 2 camisetas = 120 camisetas
- Progreso local básico (0=bloqueada, 1=parcial, 2=completa)
- Sonidos de efecto embebidos (tap, acierto, celebración, error-suave)
- Splash animado: camiseta gris que se pinta sola en 1.5s
- Sin internet, sin login, sin anuncios
- **Sin onboarding (decisión tomada: niño aprende explorando)**
- **Plataforma: Swift nativo para iOS y macOS (SwiftUI + AppKit/UIKit adaptativo)**

### FUERA DE ALCANCE (MVP)
- Juegos (ADIVINAR, MEMORIA, PREMIOS) — diseñados pero no implementados en lógica real
- Sonido hablado/voiceover
- Modo padres / controles parentales
- Compartir/exportar camisetas
- Backend remoto o sincronización
- Analytics remoto
- In-App Purchases, ads, login
- Integración con escudos/camisetas reales oficiales (usar versión estilizada SVG casi idéntica)

### V1
- Juego ADIVINAR con lógica real y selección aleatoria
- Juego MEMORIA con generación de pares aleatorios
- Pantalla PREMIOS con lógica de trofeos desbloqueables
- Persistencia robusta de progreso (AsyncStorage / Core Data)
- Sonidos adicionales (música ambiental opcional)
- Onboarding visual de 3 pasos (cómo pintar)
- Filtros de álbum mejorados

### VNEXT
- Más países / equipos
- Máscaras de pintura con textura de "rasguño" más realista
- Haptics en dispositivos compatibles
- VoiceOver de nombres de equipos
- Modo competencia: temporizador en adivinar
- Personalización de camisetas (cambiar colores)
- Foto del niño con la camiseta descubierta

---

## 4. EXPERIENCIA FRONT-FIRST

### 4.1 IA / SITEMAP

```
SPLASH (launch)
→ HOME
├── PAÍSES
│   └── LISTA DE EQUIPOS (por país)
│       └── DETALLE DE EQUIPO
│           ├── PINTAR / REVELAR CAMISETA (TITULAR)
│           │   └── FICHA FINAL
│           │       ├── ÁLBUM
│           │       ├── OTRA CAMISETA → DETALLE DE EQUIPO
│           │       └── REPINTAR → PINTAR
│           └── PINTAR / REVELAR CAMISETA (SUPLENTE)
│               └── FICHA FINAL
├── JUGAR (JUEGOS)
│   ├── PINTAR (acceso directo a PAÍSES)
│   ├── ADIVINAR
│   └── MEMORIA
├── ÁLBUM (acceso directo)
└── PREMIOS
```

### 4.2 FLUJOS PRINCIPALES

#### Abrir app
1. Splash: camiseta gris que se pinta sola progresivamente en 1.5s
2. Aparece HOME con botones grandes: PAÍSES, JUGAR, ÁLBUM, PREMIOS
3. Badge de estrellas en esquina superior derecha
4. Indicador "LISTO PARA JUGAR SIN INTERNET"
5. **Sin onboarding (decisión tomada: el niño aprende explorando)**

#### Elegir país
1. Tocar "PAÍSES" desde HOME
2. Se muestra grid 3×2 con banderas grandes de los 6 países
3. Cada tarjeta muestra contador `X/20` de camisetas descubiertas
4. Tocar una bandera → navega a LISTA DE EQUIPOS

#### Elegir equipo
1. Se muestra grid 5×2 de equipos del país seleccionado
2. Cada tarjeta: mini camiseta (gris/color/parcial) + escudo + nombre corto + `X/2`
3. Tocar equipo → navega a DETALLE DE EQUIPO

#### Elegir TITULAR / SUPLENTE
1. DETALLE muestra escudo grande, nombre del equipo, bandera
2. Dos tarjetas grandes lado a lado: TITULAR y SUPLENTE
3. Estado visible: "POR DESCUBRIR" o "✓ DESCUBIERTA"
4. Tocar una → navega a PINTAR

**Nota:** No existe pantalla separada de SELECCIÓN TITULAR/SUPLENTE. Está integrada en DETALLE DE EQUIPO.

#### Pintar camiseta
1. Camiseta real visible debajo, capa gris encima (SwiftUI/Core Animation mask)
2. Dedo borra la capa gris
3. Máscara restringe el trazo al contorno exacto de la camiseta
4. Ghost finger hint aparece si no hay progreso en 3s
5. Estrellas de progreso se iluminan cada 20%
6. Al 85%: confetti + auto-limpieza completa + sonido de celebración + "¡MUY BIEN!"
7. Botón "VER FICHA →" aparece

#### Revelar camiseta
- Revelado progresivo por porcentaje de píxeles borrados
- Transición de escala suave al completarse
- Animación de confetti con 60 partículas aleatorias

#### Completar camiseta
- Estado guardado como `2` (completa)
- Contador de estrellas global incrementa
- Disponible para ver en ÁLBUM
- Si se completan las 20 camisetas del país: desbloquea trofeo dorado en PREMIOS + confetti extra + sonido especial

#### Ver ficha final
1. Pantalla dividida: camiseta grande + info del equipo
2. Muestra: escudo, nombre, país, colores con swatches, tipo (TITULAR/SUPLENTE)
3. Botones: OTRA, ÁLBUM, REPINTAR

#### Guardar en álbum
- ÁLBUM muestra grid 8 columnas con todas las camisetas
- Descubiertas: borde verde sólido, camiseta a color
- Parciales: borde dashed, camiseta parcial
- Bloqueadas: borde dashed gris, camiseta gris
- Filtros: TODAS o por país (bandera + nombre)
- Contador global `XX / 120`

#### Jugar ADIVINAR (diseño detectado, lógica PENDIENTE)
1. Muestra camiseta parcial al 45%
2. Dos opciones grandes con escudo + mini camiseta + nombre
3. Al tocar: borde verde si acierta, rojo si falla
4. Shake animation en error
5. Estrellas de progreso arriba

#### Jugar MEMORIA (diseño detectado, lógica PENDIENTE)
1. Grid 3×2 de cartas
2. Reverso: color primario con "?"
3. Frente: camiseta a color o escudo
4. Parejas = camiseta + escudo del mismo equipo
5. Match correcto: borde verde + permanece visible

#### Ver PREMIOS (diseño detectado, lógica PENDIENTE)
1. Tarjeta grande con total de estrellas
2. Grid 4 columnas con trofeos por país y stickers de equipos
3. Trofeos desbloqueados a color, bloqueados en escala de grises
4. Badge "¡NUEVO!" en stickers recientes

#### Estados de error o contenido faltante
- Asset faltante: pantalla con icono 👕 y "NO DISPONIBLE"
- Álbum vacío: camiseta gris grande + "PINTA TU PRIMERA CAMISETA" + botón EMPEZAR
- Offline: siempre listo, sin pantalla de error (todo local)

### 4.3 ESPECIFICACIÓN POR PANTALLA

---

#### HOME

| Campo | Valor |
|-------|-------|
| **Objetivo** | Punto de entrada. El niño elige qué quiere hacer: explorar países, jugar, ver álbum o premios. |
| **Componentes visibles** | Título "CAMISETAS" display 88px · Subtítulo "⚽ PINTA · DESCUBRE · COLECCIONA ⚽" · 3 camisetas hero rotadas · Botón PAÍSES (lg, primary, 🌎) · Botón JUGAR (md, sky, 👕) · Botón ÁLBUM (md, grass, 📒) · Botón PREMIOS (sm, sun, ⭐) · Badge de estrellas arriba derecha · Chip offline arriba izquierda · Blobs decorativos de fondo |
| **Acciones disponibles** | Tocar PAÍSES · Tocar JUGAR · Tocar ÁLBUM · Tocar PREMIOS |
| **Entradas del usuario** | Tap en botones grandes |
| **Salidas / feedback** | Navegación a pantalla correspondiente · Animación de presión en botón (translateY + sombra) |
| **Estados** | Default · Botón presionado (active) |
| **Validaciones** | Ninguna (siempre accesible) |
| **Copy visible** | "CAMISETAS" · "PINTA · DESCUBRE · COLECCIONA" · "PAÍSES" · "JUGAR" · "ÁLBUM" · "PREMIOS" · "LISTO PARA JUGAR SIN INTERNET" · "12 ⭐" |
| **Navegación** | → PAÍSES · → JUEGOS · → ÁLBUM · → PREMIOS |
| **Criterios de aceptación** | Todos los botones son visibles y tocables · Título legible · Hero shirts renderizan sin error · Badge de estrellas muestra número correcto · Botones tienen feedback táctil |

---

#### PAÍSES

| Campo | Valor |
|-------|-------|
| **Objetivo** | Elegir un país para ver sus equipos. |
| **Componentes visibles** | BackButton · Título "ELIGE UN PAÍS" · Grid 3×2 de tarjetas de país · Cada tarjeta: bandera grande (180×120) · nombre del país · badge `descubiertas/total` arriba derecha |
| **Acciones disponibles** | Tocar tarjeta de país · Volver con BackButton |
| **Entradas del usuario** | Tap en tarjeta de país · Tap en BackButton |
| **Salidas / feedback** | Tarjeta hace hover translateY(-4px) · Navega a LISTA DE EQUIPOS · Back vuelve a HOME |
| **Estados** | Default · Hover/active |
| **Validaciones** | Ninguna |
| **Copy visible** | "←" · "ELIGE UN PAÍS" · nombres de países en MAYÚSCULAS · contadores "X/20" |
| **Navegación** | ← HOME · → LISTA DE EQUIPOS |
| **Criterios de aceptación** | 6 países visibles · Banderas renderizan correctamente · Contador muestra progreso real · Tarjeta es clickable en toda su área |

---

#### LISTA DE EQUIPOS

| Campo | Valor |
|-------|-------|
| **Objetivo** | Elegir un equipo del país seleccionado. |
| **Componentes visibles** | BackButton · Bandera del país (64×44) · Título con nombre del país · Grid 5×2 de tarjetas de equipo · Cada tarjeta: mini camiseta (110px, mode gray/partial/color) · badge `X/2` arriba derecha · escudo (22px) · nombre corto |
| **Acciones disponibles** | Tocar equipo · Volver |
| **Entradas del usuario** | Tap en tarjeta de equipo |
| **Salidas / feedback** | Hover translateY(-3px) · Navega a DETALLE DE EQUIPO |
| **Estados** | Default · Hover · Camiseta gris (0/2) · Parcial (1/2) · Completa (2/2) |
| **Validaciones** | Ninguna |
| **Copy visible** | Nombre del país · nombres cortos en MAYÚSCULAS · "X/2" |
| **Navegación** | ← PAÍSES · → DETALLE DE EQUIPO |
| **Criterios de aceptación** | Muestra 10 equipos del país · Mini camisetas reflejan estado de progreso · Badge de contador visible · Escudo legible a tamaño reducido |

---

#### DETALLE DE EQUIPO

| Campo | Valor |
|-------|-------|
| **Objetivo** | Ver info del equipo y elegir TITULAR o SUPLENTE para pintar. |
| **Componentes visibles** | BackButton · Escudo grande (70px) · Nombre del equipo (38px) · Bandera + nombre del país · Subtítulo "ELIGE UNA CAMISETA PARA PINTAR" · Grid 1×2: tarjeta TITULAR (🏠) y tarjeta SUPLENTE (✈️) · Cada tarjeta: badge estado · camiseta grande (240px) · label TITULAR/SUPLENTE · botón "👆 PINTAR" |
| **Acciones disponibles** | Tocar TITULAR · Tocar SUPLENTE · Volver |
| **Entradas del usuario** | Tap en tarjeta de camiseta |
| **Salidas / feedback** | Hover translateY(-6px) · Navega a PINTAR con kit seleccionado |
| **Estados** | Por descubrir (badge naranja) · Descubierta (badge verde) |
| **Validaciones** | Ninguna (se puede repintar una ya descubierta) |
| **Copy visible** | "ELIGE UNA CAMISETA PARA PINTAR" · "TITULAR" · "SUPLENTE" · "POR DESCUBRIR" · "✓ DESCUBIERTA" · "👆 PINTAR" · nombre del equipo y país en MAYÚSCULAS |
| **Navegación** | ← LISTA DE EQUIPOS · → PINTAR |
| **Criterios de aceptación** | Escudo y nombre correctos · Dos camisetas visibles · Badge de estado correcto · Botón PINTAR prominente · Camiseta ya descubierta muestra a color |

---

#### PINTAR / REVELAR CAMISETA

| Campo | Valor |
|-------|-------|
| **Objetivo** | Revelar la camiseta pasando el dedo sobre la capa gris. |
| **Componentes visibles** | BackButton · Escudo + nombre del equipo + badge TITULAR/SUPLENTE · Botón "?" de ayuda · Título "PINTA" / "¡MUY BIEN!" · Área de camiseta: SVG real debajo, canvas gris encima, clip-path de silueta · Ghost finger 👆 si <5% · 5 estrellas de progreso · Botón "VER FICHA →" al completar · Confetti al 85% · HelpOverlay (modal) |
| **Acciones disponibles** | Dedo/mouse sobre canvas · Volver · Tocar "?" · Tocar "VER FICHA" cuando aparece |
| **Entradas del usuario** | Touch drag / mouse drag sobre camiseta · Tap en botones |
| **Salidas / feedback** | Círculo borra gris (radio 36px) · Estrellas se iluminan cada 20% · Título cambia a "¡MUY BIEN!" al completar · Scale 1.05 en camiseta al completar · Confetti 60 partículas · Auto-clear al 85% |
| **Estados** | Inicial (100% gris) · Pintando (parcial) · Completado (confetti + botón) |
| **Validaciones** | `computeRevealPct()` samplea cada 8 píxeles · Umbral de completado: 85% |
| **Copy visible** | "PINTA" · "¡MUY BIEN!" · nombre del equipo · "TITULAR" / "SUPLENTE" · "?" · "VER FICHA →" |
| **Navegación** | ← DETALLE DE EQUIPO · → FICHA FINAL |
| **Criterios de aceptación** | Canvas responde a touch y mouse · Clip-path restringe a silueta · Revelado progresivo visible · Estrellas actualizan correctamente · Confetti al 85% · Botón aparece solo al completar · Ghost hint desaparece al primer toque · Performance fluido en iPad |

---

#### FICHA FINAL

| Campo | Valor |
|-------|-------|
| **Objetivo** | Celebrar el descubrimiento y ofrecer próximos pasos. |
| **Componentes visibles** | BackButton · Título "¡MUY BIEN!" (56px, naranja) · Camiseta grande en tarjeta blanca rotada -2° · Escudo + nombre del equipo · Bandera + país · Swatches de colores + nombres · Badge TITULAR/SUPLENTE · "+1 SUMADA AL ÁLBUM" · Botones: OTRA → · ÁLBUM (📒) · REPINTAR (🔄) · Blobs decorativos |
| **Acciones disponibles** | Tocar OTRA · Tocar ÁLBUM · Tocar REPINTAR · Volver |
| **Entradas del usuario** | Tap en botones |
| **Salidas / feedback** | Navegación correspondiente · Guardado de progreso |
| **Estados** | Default |
| **Validaciones** | Progreso guardado como `2` (completo) |
| **Copy visible** | "¡MUY BIEN!" · nombre del equipo · nombre del país · "COLORES" · nombres de colores · "TITULAR" / "SUPLENTE" · "+1 SUMADA AL ÁLBUM" · "OTRA →" · "ÁLBUM" · "REPINTAR" |
| **Navegación** | ← PINTAR · → ÁLBUM · → LISTA DE EQUIPOS (OTRA) · → PINTAR (REPINTAR) |
| **Notas** | REPINTAR resetea el progreso de esta camiseta a `status=0` y vuelve a PINTAR con capa gris completa. El niño puede volver a pintarla desde cero. |
| **Criterios de aceptación** | Camiseta renderiza a color · Colores correctos · Botones visibles y grandes · Progreso se guarda · Nombres de colores en español |

---

#### ÁLBUM

| Campo | Valor |
|-------|-------|
| **Objetivo** | Ver colección completa de camisetas descubiertas. |
| **Componentes visibles** | BackButton · Título "MI ÁLBUM" · Contador global `descubiertas/total` (badge verde) · Filtros: TODAS + banderas de países · Grid 8 columnas de celdas · Celda: mini camiseta (70px) + nombre corto + TITULAR/SUPLENTE · Borde verde sólido = descubierta · Borde dashed gris = bloqueada |
| **Acciones disponibles** | Tocar filtro · Volver · Scroll vertical |
| **Entradas del usuario** | Tap en filtro · Scroll |
| **Salidas / feedback** | Filtro activo resaltado en naranja · Grid se filtra por país · Scroll con sombra interior |
| **Estados** | Default · Vacío (PENDIENTE: pantalla de álbum vacío existe en artboard pero no como flujo principal) |
| **Validaciones** | Ninguna |
| **Copy visible** | "MI ÁLBUM" · "TODAS" · nombres de países · nombres cortos · "TITULAR" / "SUPLENTE" · contador "X / 120" |
| **Navegación** | ← HOME / FICHA |
| **Criterios de aceptación** | Grid responsive · Filtros funcionan · Bordes correctos según estado · Contador actualizado · Scroll fluido |

---

#### JUEGOS

| Campo | Valor |
|-------|-------|
| **Objetivo** | Elegir minijuego. |
| **Componentes visibles** | BackButton · Título "JUGAR" · Grid 3 columnas: PINTAR (🎨, naranja), ADIVINAR (❓, celeste), MEMORIA (🃏, verde) · Cada tarjeta: icono grande en círculo · título · subtítulo · botón "JUGAR ▶" |
| **Acciones disponibles** | Tocar PINTAR · Tocar ADIVINAR · Tocar MEMORIA · Volver |
| **Entradas del usuario** | Tap en tarjeta de juego |
| **Salidas / feedback** | Hover translateY(-6px) · Navegación a juego correspondiente |
| **Estados** | Default · Hover/active |
| **Validaciones** | Ninguna |
| **Copy visible** | "JUGAR" · "PINTAR" · "ADIVINAR" · "MEMORIA" · "DESCUBRE LA CAMISETA" · "¿CUÁL ES?" · "BUSCA LOS PARES" · "JUGAR ▶" |
| **Navegación** | ← HOME · → PAÍSES (si elige PINTAR) · → ADIVINAR · → MEMORIA |
| **Criterios de aceptación** | 3 juegos visibles · Iconos grandes · Tarjetas clickeables · PINTAR redirige correctamente a flujo de países |

---

#### ADIVINAR

| Campo | Valor |
|-------|-------|
| **Objetivo** | Adivinar el equipo viendo una camiseta parcial. |
| **Componentes visibles** | BackButton · Título "¿CUÁL ES?" · ProgressStars (2/5) · Camiseta parcial al 45% en tarjeta · 2 opciones grandes: escudo + mini camiseta + nombre · Animación shake en error · Icono ⭐ o 🔁 según resultado |
| **Acciones disponibles** | Tocar opción A · Tocar opción B · Volver |
| **Entradas del usuario** | Tap en opción |
| **Salidas / feedback** | Opción seleccionada resalta con borde verde/rojo · Shake si error · Icono de resultado aparece · Deshabilitado después de elegir |
| **Estados** | Default · Acierto · Error |
| **Validaciones** | Solo una selección permitida |
| **Copy visible** | "¿CUÁL ES?" · nombres cortos de equipos · emojis de resultado |
| **Navegación** | ← JUEGOS |
| **Criterios de aceptación** | Camiseta parcial renderiza · Opciones muestran escudos · Feedback visual inmediato · No permite cambiar respuesta · Shake animation funciona |

---

#### MEMORIA

| Campo | Valor |
|-------|-------|
| **Objetivo** | Encontrar pares de camiseta + escudo del mismo equipo. |
| **Componentes visibles** | BackButton · Título "MEMORIA" · Subtítulo "BUSCA LOS PARES" · ProgressStars · Grid 3×2 de cartas · Reverso: color naranja con "?" · Frente: camiseta a color o escudo · Borde verde en pares encontrados |
| **Acciones disponibles** | Tocar carta · Volver |
| **Entradas del usuario** | Tap en carta |
| **Salidas / feedback** | Volteo animado · Si par: borde verde, permanece · Si no par: vuelta a reverso |
| **Estados** | Reverso · Volteada · Matched |
| **Validaciones** | Máximo 2 cartas volteadas simultáneamente · Bloqueo de input durante animación |
| **Copy visible** | "MEMORIA" · "BUSCA LOS PARES" · "?" en cartas |
| **Navegación** | ← JUEGOS |
| **Criterios de aceptación** | Cartas voltean con animación · Solo 2 cartas a la vez · Pares detectados correctamente · Input bloqueado durante animación · Grid 3×2 visible |

---

#### PREMIOS

| Campo | Valor |
|-------|-------|
| **Objetivo** | Ver progreso y recompensas desbloqueadas. |
| **Componentes visibles** | BackButton · Título "PREMIOS" · Tarjeta grande gradiente sol: "TUS ESTRELLAS" + número grande · Estrellas decorativas rotadas · Grid 4 columnas: trofeos por país + stickers de equipos · Badge "¡NUEVO!" · Trofeos bloqueados: opacity 0.5 + grayscale |
| **Acciones disponibles** | Volver · Scroll |
| **Entradas del usuario** | Tap en BackButton · Scroll |
| **Salidas / feedback** | Visualización de progreso |
| **Estados** | Default |
| **Validaciones** | Ninguna |
| **Copy visible** | "PREMIOS" · "TUS ESTRELLAS" · nombres de países · nombres cortos · "¡NUEVO!" |
| **Navegación** | ← HOME |
| **Criterios de aceptación** | Contador de estrellas correcto · Trofeos y stickers visibles · Estados bloqueado/desbloqueado distinguibles · Badge "¡NUEVO!" visible en recientes |

---

#### SPLASH / LAUNCH

| Campo | Valor |
|-------|-------|
| **Objetivo** | Animar el lanzamiento de la app y anticipar la mecánica principal. |
| **Componentes visibles** | Fondo del color de paleta activa · Camiseta gris centrada · Progreso de revelado automático (como si un dedo invisible pintara) · Título "CAMISETAS" aparece al finalizar |
| **Acciones disponibles** | Ninguna (no interactiva) |
| **Entradas del usuario** | Ninguna |
| **Salidas / feedback** | Revelado progresivo de gris a color en 1.5s · Transición fade a HOME |
| **Estados** | Animando · Finalizado → navega a HOME |
| **Validaciones** | Duración fija 1.5s · No bloqueable |
| **Copy visible** | "CAMISETAS" al final |
| **Navegación** | → HOME (automático al finalizar) |
| **Criterios de aceptación** | Animación fluida 60fps · No se puede saltear · Transición suave a HOME · Se muestra en cada lanzamiento |

---

#### PANTALLA FALTANTE RECOMENDADA: ONBOARDING

| Campo | Valor |
|-------|-------|
| **Razón** | No existe en el diseño detectado. |
| **Decisión tomada** | **NO SE IMPLEMENTA.** El niño aprende explorando. Sin slides iniciales. |

---

### 4.4 COMPONENTES REUTILIZABLES

---

#### Botón grande infantil (BigKidButton)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Botón primario para interacciones del niño. Debe ser grande, colorido y con feedback táctil claro. |
| **Variantes** | `primary` (naranja #FF7B3D) · `secondary` (blanco) · `sun` (amarillo #FFC93C) · `sky` (celeste #6BCBFF) · `grass` (verde #7DDB8B) |
| **Tamaños** | `sm` (minH 56, fz 16) · `md` (minH 80, fz 22) · `lg` (minH 104, fz 28) |
| **Estados visuales** | Default: sombra dura 0 8px 0 + 0 12px 24px · Active/pressed: translateY(4px), sombra reducida · Hover (desktop): transform 120ms |
| **Comportamiento** | onMouseDown: hundir · onMouseUp: volver · onMouseLeave: resetear · Soporte para icono opcional |
| **Accesibilidad** | Min-height 56px (sm) a 104px (lg) · Letra 900 weight · letter-spacing 0.5px · Sin depender solo de color (sombra + texto) |

---

#### Tarjeta de país

| Atributo | Valor |
|----------|-------|
| **Propósito** | Representar un país seleccionable con bandera y progreso. |
| **Variantes** | Única |
| **Estados visuales** | Default: fondo blanco, sombra suave · Hover: translateY(-4px) |
| **Comportamiento** | Click completo en tarjeta · Badge de contador actualizado dinámicamente |
| **Accesibilidad** | Área táctil completa · Contraste entre bandera y fondo |

---

#### Tarjeta de equipo

| Atributo | Valor |
|----------|-------|
| **Propósito** | Representar un equipo con mini camiseta, escudo y estado de progreso. |
| **Variantes** | Estado según progreso: gris · parcial · color |
| **Estados visuales** | Default: fondo blanco, sombra suave · Hover: translateY(-3px) · Badge `X/2` con color según estado |
| **Comportamiento** | Click en toda la tarjeta · Mini camiseta renderiza en modo correspondiente |
| **Accesibilidad** | Mini camiseta visible a 110px · Escudo legible a 22px · Nombre corto legible |

---

#### Visor de camiseta (Shirt)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Renderizar una camiseta de fútbol en SVG paramétrico según patrón y colores del equipo. |
| **Variantes** | `mode`: color · gray · partial · mini |
| **Estados visuales** | Color: patrón real con textura, sombras, highlights · Gray: color plano #D9D5CE con textura sutil y línea central dashed · Partial: color real revelado por máscara SVG según `revealPct` |
| **Comportamiento** | Renderiza path único de camiseta (240×280 viewBox) · Aplica clipPath · Aplica PatternFill según `pattern` (solid, stripes-v, stripes-h, hoops, split-v, split-d, sash-d, sash-h, sash-v, etc.) · Escala a cualquier `size` manteniendo aspect ratio |
| **Accesibilidad** | SVG con `aria-label` descriptivo · No depende solo del color (patrones distinguibles) |

---

#### Camiseta gris (capa de pintura)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Capa superior en pantalla PINTAR que el niño borra con el dedo. |
| **Variantes** | Única |
| **Estados visuales** | Inicial: #D9D5CE con textura de puntos blancos aleatorios y "?" tenue · Parcial: áreas transparentes donde se borró · Completado: totalmente transparente (o auto-clear al 85%) |
| **Comportamiento** | Canvas 2D con `globalCompositeOperation = 'destination-out'` · Radio de borrado 36px (configurable por `revealSpeed`) · Interpolación de puntos para trazos suaves · Clip-path al path de la camiseta |
| **Accesibilidad** | Cursor crosshair · Ghost finger hint si no hay interacción · `touch-action: none` para prevenir scroll |

---

#### Camiseta revelada

| Atributo | Valor |
|----------|-------|
| **Propósito** | Camiseta real visible debajo de la capa gris. |
| **Variantes** | Mismo componente Shirt con `mode="color"` |
| **Estados visuales** | Visible siempre, revelada progresivamente por la capa superior |
| **Comportamiento** | SVG estático debajo del canvas · Escala sincronizada con canvas |

---

#### Barra/progreso visual (ProgressStars)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Mostrar progreso de forma no numérica, ideal para pre-lectores. |
| **Variantes** | `count` (iluminadas), `total` (total), `size` |
| **Estados visuales** | Iluminada: opacidad 1, sin filtro · Apagada: opacidad 0.3, grayscale · Transición suave |
| **Comportamiento** | Array de emojis ⭐ renderizados dinámicamente |
| **Accesibilidad** | Emoji universalmente reconocible · Tamaño configurable |

---

#### Botón volver (BackButton)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Navegación hacia atrás consistente en todas las pantallas. |
| **Variantes** | Único |
| **Estados visuales** | Círculo blanco 64×64 con sombra suave · Flecha ← en naranja oscuro #7A4E1B · Font 32px weight 900 |
| **Comportamiento** | Siempre posicionado arriba-izquierda · onClick = `onBack` callback |
| **Accesibilidad** | 64×64 px (muy por encima de 44px mínimo) · Alto contraste · Posición consistente |

---

#### Modal o animación de celebración (Confetti)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Reforzo positivo al completar una camiseta. |
| **Variantes** | Única |
| **Estados visuales** | 60 partículas de colores (#FFC93C, #FF7B6B, #6BCBFF, #7DDB8B, #C77DFF) cayendo con rotación · Opacidad se desvanece · Duración 1.5–2.5s |
| **Comportamiento** | Se dispara al 85% de revelado · Se auto-oculta después de 2.5s · `pointer-events: none` |
| **Accesibilidad** | No bloquea interacción · Opcional: acompañar con sonido y/o haptics |

---

#### Tarjeta de álbum (AlbumCell)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Celda individual en el grid del álbum. |
| **Variantes** | Descubierta (borde verde sólido) · Parcial (borde dashed) · Bloqueada (borde dashed gris) |
| **Estados visuales** | Fondo #FFF7EC · Border-radius 14px · Padding 8px · Mini camiseta 70px · Nombre 9px · Label TITULAR/SUPLENTE 8px |
| **Comportamiento** | Renderiza Shirt en modo correspondiente |
| **Accesibilidad** | Contraste de nombre ajustado según estado (bloqueado = gris claro) |

---

#### Carta de memoria (MemoryCard)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Carta volteable en juego MEMORIA. |
| **Variantes** | Reverso (naranja con "?") · Frente camiseta · Frente escudo · Matched (borde verde) |
| **Estados visuales** | Transición CSS 300ms · Box-shadow cambia según estado |
| **Comportamiento** | Click para voltear · Máximo 2 volteadas · Match = permanece visible |
| **Accesibilidad** | Área táctil grande (grid 3×2 llena pantalla) |

---

#### Opción de adivinanza (GuessOption)

| Atributo | Valor |
|----------|-------|
| **Propósito** | Opción seleccionable en juego ADIVINAR. |
| **Variantes** | Default · Seleccionada correcta · Seleccionada incorrecta |
| **Estados visuales** | Default: sombra suave · Correcta: borde verde 6px · Incorrecta: borde rojo 6px + shake animation |
| **Comportamiento** | Click selecciona · Deshabilita después de selección · Muestra icono resultado (⭐ o 🔁) |
| **Accesibilidad** | Área táctil grande (min-width 240px) · Feedback visual claro |

---

### 4.5 ESTADOS, VALIDACIONES Y COPY

| Estado | Descripción visual | Copy visible | Audio/Feedback |
|--------|-------------------|--------------|----------------|
| **Inicial** | Pantalla recién cargada | Títulos en MAYÚSCULAS | — |
| **Vacío (Álbum)** | 0 camisetas descubiertas | "PINTA TU PRIMERA CAMISETA" · "EMPEZAR" | — |
| **Loading** | No aplica (todo local) | — | — |
| **Error** | Asset no disponible | "NO DISPONIBLE" · "VOLVÉ A INTENTAR" | — |
| **Offline** | Siempre activo | "LISTO PARA JUGAR SIN INTERNET" | — |
| **Asset faltante** | Imagen no encontrada | "NO DISPONIBLE" | — |
| **Camiseta no descubierta** | Gris, borde dashed | "POR DESCUBRIR" | — |
| **Camiseta parcial** | Parcialmente revelada | — | — |
| **Camiseta completa** | Color, borde verde | "✓ DESCUBIERTA" · "¡MUY BIEN!" | Sonido celebrate.mp3 |
| **Acierto (adivinar)** | Borde verde + ⭐ | "¡MUY BIEN!" | Sonido success.mp3 |
| **Error suave (adivinar)** | Borde rojo + shake + 🔁 | "SIGUE PINTANDO" | Sonido error-soft.mp3 |
| **Progreso guardado** | Sin feedback explícito | — | — |
| **Repintar camiseta** | Reset a gris desde FICHA | "REPINTAR" | Sonido tap.mp3 |

**Regla de copy:** Todo texto visible para el niño debe estar en MAYÚSCULAS. El diseño detectado cumple esta regla en todas las pantallas.

---

### 4.6 ACCESIBILIDAD

| Requisito | Implementación en diseño detectado | Estado |
|-----------|-----------------------------------|--------|
| Niño de 4 años | Tipografía Nunito 800/900, redondeada, MAYÚSCULAS | ✅ Cumple |
| Botones grandes | BigKidButton min-height 56–104px, border-radius 28px | ✅ Cumple |
| Targets táctiles mínimos | BackButton 64×64, botones de país/equipo área completa | ✅ Cumple |
| Navegación sin lectura | Iconos (🌎, 👕, 📒, ⭐, 🎨, ❓, 🃏), banderas, camisetas | ✅ Cumple |
| Contraste | Fondo crema #FFF7EC vs texto #3D2A1F (ratio alto) | ✅ Cumple |
| Foco visible | Hover states con transform y sombra | ✅ Parcial (falta foco de teclado) |
| VoiceOver opcional | PENDIENTE: agregar `aria-label` a todos los botones | ⚠️ Pendiente |
| No depender solo del color | Patrones de rayas/bandas distinguibles en camisetas grises | ✅ Cumple |
| Evitar frustración | Revelado al 85% (no 100%), auto-clear, confetti, botones grandes | ✅ Cumple |
| Feedback positivo | Confetti, estrellas, "¡MUY BIEN!", animaciones de celebración | ✅ Cumple |

**RECOMENDACIÓN:** Agregar `aria-label` descriptivos en todos los botones e imágenes para VoiceOver. Ejemplo: `aria-label="Camiseta de Boca Juniors, TITULAR, descubierta"`.

---

### 4.7 TRACKING / PROGRESO LOCAL

**No usar analytics remoto en MVP.**

**Progreso local a almacenar:**

| Dato | Tipo | Descripción |
|------|------|-------------|
| `progress[countryId.teamId.kit]` | number (0,1,2) | Estado de cada camiseta: 0=locked, 1=partial, 2=complete |
| `totalStars` | number | Total de estrellas acumuladas (1 por camiseta completa) |
| `lastCountry` | string | Último país visitado |
| `lastTeam` | string | Último equipo visitado |
| `favoriteCountry` | string | País con más camisetas completadas |
| `trophies[countryId]` | boolean | Trofeo desbloqueado al completar país |
| `stickers[teamId]` | boolean | Sticker desbloqueado al completar equipo (ambas camisetas) |
| `gamesPlayed.guess` | number | Partidas de ADIVINAR jugadas |
| `gamesPlayed.memory` | number | Partidas de MEMORIA jugadas |
| `gamesWon.guess` | number | Aciertos en ADIVINAR |
| `onboardingCompleted` | boolean | Siempre `true` (sin onboarding) |

**Persistencia:** `UserDefaults` (iOS/macOS nativo). MVP debe funcionar sin pérdida de datos al cerrar la app. Incluir botón oculto "RESETEAR TODO" para testing y re-jugabilidad (accesible vía combinación de taps en escudo del equipo favorito o similar).

---

### 4.8 CRITERIOS DE ACEPTACIÓN

#### Por pantalla

| Pantalla | Criterios |
|----------|-----------|
| **HOME** | 4 botones visibles · Camisetas hero renderizan · Badge estrellas correcto · Navegación funciona a 4 destinos |
| **PAÍSES** | 6 países en grid 3×2 · Banderas correctas · Contadores actualizados · Click navega |
| **LISTA DE EQUIPOS** | 10 equipos · Mini camisetas reflejan estado · Escudos visibles · Nombres cortos legibles |
| **DETALLE DE EQUIPO** | Escudo y nombre correctos · Dos camisetas grandes · Badges de estado · Botón PINTAR prominente |
| **PINTAR** | Canvas responde a touch · Clip-path funciona · Revelado progresivo · Estrellas actualizan · Confetti al 85% · Botón VER FICHA aparece · Ghost hint funciona |
| **FICHA FINAL** | Camiseta a color · Colores correctos · Swatches visibles · 3 botones funcionan · Progreso guardado |
| **ÁLBUM** | Grid 8 cols · Filtros por país · Bordes según estado · Contador correcto · Scroll fluido |
| **JUEGOS** | 3 juegos visibles · Iconos grandes · PINTAR redirige a países · Otros navegan correctamente |
| **ADIVINAR** | Camiseta parcial visible · 2 opciones · Feedback visual inmediato · Shake en error · Input bloqueado post-selección |
| **MEMORIA** | Grid 3×2 · Volteo animado · Match detectado · Input bloqueado durante animación |
| **PREMIOS** | Estrellas totales correctas · Trofeos/stickers visibles · Estados bloqueado/desbloqueado claros |

#### Por flujo

| Flujo | Criterios |
|-------|-----------|
| **Descubrir camiseta** | HOME → PAÍSES → EQUIPOS → DETALLE → PINTAR → FICHA → ÁLBUM (verificando que aparece) |
| **Repintar** | Desde FICHA, REPINTAR → PINTAR con misma camiseta · Estado puede resetear o no |
| **Jugar directo** | HOME → JUEGOS → PINTAR → PAÍSES (acceso directo) |
| **Navegación libre** | BackButton funciona en todas las pantallas · No hay dead ends |
| **Offline** | App funciona sin conexión · No hay pantallas de error por falta de red · Contenido local |

---

## 5. BACKEND & DATOS LOCAL-FIRST

**IMPORTANTE:** Solo datos locales. No backend remoto.

### Entidades locales (Swift)

```swift
// MARK: - Models

struct Country: Codable, Identifiable {
    let id: String       // "arg", "eng", "esp", "ita", "fra", "ger"
    let name: String     // "ARGENTINA"
    let flagColors: [String]
    let emoji: String
}

struct Team: Codable, Identifiable {
    let id: String       // "boca", "mci"
    let name: String     // "BOCA JUNIORS"
    let short: String    // "BOCA"
    let home: Kit
    let away: Kit
    let crest: Crest
}

struct Kit: Codable {
    let pattern: Pattern
    let colors: [String] // Hex array ["#0A2A6C", "#FFD700"]
}

enum Pattern: String, Codable {
    case solid, stripesV = "stripes-v", stripesH = "stripes-h"
    case hoops, splitV = "split-v", splitD = "split-d"
    case sashD = "sash-d", sashH = "sash-h", sashHThin = "sash-h-thin"
    case sashHThick = "sash-h-thick", sashV = "sash-v", sashVFat = "sash-v-fat"
    case sleevesW = "sleeves-w", splitVBlueClaret = "split-v-blue-claret"
}

struct Crest: Codable {
    enum Shape: String, Codable { case round, shield, diamond }
    let shape: Shape
    let text: String       // "CABJ"
    let colors: [String]   // [fill, stroke]
}

// MARK: - Progress

struct ShirtProgress: Codable {
    let key: String        // "arg.boca.home"
    var status: Int        // 0=locked, 1=partial, 2=complete
    var revealPct: Double? // Último % revelado
}

struct AppState: Codable {
    var progress: [String: ShirtProgress]
    var totalStars: Int
    var lastCountry: String?
    var lastTeam: String?
    var trophies: [String: Bool]   // countryId -> desbloqueado
    var stickers: [String: Bool]   // teamId -> desbloqueado
    var gamesPlayed: GamesStats
    var onboardingCompleted: Bool  // Siempre true (sin onboarding)
}

struct GamesStats: Codable {
    var guessPlayed: Int
    var memoryPlayed: Int
    var guessWon: Int
}
```

### Assets offline

| Asset | Formato | Cantidad | Notas |
|-------|---------|----------|-------|
| Camisetas | SwiftUI Shapes / CAShapeLayer | 120 | Generadas por código nativo, no imágenes |
| Escudos | SwiftUI Shapes | 60 | Forma + texto + colores |
| Banderas | SwiftUI Shapes | 6 | Paths específicos por país |
| Sonidos | AAC (".m4a") | 4 | tap.m4a · success.m4a · celebrate.m4a · error-soft.m4a |
| Fuente | Nunito (TTF/OTF) | 1 | Incluida en Bundle, registada en Info.plist |

**Nota:** Las imágenes subidas (`pasted-*.png`) son **referencias reales** de camisetas y escudos para diseño visual, pero no se usan en el build. Los assets finales son vectores nativos casi idénticos en proporciones, colores y patrones, sin reproducir logos ni marcas registradas. En V1 evaluar licenciamiento oficial.

### Máscaras de pintura (Swift)

- **Técnica:** `CAShapeLayer` máscara + `UIBezierPath` para silueta. La capa gris es un `CALayer` con `mask` que se reduce progresivamente al arrastrar el dedo.
- **Alternativa:** SwiftUI `Canvas` con `BlendMode.clear` en un `GraphicsContext`.
- **Silueta:** `UIBezierPath` exacto de camiseta (240×280 viewBox escalado).
- **Radio de borrado:** 36pt base × `revealSpeed` (0.5–2.0).
- **Cálculo de %:** Sampleo del buffer de píxeles con stride 8 para performance.
- **Umbral de completado:** 85% (no 100%, para evitar frustración).

### Versionado de contenido local

| Versión | Contenido |
|---------|-----------|
| `contentVersion` | Número entero. Incrementar cuando se agreguen equipos/camis nuevas. Usar para migrar progreso local si cambian las keys. |

**Migración:** Si `contentVersion` local < `contentVersion` empaquetada, resetear progreso de nuevas camisetas a 0, preservar progreso de keys existentes.

---

## 6. NO FUNCIONALES

| Requisito | Especificación | Estado en diseño |
|-----------|---------------|------------------|
| **Performance** | 60fps en pintura, scroll fluido, transiciones suaves | ✅ Sampling optimizado (stride 8) · Transiciones nativas |
| **Peso de assets** | < 50MB total (sin imágenes reales) | ✅ Vectores nativos + fuente + 4 sonidos |
| **Uso offline** | 100% funcional sin conexión | ✅ Todo embebido en bundle |
| **Tiempos de carga** | < 2s desde tap en icono hasta HOME interactiva | ⚠️ PENDIENTE: optimizar bundle Swift |
| **Estabilidad** | Sin crashes en flujo completo de pintura | ⚠️ PENDIENTE: QA en device |
| **Plataforma** | **iOS + macOS nativo** (Swift/SwiftUI) | ✅ Target: iPadOS 16+, macOS 13+ |
| **Orientación** | **Landscape** en iPad · macOS adaptable a ventana | ✅ iPad bloqueado a landscape en MVP |
| **Persistencia local** | Progreso en `UserDefaults` + posible `Core Data` en V1 | ⚠️ PENDIENTE: implementar `UserDefaults` Codable |
| **Privacidad infantil** | Sin datos personales · Sin analytics remoto · Sin identificadores | ✅ Cumple COPPA/GDPR-K · App Kids category ready |

---

## 7. PLAN DE ENTREGA

### MVP 3–4 semanas

| Semana | Área | Tareas |
|--------|------|--------|
| **S1** | **Setup** | Proyecto SwiftUI multiplataforma (iOS + macOS) · Target iPadOS 16+ / macOS 13+ · Integrar fuente Nunito |
| | **Diseño** | Ajustes finales de tipografía en iPad real · Definir 4 sonidos (tap, success, celebrate, error-soft) · Splash animado |
| | **Frontend** | Implementar HOME, PAÍSES, EQUIPOS, DETALLE con navegación nativa (NavigationStack) |
| | **Assets** | Modelar 120 camisetas en Swift structs · Renderizado vectorial nativo (Shape/Path) |
| **S2** | **Lógica de pintura** | Implementar PaintScreen con CALayer mask · Cálculo de % revelado · Confetti con CAEmitterLayer o SpriteKit · Sonidos con AVAudioPlayer |
| | **Frontend** | FICHA FINAL (incluyendo lógica de REPINTAR que resetea progreso a 0) · ÁLBUM con filtros |
| | **Persistencia** | `UserDefaults` + `Codable` para progreso · Botón oculto RESET |
| **S3** | **Contenido** | Verificar data de los 60 equipos · Mapa de nombres de colores en español · Testing en iPad real |
| | **QA** | Flujo completo · Performance de máscara · Accesibilidad táctil · macOS ventana adaptable |
| **S4** | **Polishing** | Splash final · Ajustes de sonido · Review App Store / TestFlight · Build firmado |

### V1

- Juegos ADIVINAR y MEMORIA con lógica real
- Pantalla PREMIOS con lógica de desbloqueo
- Onboarding de 3 pasos
- Sonidos de efecto
- Haptics
- Mejoras de animación

### VNEXT

- Más países/equipos
- Camisetas reales oficiales (con licencia)
- Modo personalización
- Compartir
- VoiceOver mejorado

---

## 8. RIESGOS Y MITIGACIONES

| Riesgo | Severidad | Mitigación |
|--------|-----------|------------|
| **Derechos/licencias de camisetas reales** | Alta | MVP usa vectores nativos estilizados (patrones + colores casi idénticos, sin logos ni marcas oficiales). Escudos: iniciales + formas geométricas. Imágenes `uploads/` solo referencia de diseño. |
| **Cantidad grande de assets** | Media | Camisetas y escudos son vectores nativos (código Swift), no imágenes. Peso total < 10MB incluyendo sonidos. |
| **Performance de máscaras de pintura** | Media | `CALayer` mask + sampleo de píxeles con stride 8. Validar en iPad real con touch multi-finger. |
| **Dificultad de máscaras de pintura** | Media | Prototipo web valida la mecánica. Portar a `CAShapeLayer` / `Canvas` SwiftUI requiere ajuste pero es factible. |
| **Usabilidad para niño de 4 años** | Alta | Botones 56–104pt. Todo MAYÚSCULAS. Navegación visual. Revelado al 85%. Feedback inmediato + sonido. Sin onboarding (aprende explorando). |
| **Multiplataforma iOS + macOS** | Media | SwiftUI multiplataforma. iPad requiere landscape. macOS requiere adaptación de targets táctiles a mouse/trackpad. |
| **Offline** | Baja | Todo embebido en bundle. Sin dependencias de red. |
| **Consistencia visual entre equipos** | Media | Patrones limitados y reutilizados. Paleta normalizada. Escudos con 3 formas + iniciales. |
| **Pérdida de progreso** | Media | `UserDefaults` Codable inmediato al completar. Botón RESET oculto para testing. |

---

## 9. CHECKLIST QA

### Funcional
- [ ] Flujo completo: HOME → PAÍSES → EQUIPOS → DETALLE → PINTAR → FICHA → ÁLBUM
- [ ] Repintar desde FICHA resetea progreso de esa camiseta a 0
- [ ] BackButton funciona en todas las pantallas
- [ ] Filtros de álbum funcionan (TODAS + por país)
- [ ] Progreso se guarda al cerrar y reabrir app (`UserDefaults`)
- [ ] Contador de estrellas es correcto
- [ ] Botón RESET oculto funciona y limpia todo el progreso

### Visual
- [ ] Todas las camisetas renderizan correctamente en los 3 modos (gray, partial, color)
- [ ] Banderas de los 6 países correctas
- [ ] Escudos legibles a todos los tamaños
- [ ] Colores de los swatches en FICHA coinciden con camiseta
- [ ] Confetti anima correctamente (CAEmitterLayer o SpriteKit)
- [ ] Ghost finger aparece y desaparece correctamente
- [ ] Splash: camiseta gris se pinta sola en 1.5s

### Accesibilidad
- [ ] Botones >= 56pt de altura
- [ ] Targets táctiles no se solapan
- [ ] Contraste texto/fondo >= 4.5:1
- [ ] VoiceOver labels en botones principales
- [ ] No hay dead ends de navegación
- [ ] Feedback visual + sonido en todos los taps relevantes

### Offline
- [ ] App funciona en modo avión
- [ ] No hay pantallas de error por falta de red
- [ ] Tiempo de carga < 2s en iPad
- [ ] Sin requests de red en ningún momento

### Performance
- [ ] Pintura mantiene 60fps durante trazo en iPad
- [ ] Scroll en álbum es fluido
- [ ] Transiciones de pantalla < 300ms
- [ ] Sin memory leaks en máscara de pintura
- [ ] macOS: ventana adaptable no rompe layout

### Sonido
- [ ] tap.m4a al tocar botones
- [ ] success.m4a al acertar en adivinar
- [ ] celebrate.m4a al completar camiseta
- [ ] error-soft.m4a al fallar suavemente
- [ ] Sonidos respetan silencio del dispositivo

### Contenido
- [ ] 6 países × 10 equipos × 2 camisetas = 120 camisetas en data
- [ ] Nombres de colores en español cubren todos los hex usados
- [ ] Todos los textos visibles para el niño en MAYÚSCULAS
- [ ] Sin texto confuso o demasiado largo para pre-lector

### Regresión
- [ ] Cambio de paleta (warm/sky/mint/cream) no rompe contraste
- [ ] Cambio de `revealSpeed` no rompe cálculo de %
- [ ] iPad bloqueado a landscape no rompe navegación

---

## 10. DECISIONES CERRADAS

| # | Decisión | Detalle |
|---|----------|---------|
| 1 | **Camisetas/escudos: SVG estilizados casi iguales** | Vectores nativos Swift con patrones, colores y proporciones casi idénticos a los reales, sin reproducir logos ni marcas registradas. Referencias en `uploads/` solo para diseño. |
| 2 | **Sonidos: sí, 4 efectos en AAC (".m4a")** | `tap.m4a` (botones), `success.m4a` (acierto), `celebrate.m4a` (completar camiseta), `error-soft.m4a` (fallo suave). Embebidos en bundle, reproducidos con `AVAudioPlayer`. |
| 3 | **Onboarding: NO** | El niño aprende explorando. Sin slides iniciales. Primera apertura va directo a HOME. |
| 4 | **Repintar: sí, desde FICHA** | Botón REPINTAR resetea el progreso de esa camiseta a `status=0` y vuelve a PINTAR con capa gris completa. |
| 5 | **Plataforma: iOS + macOS nativo** | SwiftUI multiplataforma. iPad bloqueado a landscape. macOS adaptable a ventana. Target: iPadOS 16+, macOS 13+. |
| 6 | **Completar país: trofeo dorado + confetti + sonido especial** | Al descubrir las 20 camisetas de un país, desbloquea trofeo en PREMIOS con animación extra. |
| 7 | **Juegos: generación aleatoria desde data local** | ADIVINAR y MEMORIA (V1) usan selección aleatoria de equipos desde `CAMI_DATA`, no datos hardcodeados. |
| 8 | **Resetear todo: sí, botón oculto** | Accesible vía combinación de taps (ej: 5 taps rápidos en escudo del equipo favorito). Limpia `UserDefaults` y reinicia progreso. |
| 9 | **Tecnología: Swift nativo (SwiftUI)** | Prototipo web solo para validación de UX. Producto final: SwiftUI con `NavigationStack`, `UserDefaults`, `AVAudioPlayer`, `CALayer` máscaras. |
| 10 | **Splash: camiseta gris que se pinta sola en 1.5s** | Animación nativa al lanzar la app: silueta gris que se revela progresivamente como si un dedo invisible la pintara, luego fade a HOME. |

---

*Documento generado a partir del diseño detectado en `/DISEÑO CAMISETAS/`. Última actualización: 2026-04-29.*
