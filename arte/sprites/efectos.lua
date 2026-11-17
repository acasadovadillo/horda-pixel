-- EFECTOS de las armas nuevas de Horda Pixel. Construye:
--   proyectiles (12x12, 4 fotogramas): granada, molotov, virote volando (punta a la derecha) y virote clavado.
--   fuego (14x18, 4 fotogramas «arder», punto base { 7, 17 }): llama para los charcos de molotov y los zombis ardiendo.
--   explosion (48x48, 6 fotogramas «estallar», punto centro { 24, 32 }): fogonazo, bola de fuego, humo.
local L = dofile(app.params.lib)
local ME, MA, TI, FU = L.rampa("metal"), L.rampa("madera"), L.rampa("tinta"), L.rampa("fuego")
local TE, RO = L.rampa("tela"), L.rampa("rojo")
local OLIVA = { L.hex("1f2416"), L.hex("323a22"), L.hex("4a5432"), L.hex("66713f"), L.hex("858f55") }
local CRIS = { L.hex("1f2a1c"), L.hex("33452c"), L.hex("4f6640"), L.hex("7a9160"), L.hex("b5c99a") }
local GASO = { L.hex("5c2c0c"), L.hex("8a4a14"), L.hex("b8741e") }
local HUMO = { L.hex("1e1f24"), L.hex("292b31"), L.hex("34363d"), L.hex("41444c"), L.hex("51545d"), L.hex("626264") }
local TIERRA = L.rampa("tierra")

local function puntos(img, lista, c) for _, p in ipairs(lista) do L.px(img, p[1], p[2], c) end end

---------------------------------------------------------------- proyectiles
local P = 12
local function granada(img)
  -- cuerpo ovalado con cuadrícula
  local filas = { "  bcb  ", " bcdcb ", "bcdcdcb", "bcbcbcb", "bcdcdca", " acbca ", "  aaa  " }
  local mapa = { a = OLIVA[1], b = OLIVA[2], c = OLIVA[3], d = OLIVA[4] }
  L.pintar(img, filas, 2, 4, mapa)
  -- espoleta, palanca y anilla
  puntos(img, { { 4, 3 }, { 5, 3 }, { 6, 3 } }, ME[4]); L.px(img, 5, 2, ME[5])
  puntos(img, { { 7, 3 }, { 8, 4 }, { 8, 5 }, { 8, 6 } }, ME[5])
  puntos(img, { { 2, 2 }, { 3, 1 }, { 2, 0 }, { 1, 1 } }, L.col("oro", 3))
  L.contorno(img, TI[1])
end

local function molotov(img)
  -- botella de vidrio verde con gasolina, trapo y llama
  local filas = { " ab ", " ab ", "abcb", "acdb", "befb", "befb", "befb", "aeea" }
  local mapa = { a = CRIS[2], b = CRIS[3], c = CRIS[4], d = CRIS[5], e = GASO[2], f = GASO[3] }
  L.pintar(img, filas, 4, 3, mapa)
  puntos(img, { { 5, 2 }, { 6, 2 } }, TE[2]); L.px(img, 7, 1, TE[1])
  L.contorno(img, TI[1])
  -- la llama va encima del contorno (brilla)
  puntos(img, { { 5, 1 }, { 6, 1 } }, FU[4]); L.px(img, 5, 0, FU[3]); L.px(img, 6, 0, FU[5]); L.px(img, 4, 1, FU[2]); L.px(img, 7, 0, FU[2])
end

local function viroteVolando(img)
  for x = 1, 9 do L.px(img, x, 5, MA[4]) end
  for x = 2, 8 do L.px(img, x, 6, MA[2]) end
  puntos(img, { { 0, 4 }, { 1, 4 }, { 2, 4 } }, RO[2]); puntos(img, { { 0, 7 }, { 1, 7 }, { 2, 7 } }, TE[3])
  L.px(img, 10, 5, ME[5]); L.px(img, 11, 5, ME[6]); L.px(img, 10, 6, ME[3])
end

local function viroteClavado(img)
  -- clavado en diagonal: las plumas arriba a la izquierda, la punta hundida en el suelo
  local pts = { { 3, 3 }, { 4, 4 }, { 5, 5 }, { 6, 6 }, { 7, 7 }, { 8, 8 } }
  for _, p in ipairs(pts) do L.px(img, p[1], p[2], MA[4]); L.px(img, p[1] + 1, p[2], MA[2]) end
  puntos(img, { { 2, 3 }, { 2, 2 }, { 1, 2 } }, RO[2]); puntos(img, { { 3, 2 }, { 4, 1 } }, TE[3])
  L.contorno(img, TI[1])
  -- tierra levantada alrededor de donde entra
  puntos(img, { { 7, 10 }, { 8, 10 }, { 10, 10 } }, TIERRA[3]); puntos(img, { { 9, 10 }, { 8, 11 } }, TIERRA[2])
end

-- Caja de munición (botín que sale de cajas, contenedores y coches)
local function cajaMunicion(img)
  local filas = { "bbbbbbbbb", "cddddddcb", "cdeeeedcb", "cddddddcb", "ccccccccb", "aaaaaaaaa" }
  L.pintar(img, filas, 1, 4, { a = OLIVA[1], b = OLIVA[2], c = OLIVA[3], d = OLIVA[4], e = L.col("senal", 3) })
  L.px(img, 4, 3, ME[4]); L.px(img, 7, 3, ME[4])                  -- asas
  L.contorno(img, TI[1])
end

L.construir("proyectiles", P, P, { granada, molotov, viroteVolando, viroteClavado, cajaMunicion }, {}, 0.1)

---------------------------------------------------------------- fuego
local FW, FH = 14, 18
local function llama(fase)
  return function(img)
    local r = L.azar(11 + fase * 17)
    local calor = {}
    for y = 0, FH - 1 do
      local alto = (FH - 1 - y) / (FH - 2)                        -- 0 abajo, 1 arriba
      local cx = 6.5 + math.sin(y * 0.55 + fase * 1.57) * 1.6 * alto + math.sin(fase * 1.57 + 1) * 0.4
      local ancho = 5.6 * (1 - alto) ^ 0.75 + 0.6
      for x = 0, FW - 1 do
        local u = (x + 0.5 - cx) / ancho
        local h = (1 - u * u) * (1 - alto * 0.55)
        if y >= FH - 3 then h = h * (0.75 + 0.25 * (FH - 1 - y) / 2) end   -- la base se apoya en el suelo
        calor[y * FW + x] = h
      end
    end
    -- lengüetas sueltas que suben
    for k = 1, 2 do
      local lx = math.floor(3 + r() * 8)
      local ly = math.floor(1 + ((fase + k * 2) % 4) * 1.2)
      calor[ly * FW + lx] = 0.35
      calor[(ly + 1) * FW + lx] = 0.4
    end
    for y = 0, FH - 1 do for x = 0, FW - 1 do
      local h = calor[y * FW + x] or 0
      local c
      if h > 0.78 then c = FU[5] elseif h > 0.55 then c = FU[4] elseif h > 0.3 then c = FU[3] elseif h > 0.08 then c = FU[2] end
      if c then L.px(img, x, y, c) end
    end end
    L.contorno(img, FU[1], { solo = function(x, y) return y > 4 end })
  end
end
L.construir("fuego", FW, FH, { llama(0), llama(1), llama(2), llama(3) }, { { "arder", 1, 4 } }, 0.09, { base = { 7, 17 } })

---------------------------------------------------------------- explosión
local EW = 48
local CX, CY = 24, 32

-- Racimo de bolas alrededor de (cx, cy): una central y n alrededor (deterministas por semilla).
local function racimo(cx, cy, R, n, semilla, subir)
  local r = L.azar(semilla)
  local b = { { x = cx, y = cy, r = R * 0.62 } }
  for k = 1, n do
    local a = (k / n) * math.pi * 2 + r() * 0.6
    local d = R * (0.36 + r() * 0.16)
    b[#b + 1] = { x = cx + math.cos(a) * d, y = cy + math.sin(a) * d * 0.8 - (subir or 0) * math.max(0, -math.sin(a)), r = R * (0.36 + r() * 0.14) }
  end
  return b
end

-- Pinta el racimo. color(calor, luz, borde) -> color; calor 1 en el centro del racimo, 0 en su radio R;
-- luz = sombreado de la bola de encima (-1..1, luz arriba a la izquierda); borde = está en el contorno.
local function nube(img, bolas, cx, cy, R, color)
  for y = 0, EW - 1 do for x = 0, EW - 1 do
    local px, py = x + 0.5, y + 0.5
    local dentro = nil
    for _, b in ipairs(bolas) do
      local dx, dy = px - b.x, (py - b.y) / 0.85
      if dx * dx + dy * dy <= b.r * b.r then dentro = { b = b, dx = dx, dy = dy } end
    end
    if dentro then
      local calor = 1 - math.sqrt((px - cx) ^ 2 + ((py - cy) / 0.85) ^ 2) / R
      local luz = (-dentro.dx - dentro.dy) / (dentro.b.r * 1.414)
      local c = color(calor, luz, math.sqrt(dentro.dx ^ 2 + dentro.dy ^ 2) / dentro.b.r, (cy - py) / R)
      if c then L.px(img, x, y, c) end
    end
  end end
end

local function fogonazo(img)
  nube(img, racimo(CX, CY - 3, 9, 5, 3), CX, CY - 3, 9, function(calor)
    if calor > 0.5 then return FU[5] elseif calor > 0.2 then return FU[4] else return FU[3] end
  end)
  for k = 0, 7 do                                   -- rayos
    local a = k * math.pi / 4 + 0.3
    for t = 9, 13 do
      L.px(img, math.floor(CX + math.cos(a) * t), math.floor(CY - 3 + math.sin(a) * t * 0.8), t < 11 and FU[4] or FU[3])
    end
  end
end

local function bolaFuego(R, humo, semilla, cy)
  return function(img)
    local bolas = racimo(CX, cy, R, 7, semilla, humo * 6)
    nube(img, bolas, CX, cy, R, function(calor, luz, rel, arriba)
      -- el humo sale por arriba: casquete oscuro sobre la bola de fuego
      local hay = humo > 0 and calor < 0.2 + humo * 0.45 and arriba > 0.55 - humo * 0.7
      if hay and luz > -0.2 then return HUMO[luz > 0.4 and 5 or 4] end
      if hay then return HUMO[3] end
      if calor > 0.62 then return FU[5] elseif calor > 0.4 then return FU[4] elseif calor > 0.18 then return FU[3] else return FU[2] end
    end)
    L.contorno(img, FU[1])
  end
end

local function humo(R, cy, semilla, brasas, ralo)
  return function(img)
    local r = L.azar(semilla)
    nube(img, racimo(CX, cy, R, 7, semilla, 4), CX, cy, R, function(calor, luz, rel)
      if ralo and rel > 0.55 and (math.floor(r() * 3) == 0) then return nil end
      local i = luz > 0.45 and 5 or luz > 0.05 and 4 or luz > -0.4 and 3 or 2
      if ralo then i = i + 1 end
      return HUMO[math.min(6, i)]
    end)
    if not ralo then L.contorno(img, HUMO[1]) end
    for k = 1, brasas do
      local a, t = r() * math.pi * 2, r() * R * 0.5
      L.px(img, math.floor(CX + math.cos(a) * t), math.floor(cy + math.sin(a) * t * 0.8), k % 2 == 0 and FU[3] or FU[4])
    end
  end
end

L.construir("explosion", EW, EW, {
  fogonazo,
  bolaFuego(14, 0, 5, CY - 4),
  bolaFuego(18, 0.25, 6, CY - 6),
  bolaFuego(20, 0.55, 7, CY - 8),
  humo(19, CY - 11, 8, 5, false),
  humo(17, CY - 14, 9, 1, true),
}, { { "estallar", 1, 6 } }, { 0.05, 0.06, 0.07, 0.08, 0.11, 0.13 }, { centro = { CX, CY } })
