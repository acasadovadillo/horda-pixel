"""Maqueta de una pantalla del juego con los sprites exportados, para juzgarlos en conjunto.
Uso: python3 arte/montaje.py <carpeta_con_png_y_json> <salida.png>
Los sprites que falten se dibujan como un recuadro magenta con su nombre."""
import json, math, os, sys
from PIL import Image, ImageDraw

carpeta, salida = sys.argv[1], sys.argv[2]
K = 3
W, H, T = 384, 500, 24
contrato = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "contrato.json")))
cache = {}


def sprite(n):
    if n in cache:
        return cache[n]
    pj, pp = os.path.join(carpeta, n + ".json"), os.path.join(carpeta, n + ".png")
    if not (os.path.exists(pj) and os.path.exists(pp)):
        cache[n] = None
        return None
    d = json.load(open(pj))
    hoja = Image.open(pp).convert("RGBA")
    fr = [hoja.crop((f["frame"]["x"], f["frame"]["y"], f["frame"]["x"] + f["frame"]["w"],
                     f["frame"]["y"] + f["frame"]["h"])) for f in d["frames"]]
    tags = {t["name"]: (t["from"], t["to"]) for t in d["meta"].get("frameTags", [])}
    pts = {}
    for s in d["meta"].get("slices", []):
        b = s["keys"][0]["bounds"]
        base, _, idx = s["name"].partition("#")
        pts.setdefault(base, {})[int(idx) if idx else None] = (b["x"], b["y"])
    cache[n] = {"fr": fr, "tags": tags, "pts": pts}
    return cache[n]


def punto(s, nombre, i, defecto):
    por = s["pts"].get(nombre)
    if not por:
        return defecto
    return por.get(i, por.get(None, defecto))


esc = Image.new("RGBA", (W, H), (30, 31, 36, 255))
dr = ImageDraw.Draw(esc)


def falta(n, x, y):
    c = contrato.get(n, {"w": 20, "h": 20})
    dr.rectangle([x - c["w"] // 2, y - c["h"], x + c["w"] // 2, y], outline=(255, 0, 255, 255))
    dr.text((x - c["w"] // 2 + 2, y - c["h"] + 2), n[:6], fill=(255, 0, 255, 255))


# ---------------------------------------------------------------- suelo
su = sprite("suelo")
cols = ["hierba"] * 4 + ["acera", "bordillo_i"] + ["asfalto"] * 2 + ["linea"] + ["asfalto"] * 2 + ["bordillo_d", "acera"] + ["hierba"] * 3
s = 11
if su:
    for ty in range(H // T + 1):
        for tx, c in enumerate(cols):
            s = (s * 1103515245 + 12345) % 2147483648
            r = (s >> 8)
            tag = c
            if c == "linea" and ty % 2:
                tag = "asfalto"
            if c == "asfalto" and r % 11 == 0:
                tag = "grieta"
            if c == "hierba" and r % 13 == 0:
                tag = "tierra"
            if tag not in su["tags"]:
                continue
            a, b = su["tags"][tag]
            esc.alpha_composite(su["fr"][a + (r >> 4) % (b - a + 1)], (tx * T, ty * T))
for n, f, x, y in [("detalles", 4, 190, 60), ("detalles", 2, 215, 250), ("detalles", 3, 160, 330), ("detalles", 0, 240, 150),
                   ("detalles", 1, 60, 200), ("detalles", 5, 250, 400), ("detalles", 6, 170, 120), ("detalles", 7, 230, 300),
                   ("manchas", 0, 200, 215), ("manchas", 1, 165, 235), ("manchas", 2, 225, 190), ("manchas", 3, 180, 280)]:
    sp = sprite(n)
    if sp and f < len(sp["fr"]):
        esc.alpha_composite(sp["fr"][f], (x - 12, y - 12))

# ---------------------------------------------------------------- cosas de pie (ordenadas por y)
cosas = []


def objeto(n, f, x, y):
    cosas.append((y, "obj", n, f, x, y, None))


def persona(n, tag, k, x, y, izq=False, arma=None, ang=0.0):
    cosas.append((y, "per", n, (tag, k), x, y, (izq, arma, ang)))


for a in [("arbol", 0, 40, 90), ("arbol", 1, 350, 140), ("arbol", 2, 30, 300), ("arbol", 0, 345, 380),
          ("arbusto", 0, 70, 150), ("arbusto", 1, 330, 260), ("farola", 0, 108, 130), ("farola", 1, 300, 330),
          ("coche", 0, 165, 120), ("coche", 1, 255, 300), ("coche", 2, 170, 470),
          ("barril", 0, 215, 110), ("barril", 1, 135, 300), ("caja", 0, 240, 95), ("caja", 1, 150, 330),
          ("sacos", 0, 172, 400), ("sacos", 0, 268, 400), ("hoguera", 0, 85, 440), ("cono", 0, 200, 330),
          ("neumaticos", 0, 290, 200), ("contenedor", 0, 110, 230), ("barrera", 0, 215, 55)]:
    objeto(*a)

persona("zombi", "andar", 0, 150, 190)
persona("zombi", "andar", 3, 210, 150, True)
persona("zombi", "atacar", 1, 185, 262)
persona("zombi_b", "andar", 2, 250, 215, True)
persona("zombi_b", "andar", 5, 135, 250)
persona("corredor", "andar", 1, 235, 255, True)
persona("corredor", "andar", 4, 120, 165)
persona("zombi", "morir", 5, 275, 250)
persona("zombi_b", "morir", 5, 150, 290)
persona("corredor", "morir", 5, 240, 180)
persona("jugador", "quieto", 0, 205, 270, True, "brazos_pistola", math.radians(-160))
persona("jugador", "correr", 2, 160, 440, False, "brazos_subfusil", math.radians(-35))
persona("jugador", "correr", 5, 225, 445, False, "brazos_escopeta", math.radians(0))
persona("jugador", "quieto", 1, 270, 448, True, "brazos_escopeta", math.radians(-110))
persona("jugador", "morir", 5, 300, 470)


def sombra(x, y, rx):
    capa = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(capa).ellipse([x - rx, y - rx * 0.4, x + rx, y + rx * 0.4], fill=(10, 8, 16, 90))
    esc.alpha_composite(capa)


def girado(img, pivote, ang, espejo_v):
    """Gira img alrededor de pivote (x, y) el ángulo ang (radianes, sentido horario en pantalla)."""
    R = max(img.width, img.height) + 4
    lienzo = Image.new("RGBA", (2 * R, 2 * R), (0, 0, 0, 0))
    src = img
    py = pivote[1]
    if espejo_v:
        src = img.transpose(Image.FLIP_TOP_BOTTOM)
        py = img.height - 1 - pivote[1]
    lienzo.alpha_composite(src, (R - pivote[0], R - py))
    return lienzo.rotate(-math.degrees(ang), resample=Image.NEAREST, center=(R + 0.5, R + 0.5)), R


for y, tipo, n, f, x, yy, extra in sorted(cosas, key=lambda c: c[0]):
    sp = sprite(n)
    if not sp:
        falta(n, x, yy)
        continue
    if tipo == "obj":
        if f >= len(sp["fr"]):
            f = 0
        im = sp["fr"][f]
        b = punto(sp, "base", f, (im.width // 2, im.height - 2))
        if n in ("barril", "hoguera", "neumaticos", "cono"):
            sombra(x, yy, 8)
        esc.alpha_composite(im, (x - b[0], yy - b[1]))
    else:
        tag, k = f
        izq, arma, ang = extra
        if tag not in sp["tags"]:
            falta(n, x, yy)
            continue
        i = sp["tags"][tag][0] + k
        im = sp["fr"][i]
        pies = punto(sp, "pies", i, (20, 38))
        if tag != "morir":
            sombra(x, yy, 8)
        if izq:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
            pies = (im.width - 1 - pies[0], pies[1])
        ox, oy = x - pies[0], yy - pies[1]
        esc.alpha_composite(im, (ox, oy))
        if arma:
            br = sprite(arma)
            if not br:
                falta(arma, x + 20, yy - 20)
                continue
            h = punto(sp, "hombro", i, (20, 13))
            if izq:
                h = (im.width - 1 - h[0], h[1])
            ai = br["tags"].get("apuntar", (0, 0))[0]
            g, R = girado(br["fr"][ai], punto(br, "hombro", ai, (8, 10)), ang, math.cos(ang) < 0)
            esc.alpha_composite(g, (ox + h[0] - R, oy + h[1] - R))

# ---------------------------------------------------------------- interfaz de muestra
for n, f, x, y in [("corazon", 0, 6, 6), ("moneda", 0, 350, 6), ("botiquin", 0, 195, 300), ("moneda", 0, 215, 240),
                   ("moneda", 2, 228, 236), ("pistola", 0, 250, 478), ("subfusil", 0, 290, 478), ("escopeta", 0, 330, 478),
                   ("joystick", 0, 20, 440)]:
    sp = sprite(n)
    if sp and f < len(sp["fr"]):
        esc.alpha_composite(sp["fr"][f], (x, y))
le = sprite("letra")
ORDEN = list("ABCDEFGHIJKLMNÑOPQRSTUVWXYZÁÉÍÓÚÜ0123456789.,:;!¡?¿+-×/%()'\" ")
if le:
    for j, ch in enumerate("OLEADA 3   BAJAS 27   ¡CUIDADO!"):
        if ch in ORDEN:
            i = ORDEN.index(ch)
            esc.alpha_composite(le["fr"][0].crop((i * 6, 0, i * 6 + 6, 10)), (24 + j * 6, 6))

# ---------------------------------------------------------------- jugador armado, ampliado
jg = sprite("jugador")
if jg:
    KB, CW, CH = 5, 76, 64
    armas = ["brazos_pistola", "brazos_subfusil", "brazos_escopeta"]
    angs = [0, -40, 40, -90, 180, -140]
    hoja = Image.new("RGBA", (CW * len(angs), CH * len(armas)), (52, 54, 61, 255))
    for r, an in enumerate(armas):
        br = sprite(an)
        for c, deg in enumerate(angs):
            ang = math.radians(deg)
            izq = math.cos(ang) < 0
            tag = "correr" if c % 2 else "quieto"
            i = jg["tags"].get(tag, (0, 0))[0] + (2 if tag == "correr" else 0)
            im = jg["fr"][i]
            h = punto(jg, "hombro", i, (20, 13))
            if izq:
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
                h = (im.width - 1 - h[0], h[1])
            ox, oy = c * CW + 18, r * CH + 16
            hoja.alpha_composite(im, (ox, oy))
            if br:
                ai = br["tags"].get("apuntar", (0, 0))[0]
                g, R = girado(br["fr"][ai], punto(br, "hombro", ai, (8, 10)), ang, izq)
                hoja.alpha_composite(g, (ox + h[0] - R, oy + h[1] - R))
    p2 = salida.replace(".png", "_armado.png")
    hoja.resize((hoja.width * KB, hoja.height * KB), Image.NEAREST).convert("RGB").save(p2)
    print("jugador armado:", p2, "(filas: pistola, subfusil, escopeta; columnas: 0, -40, 40, -90, 180 y -140 grados)")

esc.resize((W * K, H * K), Image.NEAREST).convert("RGB").save(salida)
print("montaje:", salida, (W * K, H * K))
