-- ZONAS DE LA BASE de Horda Pixel (64x48, punto base { 32, 46 }). Construye:
--   enfermeria: tienda de lona con cruz roja, la entrada abierta y una caja de botiquines.
--   taller: cobertizo con tejado de chapa, banco de trabajo, tornillo y herramientas colgadas.
--   armeria: contenedor militar con las puertas abiertas, armero con fusiles y cajas de munición delante.
-- Vista 3/4: se ve el tejado (cara de arriba) y la cara sur. Luz arriba a la izquierda.
local L = dofile(app.params.lib)
local ME, MA, TI, TE, RO = L.rampa("metal"), L.rampa("madera"), L.rampa("tinta"), L.rampa("tela"), L.rampa("rojo")
local OX, SE, CU, SA = L.rampa("oxido"), L.rampa("senal"), L.rampa("cuero"), L.rampa("saco")
local OLIVA = { L.hex("1f2416"), L.hex("323a22"), L.hex("4a5432"), L.hex("66713f"), L.hex("858f55") }
local LONA = { L.hex("3d3b33"), L.hex("5c5a4c"), L.hex("7d7a66"), L.hex("9c9880"), L.hex("b5b097") }
local W, H = 64, 48
local M = L.hex("ff00ff")

local function mascara(img)
  local s = {}
  for y = 0, H - 1 do for x = 0, W - 1 do s[y * W + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < W and y < H and s[y * W + x] end
end
local function volumen(m, t)
  local op = mascara(m)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if op(x, y) then
      local c = t[3]
      if not op(x, y + 1) or not op(x + 1, y) then c = t[1]
      elseif not op(x, y - 1) or not op(x - 1, y) then c = t[4]
      elseif not op(x, y + 2) then c = t[2]
      end
      m:drawPixel(x, y, c)
    end
  end end
end
local function pieza(img, dibujar, t, detalles)
  local m = L.imagen(W, H)
  dibujar(m)
  volumen(m, t)
  if detalles then detalles(m) end
  L.pegar(img, m, 0, 0)
end
local function puntos(img, lista, c) for _, p in ipairs(lista) do L.px(img, p[1], p[2], c) end end

---------------------------------------------------------------- enfermería
local function enfermeria(img)
  local r = L.azar(3)
  -- pared de lona (cara sur) con la entrada abierta
  pieza(img, function(m) L.rect(m, 8, 27, 48, 18, M) end, LONA, function(m)
    for _, x in ipairs({ 14, 22, 42, 50 }) do L.rect(m, x, 28, 1, 16, LONA[2]) end          -- pliegues
    L.rect(m, 26, 29, 12, 16, TI[2])                                                         -- entrada
    L.rect(m, 27, 30, 10, 15, TI[3])
    L.rect(m, 29, 38, 7, 2, LONA[3]); L.rect(m, 29, 40, 7, 1, LONA[2])                       -- camilla dentro
    L.poligono(m, { { 24, 28 }, { 28, 28 }, { 25, 45 }, { 22, 45 } }, LONA[4])               -- faldón recogido
    L.poligono(m, { { 37, 28 }, { 41, 28 }, { 43, 45 }, { 40, 45 } }, LONA[2])
  end)
  -- tejado: la vertiente sur, del caballete al alero
  pieza(img, function(m) L.poligono(m, { { 13, 6 }, { 51, 6 }, { 59, 28 }, { 5, 28 } }, M) end, LONA, function(m)
    L.rect(m, 13, 6, 38, 1, LONA[5])
    for k = 0, 40 do local x = math.floor(6 + r() * 52); local y = math.floor(9 + r() * 17); if L.opaco(m, x, y) then L.px(m, x, y, LONA[2]) end end
    -- cruz roja
    L.rect(m, 29, 11, 6, 14, RO[2]); L.rect(m, 25, 15, 14, 6, RO[2])
    L.rect(m, 29, 11, 6, 1, RO[3]); L.rect(m, 25, 15, 4, 1, RO[3]); L.rect(m, 35, 15, 4, 1, RO[3])
    L.rect(m, 34, 12, 1, 3, RO[1]); L.rect(m, 34, 21, 1, 4, RO[1])
  end)
  L.contorno(img, TI[1])
  -- vientos y estacas
  puntos(img, { { 4, 29 }, { 3, 31 }, { 2, 33 }, { 1, 35 } }, LONA[2]); L.px(img, 1, 36, MA[2])
  puntos(img, { { 60, 29 }, { 61, 31 }, { 62, 33 } }, LONA[2]); L.px(img, 62, 34, MA[2])
  -- caja de botiquines delante a la derecha
  pieza(img, function(m) L.rect(m, 47, 38, 11, 8, M) end, TE, function(m)
    L.rect(m, 51, 40, 3, 4, RO[2]); L.rect(m, 50, 41, 5, 2, RO[2]); L.rect(m, 47, 38, 11, 1, TE[4])
  end)
  L.contorno(img, TI[1], { solo = function(x, y) return y >= 37 and x >= 46 end })
end

---------------------------------------------------------------- taller
local function taller(img)
  -- pared del fondo de tablas
  pieza(img, function(m) L.rect(m, 8, 12, 48, 16, M) end, MA, function(m)
    for y = 15, 27, 4 do L.rect(m, 9, y, 46, 1, MA[2]) end
    -- herramientas colgadas: sierra, martillo, llave
    L.rect(m, 13, 15, 9, 3, ME[5]); for x = 13, 21, 2 do L.px(m, x, 18, ME[4]) end; L.rect(m, 11, 15, 2, 3, MA[4])
    L.rect(m, 27, 14, 1, 8, MA[5]); L.rect(m, 25, 14, 5, 2, ME[3])
    L.rect(m, 34, 14, 1, 7, ME[5]); L.rect(m, 33, 14, 3, 2, ME[4]); L.rect(m, 33, 20, 3, 2, ME[4])
    -- lámpara
    L.rect(m, 45, 13, 4, 2, ME[3]); L.rect(m, 46, 15, 2, 1, L.col("fuego", 4))
  end)
  -- postes
  for _, x in ipairs({ 7, 55 }) do pieza(img, function(m) L.rect(m, x, 10, 3, 35, M) end, MA) end
  -- banco de trabajo
  pieza(img, function(m)
    L.rect(m, 11, 29, 42, 4, M)                                     -- tablero
    L.rect(m, 13, 33, 3, 12, M); L.rect(m, 48, 33, 3, 12, M)        -- patas
    L.rect(m, 13, 39, 38, 2, M)                                     -- travesaño
  end, MA, function(m)
    L.rect(m, 11, 29, 42, 1, MA[5])
    puntos(m, { { 20, 30 }, { 21, 30 }, { 38, 31 } }, MA[3])
  end)
  -- tornillo de banco y una tabla encima
  pieza(img, function(m) L.rect(m, 15, 25, 6, 4, M); L.rect(m, 17, 24, 2, 1, M) end, { ME[1], ME[2], ME[3], ME[4] })
  pieza(img, function(m) L.rect(m, 27, 26, 16, 3, M) end, { MA[2], MA[3], MA[4], MA[5] })
  L.px(img, 35, 25, L.col("fuego", 4))                              -- chispa
  -- tejado de chapa ondulada
  pieza(img, function(m) L.poligono(m, { { 3, 2 }, { 61, 2 }, { 62, 11 }, { 2, 11 } }, M) end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    for x = 4, 60, 3 do L.rect(m, x, 3, 1, 8, ME[3]) end
    puntos(m, { { 18, 5 }, { 19, 6 }, { 44, 8 }, { 45, 8 }, { 30, 4 } }, OX[3])
    puntos(m, { { 19, 5 }, { 45, 9 } }, OX[2])
  end)
  -- tablas apoyadas a un lado
  pieza(img, function(m) L.poligono(m, { { 56, 45 }, { 59, 45 }, { 63, 22 }, { 61, 22 } }, M) end, MA)
  L.contorno(img, TI[1])
end

---------------------------------------------------------------- armería
local function armeria(img)
  -- contenedor: techo y cara sur con ondas
  pieza(img, function(m) L.rect(m, 4, 14, 56, 31, M) end, OLIVA, function(m)
    for x = 6, 58, 3 do L.rect(m, x, 15, 1, 29, OLIVA[2]) end
    -- interior con las puertas abiertas
    L.rect(m, 20, 17, 24, 27, TI[2]); L.rect(m, 21, 18, 22, 26, TI[3])
    -- armero: fusiles de pie
    for k = 0, 5 do
      local x = 23 + k * 3
      L.rect(m, x, 20, 1, 17, ME[3]); L.px(m, x, 20, ME[5])
      L.rect(m, x, 31, 1, 6, MA[3])
    end
    L.rect(m, 22, 37, 20, 2, MA[2])
    -- letras de la plantilla
    L.rect(m, 8, 19, 9, 2, SE[2]); L.rect(m, 47, 19, 9, 2, SE[2])
  end)
  pieza(img, function(m) L.rect(m, 3, 9, 58, 6, M) end, OLIVA, function(m) L.rect(m, 4, 10, 56, 1, OLIVA[5]) end)
  -- puertas abiertas a los lados
  pieza(img, function(m) L.poligono(m, { { 15, 16 }, { 20, 17 }, { 20, 44 }, { 15, 45 } }, M) end, OLIVA)
  pieza(img, function(m) L.poligono(m, { { 44, 17 }, { 49, 16 }, { 49, 45 }, { 44, 44 } }, M) end, { OLIVA[1], OLIVA[2], OLIVA[2], OLIVA[3] })
  -- cajas de munición delante
  local function cajaMun(x, y)
    pieza(img, function(m) L.rect(m, x, y, 10, 6, M) end, OLIVA, function(m)
      L.rect(m, x + 2, y + 2, 6, 1, SE[3]); L.rect(m, x, y, 10, 1, OLIVA[5])
    end)
  end
  cajaMun(6, 39); cajaMun(9, 33); cajaMun(50, 39)
  L.contorno(img, TI[1])
end

L.construir("enfermeria", W, H, { enfermeria }, {}, 0.1, { base = { 32, 46 } })
L.construir("taller", W, H, { taller }, {}, 0.1, { base = { 32, 46 } })
L.construir("armeria", W, H, { armeria }, {}, 0.1, { base = { 32, 46 } })
