-- corazon (11x10): icono de vida. Corazón carnoso con volumen, luz arriba a la izquierda.
local L = dofile(app.params.lib)
local mapa = {
  o = L.hex("6e1016"),            -- contorno arriba-izquierda (más claro)
  O = L.hex("3a070b"),            -- contorno abajo-derecha
  d = L.col("rojo", 1),           -- pliegue y sombra profunda
  m = L.col("rojo", 2),           -- sombra
  b = L.hex("cf3232"),            -- tono base
  l = L.col("rojo", 4),           -- luz
  w = L.hex("ffc2b4"),            -- brillo
}
local filas = {
  ".ooo...ooo.",
  "oblloOolbmO",
  "obwlbdbbbmO",
  "obwbbbbbbmO",
  "obbbbbbbmdO",
  ".ObbbbbmmdO",
  "..ObbbmmdO.",
  "...OmmmdO..",
  "....OmdO...",
  ".....OO....",
}
L.comprobar("corazon", filas, 11)
L.construir("corazon", 11, 10, { function(img) L.pintar(img, filas, 0, 0, mapa) end })
