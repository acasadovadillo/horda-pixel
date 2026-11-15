-- Losetas de suelo (24x24): hierba, asfalto, grietas, línea, acera, bordillos y tierra.
-- Todas se dibujan sobre un búfer que da la vuelta en los bordes (coordenadas módulo 24),
-- así los mechones, piedras y juntas que cruzan un borde continúan en la loseta vecina.
local L = dofile(app.params.lib)
local N = 24

---------------------------------------------------------------- utilidades
local function H(x, y, s)
  local v = math.sin(x * 12.9898 + y * 78.233 + s * 37.719) * 43758.5453
  return v - math.floor(v)
end
-- ruido de valor periódico (celda c, divisor de 24)
local function vn(x, y, c, s)
  local n = N // c
  local gx, gy = x / c, y / c
  local x0, y0 = math.floor(gx), math.floor(gy)
  local fx, fy = gx - x0, gy - y0
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local function g(i, j) return H(i % n, j % n, s) end
  local a = g(x0, y0) + (g(x0 + 1, y0) - g(x0, y0)) * fx
  local b = g(x0, y0 + 1) + (g(x0 + 1, y0 + 1) - g(x0, y0 + 1)) * fx
  return a + (b - a) * fy
end

local function nueva()
  local t = {}
  t.set = function(x, y, c) t[(math.floor(y) % N) * N + (math.floor(x) % N)] = c end
  t.get = function(x, y) return t[(math.floor(y) % N) * N + (math.floor(x) % N)] end
  t.fill = function(c) for i = 0, N * N - 1 do t[i] = c end end
  return t
end

local function volcar(t, img)
  for y = 0, N - 1 do for x = 0, N - 1 do img:drawPixel(x, y, t[y * N + x]) end end
end

local A = L.rampa("asfalto")
local HO = L.rampa("hormigon")
local G = L.rampa("hierba")
local TI = L.rampa("tierra")
local SE = L.rampa("senal")
local SECA = { L.hex("2c2b1b"), L.hex("454229"), L.hex("625c37"), L.hex("807649"), L.hex("9c905d") }
local OCRE = { L.hex("3e2a14"), L.hex("5e401c"), L.hex("82602c"), L.hex("a07c3e") }
local MARRON = { L.hex("2e1c12"), L.hex("4a2e1c"), L.hex("6a4428"), L.hex("865a36") }
local HOJA = L.rampa("hojas")
local ACEITE = { L.hex("17181c"), L.hex("1f2026"), L.hex("2a2a34"), L.hex("35343f") }

---------------------------------------------------------------- asfalto
-- base de grano fino y poco contraste; desgaste = densidad extra de árido claro (máscara)
local function asfalto(t, s, mascaraDesgaste)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local m = vn(x, y, 4, s) * 0.55 + vn(x, y, 3, s + 7) * 0.45
    local c = A[3]
    if m < 0.30 then c = A[2] end
    t.set(x, y, c)
  end end
  local r = L.azar(s * 31 + 5)
  -- árido: piedrecitas claras con su sombra abajo a la derecha
  local n = 70
  for _ = 1, n do
    local x, y = math.floor(r() * N), math.floor(r() * N)
    local dens = 1
    if mascaraDesgaste then dens = mascaraDesgaste(x, y) end
    if r() < 0.55 + 0.45 * dens then
      local c = A[4]
      if r() < 0.12 + 0.4 * (dens - 1) then c = A[5] end
      t.set(x, y, c)
      if r() < 0.35 then t.set(x + 1, y, A[4]) end
      if r() < 0.6 then t.set(x + 1, y + 1, A[2]) end
    end
  end
  if mascaraDesgaste then
    for _ = 1, 60 do
      local x, y = math.floor(r() * N), math.floor(r() * N)
      local d = mascaraDesgaste(x, y)
      if d > 1.2 and r() < 0.8 then
        t.set(x, y, r() < 0.4 and A[5] or A[4])
        if r() < 0.5 then t.set(x + 1, y, A[4]) end
        t.set(x + 1, y + 1, A[2])
      end
    end
  end
  -- poros oscuros
  for _ = 1, 26 do
    local x, y = math.floor(r() * N), math.floor(r() * N)
    if t.get(x, y) == A[3] then t.set(x, y, A[2]) end
  end
end

-- grieta: paseo aleatorio; línea oscura con labio claro abajo/derecha
local function grieta(t, r, x, y, ang, largo, ramas)
  local pts = {}
  for _ = 1, largo do
    x = x + math.cos(ang); y = y + math.sin(ang)
    ang = ang + (r() - 0.5) * 1.2
    local ix, iy = math.floor(x + 0.5), math.floor(y + 0.5)
    if ix < 3 or ix > 20 or iy < 3 or iy > 20 then break end
    pts[#pts + 1] = { ix, iy }
  end
  for _, p in ipairs(pts) do
    t.set(p[1], p[2], A[1])
  end
  for _, p in ipairs(pts) do
    local bx, by = p[1], p[2] + 1
    if t.get(bx, by) ~= A[1] then t.set(bx, by, A[5]) end
    if r() < 0.35 and t.get(p[1] + 1, p[2]) ~= A[1] and t.get(p[1] + 1, p[2]) ~= A[5] then t.set(p[1] + 1, p[2], A[4]) end
  end
  if ramas and #pts > 4 then
    for _ = 1, ramas do
      local p = pts[3 + math.floor(r() * (#pts - 3))]
      grieta(t, r, p[1], p[2], ang + (r() < 0.5 and 1.2 or -1.2), 4 + math.floor(r() * 4), 0)
    end
  end
end

---------------------------------------------------------------- hierba
local function mechon(t, bx, by, r, seca, alto)
  local R = seca and SECA or G
  local nb = 3 + math.floor(r() * 3)
  alto = alto or 0
  for i = 1, nb do
    local dx = i - 1 - math.floor(nb / 2)
    local h = 2 + math.floor(r() * 3) + alto
    local lean = dx < 0 and -1 or (dx > 0 and 1 or 0)
    local lado = dx < 0 and 1 or (dx > 0 and -1 or 0) -- +1 = lado iluminado
    for k = 0, h - 1 do
      local x = bx + dx + math.floor(lean * k / (h + 1) + 0.5 * lean * (k == h - 1 and 1 or 0))
      local y = by - k
      local tono
      if k == 0 then tono = 2
      elseif k < h - 1 then tono = 3
      else tono = 4 end
      tono = tono + (lado > 0 and 1 or 0) - (lado < 0 and k > 0 and 1 or 0)
      local tope = seca and 4 or ((H(bx, by, 5) < 0.3) and 5 or 4)
      t.set(x, y, R[math.max(1, math.min(tope, tono))])
    end
  end
  -- oclusión en la base, a la derecha
  t.set(bx + math.ceil(nb / 2), by, G[1])
  t.set(bx + 1, by + 1, G[1])
end

-- hierba base; pasto(x,y) -> true si se puede poner un mechón ahí
local function hierba(t, s, nMechones, propSeca, pasto)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local m = vn(x, y, 3, s) * 0.45 + vn(x, y, 6, s + 3) * 0.2 + H(x, y, s) * 0.35
    local c
    if m < 0.30 then c = G[2]
    elseif m < 0.74 then c = G[3]
    elseif m < 0.80 then c = G[2]
    else c = (H(x, y, s + 9) < 0.5) and SECA[2] or G[2] end
    t.set(x, y, c)
  end end
  local r = L.azar(s * 17 + 3)
  local lista = {}
  for _ = 1, nMechones do
    local x, y = math.floor(r() * N), math.floor(r() * N)
    if not pasto or pasto(x, y) then
      lista[#lista + 1] = { x, y, r() < propSeca, r() }
    end
  end
  table.sort(lista, function(a, b) return a[2] < b[2] end)
  for i, m in ipairs(lista) do
    mechon(t, m[1], m[2], L.azar(s * 101 + i * 7), m[3])
  end
  return r
end

-- hoja seca caída de 3x2 / 4x2 con nervio
local function hojaSeca(t, x, y, r)
  local R = (r() < 0.5) and OCRE or MARRON
  local largo = 3 + math.floor(r() * 2)
  for i = 0, largo - 1 do
    t.set(x + i, y, R[(i < 2) and 4 or 3])
    t.set(x + i, y + 1, R[2])
  end
  t.set(x - 1, y + 1, R[3])
  t.set(x + largo, y, R[2])
  t.set(x + 1, y + 1, R[1]) -- nervio / pliegue
end

-- hierbajo de hoja ancha (roseta)
local function hierbajo(t, cx, cy, r)
  local hojas = {
    { -3, -1 }, { 3, -1 }, { -2, -3 }, { 2, -3 }, { 0, -4 }, { -3, 1 }, { 3, 1 },
  }
  for _, h in ipairs(hojas) do
    local ex, ey = cx + h[1], cy + h[2]
    -- hoja: trazo de 2 px
    local pasos = math.max(math.abs(h[1]), math.abs(h[2]))
    for k = 1, pasos do
      local x = cx + math.floor(h[1] * k / pasos + 0.5)
      local y = cy + math.floor(h[2] * k / pasos + 0.5)
      local izq = h[1] < 0 or (h[1] == 0)
      t.set(x, y, HOJA[k == pasos and 5 or 4])
      t.set(x, y + 1, HOJA[izq and 3 or 2])
    end
    t.set(ex, ey, HOJA[h[1] <= 0 and 5 or 4])
  end
  t.set(cx, cy, HOJA[2]); t.set(cx + 1, cy + 1, G[1]); t.set(cx, cy + 1, G[1])
end

---------------------------------------------------------------- acera
local function acera(t, s, fisura)
  local r = L.azar(s * 13 + 1)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local m = vn(x, y, 4, s) * 0.6 + vn(x, y, 3, s + 9) * 0.4
    local c = HO[3]
    if m < 0.30 then c = HO[2] elseif m > 0.74 then c = HO[4] end
    t.set(x, y, c)
  end end
  -- tono propio de cada losa (12x12): una algo más sucia
  local sucia = math.floor(r() * 4)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local losa = (y // 12) * 2 + (x // 12)
    if losa == sucia and H(x, y, s + 40) < 0.22 and t.get(x, y) == HO[3] then t.set(x, y, HO[2]) end
  end end
  -- grano
  for _ = 1, 55 do
    local x, y = math.floor(r() * N), math.floor(r() * N)
    if r() < 0.5 then t.set(x, y, HO[4]); t.set(x + 1, y + 1, HO[2])
    else t.set(x, y, HO[2]) end
  end
  -- juntas: horizontales en y = 11 y 23, vertical en x = 11 (labio claro abajo / derecha)
  for x = 0, N - 1 do
    for _, jy in ipairs({ 11, 23 }) do
      t.set(x, jy, (H(x, jy, s) < 0.2) and HO[1] or HO[2])
      if H(x, jy + 1, s + 2) < 0.75 then t.set(x, jy + 1, HO[4]) end
      
    end
  end
  for y = 0, N - 1 do
    if y % 12 ~= 11 then
      t.set(11, y, (H(11, y, s) < 0.2) and HO[1] or HO[2])
      if H(12, y, s + 2) < 0.75 and y % 12 ~= 0 then t.set(12, y, HO[4]) end
    end
  end
  -- suciedad en las juntas y manchas de tierra
  for _ = 1, 2 do
    local x = math.floor(r() * N)
    local y = (r() < 0.5) and 11 or 23
    t.set(x, y, TI[2]); t.set(x + 1, y, TI[2])
  end
  for _ = 1, 2 do
    local cx, cy = 2 + math.floor(r() * 20), 2 + math.floor(r() * 20)
    for k = 0, 4 do
      local x, y = cx + math.floor(r() * 3), cy + math.floor(r() * 2)
      if t.get(x, y) ~= HO[2] and (x % 12) ~= 11 and (y % 12) ~= 11 then t.set(x, y, HO[2]) end
    end
  end
  if fisura then
    -- fisura que cruza la losa inferior izquierda, sin tocar las juntas
    local x, y = 2, 15
    local pts = {}
    while x <= 9 do
      pts[#pts + 1] = { x, y }
      x = x + 1
      local q = H(x, y, s + 77)
      if q < 0.3 and y < 21 then y = y + 1 elseif q > 0.8 and y > 13 then y = y - 1 end
    end
    for _, p in ipairs(pts) do t.set(p[1], p[2], HO[1]) end
    for _, p in ipairs(pts) do if t.get(p[1], p[2] + 1) ~= HO[1] then t.set(p[1], p[2] + 1, HO[4]) end end
    t.set(6, 18, HO[1]); t.set(6, 19, HO[1]); t.set(7, 20, HO[1]); t.set(7, 19, HO[4]); t.set(7, 21, HO[4])
  end
end

---------------------------------------------------------------- bordillo
local function bordillo(t, s, izquierda)
  asfalto(t, s)
  local r = L.azar(s * 7 + 2)
  local x0 = izquierda and 0 or 19
  local junta = 16
  for y = 0, N - 1 do
    local cols
    if izquierda then
      -- x0..x0+2 corona, x0+3..4 cara en sombra, x0+5 cuneta
      for x = 0, 2 do
        local c = HO[4]
        local q = H(x, y, s + 11)
        if q < 0.22 then c = HO[3] elseif q > 0.86 then c = HO[5] end
        if x == 2 and q > 0.3 then c = HO[5] end -- arista que coge luz
        t.set(x, y, c)
      end
      t.set(3, y, (H(3, y, s) < 0.25) and HO[1] or HO[2])
      t.set(4, y, HO[1])
      -- cuneta: suciedad oscura pegada a la cara
      t.set(5, y, (H(5, y, s + 1) < 0.5) and A[1] or A[2])
      if H(6, y, s + 4) < 0.35 then t.set(6, y, A[2]) end
    else
      t.set(18, y, (H(18, y, s + 1) < 0.5) and A[1] or A[2])
      if H(17, y, s + 4) < 0.3 then t.set(17, y, A[2]) end
      t.set(19, y, (H(19, y, s) < 0.3) and HO[4] or HO[5])
      t.set(20, y, (H(20, y, s + 2) < 0.2) and HO[5] or HO[4])
      for x = 21, 23 do
        local c = HO[4]
        local q = H(x, y, s + 11)
        if q < 0.25 then c = HO[3] elseif q > 0.85 then c = HO[5] end
        if x == 21 and q > 0.45 then c = HO[5] end
        t.set(x, y, c)
      end
    end
  end
  -- junta entre piezas de bordillo
  if izquierda then
    for x = 0, 4 do t.set(x, junta, HO[1]) end
    for x = 0, 2 do t.set(x, junta + 1, HO[5]) end
    t.set(3, junta + 1, HO[2])
    t.set(1, 6, HO[3]); t.set(2, 6, HO[3]); t.set(2, 7, HO[2]) -- desconchón
  else
    for x = 19, 23 do t.set(x, junta, HO[2]) end
    t.set(19, junta, HO[3])
    for x = 21, 23 do t.set(x, junta + 1, HO[5]) end
    t.set(22, 6, HO[3]); t.set(23, 6, HO[3]); t.set(23, 7, HO[2])
  end
end

---------------------------------------------------------------- losetas
local fot = {}
local function loseta(f) fot[#fot + 1] = function(img) local t = nueva(); f(t); volcar(t, img) end end

-- hierba ×4: lisa, hierbajos, hojas secas, rala
loseta(function(t) hierba(t, 1, 70, 0.3) end)
loseta(function(t)
  local r = hierba(t, 2, 60, 0.3)
  hierbajo(t, 6, 8, r); hierbajo(t, 17, 18, r)
  mechon(t, 9, 9, L.azar(91), false, 1); mechon(t, 19, 20, L.azar(92), true, 1)
end)
loseta(function(t)
  local r = hierba(t, 3, 60, 0.35)
  local hs = { { 3, 4 }, { 14, 3 }, { 9, 12 }, { 19, 10 }, { 5, 19 }, { 16, 20 }, { 21, 16 } }
  for _, h in ipairs(hs) do hojaSeca(t, h[1], h[2], r) end
  for i = 1, 8 do mechon(t, math.floor(r() * N), math.floor(r() * N), L.azar(300 + i), r() < 0.5) end
end)
loseta(function(t)
  local r = hierba(t, 4, 34, 0.45)
  -- tierra asomando entre la hierba rala
  for _ = 1, 9 do
    local x, y = math.floor(r() * N), math.floor(r() * N)
    t.set(x, y, TI[3]); t.set(x + 1, y, TI[2]); if r() < 0.5 then t.set(x, y + 1, TI[2]) end
  end
  for i = 1, 14 do mechon(t, math.floor(r() * N), math.floor(r() * N), L.azar(400 + i), r() < 0.6) end
end)

-- asfalto ×4: liso, parche, aceite, desgaste
loseta(function(t) asfalto(t, 10) end)
loseta(function(t)
  asfalto(t, 11)
  -- parche de asfalto más nuevo, algo más oscuro, con junta de betún irregular
  local pol = { { 6, 7 }, { 15, 6 }, { 16, 9 }, { 17, 16 }, { 8, 17 }, { 5, 13 } }
  local dentro = {}
  local tmp = Image(N, N, ColorMode.RGB)
  L.poligono(tmp, pol, L.hex("ffffff"))
  for y = 0, N - 1 do for x = 0, N - 1 do
    if app.pixelColor.rgbaA(tmp:getPixel(x, y)) > 0 then
      dentro[y * N + x] = true
      local c = t.get(x, y)
      if c == A[2] and H(x, y, 4) < 0.35 then c = A[1] elseif c == A[3] then c = A[2] elseif c == A[4] then c = (H(x, y, 3) < 0.5) and A[3] or A[2] elseif c == A[5] then c = A[3] end
      t.set(x, y, c)
    end
  end end
  for y = 1, N - 2 do for x = 1, N - 2 do
    if dentro[y * N + x] and (not dentro[(y - 1) * N + x] or not dentro[y * N + x - 1] or not dentro[(y + 1) * N + x] or not dentro[y * N + x + 1]) then
      if H(x, y, 8) < 0.8 then t.set(x, y, A[1]) end
    end
  end end
end)
loseta(function(t)
  asfalto(t, 12)
  for y = 3, 20 do for x = 3, 20 do
    local dx, dy = (x + 0.5 - 12 - (y - 12) * 0.4) / 6.5, (y + 0.5 - 12) / 3.6
    local d = dx * dx + dy * dy + (vn(x, y, 3, 21) - 0.5) * 1.0
    if d < 1 then
      local c = ACEITE[2]
      if d < 0.3 and H(x, y, 22) < 0.5 then c = ACEITE[1] end
      if d > 0.7 then c = A[2] end
      t.set(x, y, c)
    end
  end end
  -- brillo apagado del aceite arriba a la izquierda
  t.set(10, 10, ACEITE[4]); t.set(11, 10, ACEITE[3]); t.set(10, 11, ACEITE[3])
end)
loseta(function(t)
  asfalto(t, 13, function(x, y)
    local dx, dy = (x - 12) / 9, (y - 12) / 8
    local d = dx * dx + dy * dy
    return 1 + math.max(0, 1 - d) * (vn(x, y, 4, 33) * 1.6)
  end)
end)

-- grieta ×2
loseta(function(t)
  asfalto(t, 14)
  local r = L.azar(77)
  grieta(t, r, 4, 7, 0.5, 18, 2)
end)
loseta(function(t)
  asfalto(t, 15)
  local r = L.azar(78)
  grieta(t, r, 15, 4, 1.9, 16, 1)
  grieta(t, r, 6, 14, 0.35, 8, 0)
end)

-- línea amarilla gastada (x 11..13, y 3..20)
loseta(function(t)
  asfalto(t, 16)
  for y = 3, 20 do for x = 11, 13 do
    local q = vn(x, y, 3, 61) * 0.7 + H(x, y, 62) * 0.3
    local c = SE[2]
    if q > 0.62 then c = SE[3] end
    if H(x, y, 63) < 0.12 then c = SE[1] end -- árido que asoma
    -- desconchones: grupos donde se ve el asfalto
    local chip = vn(x, y, 3, 64)
    local borde = (y <= 4 or y >= 19) and 0.12 or 0
    if chip < 0.16 + borde and H(x, y, 65) < 0.8 then c = t.get(x, y) end
    t.set(x, y, c)
  end end
end)

-- acera ×2
loseta(function(t) acera(t, 20) end)
loseta(function(t) acera(t, 21, true) end)

-- bordillos
loseta(function(t) bordillo(t, 17, true) end)
loseta(function(t) bordillo(t, 18, false) end)

-- tierra ×2: calva de tierra en el centro de la hierba
local function calva(t, s, rx, ry, cx, cy)
  local dentro = function(x, y)
    if x < 2 or x > 21 or y < 2 or y > 21 then return false end
    local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
    return dx * dx + dy * dy + (vn(x, y, 3, s) - 0.5) * 0.8 < 1
  end
  local r = hierba(t, s + 100, 60, 0.3, function(x, y) return not dentro(x, y) end)
  for y = 2, 21 do for x = 2, 21 do
    if dentro(x, y) then
      local c = TI[3]
      local q = vn(x, y, 3, s + 5) * 0.6 + H(x, y, s) * 0.4
      if q < 0.32 then c = TI[2] elseif q > 0.78 then c = TI[4] end
      -- borde superior/izquierdo en sombra (la hierba sobresale)
      if not dentro(x, y - 1) or not dentro(x - 1, y) then c = TI[2] end
      if not dentro(x, y - 1) and not dentro(x - 1, y) then c = TI[1] end
      t.set(x, y, c)
    end
  end end
  -- piedrecitas
  for i = 1, 7 do
    local x, y = math.floor(cx - rx + 2 + r() * (rx * 2 - 4)), math.floor(cy - ry + 2 + r() * (ry * 2 - 4))
    if dentro(x, y) and dentro(x + 1, y + 1) then
      t.set(x, y, HO[3])
      if i % 2 == 0 then t.set(x + 1, y, HO[3]); t.set(x + 2, y + 1, TI[1]) end
      t.set(x + 1, y + 1, TI[1])
      if i == 3 then t.set(x, y - 1, HO[4]) end
    end
  end
  -- briznas que invaden la calva por el borde
  for i = 1, 30 do
    local x, y = 2 + math.floor(r() * 20), 2 + math.floor(r() * 20)
    if dentro(x, y) and not (dentro(x, y + 2) and dentro(x - 1, y) and dentro(x + 1, y)) then
      mechon(t, x, y, L.azar(s * 50 + i), r() < 0.5)
    end
  end
end
loseta(function(t) calva(t, 41, 7.5, 6.5, 12, 12.5) end)
loseta(function(t) calva(t, 42, 8.5, 4.5, 11.5, 12.5) end)

L.construir("suelo", N, N, fot, {
  { "hierba", 1, 4 }, { "asfalto", 5, 8 }, { "grieta", 9, 10 }, { "linea", 11, 11 },
  { "acera", 12, 13 }, { "bordillo_i", 14, 14 }, { "bordillo_d", 15, 15 }, { "tierra", 16, 17 },
}, 0.2)
