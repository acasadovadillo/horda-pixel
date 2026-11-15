-- alambre (48x16, 2 variantes): concertina de alambre de cuchillas tendida en el suelo delante del muro,
-- sujeta con piquetes cortos de acero. Se repite cada 48 px (la espiral da 12 vueltas exactas por tramo).
-- 0: concertina tensa con piquetes en x = 12 y 36. 1: concertina que se vence entre piquetes (x = 0 y 24),
-- con un trapo enganchado y sangre seca. Las dos casan entre sí por los bordes.
local L = dofile(app.params.lib)
local W, H = 48, 16
local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local ACE = R({ "121418", "1f2329", "323840", "4b535e", "6e7885", "9aa4b0", "c4cbd2" })
local OX  = R({ "301710", "52281a", "7a3f20", "9e5f30" })
local TEL = R({ "3e3c36", "5c5a52", "85837a", "aeab9f" })
local SG  = R({ "2e070b", "520c12", "7a121a", "a31d24" })

local B = {}
local function S(x, y, c)
  x = math.floor(x + 0.5) % W; y = math.floor(y + 0.5)
  if y >= 0 and y < H and c then B[y * W + x] = c end
end
local function G(x, y) x = math.floor(x + 0.5) % W; y = math.floor(y + 0.5); if y < 0 or y >= H then return nil end return B[y * W + x] end

local function hash(i, j, s)
  local n = i * 374761393 + j * 668265263 + s * 1442695041
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65535
end

local SUELO = 14
local SEP, RX, RY = 6, 5.2, 4.6         -- 8 vueltas por tramo: separación y radios de cada vuelta

local function sag(v, x) if v == 1 then return 1.5 * math.sin(math.pi * x / 24) ^ 2 end return 0 end

-- tono de cada punto de una vuelta según hacia dónde mira (luz arriba a la izquierda)
local function tonoVuelta(t)
  local l = -math.cos(t) * 0.55 - math.sin(t) * 0.85          -- t medido con y hacia abajo
  if l > 0.55 then return 7 elseif l > 0.1 then return 6 elseif l > -0.45 then return 5 else return 4 end
end

local function vueltas(v, fn)
  for k = 0, 7 do
    local cx = k * SEP + 3 + (hash(k, 1, 5) - 0.5) * 1.2
    local rx = RX + (hash(k, 2, 5) - 0.5) * 1.0
    local ry = RY + (hash(k, 3, 5) - 0.5) * 0.8
    local inc = ((k % 2 == 0) and 1.1 or -0.6) + (hash(k, 4, 5) - 0.5) * 0.6
    for i = 0, 63 do
      local t = i / 64 * 2 * math.pi
      local x = cx + rx * math.cos(t) + inc * math.sin(t)          -- vueltas inclinadas, alternas
      local y = SUELO - 1 - ry + ry * math.sin(t) + sag(v, x)
      fn(x, y, t, k, i)
    end
  end
end

local function piquete(x, v)
  local y0 = 2 + math.floor(sag(v, x) + 0.5)
  for y = y0, SUELO do S(x, y, ACE[(y < y0 + 2) and 6 or 5]); S(x + 1, y, ACE[2]) end
  S(x, y0 - 1, ACE[4]); S(x + 1, y0 - 1, ACE[2])
  S(x, SUELO, ACE[3]); S(x + 1, SUELO, ACE[1])
  S(x + 1, 9, OX[2]); S(x + 1, 10, OX[1])
end

local function dibujar(img, v)
  B = {}
  -- mitad de atrás de cada vuelta (arco de arriba, más lejos): oscura
  vueltas(v, function(x, y, t, k, i) if math.sin(t) < 0 then S(x, y, (math.cos(t) > 0) and ACE[3] or ACE[4]); S(x, y + 1, G(x, y + 1) or ACE[2]) end end)
  for _, px in ipairs((v == 0) and { 12, 36 } or { 0, 24 }) do piquete(px, v) end
  -- mitad de delante (arco de abajo) y brillo: por encima de todo
  local pts = {}
  vueltas(v, function(x, y, t, k, i)
    if math.sin(t) >= -0.15 or math.cos(t) < -0.2 then pts[#pts + 1] = { x, y, tonoVuelta(t), i, k, t } end
  end)
  for _, p in ipairs(pts) do S(p[1], p[2], ACE[p[3]]) end
  for _, px in ipairs((v == 0) and { 12, 36 } or { 0, 24 }) do local y0 = 2 + math.floor(sag(v, px) + 0.5); for y = y0, y0 + 3 do S(px, y, ACE[6]); S(px + 1, y, ACE[2]) end end
  -- cuchillas: puntitas a lo largo del alambre de delante
  for _, p in ipairs(pts) do
    if p[4] % 9 == 4 then
      local x, y = math.floor(p[1] + 0.5), math.floor(p[2] + 0.5)
      local ox = (math.cos(p[6]) > 0) and 1 or -1
      if not G(x + ox, y - 1) then S(x + ox, y - 1, ACE[6]) end
    end
  end
  -- algo de óxido
  for _, p in ipairs(pts) do if hash(p[4] // 7, p[5], 3) < 0.12 then S(p[1], p[2], OX[(p[3] >= 6) and 2 or 1]) end end
  if v == 1 then
    -- trapo enganchado y sangre seca
    local tr = { { 30, 7, 4 }, { 31, 7, 3 }, { 32, 8, 3 }, { 30, 8, 3 }, { 31, 8, 2 }, { 31, 9, 2 }, { 32, 9, 1 }, { 30, 9, 2 }, { 29, 8, 4 }, { 31, 10, 1 } }
    for _, p in ipairs(tr) do S(p[1], p[2], TEL[p[3]]) end
    S(31, 9, SG[2]); S(30, 9, SG[3])
    S(9, 12, SG[3]); S(10, 12, SG[2]); S(41, 10, SG[2])
  end
  for k, c in pairs(B) do img:drawPixel(k % W, k // W, c) end
end

L.construir("alambre", W, H, {
  function(img) dibujar(img, 0) end,
  function(img) dibujar(img, 1) end,
}, nil, nil, { base = { 24, 14 } })
