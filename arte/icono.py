"""Genera los iconos de la app a partir de los sprites: python3 arte/icono.py"""
import os
from PIL import Image
raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

def base():
    """Icono de 64x64 dibujado en Aseprite (arte/sprites/icono.lua)."""
    return Image.open(os.path.join(raiz, "assets", "icono.png")).convert("RGBA").crop((0, 0, 64, 64))

b = base()
for n in (180, 192, 512):
    b.resize((n, n), Image.NEAREST).convert("RGB").save(os.path.join(raiz, "iconos", f"icono-v2-{n}.png"))
# Maskable: el dibujo ocupa el 70 % central
m = Image.new("RGBA", (512, 512), b.getpixel((0, b.height - 1)))
k = 358 // b.width
d = b.resize((b.width * k, b.height * k), Image.NEAREST)
m.alpha_composite(d, ((512 - d.width) // 2, (512 - d.height) // 2))
m.convert("RGB").save(os.path.join(raiz, "iconos", "icono-v2-maskable-512.png"))
print("iconos listos")
