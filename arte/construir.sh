#!/bin/bash
# Dibuja el arte en Aseprite y exporta cada sprite a assets/<nombre>.png + .json
# Uso: arte/construir.sh            (todo)
#      arte/construir.sh --solo-exportar   (no redibuja; exporta los .aseprite tal cual, por si los retocaste a mano)
set -e
cd "$(dirname "$0")"
ASE="${ASEPRITE:-$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite}"
# La extensión pixellab escribe errores en modo consola; se filtran.
filtro() { grep -v "pixellab" || true; }

if [ "$1" != "--solo-exportar" ]; then
  "$ASE" -b --script-param out="$PWD/fuentes" --script dibujar.lua 2>&1 | filtro
fi

mkdir -p ../assets
for f in fuentes/*.aseprite; do
  n=$(basename "$f" .aseprite)
  "$ASE" -b "$f" --sheet "../assets/$n.png" --sheet-type horizontal \
    --data "../assets/$n.json" --format json-array --list-tags 2>&1 | filtro
done
echo "Exportados: $(ls fuentes/*.aseprite | wc -l | tr -d ' ') sprites"
