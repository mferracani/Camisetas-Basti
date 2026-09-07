# Motion natural — 2026-09-07

## Pedido y tesis visual

Mati pide una nueva mejora del motion y del diseño con `ui-art-director`: el juego todavía se percibe tosco y los movimientos deben representar mejor el fútbol real.

**Cada jugada se lee por el cuerpo: perfil, apoyo, contacto y continuación de la carrera.**

Se conserva el flujo aprobado, cámara fija, 22 jugadores, duración de 90–110 segundos, kits del catálogo, resultado determinista, accesibilidad y funcionamiento offline. Base: `36cd5b6`, que incluye los 30 clubes argentinos. No se modifica la lógica del torneo ni se publica este incremento.

## Diagnóstico

- Interpolación lineal independiente por beat: continuidad de posición, pero saltos de velocidad y dirección.
- Zancada por reloj global, no por distancia; carreras en el lugar y giros sin perfil corporal.
- Balón unido al centro del jugador; remates que aceleran durante el vuelo.
- Jugadores frontales y rígidos, sin profundidad entre brazos, piernas y rivales.
- Todo el modal se invalida a 30 Hz, mezclando dibujo con marcador y accesibilidad.

## Coreografía / contrato de presentación

| Disparador | Movimiento y causa | Final / interrupción | Reduce Motion |
|---|---|---|---|
| Carrera entre jugadas | Trayectorias cúbicas con velocidad compartida en las uniones; zancada por distancia y perfil por dirección | Frenada progresiva y pies quietos al detenerse | Posiciones discretas, sin zancada |
| Pase / remate | Perfil hacia destino, pierna de apoyo, preparación y extensión en el instante de salida; pelota desde el pie | Inercia del cuerpo y recuperación corta; vuelo con impulso inicial | Contacto y resultado discretos |
| Conducción / recepción | Pequeños toques por ciclo de carrera; recepción conectada con el mismo punto de vuelo | Control sin salto de dueño ni pelota | Pelota estable junto al jugador |
| Pelota parada | Llegada con desaceleración, pausa real y carrera corta del pateador | Barrera salta tras el contacto; impacto conserva `0.78` | Preparación y resultado legibles |
| Atajada | Flexión, impulso, extensión, caída y recuperación | Sin volver vertical de golpe al iniciar la reposición | Pose estable, sin estirada continua |
| Pausa / fondo / final | Render separado a 60 Hz sobre el mismo reloj lógico | Congela y reanuda sin acumular tiempo en segundo plano | Sin animaciones ornamentales |

Silueta más atlética y compacta, articulaciones visibles, vistas de perfil/espalda según orientación, sombras ancladas al césped y orden de profundidad por posición. El campo y el marcador siguen siendo la estructura estable. Sin cámara móvil, glow, dependencias ni efectos decorativos nuevos.

## Verificación

- **Tests:** 74 unitarios + 4 XCUITests focales, sin fallos. El flujo completo duró 114,773 s incluyendo navegación/cierre y comprobó resultado persistido. Tiro libre, penal, gol y Reduce Motion conservan el marcador. Después de afinar el pateador se repitieron los 74 unitarios y el test de tanda/cierre.
- **Performance del muestreador:** ~8 ms por 120 muestras (~0,06 ms/muestra), sin incluir Canvas/GPU. El caché se crea una vez; la zancada y orientación no dependen del número de frames dibujados. Intervalo objetivo 60 Hz, no una garantía de FPS en hardware.
- **Builds:** Debug de tests y Release para iOS Simulator correctos. Release conserva warnings de metadatos de ModuleCache de Xcode, sin error de compilación.
- **Visual:** app real en iPad Pro 13 M5 y pruebas de UI en iPad A16, horizontal. Siluetas menos cuadradas, inclinación/perfil, apoyo de pies, toques cortos, barrera y caída del arquero. Tanda final sin springs; carrera, golpe, perspectiva del balón y aterrizaje continuos.
- **Accesibilidad:** cancha decorativa para VoiceOver; marcador y relato únicos conservados; sin controles ni permisos nuevos. Reduce Motion elimina zancada, saltos, estela, giro y altura.
- **Seguridad:** diff local sin red, dependencias, datos personales ni persistencia nueva. No implica certificación legal ni autorización de publicación.

Resultados: `/private/tmp/camisetas-motion-verification.xcresult` y `/private/tmp/camisetas-motion-final.xcresult`. Logs de compilación: `/private/tmp/camisetas-motion-release-final.log`.

El ajuste final de la silueta del arquero de la tanda también pasó el XCUITest de gol/impacto/cierre: `/private/tmp/camisetas-motion-keeper-final.xcresult`. Release recompilado después del cambio.

Video real (22 s, 1280×960, exportado a 60 fps sin acelerar): `/Users/mac017/Documents/ChatGPT/Camisetas basti/build/match-natural-motion/motion-natural.mp4`. Muestra tiro libre, gol, continuidad de juego y penal dentro del partido. Captura final de la tanda: `build/match-natural-motion/tanda-final.png` en el checkout original. Los fps del archivo exportado no certifican el rendimiento del dispositivo.

## Auditoría visual `ui-art-director`

18/20 en revisión interna: producto 2, diferenciación 1, comprensión 2, jerarquía 2, narrativa 2, coherencia 2, motion causal 2, media útil 2, implementación 2, robustez 1. No se agregaron glows, cámara móvil, tarjetas ni decoración nueva. El detalle se concentra en lo que explica fútbol: cuerpos y balón. Robustez queda parcial hasta medir FPS/temperatura en el iPad físico; la simulación sigue siendo 2D estilizada, no física 3D profesional ni captura de movimiento.

## Entrega / siguiente rol

Rama `codex/feat-natural-match-motion`, worktree permanente `/Users/mac017/Documents/ChatGPT/Camisetas basti/.worktrees/natural-motion`, desde `36cd5b6`. El `AGENTS.md` local modificado del checkout original no se tocó. La carpeta `.worktrees/` se excluye sólo en `.git/info/exclude` local, sin cambiar el `.gitignore` versionado. Sin commit/push. Siguiente: revisión visual de Mati, QA en iPad físico y decisión de publicación; gates existentes reutilizados dentro del mismo alcance.

Commit sugerido: `feat: add natural player motion and grounded match animation`.
