# Horda Pixel

Juego de zombis en pixel art para móvil (prototipo). Se juega con el móvil en horizontal: te mueves con el joystick de abajo a la izquierda y el personaje dispara solo al zombi más cercano.

**Jugar:** https://acasadovadillo.github.io/horda-pixel/

Para instalarlo como app: abre el enlace en el móvil y elige *Añadir a pantalla de inicio* (Safari: botón Compartir; Chrome: menú ⋮).

## Desarrollo
- `python3 servidor.py 8140` y abre http://localhost:8140 (con `--red` se puede abrir desde el móvil en la misma wifi).
- Todo el arte se dibuja en Aseprite con scripts de Lua (`arte/`); `arte/construir.sh` lo exporta a `assets/`.
- Los números del juego están en `src/config.js` y explicados en `docs/diseno.md`.
