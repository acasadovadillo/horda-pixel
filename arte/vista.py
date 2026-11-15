"""Vistas ampliadas de los sprites exportados, para revisarlos de un vistazo.
Uso: python3 arte/vista.py <carpeta> [nombre ...]   -> <carpeta>/vista_<nombre>.png
Cada vista enseña: los fotogramas ampliados por etiqueta, los puntos de anclaje (en magenta)
y una tira a tamaño de juego (x3) sobre asfalto, acera y hierba, con una persona de 35 px de referencia."""
import json, os, sys
from PIL import Image, ImageDraw

ANCHO_MAX = 1500
FONDOS = [(52, 54, 61), (123, 123, 124), (52, 80, 40)]      # asfalto, acera, hierba
FONDO = (70, 72, 80)
MAGENTA = (255, 0, 255, 255)
LOSETAS = ("suelo", "manchas", "detalles")


def maniqui():
    """Persona de 35 px de alto para comparar tamaños."""
    im = Image.new("RGBA", (12, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = (230, 230, 235, 255)
    d.rectangle([4, 1, 7, 6], fill=c)          # cabeza
    d.rectangle([2, 8, 9, 20], fill=c)         # tronco
    d.rectangle([2, 21, 5, 35], fill=c)        # piernas
    d.rectangle([6, 21, 9, 35], fill=c)
    return im


def ampliar(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def vista(carpeta, nombre):
    pj = os.path.join(carpeta, nombre + ".json")
    hoja = Image.open(os.path.join(carpeta, nombre + ".png")).convert("RGBA")
    d = json.load(open(pj))
    cuadros = [hoja.crop((f["frame"]["x"], f["frame"]["y"], f["frame"]["x"] + f["frame"]["w"],
                          f["frame"]["y"] + f["frame"]["h"])) for f in d["frames"]]
    w, h = cuadros[0].size
    tags = [(t["name"], t["from"], t["to"]) for t in d["meta"].get("frameTags", [])]
    if not tags:
        tags = [("", 0, len(cuadros) - 1)]
    puntos = {}
    for s in d["meta"].get("slices", []):
        b = s["keys"][0]["bounds"]
        base, _, idx = s["name"].partition("#")
        puntos.setdefault(base, {})[int(idx) if idx else None] = (b["x"], b["y"])

    filas = max(t[2] - t[1] + 1 for t in tags)
    k = max(2, min(10, ANCHO_MAX // max(1, filas * (w + 1))))
    if h * k > 560:
        k = max(2, 560 // h)
    partes = []          # (imagen, título)

    # 1. Fotogramas por etiqueta
    for nom, a, b in tags:
        n = b - a + 1
        fila = Image.new("RGBA", (n * (w * k + 4) + 4, h * k + 8), FONDO + (255,))
        dr = ImageDraw.Draw(fila)
        for i in range(n):
            x = 4 + i * (w * k + 4)
            dr.rectangle([x, 4, x + w * k - 1, 4 + h * k - 1], fill=FONDOS[0] + (255,))
            fila.alpha_composite(ampliar(cuadros[a + i], k), (x, 4))
        partes.append((fila, f"{nombre}  [{nom or 'fotogramas'}]  {a}-{b}   x{k}   lienzo {w}x{h}"))

    # 2. Puntos de anclaje sobre el primer fotograma de cada etiqueta
    if puntos:
        n = len(tags)
        fila = Image.new("RGBA", (n * (w * k + 4) + 4, h * k + 8), FONDO + (255,))
        dr = ImageDraw.Draw(fila)
        for j, (nom, a, b) in enumerate(tags):
            x0 = 4 + j * (w * k + 4)
            dr.rectangle([x0, 4, x0 + w * k - 1, 4 + h * k - 1], fill=FONDOS[0] + (255,))
            fila.alpha_composite(ampliar(cuadros[a], k), (x0, 4))
            for pn, por in puntos.items():
                p = por.get(a, por.get(None))
                if not p:
                    continue
                px, py = x0 + p[0] * k, 4 + p[1] * k
                dr.rectangle([px, py, px + k - 1, py + k - 1], outline=MAGENTA)
                dr.line([px + k // 2, py - 2 * k, px + k // 2, py - 1], fill=MAGENTA)
                dr.text((px + k + 2, py - 4), pn, fill=MAGENTA)
        partes.append((fila, "puntos de anclaje (magenta): " + ", ".join(
            f"{pn}={list(por.values())[0]}" for pn, por in puntos.items())))

    # 3. A tamaño de juego (x3) sobre los tres suelos
    k3 = 3
    muestra = [cuadros[t[1]] for t in tags][:6] if len(tags) > 1 else cuadros[:6]
    if w <= 160:
        tw = sum(m.width * k3 + 8 for m in muestra) + 12 * k3 + 24
        fila = Image.new("RGBA", (tw * 3, max(h, 36) * k3 + 12), FONDO + (255,))
        dr = ImageDraw.Draw(fila)
        for j, col in enumerate(FONDOS):
            x = j * tw
            dr.rectangle([x, 0, x + tw - 1, fila.height], fill=col + (255,))
            base = fila.height - 6
            fila.alpha_composite(ampliar(maniqui(), k3), (x + 8, base - 36 * k3))
            x += 12 * k3 + 16
            for m in muestra:
                fila.alpha_composite(ampliar(m, k3), (x, base - m.height * k3))
                x += m.width * k3 + 8
        partes.append((fila, "tamaño de juego x3 sobre asfalto, acera y hierba (figura blanca = persona de 35 px)"))

    # 4. Losetas: repetidas 3x3 para ver las juntas
    if nombre in LOSETAS:
        kk = 2
        n = len(cuadros)
        fila = Image.new("RGBA", (n * (w * 3 * kk + 6) + 6, h * 3 * kk + 12), FONDO + (255,))
        for i, c in enumerate(cuadros):
            g = ampliar(c, kk)
            for yy in range(3):
                for xx in range(3):
                    if nombre != "suelo":
                        ImageDraw.Draw(fila).rectangle(
                            [6 + i * (w * 3 * kk + 6) + xx * w * kk, 6 + yy * h * kk,
                             6 + i * (w * 3 * kk + 6) + (xx + 1) * w * kk - 1, 6 + (yy + 1) * h * kk - 1],
                            fill=FONDOS[0] + (255,))
                    fila.alpha_composite(g, (6 + i * (w * 3 * kk + 6) + xx * w * kk, 6 + yy * h * kk))
        partes.append((fila, "cada loseta repetida 3x3 (x2): no deben verse juntas ni patrones"))
    if nombre == "suelo" and len(tags) > 1:
        por = {t[0]: list(range(t[1], t[2] + 1)) for t in tags}
        cols = ["hierba", "hierba", "acera", "bordillo_i", "asfalto", "asfalto", "linea", "asfalto",
                "asfalto", "bordillo_d", "acera", "hierba", "tierra"]
        kk, rows = 3, 6
        fila = Image.new("RGBA", (len(cols) * w * kk, rows * h * kk), FONDO + (255,))
        s = 7
        for y in range(rows):
            for x, c in enumerate(cols):
                lista = por.get(c)
                if not lista:
                    continue
                s = (s * 1103515245 + 12345) % 2147483648
                i = lista[(s >> 8) % len(lista)]
                if c == "asfalto" and (s >> 4) % 9 == 0 and por.get("grieta"):
                    i = por["grieta"][(s >> 12) % len(por["grieta"])]
                if c == "linea" and y % 2:
                    i = por["asfalto"][0]
                fila.alpha_composite(ampliar(cuadros[i], kk), (x * w * kk, y * h * kk))
        partes.append((fila, "maqueta de carretera (x3): hierba, acera, bordillo, asfalto con línea, tierra"))

    # Montaje
    W = min(1560, max(760, max(p.width for p, _ in partes) + 16))
    H = 8 + sum(p.height + 22 for p, _ in partes)
    lienzo = Image.new("RGBA", (W, H), (30, 31, 36, 255))
    dr = ImageDraw.Draw(lienzo)
    y = 6
    for p, titulo in partes:
        dr.text((8, y), titulo, fill=(235, 235, 240, 255))
        y += 14
        if p.width > W - 16:
            p = p.crop((0, 0, W - 16, p.height))
        lienzo.alpha_composite(p, (8, y))
        y += p.height + 8
    salida = os.path.join(carpeta, f"vista_{nombre}.png")
    lienzo.convert("RGB").save(salida)
    print("vista:", salida, lienzo.size)


if __name__ == "__main__":
    carpeta = sys.argv[1]
    nombres = sys.argv[2:] or sorted(f[:-5] for f in os.listdir(carpeta) if f.endswith(".json"))
    for n in nombres:
        vista(carpeta, n)
