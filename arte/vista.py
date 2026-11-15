"""Junta las hojas exportadas en una imagen ampliada para revisarlas: python3 arte/vista.py [salida.png] [escala]"""
import sys, os
from PIL import Image
base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
out = sys.argv[1] if len(sys.argv) > 1 else "docs/vistas/hojas.png"
k = int(sys.argv[2]) if len(sys.argv) > 2 else 5
orden = ["jugador","zombi","corredor","pistola","subfusil","escopeta","fogonazo","moneda","botiquin","corazon",
         "suelo","manchas","coche","barril","caja","sacos","arbol","arbusto","farola","hoguera","joystick","letra"]
ims = [Image.open(os.path.join(base, n + ".png")).convert("RGBA") for n in orden]
W = 1400; x = y = 8; fila = 0; pos = []
for im in ims:
    w, h = im.width * k, im.height * k
    if x + w > W: x = 8; y += fila + 10; fila = 0
    pos.append((x, y)); x += w + 10; fila = max(fila, h)
H = y + fila + 8
hoja = Image.new("RGBA", (W, H), (120, 128, 110, 255))
for im, p in zip(ims, pos):
    hoja.alpha_composite(im.resize((im.width * k, im.height * k), Image.NEAREST), p)
hoja.convert("RGB").save(out)
print(out, hoja.size)
