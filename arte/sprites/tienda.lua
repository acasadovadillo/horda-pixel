-- tienda (64x48, 2 fotogramas): puesto de los supervivientes en vista 3/4. Mostrador de tablas y cajas con
-- latas de munición, un botiquín y un bidón; toldo de lona azul desvaída sobre cuatro palos; estante al fondo;
-- un farol colgado del borde del toldo y un tablón pintado a mano. Fotograma 1: la llama del farol titila.
-- Punto `luz` = llama del farol. Luz de arriba a la izquierda; el fondo bajo el toldo queda en sombra.
local L = dofile(app.params.lib)
local W, H = 64, 48
local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local MAD = R({ "26180e", "3f2917", "5c3d22", "7b5631", "9a7446" })
local MAG = R({ "211b16", "352c24", "4c4033", "675846", "84735b" })
local LON = R({ "18222a", "23333d", "324752", "445f6b", "5a7884", "7592a0" })     -- lona azul desvaída
local OLV = R({ "171a14", "252a20", "353d2e", "4a5440", "636e55", "7f8a6c" })
local ACE = R({ "121418", "1f2329", "323840", "4b535e", "6e7885", "9aa4b0" })
local TEL = R({ "3e3c36", "5c5a52", "85837a", "aeab9f", "c9c5b6" })
local ROJ = R({ "3a1210", "5c1c18", "86302a", "a84a3c" })                         -- bidón rojo apagado
local CRZ = R({ "6b1a1a", "962824" })                                              -- cruz del botiquín
local FUE = R({ "7a1c0a", "c2410c", "f08a1c", "ffc93a", "fff1a8" })
local GLO = R({ "3c2516", "573620", "77502c" })                                    -- reflejo cálido del farol
local ORO = R({ "5a3d0c", "94680f", "cc9a1e" })
local CUE = R({ "2c2418", "4a3f2a", "6b5c3e", "8c7a54" })                         -- cuerda
local SEN = R({ "6b5a1e", "9c8530" })
local TIN = R({ "0e0d12", "1a1920", "26252e" })

local INFO = {}
for _, r in ipairs({ MAD, MAG, LON, OLV, ACE, TEL, ROJ, CRZ, FUE, GLO, ORO, CUE, SEN, TIN }) do
  for i, c in ipairs(r) do if not INFO[c] then INFO[c] = { r, i } end end
end

local B = {}
local function S(x, y, c)
  x = math.floor(x + 0.5); y = math.floor(y + 0.5)
  if c and x >= 0 and y >= 0 and x < W and y < H then B[y * W + x] = c end
end
local function G(x, y) if x < 0 or y < 0 or x >= W or y >= H then return nil end return B[y * W + x] end
local function rect(x, y, w, h, c) for yy = y, y + h - 1 do for xx = x, x + w - 1 do S(xx, yy, c) end end end
local function tono(c, d)
  local inf = INFO[c]; if not inf then return c end
  local r = inf[1]; return r[math.max(1, math.min(#r, inf[2] + d))]
end
local function hash(i, j, s)
  local n = i * 374761393 + j * 668265263 + s * 1442695041
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65535
end
local function vetaH(y, x0, x1, c, sem, dens)
  local x = x0 + math.floor(hash(y, x0, sem) * 3)
  local k = 0
  while x <= x1 do
    k = k + 1
    if hash(x, y, sem + k) < dens then
      local l = 2 + math.floor(hash(k, y, sem) * 3)
      for i = 0, l - 1 do if x + i <= x1 then S(x + i, y, c) end end
      x = x + l + 2
    else x = x + 3 end
  end
end

local function contorno()
  local s = {}
  for k, v in pairs(B) do s[k] = v end
  local function g(x, y) if x < 0 or y < 0 or x >= W or y >= H then return nil end return s[y * W + x] end
  for y = 0, H - 1 do for x = 0, W - 1 do
    if not s[y * W + x] then
      local c, claro = g(x - 1, y) or g(x, y - 1), false
      if not c then c = g(x + 1, y) or g(x, y + 1); claro = true end
      if c then
        local inf = INFO[c]; local r = inf and inf[1] or TIN
        if r == FUE or r == GLO or r == ORO or r == CRZ then r = TIN end
        B[y * W + x] = claro and r[2] or r[1]
      end
    end
  end end
end

local LX, LY = 38, 18          -- llama del farol

local function dibujar(img, f)
  B = {}
  -------------------------------------------------- fondo bajo el toldo: pared de tablas en sombra y estante
  for y = 11, 27 do for x = 7, 56 do
    local k = (x - 7) % 7
    local t = (k == 6) and 1 or 2
    if k == 0 then t = 3 end
    if y >= 25 then t = math.max(1, t - 1) end
    S(x, y, MAG[t])
  end end
  -- estante con latas y botellas
  for x = 9, 34 do S(x, 19, MAD[3]); S(x, 20, MAD[1]) end
  for _, cx in ipairs({ 10, 13, 16 }) do                              -- latas de conserva
    rect(cx, 16, 2, 3, ACE[3]); S(cx, 16, ACE[5]); S(cx, 17, ACE[4]); S(cx + 1, 18, ACE[2])
    S(cx, 17, (cx == 13) and ROJ[2] or OLV[3])
  end
  for _, bx in ipairs({ 21, 24 }) do                                  -- botellas
    S(bx, 13, OLV[3]); S(bx, 14, OLV[3]); rect(bx - 1, 15, 3, 4, OLV[2]); S(bx - 1, 15, OLV[4]); S(bx - 1, 16, OLV[3])
  end
  rect(28, 15, 6, 4, MAD[2]); rect(28, 15, 6, 1, MAD[3]); S(30, 17, MAD[1])   -- caja de cartón vieja
  -- herramientas colgadas a la derecha (pala y hacha) en sombra
  for y = 12, 25 do S(51, y, MAD[2]) end
  rect(50, 22, 3, 4, ACE[2]); S(50, 22, ACE[3])
  for y = 13, 22 do S(46, y, MAD[2]) end
  rect(44, 13, 3, 3, ACE[3]); S(44, 13, ACE[4])
  -- palos de atrás
  for y = 5, 27 do S(8, y, MAD[2]); S(55, y, MAD[1]) end
  -------------------------------------------------- reflejo cálido del farol en el fondo (titila)
  local rr = (f == 0) and 7.5 or 6.2
  for y = 11, 27 do for x = 26, 52 do
    local d = math.sqrt((x - LX) ^ 2 + ((y - LY) * 1.3) ^ 2) + hash(x, y, 9 + f) * 1.2
    local c = G(x, y)
    if c and d < rr then
      local i = INFO[c][2]
      S(x, y, GLO[math.max(1, math.min(3, i + ((d < rr * 0.5) and 1 or 0)))])
    end
  end end
  -------------------------------------------------- toldo de lona
  local function bordeDel(x) return 11 + math.floor(1.6 * math.sin(math.pi * (x - 3) / 57) + 0.5) end
  for x = 2, 61 do
    local yb = bordeDel(x)
    for y = 2, yb do
      -- bandas de luz en diagonal (la lona baja hacia delante; más luz a la izquierda)
      local k = x - y * 1.5 + math.sin(y * 1.3 + x * 0.2) * 1.5
      local t = (k < 16) and 5 or ((k < 44) and 4 or 3)
      if y <= 3 then t = math.min(t, 3) end
      if y == yb then t = 3 end
      S(x, y, LON[math.max(1, math.min(6, t))])
    end
    S(x, yb + 1, LON[2])
    if (x % 6) < 4 then S(x, yb + 2, LON[(x % 6 == 0) and 3 or 2]) end
  end
  -- pliegues tensos desde las esquinas delanteras hacia atrás (cresta clara y valle oscuro)
  local function pliegue(x0, y0, x1, y1)
    local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
    for i = 0, n do
      local x = math.floor(x0 + (x1 - x0) * i / n + 0.5)
      local y = math.floor(y0 + (y1 - y0) * i / n + 0.5)
      local c = G(x, y)
      if c and INFO[c][1] == LON then S(x, y, tono(c, 1)); local d = G(x + 1, y + 1) or G(x, y + 1); if d and INFO[d][1] == LON then S(x, y + 1, tono(d, -1)) end end
    end
  end
  pliegue(4, 10, 20, 4); pliegue(9, 11, 26, 5); pliegue(58, 10, 46, 4); pliegue(53, 12, 42, 6)
  -- remiendo de otra lona
  for y = 5, 8 do for x = 14, 20 do
    if not ((x == 14 or x == 20) and (y == 5 or y == 8)) then S(x, y, OLV[(y == 5 or x == 14) and 5 or 4]) end
  end end
  for x = 15, 19 do S(x, 9, OLV[2]) end
  for _, p in ipairs({ { 14, 6 }, { 17, 5 }, { 20, 7 }, { 16, 8 } }) do S(p[1], p[2], CUE[2]) end
  -- ollaos con cuerda en el borde
  for x = 8, 56, 8 do local yb = bordeDel(x); S(x, yb, ACE[5]); S(x, yb + 1, ACE[2]) end
  -------------------------------------------------- palos delanteros (con atadura del toldo)
  for _, px in ipairs({ 2, 60 }) do
    for y = 9, 44 do
      S(px, y, MAD[(y < 11) and 5 or 4]); S(px + 1, y, MAD[2])
      if y >= 42 then S(px, y, MAD[3]); S(px + 1, y, MAD[1]) end
    end
    for _, y in ipairs({ 11, 12 }) do S(px - 1, y, CUE[3]); S(px + 2, y, CUE[2]); S(px, y, CUE[4]); S(px + 1, y, CUE[2]) end
  end
  -------------------------------------------------- mostrador: tablero de arriba
  for x = 5, 58 do
    S(x, 26, MAD[3])                         -- canto de atrás
    S(x, 27, MAD[4]); S(x, 28, MAD[4])
    S(x, 29, MAD[5])                         -- canto delantero, al sol
  end
  vetaH(27, 5, 58, MAD[3], 3, 0.4)
  vetaH(28, 5, 58, MAD[5], 4, 0.25)
  for _, jx in ipairs({ 24, 41 }) do S(jx, 27, MAD[2]); S(jx, 28, MAD[2]); S(jx, 29, MAD[3]) end
  -------------------------------------------------- frente: dos cajas a los lados y tablas en medio
  local function cajon(x0)
    local w, y0, h = 16, 30, 15
    for y = y0, y0 + h - 1 do for x = x0, x0 + w - 1 do
      local dx, dy = x - x0, y - y0
      local marco = dx <= 1 or dx >= w - 2 or dy <= 1 or dy >= h - 2
      local t = marco and 4 or 3
      if marco and dx == 0 then t = 5 end
      if marco and dx == w - 1 then t = 2 end
      if dy == 0 then t = 2 end                                -- sombra bajo el tablero
      if not marco and (dy == 2 or dx == 2) then t = 2 end     -- sombra del marco en el panel
      if not marco and (dy - 2) % 4 == 3 then t = 2 end        -- juntas de las tablas del panel
      if dy == h - 1 then t = 2 end
      S(x, y, MAD[t])
    end end
    -- riostra
    for k = 0, 11 do
      local x, y = x0 + 2 + k, y0 + 12 - math.floor(k * 10 / 11 + 0.5)
      S(x, y - 1, MAD[5]); S(x, y, MAD[4])
    end
    for _, p in ipairs({ { 1, 1 }, { w - 2, 1 }, { 1, h - 2 }, { w - 2, h - 2 } }) do S(x0 + p[1], y0 + p[2], TIN[3]) end
    vetaH(y0 + 1, x0 + 2, x0 + w - 3, MAD[3], x0, 0.4)
  end
  cajon(5); cajon(43)
  for y = 30, 44 do for x = 21, 42 do
    local t = ((y - 30) % 4 == 3) and 2 or 3
    if (y - 30) % 4 == 0 then t = 4 end
    if y == 30 then t = 2 end
    if y >= 43 then t = 2 end
    S(x, y, MAD[t])
  end end
  vetaH(32, 21, 42, MAD[2], 8, 0.3); vetaH(36, 21, 42, MAD[2], 9, 0.3); vetaH(40, 21, 42, MAD[2], 10, 0.3)
  -- barro en la base
  for x = 5, 58 do if hash(x, 44, 2) < 0.5 then S(x, 44, MAD[1]) end if hash(x, 43, 2) < 0.2 then S(x, 43, MAD[2]) end end
  -------------------------------------------------- tablón pintado a mano, clavado en el centro
  for y = 32, 40 do for x = 20, 43 do
    local t = 4
    if y == 32 then t = 5 end
    if y == 36 then t = 2 end                                   -- junta entre las dos tablas
    if y == 37 then t = 4 end
    if x == 43 or y == 40 then t = 2 end
    S(x, y, MAG[t])
  end end
  S(20, 32, nil); B[32 * W + 20] = nil; S(43, 40, MAD[1])
  for _, p in ipairs({ { 21, 33 }, { 42, 33 }, { 21, 39 }, { 42, 39 } }) do S(p[1], p[2], TIN[3]) end
  local letras = {
    { "###", ".#.", ".#.", ".#.", ".#." },             -- T
    { "#", "#", "#", "#", "#" },                         -- I
    { "###", "#..", "##.", "#..", "###" },             -- E
    { "#..#", "##.#", "#.##", "#..#", "#..#" },        -- N
    { "##.", "#.#", "#.#", "#.#", "##." },             -- D
    { ".#.", "#.#", "###", "#.#", "#.#" },             -- A
  }
  local lx = 22
  for li, g in ipairs(letras) do
    local dy = 0
    for j, fila in ipairs(g) do
      for i = 1, #fila do
        if fila:sub(i, i) == "#" then
          local c = (hash(lx + i, j, 3) < 0.22) and TEL[3] or TEL[4]
          S(lx + i - 1, 33 + j - 1 + dy - ((j == 5 and li == 3) and 0 or 0), c)
        end
      end
    end
    lx = lx + #g[1] + 1
  end
  S(25, 39, TEL[3]); S(36, 39, TEL[3])                            -- goterones de pintura
  -------------------------------------------------- cosas sobre el mostrador
  -- latas de munición (verde oliva), una encima de otra
  local function lata(x0, y0, w, hf)
    for x = x0, x0 + w - 1 do S(x, y0, OLV[(x == x0) and 6 or 5]); S(x, y0 + 1, OLV[5]) end
    for y = y0 + 2, y0 + 1 + hf do for x = x0, x0 + w - 1 do
      local t = 4
      if x == x0 then t = 5 elseif x == x0 + w - 1 then t = 2 end
      if y == y0 + 1 + hf then t = 2 end
      S(x, y, OLV[t])
    end end
    local cx = x0 + w // 2
    S(cx - 1, y0, ACE[3]); S(cx, y0, ACE[4]); S(cx + 1, y0, ACE[3])          -- asa
    S(x0 + 1, y0 + 2, ACE[5]); S(x0 + 1, y0 + 3, ACE[3])                     -- cierre
    for i = 0, 2 do S(cx + i - 1, y0 + 3, SEN[(i == 1) and 1 or 2]) end      -- estarcido
  end
  lata(8, 21, 11, 5)
  lata(10, 16, 8, 3)
  -- cartuchos sueltos
  for _, p in ipairs({ { 20, 27 }, { 33, 28 }, { 35, 27 } }) do S(p[1], p[2], ROJ[3]); S(p[1] + 1, p[2], ORO[3]) end
  S(34, 28, ORO[2])
  -- botiquín: caja clara con cruz y asa
  for x = 23, 31 do S(x, 22, TEL[(x == 23) and 5 or 4]); S(x, 23, TEL[4]) end
  for y = 24, 28 do for x = 23, 31 do
    local t = 3
    if x == 23 then t = 4 elseif x == 31 then t = 1 end
    if y == 28 then t = 2 end
    S(x, y, TEL[t])
  end end
  S(26, 21, TEL[2]); S(27, 21, TEL[2]); S(28, 21, TEL[2]); S(25, 22, TEL[2]); S(29, 22, TEL[2])
  S(27, 24, CRZ[2]); S(26, 25, CRZ[2]); S(27, 25, CRZ[2]); S(28, 25, CRZ[2]); S(27, 26, CRZ[1])
  S(30, 25, TEL[2]); S(29, 27, TEL[2])                                       -- suciedad
  -- bidón rojo apagado, de pie: cara de arriba con tres asas y boca, cuerpo con aspa estampada
  local bx0, bx1, by0 = 46, 52, 19
  for x = bx0, bx1 do S(x, by0, ROJ[(x == bx0) and 4 or 3]); S(x, by0 + 1, ROJ[3]) end
  for _, x in ipairs({ 47, 49 }) do S(x, by0 - 1, ROJ[2]); S(x + 1, by0 - 1, ROJ[1]) end   -- asas
  S(51, by0 - 1, ACE[4]); S(52, by0 - 1, ACE[5]); S(52, by0 - 2, ACE[4])                -- boca con tapón
  for y = by0 + 2, 28 do for x = bx0, bx1 do
    local t = 3
    if x == bx0 then t = 4 elseif x == bx1 then t = 1 elseif x == bx1 - 1 then t = 2 end
    if y == by0 + 2 then t = 2 end
    if y == 28 then t = 1 end
    S(x, y, ROJ[t])
  end end
  for k = 0, 4 do                                                           -- aspa en relieve
    local y = by0 + 3 + k
    S(bx0 + 1 + k, y, ROJ[(k < 2) and 4 or 2]); S(bx1 - 1 - k, y, ROJ[2])
  end
  S(bx0 + 3, by0 + 5, ROJ[4])
  S(bx0, 26, ACE[3]); S(bx0 + 1, 27, ACE[4]); S(bx1 - 2, 22, OLV[2])        -- pintura saltada
  -------------------------------------------------- farol colgado
  for y = 12, 14 do S(LX, y, ACE[3]) end                                     -- alambre
  S(LX - 1, 15, ACE[4]); S(LX, 15, ACE[5]); S(LX + 1, 15, ACE[3])           -- sombrerete
  S(LX - 2, 16, ACE[3]); S(LX + 2, 16, ACE[2]); S(LX - 1, 16, ACE[4]); S(LX, 16, ACE[4]); S(LX + 1, 16, ACE[3])
  for y = 17, 20 do
    S(LX - 2, y, ACE[2]); S(LX + 2, y, ACE[1])                               -- varillas
    for x = LX - 1, LX + 1 do S(x, y, FUE[(f == 0) and 3 or 2]) end          -- cristal iluminado
  end
  -- llama
  if f == 0 then
    S(LX, 17, FUE[4]); S(LX, 18, FUE[5]); S(LX, 19, FUE[5]); S(LX - 1, 19, FUE[4]); S(LX + 1, 19, FUE[4]); S(LX, 20, FUE[4])
  else
    S(LX + 1, 18, FUE[4]); S(LX, 19, FUE[5]); S(LX, 20, FUE[4]); S(LX - 1, 20, FUE[3]); S(LX - 1, 18, FUE[2])
  end
  for x = LX - 2, LX + 2 do S(x, 21, ACE[(x == LX - 2) and 4 or 3]) end     -- base
  S(LX - 1, 22, ACE[2]); S(LX, 22, ACE[2]); S(LX + 1, 22, ACE[1])
  -- reflejo del farol en el canto del mostrador y en las latas
  if f == 0 then S(36, 29, FUE[3]); S(37, 29, FUE[4]); S(39, 29, FUE[3]); S(31, 23, GLO[3]) else S(37, 29, FUE[3]); S(38, 29, FUE[3]) end
  contorno()
  for k, c in pairs(B) do img:drawPixel(k % W, k // W, c) end
end

L.construir("tienda", W, H, {
  function(img) dibujar(img, 0) end,
  function(img) dibujar(img, 1) end,
}, { { "farol", 1, 2 } }, { 0.18, 0.14 }, { base = { 32, 45 }, luz = { LX, LY } })
