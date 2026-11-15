# Horda Pixel — prototipo 0.3 (horizontal)

Juego de zombis para móvil en horizontal, pixel art. Si se sujeta el móvil en vertical, pide girarlo. El nombre es provisional.

## Cómo se juega
- **Moverse:** joystick fijo abajo a la izquierda; vale tocar en cualquier punto de la mitad izquierda de la pantalla y arrastrar. En el ordenador: WASD o flechas.
- **Disparar:** automático. El personaje apunta y dispara al zombi vivo más cercano que esté a su alcance.
- **Recargar:** automático cuando se vacía el cargador, o tras 1,2 s sin zombis cerca. En el ordenador también con R.
- **Armas:** los tres botones de abajo a la derecha (1, 2 y 3 en el teclado). Ahora están todas desbloqueadas para probarlas; más adelante se comprarán.
- **Pausa:** botón arriba a la derecha (P o Esc). Desde ahí se quita el sonido y se reinicia la partida.

## Números (src/config.js)
Escala: 20 px = 1 m; una persona mide 35 px y una loseta 24 px.

| | Daño | Disparos/s | Cargador | Recarga | Alcance | Notas |
|---|---|---|---|---|---|---|
| Pistola | 12 | 2,6 | 12 | 1,1 s | 165 px | 10 % crítico (×2) |
| Subfusil | 7 | 9 | 30 | 1,7 s | 142 px | más dispersión |
| Escopeta | 6 × 8 | 1,1 | 6 | 2,1 s | 108 px | empuja a los zombis |

| Zombi | Vida | Velocidad | Daño | Golpea cada |
|---|---|---|---|---|
| Normal (3 aspectos distintos) | 36 | 30 px/s | 10 | 1,0 s |
| Corredor (desde la oleada 2) | 22 | 57 px/s | 6 | 0,7 s |

- Jugador: 100 de vida, 87 px/s. Un zombi normal solo te mata en unos 10 s; tres a la vez, en unos 3,3 s.
- Pistola contra zombi normal: 3 balas (~0,8 s). Subfusil: 6 balas (~0,6 s). Escopeta: un disparo a bocajarro.
- Oleada n: 6 + 4·(n−1) zombis. Cada oleada les da un 8 % más de vida. Hay 4 s de descanso entre oleadas.
- Cada zombi suelta de 1 a 2 monedas (el corredor, de 1 a 3) y un botiquín (+30) el 5 % de las veces.
- Prueba automática quedándose quieto: muere hacia la oleada 4-5 con la pistola, la 4 con la escopeta y la 6 con el subfusil.

## Arte
Todo se dibuja en Aseprite con scripts de Lua, un archivo por sprite en `arte/sprites/`, usando la librería `arte/lib.lua`. La guía de estilo realista está en `arte/ESTILO.md` y las medidas obligatorias de cada sprite en `arte/contrato.json`.
- `arte/construir.sh`: redibuja todo, lo exporta a `assets/` y rehace los iconos de la app.
- `arte/construir.sh --solo-exportar`: solo exporta `arte/fuentes/*.aseprite`, para no perder retoques hechos a mano en Aseprite.
- `arte/probar.sh <carpeta> <sprite.lua>`: prueba un sprite y genera una vista ampliada; `python3 arte/montaje.py <carpeta> <salida.png>` monta una pantalla de ejemplo.

## Sonido
Los sonidos se sintetizan con Web Audio en `src/audio.js`, sin archivos: disparos de cada arma, recarga, impacto, gruñidos, muerte, monedas, curación y aviso de oleada.

## Ideas para siguientes versiones
Tienda de armas con las monedas, mascotas de apoyo, trajes, zombi gordo y jefes, más mapas, y empaquetarlo como app con Capacitor (Android/iOS).
