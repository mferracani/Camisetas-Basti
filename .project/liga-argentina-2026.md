# Liga Argentina 2026 en Simular Torneo

## Alcance

- Plantel: 30 clubes de Primera División 2026 según el Reglamento de Torneos LPF.
- Experiencia: eliminación directa con ronda de 32, octavos, cuartos, semifinales y final.
- Dos clubes reciben pase libre, uno por cada lado de la llave.
- Las otras ligas mantienen la llave de 16 existente.
- Todo sigue siendo local y offline.

## Clubes agregados

Aldosivi, Atlético Tucumán, Barracas Central, Central Córdoba, Defensa y Justicia,
Deportivo Riestra, Estudiantes de Río Cuarto, Gimnasia La Plata, Gimnasia de Mendoza,
Independiente Rivadavia, Instituto, Sarmiento, Tigre y Unión.

Con los 16 existentes, Argentina queda en 30 clubes y 60 camisetas estilizadas.

## Decisión de producto

Este incremento amplía la llave genérica de `SIMULAR TORNEO`; no replica las dos
zonas de 15 equipos del Apertura/Clausura 2026. Ese formato requiere fixture,
tabla, clasificación de los primeros ocho de cada zona e interzonales, por lo que
se considera una evolución separada.

## Fuente

- Reglamento oficial LPF Primera División 2026, artículos 3 y 4:
  https://www.ligaprofesional.ar/wp-content/uploads/2026/01/Reglamento-Torneos-LPF-Primera-2026-1.pdf
- Directorio oficial de clubes LPF 2026:
  https://www.ligaprofesional.ar/elpf/

Los colores y patrones de los 14 clubes nuevos son representaciones estilizadas
de su identidad tradicional; no se certifica una edición comercial específica.

## Evidencia

- `ArgentinaTournamentTests`: 3 tests focales.
- Suite unitaria: 67 tests, 0 fallos.
- `testArgentinaTournamentShowsAllThirtyLPFTeams`: aprobado en iPad (A16).
- Build Release para iOS Simulator: aprobado.
- Captura: `build/liga-argentina/ui-attachments/5611502B-C7FE-45B4-8871-81722F074196.png`.
