-- ICONOS DE LAS ARMAS NUEVAS de Horda Pixel (36x18): cada arma sola de perfil, apuntando a la derecha
-- (botones de la barra de armas y tarjetas de la tienda). Construye: bate, machete, francotirador,
-- ballesta y lanzallamas. Mismo método que pistola.lua: cada pieza es una silueta con volumen
-- (luz arriba a la izquierda) y al final un contorno selectivo.
local L = dofile(app.params.lib)
local W, H = 36, 18
local ME, MA, TI = L.rampa("metal"), L.rampa("madera"), L.rampa("tinta")
local OX, SA, PI, CU = L.rampa("oxido"), L.rampa("sangre"), L.rampa("pintura"), L.rampa("cuero")
local FU = L.rampa("fuego")
local M = L.hex("ff00ff")
local CINTA = { L.hex("17171c"), L.hex("25252c"), L.hex("35353e"), L.hex("4a4954") }   -- cinta aislante negra
local OLIVA = { L.hex("1f2416"), L.hex("323a22"), L.hex("4a5432"), L.hex("66713f"), L.hex("858f55") }

local function capa() return L.imagen(W, H) end
local function mascara(img)
  local s = {}
  for y = 0, H - 1 do for x = 0, W - 1 do s[y * W + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < W and y < H and s[y * W + x] end
end

-- Volumen: t = { borde, sombra, base, luz }.
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
  local m = capa()
  dibujar(m)
  volumen(m, t)
  if detalles then detalles(m) end
  L.pegar(img, m, 0, 0)
end

local function contorno(img)
  local op = mascara(img)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if not op(x, y) then
      local arriba = op(x, y + 1) or op(x + 1, y)
      local abajo = op(x, y - 1) or op(x - 1, y)
      if arriba or abajo then img:drawPixel(x, y, abajo and TI[1] or TI[2]) end
    end
  end end
end
local function puntos(img, lista, c) for _, p in ipairs(lista) do L.px(img, p[1], p[2], c) end end

-- Barra recta con grosor variable de (x0, y) a (x1, y): g(x) = medio grosor en x (centrado en yc).
local function huso(m, x0, x1, yc, g)
  for x = x0, x1 do
    local r = g(x)
    for y = math.floor(yc - r + 0.5), math.floor(yc + r - 0.5) do L.px(m, x, y, M) end
  end
end

---------------------------------------------------------------- bate
-- Bate de madera con el puño envuelto en cinta y sangre seca en la punta.
local function bate(img)
  local yc = 9
  pieza(img, function(m)
    huso(m, 1, 34, yc, function(x)
      if x < 3 then return 2.5 end                 -- pomo
      if x < 13 then return 1.5 end                -- mango
      local u = (x - 13) / 21
      return 1.5 + 2.6 * math.min(1, u * 1.5)      -- se ensancha hacia el barril
    end)
  end, { MA[2], MA[3], MA[4], MA[5] }, function(m)
    -- vetas y golpes
    puntos(m, { { 19, 9 }, { 20, 9 }, { 21, 9 }, { 26, 10 }, { 27, 10 }, { 30, 8 }, { 31, 8 } }, MA[3])
    puntos(m, { { 24, 8 }, { 29, 10 }, { 33, 9 } }, MA[2])
    -- sangre seca en la punta
    puntos(m, { { 29, 10 }, { 30, 10 }, { 31, 11 }, { 32, 10 }, { 32, 11 }, { 33, 10 }, { 28, 11 }, { 30, 12 }, { 31, 12 } }, SA[2])
    puntos(m, { { 31, 10 }, { 33, 11 }, { 29, 11 } }, SA[3])
  end)
  -- cinta del puño
  pieza(img, function(m) huso(m, 3, 12, yc, function() return 1.7 end) end, CINTA, function(m)
    for _, x in ipairs({ 5, 8, 11 }) do L.px(m, x, 9, CINTA[1]); L.px(m, x, 8, CINTA[1]) end
  end)
end

---------------------------------------------------------------- machete
-- Machete: hoja larga algo curva con filo claro, lomo oscuro, mango de madera con remaches.
local function machete(img)
  -- hoja: ancha, con panza en el filo y la punta subiendo en curva
  pieza(img, function(m)
    for x = 12, 34 do
      local u = (x - 12) / 22
      local lomo = 6 + math.floor(u * 1.5)
      local filo = 11 + math.floor(math.sin(u * 2.8) * 2.4)
      if x > 29 then lomo = lomo + math.floor((x - 29) * 0.9); filo = filo - math.floor((x - 29) * 0.6) end
      for y = lomo, filo do L.px(m, x, y, M) end
    end
  end, { ME[3], ME[4], ME[5], ME[6] }, function(m)
    -- bisel del filo: franja clara a lo largo del borde de abajo
    for x = 13, 33 do
      for y = 17, 4, -1 do
        if L.opaco(m, x, y) then L.px(m, x, y - 1, ME[6]); L.px(m, x, y - 2, ME[5]); break end
      end
    end
    -- lomo oscuro
    for x = 12, 30 do for y = 3, 12 do if L.opaco(m, x, y) then L.px(m, x, y, ME[3]); L.px(m, x, y + 1, ME[4]); break end end end
    -- óxido y sangre
    puntos(m, { { 15, 9 }, { 16, 9 }, { 16, 10 }, { 17, 9 }, { 21, 9 }, { 22, 9 } }, OX[3])
    puntos(m, { { 16, 8 }, { 22, 10 } }, OX[2])
    puntos(m, { { 25, 10 }, { 26, 10 }, { 26, 11 }, { 27, 10 }, { 28, 11 }, { 27, 12 }, { 29, 10 } }, SA[3])
    puntos(m, { { 27, 11 }, { 25, 11 }, { 28, 12 } }, SA[2])
  end)
  -- guarda
  pieza(img, function(m) L.rect(m, 10, 5, 2, 9, M) end, { ME[1], ME[2], ME[3], ME[4] })
  -- mango con remaches
  pieza(img, function(m)
    L.rect(m, 1, 7, 9, 5, M); L.px(m, 0, 8, M); L.px(m, 0, 9, M); L.px(m, 0, 10, M)
  end, { MA[1], MA[2], MA[3], MA[4] }, function(m)
    puntos(m, { { 3, 8 }, { 7, 8 } }, ME[6])
    puntos(m, { { 3, 9 }, { 7, 9 } }, ME[3])
  end)
end

---------------------------------------------------------------- fusil de cerrojo
local function francotirador(img)
  -- culata y guardamanos de madera
  pieza(img, function(m)
    L.poligono(m, { { 0, 8 }, { 4, 8 }, { 11, 9 }, { 23, 9 }, { 23, 12 }, { 14, 12 }, { 11, 13 }, { 6, 15 }, { 0, 16 } }, M)
  end, { MA[2], MA[3], MA[4], MA[5] }, function(m)
    puntos(m, { { 3, 11 }, { 4, 11 }, { 5, 12 }, { 7, 13 }, { 16, 10 }, { 18, 11 }, { 20, 10 } }, MA[3])
    L.rect(m, 0, 8, 1, 8, CU[2])             -- cantonera
  end)
  -- cajón, cañón y cerrojo
  pieza(img, function(m)
    L.rect(m, 11, 7, 11, 3, M)               -- cajón
    L.rect(m, 22, 8, 13, 2, M)               -- cañón
    L.rect(m, 34, 7, 2, 3, M)                -- freno de boca
  end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    puntos(m, { { 24, 8 }, { 25, 8 }, { 26, 8 }, { 30, 8 }, { 31, 8 } }, ME[6])
  end)
  -- palanca del cerrojo
  pieza(img, function(m) L.rect(m, 13, 10, 1, 2, M); L.rect(m, 13, 12, 3, 2, M) end, { ME[2], ME[3], ME[4], ME[5] })
  -- guardamonte y gatillo
  puntos(img, { { 16, 14 }, { 17, 14 }, { 18, 14 }, { 19, 13 } }, ME[2])
  L.px(img, 17, 13, ME[4])
  -- mira telescópica
  pieza(img, function(m)
    L.rect(m, 11, 3, 13, 3, M)
    L.rect(m, 9, 2, 3, 5, M); L.rect(m, 22, 2, 3, 5, M)
  end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
    L.px(m, 24, 3, L.col("cristal", 5)); L.px(m, 24, 4, L.col("cristal", 4)); L.px(m, 24, 5, L.col("cristal", 3))
    puntos(m, { { 13, 3 }, { 14, 3 }, { 15, 3 }, { 16, 3 } }, ME[5])
  end)
end

---------------------------------------------------------------- ballesta
-- Ballesta vista un poco desde arriba: culata de madera, palas del arco en vertical, cuerda y virote.
local function ballesta(img)
  -- culata y cuerpo
  pieza(img, function(m)
    L.poligono(m, { { 0, 9 }, { 6, 8 }, { 29, 8 }, { 29, 11 }, { 13, 11 }, { 10, 15 }, { 4, 15 }, { 0, 13 } }, M)
  end, { MA[2], MA[3], MA[4], MA[5] }, function(m)
    puntos(m, { { 5, 11 }, { 6, 11 }, { 18, 9 }, { 22, 9 } }, MA[3])
  end)
  -- estribo delante
  pieza(img, function(m)
    L.rect(m, 30, 6, 1, 6, M); L.rect(m, 28, 6, 3, 1, M); L.rect(m, 28, 11, 3, 1, M)
  end, { ME[2], ME[3], ME[4], ME[5] })
  -- palas del arco (curvadas hacia atrás en las puntas)
  pieza(img, function(m)
    for y = 1, 16 do
      local d = math.abs(y - 8.5) / 7.5
      local x = 26 - math.floor(d * d * 4)
      L.px(m, x, y, M); L.px(m, x + 1, y, M)
    end
  end, { OLIVA[1], OLIVA[2], OLIVA[3], OLIVA[4] })
  -- cuerda tensa
  for y = 2, 15 do
    local tc = math.abs(y - 8.5) / 6.5
    local x = math.floor(13 + tc * 9)
    L.px(img, x, y, L.col("tela", 2))
  end
  -- virote montado
  for x = 13, 33 do L.px(img, x, 7, MA[4]) end
  puntos(img, { { 34, 7 }, { 33, 6 }, { 33, 8 } }, ME[5])
  puntos(img, { { 14, 6 }, { 15, 6 } }, L.col("rojo", 2))
  -- gatillo
  puntos(img, { { 9, 11 }, { 9, 12 } }, ME[3])
end

---------------------------------------------------------------- lanzallamas
-- Lanzallamas: depósito rojo debajo, cuerpo de acero, tubo largo y llama piloto en la boca.
local function lanzallamas(img)
  -- depósito
  pieza(img, function(m)
    L.rect(m, 6, 11, 14, 5, M); L.px(m, 5, 12, M); L.px(m, 5, 13, M); L.px(m, 5, 14, M)
    L.px(m, 20, 12, M); L.px(m, 20, 13, M); L.px(m, 20, 14, M)
  end, { PI[1], PI[2], PI[3], PI[4] }, function(m)
    puntos(m, { { 8, 12 }, { 9, 12 }, { 10, 12 } }, PI[5])
    L.rect(m, 12, 11, 1, 5, PI[2])
  end)
  -- cuerpo y empuñaduras
  pieza(img, function(m)
    L.rect(m, 3, 6, 21, 4, M)
    L.rect(m, 3, 10, 3, 3, M)          -- empuñadura trasera
    L.rect(m, 20, 10, 2, 3, M)         -- empuñadura delantera
  end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
    puntos(m, { { 8, 7 }, { 12, 7 }, { 16, 7 } }, ME[2])
    L.rect(m, 5, 6, 12, 1, ME[5])
  end)
  -- tubo y boquilla
  pieza(img, function(m)
    L.rect(m, 24, 7, 9, 2, M)
    L.rect(m, 32, 6, 2, 4, M)
  end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    for _, x in ipairs({ 26, 28, 30 }) do L.px(m, x, 7, ME[2]) end
  end)
  -- llama piloto
  puntos(img, { { 34, 7 }, { 35, 7 } }, FU[4]); L.px(img, 34, 8, FU[3]); L.px(img, 35, 6, FU[3])
  -- manguera
  puntos(img, { { 4, 13 }, { 3, 14 }, { 4, 15 } }, CU[3])
end

local function icono(nombre, f)
  L.construir(nombre, W, H, { function(img) f(img); contorno(img) end })
end
icono("bate", bate)
icono("machete", machete)
icono("francotirador", francotirador)
icono("ballesta", ballesta)
icono("lanzallamas", lanzallamas)
