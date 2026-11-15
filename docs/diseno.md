# Horda Pixel — prototipo 0.1

Juego de zombis para móvil en vertical, pixel art. El nombre es provisional.

## Cómo se juega
- **Moverse:** toca en cualquier sitio y arrastra; el joystick aparece bajo el dedo. En el ordenador: WASD o flechas.
- **Disparar:** automático. El personaje apunta y dispara al zombi vivo más cercano que esté a su alcance.
- **Recargar:** automático cuando se vacía el cargador, o tras 1,2 s sin zombis cerca. En el ordenador también con R.
- **Armas:** los tres botones de abajo a la derecha (1, 2 y 3 en el teclado). Ahora están todas desbloqueadas para probarlas; más adelante se comprarán.
- **Pausa:** botón arriba a la derecha (P o Esc). Desde ahí se quita el sonido y se reinicia la partida.

## Números (src/config.js)
| | Daño | Disparos/s | Cargador | Recarga | Alcance | Notas |
|---|---|---|---|---|---|---|
| Pistola | 12 | 2,6 | 12 | 1,1 s | 110 px | 10 % crítico (×2) |
| Subfusil | 7 | 9 | 30 | 1,7 s | 95 px | más dispersión |
| Escopeta | 6 × 8 | 1,1 | 6 | 2,1 s | 72 px | empuja a los zombis |

| Zombi | Vida | Velocidad | Daño | Golpea cada |
|---|---|---|---|---|
| Normal | 36 | 20 px/s | 10 | 1,0 s |
| Corredor (desde la oleada 2) | 22 | 38 px/s | 6 | 0,7 s |

- Jugador: 100 de vida, 58 px/s. Un zombi normal solo te mata en unos 10 s; tres a la vez, en unos 3,3 s.
- Pistola contra zombi normal: 3 balas (~0,8 s). Subfusil: 6 balas (~0,6 s). Escopeta: un disparo a bocajarro.
- Oleada n: 6 + 4·(n−1) zombis. Cada oleada les da un 8 % más de vida. Hay 4 s de descanso entre oleadas.
- Cada zombi suelta de 1 a 2 monedas (el corredor, de 1 a 3) y un botiquín (+30) el 5 % de las veces.
- Prueba automática quedándose quieto: muere en la oleada 5 con la pistola y en la 6 con el subfusil o la escopeta.

## Arte
Todo se dibuja en Aseprite con `arte/dibujar.lua`. Los archivos `arte/fuentes/*.aseprite` se pueden abrir y retocar a mano.
- `arte/construir.sh`: redibuja y exporta a `assets/` (sobrescribe los .aseprite).
- `arte/construir.sh --solo-exportar`: solo exporta, para no perder retoques hechos a mano.
- `python3 arte/vista.py`: genera `docs/vistas/hojas.png` con todas las hojas ampliadas.

## Sonido
Los sonidos se sintetizan con Web Audio en `src/audio.js`, sin archivos: disparos de cada arma, recarga, impacto, gruñidos, muerte, monedas, curación y aviso de oleada.

## Ideas para siguientes versiones
Tienda de armas con las monedas, mascotas de apoyo, trajes, zombi gordo y jefes, más mapas, y empaquetarlo como app con Capacitor (Android/iOS).
