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
- **Base fortificada** (`src/base.js`, `src/tienda.js`, números en `BASE`, `MUNICION`, `MEJORAS` y `PRECIOS` de `src/config.js`):
  - **Estructura:** abajo del mapa hay un muro de lado a lado (17 tramos de 48 px) con un portón en la carretera. El jugador cruza el portón; los zombis no.
  - **Ataques al muro:** si el jugador está al otro lado, los zombis van al tramo que tiene delante y lo golpean (10 por golpe). Vida por tramo: madera 150, chapa 300, hormigón 500. Un tramo roto deja un hueco, y los zombis cercanos van hacia él.
  - **Inicio:** empiezas dentro de la base y la ronda 1 no empieza hasta que sales por primera vez (un aviso arriba lo dice).
  - **Descanso:** al acabar cada ronda no salen zombis hasta pulsar LISTO, y las monedas del suelo vuelan hacia ti; mientras dura la ronda no desaparecen. Dentro de la base, el botón TIENDA abre la tienda con el juego parado, tanto en el descanso como en mitad de una ronda (si te quedas sin balas fuera, un aviso te dice que vuelvas).
  - **Armas:** al empezar solo tienes la Glock. La MP5 cuesta 80 y la Remington 120.
  - **Munición limitada:** se carga de la reserva y se compra por lotes. Glock: +34 por 5 (máximo 170). MP5: +60 por 9 (máximo 270). Remington: +10 por 9 (máximo 45). Sin balas en ninguna arma, sale «SIN BALAS».
  - **Curación:** +25 de vida por 6; curar del todo, 5 por cada 25 que falten; botiquín para llevar encima por 15 (+40, máximo 2, se usa tocándolo junto a la vida o con la tecla H).
  - **Mejoras por arma** (3 niveles cada una): daño (+20 %, +42 %, +70 %), cargador (Glock 22, 27 y 33; MP5 40, 50 y 60; Remington 6, 7 y 8) y recarga (−15 %, −28 %, −40 %).
  - **Defensas:** reparar muros (1 moneda por cada 20 de vida que falte); reforzar a chapa (90) o a hormigón (180); alambre de espino (70: frena al 45 % y quita 5 de vida por segundo); chaleco (40, luego 20 para rellenarlo: 50 puntos que se gastan antes que la vida).
- **Ragdoll y desmembramiento** (`src/ragdoll.js`): al morir, el fotograma que se veía se trocea en cabeza, tronco, brazos y piernas colgados de un esqueleto de palos con física. El cuerpo cae empujado por el golpe y algunos miembros se arrancan y salen volando con chorros de sangre: con pistola, un 45 % por miembro; con escopeta, un 65 %; siempre al menos uno; un crítico vuela la cabeza. Al quedar quietos, los trozos y un charco se pintan en el suelo para siempre. Al jugador le pasa lo mismo, con los brazos y el arma, y la cámara sigue su cuerpo.
- **Zombis distintos:** cada modelo (zombi, zombi_b, zombi_c, corredor) sale con una de 6 combinaciones de camiseta, pantalón y pelo (`arte/variantes.py` → `assets/variantes.json`, aplicadas al cargar en `src/sprites.js`). Los ojos se pintan en amarillo y se dibujan otra vez encima de la oscuridad, con un halo suave, para que brillen.
- **Ronda:** debajo de la vida, pintada con sangre: palotes de la 1 a la 9 (el quinto tacha a los cuatro primeros) y números de la 10 en adelante (sprites `palotes` y `cifras_sangre`, de `arte/sprites/rondas.lua`). Entre rondas parpadea en blanco. Las bajas y el resto de datos de la partida están en Pausa → Estadísticas.
- **Botiquines:** con la vida llena se quedan en el suelo (ni se atraen ni se recogen) hasta que desaparecen.
- **Cámara (zoom):** cerca, media (por defecto) o lejos, desde la pausa; se ve unos 100, 130 o 180 píxeles de alto del mundo (una persona mide 35). La interfaz no cambia de tamaño. Se guarda con la clave `horda-pixel:camara`; `?vista=N` en la dirección prueba otro valor. Solo se dispara a zombis que se ven en pantalla.
- **Idioma:** español o inglés (EE. UU.), desde la pantalla de inicio (banderas de España y EE. UU. arriba a la derecha) o desde la pausa. Se guarda en el navegador con la clave `horda-pixel:idioma`; la primera vez se usa el idioma del sistema. Los textos están en `src/idioma.js`.

- **Armas nuevas** (2026-11-15, números en `ARMAS`, `LANZABLES` y `FUEGO` de `src/config.js`):
  - **Cuerpo a cuerpo:** la primera casilla de la barra. Empiezas con el bate (aturde y empuja); el machete se compra (más rápido, crítico que decapita). Si tienes los dos, tocar otra vez la casilla cambia de uno a otro. Golpean en arco a todos los zombis a su alcance; en automático, cuando uno está cerca. Si te quedas sin balas en todas las armas, pasas solo al cuerpo a cuerpo. Mejoras: daño y velocidad.
  - **Fusil de cerrojo** (atraviesa 3 zombis), **ballesta** (virotes que atraviesan 2 y se quedan en el suelo para recogerlos; al acabar la ronda vuelan hacia ti) y **lanzallamas** (llamas que prenden fuego; el depósito es la munición).
  - **Granadas y molotov:** pestaña EXPLOSIVOS, hasta 4 de cada. Botones a la derecha (teclas G y F). Se lanzan al zombi visible con más compañía (en manual, hacia donde apuntas). La granada estalla a los 1,25 s; el molotov deja un charco de fuego 6 s. No hacen daño al jugador.
  - Zombis ardiendo: pierden 11 de vida por segundo.

- **Defensas y zonas** (2026-11-15, `src/defensas.js` y `src/supervivientes.js`; números en `TORRETAS`, `FOCOS`, `TRAMPAS`, `SUPERVIVIENTES` y `ZONAS`):
  - **Torretas** (pestaña DEFENSAS): hasta 4 sobre el muro (tramos ±3 y ±6), cada una más cara. Disparan solas a los zombis de fuera; 150 balas cada una, se rellenan en la tienda. Si su tramo cae, se apagan hasta repararlo.
  - **Focos**: cuatro en el muro; alumbran por delante y los zombis deslumbrados van al 72 % de velocidad.
  - **Trampas** (pestaña EQUIPO, botones a la izquierda, teclas Z, X y C): se dejan a tus pies, solo fuera de la base. Mina (estalla al pisarla), barril explosivo (estalla al dispararle, con el fuego o con otra explosión; deja fuego) y cepo (atrapa 3,5 s y hiere; 4 usos).
  - **Supervivientes**: desde la ronda 2, a veces aparece uno atrapado fuera pidiendo ayuda (flecha en el borde de la pantalla). Si llegas hasta él te sigue y dispara; dentro de la base sube al muro y defiende. Los zombis van a por el que tengan más cerca. Hasta 4.
  - **Zonas** (pestaña ZONAS): enfermería (te cura dentro de la base), taller (repara el 30 % del muro y recarga torretas tras cada ronda), armería (un lote de munición de cada arma tras cada ronda).
  - El chaleco pasa a la pestaña CURACIÓN.

- **Progreso entre partidas** (2026-11-15, `src/perfil.js`, `src/menus.js`, `src/mascotas.js`; se guarda en `horda-pixel:perfil`):
  - Cada partida acabada (o reiniciada a medias) se apunta: ronda, bajas, monedas, tiempo, puntería y rescatados. Se guardan las 20 últimas, los totales y las mejores marcas.
  - **Estadísticas**: desde la pausa (botón ANTERIORES) y desde la pantalla de inicio: mejores marcas y últimas partidas. Al morir se avisa de las marcas batidas y de lo desbloqueado.
  - **Personaje** (inicio, pausa y pantalla final): trajes y mascotas. Se desbloquean con logros:
    - Trajes: militar (ronda 5), motero (500 bajas en total), médico (3 rescatados), leñador (100 bajas cuerpo a cuerpo), pirómano (60 bajas con fuego o explosiones), veterano (ronda 10). Son el dibujo del jugador con otra ropa.
    - Mascotas: perro (ronda 3; muerde y frena), gato (200 bajas; recoge monedas y virotes), cuervo (10 partidas; pica a los zombis y trae monedas). No mueren.

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
