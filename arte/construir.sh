#!/bin/bash
# Dibuja todo el arte en Aseprite (arte/sprites/*.lua) y lo exporta a assets/<nombre>.png + .json
# Uso: arte/construir.sh                  (redibuja todo y exporta)
#      arte/construir.sh --solo-exportar  (no redibuja: exporta arte/fuentes/*.aseprite tal cual,
#                                          por si los has retocado a mano en Aseprite)
set -e
cd "$(dirname "$0")"
ARTE="$PWD"
ASE="${ASEPRITE:-$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite}"
# La extensión pixellab escribe errores en modo consola; se filtran.
filtro() { grep -v "pixellab" || true; }
mkdir -p fuentes ../assets

if [ "$1" != "--solo-exportar" ]; then
  for lua in sprites/*.lua; do
    salida=$(nice -n 10 "$ASE" -b --script-param lib="$ARTE/lib.lua" --script-param out="$ARTE/fuentes" --script "$lua" 2>&1 | filtro)
    echo "$salida"
    if echo "$salida" | grep -q -E "\.lua:[0-9]+:"; then echo "ERROR en $lua" >&2; exit 1; fi
  done
fi

for f in fuentes/*.aseprite; do
  n=$(basename "$f" .aseprite)
  nice -n 10 "$ASE" -b "$f" --sheet "../assets/$n.png" --sheet-type horizontal \
    --data "../assets/$n.json" --format json-array --list-tags --list-slices 2>&1 | filtro
done
python3 comprobar.py ../assets
python3 icono.py
echo "Exportados: $(ls fuentes/*.aseprite | wc -l | tr -d ' ') sprites"
