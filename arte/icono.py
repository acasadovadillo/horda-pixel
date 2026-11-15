"""Genera los iconos de la app a partir de los sprites: python3 arte/icono.py"""
import os
from PIL import Image
raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
A = lambda n: Image.open(os.path.join(raiz, "assets", n + ".png")).convert("RGBA")

def base():
    """Icono de 64x64 a píxel real."""
    p = os.path.join(raiz, "assets", "icono.png")
    if os.path.exists(p):
        return Image.open(p).convert("RGBA")
    im = Image.new("RGBA", (32, 32), (26, 20, 35, 255))
    for y in range(32):                      # degradado de atardecer
        for x in range(32):
            im.putpixel((x, y), (60 - y, 30 + y // 4, 50 + y // 3, 255) if y < 22 else (42, 44, 52, 255))
    j, z = A("jugador"), A("zombi")
    im.alpha_composite(j.crop((0, 0, 16, 20)), (3, 8))
    im.alpha_composite(z.crop((0, 0, 16, 20)).transpose(Image.FLIP_LEFT_RIGHT), (15, 8))
    return im

b = base()
for n in (180, 192, 512):
    b.resize((n, n), Image.NEAREST).convert("RGB").save(os.path.join(raiz, "iconos", f"icono-{n}.png"))
# Maskable: el dibujo ocupa el 70 % central
m = Image.new("RGBA", (512, 512), b.getpixel((0, b.height - 1)))
k = 358 // b.width
d = b.resize((b.width * k, b.height * k), Image.NEAREST)
m.alpha_composite(d, ((512 - d.width) // 2, (512 - d.height) // 2))
m.convert("RGB").save(os.path.join(raiz, "iconos", "icono-maskable-512.png"))
print("iconos listos")
