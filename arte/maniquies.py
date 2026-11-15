"""Genera sprites de relleno (cajas de colores con las medidas del contrato) para probar el código
sin el arte definitivo: python3 arte/maniquies.py <carpeta_salida>"""
import json, os, sys
from PIL import Image, ImageDraw
aqui = os.path.dirname(os.path.abspath(__file__))
contrato = json.load(open(os.path.join(aqui, "contrato.json")))
out = sys.argv[1]
os.makedirs(out, exist_ok=True)
PUNTOS = {"pies": (20, 38), "hombro": (20, 13), "boca": (30, 9), "casquillo": (22, 8), "origen": (1, 7), "luz": (8, 6)}
COL = {"jugador": (70, 110, 150), "zombi": (110, 130, 100), "zombi_b": (90, 120, 120), "corredor": (180, 185, 170),
       "armas": (60, 65, 75), "suelo": (60, 62, 70), "coche": (130, 50, 45), "objetos": (130, 95, 55),
       "vegetacion": (50, 90, 50), "interfaz": (220, 220, 220)}
for n, c in contrato.items():
    w, h = c["w"], c["h"]
    nf = sum(c["tags"].values()) if "tags" in c else c.get("frames", 1)
    if c.get("hoja"):
        w = c["hoja_w"]
    hoja = Image.new("RGBA", (w * nf, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(hoja)
    col = COL.get(n, COL.get(c["grupo"], (150, 150, 150)))
    for i in range(nf):
        x = i * w
        if c["grupo"] in ("jugador", "zombi", "corredor"):
            d.rectangle([x + 17, 4, x + 22, 9], fill=(200, 160, 130, 255))
            d.rectangle([x + 15, 11, x + 24, 23], fill=col + (255,))
            d.rectangle([x + 16, 24, x + 19, 38 - (i % 2)], fill=(60, 55, 50, 255))
            d.rectangle([x + 20, 24, x + 23, 38 - ((i + 1) % 2)], fill=(80, 70, 60, 255))
            if n != "jugador":
                d.rectangle([x + 24, 13, x + 32, 15], fill=col + (255,))
        elif n.startswith("brazos_"):
            d.rectangle([x + 8, 9, x + 20, 11], fill=(70, 110, 150, 255))
            d.rectangle([x + 20, 8, x + 30, 10], fill=(40, 42, 50, 255))
        elif n == "suelo":
            base = 0
            for t, k in c["tags"].items():
                if base <= i < base + k:
                    cc = {"hierba": (52, 80, 40), "tierra": (89, 68, 48), "acera": (123, 123, 124),
                          "linea": (52, 54, 61), "grieta": (45, 47, 53)}.get(t, (52, 54, 61))
                    d.rectangle([x, 0, x + w - 1, h - 1], fill=cc + (255,))
                    if t == "linea":
                        d.rectangle([x + 11, 3, x + 13, 20], fill=(201, 173, 69, 255))
                    if t.startswith("bordillo"):
                        bx = x if t.endswith("_i") else x + w - 5
                        d.rectangle([bx, 0, bx + 4, h - 1], fill=(148, 148, 147, 255))
                base += k
        elif n in ("manchas", "detalles"):
            d.ellipse([x + 6, 8, x + 17, 15], fill=(82, 12, 18, 255) if n == "manchas" else (30, 30, 34, 255))
        elif n == "letra":
            for j in range(w // 6):
                d.rectangle([j * 6 + 1, 3, j * 6 + 3, 7], fill=(255, 255, 255, 255))
        else:
            d.rectangle([x + 1, 1, x + w - 2, h - 2], fill=col + (255,), outline=(20, 20, 26, 255))
    hoja.save(os.path.join(out, n + ".png"))
    frames = [{"filename": f"{n} {i}.aseprite", "frame": {"x": i * w, "y": 0, "w": w, "h": h}, "duration": 100} for i in range(nf)]
    tags, a = [], 0
    for t, k in c.get("tags", {}).items():
        tags.append({"name": t, "from": a, "to": a + k - 1, "direction": "forward"}); a += k
    slices = []
    for p in c.get("puntos", []):
        q = (8, 10) if (p == "hombro" and n.startswith("brazos_")) else PUNTOS.get(p, (w // 2, h - 2))
        slices.append({"name": p, "keys": [{"frame": 0, "bounds": {"x": q[0], "y": q[1], "w": 1, "h": 1}}]})
    json.dump({"frames": frames, "meta": {"frameTags": tags, "slices": slices}}, open(os.path.join(out, n + ".json"), "w"))
print("maniquíes en", out, len(contrato))
