-- muro (48x40, 9 fotogramas): tramo de muralla de la base en vista 3/4, cara frontal mirando al sur
-- (el interior de la base). Se coloca cada 48 px: los fotogramas sanos y dañados casan por los lados.
--   0-2 madera: empalizada de tablas sobre postes, con travesaños, riostras, clavos y adarve de tablas.
--   3-5 chapa: chapa ondulada oxidada atornillada a postes y largueros, con tapa de chapa.
--   6-8 hormigón: bloques a soga con una hilada de sacos terreros encima.
-- En cada material: sano, dañado (agujeros, grietas, tablas que faltan, arañazos, sangre), roto (escombro bajo).
-- Cara frontal ~22 px (y 15..36), cara de arriba ~10 px (y 5..14). Luz de arriba a la izquierda.
local L = dofile(app.params.lib)
local W, H = 48, 40

local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local MAD = R({ "26180e", "3f2917", "5c3d22", "7b5631", "9a7446" })            -- madera (L.P.madera)
local MAG = R({ "261e17", "3e3328", "574937", "72614b", "8e7c60" })            -- madera vieja, agrisada
local GAL = R({ "1c1f20", "2c3031", "414746", "5a605c", "767d77", "959b92" })  -- chapa galvanizada sucia
local PIN = R({ "1a211d", "29352d", "3a4a3f", "4f6153", "687a69" })            -- chapa pintada de verde, desvaída
local OX  = R({ "301710", "52281a", "7a3f20", "9e5f30" })                       -- óxido
local ACE = R({ "121418", "1f2329", "323840", "4b535e", "6e7885", "9aa4b0" })  -- acero (L.P.metal)
local HO  = R({ "3a3a3b", "4e4e4f", "656563", "7c7b78", "93918c", "aba9a2" })  -- hormigón
local SA  = R({ "241d13", "4a3f2a", "6b5c3e", "8c7a54", "ab986e" })            -- arpillera
local ARE = R({ "3e3426", "5e5038", "7d6c4c", "9a8862" })                      -- arena y tierra
local SG  = R({ "2e070b", "520c12", "7a121a", "a31d24" })                      -- sangre
local TIN = R({ "0e0d12", "1a1920", "26252e" })                                 -- tinta

local INFO = {}
for _, r in ipairs({ MAD, MAG, GAL, PIN, OX, ACE, HO, SA, ARE, SG, TIN }) do
  for i, c in ipairs(r) do if not INFO[c] then INFO[c] = { r, i } end end
end

---------------------------------------------------------------- lienzo con repetición horizontal
local B, WRAP = {}, true
local function nuevo(wrap) B = {}; WRAP = wrap end
local function ix(x, y)
  x = math.floor(x + 0.5); y = math.floor(y + 0.5)
  if y < 0 or y >= H then return nil end
  if WRAP then x = x % W elseif x < 0 or x >= W then return nil end
  return y * W + x
end
local function S(x, y, c) local i = ix(x, y); if i and c then B[i] = c end end
local function G(x, y) local i = ix(x, y); return i and B[i] end
local function DEL(x, y) local i = ix(x, y); if i then B[i] = nil end end
local function tono(c, d)
  local inf = INFO[c]; if not inf then return c end
  local r = inf[1]; return r[math.max(1, math.min(#r, inf[2] + d))]
end
local function osc(x, y, d) local c = G(x, y); if c then S(x, y, tono(c, -(d or 1))) end end
local function rect(x, y, w, h, c) for yy = y, y + h - 1 do for xx = x, x + w - 1 do S(xx, yy, c) end end end
local function cl(r, t) return r[math.max(1, math.min(#r, t))] end

local function hash(i, j, s)
  local n = i * 374761393 + j * 668265263 + s * 1442695041
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65535
end
-- ruido de valor; px = periodo horizontal (para que case al repetir)
local function ruido(x, y, ex, ey, s, px)
  local fx, fy = x / ex, y / ey
  local i, j = math.floor(fx), math.floor(fy)
  local u, v = fx - i, fy - j
  u = u * u * (3 - 2 * u); v = v * v * (3 - 2 * v)
  local n = px and math.floor(px / ex + 0.5) or nil
  local function hh(a, b) if n then a = a % n end return hash(a, b, s) end
  local a, b, c, d = hh(i, j), hh(i + 1, j), hh(i, j + 1), hh(i + 1, j + 1)
  return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v
end

-- contorno selectivo: oscuro abajo/derecha, más claro arriba/izquierda
local function contorno()
  local s = {}
  for k, v in pairs(B) do s[k] = v end
  local function g(x, y)
    if y < 0 or y >= H then return nil end
    if WRAP then x = x % W elseif x < 0 or x >= W then return nil end
    return s[y * W + x]
  end
  for y = 0, H - 1 do for x = 0, W - 1 do
    if not s[y * W + x] then
      local c, claro = g(x - 1, y) or g(x, y - 1), false
      if not c then c = g(x + 1, y) or g(x, y + 1); claro = true end
      if c then
        local inf = INFO[c]; local r = inf and inf[1] or TIN
        if r == SG then r = TIN end
        B[y * W + x] = claro and r[2] or r[1]
      end
    end
  end end
end

local function volcar(img) for k, c in pairs(B) do img:drawPixel(k % W, k // W, c) end end

-- vetas verticales de 2-4 px dentro de una columna
local function vetaV(x, y0, y1, c, r, dens)
  local y = y0 + math.floor(r() * 3)
  while y <= y1 do
    if r() < dens then
      local l = 2 + math.floor(r() * 3)
      for k = 0, l - 1 do if y + k <= y1 then S(x, y + k, c) end end
      y = y + l + 2 + math.floor(r() * 3)
    else y = y + 2 end
  end
end
local function vetaH(y, x0, x1, c, r, dens)
  local x = x0 + math.floor(r() * 3)
  while x <= x1 do
    if r() < dens then
      local l = 2 + math.floor(r() * 4)
      for k = 0, l - 1 do if x + k <= x1 then S(x + k, y, c) end end
      x = x + l + 2 + math.floor(r() * 4)
    else x = x + 3 end
  end
end

-- sangre: mano ensangrentada arrastrada hacia abajo (palma y cuatro dedos que se cortan) y gotas
local function restregon(x0, y0, largo, r)
  local palma = { { 1, 0 }, { 2, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 }, { 3, 1 }, { 0, 2 }, { 1, 2 }, { 2, 2 }, { 3, 2 } }
  for _, p in ipairs(palma) do if G(x0 + p[1], y0 + p[2]) then S(x0 + p[1], y0 + p[2], SG[2]) end end
  S(x0 + 1, y0, SG[3]); S(x0 + 1, y0 + 1, SG[4]); S(x0 + 2, y0 + 1, SG[3])
  for k = 0, 3 do
    local x = x0 + k
    local l = largo - math.floor(hash(k, 1, x0 + y0) * 6) - ((k == 0 or k == 3) and 2 or 0)
    for y = y0 + 3, y0 + 3 + l do
      if G(x, y) and hash(x, y, 5) > 0.12 then S(x, y, (y - y0 < l * 0.5) and SG[2] or SG[1]) end
    end
    if k == 1 then S(x, y0 + 4 + l, SG[2]); S(x, y0 + 6 + l, SG[1]) end
  end
end
-- agujero con fondo: dentro oscuro, los cantos de abajo/derecha del hueco reciben luz (grosor del material),
-- y alrededor un labio roto, claro arriba a la izquierda
local function hueco(cx, cy, rx, ry, sem, canto, claro, oscuro)
  local den = {}
  local function k(x, y) return y * 1000 + x + 500 end
  for y = math.floor(cy - ry - 2), math.ceil(cy + ry + 2) do for x = math.floor(cx - rx - 2), math.ceil(cx + rx + 2) do
    local d = ((x + 0.5 - cx) / rx) ^ 2 + ((y + 0.5 - cy) / ry) ^ 2 + (hash(x, y, sem) - 0.5) * 0.55
    if d < 1 then den[k(x, y)] = true end
  end end
  for y = math.floor(cy - ry - 3), math.ceil(cy + ry + 3) do for x = math.floor(cx - rx - 3), math.ceil(cx + rx + 3) do
    if den[k(x, y)] then
      if not den[k(x, y + 1)] or not den[k(x + 1, y)] then S(x, y, canto)
      elseif not den[k(x, y - 1)] or not den[k(x - 1, y)] then S(x, y, TIN[1])
      else S(x, y, TIN[2]) end
    elseif G(x, y) and (den[k(x + 1, y)] or den[k(x, y + 1)]) then S(x, y, claro)
    elseif G(x, y) and (den[k(x - 1, y)] or den[k(x, y - 1)]) and oscuro then S(x, y, oscuro) end
  end end
end
local function salpicar(cx, cy, n, r)
  for _ = 1, n do
    local x, y = cx + math.floor((r() - 0.5) * 7), cy + math.floor((r() - 0.5) * 5)
    if G(x, y) then S(x, y, r() < 0.5 and SG[2] or SG[3]) end
  end
end
-- arañazos de zarpa: tres trazos paralelos que bajan en diagonal suave (cruzan tablas y ondas)
local function zarpazo(x0, y0, largo, claro, r)
  for k = 0, 2 do
    for i = 0, largo - (k == 1 and 0 or 1) do
      local x, y = x0 + i + k, y0 + k * 2 + math.floor(i * 0.55)
      if G(x, y) then S(x, y, claro(G(x, y))) end
    end
  end
end

---------------------------------------------------------------- escombro (para los tramos rotos)
-- montón de tierra y polvo bajo a lo largo de todo el ancho
local function monton(pal, semilla, alto)
  for x = 0, W - 1 do
    local h = math.floor(1 + ruido(x, 0, 6, 1, semilla) * alto + (ruido(x, 3, 2.5, 1, semilla + 1) - 0.5) * 2)
    if x == 0 or x == W - 1 then h = math.max(1, h - 1) end
    for k = 0, h - 1 do
      local y = 36 - k
      local t = (k == h - 1) and 4 or (k == h - 2 and 3 or 2)
      if hash(x, y, semilla) < 0.12 then t = t - 1 end
      S(x, y, cl(pal, t))
    end
  end
end
-- tabla tumbada en el suelo: cara de arriba (2 filas) y canto delantero (1 fila)
local function tablaSuelo(x0, y0, x1, y1, pal, r, rota)
  local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  for i = 0, n do
    local t = i / math.max(1, n)
    local x = math.floor(x0 + (x1 - x0) * t + 0.5)
    local y = math.floor(y0 + (y1 - y0) * t + 0.5)
    local ext = (i == 0 or i == n)
    S(x, y, pal[ext and 4 or 5]); S(x, y + 1, pal[(i % 5 == 2) and 3 or 4]); S(x, y + 2, pal[2])
  end
  -- astillas en la punta rota
  if rota then
    S(x1 + 1, y1, pal[5]); S(x1 + 1, y1 + 1, pal[3]); S(x1 + 2, y1 + 1, pal[5])
  end
end
-- trozo de bloque: caja con cara de arriba, frontal y lado derecho en sombra
local function trozo(x, y, w, h, d, pal, r)
  for yy = 0, d - 1 do for xx = 0, w - 1 do
    if not ((xx == 0 or xx == w - 1) and yy == 0 and r() < 0.6) then
      S(x + xx + (d - 1 - yy) // 2, y + yy, pal[(xx == 0) and 6 or 5])
    end
  end end
  for yy = 0, h - 1 do for xx = 0, w - 1 do
    local t = 4
    if xx == w - 1 then t = 3 end
    if yy == h - 1 then t = t - 1 end
    S(x + xx, y + d + yy, pal[t])
  end end
end

---------------------------------------------------------------- MADERA
local TABLAS = { MAD, MAD, MAD, MAG, MAD, MAD, MAG, MAD }
local POSTES_M = { 10, 34 }
local function pTabla(i) return TABLAS[(i % 8) + 1] end

local function madera(estado)
  nuevo(estado < 2)
  if estado == 2 then
    local r = L.azar(71)
    monton(ARE, 5, 2)
    -- poste caído, más grueso, debajo de todo
    for x = 5, 30 do
      local y = 31 + math.floor((x - 5) * 0.08 + 0.5)
      S(x, y, MAD[5]); S(x, y + 1, MAD[4]); S(x, y + 2, MAD[4]); S(x, y + 3, MAD[2])
      if x % 4 == 1 then S(x, y + 1, MAD[3]) end
    end
    S(4, 31, MAD[3]); S(4, 32, MAD[4]); S(4, 33, MAD[4]); S(4, 34, MAD[2]); S(5, 32, MAD[2])   -- testa
    S(31, 33, MAD[5]); S(32, 33, MAD[4]); S(31, 34, MAD[3])                                   -- punta astillada
    -- tablas de la empalizada tumbadas y partidas
    tablaSuelo(1, 33, 14, 34, MAG, r, true)
    tablaSuelo(17, 30, 33, 32, MAD, r, true)
    tablaSuelo(24, 33, 38, 34, MAD, r, false)
    tablaSuelo(35, 31, 46, 32, MAG, r, true)
    tablaSuelo(8, 29, 19, 30, MAD, r, true)
    -- astillas, clavos y trozos sueltos
    for k = 1, 14 do
      local x, y = 2 + math.floor(r() * 44), 33 + math.floor(r() * 3)
      local c = r() < 0.6 and MAD[5] or MAG[5]
      S(x, y, c); if r() < 0.6 then S(x + 1, y, MAD[3]) end
    end
    for k = 1, 5 do S(3 + math.floor(r() * 42), 32 + math.floor(r() * 4), ACE[4]) end
    -- sangre en un madero
    S(21, 30, SG[3]); S(22, 30, SG[2]); S(23, 31, SG[2]); S(38, 31, SG[2])
    contorno()
    return
  end
  -------------------------------------------------- empalizada de atrás (puntas que asoman sobre el adarve)
  for i = 0, 7 do
    local x0 = i * 6 + 3
    for y = 2, 8 do for dx = 0, 4 do
      local ok = true
      if y == 2 then ok = dx == 2 elseif y == 3 then ok = dx >= 1 and dx <= 3 end
      if ok then
        local t = 3
        if dx == 0 or (y == 3 and dx == 1) or (y == 2) then t = 4 end
        if dx >= 3 then t = 2 end
        if y == 8 then t = 2 end
        S(x0 + dx, y, MAG[t])
      end
    end end
    for y = 4, 8 do S(x0 + 5, y, MAG[1]) end
  end
  -------------------------------------------------- adarve: tablas a lo largo del muro (cara de arriba)
  local r = L.azar(11)
  for x = 0, W - 1 do
    S(x, 9, MAD[2])                              -- sombra al pie de las puntas
    S(x, 10, MAD[5]); S(x, 11, MAD[4])           -- tabla de atrás
    S(x, 12, MAD[2])                             -- junta
    S(x, 13, MAD[4]); S(x, 14, MAD[4])           -- tabla de delante
  end
  vetaH(11, 0, W - 1, MAD[3], r, 0.35)
  vetaH(14, 0, W - 1, MAD[3], r, 0.35)
  vetaH(13, 0, W - 1, MAD[5], r, 0.25)
  for _, j in ipairs({ { 10, 6 }, { 10, 30 }, { 13, 18 }, { 13, 42 } }) do
    S(j[2], j[1], MAD[1]); S(j[2], j[1] + 1, MAD[2])
    S(j[2] - 1, j[1], TIN[3]); S(j[2] + 1, j[1] + 1, TIN[3])   -- clavos a cada lado de la junta
  end
  -------------------------------------------------- tablas verticales de la cara frontal
  for i = 0, 7 do
    local x0 = i * 6
    local p = pTabla(i)
    local rr = L.azar(30 + i)
    for y = 15, 36 do
      for dx = 0, 4 do
        local t = 3
        if dx == 0 then t = 4 elseif dx == 4 then t = 2 end
        if y == 15 then t = (dx == 4) and 3 or 5 end           -- testa de la tabla, vista desde arriba
        if y == 16 and dx < 4 then t = 4 end
        S(x0 + dx, y, p[t])
      end
      S(x0 + 5, y, (y == 15) and MAD[2] or TIN[3])
    end
    for dx = 2, 3 do vetaV(x0 + dx, 17, 35, p[2], rr, 0.16) end
    vetaV(x0 + 1, 17, 30, p[4], rr, 0.12)
    -- nudo
    if i % 3 == 1 then local ky = 24 + (i * 5) % 6; S(x0 + 2, ky, p[1]); S(x0 + 3, ky, p[2]); S(x0 + 2, ky - 1, p[4]) end
    -- suciedad abajo (salpicaduras de barro)
    for y = 32, 36 do for dx = 0, 4 do
      if ruido(x0 + dx, y, 3, 2, 9, W) + (y - 32) * 0.12 > 0.72 then osc(x0 + dx, y, 1) end
    end end
  end
  -------------------------------------------------- postes (delante de las tablas)
  for _, px in ipairs(POSTES_M) do
    for y = 11, 36 do
      for dx = 0, 3 do
        local t = ({ 5, 4, 3, 2 })[dx + 1]
        if y == 11 then t = (dx == 3) and 4 or 5 elseif y == 12 then t = (dx == 3) and 3 or 4 end   -- cabeza
        if y == 13 then t = t - 1 end
        if y >= 33 then t = t - 1 end
        S(px + dx, y, MAD[math.max(1, t)])
      end
      if y >= 13 then osc(px + 4, y, 1) end                    -- sombra del poste sobre las tablas
    end
    local rr = L.azar(px)
    vetaV(px + 1, 14, 35, MAD[3], rr, 0.3)
    vetaV(px + 2, 14, 35, MAD[2], rr, 0.25)
  end
  -------------------------------------------------- riostras en diagonal entre los travesaños
  local function riostra(xa, ya, xb, yb)
    for x = xa, xb do
      local y = math.floor(ya + (yb - ya) * (x - xa) / (xb - xa) + 0.5)
      S(x, y - 1, MAD[5]); S(x, y, MAD[4]); S(x, y + 1, MAD[3])
      osc(x, y + 2, 1)
    end
  end
  riostra(14, 28, 33, 23)
  riostra(38, 23, 57, 28)
  -------------------------------------------------- travesaños horizontales (sobre postes y tablas)
  for _, ty in ipairs({ 19, 30 }) do
    for x = 0, W - 1 do
      S(x, ty, MAD[5]); S(x, ty + 1, MAD[4]); S(x, ty + 2, MAD[3])
      osc(x, ty + 3, 1)
    end
    vetaH(ty + 1, 0, W - 1, MAD[3], r, 0.3)
    for i = 0, 7 do S(i * 6 + 2, ty + 1, TIN[3]) end                -- clavos
    for _, px in ipairs(POSTES_M) do                                -- pernos en los postes
      S(px + 1, ty + 1, ACE[3]); S(px + 2, ty + 1, ACE[2]); S(px + 1, ty, ACE[5])
    end
  end
  -- clavos de las riostras y un herraje con óxido
  S(15, 27, TIN[3]); S(32, 23, TIN[3]); S(39, 23, TIN[3]); S(56, 27, TIN[3])
  S(2, 21, OX[2]); S(2, 22, OX[1])

  if estado == 1 then
    local rd = L.azar(23)
    -- tabla 3 arrancada entre los travesaños: hueco oscuro con la empalizada de atrás
    local hx = 18
    for y = 22, 29 do for dx = 0, 5 do
      local borde = (y == 22 and (dx == 1 or dx == 4)) or (y == 29 and (dx == 2 or dx == 3))
      if not borde then S(hx + dx, y, (dx == 2 or dx == 5) and TIN[1] or ((dx < 2) and MAG[1] or TIN[2])) end
    end end
    S(hx + 1, 22, MAD[5]); S(hx + 4, 22, MAD[4]); S(hx + 2, 29, MAD[5]); S(hx + 3, 29, MAD[4])  -- astillas
    S(hx, 23, MAD[4]); S(hx, 28, MAD[4])
    -- tabla 1 partida arriba: falta la punta, astillada
    for y = 15, 18 do for dx = 0, 4 do
      local corte = 17 + ((dx * 2) % 3) - 1
      if y < corte then
        S(6 + dx, y, (y < 14 + 2) and nil or TIN[2])
        if y <= 15 then DEL(6 + dx, y) end
      end
    end end
    for dx = 0, 4 do
      local corte = 17 + ((dx * 2) % 3) - 1
      for y = 15, corte - 1 do S(6 + dx, y, (y == 15) and MAD[1] or MAG[2]) end
      S(6 + dx, corte, MAD[5])
    end
    -- agujero reventado desde fuera en las tablas 6 y 7 (bajo el travesaño): astillas hacia dentro
    hueco(42, 26, 3.4, 2.8, 3, MAD[3], MAD[5], MAD[2])
    S(38, 25, MAD[5]); S(45, 29, MAD[5]); S(41, 29, MAD[4])
    -- riostra rota en el primer tramo: le falta el trozo central
    for x = 22, 25 do for y = 23, 29 do
      local c = G(x, y)
      if c and (INFO[c][1] == MAD) and y >= 24 and y <= 28 then
        local yy = math.floor(28 + (23 - 28) * (x - 14) / 19 + 0.5)
        if math.abs(y - yy) <= 1 then S(x, y, pTabla(3)[3]) end
      end
    end end
    S(21, 25, MAD[5]); S(26, 24, MAD[5])
    -- arañazos de zarpa en la madera (madera clara al aire)
    zarpazo(27, 17, 9, function(c) return MAD[5] end, rd)
    zarpazo(1, 23, 6, function(c) return MAD[5] end, rd)
    -- sangre: mano arrastrada por la tabla y el travesaño, gotas
    restregon(30, 18, 11, rd)
    salpicar(31, 33, 5, rd)
    salpicar(13, 20, 3, rd)
    -- tabla del adarve partida
    for x = 25, 28 do S(x, 13, TIN[2]); S(x, 14, TIN[2]) end
    S(24, 13, MAD[5]); S(29, 14, MAD[5]); S(29, 13, MAD[3])
    -- punta de la empalizada de atrás rota
    DEL(29, 2); DEL(28, 3); DEL(29, 3); DEL(30, 3); S(28, 4, MAG[4]); S(29, 4, MAG[2]); S(30, 4, MAG[4])
  end
  contorno()
end

---------------------------------------------------------------- CHAPA
local POSTES_C = { 10, 34 }
local function onda(x) return ({ 5, 4, 3, 2 })[(x % 4) + 1] end

local function chapa(estado)
  nuevo(estado < 2)
  if estado == 2 then
    local r = L.azar(41)
    monton(ARE, 17, 2)
    -- chapas arrugadas tiradas: franjas de ondas en diagonal
    local function chapaSuelo(x0, y0, w, d, pal, inc)
      for yy = 0, d - 1 do for xx = 0, w - 1 do
        local x, y = x0 + xx + math.floor(yy * inc), y0 + yy
        local t = onda(xx + yy)
        if yy == d - 1 then t = 2 end
        if hash(x, y, 7) < 0.15 then t = t - 1 end
        S(x, y, cl(pal, t + 1))
      end end
    end
    chapaSuelo(3, 30, 15, 4, GAL, 0.5)
    chapaSuelo(24, 29, 13, 5, PIN, -0.4)
    chapaSuelo(15, 32, 12, 3, GAL, 0.0)
    chapaSuelo(36, 32, 9, 3, PIN, 0.6)
    -- óxido en los trozos
    for y = 28, 36 do for x = 0, W - 1 do
      local c = G(x, y)
      if c and (INFO[c][1] == GAL or INFO[c][1] == PIN) and ruido(x, y, 3, 2, 31) > 0.62 then
        S(x, y, OX[math.max(1, math.min(4, INFO[c][2] - 1))])
      end
    end end
    -- larguero doblado y poste tumbado
    for x = 8, 30 do
      local y = 30 + ((x < 19) and math.floor((19 - x) * 0.25) or 0)
      S(x, y, ACE[5]); S(x, y + 1, ACE[3]); S(x, y + 2, ACE[1])
    end
    for x = 30, 44 do S(x, 34, ACE[4]); S(x, 35, ACE[2]) end
    S(29, 34, ACE[5]); S(29, 35, ACE[3])
    -- tornillos sueltos
    for k = 1, 6 do S(3 + math.floor(r() * 42), 33 + math.floor(r() * 3), ACE[6]) end
    S(20, 33, SG[3]); S(21, 33, SG[2]); S(27, 31, SG[2])
    contorno()
    return
  end
  -------------------------------------------------- tapa de chapa encima (ondas de norte a sur)
  -- pasarela de planchas lisas de acero (cara de arriba), con soldaduras y remaches
  for y = 5, 14 do for x = 0, W - 1 do
    local t = 4
    if y == 5 then t = 2 elseif y == 6 then t = 3 end
    if y == 13 then t = 5 end
    if y == 14 then t = 6 end                                   -- canto doblado, al sol
    if t == 4 and ruido(x, y, 5, 3, 21, W) > 0.68 then t = 5 end
    S(x, y, GAL[t])
  end end
  for _, p in ipairs({ { 3, 12 }, { 4, 12 }, { 4, 11 }, { 28, 6 }, { 29, 6 }, { 44, 13 }, { 45, 13 }, { 45, 12 } }) do S(p[1], p[2], OX[3]) end
  S(4, 13, OX[2]); S(29, 7, OX[2]); S(45, 14, OX[2])
  for _, sx in ipairs({ 16, 40 }) do
    for y = 6, 13 do S(sx, y, GAL[2]); S(sx + 1, y, GAL[5]) end
    S(sx - 2, 8, GAL[6]); S(sx - 2, 11, GAL[6]); S(sx + 3, 8, GAL[6]); S(sx + 3, 11, GAL[6])
    S(sx - 2, 9, GAL[2]); S(sx - 2, 12, GAL[2]); S(sx + 3, 9, GAL[2]); S(sx + 3, 12, GAL[2])
  end
  -------------------------------------------------- cara frontal: dos chapas onduladas por tramo
  for y = 15, 36 do for x = 0, W - 1 do
    local pal = (x < 24) and GAL or PIN
    local t = onda(x)
    if y == 15 then t = 1 end                                   -- sombra bajo el canto
    if y == 16 then t = (x % 4 < 2) and 4 or 2 end              -- cresta ondulada del borde
    if y == 36 then t = t - 1 end
    S(x, y, cl(pal, t))
  end end
  -- solape entre chapas: canto claro y sombra
  for y = 15, 36 do S(23, y, PIN[1]); S(24, y, PIN[5]); S(47, y, GAL[1]); S(0, y, GAL[6]) end
  -- abolladuras suaves
  for _, d in ipairs({ { 6, 26 }, { 30, 21 }, { 43, 31 } }) do
    S(d[1], d[2], tono(G(d[1], d[2]), -1)); S(d[1] + 1, d[2], tono(G(d[1] + 1, d[2]), -1))
    S(d[1], d[2] + 1, tono(G(d[1], d[2] + 1), 1))
  end
  -------------------------------------------------- óxido en manchas, más abajo y en los solapes
  for y = 16, 36 do for x = 0, W - 1 do
    local c = G(x, y)
    local n = ruido(x, y, 6, 4, 13, W) * 0.85 + ruido(x, y, 3, 2, 14, W) * 0.15
    local bias = (y > 16) and ((y - 16) / 20) ^ 3 * 0.3 or 0.0
    if math.abs(x - 23.5) < 2.5 or x < 2 or x > 45 then bias = bias + 0.08 end
    if c and n + bias > 0.8 then
      local i = INFO[c][2]
      S(x, y, OX[math.max(1, math.min(3, i - 2))])
    end
  end end
  -------------------------------------------------- postes de acero y largueros atornillados
  for _, px in ipairs(POSTES_C) do
    for y = 12, 36 do
      local t = ({ 5, 4, 3 })
      for dx = 0, 2 do
        local tt = t[dx + 1]
        if y == 12 then tt = 6 end
        if y >= 34 then tt = tt - 1 end
        S(px + dx, y, ACE[tt])
      end
      osc(px + 3, y, 1)
    end
  end
  for _, ty in ipairs({ 18, 31 }) do
    for x = 0, W - 1 do
      S(x, ty, ACE[5]); S(x, ty + 1, ACE[3])
      osc(x, ty + 2, 1)
    end
    for x = 2, W - 1, 6 do S(x, ty + 1, ACE[6]); S(x, ty + 2, OX[2]) end   -- tornillos con churrete
    for _, px in ipairs(POSTES_C) do S(px + 1, ty, ACE[6]); S(px + 1, ty + 1, ACE[1]) end
  end
  -- churretes de óxido desde el canto de arriba
  for _, x in ipairs({ 5, 18, 29, 42 }) do
    local l = 4 + (x * 7) % 5
    for y = 17, 17 + l do local c = G(x, y); if c and INFO[c][1] ~= ACE then S(x, y, OX[(y < 17 + l // 2) and 2 or 1]) end end
  end
  -- churretes de óxido bajo los tornillos de abajo
  for x = 2, W - 1, 12 do for y = 34, 36 do S(x, y, OX[2]) end end
  for x = 14, W - 1, 24 do for y = 21, 25 do S(x, y, (y < 23) and OX[3] or OX[2]) end end

  if estado == 1 then
    local rd = L.azar(57)
    -- boquete arrancado: chapa rasgada con labios doblados hacia dentro
    hueco(18, 25, 4.0, 3.3, 9, GAL[3], GAL[6], GAL[2])
    -- dientes de chapa doblados hacia dentro (claros)
    S(15, 22, GAL[6]); S(16, 23, GAL[5]); S(21, 21, GAL[6]); S(21, 22, GAL[5]); S(14, 27, GAL[5]); S(22, 28, GAL[4])
    S(18, 29, GAL[6]); S(19, 30, GAL[5])
    -- chapa de la derecha medio despegada: esquina doblada arriba
    for y = 15, 17 do for x = 44 - (y - 15), 47 do DEL(x, y) end end
    S(42, 16, PIN[5]); S(43, 17, PIN[5]); S(44, 18, PIN[4]); S(43, 16, PIN[3]); S(44, 17, PIN[2])
    -- abolladura grande de golpes
    for y = 23, 28 do for x = 34, 40 do
      local d = ((x - 37) / 3) ^ 2 + ((y - 25.5) / 2.5) ^ 2
      if d < 1 and G(x, y) and INFO[G(x, y)][1] ~= ACE then S(x, y, tono(G(x, y), (x < 37) and -1 or 1)) end
    end end
    -- arañazos brillantes en la chapa
    zarpazo(28, 22, 8, function(c) return GAL[6] end, rd)
    zarpazo(3, 20, 7, function(c) return GAL[6] end, rd)
    -- sangre
    restregon(8, 22, 12, rd)
    salpicar(19, 33, 6, rd)
    salpicar(38, 20, 3, rd)
    -- tapa abollada y con un tornillo saltado
    for x = 30, 33 do S(x, 10, GAL[2]) end
    S(29, 11, GAL[6]); S(34, 9, GAL[6])
  end
  contorno()
end

---------------------------------------------------------------- HORMIGÓN + SACOS
local LX, LY, LZ = -0.45, -0.72, 0.53
do local n = math.sqrt(LX * LX + LY * LY + LZ * LZ); LX, LY, LZ = LX / n, LY / n, LZ / n end
-- saco terrero: superelipse sombreada por normales; dx con repetición horizontal
local function saco(cx, cy, a, b, sem, roto)
  local p = 2.7
  local function dxw(x) local d = x - cx; if WRAP then d = (d + W / 2) % W - W / 2 end return d end
  local function f(x, y)
    local dx = dxw(x) / a
    local dy = (y - cy - 0.8 * dx * dx) / b
    if dy > 0 then dy = dy / 0.9 end
    return math.abs(dx) ^ p + math.abs(dy) ^ p
  end
  local function h(x, y)
    local v = f(x, y)
    if v >= 1 then return 0 end
    return (1 - v) ^ 0.5 + (ruido(x, y, 2.6, 1.8, sem) - 0.5) * 0.07
  end
  for y = math.floor(cy - b - 2), math.ceil(cy + b + 2) do
    for x = math.floor(cx - a - 2), math.ceil(cx + a + 2) do
      local px, py = x + 0.5, y + 0.5
      local v = f(px, py)
      if v <= 1.22 and v > 1 then S(x, y, SA[1])
      elseif v <= 1 then
        local e, Hs = 0.6, 2.4
        local gx = (h(px + e, py) - h(px - e, py)) / (2 * e) * Hs
        local gy = (h(px, py + e) - h(px, py - e)) / (2 * e) * Hs
        local nx, ny, nz = -gx, -gy, 1
        local n = math.sqrt(nx * nx + ny * ny + nz * nz)
        local d = (nx * LX + ny * LY + nz * LZ) / n
        local t
        if d > 0.93 then t = 5 elseif d > 0.74 then t = 4 elseif d > 0.42 then t = 3 else t = 2 end
        S(x, y, SA[t])
      end
    end
  end
  -- costura y boca atada
  local sx = cx - a + 2
  for y = math.floor(cy - b + 2), math.floor(cy + b - 1) do
    if y % 2 == 0 then local c = G(sx, y); if c and INFO[c][1] == SA and INFO[c][2] > 2 then S(sx, y, tono(c, -1)) end end
  end
  local bx = cx + a - 2
  S(bx, cy, SA[2]); S(bx - 1, cy - 1, SA[2]); S(bx - 1, cy + 1, SA[2])
end

local function bloques(estado)
  -- hiladas: mortero en 16, 21, 26, 31; bloques de 4 filas; zócalo sucio en 36
  local r = L.azar(5)
  for y = 15, 36 do for x = 0, W - 1 do
    local fila = (y - 16) % 5
    local hilada = (y - 16) // 5
    local t
    if y == 15 then t = 4                       -- canto de arriba
    elseif fila == 0 then t = 2                  -- tendel
    else
      local off = (hilada % 2 == 0) and 0 or 6
      local bx = (x + off) % 12
      local id = ((x + off) // 12) % 4 + hilada * 4
      if bx == 11 then t = 2                     -- llaga
      else
        t = (hash(id, 1, 77) < 0.35) and 3 or 4
        if fila == 1 then t = t + 1 end
        if bx == 10 then t = t - 1 end
        if bx == 0 and fila > 1 then t = math.min(5, t + 0) end
      end
    end
    if y >= 35 then t = t - 1 end
    S(x, y, HO[math.max(1, math.min(6, t))])
  end end
  -- moteado en manchas de 2 px y poros
  for k = 1, 40 do
    local x, y = math.floor(r() * W), 17 + math.floor(r() * 18)
    local c = G(x, y)
    if c and INFO[c][2] >= 3 then
      local d = (r() < 0.5) and -1 or 1
      if (y - 16) % 5 ~= 0 then S(x, y, tono(c, d)); if r() < 0.5 then S(x + 1, y, tono(c, d)) end end
    end
  end
  -- suciedad y verdín en el zócalo
  for y = 30, 36 do for x = 0, W - 1 do
    if ruido(x, y, 4, 2, 8, W) + (y - 30) * 0.06 > 0.75 then osc(x, y, 1) end
  end end
  -- churretes desde los sacos
  for _, x in ipairs({ 7, 29, 40 }) do for y = 16, 21 do if (y - 16) % 5 ~= 0 then osc(x, y, 1) end end end
end

local function hormigon(estado)
  nuevo(estado < 2)
  if estado == 2 then
    local r = L.azar(93)
    monton(HO, 3, 2)
    -- arena derramada de los sacos
    for x = 0, W - 1 do
      local h = math.floor(ruido(x, 1, 7, 1, 44) * 3)
      for k = 0, h - 1 do S(x, 36 - k - 1, ARE[(k == h - 1) and 4 or 3]) end
    end
    -- trozos de bloque
    trozo(3, 30, 7, 3, 3, HO, r)
    trozo(15, 32, 5, 2, 2, HO, r)
    trozo(22, 29, 9, 4, 3, HO, r)
    trozo(34, 31, 6, 3, 2, HO, r)
    trozo(42, 32, 4, 2, 2, HO, r)
    -- sacos reventados y aplastados
    for _, s in ipairs({ { 11, 33.5, 5.5, 2.0 }, { 37, 34, 5.0, 1.8 } }) do
      for y = math.floor(s[2] - s[4] - 1), math.ceil(s[2] + s[4] + 1) do
        for x = math.floor(s[1] - s[3] - 1), math.ceil(s[1] + s[3] + 1) do
          local dx, dy = (x + 0.5 - s[1]) / s[3], (y + 0.5 - s[2]) / s[4]
          local v = dx * dx + dy * dy
          if v <= 1 then S(x, y, SA[(dy < -0.3) and 4 or ((dy > 0.4) and 2 or 3)])
          elseif v <= 1.35 then S(x, y, SA[1]) end
        end
      end
    end
    S(9, 31, ARE[4]); S(10, 31, ARE[3]); S(40, 32, ARE[4])
    -- trozos pequeños y polvo
    for k = 1, 16 do
      local x, y = 1 + math.floor(r() * 46), 32 + math.floor(r() * 4)
      S(x, y, HO[(r() < 0.5) and 5 or 4]); S(x + 1, y, HO[3])
    end
    S(26, 33, SG[2]); S(27, 33, SG[3]); S(28, 34, SG[2])
    contorno()
    return
  end
  bloques(estado)
  -- cara de arriba: canto de hormigón y dos filas de sacos al tresbolillo
  for x = 0, W - 1 do S(x, 14, HO[5]); S(x, 13, HO[4]) end
  for _, x in ipairs({ 0, 12, 24, 36 }) do saco(x + 0.5, 6.6, 6.6, 3.5, 200 + x) end
  for _, x in ipairs({ 6, 18, 30, 42 }) do saco(x + 0.5, 11.0, 6.7, 3.7, 300 + x) end
  -- sombra de los sacos sobre el canto
  for x = 0, W - 1 do if G(x, 15) and INFO[G(x, 15)][1] == HO then S(x, 15, (ruido(x, 0, 3, 1, 4, W) > 0.5) and HO[3] or HO[4]) end end

  if estado == 1 then
    local rd = L.azar(61)
    -- grieta escalonada que baja por las juntas
    local gr = { { 33, 16 }, { 33, 17 }, { 34, 18 }, { 34, 19 }, { 35, 20 }, { 35, 21 }, { 36, 22 }, { 36, 23 }, { 37, 24 },
      { 38, 25 }, { 38, 26 }, { 39, 27 }, { 39, 28 }, { 40, 29 }, { 41, 30 }, { 41, 31 } }
    for _, p in ipairs(gr) do S(p[1], p[2], HO[1]); if G(p[1] - 1, p[2]) and INFO[G(p[1] - 1, p[2])][2] > 2 then S(p[1] - 1, p[2], HO[5]) end end
    S(36, 21, HO[1]); S(37, 21, HO[2]); S(42, 32, HO[2])
    -- bloque reventado: falta media pieza, se ve el hueco y el árido
    -- desconchado alrededor (árido al aire) y el hueco
    for y = 21, 30 do for x = 6, 20 do
      local d = ((x + 0.5 - 13) / 6.2) ^ 2 + ((y + 0.5 - 25.5) / 4.3) ^ 2 + (hash(x, y, 2) - 0.5) * 0.5
      if d < 1 and G(x, y) then S(x, y, (hash(x, y, 4) < 0.3) and HO[2] or HO[3]) end
    end end
    hueco(13, 25.5, 3.6, 2.6, 2, HO[4], HO[5], HO[2])
    -- esquinas desconchadas
    for _, p in ipairs({ { 2, 17 }, { 3, 17 }, { 26, 32 }, { 27, 32 }, { 26, 33 } }) do S(p[1], p[2], HO[2]) end
    S(2, 18, HO[6]); S(27, 33, HO[5])
    -- saco reventado: arena que cae por la cara del muro
    for _, p in ipairs({ { 20, 10, SA[1] }, { 21, 10, SA[2] }, { 19, 11, SA[2] }, { 20, 11, TIN[3] }, { 21, 11, TIN[3] }, { 22, 11, SA[2] }, { 20, 12, ARE[3] }, { 21, 12, ARE[4] } }) do S(p[1], p[2], p[3]) end
    S(19, 13, ARE[4]); S(20, 13, ARE[3]); S(21, 13, ARE[4]); S(22, 13, ARE[3])
    -- arena que se derrama sobre el canto y granos que caen; montoncito al pie
    for _, p in ipairs({ { 18, 14 }, { 19, 14 }, { 20, 14 }, { 21, 14 }, { 22, 14 }, { 23, 14 }, { 19, 15 }, { 20, 15 }, { 21, 15 }, { 22, 15 }, { 20, 16 }, { 21, 16 } }) do
      S(p[1], p[2], ARE[(p[2] == 14) and 4 or 3])
    end
    S(21, 17, ARE[3]); S(20, 18, ARE[2])
    -- arañazos y sangre
    zarpazo(27, 18, 8, function(c) return HO[6] end, rd)
    restregon(4, 26, 9, rd)
    salpicar(31, 30, 5, rd)
    salpicar(14, 18, 3, rd)
  end
  contorno()
end

---------------------------------------------------------------- construir
local cuadros = {}
for _, m in ipairs({ madera, chapa, hormigon }) do
  for e = 0, 2 do
    cuadros[#cuadros + 1] = function(img) m(e); volcar(img) end
  end
end
L.construir("muro", W, H, cuadros,
  { { "madera", 1, 3 }, { "chapa", 4, 6 }, { "hormigon", 7, 9 } }, 0.1, { base = { 24, 37 } })
