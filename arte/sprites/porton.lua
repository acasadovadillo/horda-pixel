-- porton (48x40, 9 fotogramas): portón de la base en vista 3/4, entre dos tramos de muro.
-- Mismos materiales y orden que el muro: 0-2 madera, 3-5 chapa, 6-8 hormigón (pilares de bloques con
-- sacos y hojas de plancha de acero). En cada uno: cerrado, abierto (las hojas giradas hacia dentro,
-- hacia la cámara, dejando paso en el centro) y roto (escombro bajo).
-- Las hojas están en el plano norte del muro (fila 27 abajo); los pilares ocupan todo el grueso.
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

local function onda(x) return ({ 5, 4, 3, 2 })[(x % 4) + 1] end
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


local OLV = R({ "171a14", "252a20", "353d2e", "4a5440", "636e55", "7f8a6c" })  -- plancha de acero verde oliva
for i, c in ipairs(OLV) do if not INFO[c] then INFO[c] = { OLV, i } end end

---------------------------------------------------------------- hojas del portón
local WL, HL, YB = 18, 22, 27     -- ancho y alto de cada hoja; fila de abajo con el portón cerrado
local HX = { 6, 41 }              -- columna de la bisagra de cada hoja (izquierda, derecha)

-- u = 0..WL-1 desde la bisagra; v = 0..HL-1 desde abajo; a = 0..WL-1 de izquierda a derecha en pantalla
local function texMadera(u, v, a, lado)
  local pal = ({ MAD, MAG, MAD })[(u // 6) + 1]
  local vb = 5 + (u - 1) * 10 / 15                      -- riostra en diagonal (bisagra abajo, cierre arriba)
  if (v >= 2 and v <= 4) or (v >= 16 and v <= 18) then  -- travesaños
    local top = (v == 4 or v == 18)
    local t = top and 5 or ((v == 2 or v == 16) and 3 or 4)
    if u <= 6 and (v == 3 or v == 17) then return (u == 6) and ACE[2] or ((u % 3 == 1) and ACE[5] or ACE[3]) end  -- pernio
    if u <= 6 and (v == 4 or v == 18) then return ACE[4] end
    if u % 6 == 2 and v % 2 == 1 then return TIN[3] end
    return MAD[t]
  end
  if v > 4 and v < 16 and u >= 1 and u <= 16 and math.abs(v - vb) <= 1.1 then
    local d = v - vb
    return MAD[(d > 0.4) and 5 or ((d < -0.4) and 3 or 4)]
  end
  if v > 4 and v < 16 and u >= 1 and u <= 16 and v - vb < -1.1 and v - vb > -2.2 then
    -- sombra bajo la riostra
    local k = a % 6
    if k == 5 then return TIN[2] end
    return pal[2]
  end
  local k = a % 6
  if k == 5 then return TIN[3] end
  local t = (k == 0) and 4 or ((k == 4) and 2 or 3)
  if v == HL - 1 then t = 5 end
  if v == 1 or v == 15 then t = t - 1 end                -- sombra bajo los travesaños
  if v == 0 then t = t - 1 end
  if (k == 2 or k == 3) and hash(a, v // 3, 11 + lado) < 0.18 then t = t - 1 end
  return pal[math.max(1, t)]
end

local function texChapa(u, v, a, lado)
  local marco = (u <= 1 or u >= WL - 2 or v <= 1 or v >= HL - 2)
  local vb = 2 + (u - 2) * (HL - 5) / (WL - 5)
  if marco then
    local t = 4
    if v == HL - 1 then t = 6 elseif v == HL - 2 then t = 5
    elseif v == 0 then t = 2 elseif v == 1 then t = 3
    elseif a <= 1 then t = (a == 0) and 5 or 4 else t = (a == WL - 1) and 2 or 3 end
    if u <= 1 and (v == 4 or v == 17) then return ACE[6] end   -- bisagras
    return ACE[t]
  end
  if math.abs(v - vb) <= 0.8 then return ACE[(v > vb) and 5 or 4] end
  if v - vb < -0.8 and v - vb > -1.8 then return GAL[2] end
  local pal = (lado == 1) and GAL or PIN
  local t = onda(a)
  if v == 2 then t = t - 1 end
  local c = cl(pal, t)
  if ruido(a + lado * 20, v, 6, 4, 13) + ((v < 6) and 0.12 or 0) > 0.8 then
    c = OX[math.max(1, math.min(3, t - 2))]
  end
  return c
end

local function texPlancha(u, v, a, lado)
  local t = 4
  if a == 0 then t = 5 elseif a == WL - 1 then t = 2 end
  if v == HL - 1 then t = 6 elseif v == 0 then t = 2 end
  if v == 7 or v == 15 then t = 5 elseif v == 6 or v == 14 then t = 2 end   -- nervios
  if (v == 6 or v == 14) and (a == 0) then t = 3 end
  -- remaches en el borde y en los nervios
  if (u == 1 or u == WL - 2) and v % 3 == 1 and v > 0 and v < HL - 1 then return OLV[6] end
  if (v == 7 or v == 15) and u % 4 == 2 then return OLV[6] end
  -- mirilla en la hoja derecha
  if lado == 2 and v == 18 and u >= 3 and u <= 7 then return TIN[1] end
  if lado == 2 and v == 17 and u >= 3 and u <= 7 then return OLV[5] end
  local c = OLV[t]
  -- pintura saltada: acero al aire y óxido
  local n = ruido(a + lado * 30, v, 2, 2, 41)
  if n > 0.86 then c = (t >= 4) and ACE[5] or ACE[3] end
  if ruido(a + lado * 30, v, 3, 2, 43) + ((v < 4) and 0.2 or 0) > 0.86 then c = OX[math.max(1, math.min(3, t - 2))] end
  return c
end

local TEX = { texMadera, texChapa, texPlancha }
local BORDE = { function() return MAD[5] end, function() return ACE[6] end, function() return OLV[6] end }

-- dibuja una hoja girada ang grados hacia dentro (0 = cerrada)
local function hoja(mat, lado, ang)
  local s = (lado == 1) and 1 or -1
  local hx = HX[lado]
  local ca, sa = math.cos(math.rad(ang)), math.sin(math.rad(ang))
  local ancho = math.max(1, math.floor(WL * ca + 0.5))
  local shade = (ang > 0) and ((lado == 1) and 0 or -1) or 0
  local yfin
  for j = 0, ancho - 1 do
    local u = math.floor((j + 0.5) / ca)
    if u > WL - 1 then u = WL - 1 end
    local a = (lado == 1) and u or (WL - 1 - u)
    if ang > 0 then a = (lado == 1) and j or (ancho - 1 - j) end
    local x = hx + s * j
    local yb = YB + math.floor((j + 0.5) / ca * sa * 0.6 + 0.5)
    for v = 0, HL - 1 do
      local c = TEX[mat](u, v, ang > 0 and math.floor(a / ca) or a, lado)
      if shade ~= 0 then c = tono(c, shade) end
      S(x, yb - v, c)
    end
    S(x, yb - HL, BORDE[mat]())                                -- canto de arriba de la hoja
    yfin = yb
  end
  if ang > 0 then
    -- canto libre de la hoja (grueso visto de lado)
    local x = hx + s * ancho
    local c = (mat == 1) and MAD[2] or ((mat == 2) and ACE[2] or OLV[2])
    for y = yfin - HL, yfin do S(x, y, c) end
    S(x, yfin - HL, BORDE[mat]())
  end
end

---------------------------------------------------------------- pilares
local function pilar(mat, x0, lado)
  local w = 6
  if mat == 1 then
    -- poste gordo de madera: testa con anillos arriba, cara con vetas, zuncho de hierro
    for y = 2, 11 do for dx = 0, w - 1 do
      local t = 4
      local ex, ey = (dx - 2.5) / 3, (y - 6.5) / 5
      local rr = math.sqrt(ex * ex + ey * ey)
      if math.floor(rr * 3.2) % 2 == 1 then t = 3 end
      if dx == 0 or y == 2 then t = 5 end
      if dx == w - 1 then t = 3 end
      if y == 11 then t = 5 end
      S(x0 + dx, y, MAD[t])
    end end
    S(x0 + 2, 6, MAD[2]); S(x0 + 3, 7, MAD[2]); S(x0 + 3, 8, MAD[2])             -- raja de la testa
    for y = 12, 36 do for dx = 0, w - 1 do
      local t = ({ 5, 4, 4, 3, 3, 2 })[dx + 1]
      if y == 12 then t = math.min(5, t + 1) end
      if y >= 34 then t = t - 1 end
      S(x0 + dx, y, MAD[t])
    end end
    local rr = L.azar(x0 + 3)
    for dx = 1, 4 do vetaV(x0 + dx, 14, 35, MAD[(dx < 3) and 3 or 2], rr, 0.25) end
    for _, zy in ipairs({ 16, 31 }) do
      for dx = 0, w - 1 do S(x0 + dx, zy, ACE[(dx == 0) and 5 or 4]); S(x0 + dx, zy + 1, ACE[2]) end
      S(x0 + 2, zy, ACE[6]); S(x0 + 3, zy + 2, OX[2])
    end
  elseif mat == 2 then
    -- pilar de tubo cuadrado de acero con chapa de remate
    for y = 2, 11 do for dx = 0, w - 1 do
      local t = 5
      if dx == 0 or y == 11 then t = 6 end
      if y == 2 or dx == w - 1 then t = 4 end
      S(x0 + dx, y, ACE[t])
    end end
    S(x0 + 1, 4, ACE[3]); S(x0 + 4, 4, ACE[3]); S(x0 + 1, 9, ACE[3]); S(x0 + 4, 9, ACE[3])   -- tornillos del remate
    for y = 12, 36 do for dx = 0, w - 1 do
      local t = ({ 5, 4, 4, 4, 3, 2 })[dx + 1]
      if y == 12 then t = 2 end
      if y == 36 then t = t - 1 end
      S(x0 + dx, y, ACE[t])
    end end
    for y = 13, 36 do for dx = 0, w - 1 do
      if ruido(x0 + dx, y, 3, 4, 17) + (y - 13) / 23 * 0.2 > 0.9 then
        local c = G(x0 + dx, y); S(x0 + dx, y, OX[math.max(1, math.min(3, INFO[c][2] - 2))])
      end
    end end
    for _, by in ipairs({ 15, 26, 33 }) do S(x0 + 1, by, ACE[6]); S(x0 + 4, by, ACE[6]); S(x0 + 1, by + 1, OX[2]); S(x0 + 4, by + 1, ACE[2]) end
  else
    -- pilar de bloques con un saco encima
    for y = 8, 11 do for dx = 0, w - 1 do S(x0 + dx, y, HO[(y == 11) and 6 or 5]) end end
    for y = 12, 36 do for dx = 0, w - 1 do
      local f = (y - 12) % 5
      local t = 4
      if f == 0 then t = 2 elseif f == 1 then t = 5 end
      if dx == 0 and f ~= 0 then t = math.min(6, t + 1) end
      if dx == w - 1 then t = t - 1 end
      if y >= 35 then t = t - 1 end
      S(x0 + dx, y, HO[t])
    end end
    S(x0 + 2, 20, HO[3]); S(x0 + 3, 20, HO[3]); S(x0 + 3, 29, HO[3])
    saco(x0 + 2.8, 6.0, 3.9, 3.6, 500 + x0)
    saco(x0 + 3.2, 9.5, 4.0, 3.2, 600 + x0)
    -- anclajes de las bisagras
    local hxs = (lado == 1) and (x0 + w - 1) or x0
  end
end

local function umbral(mat)
  -- línea de contacto de las hojas cerradas con el suelo
  for x = 6, 41 do S(x, 28, (mat == 1) and MAD[1] or ((mat == 2) and ACE[1] or OLV[1])) end
end

local function portonCerrado(mat)
  nuevo(false)
  pilar(mat, 0, 1); pilar(mat, 42, 2)
  umbral(mat)
  hoja(mat, 1, 0); hoja(mat, 2, 0)
  -- junta central
  for y = YB - HL + 1, YB do S(23, y, tono(G(23, y), -1)); S(24, y, (mat == 1) and TIN[3] or ACE[1]) end
  if mat == 1 then
    -- tranca atravesada
    for x = 14, 33 do S(x, 15, MAD[5]); S(x, 16, MAD[4]); S(x, 17, MAD[2]) end
    S(13, 15, ACE[4]); S(13, 16, ACE[2]); S(34, 15, ACE[4]); S(34, 16, ACE[2])
  elseif mat == 2 then
    -- cadena y candado
    for _, p in ipairs({ { 21, 14 }, { 22, 15 }, { 23, 15 }, { 24, 15 }, { 25, 15 }, { 26, 14 } }) do S(p[1], p[2], ACE[5]) end
    S(23, 16, ACE[4]); S(24, 16, ACE[4]); S(23, 17, ACE[3]); S(24, 17, ACE[2]); S(23, 16, ACE[6])
  else
    -- cerrojo
    for x = 20, 27 do S(x, 16, OLV[6]); S(x, 17, OLV[2]) end
    S(26, 15, OLV[5]); S(26, 18, OLV[2])
  end
  local rd = L.azar(7 + mat)
  zarpazo(9, 9, 6, function(c) return (mat == 1) and MAD[5] or ((mat == 2) and GAL[6] or ACE[5]) end, rd)
  salpicar(30, 22, 4, rd)
  contorno()
end

local function portonAbierto(mat)
  nuevo(false)
  pilar(mat, 0, 1); pilar(mat, 42, 2)
  hoja(mat, 1, 62); hoja(mat, 2, 62)
  contorno()
end

---------------------------------------------------------------- roto
local function hojaTumbada(mat, x0, y0, filas, largo, lado)
  -- media hoja caída de lado, de plano: las tablas quedan en horizontal (comprimidas al 60 %)
  for r = 0, filas - 1 do
    local u = math.floor(r / 0.6)
    local lim = largo - math.floor(hash(r, 0, mat + 5) * 4)
    for v = 0, lim do
      S(x0 + v + math.floor(r * 0.4), y0 - r, tono(TEX[mat](u, v, u, lado), 1))
    end
  end
  local c = (mat == 1) and MAD[2] or ((mat == 2) and ACE[2] or OLV[2])
  for v = 0, largo do S(x0 + v, y0 + 1, c) end
end

local function portonRoto(mat)
  nuevo(false)
  local r = L.azar(300 + mat)
  if mat == 1 then
    monton(ARE, 8, 2)
    hojaTumbada(1, 14, 33, 6, 20, 1)
    for x = 1, 15 do local y = 32 + math.floor(x * 0.1); S(x, y, MAD[5]); S(x, y + 1, MAD[4]); S(x, y + 2, MAD[4]); S(x, y + 3, MAD[2]) end
    S(16, 33, MAD[5]); S(16, 34, MAD[3])
    tablaSuelo(32, 32, 46, 33, MAD, r, true)
    tablaSuelo(30, 34, 40, 35, MAG, r, false)
    for k = 1, 10 do local x, y = 2 + math.floor(r() * 44), 34 + math.floor(r() * 2); S(x, y, MAD[5]); S(x + 1, y, MAD[3]) end
  elseif mat == 2 then
    monton(ARE, 19, 2)
    hojaTumbada(2, 15, 33, 6, 19, 1)
    for x = 2, 13 do S(x, 33, ACE[5]); S(x, 34, ACE[4]); S(x, 35, ACE[2]) end
    S(1, 33, ACE[3]); S(1, 34, ACE[3])
    for x = 34, 46 do local y = 31 + math.floor((x - 34) * 0.2); S(x, y, GAL[(x % 4 < 2) and 5 or 3]); S(x, y + 1, GAL[(x % 4 < 2) and 4 or 2]); S(x, y + 2, OX[2]) end
    for k = 1, 6 do S(3 + math.floor(r() * 42), 34 + math.floor(r() * 2), ACE[6]) end
  else
    monton(HO, 23, 2)
    hojaTumbada(3, 13, 33, 6, 21, 2)
    trozo(2, 31, 6, 3, 2, HO, r)
    trozo(37, 30, 8, 3, 3, HO, r)
    trozo(33, 33, 4, 2, 1, HO, r)
    for _, sc in ipairs({ { 9, 34, 4.5, 1.8 } }) do
      for y = math.floor(sc[2] - 3), math.ceil(sc[2] + 3) do for x = math.floor(sc[1] - 6), math.ceil(sc[1] + 6) do
        local dx, dy = (x + 0.5 - sc[1]) / sc[3], (y + 0.5 - sc[2]) / sc[4]
        local v = dx * dx + dy * dy
        if v <= 1 then S(x, y, SA[(dy < -0.3) and 4 or ((dy > 0.4) and 2 or 3)]) elseif v <= 1.35 then S(x, y, SA[1]) end
      end end
    end
    for k = 1, 10 do local x, y = 1 + math.floor(r() * 46), 34 + math.floor(r() * 2); S(x, y, HO[5]); S(x + 1, y, HO[3]) end
  end
  S(24, 34, SG[2]); S(25, 34, SG[3]); S(26, 35, SG[2])
  contorno()
end

local cuadros = {}
for m = 1, 3 do
  cuadros[#cuadros + 1] = function(img) portonCerrado(m); volcar(img) end
  cuadros[#cuadros + 1] = function(img) portonAbierto(m); volcar(img) end
  cuadros[#cuadros + 1] = function(img) portonRoto(m); volcar(img) end
end
L.construir("porton", W, H, cuadros,
  { { "madera", 1, 3 }, { "chapa", 4, 6 }, { "hormigon", 7, 9 } }, 0.1, { base = { 24, 37 } })
