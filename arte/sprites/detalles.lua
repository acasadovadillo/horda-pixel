-- Detalles de suelo (24x24, fondo transparente, 8 fotogramas):
-- 0 papeles y basura, 1 hojas secas, 2 marcas de frenada, 3 mancha de aceite,
-- 4 tapa de alcantarilla, 5 cascotes, 6 cristales rotos, 7 hierbajos en una grieta.
local L = dofile(app.params.lib)
local N = 24
local pc = app.pixelColor

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

local T = L.rampa("tela")
local M = L.rampa("metal")
local A = L.rampa("asfalto")
local HO = L.rampa("hormigon")
local G = L.rampa("hierba")
local HJ = L.rampa("hojas")
local OX = L.rampa("oxido")
local CR = { L.hex("1c262c"), L.hex("34444c"), L.hex("587078"), L.hex("8aa2a8"), L.hex("c4d4d6") }
local RA = L.rampa("ropa_a")
local RC = L.rampa("ropa_c")
local TI = L.rampa("tierra")
local GOMA = { L.hex("141418"), L.hex("1b1b20"), L.hex("23232a") }
local ACEITE = { L.hex("15161a"), L.hex("1d1e24"), L.hex("272832"), L.hex("353447"), L.hex("2e403c") }
local OCRE = { L.hex("3e2a14"), L.hex("5e401c"), L.hex("82602c"), L.hex("a07c3e") }
local MARRON = { L.hex("2e1c12"), L.hex("4a2e1c"), L.hex("6a4428"), L.hex("865a36") }
local ROJIZA = { L.hex("3a1a10"), L.hex("5c2a18"), L.hex("7e4024"), L.hex("9a5a34") }
local LADRILLO = { L.hex("3e1c14"), L.hex("5e2c1e"), L.hex("7e3f2a"), L.hex("9c5a3e") }

-- contorno solo abajo y a la derecha de lo ya dibujado
local function contornoBD(img, c)
  L.contorno(img, c, { solo = function(x, y) return L.opaco(img, x - 1, y) or L.opaco(img, x, y - 1) end })
end
-- copia en otra imagen para contornear un objeto sin afectar a los demás
local function capa() return Image(N, N, ColorMode.RGB) end

local fot = {}

---------------------------------------------------------------- 0 papeles y basura
fot[1] = function(img)
  -- hoja de periódico doblada
  local p = capa()
  L.poligono(p, { { 2, 4 }, { 11, 3 }, { 12, 10 }, { 3, 11 } }, T[2])
  L.poligono(p, { { 2, 4 }, { 11, 3 }, { 11.5, 6.5 }, { 2.5, 7.5 } }, T[3]) -- mitad que coge luz
  for _, f in ipairs({ { 4, 5, 8 }, { 4, 9, 7 }, { 5, 10, 6 } }) do
    for x = f[1], f[3] do if (x + f[2]) % 4 ~= 0 then L.px(p, x, f[2], f[2] < 8 and T[2] or T[1]) end end
  end
  L.linea(p, 3, 8, 11, 7, T[1]) -- pliegue
  
  contornoBD(p, L.hex('3e3c36'))
  L.pegar(img, p, 0, 0)
  -- bola de papel arrugado
  p = capa()
  L.elipse(p, 16.5, 6.5, 2.6, 2.2, T[2])
  L.px(p, 15, 5, T[3]); L.px(p, 16, 5, T[4]); L.px(p, 15, 6, T[3]); L.px(p, 17, 6, T[2]); L.px(p, 16, 7, T[2])
  L.px(p, 17, 8, T[2]); L.px(p, 18, 7, T[2])
  contornoBD(p, T[1])
  L.pegar(img, p, 0, 0)
  -- lata aplastada tumbada
  p = capa()
  L.rect(p, 5, 16, 7, 3, M[4])
  L.rect(p, 6, 16, 5, 1, M[5])
  L.rect(p, 7, 17, 3, 1, RA[3]); L.px(p, 10, 17, RA[2]); L.px(p, 6, 17, RA[3])
  L.rect(p, 5, 18, 7, 1, M[3])
  L.px(p, 8, 16, M[3]); L.px(p, 8, 18, M[2]) -- abolladura
  L.px(p, 4, 17, M[4]); L.px(p, 4, 16, M[5]); L.px(p, 12, 17, M[3]); L.px(p, 12, 16, M[4])
  contornoBD(p, M[1])
  L.pegar(img, p, 0, 0)
  -- envoltorio arrugado
  p = capa()
  L.poligono(p, { { 15, 15 }, { 20, 14 }, { 21, 18 }, { 16, 19 } }, RC[3])
  L.px(p, 16, 15, RC[4]); L.px(p, 17, 15, RC[4]); L.px(p, 16, 16, RC[4])
  L.px(p, 18, 16, RC[2]); L.px(p, 19, 17, RC[2]); L.px(p, 17, 17, T[3]); L.px(p, 18, 17, T[3])
  contornoBD(p, RC[1])
  L.pegar(img, p, 0, 0)
  -- colilla
  L.px(img, 19, 10, T[4]); L.px(img, 20, 10, T[3]); L.px(img, 21, 10, RC[3]); L.px(img, 20, 11, T[1]); L.px(img, 21, 11, RC[1])
end

---------------------------------------------------------------- 1 hojas secas
local function hoja(img, cx, cy, ang, largo, ancho, R)
  local p = capa()
  local ux, uy = math.cos(ang), math.sin(ang) * 0.8
  for y = 0, N - 1 do for x = 0, N - 1 do
    local dx, dy = x + 0.5 - cx, y + 0.5 - cy
    local a = dx * ux + dy * uy        -- a lo largo
    local b = -dx * uy + dy * ux       -- a lo ancho
    local t = a / largo
    if t > -1 and t < 1 then
      local w = ancho * math.sqrt(1 - t * t) * (t > 0 and (1 - t * 0.3) or 1)
      if math.abs(b) <= w then
        local c = (b < -0.3) and R[4] or R[3]
        if b > w - 0.9 then c = R[2] end
        L.px(p, x, y, c)
      end
    end
  end end
  -- nervio central y rabillo
  for k = -largo + 1, largo - 1 do L.px(p, cx + ux * k - 0.5, cy + uy * k - 0.5, R[2]) end
  L.px(p, cx - ux * (largo + 0.6) - 0.5, cy - uy * (largo + 0.6) - 0.5, R[1])
  contornoBD(p, R[1])
  L.pegar(img, p, 0, 0)
end
fot[2] = function(img)
  hoja(img, 6, 6, 0.4, 3.6, 1.8, OCRE)
  hoja(img, 15, 5, 2.4, 3.2, 1.6, MARRON)
  hoja(img, 11, 12, -0.3, 4, 2.0, ROJIZA)
  hoja(img, 19, 13, 1.3, 3, 1.5, OCRE)
  hoja(img, 5, 17, 2.9, 3.4, 1.7, MARRON)
  hoja(img, 14, 19, 0.9, 3.3, 1.7, OCRE)
  -- trocitos
  L.px(img, 20, 20, MARRON[3]); L.px(img, 21, 20, MARRON[2]); L.px(img, 9, 20, OCRE[3]); L.px(img, 10, 20, OCRE[2])
end

---------------------------------------------------------------- 2 marcas de frenada
fot[3] = function(img)
  local function marca(x0, ancho, curva, ini, fin, s)
    for y = ini, fin do
      local t = (y - ini) / (fin - ini)
      local cx = x0 + curva * t * t
      for k = 0, ancho - 1 do
        local x = math.floor(cx + k)
        local borde = (t < 0.15 and H(x, y, s) < 0.6 - t * 3) -- empieza a trozos
        local hueco = (y % 3 == 0 and k == 1 and H(x, y, s + 1) < 0.5) -- dibujo de la rueda
        if not borde and not hueco then
          local c = GOMA[2]
          if k == 0 or k == ancho - 1 then c = GOMA[3] end
          if H(x, y, s + 2) < 0.15 then c = GOMA[1] end
          L.px(img, x, y, c)
        end
      end
    end
  end
  marca(4, 4, 5, 1, 22, 1)
  marca(14, 4, 4, 5, 22, 2)
end

---------------------------------------------------------------- 3 mancha de aceite
fot[4] = function(img)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local dx, dy = (x + 0.5 - 11) / 8, (y + 0.5 - 12.5) / 6
    local d = dx * dx + dy * dy + (vn(x, y, 4, 5) - 0.5) * 0.9
    local dx2, dy2 = (x + 0.5 - 18.5) / 2.6, (y + 0.5 - 17.5) / 2
    local d2 = dx2 * dx2 + dy2 * dy2
    if d < 1 or d2 < 1 then
      local c = ACEITE[2]
      if d < 0.35 then c = ACEITE[1] elseif d > 0.75 and d2 >= 1 then c = ACEITE[3] end
      L.px(img, x, y, c)
    end
  end end
  -- irisación apagada en el borde superior izquierdo
  for _, p in ipairs({ { 6, 9, 4 }, { 7, 9, 4 }, { 8, 8, 4 }, { 9, 8, 5 }, { 10, 8, 5 } }) do
    L.px(img, p[1], p[2], ACEITE[p[3]])
  end
  -- gotas
  L.px(img, 3, 18, ACEITE[2]); L.px(img, 4, 18, ACEITE[2]); L.px(img, 21, 7, ACEITE[2]); L.px(img, 21, 8, ACEITE[2])
end

---------------------------------------------------------------- 4 tapa de alcantarilla
fot[5] = function(img)
  local cx, cy = 12, 11.5
  -- cerco de hierro con su canto sur
  L.elipse(img, cx, cy + 1, 10.5, 7.2, M[1])
  L.elipse(img, cx, cy, 10.5, 7.2, M[3])
  L.elipse(img, cx, cy, 9, 6, M[2])        -- ranura
  L.elipse(img, cx, cy + 0.3, 8.6, 5.7, M[3]) -- tapa
  for y = 0, N - 1 do for x = 0, N - 1 do
    local c = L.get(img, x, y)
    local dx, dy = (x + 0.5 - cx) / 10.5, (y + 0.5 - cy) / 7.2
    local d = dx * dx + dy * dy
    -- cerco: luz arriba a la izquierda, sombra abajo a la derecha
    if c == M[3] and d > 0.72 then
      if dx + dy < -0.35 then L.px(img, x, y, M[5]) elseif dx + dy > 0.45 then L.px(img, x, y, M[2]) end
    end
    -- tapa: retícula de tacos en relieve
    local ex, ey = (x + 0.5 - cx) / 8.6, (y + 0.5 - cy - 0.3) / 5.7
    if ex * ex + ey * ey < 0.78 then
      if x % 3 == 0 and y % 2 == 0 then
        L.px(img, x, y, M[4]); L.px(img, x + 1, y + 1, M[2])
      end
    end
  end end
  -- óxido en la mitad baja
  for y = 0, N - 1 do for x = 0, N - 1 do
    local ex, ey = (x + 0.5 - cx) / 8.6, (y + 0.5 - cy - 0.3) / 5.7
    if ex * ex + ey * ey < 0.9 and vn(x, y, 3, 9) > 0.68 and y > 11 then
      L.px(img, x, y, (H(x, y, 3) < 0.6) and OX[1] or OX[2])
    end
  end end
  -- agujeros de izado
  L.px(img, 7, 11, A[1]); L.px(img, 8, 11, A[1]); L.px(img, 16, 12, A[1]); L.px(img, 17, 12, A[1])
  L.px(img, 7, 12, M[4]); L.px(img, 16, 13, M[4])
  -- canto sur del cerco en sombra
  contornoBD(img, A[1])
end

---------------------------------------------------------------- 5 cascotes
local function cascote(img, pts, alto, R)
  local p = capa()
  -- cara sur: el mismo polígono desplazado hacia abajo
  local sur = {}
  for i, q in ipairs(pts) do sur[i] = { q[1], q[2] + alto } end
  L.poligono(p, sur, R[2])
  L.poligono(p, pts, R[3])
  -- arista iluminada arriba a la izquierda
  local minx, miny = 99, 99
  for _, q in ipairs(pts) do minx = math.min(minx, q[1]); miny = math.min(miny, q[2]) end
  for y = 0, N - 1 do for x = 0, N - 1 do
    if L.get(p, x, y) == R[3] and (L.get(p, x - 1, y) == 0 or L.get(p, x, y - 1) == 0) then L.px(p, x, y, R[4]) end
  end end
  contornoBD(p, R[1])
  L.pegar(img, p, 0, 0)
end
fot[6] = function(img)
  local HR = { HO[1], HO[2], HO[3], HO[4] }
  cascote(img, { { 3, 6 }, { 8, 4 }, { 11, 7 }, { 9, 10 }, { 4, 10 } }, 2, HR)
  cascote(img, { { 13, 11 }, { 19, 10 }, { 20, 14 }, { 14, 15 } }, 2, LADRILLO)
  cascote(img, { { 5, 15 }, { 9, 14 }, { 10, 17 }, { 6, 18 } }, 1, HR)
  cascote(img, { { 15, 4 }, { 18, 3 }, { 19, 6 }, { 16, 7 } }, 1, HR)
  cascote(img, { { 16, 18 }, { 19, 18 }, { 19, 20 }, { 16, 20 } }, 1, LADRILLO)
  -- grava y polvo
  for _, q in ipairs({ { 12, 8 }, { 2, 13 }, { 11, 19 }, { 21, 8 }, { 13, 3 } }) do
    L.px(img, q[1], q[2], HO[3]); L.px(img, q[1] + 1, q[2], HO[2]); L.px(img, q[1] + 1, q[2] + 1, HO[1])
  end
end

---------------------------------------------------------------- 6 cristales rotos
local function esquirla(img, pts, brillo)
  local p = capa()
  L.poligono(p, pts, CR[3])
  for y = 0, N - 1 do for x = 0, N - 1 do
    if L.opaco(p, x, y) then
      if L.get(p, x - 1, y) == 0 or L.get(p, x, y - 1) == 0 then L.px(p, x, y, CR[4]) end
    end
  end end
  if brillo then L.px(p, brillo[1], brillo[2], CR[5]) end
  contornoBD(p, CR[2])
  L.pegar(img, p, 0, 0)
end
fot[7] = function(img)
  esquirla(img, { { 8, 8 }, { 13, 7 }, { 10, 11 } }, { 9, 8 })
  esquirla(img, { { 14, 10 }, { 18, 12 }, { 14, 13 } }, { 15, 11 })
  esquirla(img, { { 5, 13 }, { 10, 12 }, { 8, 17 } }, { 6, 13 })
  esquirla(img, { { 11, 14 }, { 15, 15 }, { 12, 17 } }, { 12, 15 })
  esquirla(img, { { 17, 5 }, { 20, 6 }, { 18, 8 } }, nil)
  esquirla(img, { { 3, 9 }, { 5, 8 }, { 5, 11 } }, nil)
  for _, q in ipairs({ { 19, 16 }, { 4, 18 }, { 15, 19 } }) do
    L.px(img, q[1], q[2], CR[4]); L.px(img, q[1] + 1, q[2], CR[2])
  end
end

---------------------------------------------------------------- 7 hierbajos en una grieta
fot[8] = function(img)
  -- grieta
  local pts = {}
  local x, y = 1, 15
  local r = L.azar(12)
  while x <= 22 do
    pts[#pts + 1] = { x, y }
    x = x + 1
    local q = r()
    if q < 0.3 and y > 8 then y = y - 1 elseif q > 0.85 and y < 17 then y = y + 1 end
  end
  for _, p in ipairs(pts) do
    L.px(img, p[1], p[2], A[1])
    if p[1] > 7 and p[1] < 15 then L.px(img, p[1], p[2] - 1, A[1]) end -- más abierta donde sale la hierba
  end
  for _, p in ipairs(pts) do
    if not L.opaco(img, p[1], p[2] + 1) then L.px(img, p[1], p[2] + 1, A[5]) end
  end
  for _, p in ipairs(pts) do if p[1] > 7 and p[1] < 15 then L.px(img, p[1], p[2] - 2, A[4]) end end
  -- tierra en la grieta
  local bx, by
  for _, p in ipairs(pts) do if p[1] == 11 then bx, by = p[1], p[2] end end
  L.px(img, bx - 1, by, TI[2]); L.px(img, bx, by, TI[2]); L.px(img, bx + 1, by - 1, TI[2])
  -- mechón de briznas
  local function brizna(x0, y0, dx, h, claro, R)
    for k = 0, h - 1 do
      local xx = x0 + math.floor(dx * k / h + 0.5)
      local tono = (k == 0) and 2 or ((k < h - 2) and 3 or 4)
      if claro then tono = tono + 1 end
      L.px(img, xx, y0 - k, R[math.min(5, tono)])
    end
  end
  brizna(bx - 2, by, -3, 6, true, G)
  brizna(bx - 1, by, -1, 8, true, G)
  brizna(bx, by, 0, 7, false, G)
  brizna(bx + 1, by - 1, 2, 7, false, G)
  brizna(bx + 2, by - 1, 4, 5, false, G)
  -- hojas anchas de diente de león a los lados
  for _, h in ipairs({ { -5, 1, true }, { 4, 1, false }, { -4, -2, true } }) do
    local ex = bx + h[1]
    local s = h[1] < 0 and -1 or 1
    for k = 0, math.abs(h[1]) do
      local xx = bx + s * k
      local yy = by + (k > 1 and h[2] or 0)
      L.px(img, xx, yy, HJ[h[3] and 5 or 4]); L.px(img, xx, yy + 1, HJ[h[3] and 3 or 2])
    end
    L.px(img, ex, by + h[2], HJ[4])
  end
  -- segundo mechón pequeño
  local cx2, cy2
  for _, p in ipairs(pts) do if p[1] == 19 then cx2, cy2 = p[1], p[2] end end
  brizna(cx2 - 1, cy2, -1, 4, true, G)
  brizna(cx2, cy2, 0, 5, false, G)
  brizna(cx2 + 1, cy2, 2, 3, false, G)
  L.px(img, cx2 + 1, cy2 + 1, G[1])
end

L.construir("detalles", N, N, fot, nil, 0.2)
