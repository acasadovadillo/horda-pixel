-- Coche abandonado (40x64), vista 3/4 cenital, morro hacia arriba.
-- 0 berlina roja, 1 utilitario blanco sucio (portón trasero), 2 berlina calcinada.
local L = dofile(app.params.lib)
local H = L.hex
local W = 40

local function R(t) local r = {} for i, h in ipairs(t) do r[i] = H(h) end return r end
local ROJA    = L.rampa("pintura")
local BLANCA  = R{ "3b3d3e", "626664", "8a8d88", "adaea6", "c9c8bd" }
local QUEMADA = R{ "121012", "1e1a19", "2c2522", "3d332c", "514338" }
local OX = L.rampa("oxido")
local CR = L.rampa("cristal")
local MT = L.rampa("metal")
local TI = L.rampa("tinta")
local TE = L.rampa("tela")
local SA = L.rampa("saco")
local CU = L.rampa("cuero")
local GOMA = R{ "17171a", "222226", "303035", "434349" }
local PILOTO = R{ "3a0c0e", "6a1a18", "9a3228", "c45e44" }
local CENIZA = R{ "4a4642", "6a655e", "8c867c" }
local HOJA = R{ "4a3216", "7a5422", "9c7232" }

---------------------------------------------------------------- utilidades
local function span(img, y, x0, x1, c) for x = x0, x1 do L.px(img, x, y, c) end end

-- Parche a mano: filas de caracteres, solo sobre píxeles ya opacos.
local function parche(img, x, y, filas, mapa)
  for j, f in ipairs(filas) do
    for i = 1, #f do
      local ch = f:sub(i, i)
      if ch ~= "." then
        local px, py = x + i - 1, y + j - 1
        if L.opaco(img, px, py) then L.px(img, px, py, mapa[ch]) end
      end
    end
  end
end

local function lerp(a, b, t) return a + (b - a) * t end

-- Máscara de cristal (para recortar reflejos y grietas).
local function nuevaMascara() return {} end
local function marca(m, x, y) m[y * W + x] = true end
local function en(m, x, y) return m[y * W + x] end

-- Contorno selectivo: arriba/izquierda más claro, abajo/derecha oscuro, filas bajas tinta.
local function contornoSel(img, cTL, cBR, cBaj, yBaj)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) end end
  local function op(x, y) return x >= 0 and y >= 0 and x < w and y < h and s[y * w + x] end
  for y = 0, h - 1 do for x = 0, w - 1 do
    if not s[y * w + x] then
      local l, r, u, d = op(x - 1, y), op(x + 1, y), op(x, y - 1), op(x, y + 1)
      if l or r or u or d then
        local c
        if y >= yBaj then c = cBaj
        elseif (r or d) and not (l or u) and x < 20 then c = cTL
        elseif d and not (l or u or r) then c = cTL
        else c = cBR end
        img:drawPixel(x, y, c)
      end
    end
  end end
end

---------------------------------------------------------------- piezas comunes
local function cuerpo(img, p, F)
  -- F.nariz = sangrías de las primeras filas; F.cola = sangría de la fila 58; F.cintura = {y0, y1}
  for y = 4, 58 do
    local s = 0
    if y - 4 < #F.nariz then s = F.nariz[y - 3] end
    if y >= F.cintura[1] and y <= F.cintura[2] then s = 1 end
    if y == 58 then s = F.cola end
    local x0, x1 = 3 + s, 36 - s
    for x = x0, x1 do
      local c = p[4]
      if x >= 34 then c = p[2] elseif x >= 28 then c = p[3] end
      L.px(img, x, y, c)
    end
  end
  -- brillo de la línea de cintura a la izquierda, cortado por las puertas
  for y = F.cintura[1] + 1, F.cintura[2] - 1 do L.px(img, 5, y, p[5]) end
end

local function ruedasLaterales(img, tramos, plano)
  for _, t in ipairs(tramos) do
    for y = t[1], t[2] do
      L.px(img, 2, y, GOMA[3]); L.px(img, 37, y, GOMA[2])
    end
  end
  if plano then -- neumático pinchado: se aplasta y sobresale
    local t = plano
    for y = t[2], t[3] do L.px(img, t[1], y, GOMA[2]) end
  end
end

local function ruedasTraseras(img, pinchada, llantas)
  local function rueda(x0, x1, y0, y1)
    for y = y0, y1 do for x = x0, x1 do
      local c = GOMA[3]
      if y == y0 then c = GOMA[1] elseif y == y1 then c = GOMA[2] end
      if x == x0 and y > y0 then c = GOMA[4] end
      if x == x1 then c = GOMA[2] end
      L.px(img, x, y, c)
    end end
  end
  if llantas then
    for _, x in ipairs({ 6, 30 }) do
      span(img, 59, x, x + 3, OX[1]); span(img, 60, x, x + 3, MT[2])
      L.px(img, x, 60, MT[3]); L.px(img, x + 1, 59, OX[2])
    end
    return
  end
  rueda(5, 10, 59, 61)
  if pinchada then
    rueda(28, 35, 60, 61)
    span(img, 59, 29, 34, GOMA[1])
  else
    rueda(29, 34, 59, 61)
  end
end

local function retrovisores(img, p, y, falta)
  L.px(img, 2, y, p[5]); L.px(img, 3, y, p[4]); L.px(img, 2, y + 1, p[3]); L.px(img, 3, y + 1, p[3])
  if not falta then
    L.px(img, 36, y, p[3]); L.px(img, 37, y, p[2]); L.px(img, 36, y + 1, p[2]); L.px(img, 37, y + 1, p[1])
  end
end

-- cristal: rellena una fila y la marca
local function filaCristal(img, m, y, x0, x1, fn)
  for x = x0, x1 do L.px(img, x, y, fn(x, y)); marca(m, x, y) end
end

local function reflejo(img, m, d0, d1, c, inclin)
  for y = 0, 63 do for x = 0, W - 1 do
    if en(m, x, y) then
      local d = x + (y * (inclin or 1))
      if d >= d0 and d <= d1 then L.px(img, x, y, c) end
    end
  end end
end

-- Grieta en estrella desde (cx, cy)
local function grieta(img, m, cx, cy, rayos, cl, cd)
  for _, r in ipairs(rayos) do
    local x, y = cx, cy
    for k = 1, r[3] do
      x = x + r[1]; y = y + r[2]
      if en(m, math.floor(x + 0.5), math.floor(y + 0.5)) then L.px(img, x, y, cl) end
    end
  end
  for _, q in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
    if en(m, cx + q[1], cy + q[2]) then L.px(img, cx + q[1], cy + q[2], cd) end
  end
end

---------------------------------------------------------------- berlina
local function berlina(img, p, V)
  local m = nuevaMascara()
  ruedasLaterales(img, V.quemado and { { 10, 14 }, { 41, 45 } } or { { 9, 15 }, { 40, 46 } })
  ruedasTraseras(img, V.pinchada, V.quemado)
  cuerpo(img, p, { nariz = { 7, 4, 2, 1, 1 }, cola = 1, cintura = { 18, 38 } })

  -- capó: pliegues y brillo del morro
  for y = 7, 15 do L.px(img, 12, y, p[5]); L.px(img, 27, y, p[3]) end
  parche(img, 5, 5, { "pppp.", "pppp", "pp" }, { p = p[5] })
  span(img, 4, 9, 30, p[3])
  -- faros (cara superior)
  span(img, 5, 5, 8, V.quemado and TI[1] or CR[4]); span(img, 5, 31, 34, V.quemado and TI[1] or CR[3])
  span(img, 6, 5, 8, V.quemado and TI[2] or CR[3]); span(img, 6, 31, 34, V.quemado and TI[2] or CR[2])
  L.px(img, 5, 5, V.quemado and TI[1] or CR[5])
  -- rejilla del salpicadero / limpiaparabrisas
  span(img, 16, 6, 33, MT[2])

  -- parabrisas y17..24
  for y = 17, 24 do
    local t = (y - 17) / 7
    local x0, x1 = math.floor(lerp(7, 10, t) + 0.5), math.floor(lerp(32, 29, t) + 0.5)
    L.px(img, x0 - 1, y, p[5]); L.px(img, x1 + 1, y, p[2])
    filaCristal(img, m, y, x0, x1, function(x, yy)
      if V.quemado then return yy <= 18 and QUEMADA[1] or TI[2] end
      if yy <= 18 then return CR[1] end
      return CR[2]
    end)
  end
  -- techo y25..38
  for y = 25, 38 do
    for x = 10, 29 do
      local c = p[4]
      if y == 25 then c = p[5] end
      if x >= 27 or y == 38 then c = p[3] end
      L.px(img, x, y, c)
    end
  end
  L.poligono(img, { { 11, 26 }, { 19, 26 }, { 14, 31 }, { 11, 33 } }, p[5])
  -- ventanillas laterales
  for y = 25, 38 do
    filaCristal(img, m, y, 8, 9, function(x) return V.quemado and TI[2] or (x == 8 and CR[3] or CR[2]) end)
    filaCristal(img, m, y, 30, 31, function(x) return V.quemado and TI[1] or (x == 30 and CR[2] or CR[1]) end)
  end
  for _, y in ipairs({ 31, 32 }) do -- pilar B
    span(img, y, 8, 9, p[4]); span(img, y, 30, 31, p[2])
  end
  -- luneta y39..44
  for y = 39, 44 do
    local t = (y - 39) / 5
    local x0, x1 = math.floor(lerp(10, 8, t) + 0.5), math.floor(lerp(29, 31, t) + 0.5)
    L.px(img, x0 - 1, y, p[5]); L.px(img, x1 + 1, y, p[2])
    filaCristal(img, m, y, x0, x1, function(x, yy)
      if V.quemado then return TI[2] end
      if yy >= 43 then return CR[1] end
      return CR[2]
    end)
  end
  -- maletero
  span(img, 45, 8, 31, p[3])
  for y = 45, 48 do L.px(img, 6, y, p[3]); L.px(img, 33, y, p[2]) end
  span(img, 49, 5, 34, p[5])
  -- cara trasera y50..58
  for y = 50, 53 do for x = 3, 36 do
    local c = p[3]
    if x >= 33 or y == 53 then c = p[2] end
    L.px(img, x, y, c)
  end end
  -- pilotos
  local function piloto(x0)
    for y = 50, 52 do for x = x0, x0 + 5 do
      local c
      if V.quemado then c = (y == 50) and TI[2] or TI[1]
      else
        c = PILOTO[2]
        if y == 50 then c = PILOTO[3] end
        if y == 50 and x <= x0 + 1 then c = PILOTO[4] end
        local interior = (x0 < 20 and x >= x0 + 4) or (x0 > 20 and x <= x0 + 1)
        if interior then c = (y == 50) and TE[4] or TE[2] end
        if y == 52 then c = PILOTO[1] end
      end
      L.px(img, x, y, c)
    end end
  end
  piloto(4); piloto(30)
  -- matrícula
  span(img, 50, 15, 24, p[1]); span(img, 53, 4, 9, p[1]); span(img, 53, 30, 35, p[1])
  for y = 51, 54 do for x = 15, 24 do L.px(img, x, y, y == 51 and TE[4] or TE[3]) end end
  span(img, 52, 17, 18, TI[3]); span(img, 52, 20, 21, TI[3]); span(img, 53, 17, 18, TI[3]); span(img, 53, 20, 22, TI[3])
  -- paragolpes
  for y = 54, 57 do for x = 3, 36 do
    if not (y == 54 and x >= 15 and x <= 24) then
      local c = MT[3]
      if y == 54 then c = MT[4] elseif y == 57 then c = MT[2] end
      if x >= 34 then c = MT[2] end
      L.px(img, x, y, c)
    end
  end end
  span(img, 58, 4, 35, MT[1])
  L.px(img, 26, 58, TI[1]); L.px(img, 27, 58, TI[1]); L.px(img, 26, 57, MT[4])

  retrovisores(img, p, 17, V.quemado)
  -- juntas de puertas y manetas
  for _, y in ipairs({ 18, 31, 43 }) do span(img, y, 4, 7, p[3]); span(img, y, 32, 35, p[1]) end
  for _, y in ipairs({ 28, 40 }) do
    L.px(img, 4, y, p[2]); L.px(img, 5, y, p[2]); L.px(img, 4, y - 1, p[5])
    L.px(img, 33, y, p[1]); L.px(img, 34, y, p[1])
  end
  return m
end

---------------------------------------------------------------- utilitario con portón
local function utilitario(img, p, V)
  local m = nuevaMascara()
  ruedasLaterales(img, { { 8, 13 }, { 41, 47 } }, { 1, 9, 14 })
  ruedasTraseras(img, false)
  cuerpo(img, p, { nariz = { 5, 2, 1, 1 }, cola = 1, cintura = { 15, 39 } })
  span(img, 4, 7, 32, p[3])
  for y = 6, 11 do L.px(img, 11, y, p[5]); L.px(img, 28, y, p[3]) end
  parche(img, 4, 5, { "pppp", "ppp" }, { p = p[5] })
  span(img, 5, 4, 8, CR[4]); span(img, 5, 31, 35, CR[3]); span(img, 6, 4, 7, CR[3]); span(img, 6, 32, 35, CR[2])
  span(img, 12, 6, 33, MT[2])
  -- parabrisas y13..20
  for y = 13, 20 do
    local t = (y - 13) / 7
    local x0, x1 = math.floor(lerp(7, 10, t) + 0.5), math.floor(lerp(32, 29, t) + 0.5)
    L.px(img, x0 - 1, y, p[5]); L.px(img, x1 + 1, y, p[2])
    filaCristal(img, m, y, x0, x1, function(x, yy) return yy <= 14 and CR[1] or CR[2] end)
  end
  -- techo y21..43
  for y = 21, 43 do for x = 10, 29 do
    local c = p[4]
    if y == 21 then c = p[5] end
    if x >= 27 then c = p[3] end
    L.px(img, x, y, c)
  end end
  L.poligono(img, { { 12, 22 }, { 20, 22 }, { 15, 27 }, { 12, 29 } }, p[5])
  for y = 22, 42 do -- barras de techo
    L.px(img, 11, y, MT[4]); L.px(img, 28, y, MT[2])
  end
  -- bulto atado en la baca
  local fardo = {
    ".aabbbbbbbb.",
    "aabbbbbbbbbc",
    "abbbbcbbbbbc",
    "abbbbbbbbbcc",
    "abbbbbbcbbcc",
    "bbbbbbbbbccd",
    ".bbbbbbbccd.",
    "..cccccddd..",
  }
  L.pintar(img, fardo, 14, 29, { a = SA[4], b = SA[3], c = SA[2], d = SA[1] })
  for y = 29, 36 do L.px(img, 17, y, CU[3]); L.px(img, 23, y, CU[2]) end
  L.px(img, 17, 29, CU[4]); L.px(img, 23, 29, CU[3])
  -- ventanillas laterales
  for y = 21, 43 do
    filaCristal(img, m, y, 8, 9, function(x) return x == 8 and CR[3] or CR[2] end)
    filaCristal(img, m, y, 30, 31, function(x) return x == 30 and CR[2] or CR[1] end)
  end
  for _, y in ipairs({ 29, 30, 38 }) do span(img, y, 8, 9, p[4]); span(img, y, 30, 31, p[2]) end
  -- borde trasero del techo (alerón)
  span(img, 44, 8, 31, p[3]); span(img, 45, 5, 34, p[5])
  -- cara trasera: luneta vertical y47..51
  for y = 46, 53 do for x = 3, 36 do
    local c = p[3]
    if x >= 33 then c = p[2] end
    L.px(img, x, y, c)
  end end
  for y = 47, 51 do
    local x0, x1 = 8, 31
    if y == 51 then x0, x1 = 9, 30 end
    filaCristal(img, m, y, x0, x1, function(x, yy)
      if yy == 47 then return CR[1] end
      return CR[2]
    end)
  end
  span(img, 46, 8, 31, p[2])
  L.linea(img, 13, 49, 20, 51, MT[1])
  -- pilotos verticales
  for y = 47, 53 do
    for _, x0 in ipairs({ 4, 33 }) do
      for x = x0, x0 + 2 do
        local c = PILOTO[2]
        if x == x0 and y <= 49 then c = PILOTO[4] elseif y <= 49 then c = PILOTO[3] end
        if y == 53 or x == x0 + 2 then c = PILOTO[1] end
        L.px(img, x, y, c)
      end
    end
  end
  span(img, 52, 7, 32, p[3]); span(img, 53, 7, 32, p[2])
  span(img, 51, 15, 24, p[1])
  for y = 52, 54 do for x = 15, 24 do L.px(img, x, y, y == 52 and TE[4] or TE[3]) end end
  span(img, 53, 17, 18, TI[3]); span(img, 53, 20, 22, TI[3])
  for y = 54, 57 do for x = 3, 36 do
    if not (y == 54 and x >= 15 and x <= 24) then
      local c = MT[3]
      if y == 54 then c = MT[4] elseif y == 57 then c = MT[2] end
      if x >= 34 then c = MT[2] end
      L.px(img, x, y, c)
    end
  end end
  span(img, 58, 4, 35, MT[1])
  L.px(img, 28, 58, TI[1]); L.px(img, 29, 58, TI[1])
  retrovisores(img, p, 13)
  for _, y in ipairs({ 14, 29, 39 }) do span(img, y, 4, 7, p[3]); span(img, y, 32, 35, p[1]) end
  for _, y in ipairs({ 26, 36 }) do
    L.px(img, 4, y, p[2]); L.px(img, 5, y, p[2]); L.px(img, 4, y - 1, p[5])
    L.px(img, 33, y, p[1]); L.px(img, 34, y, p[1])
  end
  return m
end

---------------------------------------------------------------- desgaste
local RUST = { a = OX[4], o = OX[3], O = OX[2], d = OX[1] }

local function variante0(img)
  local p = ROJA
  local m = berlina(img, p, { pinchada = true })
  reflejo(img, m, 30, 31, CR[3], 1)
  reflejo(img, m, 32, 33, CR[4], 1)
  reflejo(img, m, 37, 37, CR[3], 1)
  reflejo(img, m, 52, 53, CR[3], 1)
  grieta(img, m, 23, 20, { { 1, -0.5, 4 }, { -1, -0.4, 6 }, { -1, 0.6, 5 }, { 1, 0.8, 4 }, { 0.3, -1, 3 } }, CR[5], TI[2])
  -- luneta reventada: se ve la bandeja y el respaldo
  parche(img, 14, 40, { "..g.gg.g..", ".giiiiiig.", "giiiiiiiig", "iiiiiiiiii", "iiiiiiiiii" }, { g = CR[4], i = TI[2], b = H("3e3833") })
  parche(img, 17, 42, { "s" }, { s = CR[3] })
  -- óxido
  parche(img, 32, 43, { "..ao", ".aoOo", "aoOOd", ".oOd" }, RUST)
  parche(img, 3, 9, { "ao", "oO", "oO", ".o" }, RUST)
  parche(img, 3, 51, { "ao.", "oOo", "OOd" }, RUST)
  parche(img, 29, 30, { "a", "o", "O", "o" }, RUST)
  parche(img, 20, 46, { "aoo", "oO." }, RUST)
  -- polvo y hojas secas
  parche(img, 22, 29, { ".pp", "ppp" }, { p = H("94604f") })
  parche(img, 24, 11, { "hH", ".hh" }, { h = HOJA[3], H = HOJA[2] })
  parche(img, 14, 35, { "hh", ".H" }, { h = HOJA[3], H = HOJA[1] })
  parche(img, 30, 47, { "hH" }, { h = HOJA[3], H = HOJA[2] })
  -- barro en el paragolpes
  parche(img, 4, 56, { ".tt..tt", "tttt.ttt" }, { t = H("4a3c2e") })
  parche(img, 28, 56, { "tt.tt", "ttttt" }, { t = H("3a3026") })
end

local function variante1(img)
  local p = BLANCA
  local m = utilitario(img, p, {})
  reflejo(img, m, 25, 26, CR[3], 1)
  reflejo(img, m, 28, 29, CR[4], 1)
  reflejo(img, m, 58, 60, CR[3], 0.4)
  -- parabrisas reventado a la izquierda: hueco con el salpicadero
  parche(img, 10, 14, { "..ee.e.", ".eiiiee", "eiiiiiie", ".eiiie", "..e.e" }, { e = CR[5], i = TI[2] })
  grieta(img, m, 16, 16, { { 1, 0.3, 9 }, { 1, -0.5, 6 }, { 0.6, 1, 4 } }, CR[4], TI[2])
  -- ventanilla trasera derecha rota
  for y = 33, 37 do L.px(img, 30, y, TI[2]); L.px(img, 31, y, TI[1]) end
  L.px(img, 30, 33, CR[4])
  -- óxido: churretes bajo la luneta y bordes
  parche(img, 8, 52, { "o", "O", "O" }, RUST)
  parche(img, 30, 52, { "o", "O", "d" }, RUST)
  parche(img, 3, 39, { "ao", "oO", "Od" }, RUST)
  parche(img, 33, 9, { ".ao", "aoO", "oOd" }, RUST)
  parche(img, 34, 48, { "aO", "Od" }, RUST)
  -- suciedad del blanco: barro y polvo
  parche(img, 3, 49, { "tt", "ttt", "tTT", "TTT" }, { t = H("7a7262"), T = H("5e5648") })
  parche(img, 31, 50, { "..tt", ".tTT", "tTTT" }, { t = H("6a6254"), T = H("4e4840") })
  parche(img, 5, 55, { "tt.ttt..tt", "TTTTTTTTTT" }, { t = H("5a5246"), T = H("40382e") })
  parche(img, 26, 55, { ".tt.ttt", "TTTTTTT" }, { t = H("5a5246"), T = H("40382e") })
  parche(img, 15, 8, { "pp..", "ppp.", ".pp" }, { p = H("9a978c") })
  parche(img, 22, 23, { "pp", "ppp" }, { p = H("9a978c") })
  parche(img, 12, 40, { "hH", ".h" }, { h = HOJA[3], H = HOJA[2] })
end

local function variante2(img)
  local p = QUEMADA
  local m = berlina(img, p, { quemado = true })
  -- interior calcinado: volante y armazones de asientos
  L.elipse(img, 13.5, 21.5, 2.5, 1.8, MT[3]); L.elipse(img, 13.5, 21.5, 1.5, 0.9, TI[1])
  L.px(img, 12, 20, MT[4])
  L.linea(img, 19, 23, 26, 23, OX[2]); L.linea(img, 10, 24, 17, 24, OX[1])
  for x = 19, 26, 2 do L.px(img, x, 22, OX[1]) end
  -- luneta: muelles del asiento trasero
  for x = 10, 29 do
    local y = (x % 3 == 0) and 41 or 42
    L.px(img, x, y, OX[2])
  end
  span(img, 43, 9, 30, OX[1])
  L.px(img, 12, 40, OX[3]); L.px(img, 24, 40, OX[3])
  -- capó oxidado: la pintura se ha quemado
  L.poligono(img, { { 8, 6 }, { 26, 5 }, { 31, 9 }, { 30, 15 }, { 12, 15 }, { 6, 12 } }, OX[2])
  L.poligono(img, { { 9, 7 }, { 20, 6 }, { 16, 11 }, { 9, 12 } }, OX[3])
  parche(img, 10, 7, { "aaa", "aa" }, RUST)
  parche(img, 22, 10, { "..dd", "dddO", ".dOO" }, RUST)
  span(img, 15, 12, 30, OX[1])
  -- techo hundido y oxidado, ceniza en los bordes
  L.poligono(img, { { 11, 26 }, { 27, 26 }, { 29, 33 }, { 25, 38 }, { 12, 37 } }, OX[2])
  L.poligono(img, { { 12, 27 }, { 20, 27 }, { 16, 31 }, { 12, 32 } }, OX[3])
  parche(img, 19, 31, { "..dd", ".dddd", "ddd", "dd" }, RUST)
  parche(img, 10, 25, { "cccc..cc", "cC" }, { c = CENIZA[3], C = CENIZA[2] })
  parche(img, 25, 37, { "CCC.", "cC" }, { c = CENIZA[2], C = CENIZA[1] })
  -- maletero y laterales
  L.poligono(img, { { 9, 46 }, { 30, 46 }, { 28, 49 }, { 11, 49 } }, OX[2])
  parche(img, 10, 46, { "aaoo", "oo" }, RUST)
  parche(img, 3, 20, { "o", "O", "O", "o", "d" }, RUST)
  parche(img, 3, 33, { "c", "C", "c" }, { c = CENIZA[2], C = CENIZA[1] })
  parche(img, 34, 24, { "Od", "dd" }, RUST)
  parche(img, 4, 44, { "aoo", "oOd" }, RUST)
  -- matrícula y paragolpes derretidos
  for y = 51, 54 do span(img, y, 15, 24, OX[1]) end
  span(img, 52, 17, 21, OX[2])
  for y = 54, 57 do span(img, y, 3, 36, QUEMADA[2]) end
  span(img, 54, 3, 36, OX[2]); span(img, 55, 4, 35, OX[1])
  parche(img, 7, 56, { "dd", "d." }, RUST)
  parche(img, 22, 56, { "ddd" }, RUST)
  span(img, 58, 4, 35, QUEMADA[1])
  parche(img, 14, 50, { "cc", "C" }, { c = CENIZA[2], C = CENIZA[1] })
end

---------------------------------------------------------------- montaje
local function fotograma(fn, p)
  return function(img)
    fn(img)
    contornoSel(img, p[2], p[1], TI[2], 59)
  end
end

L.construir("coche", 40, 64, {
  fotograma(variante0, ROJA),
  fotograma(variante1, BLANCA),
  fotograma(variante2, QUEMADA),
}, nil, nil, { base = { 20, 62 } })
