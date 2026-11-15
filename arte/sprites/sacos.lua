-- sacos (72x26): parapeto de sacos terreros de arpillera, tres hiladas al tresbolillo (5-4-3),
-- sacos blandos y vencidos por el peso, con pliegues en las bocas atadas y costuras.
local L = dofile(app.params.lib)
local W, H = 72, 26

local function hash(i, j, s)
  local n = i * 374761393 + j * 668265263 + s * 1442695041
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65535
end
local function ruidoV(x, y, ex, ey, s)
  local fx, fy = x / ex, y / ey
  local i, j = math.floor(fx), math.floor(fy)
  local u, v = fx - i, fy - j
  u = u * u * (3 - 2 * u); v = v * v * (3 - 2 * v)
  local a, b, c, d = hash(i, j, s), hash(i + 1, j, s), hash(i, j + 1, s), hash(i + 1, j + 1, s)
  return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v
end

local function rampa(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
-- 1 = grieta/contorno, 2..5 = rampa de la arpillera
local PAL = {
  rampa({ "241d13", "4a3f2a", "6b5c3e", "8c7a54", "ab986e" }),   -- arpillera (L.P.saco)
  rampa({ "211e15", "433f2e", "625c44", "807a5c", "9d9676" }),   -- arpillera vieja, más gris
  rampa({ "22190f", "45351f", "634c2e", "836843", "a2865c" }),   -- húmeda, más parda
}

-- buffers de tono (0 = vacío) y paleta por píxel
local T, P = {}, {}
local function get(x, y) return T[y * W + x] or 0 end
local function set(x, y, t, p)
  if x < 0 or y < 0 or x >= W or y >= H then return end
  T[y * W + x] = t; if p then P[y * W + x] = p end
end

local LX, LY, LZ = -0.45, -0.72, 0.53
do local n = math.sqrt(LX * LX + LY * LY + LZ * LZ); LX, LY, LZ = LX / n, LY / n, LZ / n end

-- saco: centro, semiejes, caída de las puntas, paleta, semilla, lado de la boca (-1/1)
local function saco(cx, cy, a, b, caida, pal, sem, boca)
  local p = 2.9
  local function f(x, y)
    local dx = (x - cx) / a
    local dy = (y - cy - caida * dx * dx)
    -- la mitad de abajo se aplasta un poco (peso)
    local bb = dy > 0 and b * 0.92 or b
    -- la boca atada se estrecha
    local estr = 1
    if dx * boca > 0.55 then estr = 1 - (dx * boca - 0.55) * 0.55 end
    dy = dy / (bb * estr)
    return math.abs(dx) ^ p + math.abs(dy) ^ p
  end
  local function h(x, y)
    local v = f(x, y)
    if v >= 1 then return 0 end
    return (1 - v) ^ 0.5 + (ruidoV(x, y, 2.6, 1.8, sem) - 0.5) * 0.06
  end
  -- sombra de oclusión sobre lo que ya había debajo (la hilada inferior)
  for x = math.floor(cx - a - 1), math.ceil(cx + a + 1) do
    local fondo = nil
    for y = H - 1, 0, -1 do
      if f(x + 0.5, y + 0.5) <= 1.12 then fondo = y; break end
    end
    if fondo then
      for k = 1, 2 do
        local t = get(x, fondo + k)
        if t > 2 then set(x, fondo + k, t - (k == 1 and 2 or 1)) end
      end
    end
  end
  -- grieta/contorno (un poco más grande que el saco)
  for y = math.floor(cy - b - 3), math.ceil(cy + b + 3) do
    for x = math.floor(cx - a - 2), math.ceil(cx + a + 2) do
      if f(x + 0.5, y + 0.5) <= 1.0 + 0.30 * (1.0 / math.min(a, b)) * 3 then set(x, y, 1, pal) end
    end
  end
  -- cuerpo sombreado por normales
  for y = math.floor(cy - b - 2), math.ceil(cy + b + 2) do
    for x = math.floor(cx - a - 1), math.ceil(cx + a + 1) do
      local px, py = x + 0.5, y + 0.5
      if f(px, py) <= 1 then
        local e, Hs = 0.6, 2.6
        local gx = (h(px + e, py) - h(px - e, py)) / (2 * e) * Hs
        local gy = (h(px, py + e) - h(px, py - e)) / (2 * e) * Hs
        local nx, ny, nz = -gx, -gy, 1
        local n = math.sqrt(nx * nx + ny * ny + nz * nz)
        local d = (nx * LX + ny * LY + nz * LZ) / n
        local t
        if d > 0.93 then t = 5 elseif d > 0.74 then t = 4 elseif d > 0.42 then t = 3 else t = 2 end
        set(x, y, t, pal)
      end
    end
  end
  -- pliegues de la boca atada: dos arrugas que convergen en la punta
  local px0 = cx + boca * (a - 1)
  for k, dy in ipairs({ -1.6, 1.4 }) do
    for i = 0, 2 do
      local x = math.floor(px0 - boca * (i + 1) + 0.5)
      local y = math.floor(cy + caida * 0.9 + dy * (1 - i * 0.25) + 0.5)
      if get(x, y) > 1 then set(x, y, math.max(2, get(x, y) - 1)) end
      if k == 1 and get(x, y - 1) > 1 then set(x, y - 1, math.min(5, get(x, y - 1) + 1)) end
    end
  end
  -- costura vertical en el extremo cosido (puntadas de 2 px)
  local sx = math.floor(cx - boca * (a - 2.2) + 0.5)
  for y = math.floor(cy - b + 2), math.floor(cy + b - 1) do
    if (y % 3) ~= 0 and get(sx, y) > 2 then set(sx, y, get(sx, y) - 1) end
  end
  -- arruga larga en diagonal (tela tensa)
  local r = L.azar(sem)
  local ax = cx + (r() - 0.5) * a * 0.6
  for i = 0, 3 do
    local x = math.floor(ax + i + 0.5)
    local y = math.floor(cy + 1 + i * 0.5 + caida * 0.3 + 0.5)
    if get(x, y) > 2 then set(x, y, get(x, y) - 1) end
  end
end

-- hilada de abajo (5), media (4), arriba (3); distintas caídas y paletas
local hiladas = {
  { cy = 20.0, caida = 0.6, a = 7.1, b = 4.1, xs = { 8, 22, 36, 50, 64 } },
  { cy = 13.6, caida = -1.3, a = 7.2, b = 4.1, xs = { 15, 29, 43, 57 } },
  { cy = 7.0,  caida = -1.2, a = 7.3, b = 4.3, xs = { 22, 36, 50 } },
}
local r = L.azar(91)
local n = 0
for hi, hh in ipairs(hiladas) do
  for _, x in ipairs(hh.xs) do
    n = n + 1
    local pal = ({ 1, 2, 1, 3, 1, 2, 1, 3, 2, 1, 3, 1 })[n]
    local dx = (r() - 0.5) * 1.0
    local dy = (r() - 0.5) * 0.8
    local boca = (n % 2 == 0) and 1 or -1
    saco(x + dx, hh.cy + dy, hh.a + (r() - 0.5) * 0.6, hh.b, hh.caida + r() * 0.5, pal, 100 + n * 13, boca)
  end
end

L.construir("sacos", W, H, {
  function(img)
    for y = 0, H - 1 do for x = 0, W - 1 do
      local t = get(x, y)
      if t > 0 then
        local pal = PAL[P[y * W + x] or 1]
        local c = pal[t]
        -- contorno exterior: más claro arriba/izquierda
        if t == 1 and (get(x - 1, y) == 0 and get(x + 1, y) ~= 0 or get(x, y - 1) == 0) and y < 24 then c = pal[2] end
        L.px(img, x, y, c)
      end
    end end
  end,
}, nil, nil, { base = { 36, 25 } })
