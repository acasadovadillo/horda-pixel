# Horda Pixel — prototipo 0.4

Juego de zombis para móvil en horizontal, pixel art. Si se sujeta el móvil en vertical, pide girarlo. El nombre es provisional.

## Cómo se juega
- **Moverse:** joystick fijo abajo a la izquierda; vale tocar en cualquier punto de la mitad izquierda de la pantalla y arrastrar. En el ordenador: WASD o flechas.
- **Disparar:** automático. El personaje apunta y dispara al zombi vivo más cercano que esté a su alcance.
- **Recargar:** automático cuando se vacía el cargador, o tras 1,2 s sin zombis cerca. En el ordenador también con R.
- **Armas:** los tres botones de abajo a la derecha (1, 2 y 3 en el teclado). Ahora están todas desbloqueadas para probarlas; más adelante se comprarán.
- **Pausa:** botón arriba a la derecha (P o Esc). Desde ahí se quita el sonido, se cambia el idioma y se reinicia la partida.
- **Disparo:** automático (al zombi visible más cercano) o manual, desde la pausa. En manual aparece un joystick de apuntar abajo a la derecha: mientras se arrastra, el personaje apunta en esa dirección (360°) y dispara solo; al soltar, deja de disparar. Las armas pasan abajo al centro. En el ordenador, I J K L. Clave `horda-pixel:disparo`.
- **Direcciones:** jugador y zombis miran en 8 direcciones (se dibujan s, se, e, ne y n; el resto en espejo). Con el arma apuntando hacia arriba, los brazos van detrás del cuerpo.
- **Cámara (zoom):** cerca, media (por defecto) o lejos, desde la pausa; se ve unos 100, 130 o 180 píxeles de alto del mundo (una persona mide 35). La interfaz no cambia de tamaño. Se guarda con la clave `horda-pixel:camara`; `?vista=N` en la dirección prueba otro valor. Solo se dispara a zombis que se ven en pantalla.
- **Idioma:** español o inglés (EE. UU.), desde la pantalla de inicio (banderas de España y EE. UU. arriba a la derecha) o desde la pausa. Se guarda en el navegador con la clave `horda-pixel:idioma`; la primera vez se usa el idioma del sistema. Los textos están en `src/idioma.js`.

## Números (src/config.js)
Escala: 20 px = 1 m; una persona mide 35 px y una loseta 24 px.

| | Daño | Disparos/s | Cargador | Recarga | Alcance | Notas |
|---|---|---|---|---|---|---|
| Glock 17 (pistola) | 12 | 2,6 | 17 | 1,4 s | 165 px | 10 % crítico (×2) |
| MP5 (subfusil) | 7 | 9 | 30 | 1,7 s | 142 px | más dispersión |
| Remington 870 (escopeta) | 6 × 8 | 1,1 | 4+1 | 0,5 s por cartucho | 108 px | empuja a los zombis |

| Zombi | Vida | Velocidad | Daño | Golpea cada |
|---|---|---|---|---|
| Normal (3 aspectos distintos) | 36 | 30 px/s | 10 | 1,0 s |
| Corredor (desde la oleada 2) | 22 | 57 px/s | 6 | 0,7 s |

- Jugador: 100 de vida, 87 px/s. Un zombi normal solo te mata en unos 10 s; tres a la vez, en unos 3,3 s.
- La escopeta se recarga cartucho a cartucho y se puede interrumpir para disparar; si la recámara quedó vacía, al final monta la corredera (0,45 s).
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
- **Armas:** grabaciones reales de Freesound con licencia CC0 (Glock, MP5A3 y Remington 870): disparo, recarga por pasos (cargador fuera, dentro y corredera en la Glock) y corredera de la Remington tras cada disparo. Créditos y origen en `sonido/CREDITOS.md`; los recortes salen de `sonido/recortar.py` a `assets/sonido/`.
- **Resto:** impactos, gruñidos, monedas, curación y aviso de oleada se sintetizan con Web Audio en `src/audio.js`, que también hace de respaldo si una grabación no carga.

## Ideas para siguientes versiones
Tienda de armas con las monedas, mascotas de apoyo, trajes, zombi gordo y jefes, más mapas, y empaquetarlo como app con Capacitor (Android/iOS).
