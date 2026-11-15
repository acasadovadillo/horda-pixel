-- EJEMPLO DE USO DE LA LIBRERÍA (no es una referencia de calidad, solo enseña la API).
-- Probar:  arte/probar.sh arte/ejemplo/salida arte/ejemplo/ejemplo.lua
local L = dofile(app.params.lib)

-- Colores: rampas de la paleta (1 = oscuro) o un hexadecimal propio.
local naranja = { L.hex("7a3210"), L.hex("b5521a"), L.hex("e07a2a"), L.hex("f5a55a") }
local tinta = L.col("tinta", 1)

-- Un sprite de un fotograma con punto de anclaje: cono de carretera (10x14).
L.construir("cono", 10, 14, {
  function(img)
    L.poligono(img, { { 4, 1 }, { 6, 1 }, { 8, 11 }, { 2, 11 } }, naranja[3])   -- cuerpo
    L.rect(img, 3, 5, 4, 2, L.col("tela", 4))                                   -- franja reflectante
    L.linea(img, 4, 1, 2, 10, naranja[4])                                       -- luz a la izquierda
    L.linea(img, 6, 2, 7, 10, naranja[2])                                       -- sombra a la derecha
    L.rect(img, 1, 11, 8, 2, naranja[2])                                        -- base
    L.contorno(img, tinta)
  end,
}, nil, nil, { base = { 5, 12 } })

-- Un sprite animado con etiqueta: moneda que gira (10x10, 6 fotogramas).
local anchos = { 4, 3, 1.2, 0.6, 1.2, 3 }
local cuadros = {}
for i, rx in ipairs(anchos) do
  cuadros[i] = function(img)
    L.elipse(img, 5, 5, rx, 4, L.col("oro", 3))
    L.elipse(img, 5 - rx * 0.3, 4.5, rx * 0.5, 2.5, L.col("oro", 4))
    L.contorno(img, L.col("oro", 1))
  end
end
L.construir("moneda", 10, 10, cuadros, { { "girar", 1, 6 } }, 0.09)

-- También se puede dibujar a mano con filas de caracteres:
local mapa = { K = tinta, r = L.col("rojo", 2), R = L.col("rojo", 1), w = L.col("rojo", 4) }
local filas = {
  "..KK...KK..",
  ".KrrK.KrrK.",
  "KrwrrKrrrRK",
  "KrwrrrrrrRK",
  "KrrrrrrrrRK",
  ".KrrrrrrRK.",
  "..KrrrrRK..",
  "...KrrRK...",
  "....KRK....",
  ".....K.....",
}
L.comprobar("corazon", filas, 11)
L.construir("corazon", 11, 10, { function(img) L.pintar(img, filas, 0, 0, mapa) end })
