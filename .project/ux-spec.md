# UX Spec — Torneo simulado

## Objetivo de experiencia
La seccion torneo debe tener dos maneras claras de jugar:

1. **Manual:** Basti toca el escudo/equipo que quiere hacer avanzar.
2. **Simulado:** Basti toca un partido, mira como se juega, ve goles y resultado, y el ganador avanza solo.

La experiencia tiene que sentirse como "jugar un torneo", no como completar una tabla. La clave es que cada avance tenga causa visible: se jugo un partido, hubo resultado, y por eso el equipo paso de fase.

## Estructura de pantalla

### Header
- Titulo: `SIMULAR TORNEO`.
- Subtitulo dinamico segun modo:
  - Manual: `TOCA UN ESCUDO PARA HACERLO AVANZAR`.
  - Simulado: `TOCA UN PARTIDO PARA JUGARLO`.
- Mantener boton volver.

### Controles superiores
- Selector de liga/pais actual.
- Boton `ARMAR LLAVES`.
- Nuevo control segmentado:
  - `Manual`
  - `Partidos`

El modo elegido debe quedar muy claro visualmente. No alcanza con cambiar texto chico: el control segmentado tiene que mostrar estado activo con color/acento.

## Modo Manual
Mantiene el comportamiento actual:
- El usuario toca un equipo dentro de un partido.
- Ese equipo avanza a la siguiente fase.
- Si cambia una fase anterior, se limpian las fases dependientes.

Microcopy recomendado:
- `TOCA UN ESCUDO PARA HACERLO AVANZAR`.

## Modo Partidos

### Regla principal
En modo simulado no se elige un ganador tocando un escudo. Se toca el **partido completo**.

Un partido es jugable si:
- tiene dos equipos cargados;
- todavia no tiene ganador;
- pertenece a la fase activa o a una fase disponible por la progresion de la llave.

### Estados visuales de un partido
- **Pendiente:** dos equipos cargados, sin resultado. Debe verse como accionable.
- **No disponible:** falta algun equipo. Debe verse apagado y no accionable.
- **Jugado:** tiene resultado final y ganador. Debe mostrar marcador chico y resaltar ganador.
- **Siguiente recomendado:** primer partido pendiente disponible. Debe tener un brillo/borde suave para guiar a Basti.

### Comportamiento al tocar un partido
1. Si el partido esta disponible, se abre modal de partido.
2. La llave queda por detras oscurecida.
3. El modal toma foco completo.
4. El partido se juega automaticamente.
5. Al terminar, aparece resultado final y boton `CERRAR`.
6. Al cerrar, se carga el resultado en la llave y el ganador avanza.
7. Si el ganador completa una nueva fase, el proximo partido disponible queda sugerido visualmente.

## Modal de partido

### Layout iPad horizontal
El modal debe ocupar casi toda la pantalla, pero no parecer una alerta chica.

Estructura:
- Top bar de marcador.
- Cancha central vista desde arriba.
- Banda inferior de estado/eventos.

### Top bar de marcador
Debe mostrar:
- escudo local;
- nombre corto local;
- goles local;
- tiempo animado;
- goles visitante;
- nombre corto visitante;
- escudo visitante.

Formato sugerido:
`[escudo] RIVER 1  —  0 RACING [escudo]`

El tiempo puede ser ficticio:
- inicia en `0'`;
- avanza hasta `90'` durante los 30-45 segundos reales;
- si hay goles, el marcador cambia en el momento del evento.

### Cancha
Vista superior, simple y legible:
- pasto verde con lineas blancas;
- area grande, circulo central, arcos;
- jugadores como circulos o pins;
- pelota visible con contraste;
- equipos diferenciados por color.

No buscar realismo 3D. El objetivo es comprension inmediata.

### Jugadores
- 5 o 6 jugadores por equipo para que no se sature en iPad 10.
- Local usa color primario de camiseta/equipo.
- Visitante usa color contrastante.
- Si los colores se parecen, usar borde blanco/oscuro o short secundario para distinguir.

### Pelota
- Debe ser el elemento mas facil de seguir despues del marcador.
- Se mueve entre zonas de la cancha.
- En ataque, se acerca al arco.
- En gol, entra al arco y dispara feedback visual.

### Eventos
Estados de evento:
- `ARRANCA EL PARTIDO`
- `ATACA RIVER`
- `REMATE`
- `GOL DE RIVER`
- `ATAJA EL ARQUERO`
- `FINAL DEL PARTIDO`

La banda inferior muestra el evento actual, no una lista larga.

## Motion

Momentos donde la animacion importa:

1. **Apertura del partido**
   - Modal entra con scale/fade suave.
   - Marcador aparece primero, cancha despues.
   - Duracion: 300-450 ms.

2. **Juego en vivo**
   - Pelota se mueve con trayectorias simples.
   - Jugadores se desplazan en pequenos patrones.
   - La camara no se mueve; la cancha queda estable.
   - Evitar animaciones caoticas: Basti tiene que entender donde esta la pelota.

3. **Gol**
   - Marcador hace pulse.
   - Equipo que convierte tiene halo/acento.
   - Texto grande breve: `GOOOL`.
   - Puede haber vibracion/haptic si esta disponible y no molesta.

4. **Final**
   - Se frena la pelota.
   - Resultado final aparece grande.
   - Ganador queda resaltado.
   - Boton `CERRAR` aparece solo al terminar.

5. **Avance en llave**
   - Al cerrar modal, ganador debe "aparecer" en la siguiente fase con una transicion clara.
   - No debe sentirse instantaneo o invisible.

## Resultados

Los resultados deben sentirse futboleros, no completamente random.

Distribucion UX esperada:
- Frecuentes: 0-0, 1-0, 1-1, 2-1, 2-0.
- Menos frecuentes: 3-1, 3-2.
- Raros: 4-0, 4-1, 5-2.

Si hay empate en fase eliminatoria:
- Mostrar como partido empatado hasta el final.
- Resolver con evento simple: `PENALES`.
- El marcador final puede quedar empatado, pero el ganador se define por penales.
- En la llave, avanzar el ganador y mostrar indicador corto: `PEN`.

## Copy

Pantalla:
- Modo Manual: `TOCA UN ESCUDO PARA HACERLO AVANZAR`.
- Modo Partidos: `TOCA UN PARTIDO PARA JUGARLO`.
- Partido no disponible: `FALTA RIVAL`.
- Partido jugado: `FINALIZADO`.

Modal:
- Inicio: `ARRANCA EL PARTIDO`
- Gol: `GOOOL`
- Penales: `SE DEFINE POR PENALES`
- Final: `FINAL DEL PARTIDO`
- Boton final: `CERRAR`

## Responsive

### iPad 12/13 pulgadas horizontal
- Bracket completo visible sin scroll horizontal.
- Modal amplio, cancha protagonista.
- Marcador con nombres cortos y escudos grandes.

### iPad 10 pulgadas horizontal
- Reducir tamanos de crest/nombres antes que comprimir la cancha.
- Mantener cancha legible.
- Si hace falta, abreviar nombres a `short`.
- Modal debe evitar margenes grandes.

## Accesibilidad y reduced motion
- Si `Reduce Motion` esta activo, el partido puede usar menos movimiento continuo y mas estados discretos:
  - posesicion;
  - ataque;
  - remate;
  - gol/final.
- El resultado no debe depender solo del color: usar marcador, texto y resaltado.
- Los botones deben tener area tactil amplia para chico en iPad.

## Tradeoffs
- Se prioriza claridad y diversion por encima de simulacion futbolistica real.
- No se implementa fisica compleja; se simulan momentos narrativos.
- No se agrega sonido obligatorio en MVP para evitar sumar dependencia y QA extra.
- No se oculta el modo manual: queda como alternativa rapida para seguir jugando como hoy.

## Handoff a implementacion
La implementacion deberia crear:
- Estado de modo de torneo: `manual` / `simulated`.
- Modelo de resultado por partido.
- Modelo de simulacion con eventos temporales.
- Modal full-screen de partido.
- Vista de cancha animada offline.
- Actualizacion de bracket al cerrar un partido finalizado.
- Estados visuales por partido: pendiente, no disponible, jugado, recomendado.

## Criterios de aceptacion UX
- Basti puede distinguir modo manual vs modo partidos sin ayuda.
- En modo partidos, tocar un partido abre una simulacion y no selecciona ganador directo.
- Durante el partido se entiende quien juega, cuanto van y cuando hay gol.
- Al terminar, se entiende quien gano.
- Al cerrar, el ganador aparece en la siguiente fase.
- Se puede completar un torneo completo hasta campeon simulado.
- En iPad 10 y 12/13 horizontal no hay elementos cortados, superpuestos ni botones chicos.
