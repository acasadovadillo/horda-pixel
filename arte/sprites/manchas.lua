-- Manchas de sangre seca (24x24, fondo transparente): charco, salpicadura, rastro de arrastre, gotas.
local L = dofile(app.params.lib)
local N = 24
local S = L.rampa("sangre")
local SECA = L.hex("3a0a0e") -- entre sangre 1 y 2: costra

local function H(x, y, s)
  local v = math.sin(x * 12.9898 + y * 78.233 + s * 37.719) * 43758.5453
  return v - math.floor(v)
end
local function vn(x, y, c, s)
  local gx, gy = x / c, y / c
  local x0, y0 = math.floor(gx), math.floor(gy)
  local fx, fy = gx - x0, gy - y0
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local function g(i, j) return H(i, j, s) end
  local a = g(x0, y0) + (g(x0 + 1, y0) - g(x0, y0)) * fx
  local b = g(x0, y0 + 1) + (g(x0 + 1, y0 + 1) - g(x0, y0 + 1)) * fx
  return a + (b - a) * fy
end

-- máscara: m[y*N+x] = true
local function mascara() return {} end
local function elip(m, cx, cy, rx, ry, s, rug)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
    local d = dx * dx + dy * dy
    if rug then d = d + (vn(x, y, 3, s) - 0.5) * rug end
    if d <= 1 then m[y * N + x] = true end
  end end
end
local function trazo(m, x0, y0, x1, y1, g0, g1)
  local pasos = math.max(1, math.floor(math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) * 2))
  for k = 0, pasos do
    local t = k / pasos
    local cx, cy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
    local r = (g0 + (g1 - g0) * t) / 2
    for y = math.floor(cy - r - 1), math.ceil(cy + r + 1) do for x = math.floor(cx - r - 1), math.ceil(cx + r + 1) do
      if (x + 0.5 - cx) ^ 2 + (y + 0.5 - cy) ^ 2 <= r * r and x >= 0 and y >= 0 and x < N and y < N then m[y * N + x] = true end
    end end
  end
end
local function en(m, x, y) return x >= 0 and y >= 0 and x < N and y < N and m[y * N + x] end

-- profundidad: distancia (en pasos) al exterior
local function profundidad(m)
  local d = {}
  for y = 0, N - 1 do for x = 0, N - 1 do if m[y * N + x] then d[y * N + x] = 99 end end end
  for paso = 1, 6 do
    for y = 0, N - 1 do for x = 0, N - 1 do
      local i = y * N + x
      if d[i] == 99 then
        local function v(xx, yy)
          if not en(m, xx, yy) then return 0 end
          return d[yy * N + xx]
        end
        local mn = math.min(v(x - 1, y), v(x + 1, y), v(x, y - 1), v(x, y + 1))
        if mn == paso - 1 then d[i] = paso end
      end
    end end
  end
  return d
end

-- pinta una máscara como sangre seca: borde fino oscuro, cuerpo rojo apagado,
-- zonas gruesas más oscuras, brillo mate arriba a la izquierda de las zonas gruesas.
local function pintar(img, m, s, opciones)
  opciones = opciones or {}
  local d = profundidad(m)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local i = y * N + x
    if m[i] then
      local p = d[i]
      local c
      local q = vn(x, y, 3, s + 1)
      if p <= 1 then
        -- borde: más oscuro abajo a la derecha, rojo abajo-izquierda/arriba
        if not en(m, x + 1, y) or not en(m, x, y + 1) then c = S[1] else c = S[2] end
      elseif p == 2 then
        c = (q > 0.85) and S[3] or S[2]
      else
        c = (q > 0.6) and S[2] or SECA
        if opciones.rayas then c = opciones.rayas(x, y, p) end
      end
      L.px(img, x, y, c)
    end
  end end
  -- brillo: primer píxel profundo arriba a la izquierda de cada zona gruesa
  for y = 1, N - 2 do for x = 1, N - 2 do
    local i = y * N + x
    if d[i] and d[i] >= 3 and not (d[i - N] and d[i - N] >= 3) and not (d[i - 1] and d[i - 1] >= 3) then
      L.px(img, x, y, S[3]); L.px(img, x + 1, y, S[3])
    end
  end end
end

local fot = {}

-- 0 charco
fot[1] = function(img)
  local m = mascara()
  elip(m, 12, 13, 8.2, 5.2, 3, 0.7)
  elip(m, 7.5, 10.5, 4, 3, 4, 0.6)
  elip(m, 16.5, 15.5, 4.5, 3.2, 5, 0.6)
  elip(m, 4, 18, 1.2, 1.0)
  elip(m, 21, 9, 1.5, 1.0)
  elip(m, 20, 20, 1.1, 1.0)
  pintar(img, m, 1)
end

-- 1 salpicadura: impacto con chorros y gotas hacia la derecha
fot[2] = function(img)
  local m = mascara()
  elip(m, 8, 12, 3.8, 2.8, 6, 0.6)
  local rayos = { { 0.0, 13 }, { -0.45, 11 }, { 0.5, 10 }, { -1.0, 8 }, { 1.05, 8 }, { 2.6, 6 }, { -2.4, 5 } }
  for k, ry in ipairs(rayos) do
    local a, l = ry[1], ry[2]
    local ex, ey = 8 + math.cos(a) * l, 12 + math.sin(a) * l * 0.75
    trazo(m, 8 + math.cos(a) * 3, 12 + math.sin(a) * 2.2, ex - math.cos(a) * 1.5, ey - math.sin(a) * 1.1, 2.2, 1.1)
    elip(m, ex, ey, 1.2, 1.1)
    -- gotas sueltas más allá
    local fx, fy = 8 + math.cos(a) * (l + 3.5), 12 + math.sin(a) * (l + 3.5) * 0.75
    if k <= 4 then trazo(m, fx, fy, fx + 0.8, fy, 1.6, 1.4) end
  end
  pintar(img, m, 2)
end

-- 2 rastro de arrastre: banda que se adelgaza y se rompe, con regueros a lo largo
fot[3] = function(img)
  local m = mascara()
  local function eje(t) return 2 + 20 * t, 15 - 6 * t + math.sin(t * 3) * 1.2 end
  for k = 0, 60 do
    local t = k / 60
    local x, y = eje(t)
    local g = 7 - 4 * t
    if not (t > 0.7 and math.floor(t * 30) % 3 == 0) then trazo(m, x, y, x, y, g, g) end
  end
  elip(m, 4, 15, 3.4, 3, 7, 0.5) -- inicio más cargado
  pintar(img, m, 3, {
    rayas = function(x, y, p)
      -- regueros: bandas según la distancia perpendicular al eje
      local t = math.max(0, math.min(1, (x - 2) / 20))
      local _, ey = eje(t)
      local v = math.floor((y - ey) + 10)
      if v % 3 == 0 then return S[2] end
      if v % 3 == 1 and t > 0.45 then return S[1] end
      return SECA
    end,
  })
  -- arañazos de dedos al final
  L.px(img, 21, 9, S[2]); L.px(img, 22, 9, S[2]); L.px(img, 20, 11, S[2]); L.px(img, 21, 11, S[1])
end

-- 3 gotas: reguero de gotas a lo largo de un camino curvo
fot[4] = function(img)
  local m = mascara()
  local gotas = {
    { 3.5, 19.5, 2.0 }, { 8, 16, 1.4 }, { 11.5, 12.5, 1.7 }, { 16, 10, 1.3 },
    { 20, 6, 1.6 }, { 13, 17, 1.0 }, { 20, 13, 1.0 }, { 6, 12, 1.0 },
  }
  for i, g in ipairs(gotas) do
    elip(m, g[1], g[2], g[3] * 1.15, g[3])
    -- cola corta hacia atrás del movimiento (abajo-izquierda)
    if i <= 5 and i % 2 == 1 then trazo(m, g[1] - g[3], g[2] + g[3] * 0.6, g[1] - g[3] - 1.2, g[2] + g[3] + 0.4, 1.2, 1.0) end
  end
  pintar(img, m, 4)
end

L.construir("manchas", N, N, fot, nil, 0.2)
