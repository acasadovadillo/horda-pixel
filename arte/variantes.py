"""Variantes de color de los zombis: otra camiseta, otro pantalón, otro pelo.
Uso: python3 arte/variantes.py   (lee assets/<zombi>.png y escribe assets/variantes.json)

Para cada zombi se buscan los colores de su ropa y su pelo (los de sus rampas y los tonos intermedios
que salen al sombrear, que se asignan a la rampa más parecida) y se calcula, para cada variante,
el color nuevo de cada uno: mismo brillo relativo dentro de la rampa, pero con la rampa de destino.
El juego (src/sprites.js) aplica estos cambios al cargar. También se apunta el color de los ojos,
que el juego pinta en amarillo y hace brillar en la oscuridad."""
import json, os, re
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def rampas_lib():
    txt = open(os.path.join(RAIZ, "arte", "lib.lua")).read()
    return {m.group(1): re.findall(r'"([0-9a-f]{6})"', m.group(2))
            for m in re.finditer(r"^\s*(\w+)\s*=\s*\{([^}]*)\}", txt, re.M)}


R = rampas_lib()
# Rampas propias de algunos sprites (definidas en su .lua).
R["mostaza"] = ["33290f", "54441c", "78632c", "9c8444", "b39c5a"]
R["tirantes"] = ["2e2a21", "4a4535", "686049", "877d61", "a39878"]
R["pantalon_negro"] = ["17171c", "25252c", "35353e", "4a4954"]

# Rampas de destino (de oscuro a claro, apagadas y sucias como el resto de la paleta).
CAMISAS = {
    "granate": R["ropa_a"], "gris_azul": R["ropa_b"], "mostaza": R["ropa_c"],
    "oliva": ["2a2e1a", "434a2a", "5f6a3c", "7d8a52"],
    "blanco_sucio": ["5c5a52", "85837a", "aeab9f", "d1cec0"],
    "azul_marino": ["1a2333", "2a3a52", "3e5573", "587494"],
    "rojo": ["3a1210", "62201c", "8a3229", "a94a3b"],
    "negro": ["141317", "222127", "33323a", "4a4952"],
    "marron": ["2c1f15", "47331f", "664a2e", "85643f"],
    "verde_hospital": ["23332f", "365049", "4d6d64", "6b8c82"],
    "morado": ["2a1d2e", "433048", "5e4563", "7a5e7e"],
}
PANTALONES = {
    "vaquero": R["vaquero"], "negro": R["pantalon_negro"], "caqui": R["caqui"],
    "gris": ["2b2c2f", "414348", "5a5d62", "777a7e"],
    "marron": ["2a2018", "40301f", "594430", "765c40"],
    "militar": ["22281a", "343d26", "4a5636", "637048"],
    "vaquero_claro": ["2a3548", "3f5068", "5a6f8c", "7d92ad"],
}
PELOS = {
    "castano": R["pelo"],
    "negro": ["0f0e10", "1c1a1d", "2c2a2e", "3e3b40"],
    "rubio": ["4a3a1e", "6e5a30", "917a45", "b09a5e"],
    "pelirrojo": ["3d1a10", "63301c", "8a4a2a", "a8663d"],
    "canoso": ["4a4a48", "6e6e6a", "93938d", "b3b2aa"],
}
DESTINOS = {"camisa": CAMISAS, "pantalon": PANTALONES, "pelo": PELOS}

# Por zombi: de qué rampa sale cada prenda, el color de los ojos, y sus variantes
# (la primera, vacía, es el original). Combinaciones distintas para que no se repitan entre zombis.
ZOMBIS = {
    "zombi": {
        "grupos": {"camisa": "ropa_a", "pantalon": "vaquero", "pelo": "pelo"}, "ojo": "c3c8ad",
        "variantes": [
            {},
            {"camisa": "blanco_sucio", "pantalon": "gris", "pelo": "negro"},
            {"camisa": "azul_marino", "pantalon": "caqui", "pelo": "rubio"},
            {"camisa": "oliva", "pantalon": "negro", "pelo": "canoso"},
            {"camisa": "rojo", "pantalon": "vaquero_claro", "pelo": "pelirrojo"},
            {"camisa": "verde_hospital", "pantalon": "verde_hospital_p", "pelo": "negro"},
        ],
    },
    "zombi_b": {
        "grupos": {"camisa": "mostaza", "pelo": "pelo"}, "ojo": "c4c8ba",
        "variantes": [
            {},
            {"camisa": "gris_azul", "pelo": "negro"},
            {"camisa": "morado", "pelo": "rubio"},
            {"camisa": "blanco_sucio", "pelo": "pelirrojo"},
            {"camisa": "rojo", "pelo": "canoso"},
            {"camisa": "marron", "pelo": "negro"},
        ],
    },
    "zombi_c": {
        "grupos": {"camisa": "ropa_a", "pantalon": "vaquero", "pelo": "pelo"}, "ojo": "c4c8ba",
        "variantes": [
            {"camisa": "gris_azul", "pantalon": "negro"},
            {"camisa": "mostaza", "pantalon": "marron", "pelo": "negro"},
            {"camisa": "negro", "pantalon": "vaquero", "pelo": "rubio"},
            {"camisa": "blanco_sucio", "pantalon": "militar", "pelo": "canoso"},
            {"camisa": "azul_marino", "pantalon": "gris", "pelo": "pelirrojo"},
            {"camisa": "morado", "pantalon": "caqui"},
        ],
    },
    "corredor": {
        "grupos": {"camisa": "tirantes", "pantalon": "pantalon_negro", "pelo": "pelo"}, "ojo": "d6d9c6",
        "variantes": [
            {},
            {"camisa": "rojo", "pantalon": "vaquero", "pelo": "negro"},
            {"camisa": "gris_azul", "pantalon": "caqui", "pelo": "rubio"},
            {"camisa": "verde_hospital", "pantalon": "gris", "pelo": "pelirrojo"},
            {"camisa": "negro", "pantalon": "militar", "pelo": "canoso"},
            {"camisa": "mostaza", "pantalon": "vaquero_claro"},
        ],
    },
}
PANTALONES["verde_hospital_p"] = CAMISAS["verde_hospital"]   # pijama de hospital completo

# Rampas que NO son ropa ni pelo: sirven para no confundir un tono de piel con uno de camiseta.
OTRAS = ["tinta", "piel", "zombi", "palido", "carne", "sangre", "cuero", "tela"]


def rgb(h): return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
def hexa(c): return "%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)
def luz(c): return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
def dist(a, b): return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def en_rampa(rampa, t):
    """Color de la rampa en la posición t (0 = más oscuro, 1 = más claro), interpolando."""
    cs = [rgb(h) for h in rampa]
    t = max(0.0, min(1.0, t)) * (len(cs) - 1)
    i = min(int(t), len(cs) - 2)
    f = t - i
    return tuple(a + (b - a) * f for a, b in zip(cs[i], cs[i + 1]))


def main():
    salida = {}
    for nombre, cfg in ZOMBIS.items():
        im = Image.open(os.path.join(RAIZ, "assets", nombre + ".png")).convert("RGBA")
        colores = sorted({"%02x%02x%02x" % p[:3] for p in im.getdata() if p[3]})
        # Cada color, a la rampa conocida más cercana (ropa, pelo u otra cosa).
        candidatos = [(g, h) for g, r in cfg["grupos"].items() for h in R[r]]
        candidatos += [("otra", h) for r in OTRAS for h in R[r]]
        asignado = {}
        for c in colores:
            if c == cfg["ojo"]: continue
            g, h = min(candidatos, key=lambda gh: dist(rgb(c), rgb(gh[1])))
            if g != "otra" and dist(rgb(c), rgb(h)) < 34: asignado[c] = g
        variantes = []
        for v in cfg["variantes"]:
            cambios = {}
            for c, g in asignado.items():
                if g not in v: continue
                base = [rgb(h) for h in R[cfg["grupos"][g]]]
                lo, hi = luz(base[0]), luz(base[-1])
                t = (luz(rgb(c)) - lo) / (hi - lo) if hi > lo else 0.5
                cambios[c] = hexa(en_rampa(DESTINOS[g][v[g]], t))
            variantes.append(cambios)
        salida[nombre] = {"ojo": cfg["ojo"], "variantes": variantes}
        print(f"{nombre}: {len(asignado)} colores de ropa/pelo, {len(variantes)} variantes")
    json.dump(salida, open(os.path.join(RAIZ, "assets", "variantes.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
