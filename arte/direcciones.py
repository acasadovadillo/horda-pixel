"""Animación (GIF) de personajes en sus 8 direcciones, para revisarlos de un vistazo.
Uso: python3 arte/direcciones.py <salida.gif> <carpeta>:<sprite> [<carpeta>:<sprite> ...]
Cada fila es un sprite; las columnas, las direcciones n, ne, e, se, s, sw, w, nw (w, sw y nw en espejo,
como en el juego). Al jugador se le ponen encima los brazos con la pistola, girados como en el juego."""
import json, math, os, sys
from PIL import Image

K = 3                                          # aumento
FONDO = (52, 54, 61, 255)                      # asfalto
DIRS = [("n", False, -90), ("ne", False, -45), ("e", False, 0), ("se", False, 45),
        ("s", False, 90), ("se", True, 135), ("e", True, 180), ("ne", True, -135)]
ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")


def cargar(carpeta, nombre):
    d = json.load(open(os.path.join(carpeta, nombre + ".json")))
    im = Image.open(os.path.join(carpeta, nombre + ".png")).convert("RGBA")
    frames = [im.crop((f["frame"]["x"], f["frame"]["y"], f["frame"]["x"] + f["frame"]["w"], f["frame"]["y"] + f["frame"]["h"]))
              for f in d["frames"]]
    tags = {t["name"]: (t["from"], t["to"]) for t in d["meta"]["frameTags"]}
    puntos = {}
    for s in d["meta"].get("slices", []):
        n, _, i = s["name"].partition("#")
        b = s["keys"][0]["bounds"]
        puntos.setdefault(n, {})[int(i) if i else "*"] = (b["x"], b["y"])
    return frames, tags, puntos


def punto(puntos, n, i, defecto):
    p = puntos.get(n, {})
    return p.get(i, p.get("*", defecto))


def brazos():
    frames, _, puntos = cargar(ASSETS, "brazos_pistola")
    return frames[0], punto(puntos, "hombro", 0, (8, 10))


def cuadro(frames, tags, puntos, base, d, espejo, ang, k, arma):
    tag = base + "_" + d if base + "_" + d in tags else base
    a, b = tags[tag]
    i = a + k % (b - a + 1)
    im = Image.new("RGBA", (56, 48), (0, 0, 0, 0))
    cuerpo = frames[i].transpose(Image.FLIP_LEFT_RIGHT) if espejo else frames[i]
    ox, oy = 8, 6
    capa_brazos = None
    if arma:
        br, hb = arma
        h = punto(puntos, "hombro", i, (20, 13))
        hx = 39 - h[0] if espejo else h[0]
        izq = math.cos(math.radians(ang)) < 0
        b2 = br.transpose(Image.FLIP_TOP_BOTTOM) if izq else br
        hby = br.height - 1 - hb[1] if izq else hb[1]
        lienzo = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        lienzo.paste(b2, (50 - hb[0], 50 - hby))
        lienzo = lienzo.rotate(-ang, resample=Image.NEAREST, center=(50, 50))
        capa_brazos = (lienzo, (ox + hx - 50, oy + h[1] - 50))
    detras = d in ("n", "ne")
    if capa_brazos and detras: im.paste(capa_brazos[0], capa_brazos[1], capa_brazos[0])
    im.paste(cuerpo, (ox, oy), cuerpo)
    if capa_brazos and not detras: im.paste(capa_brazos[0], capa_brazos[1], capa_brazos[0])
    return im


def main():
    salida, pares = sys.argv[1], sys.argv[2:]
    filas = []
    for par in pares:
        carpeta, nombre = par.split(":")
        frames, tags, puntos = cargar(carpeta, nombre)
        base = "correr" if any(t.startswith("correr") for t in tags) else "andar"
        filas.append((frames, tags, puntos, base, brazos() if nombre == "jugador" else None))
    n = 8
    gif = []
    for k in range(n):
        hoja = Image.new("RGBA", (56 * 8, 48 * len(filas)), FONDO)
        for r, (frames, tags, puntos, base, arma) in enumerate(filas):
            for c, (d, espejo, ang) in enumerate(DIRS):
                im = cuadro(frames, tags, puntos, base, d, espejo, ang, k, arma)
                hoja.paste(im, (c * 56, r * 48), im)
        gif.append(hoja.resize((hoja.width * K, hoja.height * K), Image.NEAREST).convert("P", palette=Image.ADAPTIVE))
    gif[0].save(salida, save_all=True, append_images=gif[1:], duration=110, loop=0)
    print("GIF:", salida)


if __name__ == "__main__":
    main()
