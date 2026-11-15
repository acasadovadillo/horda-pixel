#!/bin/bash
# Ejecuta uno o varios archivos de sprites en Aseprite, exporta las hojas y genera vistas ampliadas.
# Uso: arte/probar.sh <carpeta_salida> <archivo.lua> [<archivo.lua> ...]
# Deja en <carpeta_salida>: <nombre>.aseprite, <nombre>.png, <nombre>.json y vista_<nombre>.png
set -e
ARTE="$(cd "$(dirname "$0")" && pwd)"
ASE="${ASEPRITE:-$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite}"
filtro() { grep -v "pixellab" || true; }
out="$1"; shift
mkdir -p "$out"; out="$(cd "$out" && pwd)"
nuevos=()
for lua in "$@"; do
  marca="$out/.marca"; touch "$marca"; sleep 0.05
  salida=$(nice -n 10 "$ASE" -b --script-param lib="$ARTE/lib.lua" --script-param out="$out" --script "$lua" 2>&1 | filtro)
  echo "$salida"
  if echo "$salida" | grep -q -E "\.lua:[0-9]+:"; then echo "ERROR en $lua" >&2; exit 1; fi
  while IFS= read -r f; do nuevos+=("$f"); done < <(find "$out" -maxdepth 1 -name "*.aseprite" -newer "$marca")
done
rm -f "$out/.marca"
nombres=()
for f in "${nuevos[@]}"; do
  n=$(basename "$f" .aseprite)
  nice -n 10 "$ASE" -b "$f" --sheet "$out/$n.png" --sheet-type horizontal \
    --data "$out/$n.json" --format json-array --list-tags --list-slices 2>&1 | filtro
  nombres+=("$n")
done
if [ ${#nombres[@]} -eq 0 ]; then echo "No se generó ningún sprite" >&2; exit 1; fi
python3 "$ARTE/vista.py" "$out" "${nombres[@]}"
python3 "$ARTE/comprobar.py" "$out" "${nombres[@]}"
