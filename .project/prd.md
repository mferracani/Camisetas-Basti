# PRD — Simulacion de partidos en torneos

## Problema
La seccion de torneos hoy permite avanzar equipos tocando escudos, pero la experiencia todavia se siente demasiado manual: el equipo pasa de fase porque el usuario lo elige, no porque "jugo" un partido.

Para Basti, el torneo necesita sentirse mas vivo y futbolero. La app tiene que permitir que toque un partido, vea una simulacion clara y entretenida, entienda quien gano, y que el ganador avance solo en la llave hasta llegar a un campeon.

## Usuario y JTBD
- **Usuario principal:** Basti, jugando en iPad en modo horizontal.
- **JTBD:** Cuando estoy jugando el torneo, quiero tocar un partido y verlo jugarse solo, para sentir que el equipo gano de verdad y no que simplemente paso de fase.

## Metrica de exito
Basti puede completar un torneo simulado entero, desde octavos hasta campeon, sin errores ni fricciones. Cada torneo nuevo genera partidos, goles y resultados aleatorios distintos, sin repetir siempre la misma secuencia.

## MVP — Scope
### Incluye
- Mantener la modalidad actual: el usuario toca un equipo y lo hace avanzar manualmente.
- Agregar una segunda modalidad de torneo simulado.
- En modalidad simulada, tocar un partido abre un modal de partido.
- El modal muestra una cancha de futbol vista desde arriba.
- Se muestran jugadores como elementos simples diferenciados por colores de camiseta/equipo.
- Se muestra una pelota animada durante el partido.
- La parte superior muestra escudos, nombres abreviados y resultado en vivo.
- El partido dura entre 30 y 45 segundos.
- Durante el partido aparecen eventos de juego y goles.
- Los resultados deben sentirse plausibles: 0-0, 1-0, 2-1, 4-1, etc.
- Al terminar, se muestra resultado final y boton para cerrar.
- Al cerrar, el ganador queda cargado en la llave y avanza a la siguiente fase.
- El usuario puede seguir simulando el proximo partido disponible.
- Al completar la final, se muestra el campeon simulado.
- Cada nuevo torneo debe generar una simulacion distinta.
- Debe funcionar perfecto en iPad de 12/13 pulgadas y 10 pulgadas, en horizontal.
- Debe funcionar sin internet.

### NO incluye (explicito)
- Fisica real compleja de futbol.
- IA tactica real.
- Comentarios narrados por voz.
- Sonido obligatorio.
- Multiplayer.
- Datos reales de fixtures, ratings o estadisticas externas.
- Dependencia de APIs o servicios online.

## Restricciones
- Plataforma principal: iPad horizontal.
- Soporte visual: iPad 12/13 pulgadas y 10 pulgadas.
- Offline first: no usar internet ni servicios externos.
- Duracion real por partido: 30 a 45 segundos.
- La simulacion debe ser suficientemente variada para que torneos consecutivos no se sientan iguales.
- La nueva modalidad no debe romper la modalidad manual existente.

## Riesgos conocidos
- Si la animacion es demasiado decorativa y no comunica goles/resultado, Basti puede no entender por que avanzo un equipo.
- Si la duracion de 30-45 segundos se siente lenta, puede necesitar opcion de acelerar o saltar partido mas adelante.
- Si el algoritmo de resultados es muy random, pueden aparecer marcadores poco creibles con demasiada frecuencia.
- Si el modal no esta bien adaptado a iPad 10 pulgadas, la cancha, marcador y boton final pueden competir por espacio.
- Si no hay estados claros de partido pendiente/jugado, puede haber confusion sobre que partido toca simular despues.

## Proximo paso
Handoff a UX Designer para definir flujo, estados, estructura de pantalla, modal de partido, microinteracciones y comportamiento responsive en iPad.
