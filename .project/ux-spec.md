# UX Spec — Camisetas Basti

> Especificación de experiencia de usuario con wireframes ASCII adaptados a iPad landscape (1180×820 logical) y macOS ventana. Generado desde el PRD aprobado.

---

## 1. FLOWS PRINCIPALES

### Flow 1: Descubrir una camiseta (MVP principal)
1. Usuario abre app → **SPLASH** (camiseta gris se pinta sola, 1.5s)
2. Aparece **HOME** → toca "PAÍSES" (o "JUGAR" → "PINTAR")
3. Elige país en **PAÍSES** → navega a **EQUIPOS**
4. Elige equipo en **EQUIPOS** → navega a **DETALLE**
5. Toca "PINTAR" en TITULAR o SUPLENTE → navega a **PINTAR**
6. Pasa el dedo sobre camiseta gris → revela progresivamente
7. Al 85%: confetti + sonido + aparece "VER FICHA →"
8. Toca "VER FICHA" → navega a **FICHA**
9. Celebra, ve info del equipo, elige: ÁLBUM / OTRA / REPINTAR

### Flow 2: Jugar (MVP: acceso a pintar | V1: adivinar/memoria)
1. Usuario en **HOME** → toca "JUGAR"
2. **JUEGOS** muestra 3 opciones: PINTAR, ADIVINAR, MEMORIA
3. Toca PINTAR → redirige a **PAÍSES** (flujo 1 desde paso 3)
4. (V1) Toca ADIVINAR → **ADIVINAR**: camiseta parcial + 2 opciones
5. (V1) Toca MEMORIA → **MEMORIA**: grid 3×2 de cartas

### Flow 3: Ver progreso y colección
1. Usuario en **HOME** → toca "ÁLBUM" o "PREMIOS"
2. **ÁLBUM**: grid 8 columnas, filtra por país, ve descubiertas/bloqueadas
3. **PREMIOS**: estrellas totales, trofeos por país, stickers

### Flow 4: Repintar una camiseta ya descubierta
1. Usuario en **FICHA** de camiseta ya descubierta
2. Toca "REPINTAR" → progreso resetea a 0
3. Vuelve a **PINTAR** con capa gris completa

---

## 2. MAPA DE PANTALLAS

```
SPLASH
  │ (auto, 1.5s)
  ▼
HOME ───┬──→ PAÍSES ──→ EQUIPOS ──→ DETALLE ──→ PINTAR ──→ FICHA
        │                                        ↑            │
        │                                        └─────────────┘ (REPINTAR)
        │                                                                   
        ├──→ JUEGOS ──┬──→ PAÍSES (acceso directo a pintar)
        │             ├──→ ADIVINAR (V1)
        │             └──→ MEMORIA (V1)
        │
        ├──→ ÁLBUM ←──────────────────────────────────────────────┐
        │                                                         │
        └──→ PREMIOS                                              │
                                                                  │
        FICHA ──→ ÁLBUM ──────────────────────────────────────────┘
        FICHA ──→ OTRA ──→ DETALLE (elegir otra camiseta)
```

---

## 3. WIREFRAMES

---

### 3.1 SPLASH / LAUNCH

**Propósito:** Animar el lanzamiento y anticipar la mecánica de pintura.  
**Estados:** Animando (0-1.5s) · Finalizado → auto-navega a HOME  
**Dispositivo:** iPad landscape / macOS ventana  
**Interactiva:** NO. No se puede saltear.

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│                                                                            │
│                                                                            │
│                              ╭──────────╮                                  │
│                             ╱   ╭──╮    ╲                                 │
│                            │   │GRIS│    │         ← camiseta gris        │
│                            │   │ ?  │    │         (se revela            │
│                            │    ╰──╯    │          progresivamente)      │
│                             ╲          ╱                                   │
│                              ╰──────────╯                                  │
│                                                                            │
│                                                                            │
│                              CAMISETAS                                     │
│                         (aparece al finalizar)                             │
│                                                                            │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Camiseta centrada (grande, único elemento visual)
- Secundario: Título "CAMISETAS" (aparece fade-in al final)

**Acciones:** Ninguna. Auto-navega a HOME después de 1.5s.

**Criterios:** Animación 60fps · No bloqueable · Fade suave a HOME · Se muestra siempre

---

### 3.2 HOME

**Propósito:** Punto de entrada. El niño elige qué quiere hacer.  
**Estados:** Default · Botón presionado (active/hover)  
**Dispositivo:** iPad landscape / macOS ventana

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [✈ LISTO PARA JUGAR SIN INTERNET]                          [⭐ 12]        │
│                                                                            │
│                            CAMISETAS                                       │
│                      ⚽ PINTA · DESCUBRE · COLECCIONA ⚽                    │
│                                                                            │
│            [camiseta]       [camiseta]       [camiseta]                    │
│              (-12°)           (centro)         (+12°)                      │
│                                                                            │
│                                                                            │
│                 ┌────────────────────────────────────┐                     │
│                 │  🌎  PAÍSES                        │                     │
│                 └────────────────────────────────────┘                     │
│                                                                            │
│       ┌──────────────────┐          ┌──────────────────┐                   │
│       │  👕  JUGAR       │          │  📒  ÁLBUM       │                   │
│       └──────────────────┘          └──────────────────┘                   │
│                                                                            │
│                      ┌────────────────────┐                                │
│                      │  ⭐  PREMIOS       │                                │
│                      └────────────────────┘                                │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Botón "PAÍSES" (lg, naranja, más grande)
- Secundario: Botones "JUGAR" y "ÁLBUM" (md, celeste/verde)
- Terciario: Botón "PREMIOS" (sm, amarillo)
- Info: Badge estrellas arriba derecha · Chip offline arriba izquierda

**Acciones:**
- [PAÍSES] → Pantalla PAÍSES
- [JUGAR] → Pantalla JUEGOS
- [ÁLBUM] → Pantalla ÁLBUM
- [PREMIOS] → Pantalla PREMIOS

**Criterios:** 4 botones visibles · Targets >= 56pt · Título legible · Hero shirts renderizan

---

### 3.3 PAÍSES

**Propósito:** Elegir un país para ver sus equipos.  
**Estados:** Default · Hover/active en tarjeta  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  ELIGE UN PAÍS                                           [⭐ 12]      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │   [BANDERA       │  │   [BANDERA       │  │   [BANDERA       │         │
│  │   ARGENTINA]     │  │   INGLATERRA]    │  │    ESPAÑA]       │         │
│  │   🇦🇷             │  │   🏴󠁧󠁢󠁥󠁮󠁧󠁿       │  │   🇪🇸             │         │
│  │                  │  │                  │  │                  │         │
│  │   ARGENTINA      │  │   INGLATERRA     │  │   ESPAÑA         │         │
│  │      [12/20]     │  │       [0/20]     │  │       [8/20]     │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │   [BANDERA       │  │   [BANDERA       │  │   [BANDERA       │         │
│  │    ITALIA]       │  │    FRANCIA]      │  │    ALEMANIA]     │         │
│  │   🇮🇹             │  │   🇫🇷             │  │   🇩🇪             │         │
│  │                  │  │                  │  │                  │         │
│  │   ITALIA         │  │   FRANCIA        │  │   ALEMANIA       │         │
│  │       [0/20]     │  │       [0/20]     │  │       [0/20]     │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Grid 3×2 de tarjetas de país (ocupan casi toda la pantalla)
- Secundario: BackButton · Badge estrellas

**Acciones:**
- [Tarjeta país] → EQUIPOS (con country seleccionado)
- [←] → HOME

**Criterios:** 6 tarjetas visibles · Banderas legibles · Contador actualizado · Área táctil completa en tarjeta

---

### 3.4 EQUIPOS (Lista de equipos por país)

**Propósito:** Elegir un equipo del país seleccionado.  
**Estados:** Default · Hover · Camiseta gris (0/2) · Parcial (1/2) · Completa (2/2)  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  [🇦🇷] ARGENTINA                                          [⭐ 12]      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                   │
│  │ [1/2]  │ │ [2/2]  │ │ [0/2]  │ │ [0/2]  │ │ [0/2]  │                   │
│  │ [mini] │ │ [mini] │ │ [mini] │ │ [mini] │ │ [mini] │                   │
│  │shirt   │ │shirt   │ │shirt   │ │shirt   │ │shirt   │                   │
│  │ gray   │ │ color  │ │ gray   │ │ gray   │ │ gray   │                   │
│  │        │ │        │ │        │ │        │ │        │                   │
│  │ [⚽]   │ │ [⚽]   │ │ [⚽]   │ │ [⚽]   │ │ [⚽]   │                   │
│  │ BOCA   │ │ RIVER  │ │ RACING │ │ INDE   │ │ SAN LO.│                   │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘                   │
│                                                                            │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                   │
│  │ [0/2]  │ │ [0/2]  │ │ [0/2]  │ │ [0/2]  │ │ [0/2]  │                   │
│  │ [mini] │ │ [mini] │ │ [mini] │ │ [mini] │ │ [mini] │                   │
│  │shirt   │ │shirt   │ │shirt   │ │shirt   │ │shirt   │                   │
│  │ gray   │ │ gray   │ │ gray   │ │ gray   │ │ gray   │                   │
│  │        │ │        │ │        │ │        │ │        │                   │
│  │ [⚽]   │ │ [⚽]   │ │ [⚽]   │ │ [⚽]   │ │ [⚽]   │                   │
│  │ VÉLEZ  │ │ ESTU.  │ │CENTRAL │ │  NOB   │ │ HURA.  │                   │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘                   │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Grid 5×2 de tarjetas de equipo
- Secundario: BackButton · Bandera + nombre del país · Badge estrellas

**Acciones:**
- [Tarjeta equipo] → DETALLE (con team seleccionado)
- [←] → PAÍSES

**Criterios:** 10 equipos · Mini camisetas reflejan estado · Escudo legible a 22px · Badge X/2 visible

---

### 3.5 DETALLE DE EQUIPO

**Propósito:** Ver info del equipo y elegir TITULAR o SUPLENTE para pintar.  
**Estados:** Por descubrir · Descubierta  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]                                          [🗑] invisible (reset)        │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│              [⚽ ESCUDO GRANDE]          BOCA JUNIORS                       │
│                                         [🇦🇷] ARGENTINA                   │
│                                                                            │
│         ELIGE UNA CAMISETA PARA PINTAR                                     │
│                                                                            │
│  ┌────────────────────────┐    ┌────────────────────────┐                 │
│  │ [POR DESCUBRIR]        │    │ [✓ DESCUBIERTA]       │                 │
│  │                        │    │                        │                 │
│  │      [camiseta         │    │      [camiseta         │                 │
│  │       grande           │    │       grande           │                 │
│  │       240px]           │    │       240px            │                 │
│  │       gris]            │    │       color]           │                 │
│  │                        │    │                        │                 │
│  │       TITULAR          │    │       SUPLENTE         │                 │
│  │         🏠             │    │         ✈️             │                 │
│  │                        │    │                        │                 │
│  │    [ 👆 PINTAR ]       │    │    [ 👆 PINTAR ]       │                 │
│  └────────────────────────┘    └────────────────────────┘                 │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Dos tarjetas grandes de camiseta (TITULAR / SUPLENTE)
- Secundario: Escudo + nombre del equipo · BackButton
- Info: Badge de estado arriba izquierda de cada tarjeta

**Acciones:**
- [TITULAR] → PINTAR (kit = home)
- [SUPLENTE] → PINTAR (kit = away)
- [←] → EQUIPOS

**Criterios:** Escudo 70pt legible · Dos camisetas 240px · Badge estado visible · Botón PINTAR prominente

---

### 3.6 PINTAR / REVELAR CAMISETA

**Propósito:** Revelar la camiseta pasando el dedo sobre la capa gris.  
**Estados:** Inicial (100% gris) · Pintando (parcial) · Completado (confetti + botón)  
**Dispositivo:** iPad landscape. **Pantalla más importante de la app.**

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  [⚽] BOCA JUNIORS          [TITULAR]                    [?]          │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│                              PINTA                                         │
│                         (o "¡MUY BIEN!" al completar)                      │
│                                                                            │
│                              ╭──────────╮                                  │
│                             ╱            ╲                                 │
│                            │   ~~~~~~     │                                │
│                            │   ~~~~~~     │     ← capa gris encima        │
│                            │   ~~~~~~     │       (dedo la borra)         │
│                            │   ~~~~~~     │                                │
│                             ╲            ╱                                 │
│                              ╰──────────╯                                  │
│                            👆   (ghost hint                                │
│                                 si <5% progreso)                           │
│                                                                            │
│        ⭐      ⭐      ⭐      ○      ○                                      │
│       (20%)   (40%)  (60%)  (80%) (100%)                                   │
│                                                                            │
│                 ┌────────────────────────┐                                 │
│                 │    VER FICHA →         │     ← aparece al 85%           │
│                 └────────────────────────┘                                 │
│                                                                            │
│  [confetti cayendo al completar]                                           │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Área de camiseta (ocupa centro de pantalla, grande)
- Secundario: Barra de estrellas (feedback de progreso)
- Terciario: Botón "VER FICHA →" (aparece solo al completar)
- Info: BackButton · Escudo + nombre · Badge TITULAR/SUPLENTE · Botón "?" ayuda

**Acciones:**
- [Dedo sobre camiseta] → Borra gris, revela debajo
- [?] → HelpOverlay modal: "PASA EL DEDO POR LA CAMISETA PARA DESCUBRIRLA"
- [VER FICHA →] → FICHA FINAL (solo al completar)
- [←] → DETALLE DE EQUIPO

**Criterios:** Respuesta inmediata al touch · No pinta fuera de silueta · Estrellas actualizan cada 20% · Confetti al 85% · Ghost hint funciona · Sonido celebrate al completar

---

### 3.7 FICHA FINAL

**Propósito:** Celebrar el descubrimiento y ofrecer próximos pasos.  
**Estados:** Default  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]                              ¡MUY BIEN!                                │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌─────────────────────────┐    ┌─────────────────────────────────────────┐│
│  │                         │    │ [⚽ ESCUDO]     BOCA JUNIORS            ││
│  │    [camiseta            │    │                                         ││
│  │     grande              │    │  [🇦🇷] ARGENTINA                        ││
│  │     a color             │    │                                         ││
│  │     en tarjeta          │    │  COLORES                                ││
│  │     blanca              │    │  [🔵] [🟡] AZUL Y AMARILLO              ││
│  │     rotada -2°]         │    │                                         ││
│  │                         │    │  TITULAR                                ││
│  │                         │    │  +1 SUMADA AL ÁLBUM                     ││
│  └─────────────────────────┘    │                                         ││
│                                 │  ┌──────────┐ ┌──────────┐ ┌─────────┐ ││
│                                 │  │ OTRA →   │ │ 📒 ÁLBUM │ │ 🔄 REP  │ ││
│                                 │  └──────────┘ └──────────┘ └─────────┘ ││
│                                 └─────────────────────────────────────────┘│
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Camiseta grande en tarjeta blanca (celebración visual)
- Secundario: Info del equipo (escudo, nombre, país, colores)
- Terciario: Botones de acción (OTRA, ÁLBUM, REPINTAR)
- Destacado: Título "¡MUY BIEN!" en naranja grande

**Acciones:**
- [OTRA →] → DETALLE DE EQUIPO (mismo país)
- [ÁLBUM] → ÁLBUM
- [REPINTAR] → PINTAR (resetea progreso a 0)
- [←] → PINTAR

**Criterios:** Camiseta a color · Swatches de colores correctos · Botones grandes y claros · Progreso guardado

---

### 3.8 ÁLBUM

**Propósito:** Ver colección completa de camisetas.  
**Estados:** Default · Con datos · Vacío (0 descubiertas)  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  MI ÁLBUM                                          [12 / 120] ✅      │
├────────────────────────────────────────────────────────────────────────────┤
│  [TODAS]  [🇦🇷]  [🏴󠁧󠁢󠁥󠁮󠁧󠁿]  [🇪🇸]  [🇮🇹]  [🇫🇷]  [🇩🇪]                         │
├────────────────────────────────────────────────────────────────────────────┤
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐                 │
│ │✅🟢│ │✅🟢│ │⚪──│ │⚪──│ │⚪──│ │⚪──│ │⚪──│ │⚪──│                 │
│ │shirt│ │shirt│ │shirt│ │shirt│ │shirt│ │shirt│ │shirt│ │shirt│                 │
│ │color│ │color│ │gray │ │gray │ │gray │ │gray │ │gray │ │gray │                 │
│ │BOCA│ │RIVER│ │RAC. │ │INDE │ │SANL│ │VEL. │ │EST. │ │CEN. │                 │
│ │TIT │ │TIT  │ │TIT  │ │AWAY │ │TIT  │ │TIT  │ │TIT  │ │TIT  │                 │
│ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘                 │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐                 │
│ │⚪──│ │⚪──│ │⚪──│ │⚪──│ ...                                      │
│ │shirt│ │shirt│ │shirt│ │shirt│                                            │
│ │gray │ │gray │ │gray │ │gray │                                            │
│ │ NOB │ │HURA│ │ ... │ │ ... │                                            │
│ │TIT  │ │TIT  │      │      │                                            │
│ └────┘ └────┘ └────┘ └────┘                                              │
│                                                                           │
│  (scroll vertical si hay más)                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

**Estado vacío (alternativo):**
```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  MI ÁLBUM                                            [0 / 120]        │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│                                                                            │
│                         [camiseta gris grande]                             │
│                                                                            │
│                    PINTA TU PRIMERA                                        │
│                       CAMISETA                                             │
│                                                                            │
│                      ┌────────────┐                                        │
│                      │  🎨 EMPEZAR │                                        │
│                      └────────────┘                                        │
│                                                                            │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Grid 8 columnas de celdas de camiseta
- Secundario: Filtros por país (TODAS + banderas)
- Info: Contador global descubiertas/total · BackButton

**Acciones:**
- [Filtro país] → Filtra grid
- [Celda camiseta] → (V1: opcional, navegar a ficha de esa camiseta)
- Scroll → Ver más camisetas
- [←] → HOME

**Criterios:** Grid 8 cols responsive · Bordes correctos (verde sólido = descubierta, dashed gris = bloqueada) · Contador actualizado · Scroll fluido

---

### 3.9 JUEGOS

**Propósito:** Elegir minijuego.  
**Estados:** Default · Hover/active  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  JUGAR                                                                 │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌────────────────────────┐ ┌────────────────────────┐ ┌──────────────────┐│
│  │                        │ │                        │ │                  ││
│  │      [🎨]              │ │      [❓]              │ │      [🃏]        ││
│  │    (círculo            │ │    (círculo            │ │    (círculo      ││
│  │     naranja            │ │     celeste            │ │     verde)       ││
│  │     140px)             │ │     140px)             │ │     140px)       ││
│  │                        │ │                        │ │                  ││
│  │       PINTAR           │ │      ADIVINAR          │ │      MEMORIA     ││
│  │   DESCUBRE LA          │ │      ¿CUÁL ES?         │ │   BUSCA LOS      ││
│  │      CAMISETA          │ │                        │ │      PARES       ││
│  │                        │ │                        │ │                  ││
│  │   [ JUGAR ▶ ]          │ │   [ JUGAR ▶ ]          │ │   [ JUGAR ▶ ]    ││
│  │   (naranja)            │ │   (celeste)            │ │   (verde)        ││
│  └────────────────────────┘ └────────────────────────┘ └──────────────────┘│
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: 3 tarjetas grandes de juego (grid 3 columnas)
- Secundario: BackButton

**Acciones:**
- [PINTAR] → PAÍSES (acceso directo a flujo de pintura)
- [ADIVINAR] → ADIVINAR (V1)
- [MEMORIA] → MEMORIA (V1)
- [←] → HOME

**Criterios:** 3 juegos visibles · Iconos grandes en círculos · Tarjetas clickeables en toda el área

---

### 3.10 ADIVINAR (V1)

**Propósito:** Adivinar el equipo viendo una camiseta parcial.  
**Estados:** Default · Acierto · Error  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  ¿CUÁL ES?                                    [⭐ ⭐ ○ ○ ○]            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│                    ┌────────────────────┐                                  │
│                    │  [camiseta         │                                  │
│                    │   parcial          │                                  │
│                    │   al 45%]          │                                  │
│                    │   (solo se ve      │                                  │
│                    │    un pedacito)    │                                  │
│                    └────────────────────┘                                  │
│                                                                            │
│        ┌────────────────────────┐      ┌────────────────────────┐         │
│        │        [⚽]            │      │        [⚽]            │         │
│        │       escudo           │      │       escudo           │         │
│        │       BOCA             │      │       RIVER            │         │
│        │                        │      │                        │         │
│        │      [mini shirt      │      │      [mini shirt       │         │
│        │        color]          │      │        gray]           │         │
│        │                        │      │                        │         │
│        │       BOCA             │      │       RIVER            │         │
│        │                        │      │                        │         │
│        │        ⭐ (si acierta) │      │        🔁 (si falla)   │         │
│        │    [borde verde]       │      │    [borde rojo]        │         │
│        │                        │      │    [shake anim]        │         │
│        └────────────────────────┘      └────────────────────────┘         │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Camiseta parcial centrada + 2 opciones grandes abajo
- Secundario: ProgressStars · BackButton

**Acciones:**
- [Opción A/B] → Selecciona equipo · Feedback visual inmediato · Input bloqueado
- [←] → JUEGOS

**Criterios:** Camiseta parcial visible · Opciones con escudo + mini camiseta · Feedback inmediato · Shake en error · No permite cambiar respuesta

---

### 3.11 MEMORIA (V1)

**Propósito:** Encontrar pares de camiseta + escudo del mismo equipo.  
**Estados:** Reverso · Volteada · Matched  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  MEMORIA                                      [⭐ ⭐ ○ ○ ○]            │
│      BUSCA LOS PARES                                                       │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐               │
│  │   [🟧 naranja] │  │   [🟧 naranja] │  │   [🟧 naranja] │               │
│  │                │  │                │  │                │               │
│  │       ?        │  │       ?        │  │       ?        │               │
│  │                │  │                │  │                │               │
│  │   (reverso)    │  │   (reverso)    │  │   (reverso)    │               │
│  └────────────────┘  └────────────────┘  └────────────────┘               │
│                                                                            │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐               │
│  │   [🟧 naranja] │  │   [🟧 naranja] │  │   [🟧 naranja] │               │
│  │                │  │                │  │                │               │
│  │       ?        │  │       ?        │  │       ?        │               │
│  │                │  │                │  │                │               │
│  │   (reverso)    │  │   (reverso)    │  │   (reverso)    │               │
│  └────────────────┘  └────────────────┘  └────────────────┘               │
│                                                                            │
│  (al voltear: muestra camiseta o escudo)                                   │
│  (si match: borde verde, permanece visible)                                │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Grid 3×2 de cartas (ocupa centro)
- Secundario: ProgressStars · BackButton · Subtítulo

**Acciones:**
- [Carta] → Voltea · Si 2 volteadas: compara · Match = verde · No match = vuelve a reverso
- [←] → JUEGOS

**Criterios:** Volteo animado · Solo 2 cartas a la vez · Match detectado · Input bloqueado durante animación

---

### 3.12 PREMIOS (V1)

**Propósito:** Ver progreso y recompensas desbloqueadas.  
**Estados:** Default  
**Dispositivo:** iPad landscape

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [←]  PREMIOS                                                               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │  TUS ESTRELLAS                                                     │   │
│  │                                                                    │   │
│  │  12 ⭐                                    [⭐][⭐][⭐][⭐][⭐]       │   │
│  │                                         (estrellas decorativas)   │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐                      │
│  │   🏆     │ │   🏆     │ │   🏆     │ │   🏆     │                      │
│  │  [🇦🇷]   │ │  [🇪🇸]   │ │  [🏴󠁧󠁢󠁥󠁮󠁧󠁿]│ │  [🇮🇹]   │                      │
│  │ARGENTINA │ │  ESPAÑA  │ │INGLATERRA│ │  ITALIA  │                      │
│  │ ✅ dorado│ │ ✅ dorado│ │ ⚪ gris  │ │ ⚪ gris  │                      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘                      │
│                                                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐                      │
│  │ [shirt]  │ │ [shirt]  │ │ [shirt]  │ │ [shirt]  │                      │
│  │  BOCA    │ │  BARÇA   │ │   LIV    │ │  BAYERN  │                      │
│  │ [¡NUEVO!]│ │          │ │          │ │          │                      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘                      │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía:**
- Primario: Tarjeta grande gradiente con estrellas totales
- Secundario: Grid 4 columnas de trofeos + stickers
- Info: BackButton

**Acciones:**
- Scroll → Ver más trofeos/stickers
- [←] → HOME

**Criterios:** Estrellas correctas · Trofeos dorados vs grises distinguibles · Badge "¡NUEVO!" visible

---

## 4. COMPONENTES REUTILIZABLES DETECTADOS

| Componente | Dónde se usa | Variantes | Notas de implementación |
|------------|-------------|-----------|------------------------|
| **BackButton** | Todas excepto SPLASH | Único | Círculo 64×64 blanco, flecha ← naranja #7A4E1B. Siempre arriba-izquierda. |
| **BigKidButton** | HOME, JUEGOS, FICHA, ÁLBUM vacío | primary/sky/grass/sun/secondary · sm/md/lg | Sombra dura 0 8px, hundimiento al tocar. Min-height 56-104pt. |
| **CountryCard** | PAÍSES | Default | Fondo blanco, bandera grande, nombre, badge contador. Hover translateY(-4px). |
| **TeamCard** | EQUIPOS | Gris / Parcial / Color | Fondo blanco, mini camiseta 110pt, escudo 22pt, nombre corto, badge X/2. |
| **ShirtView** | PINTAR, FICHA, DETALLE, ÁLBUM, ADIVINAR, MEMORIA | color / gray / partial | Renderizado vectorial nativo. Silueta única, patrones parametrizados. |
| **CrestView** | DETALLE, EQUIPOS, ADIVINAR, MEMORIA | round / shield / diamond | Forma + iniciales + 2 colores. Escalable. |
| **FlagView** | PAÍSES, EQUIPOS, DETALLE, FICHA, ÁLBUM filtros | 6 países | Paths nativos específicos por país. Bordes redondeados. |
| **ProgressStars** | PINTAR, ADIVINAR, MEMORIA | count / total / size | Estrellas ⭐ iluminadas vs apagadas. Progreso no numérico. |
| **ConfettiView** | PINTAR (completado), FICHA | Único | 60 partículas, colores definidos, 1.5-2.5s. `pointerEvents: none`. |
| **AlbumCell** | ÁLBUM | Descubierta / Parcial / Bloqueada | Fondo #FFF7EC, borde verde sólido/dashed, mini camiseta 70pt. |
| **HelpOverlay** | PINTAR | Único | Modal centrado con 👆 y texto "PASA EL DEDO". Tap fuera para cerrar. |

---

## 5. HANDOFF A LOCAL DATA DESIGNER

Datos locales que cada pantalla necesita:

| Pantalla | Datos necesarios | Fuente |
|----------|-----------------|--------|
| **SPLASH** | Ninguno (solo animación) | — |
| **HOME** | `totalStars`, `hasProgress` | `AppState` |
| **PAÍSES** | `CAMI_DATA.COUNTRIES`, `progressByCountry` | `CAMI_DATA` + `AppState` |
| **EQUIPOS** | `CAMI_DATA.TEAMS[countryId]`, `progressByTeam` | `CAMI_DATA` + `AppState` |
| **DETALLE** | `Team`, `Country`, `progress[home/away]` | `CAMI_DATA` + `AppState` |
| **PINTAR** | `Team`, `kit` (home/away), `revealPct` (si parcial) | `CAMI_DATA` + `AppState` |
| **FICHA** | `Team`, `Country`, `kit`, `colors`, `status` | `CAMI_DATA` + `AppState` |
| **ÁLBUM** | `allShirtsProgress`, `filter` | `AppState` |
| **JUEGOS** | Ninguno (estático) | — |
| **ADIVINAR** | `randomTeam`, `wrongTeam`, `revealPct=45` | `CAMI_DATA` (aleatorio) |
| **MEMORIA** | `randomTeams[3]`, generación de 6 cartas | `CAMI_DATA` (aleatorio) |
| **PREMIOS** | `totalStars`, `trophies`, `stickers` | `AppState` |

---

## 6. DECISIONES DE UX TOMADAS

| Decisión | Valor | Razón |
|----------|-------|-------|
| Sin onboarding | No slides iniciales | El niño aprende explorando, como acordó en el PRD |
| iPad landscape | Horizontal primario | El diseño original está en 1180×820 landscape |
| Grid 3×2 en PAÍSES | 6 países | Fill rate perfecto, tarjetas grandes |
| Grid 5×2 en EQUIPOS | 10 equipos | Fill rate perfecto, 2 filas |
| Grid 1×2 en DETALLE | 2 camisetas | TITULAR/SUPLENTE lado a lado, muy grandes |
| Grid 8 cols en ÁLBUM | 120 camisetas | 15 filas aprox, scroll manejable |
| Ghost finger en PINTAR | 👆 animado a los 3s | Ayuda al niño que no sabe qué hacer |
| Revelado al 85% | No 100% | Evita frustración, auto-clear completa |
| BackButton siempre | Arriba-izquierda | Navegación consistente, fácil de encontrar |
| MAYÚSCULAS todo | Texto visible para niño | Acuerdo del PRD, niño de 4 años |

---

*UX Spec generado desde PRD.md · Estado: LISTO PARA APROBACIÓN*

**Próximo paso:** Si el usuario aprueba este UX Spec, actualizar `.project/state.md` (Gate 2 ✅) y handoff a `@backend-designer` o `@swiftui-engineer`.
