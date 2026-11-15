"""Muestra los golpes (eventos) de cada grabación para decidir dónde recortar: python3 sonido/analizar.py"""
import wave, sys, os
import numpy as np
def leer(p):
    w = wave.open(p); n = w.getnframes(); sr = w.getframerate(); ch = w.getnchannels()
    a = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float32) / 32768
    if ch > 1: a = a.reshape(-1, ch).mean(axis=1)
    return a, sr
carpeta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "originales")
for f in sorted(os.listdir(carpeta)):
    if not f.endswith(".wav"): continue
    a, sr = leer(os.path.join(carpeta, f))
    hop = int(sr * 0.01)
    env = np.array([np.abs(a[i:i+hop]).max() for i in range(0, len(a) - hop, hop)])
    pico = env.max(); umbral = pico * 0.25
    eventos, dentro, ini = [], False, 0
    for i, v in enumerate(env):
        if v > umbral and not dentro: dentro, ini = True, i
        elif v < umbral * 0.4 and dentro:
            dentro = False; eventos.append((ini * 0.01, i * 0.01, float(env[ini:i].max())))
    print(f"{f}: {len(a)/sr:.2f}s pico {pico:.2f} eventos {len(eventos)}")
    for e in eventos[:24]: print(f"   {e[0]:7.2f}-{e[1]:6.2f}s  {e[2]:.2f}")
