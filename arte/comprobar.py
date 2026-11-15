"""Comprueba que los sprites exportados cumplen el contrato (arte/contrato.json).
Uso: python3 arte/comprobar.py <carpeta> [nombre ...]   (sin nombres: todos los del contrato)"""
import json, os, sys
from PIL import Image
aqui = os.path.dirname(os.path.abspath(__file__))
contrato = json.load(open(os.path.join(aqui, "contrato.json")))
carpeta = sys.argv[1]
nombres = sys.argv[2:] or list(contrato)
fallos = 0
for n in nombres:
    c = contrato.get(n)
    if not c:
        print(f"AVISO {n}: no está en el contrato (¿nombre mal escrito?)"); continue
    pj, pp = os.path.join(carpeta, n + ".json"), os.path.join(carpeta, n + ".png")
    if not os.path.exists(pj) or not os.path.exists(pp):
        print(f"FALLO {n}: falta {n}.png o {n}.json"); fallos += 1; continue
    d = json.load(open(pj)); err = []
    fr = d["frames"]; w, h = fr[0]["frame"]["w"], fr[0]["frame"]["h"]
    if c.get("hoja"):
        if c.get("hoja_w") and w != c["hoja_w"]: err.append(f"la hoja mide {w} de ancho y debe medir {c['hoja_w']}")
        if h != c["h"] or w % c["w"] != 0: err.append(f"la hoja mide {w}x{h}; debe ser múltiplo de {c['w']} de ancho y {c['h']} de alto")
    elif (w, h) != (c["w"], c["h"]): err.append(f"lienzo {w}x{h}, debe ser {c['w']}x{c['h']}")
    tags = {t["name"]: t["to"] - t["from"] + 1 for t in d["meta"].get("frameTags", [])}
    if "tags" in c:
        for t, k in c["tags"].items():
            if t not in tags: err.append(f"falta la etiqueta '{t}'")
            elif tags[t] != k: err.append(f"la etiqueta '{t}' tiene {tags[t]} fotogramas, deben ser {k}")
        if len(fr) != sum(c["tags"].values()): err.append(f"{len(fr)} fotogramas, deben ser {sum(c['tags'].values())}")
    elif len(fr) != c.get("frames", 1): err.append(f"{len(fr)} fotogramas, deben ser {c.get('frames', 1)}")
    sl = {s["name"].split("#")[0] for s in d["meta"].get("slices", [])}
    for p in c.get("puntos", []):
        if p not in sl: err.append(f"falta el punto de anclaje '{p}'")
    im = Image.open(pp).convert("RGBA")
    semi = sum(1 for a in im.getchannel("A").tobytes() if 0 < a < 255)
    if semi: err.append(f"{semi} píxeles semitransparentes (el alfa debe ser 0 o 255)")
    for i, f in enumerate(fr):
        r = f["frame"]
        if not im.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"])).getbbox(): err.append(f"el fotograma {i} está vacío")
    if err:
        fallos += 1; print(f"FALLO {n}: " + "; ".join(err))
    else:
        print(f"OK    {n}")
sys.exit(1 if fallos else 0)
