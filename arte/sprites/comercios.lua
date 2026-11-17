-- COMERCIOS DE LA BASE de Horda Pixel (56x52, 10 fotogramas, punto base { 28, 49 }).
-- Una caseta por vendedor, con el vendedor de cintura para arriba detrás del mostrador, mirando a la cámara.
-- Dos fotogramas por comercio: 1 normal, 2 parpadeo (el juego los alterna despacio).
--   1-2 armero (toldo granate, armero con fusiles, letrero con una pistola)
--   3-4 intendente (lona oliva, cajas de munición y granadas, letrero con balas)
--   5-6 médico (lona blanca con cruz, estante de frascos, letrero con cruz)
--   7-8 mecánico (tejadillo de chapa, panel de herramientas y rueda, letrero con llave inglesa)
--   9-10 constructor (lona naranja con franja de aviso, tablones y ladrillos, letrero con martillo)
-- Vista 3/4: se ve el toldo por arriba, el fondo en sombra y la cara sur del mostrador. Luz arriba a la izquierda.
local L = dofile(app.params.lib)
local W, H = 56, 52
local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local MAD = R({ "26180e", "3f2917", "5c3d22", "7b5631", "9a7446" })
local MAG = R({ "1d1813", "2c241d", "3d3228", "52453a", "6b5c4c" })                 -- fondo en sombra
local PI = R({ "4a2f28", "7a4e3c", "a36f55", "c4937a", "deb89e" })
local PE = R({ "1c1512", "2e221b", "45342a", "5e4a3a" })
local CANA = R({ "3c3a36", "5e5b54", "85817a" })                                      -- pelo canoso
local TIN = R({ "0e0d12", "1a1920", "26252e" })
local ME = R({ "121418", "1f2329", "323840", "4b535e", "6e7885", "9aa4b0" })
local TEL = R({ "3e3c36", "5c5a52", "85837a", "aeab9f", "d1cec0", "e8e5d8" })
local GRA = R({ "2e0f10", "4a1a1a", "6b2622", "8a3a30", "a65446" })                 -- granate
local OLV = R({ "171a14", "252a20", "353d2e", "4a5440", "636e55", "7f8a6c" })
local AZU = R({ "141b26", "1f2b3d", "2c3e57", "3e5674", "577191" })                 -- mono de mecánico
local NAR = R({ "4a200c", "7a3612", "a8521e", "cc7330", "e09a5a" })                 -- chaleco naranja
local AMA = R({ "5a4612", "8a6d1c", "b8922a", "d9b546", "ecd27a" })                 -- casco y aviso
local ROJ = R({ "4a1012", "7a1a1c", "a8302c", "c84a3e" })
local OX = R({ "361a0e", "5c2c14", "86451d", "ad6a2e" })
local LAD = R({ "3a1f18", "5c3024", "7d4432", "9a5a42" })
local CU = R({ "17120f", "261d18", "3a2c23", "524033", "6e5844" })
local ORO = R({ "5a3d0c", "94680f", "cc9a1e", "f2c84a" })
local CRI = R({ "24394a", "3b5a70", "6d93a8", "b5d0db" })

local INFO = {}
for _, r in ipairs({ MAD, MAG, PI, PE, CANA, TIN, ME, TEL, GRA, OLV, AZU, NAR, AMA, ROJ, OX, LAD, CU, ORO, CRI }) do
  for i, c in ipairs(r) do if not INFO[c] then INFO[c] = { r, i } end end
end

local B = {}
local function S(x, y, c)
  x = math.floor(x + 0.5); y = math.floor(y + 0.5)
  if c and x >= 0 and y >= 0 and x < W and y < H then B[y * W + x] = c end
end
local function G(x, y) if x < 0 or y < 0 or x >= W or y >= H then return nil end return B[y * W + x] end
local function rect(x, y, w, h, c) for yy = y, y + h - 1 do for xx = x, x + w - 1 do S(xx, yy, c) end end end
local function hash(i, j, s)
  local n = i * 374761393 + j * 668265263 + s * 1442695041
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65535
end
-- Dibujo a mano: filas de caracteres; cada carácter se busca en la tabla de colores (el punto es hueco).
local function mapa(x0, y0, filas, cols)
  for j, fila in ipairs(filas) do for i = 1, #fila do
    local c = cols[fila:sub(i, i)]
    if c then S(x0 + i - 1, y0 + j - 1, c) end
  end end
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
        if r == ORO or r == CRI or r == AMA or r == NAR or r == ROJ then r = TIN end
        B[y * W + x] = claro and r[2] or r[1]
      end
    end
  end end
end

---------------------------------------------------------------- piezas comunes
local CX = 28                -- centro del vendedor
local HY = 15                -- fila de arriba de la cabeza

local function fondo()
  for y = 10, 33 do for x = 5, 50 do
    local k = (x - 5) % 7
    local t = (k == 6) and 1 or 2
    if k == 0 then t = 3 end
    if y >= 30 then t = math.max(1, t - 1) end
    S(x, y, MAG[t])
  end end
  for y = 8, 33 do S(6, y, MAD[2]); S(49, y, MAD[1]) end         -- palos de atrás
end

-- Toldo: tela con caída, bandas de luz en diagonal; estilo = "lona" | "rayas" | "chapa"
local function borde(x) return 9 + math.floor(1.4 * math.sin(math.pi * (x - 1) / 54) + 0.5) end
local function toldo(R1, estilo, R2)
  for x = 1, 54 do
    local yb = borde(x)
    for y = 2, yb do
      local k = x - y * 1.5 + math.sin(y * 1.3 + x * 0.2) * 1.2
      local t = (k < 14) and 5 or ((k < 38) and 4 or 3)
      if y <= 3 then t = math.min(t, 3) end
      if y == yb then t = 3 end
      local r = R1
      if estilo == "rayas" and (x // 6) % 2 == 1 then r = R2 end
      if estilo == "chapa" then
        t = ((x % 4) == 0) and 2 or ((x % 4) == 1 and 5 or 4)
        if y == yb then t = 2 end
        if hash(x // 4, y // 3, 5) < 0.12 and hash(x, y, 7) < 0.6 then r = OX; t = 2 + math.floor(hash(y, x, 6) * 2) end
      end
      S(x, y, r[math.max(1, math.min(#r, t))])
    end
    S(x, yb + 1, R1[2])
    if estilo ~= "chapa" and (x % 6) < 4 then S(x, yb + 2, R1[(x % 6 == 0) and 3 or 2]) end
  end
end

local function palos()
  for _, px in ipairs({ 1, 53 }) do
    for y = 9, 47 do
      S(px, y, MAD[(y < 11) and 5 or 4]); S(px + 1, y, MAD[2])
      if y >= 45 then S(px, y, MAD[3]); S(px + 1, y, MAD[1]) end
    end
  end
end

-- Mostrador: tablero arriba (filas 32-35) y frente de tablas (36-47) con un letrero en medio.
local function mostrador(R1)
  R1 = R1 or MAD
  for x = 3, 52 do
    S(x, 32, R1[3]); S(x, 33, R1[4]); S(x, 34, R1[4]); S(x, 35, R1[5])
    if hash(x, 33, 3) < 0.25 then S(x, 33, R1[3]) end
  end
  for y = 36, 47 do for x = 3, 52 do
    local t = ((y - 36) % 4 == 3) and 2 or 3
    if (y - 36) % 4 == 0 then t = 4 end
    if y == 36 then t = 2 end
    if x == 3 then t = math.min(5, t + 1) end
    if x == 52 or y >= 46 then t = 2 end
    S(x, y, R1[t])
  end end
  for _, jx in ipairs({ 16, 39 }) do for y = 36, 47 do S(jx, y, R1[2]) end end
  for x = 3, 52 do if hash(x, 47, 2) < 0.5 then S(x, 47, MAD[1]) end end
  -- letrero: tablón claro clavado en el centro
  for y = 37, 45 do for x = 19, 36 do
    local t = 4
    if y == 37 then t = 5 end
    if x == 36 or y == 45 then t = 2 end
    S(x, y, MAG[t])
  end end
  for _, p in ipairs({ { 20, 38 }, { 35, 38 }, { 20, 44 }, { 35, 44 } }) do S(p[1], p[2], TIN[3]) end
end

-- Vendedor de cintura para arriba, de frente. o = { ropa, pelo, barba, gorro, detalle }
local function vendedor(o, f)
  local cx, hy = CX, HY
  -- brazos a los lados, apoyados en el tablero
  for y = hy + 9, 31 do
    S(cx - 7, y, o.ropa[3]); S(cx - 6, y, o.ropa[4])
    S(cx + 5, y, o.ropa[2]); S(cx + 6, y, o.ropa[1])
  end
  -- manos sobre el tablero
  S(cx - 7, 32, PI[3]); S(cx - 6, 32, PI[4]); S(cx - 5, 32, PI[3])
  S(cx + 4, 32, PI[3]); S(cx + 5, 32, PI[3]); S(cx + 6, 32, PI[2])
  -- torso
  for y = hy + 8, 31 do
    local m = (y == hy + 8) and 5 or 6
    for x = cx - m + 1, cx + m - 2 do
      local t = 3
      if x <= cx - m + 2 then t = 4 end
      if x >= cx + m - 3 then t = 2 end
      if y == hy + 8 then t = math.min(5, t + 1) end
      S(x, y, o.ropa[t])
    end
  end
  -- sombra de la barbilla y cuello
  S(cx - 1, hy + 7, PI[2]); S(cx, hy + 7, PI[2]); S(cx - 1, hy + 8, PI[1]); S(cx, hy + 8, PI[1])
  -- cabeza 6x7
  for y = hy, hy + 6 do for x = cx - 3, cx + 2 do
    local esquina = (y == hy or y == hy + 6) and (x == cx - 3 or x == cx + 2)
    if not esquina then
      local t = (x <= cx - 2) and 4 or ((x >= cx + 1) and 2 or 3)
      if y == hy + 6 then t = math.max(1, t - 1) end
      S(x, y, PI[t])
    end
  end end
  -- orejas
  S(cx - 4, hy + 3, PI[3]); S(cx + 3, hy + 3, PI[2])
  -- pelo
  local P = o.pelo or PE
  for x = cx - 3, cx + 2 do S(x, hy, P[(x <= cx - 2) and 3 or 2]) end
  S(cx - 2, hy - 1, P[2]); S(cx - 1, hy - 1, P[3]); S(cx, hy - 1, P[2]); S(cx + 1, hy - 1, P[1])
  S(cx - 3, hy + 1, P[2]); S(cx + 2, hy + 1, P[1])
  if o.pelo ~= "calvo" then S(cx - 3, hy + 2, P[1]) end
  -- cejas, ojos (parpadeo en el fotograma 2), nariz y boca
  S(cx - 2, hy + 2, PI[2]); S(cx + 1, hy + 2, PI[1])
  if f == 2 then S(cx - 2, hy + 3, PI[2]); S(cx + 1, hy + 3, PI[1])
  else S(cx - 2, hy + 3, TIN[1]); S(cx + 1, hy + 3, TIN[1]) end
  S(cx, hy + 4, PI[2])
  S(cx - 1, hy + 5, PI[1]); S(cx, hy + 5, PI[2])
  if o.barba then
    for x = cx - 3, cx + 2 do S(x, hy + 5, o.barba[(x <= cx - 2) and 3 or 2]); S(x, hy + 6, o.barba[(x >= cx + 1) and 1 or 2]) end
    S(cx - 2, hy + 4, o.barba[2]); S(cx + 1, hy + 4, o.barba[1]); S(cx - 1, hy + 7, o.barba[1]); S(cx, hy + 7, o.barba[1])
    S(cx - 1, hy + 5, PI[1])
  end
  if o.detalle then o.detalle(cx, hy, f) end
end

local function letrero(filas, cols)
  local w = #filas[1]
  mapa(28 - w // 2, 41 - #filas // 2, filas, cols)
end

---------------------------------------------------------------- armero
local function armero(f)
  B = {}
  fondo()
  -- armero de pared con tres fusiles (izquierda) y dos pistolas colgadas (derecha)
  rect(7, 14, 13, 2, MAD[3]); rect(7, 28, 13, 2, MAD[2])
  for _, x in ipairs({ 9, 13, 17 }) do
    for y = 13, 27 do S(x, y, ME[(y < 22) and 3 or 2]) end
    S(x + 1, 15, ME[2]); S(x + 1, 16, ME[2])
    rect(x - 1, 23, 3, 5, MAD[(x == 9) and 4 or 3]); S(x + 1, 25, MAD[2])
  end
  for _, p in ipairs({ { 39, 17 }, { 44, 21 } }) do
    rect(p[1], p[2], 6, 2, ME[3]); S(p[1], p[2], ME[5]); rect(p[1], p[2] + 2, 2, 3, CU[3]); S(p[1] + 2, p[2] - 1, MAD[3])
  end
  rect(38, 26, 11, 4, OLV[3]); rect(38, 26, 11, 1, OLV[5]); S(42, 28, AMA[3]); S(43, 28, AMA[3])
  vendedor({ ropa = CU, pelo = "calvo", barba = PE, detalle = function(cx, hy)
    -- camisa oscura bajo el chaleco y canana cruzada
    for y = hy + 8, 31 do S(cx - 1, y, TIN[3]); S(cx, y, TIN[2]) end
    for k = 0, 9 do S(cx - 4 + k, hy + 10 + k, ORO[(k % 2 == 0) and 3 or 2]) end
    -- cabeza afeitada: brillo
    S(cx - 2, hy, PI[5]); S(cx - 1, hy - 1, PI[4]); S(cx - 2, hy - 1, PI[4]); S(cx, hy - 1, PI[3]); S(cx + 1, hy - 1, PI[2])
    S(cx - 3, hy, PI[4]); S(cx - 1, hy, PI[4]); S(cx, hy, PI[3]); S(cx + 1, hy, PI[3]); S(cx + 2, hy, PI[2])
    S(cx - 3, hy + 1, PI[4]); S(cx + 2, hy + 1, PI[2])
  end }, f)
  mostrador()
  -- sobre el mostrador: una escopeta tumbada y una caja de cartuchos
  for x = 6, 17 do S(x, 31, ME[3]); S(x, 32, ME[2]) end
  rect(14, 31, 6, 2, MAD[4]); S(19, 33, MAD[3]); S(6, 31, ME[5])
  rect(38, 29, 7, 4, ROJ[2]); rect(38, 29, 7, 1, ROJ[4]); S(40, 31, TEL[5]); S(41, 31, TEL[5])
  palos()
  toldo(GRA)
  letrero({
    ".#########",
    "##########",
    "o####.....",
    "o###......",
    ".##.......",
  }, { ["#"] = ME[2], o = MAD[2] })
  contorno()
end

---------------------------------------------------------------- intendente
local function caja(x, y, w, h, Rr)
  rect(x, y, w, h, Rr[3]); rect(x, y, w, 1, Rr[5]); rect(x, y + h - 1, w, 1, Rr[2]); rect(x + w - 1, y, 1, h, Rr[2])
  S(x + w // 2 - 1, y + h // 2, AMA[3]); S(x + w // 2, y + h // 2, AMA[3])
end
local function intendente(f)
  B = {}
  fondo()
  caja(7, 23, 12, 7, OLV); caja(8, 17, 10, 6, OLV); caja(37, 22, 12, 8, OLV); caja(39, 15, 9, 7, OLV)
  vendedor({ ropa = OLV, pelo = CANA, barba = CANA, detalle = function(cx, hy)
    -- boina
    for x = cx - 4, cx + 2 do S(x, hy - 1, OLV[(x < cx) and 3 or 2]) end
    for x = cx - 3, cx + 3 do S(x, hy, OLV[(x < cx) and 4 or 2]) end
    S(cx - 2, hy - 2, OLV[3]); S(cx - 1, hy - 2, OLV[3]); S(cx, hy - 2, OLV[2])
    S(cx - 3, hy - 1, OLV[4])
    -- bolsillos y galón
    S(cx - 4, hy + 11, OLV[2]); S(cx - 3, hy + 11, OLV[2]); S(cx + 2, hy + 11, OLV[1]); S(cx + 3, hy + 11, OLV[1])
    S(cx - 5, hy + 9, AMA[4]); S(cx - 4, hy + 9, AMA[3])
    for y = hy + 9, 31 do S(cx - 1, y, OLV[2]) end
  end }, f)
  mostrador()
  -- lata de munición y dos granadas
  rect(7, 28, 10, 5, OLV[4]); rect(7, 28, 10, 1, OLV[6]); rect(11, 27, 3, 1, ME[4]); S(8, 30, AMA[2]); S(9, 30, AMA[2])
  for _, gx in ipairs({ 39, 44 }) do
    rect(gx, 29, 4, 4, OLV[3]); S(gx, 29, OLV[5]); S(gx + 3, 32, OLV[1]); S(gx + 1, 28, ME[4]); S(gx + 2, 28, ME[3]); S(gx + 3, 27, ME[4])
  end
  palos()
  toldo(OLV)
  letrero({
    ".o..o..o.",
    "ooo.ooo.ooo",
    "###.###.###",
    "###.###.###",
    "###.###.###",
    "ddd.ddd.ddd",
  }, { ["#"] = ORO[3], o = ORO[2], d = ORO[1] })
  contorno()
end

---------------------------------------------------------------- médico
local function medico(f)
  B = {}
  fondo()
  -- estantes con frascos
  for _, y in ipairs({ 20, 28 }) do rect(7, y, 13, 1, MAD[3]); rect(37, y, 13, 1, MAD[3]) end
  for _, p in ipairs({ { 8, 17, CRI }, { 11, 16, OX }, { 15, 17, TEL }, { 38, 17, OX }, { 42, 16, TEL }, { 46, 17, CRI },
                       { 9, 25, TEL }, { 13, 24, OX }, { 40, 25, CRI }, { 45, 24, TEL } }) do
    local c = p[3]
    rect(p[1], p[2], 3, 20 - p[2] + ((p[2] > 21) and 8 or 0), c[2]); S(p[1], p[2], c[3]); S(p[1] + 1, p[2] - 1, TEL[2])
  end
  vendedor({ ropa = TEL, pelo = PE, detalle = function(cx, hy, f2)
    -- mascarilla y moño
    for x = cx - 3, cx + 2 do S(x, hy + 4, CRI[(x <= cx - 2) and 4 or 3]); S(x, hy + 5, CRI[(x >= cx + 1) and 2 or 3]) end
    S(cx - 4, hy + 4, CRI[2]); S(cx + 3, hy + 4, CRI[1])
    S(cx - 1, hy - 2, PE[2]); S(cx, hy - 2, PE[2]); S(cx - 1, hy - 3, PE[3])
    for y = hy + 1, hy + 4 do S(cx - 3, y, PE[2]); S(cx + 2, y, PE[1]) end
    -- solapas, estetoscopio y cruz en el pecho
    for y = hy + 8, 31 do S(cx - 1, y, TEL[2]) end
    S(cx - 2, hy + 9, TEL[2]); S(cx + 1, hy + 9, TEL[1])
    for k = 0, 3 do S(cx - 3 + k // 2, hy + 9 + k, ME[2]); S(cx + 2 - k // 2, hy + 9 + k, ME[2]) end
    S(cx - 1, hy + 13, ME[4]); S(cx, hy + 13, ME[3])
    S(cx + 3, hy + 12, ROJ[3]); S(cx + 2, hy + 13, ROJ[3]); S(cx + 3, hy + 13, ROJ[3]); S(cx + 4, hy + 13, ROJ[3]); S(cx + 3, hy + 14, ROJ[2])
  end }, f)
  mostrador()
  -- botiquín y vendas
  rect(6, 27, 11, 6, TEL[4]); rect(6, 27, 11, 1, TEL[6]); rect(16, 27, 1, 6, TEL[2]); rect(6, 32, 11, 1, TEL[2])
  S(11, 28, ROJ[3]); S(10, 29, ROJ[3]); S(11, 29, ROJ[3]); S(12, 29, ROJ[3]); S(11, 30, ROJ[2]); rect(10, 26, 3, 1, TEL[2])
  for _, bx in ipairs({ 39, 44 }) do rect(bx, 29, 4, 4, TEL[5]); S(bx, 29, TEL[6]); S(bx + 3, 32, TEL[3]); S(bx + 1, 31, TEL[3]) end
  palos()
  toldo(TEL, "rayas", R({ "4a1012", "6b1a1a", "8a2a24", "a8402f", "b85040" }))
  letrero({
    "...##...",
    "...##...",
    "########",
    "########",
    "...##...",
    "...##...",
  }, { ["#"] = ROJ[3] })
  contorno()
end

---------------------------------------------------------------- mecánico
local function mecanico(f)
  B = {}
  fondo()
  -- panel de herramientas (izquierda) y rueda colgada (derecha)
  rect(7, 14, 13, 13, MAG[3])
  for y = 15, 25, 2 do for x = 8, 18, 2 do S(x, y, MAG[1]) end end
  for y = 15, 22 do S(9, y, ME[4]) end; rect(8, 15, 3, 2, ME[4]); S(9, 15, MAG[3])          -- llave
  for y = 16, 24 do S(13, y, ME[3]) end; rect(12, 16, 3, 2, ME[5])                          -- destornillador
  for y = 17, 24 do S(17, y, MAD[3]) end; rect(16, 16, 3, 2, ME[4])                         -- martillo
  for a = 0, 31 do
    local t = a / 32 * math.pi * 2
    for rr = 4, 6 do S(43 + math.cos(t) * rr, 21 + math.sin(t) * rr * 0.9, TIN[(rr == 6) and 2 or 3]) end
  end
  S(41, 17, ME[4]); S(42, 16, ME[4])
  vendedor({ ropa = AZU, pelo = PE, detalle = function(cx, hy)
    -- gafas de soldar en la frente y gorra
    for x = cx - 3, cx + 2 do S(x, hy + 1, CU[2]) end
    S(cx - 2, hy + 1, CRI[3]); S(cx - 1, hy + 1, CRI[2]); S(cx + 1, hy + 1, CRI[2]); S(cx, hy + 1, ME[3])
    -- tirantes del mono, camiseta debajo y grasa
    for y = hy + 8, hy + 10 do for x = cx - 3, cx + 2 do S(x, y, TEL[3]) end end
    for y = hy + 8, 31 do S(cx - 4, y, AZU[4]); S(cx + 3, y, AZU[2]) end
    S(cx - 3, hy + 15, TIN[3]); S(cx - 2, hy + 15, TIN[3]); S(cx + 1, hy + 4, PI[2]); S(cx + 2, hy + 14, TIN[3])
    rect(cx - 1, hy + 12, 3, 2, AZU[2])
  end }, f)
  mostrador()
  -- caja de herramientas roja y un engranaje
  rect(6, 27, 12, 6, ROJ[3]); rect(6, 27, 12, 1, ROJ[4]); rect(17, 27, 1, 6, ROJ[1]); rect(10, 26, 4, 1, ME[4]); rect(6, 29, 12, 1, ROJ[2])
  S(11, 30, ME[5])
  for a = 0, 15 do local t = a / 16 * math.pi * 2; S(44 + math.cos(t) * 3, 30 + math.sin(t) * 2, ME[(a % 2 == 0) and 5 or 3]) end
  S(44, 30, ME[1])
  palos()
  toldo(ME, "chapa")
  letrero({
    "#..#.....",
    "####.....",
    ".###.....",
    "..###....",
    "...###...",
    "....###..",
    ".....##..",
  }, { ["#"] = ME[5] })
  contorno()
end

---------------------------------------------------------------- constructor
local function constructor(f)
  B = {}
  fondo()
  -- tablones apoyados (izquierda) y ladrillos apilados (derecha)
  for k = 0, 3 do
    local x0 = 7 + k * 3
    for y = 13, 30 do S(x0 + math.floor((y - 13) / 6), y, MAD[(k % 2 == 0) and 4 or 3]); S(x0 + 1 + math.floor((y - 13) / 6), y, MAD[2]) end
  end
  for j = 0, 3 do for i = 0, 2 do
    local x, y = 37 + i * 4 + (j % 2) * 2, 29 - j * 3
    rect(x, y, 4, 2, LAD[3]); S(x, y, LAD[4]); S(x + 3, y + 1, LAD[2])
  end end
  vendedor({ ropa = NAR, pelo = PE, barba = PE, detalle = function(cx, hy)
    -- casco amarillo
    for x = cx - 4, cx + 3 do S(x, hy, AMA[(x <= cx - 2) and 4 or ((x >= cx + 2) and 2 or 3)]) end
    for x = cx - 3, cx + 2 do S(x, hy - 1, AMA[(x <= cx - 1) and 5 or 3]) end
    for x = cx - 2, cx + 1 do S(x, hy - 2, AMA[(x <= cx - 1) and 4 or 3]) end
    S(cx - 1, hy - 3, AMA[3]); S(cx, hy - 3, AMA[2])
    -- camiseta oscura bajo el chaleco, bandas reflectantes
    for y = hy + 8, 31 do S(cx - 1, y, PE[2]); S(cx, y, PE[1]) end
    for x = cx - 5, cx + 4 do S(x, hy + 14, TEL[(x <= cx - 2) and 6 or 5]) end
    for x = cx - 5, cx + 4 do if x ~= cx - 1 and x ~= cx then S(x, hy + 11, TEL[(x <= cx - 2) and 5 or 4]) end end
  end }, f)
  mostrador()
  -- ladrillos y un serrucho
  rect(6, 29, 5, 2, LAD[3]); rect(11, 29, 5, 2, LAD[2]); rect(8, 27, 5, 2, LAD[4]); S(8, 27, LAD[4])
  for x = 37, 47 do S(x, 31, ME[5]); S(x, 32, ME[3]) end
  for x = 38, 46, 2 do S(x, 33, ME[4]) end
  rect(47, 30, 4, 3, MAD[4])
  palos()
  toldo(NAR)
  for x = 1, 54 do                       -- franja de aviso en el borde del toldo
    local yb = borde(x)
    local c = (((x + 0) // 3) % 2 == 0) and AMA[4] or TIN[2]
    S(x, yb - 1, c); S(x, yb, (c == AMA[4]) and AMA[3] or TIN[1])
  end
  letrero({
    "######..",
    "######..",
    "..##....",
    "..##....",
    "..##....",
    "..##....",
  }, { ["#"] = ME[4] })
  -- mango de madera del martillo
  for y = 41, 44 do S(27, y, MAD[4]); S(28, y, MAD[3]) end
  contorno()
end

local function volcar(img)
  for k, c in pairs(B) do img:drawPixel(k % W, k // W, c) end
end
local function fot(fn, f) return function(img) fn(f); volcar(img) end end

L.construir("comercios", W, H, {
  fot(armero, 1), fot(armero, 2), fot(intendente, 1), fot(intendente, 2), fot(medico, 1), fot(medico, 2),
  fot(mecanico, 1), fot(mecanico, 2), fot(constructor, 1), fot(constructor, 2),
}, {
  { "armero", 1, 2 }, { "intendente", 3, 4 }, { "medico", 5, 6 }, { "mecanico", 7, 8 }, { "constructor", 9, 10 },
}, { 2.4, 0.15, 2.4, 0.15, 2.4, 0.15, 2.4, 0.15, 2.4, 0.15 }, { base = { 28, 49 } })
