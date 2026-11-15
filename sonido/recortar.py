"""Recorta las grabaciones originales (sonido/originales, de Freesound, CC0) en sonidos cortos para el juego
y los guarda en assets/sonido/*.m4a.  Uso: python3 sonido/recortar.py   (necesita afconvert, de macOS)"""
import os, subprocess, wave
import numpy as np

AQUI = os.path.dirname(os.path.abspath(__file__))
ORIG = os.path.join(AQUI, "originales")
SALIDA = os.path.join(AQUI, "..", "assets", "sonido")
TMP = os.path.join(AQUI, "tmp")

# nombre: (archivo original, inicio s, fin s, fundido de salida s)
CORTES = {
    "glock_disparo":          ("glock_disparo", 0.00, 0.85, 0.35),
    "glock_cargador_fuera":   ("glock_cargador", 3.95, 4.35, 0.10),
    "glock_cargador_dentro":  ("glock_cargador", 8.66, 9.05, 0.10),
    "glock_corredera":        ("glock_corredera", 11.82, 12.38, 0.10),
    "mp5_disparo_1":          ("mp5_disparo", 0.022, 0.118, 0.025),
    "mp5_disparo_2":          ("mp5_disparo", 0.112, 0.208, 0.025),
    "mp5_disparo_3":          ("mp5_disparo", 0.202, 0.298, 0.025),
    "mp5_recarga":            ("mp5_recarga", 0.00, 1.47, 0.08),
    "remington_disparo":      ("remington_disparo", 0.00, 0.92, 0.35),
    "remington_corredera":    ("remington_corredera", 23.02, 24.02, 0.10),       # lenta, al acabar de recargar
    "remington_cartucho_1":   ("escopeta_cargar", 1.10, 1.42, 0.08),   # cartuchos entrando en el tubo
    "remington_cartucho_2":   ("escopeta_cargar", 6.67, 6.94, 0.08),
    "remington_cartucho_3":   ("escopeta_cargar", 9.03, 9.30, 0.08),
    "remington_corredera_rapida": ("remington_corredera", 12.46, 12.95, 0.10),  # rápida, tras cada disparo
}

def leer(nombre):
    w = wave.open(os.path.join(ORIG, nombre + ".wav"))
    sr, ch = w.getframerate(), w.getnchannels()
    a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768
    return (a.reshape(-1, ch).mean(axis=1) if ch > 1 else a), sr

os.makedirs(SALIDA, exist_ok=True); os.makedirs(TMP, exist_ok=True)
cache = {}
for nombre, (orig, ini, fin, fundido) in CORTES.items():
    if orig not in cache: cache[orig] = leer(orig)
    a, sr = cache[orig]
    trozo = a[int(ini * sr):int(fin * sr)].copy()
    entrada = int(0.003 * sr)                       # 3 ms de entrada para que no chasquee
    trozo[:entrada] *= np.linspace(0, 1, entrada)
    n = int(fundido * sr)
    if n: trozo[-n:] *= np.linspace(1, 0, n) ** 2
    pico = np.abs(trozo).max() or 1
    trozo = trozo / pico * 0.9
    tmp = os.path.join(TMP, nombre + ".wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes((trozo * 32767).astype(np.int16).tobytes())
    dst = os.path.join(SALIDA, nombre + ".m4a")
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", tmp, dst], check=True)
    print(f"{nombre}: {len(trozo)/sr:.2f}s  {os.path.getsize(dst)//1024} KB")
for f in os.listdir(TMP): os.remove(os.path.join(TMP, f))
os.rmdir(TMP)
