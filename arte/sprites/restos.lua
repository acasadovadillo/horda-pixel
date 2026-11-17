-- RESTOS de Horda Pixel (40x24, 9 fotogramas, punto base { 20, 20 }): lo que queda en el suelo cuando se
-- rompe algo del mapa. El juego los pinta en el suelo para siempre (no chocan).
--   0 astillas y tablas rotas (caja, barrera)    1 chatarra (barril, contenedor)
--   2 tocón con astillas y hojas (árbol)          3 ramas y hojas sueltas (arbusto)
--   4 cono aplastado                              5 neumáticos tirados
--   6 farola caída (el poste tumbado)             7 sacos reventados con arena derramada
local L = dofile(app.params.lib)
local W, H = 40, 24
local MA, ME, TI, HO = L.rampa("madera"), L.rampa("metal"), L.rampa("tinta"), L.rampa("hojas")
local TR, OX, SA, PN = L.rampa("tronco"), L.rampa("oxido"), L.rampa("saco"), L.rampa("pintura")
local CU, TIERRA, SE = L.rampa("cuero"), L.rampa("tierra"), L.rampa("senal")
local NAR = { L.hex("6b2a0e"), L.hex("a8461a"), L.hex("d9702e"), L.hex("f0a060") }
local GOMA = { L.hex("141317"), L.hex("222127"), L.hex("33323a"), L.hex("4a4952") }
local ARENA = { L.hex("6b5a3e"), L.hex("8c7a54"), L.hex("ab986e") }

local function puntos(img, lista, c) for _, p in ipairs(lista) do L.px(img, p[1], p[2], c) end end
-- Tabla o trozo alargado de (x0,y0) a (x1,y1) con 2 px de grueso: luz arriba, sombra abajo.
local function tabla(img, x0, y0, x1, y1, R)
  L.grueso(img, x0, y0, x1, y1, 2, R[3])
  L.linea(img, x0, y0, x1, y1, R[4])
end
local function perfilar(img) L.contorno(img, TI[1]) end

local function astillas(img)
  local r = L.azar(4)
  tabla(img, 6, 16, 18, 13, MA); tabla(img, 20, 18, 33, 15, MA); tabla(img, 13, 20, 24, 21, MA)
  tabla(img, 24, 11, 30, 14, MA)
  perfilar(img)
  for k = 1, 14 do L.px(img, math.floor(4 + r() * 32), math.floor(9 + r() * 13), k % 2 == 0 and MA[4] or MA[2]) end
  puntos(img, { { 16, 14 }, { 28, 16 } }, ME[4])                     -- clavos
end

local function chatarra(img)
  local r = L.azar(9)
  L.poligono(img, { { 8, 14 }, { 18, 11 }, { 22, 17 }, { 11, 20 } }, ME[3])
  L.poligono(img, { { 21, 13 }, { 32, 12 }, { 34, 18 }, { 24, 20 } }, ME[2])
  L.linea(img, 8, 14, 18, 11, ME[5]); L.linea(img, 21, 13, 32, 12, ME[4])
  L.poligono(img, { { 14, 18 }, { 20, 18 }, { 19, 22 }, { 13, 21 } }, OX[2])
  perfilar(img)
  for k = 1, 10 do L.px(img, math.floor(5 + r() * 30), math.floor(10 + r() * 12), k % 3 == 0 and OX[3] or ME[4]) end
end

local function tocon(img)
  local r = L.azar(5)
  -- hojas y astillas alrededor
  for k = 1, 22 do L.px(img, math.floor(6 + r() * 28), math.floor(11 + r() * 11), HO[2 + (k % 3)]) end
  -- tocón: cara de arriba con anillos y corteza
  L.elipse(img, 20, 15, 5, 3, TR[3]); L.rect(img, 15, 15, 11, 4, TR[2])
  L.elipse(img, 20, 15, 4, 2, MA[4]); L.elipse(img, 20, 15, 2, 1, MA[3])
  puntos(img, { { 16, 13 }, { 24, 17 } }, MA[5])
  perfilar(img)
  tabla(img, 26, 18, 32, 16, MA)                                     -- astilla grande
end

local function ramas(img)
  local r = L.azar(6)
  L.linea(img, 8, 17, 18, 14, TR[3]); L.linea(img, 20, 19, 31, 15, TR[3]); L.linea(img, 14, 14, 20, 11, TR[2])
  for k = 1, 30 do L.px(img, math.floor(6 + r() * 28), math.floor(10 + r() * 12), HO[1 + (k % 4)]) end
  perfilar(img)
end

local function conoAplastado(img)
  L.poligono(img, { { 12, 16 }, { 28, 14 }, { 29, 19 }, { 13, 21 } }, NAR[2])
  L.linea(img, 12, 16, 28, 14, NAR[3])
  L.rect(img, 17, 15, 3, 5, L.col("tela", 4)); L.rect(img, 23, 15, 2, 4, L.col("tela", 3))
  L.rect(img, 10, 19, 6, 2, GOMA[2])
  perfilar(img)
end

local function neumaticos(img)
  for _, c in ipairs({ { 13, 15 }, { 26, 17 } }) do
    L.elipse(img, c[1], c[2], 6, 3, GOMA[3]); L.elipse(img, c[1], c[2], 3, 1, GOMA[1])
    L.px(img, c[1] - 4, c[2] - 2, GOMA[4])
  end
  perfilar(img)
end

local function farolaCaida(img)
  L.grueso(img, 2, 18, 33, 13, 2, ME[3]); L.linea(img, 2, 17, 33, 12, ME[4])
  L.rect(img, 32, 10, 6, 4, ME[2]); L.px(img, 33, 10, ME[4])           -- cabeza de la farola
  L.rect(img, 1, 17, 4, 4, ME[2])                                      -- base arrancada
  perfilar(img)
  puntos(img, { { 30, 16 }, { 36, 15 }, { 35, 17 }, { 28, 18 } }, L.col("cristal", 4))   -- cristales
end

local function sacos(img)
  local r = L.azar(8)
  L.elipse(img, 20, 17, 15, 4, ARENA[2])
  for k = 1, 30 do L.px(img, math.floor(6 + r() * 28), math.floor(14 + r() * 7), ARENA[1 + (k % 3)]) end
  L.poligono(img, { { 8, 13 }, { 17, 12 }, { 18, 16 }, { 9, 17 } }, SA[2]); L.linea(img, 8, 13, 17, 12, SA[4])
  L.poligono(img, { { 23, 12 }, { 32, 13 }, { 31, 17 }, { 22, 16 } }, SA[3]); L.linea(img, 23, 12, 32, 13, SA[4])
  perfilar(img)
end

-- 8 ladrillos rotos y polvo de mortero (paredes de ladrillo)
local LAD = { L.hex("3a1f18"), L.hex("5c3024"), L.hex("7d4432"), L.hex("9a5a42") }
local function ladrillos(img)
  local r = L.azar(12)
  for k = 1, 26 do L.px(img, math.floor(5 + r() * 30), math.floor(12 + r() * 10), L.col("hormigon", 1 + (k % 3))) end
  for _, b in ipairs({ { 8, 14 }, { 15, 17 }, { 22, 13 }, { 27, 18 }, { 13, 11 }, { 30, 14 } }) do
    L.rect(img, b[1], b[2], 5, 3, LAD[3]); L.rect(img, b[1], b[2], 5, 1, LAD[4]); L.rect(img, b[1], b[2] + 2, 5, 1, LAD[2])
  end
  perfilar(img)
end

L.construir("restos", W, H, { astillas, chatarra, tocon, ramas, conoAplastado, neumaticos, farolaCaida, sacos, ladrillos }, {}, 0.1, { base = { 20, 20 } })
