# Corrección de carreras y fluidez · 2026-09-07

## Pedido y diagnóstico

Mati: «cuando corren es muy rapido y bastante trabado». La iteración anterior no resolvió la percepción de velocidad. `debug` reproduce el problema y `ui-art-director` enfoca el ajuste en causalidad: desplazamiento, apoyo y ritmo, sin sumar decoración.

La medición previa en tres semillas (31, 73, 2026; duración 100 s) dio máximos de trayectoria de 1.030, 0.954 y 0.977 anchos de cancha por segundo. Algunas recepciones mandaban a un defensor a un punto de ataque lejano, y el siguiente pase lo devolvía a su formación. Un suavizado cúbico no limitaba esos desplazamientos; además concentraba velocidad en el centro de cada beat.

El dibujo previo ya registraba alrededor de 60 callbacks de Canvas/s: el problema no era simplemente falta de cuadros. El solver de separación aplicado después de las curvas agregaba picos de velocidad visibles; por eso la nueva prueba mide también las posiciones resueltas, no sólo la velocidad declarada de la curva.

## Decisión / implementación

- Pases a compañeros disponibles: destino próximo a la posición real del receptor, selección cercana a la línea de ataque y continuidad del portador. El receptor de un pase interceptado no corre hasta el interceptor.
- Reposiciones desde el jugador cercano al centro o la posesión real del despeje. El balón controlado respeta los mismos límites del jugador.
- Tiempo por distancia y ventanas de contacto, con una duración mínima legible. Se eliminan intercambios de relleno entre ataques. Se conservan todos los remates y el resultado generado.
- Rango aprobado conservado: reproducción normal estable de 110 s; accesibilidad 100 s y tanda 70 s. No se sortea una velocidad distinta para la misma coreografía.
- Perfil de velocidad con aceleración suave, crucero y frenada. Velocidad compartida entre beats, aceleración nula en las uniones; zancada más larga para evitar piernas frenéticas.
- Pequeñas curvas laterales anticipan cruces entre compañeros. Separación basada en la silueta compacta (0.038 anchos de cancha); el margen numérico del solver ya no provoca desplazamientos perceptibles.
- `MatchPlaybackClock`: un único CADisplayLink y tiempo monotónico para cancha, pelota, marcador y relato. Pausa explícita al ir al fondo, sin recuperar de golpe los segundos transcurridos; proxy débil y parada al cerrar. Contrato de Apple: [CADisplayLink](https://developer.apple.com/documentation/quartzcore/cadisplaylink), [timing de ProMotion](https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays).

Sin dependencias, red, permisos, persistencia ni cambios de catálogo/camisetas. El modelo sigue siendo una representación 2D estilizada, no captura de movimiento ni simulación física profesional.

## Verificación

Verificación final cerrada: 76 tests unitarios y cinco XCUITests focales (81/81, sin fallos), más compilación Release de este código. No se reutilizan cifras de QA de la iteración anterior como prueba de este cambio.

- Velocidad: 27 partidos deterministas (semillas 0–23, 31, 73, 2026), 20 jugadores de campo y 31 muestras por beat. Pico de trayectoria 0.096732 anchos/s; pico medido sobre posiciones resueltas con paso de 1/60 s: 0.107121 anchos/s. Los picos de trayectoria de las tres semillas iniciales bajan aproximadamente 90%. El test incluye un límite independiente para detectar que la separación no reintroduzca tirones.
- La curva lateral se limita sobre la geometría real; no se maquilla la velocidad que recibe la pose. Arranques, contactos y extremos se conservan.
- El muestreo cacheado de 120 cuadros demora aproximadamente 7 ms en el test de CPU, sin incluir Canvas/GPU. No se presenta esta cifra como FPS.
- Prueba de UI de pausa/reanudación: pasó. La app avanza, se mantiene cinco segundos en segundo plano y retoma sin sumar ese intervalo a la jugada.
- UI final: gol normal/Reduce Motion, pelota parada normal/Reduce Motion, tanda e impacto/cierre y partido MEX–RSA de principio a fin con resultado persistido. Este último test duró 129.501 s incluyendo navegación, 110 s de partido y cierre.
- Cadencia sin grabación, compilación ni otros tests activos: las ventanas de cuatro segundos observadas después del arranque registraron 59.0–59.7 callbacks de Canvas/s, p95 del intervalo 16.8–17.0 ms y aproximadamente 2.4–2.5 ms de CPU dentro del dibujante. La grabación simultánea a XCUITest en otro iPad degradó algunas ventanas a 53.5–56 callbacks/s; por eso se distingue la muestra sin carga adicional.

Evidencia: `/private/tmp/camisetas-running-fluidity-final.xcresult`, `/private/tmp/camisetas-running-fluidity-final.log`, `/private/tmp/camisetas-running-fluidity-release.log` y `/private/tmp/camisetas-running-fluidity-idle-render.log`. Video real a velocidad normal: `build/match-natural-motion/carreras-fluidas-2026-09-07.mp4` en el checkout original.

Pruebas nuevas: velocidad máxima en 27 partidos deterministas, velocidad de posiciones efectivamente resueltas, tiempo monotónico/pause/seek y regreso desde segundo plano en la app real. Se reejecutaron continuidad, contactos, preparación/resultado de tiros libres y penales, marcador, flujo completo y Release. Pendiente: iPad físico, percepción de Mati/Basti y gaps manuales preexistentes de VoiceOver/bracket.

Las métricas de Canvas son cadencia de callbacks y tiempo de CPU del dibujante, no medición de presentación GPU ni garantía térmica en iPad físico. Los FPS del archivo de video tampoco certifican rendimiento.

## Git / siguiente rol

Mati solicitó commit, push de todos los cambios pendientes y merge. Código de motion guardado en `35ff0eb` (`feat: improve match motion and pacing`), sobre la Liga Argentina `36cd5b6`. El cambio pendiente de `AGENTS.md` se conservó en un commit separado (`9831774`) y se integró mediante `9853908`. Ese SHA quedó publicado en `main` y en las ramas de motion/simulación, comprobado con `git ls-remote`; la rama de Liga Argentina también está publicada. No hubo conflictos ni force-push.

Revalidación previa al merge: 76 unitarios sin fallos (`/private/tmp/camisetas-premerge-20260907-unit.xcresult`) y build Release para Simulator correcto (`/private/tmp/camisetas-premerge-20260907-release.log`). El merge sólo añadió `AGENTS.md` al código probado; los cinco XCUITests citados arriba corresponden a la verificación completa anterior de ese mismo código, no a una nueva ejecución durante la integración.

Siguiente rol: QA en iPad físico y revisión perceptual con Mati/Basti antes de distribuir. No se archivó ni subió un build a TestFlight. El estado vigente y las actualizaciones documentales posteriores al merge se registran en `.project/state.md`.

## Revisión `ui-art-director`

17/20 interna: producto 2, diferenciación 1, comprensión 2, jerarquía 2, narrativa 2, coherencia 2, motion 1, media útil 2, implementación 2, robustez 1. Sin ceros críticos. La decisión visual se concentra en desplazamiento y contacto, sin más decoración. Motion y robustez quedan parciales por los límites de la representación 2D y la validación pendiente en dispositivo/personas; esta revisión no es aprobación del usuario ni una garantía de realismo físico.
