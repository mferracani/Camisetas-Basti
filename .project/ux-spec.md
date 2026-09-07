# UX Spec — Torneo simulado

## Iteración de juego colectivo — 2026-09-07

Mati validó la fluidez de la carrera pero rechazó la simulación por repetitiva y aburrida. Dentro del mismo modal aprobado: combinar paredes (pasar y seguir corriendo), pases al espacio, cambios de frente, desbordes y centros, conducciones y contraataques tras recuperar. Quien pierde la pelota presiona o retrocede; quien la gana tiene salida y compañeros que se ofrecen. Los defensores marcan, cubren al compañero que sale y cierran líneas de pase. Los ataques también pueden perderse antes de llegar al remate. Los apoyos tienen funciones y recorridos diferentes, sin desplazar todo el equipo en bloque. La jugada se debe entender mirando cancha/pelota, con el relato como complemento. Se conservan cámara fija, kits, fluidez, duración de 110 s, Reduce Motion y el resultado/avance aprobados.

## Iteración motion natural — 2026-09-07

Pedido explícito de Mati con `ui-art-director`, dentro del modal y gates existentes. Tesis: **perfil, apoyo, contacto y continuación de la carrera**. Trayectorias cúbicas conectadas, orientación corporal gradual, zancada por distancia, piernas/brazos articulados, toques cortos y recepción desde el pie. El arquero conserva la caída y se recupera sin saltar de pose al cambiar la jugada. Jugadores más compactos, sombra anclada y profundidad por posición.

El render de cancha y tanda usa `TimelineView` con intervalo objetivo de 1/60 s; esto reemplaza el refresco visual de 30 Hz indicado en el addendum v2. El reloj lógico sigue a 30 Hz y la presentación interpola como máximo hasta el siguiente tick, sin springs sobre posiciones. Fondo, final y Reduce Motion pausan el render continuo; se conserva el relato accesible único y el impacto `0.78`.

Tanda final: carrera y apoyo continuos, golpe sin rebote, pelota que se achica con la distancia, figura del pateador con shorts/rodillas/botines y aterrizaje del arquero. Sin controles nuevos. Coreografía, evidencia y límites: `match-natural-motion-2026-09-07.md`.

## Incremento Liga Argentina 2026

- Al elegir `ARGENTINA`, la llave suma una columna exterior `RONDA DE 32` en cada lado.
- Los 30 clubes se distribuyen entre 32 plazas y dos plazas se muestran como `LIBRE`.
- La llave admite desplazamiento horizontal para preservar escudos y blancos táctiles legibles en iPad.
- `MUNDIAL 2026` y las ligas de hasta 16 equipos conservan su presentación actual.

## Iteración solicitada: camisetas y pelota parada (2026-09-07)

Mati validó la presentación del partido y pidió fidelidad de camisetas, tiros libres y penales. Extensión de los microeventos existentes, sin pantalla ni interacción nueva:
- Camisetas del partido: conservar el kit titular o suplente real del catálogo; no inventar colores para contraste. Patrones diferentes conservan su geometría, incluida la cuadrícula de Croacia. Contornos e indicadores distinguen lados si los kits auténticos se parecen.
- Tiro libre: falta → pelota quieta y barrera → carrera/remate por arriba o alrededor de la barrera → gol, atajada, afuera o bloqueo → reposición.
- Penal durante el partido: falta → pelota en el punto penal, rivales fuera del área y detrás de la pelota → carrera y disparo → gol, atajada o afuera → reposición. No confundir con la tanda final existente.
- Mantener 22 jugadores, cámara fija, 90–110 segundos y accesibilidad. Reducir movimiento conserva preparación y desenlace, sin salto ni vuelo continuo.
- El marcador cambia una sola vez al impacto del gol, nunca al cobrar la falta. La tanda final mantiene su marcador independiente y usa las mismas camisetas que el partido.

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
- avanza hasta `90'` durante los 90-110 segundos reales;
- si hay goles, el marcador cambia en el momento del evento.

### Cancha
Vista superior, simple y legible:
- pasto verde con lineas blancas;
- area grande, circulo central, arcos;
- jugadores como mini-camisetas compactas;
- pelota visible con contraste;
- equipos diferenciados por color.

No buscar realismo 3D. El objetivo es comprension inmediata.

### Jugadores
- 11 jugadores por equipo en mini-camisetas compactas, con dorsal grande y contrastado; sólo poseedor, receptor y jugador que presiona reciben un énfasis de silueta.
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

## Addendum UX — Realismo narrativo v2 (2026-08-22)

### Principio de interacción

La simulación usa una timeline de microjugadas conectadas. Cada evento empieza exactamente donde terminó el anterior:

`POSESIÓN → PASE / CONDUCCIÓN → PRESIÓN → DUELO / INTERCEPCIÓN → REMATE → REPOSICIÓN`

En ataques por afuera, la secuencia puede ser `DEFENSA → MEDIOCAMPO → EXTREMO → DESBORDE → CENTRO → LLEGADA DEL 9`. El bloque acompaña de forma gradual: no se reposiciona completo de un evento al siguiente.

No se busca física profesional. El realismo surge de que cada cambio tiene causa, continuidad y una consecuencia visible.

### Estados aprobados

- `kickoff`: saque inicial con pateador sobre la pelota.
- `carry`: conducción corta con la pelota controlada.
- `pass`: la pelota sale del pasador, queda libre durante el viaje y llega al receptor.
- `cross`: el extremo desborda y envía un centro curvo al delantero que llega al área.
- `pressure`: un defensor sale al cruce y el resto conserva la forma.
- `duel`: atacante y defensor disputan próximos; el resultado es legible.
- `interception`: el defensor corta la trayectoria antes del receptor.
- `tackle`: el defensor alcanza al portador y sale con la pelota.
- `shot`: resultado diferenciado en gol, atajada, afuera o bloqueo.
- `restart`: saque del medio, salida del arquero, saque de arco o despeje.
- `finalWhistle`: pelota detenida y resultado final.

### Claridad visual

- 11 jugadores por equipo en una formación 4-3-3 compacta, representados como camisetas con números 1-11 de lectura inmediata, sin saturar el iPad 10.
- Aro blanco sólido para quien controla la pelota.
- Aro amarillo punteado para el próximo receptor.
- Aro naranja para el defensor que presiona.
- Trail sólo durante pases largos, centros y remates.
- La pelota permanece por encima de los jugadores y nunca cambia de dueño durante el vuelo.
- El feedback `AFUERA` se mantiene dentro del área visible aunque la pelota termine junto al borde.
- La formación mantiene una separación mínima corregida por la relación 1.72:1 de la cancha, también durante la interpolación y no sólo al final de cada jugada.

### Ritmo y motion

- Partido completo: 90–110 segundos.
- Pases y conducciones: aproximadamente 0,55–1,10 segundos relativos.
- Presiones, duelos e intercepciones: aproximadamente 0,45–0,85 segundos relativos.
- Remate y resolución: aproximadamente 0,90–1,35 segundos relativos.
- Cámara fija y refresco visual a 30 Hz con interpolación continua; no usar springs sobre posiciones actualizadas por timer.
- Al terminar, el timer deja de invalidar la pantalla detrás del panel final.

### Accesibilidad

- Con `Reduce Motion`, la duración no se comprime: se muestran los mismos eventos con posiciones discretas, pelota sin giro y transiciones de etapa sin spring.
- La cancha y los 22 marcadores de jugador son decorativos para VoiceOver.
- La banda inferior expone un único anuncio con minuto, marcador y jugada actual.

### Criterios de aceptación v2

- Ambos equipos completan pases y recuperan la pelota durante cada simulación.
- Cada partido contiene al menos un remate no convertido; la batería determinística cubre afuera, atajada y bloqueo.
- El marcador visible coincide exactamente con los goles de la timeline y el resultado final.
- Los pateadores, portadores y receptores están espacialmente conectados con la pelota.
- Ningún jugador sale del área jugable ni se amontona con un compañero durante una trayectoria.
- Los reinicios no muestran jugadores corriendo detrás del arco ni saltos de pelota visibles.

## Iteración de presentación — Partidos con más vida (2026-09-07)

Pedido de Mati: mejorar una visualización que se percibe tosca, poco animada y aburrida. Se reutiliza el alcance aprobado: el mismo modal, cámara fija, 22 jugadores, partidos de 90–110 segundos, marcador y avance de llave.

- **Jugador:** conserva camiseta y dorsal; agrega cabeza, brazos, piernas y sombra. Zancada ligada al desplazamiento, preparación/contacto al patear, estirada del arquero y salto de festejo. Los jugadores dejan de frenar todos juntos al cambiar de microjugada.
- **Pelota:** un único muestreador conecta pie, vuelo y recepción sin saltos. Sombra sobre el césped y altura en centros/remates; la estela corta sigue la trayectoria real.
- **Cancha:** césped con franjas, arcos con red y tribunas discretas en los bordes. Todos los elementos usan las mismas coordenadas de campo.
- **Momentos:** remates y atajadas se reconocen en la acción. Al entrar un gol, red, jugadores, tribuna, marcador y cartel del equipo reaccionan juntos; el festejo permanece brevemente durante la reposición.
- **Jerarquía:** marcador arriba, cancha protagonista, relato con icono abajo. Sin controles de juego nuevos ni exigencia de lectura adicional.
- **Accesibilidad:** Reduce Motion elimina zancadas, partículas, vuelo en altura y rebotes; mantiene eventos discretos y la misma resolución. El gol nunca se anuncia antes de su entrada al arco.

**Handoff:** SwiftUI Engineer implementa la capa de presentación sobre la timeline existente; QA verifica continuidad renderizada, resultado/cierre/llave y legibilidad en iPad. No requiere nuevas reglas de producto ni persistencia.

### Afinado de carreras — 2026-09-07

Pedido explícito de Mati después de ver la iteración: carreras demasiado rápidas y trabadas. Se mantiene estructura, cámara y kits. La carrera tiene aceleración corta, crucero y frenada, con menos pasos por segundo y curvas laterales para anticipar cruces. Los jugadores de apoyo no se reorganizan a toda velocidad durante un remate. Separación ajustada a la silueta compacta, manteniendo 22 jugadores legibles. Se quitan intercambios redundantes, no goles ni remates; se usa 110 s estables en lugar de sortear velocidad dentro del rango aprobado. Gol/atajada siguen ligados al contacto y al impacto 0.78. El reloj se congela al ir al fondo y retoma sin recuperar tiempo perdido. Reduce Motion conserva sus estados discretos y 100 s. Verificación y handoff: `.project/match-running-fluidity-2026-09-07.md`.
