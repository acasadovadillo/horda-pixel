-- PAREDES DE LOS EDIFICIOS de Horda Pixel (vista 3/4: arriba la cara de arriba del muro, abajo la cara sur).
-- Construye:
--   pared (24x32): tramo horizontal de 24 px. Cara de arriba en las filas 0-7, cara sur en las 8-31.
--     0 ladrillo, 1 ladrillo dañado, 2 madera, 3 madera dañada, 4 puerta cerrada, 5 puerta abierta, 6 puerta dañada.
--   pared_v (8x48): tramo vertical de 24 px. Cara de arriba en las filas 0-23, cara sur en las 24-47
--     (solo se ve la del último tramo; las demás las tapa el siguiente). 0 ladrillo, 1 dañado, 2 madera, 3 dañada.
--   suelo_casa (24x24): tablas del suelo de dentro. 0 tablas, 1 tablas gastadas con una mancha.
local L = dofile(app.params.lib)
local MA, HO, TI, SA = L.rampa("madera"), L.rampa("hormigon"), L.rampa("tinta"), L.rampa("sangre")
local LAD = { L.hex("3a1f18"), L.hex("5c3024"), L.hex("7d4432"), L.hex("9a5a42"), L.hex("b37555") }
local MORT = { L.hex("4a4a4c"), L.hex("626264"), L.hex("7b7b7c") }

local function puntos(img, lista, c) for _, p in ipairs(lista) do L.px(img, p[1], p[2], c) end end

-- Ladrillos en un rectángulo (x0..x0+w-1, y0..y0+h-1): hiladas de 3 px con llaga desplazada; más oscuro abajo.
local function ladrillos(img, x0, y0, w, h, semilla, salto)
  local r = L.azar(semilla)
  for y = y0, y0 + h - 1 do
    local fila = math.floor((y - y0) / 3)
    local junta = (y - y0) % 3 == 2
    local osc = (y - y0) / h
    for x = x0, x0 + w - 1 do
      local c
      if junta then c = MORT[2]
      elseif ((x - x0) + (fila % 2) * (salto or 3)) % 6 == 5 then c = MORT[1]
      else
        local base = osc > 0.75 and 2 or osc > 0.3 and 3 or 4
        if r() < 0.12 then base = base - 1 end
        c = LAD[base]
      end
      L.px(img, x, y, c)
    end
  end
end

-- Tablas verticales de madera.
local function tablas(img, x0, y0, w, h, semilla)
  local r = L.azar(semilla)
  for x = x0, x0 + w - 1 do
    local k = (x - x0) % 5
    for y = y0, y0 + h - 1 do
      local osc = (y - y0) / h
      local c = k == 4 and MA[1] or k == 0 and MA[4] or (osc > 0.7 and MA[2] or MA[3])
      if k ~= 4 and r() < 0.06 then c = MA[2] end
      L.px(img, x, y, c)
    end
  end
end

-- Daños: grietas y huecos de ladrillo o tablas rotas.
local function danos(img, x0, y0, w, h, semilla, madera)
  local r = L.azar(semilla)
  for k = 1, 3 do
    local x, y = x0 + math.floor(r() * (w - 4)), y0 + math.floor(r() * (h - 4))
    if madera then L.rect(img, x, y, 2, 3 + math.floor(r() * 3), TI[2])
    else L.rect(img, x, y, 3, 2, TI[3]); L.px(img, x + 1, y + 2, TI[2]) end
  end
  for k = 1, 4 do                                   -- grieta
    local x, y = x0 + math.floor(r() * w), y0 + math.floor(r() * h)
    for i = 0, 3 do L.px(img, x + i, y + math.floor(i * 0.7), TI[2]) end
  end
end

local function remate(img, x0, w, h, madera)          -- cara de arriba del muro
  if madera then
    L.rect(img, x0, 0, w, h, MA[4]); L.rect(img, x0, 0, w, 1, MA[5]); L.rect(img, x0, h - 1, w, 1, MA[2])
  else
    L.rect(img, x0, 0, w, h, HO[3]); L.rect(img, x0, 0, w, 1, HO[4]); L.rect(img, x0, h - 1, w, 1, HO[2])
    puntos(img, { { x0 + 2, 3 }, { x0 + math.max(1, w - 3), 5 } }, HO[2])
  end
end

---------------------------------------------------------------- pared horizontal
local function horizontal(tipo, danada)
  return function(img)
    local madera = tipo == "madera"
    remate(img, 0, 24, 8, madera)
    if madera then tablas(img, 0, 8, 24, 24, 3) else ladrillos(img, 0, 8, 24, 24, 5) end
    L.rect(img, 0, 8, 24, 1, madera and MA[1] or LAD[1])        -- sombra bajo el remate
    if danada then danos(img, 1, 10, 22, 20, 9, madera) end
  end
end

local function puerta(estado)
  return function(img)
    remate(img, 0, 24, 8, true)
    ladrillos(img, 0, 8, 24, 24, 5)
    L.rect(img, 0, 8, 24, 1, LAD[1])
    -- marco
    L.rect(img, 4, 9, 16, 23, MA[2]); L.rect(img, 4, 9, 16, 1, MA[4])
    if estado == "abierta" then
      L.rect(img, 6, 10, 12, 22, TI[2]); L.rect(img, 6, 10, 12, 2, TI[1])
      L.rect(img, 6, 12, 3, 20, MA[3])                          -- la hoja abierta hacia dentro, de canto
    else
      tablas(img, 6, 10, 12, 22, 7)
      L.rect(img, 6, 15, 12, 1, MA[2]); L.rect(img, 6, 25, 12, 1, MA[2])
      L.px(img, 16, 20, L.col("oro", 3)); L.px(img, 16, 21, L.col("oro", 2))   -- pomo
      if estado == "danada" then danos(img, 6, 11, 12, 19, 11, true); puntos(img, { { 9, 18 }, { 10, 19 } }, SA[2]) end
    end
  end
end

L.construir("pared", 24, 32, {
  horizontal("ladrillo"), horizontal("ladrillo", true), horizontal("madera"), horizontal("madera", true),
  puerta("cerrada"), puerta("abierta"), puerta("danada"),
}, {}, 0.1)

---------------------------------------------------------------- pared vertical
local function vertical(tipo, danada)
  return function(img)
    local madera = tipo == "madera"
    remate(img, 0, 8, 24, madera)
    -- sin rayas arriba y abajo: los tramos verticales se unen en una sola tira
    L.rect(img, 1, 0, 6, 1, madera and MA[4] or HO[3]); L.rect(img, 1, 23, 6, 1, madera and MA[4] or HO[3])
    -- borde claro a la izquierda y oscuro a la derecha en la cara de arriba (es una tira larga)
    L.rect(img, 0, 0, 1, 24, madera and MA[5] or HO[4]); L.rect(img, 7, 0, 1, 24, madera and MA[2] or HO[2])
    if madera then tablas(img, 0, 24, 8, 24, 4) else ladrillos(img, 0, 24, 8, 24, 6, 2) end
    L.rect(img, 0, 24, 8, 1, madera and MA[1] or LAD[1])
    if danada then danos(img, 0, 26, 8, 20, 13, madera); puntos(img, { { 3, 6 }, { 4, 7 }, { 4, 15 } }, TI[3]) end
  end
end
L.construir("pared_v", 8, 48, { vertical("ladrillo"), vertical("ladrillo", true), vertical("madera"), vertical("madera", true) }, {}, 0.1)

---------------------------------------------------------------- suelo de dentro
local function suelo(mancha)
  return function(img)
    local r = L.azar(mancha and 21 or 17)
    for y = 0, 23 do
      local tabla = math.floor(y / 6)
      for x = 0, 23 do
        local c = (y % 6 == 5) and MA[1] or ((x + tabla * 9) % 24 == 0) and MA[1] or MA[2]
        if c == MA[2] and r() < 0.15 then c = MA[3] end
        if c == MA[2] and r() < 0.05 then c = MA[1] end
        L.px(img, x, y, c)
      end
    end
    if mancha then L.elipse(img, 14, 13, 4, 2, SA[1]); L.px(img, 12, 13, SA[2]) end
  end
end
L.construir("suelo_casa", 24, 24, { suelo(false), suelo(true) }, {}, 0.1)
