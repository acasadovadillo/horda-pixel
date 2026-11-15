-- Árbol (48x64), vista 3/4 cenital. 0 frondoso, 1 otoñal medio pelado, 2 seco.
-- La copa se modela como un relieve de masas de hojas (esferas) iluminado desde arriba a la izquierda.
local L = dofile(app.params.lib)
local W, H = 48, 64

local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local VERDE  = R{ "132016", "1e3320", "2e4a2a", "426438", "5b7f48", "789a5a" }
local OCRE   = R{ "2c1f14", "4a3319", "6b4b24", "8c6a35", "a8874c" }
local ROJIZO = R{ "2c1610", "4d2616", "6e3a1f", "8c532b", "a66c3a" }
local CORTEZA = R{ "1e1610", "32241a", "4a3626", "634a34", "7a5e44" }
local GRIS   = R{ "1c1916", "352f29", "4f463d", "6b6053", "877b6a" }

local LX, LY, LZ = -0.52, -0.62, 0.58
do local n = math.sqrt(LX * LX + LY * LY + LZ * LZ); LX, LY, LZ = LX / n, LY / n, LZ / n end

---------------------------------------------------------------- rejilla
local function rejilla() return { k = {}, c = {}, r = {}, lv = {} } end
local function I(x, y) return y * W + x end
local function dentro(x, y) return x >= 0 and y >= 0 and x < W and y < H end

local function ruidoValor(sem, celda)
  local r = L.azar(sem); local t = {}
  for i = 0, 64 * 64 do t[i] = r() end
  return function(x, y)
    local gx, gy = x / celda, y / celda
    local x0, y0 = math.floor(gx), math.floor(gy)
    local fx, fy = gx - x0, gy - y0
    local function g(a, b) return t[(b % 64) * 64 + (a % 64)] end
    local a = g(x0, y0) * (1 - fx) + g(x0 + 1, y0) * fx
    local b = g(x0, y0 + 1) * (1 - fx) + g(x0 + 1, y0 + 1) * fx
    return a * (1 - fy) + b * fy
  end
end

---------------------------------------------------------------- madera
local function segmento(G, x0, y0, x1, y1, g, rampa)
  local rr = g / 2
  local dx, dy = x1 - x0, y1 - y0
  local l2 = dx * dx + dy * dy
  local kind = g <= 1.3 and "ramita" or "rama"
  for y = math.floor(math.min(y0, y1) - rr - 1), math.ceil(math.max(y0, y1) + rr + 1) do
    for x = math.floor(math.min(x0, x1) - rr - 1), math.ceil(math.max(x0, x1) + rr + 1) do
      if dentro(x, y) then
        local cx, cy = x + 0.5, y + 0.5
        local t = l2 > 0 and math.max(0, math.min(1, ((cx - x0) * dx + (cy - y0) * dy) / l2)) or 0
        local qx, qy = x0 + dx * t, y0 + dy * t
        local lim = math.max(rr, 0.5)
        if (cx - qx) ^ 2 + (cy - qy) ^ 2 <= lim * lim then
          local i = I(x, y)
          if G.k[i] ~= "tronco" and not (G.k[i] == "rama" and kind == "ramita") then
            G.k[i] = kind; G.r[i] = rampa
          end
        end
      end
    end
  end
end

-- Ramas recursivas; ang en radianes en pantalla (arriba = -pi/2).
local function ramas(G, x, y, ang, largo, g, prof, r, rampa, abre)
  local mx = x + math.cos(ang) * largo * 0.5 + (r() - 0.5) * 1.2
  local my = y + math.sin(ang) * largo * 0.5 + (r() - 0.5) * 1.2
  local x2 = x + math.cos(ang) * largo
  local y2 = y + math.sin(ang) * largo
  segmento(G, x, y, mx, my, g, rampa)
  segmento(G, mx, my, x2, y2, math.max(1, g * 0.85), rampa)
  if prof > 0 then
    local n = (r() < 0.35) and 3 or 2
    for j = 1, n do
      local a = ang + abre * (j - (n + 1) / 2) * (n == 3 and 1 or 1.3) + (r() - 0.5) * 0.35
      -- tendencia a crecer hacia arriba
      a = a + (-math.pi / 2 - a) * 0.15
      ramas(G, x2, y2, a, largo * (0.62 + r() * 0.18), math.max(1, g * 0.62), prof - 1, r, rampa, abre * 0.95)
    end
  end
end

local function tronco(G, rampa, ytop, ybase, xc, wtop, wbase, sem)
  local nb = ruidoValor(sem, 2)
  for y = ytop, ybase do
    local t = (y - ytop) / (ybase - ytop)
    local hw = (wtop + (wbase - wtop) * t) / 2
    local fl = ybase - y
    if fl < 6 then hw = hw + (6 - fl) ^ 2 * 0.06 end
    local cx = xc + math.sin(t * 2.2) * 0.6
    local xl, xr = math.floor(cx - hw + 0.5), math.floor(cx + hw - 0.5)
    for x = xl, xr do
      local i = I(x, y)
      G.k[i] = "tronco"; G.r[i] = rampa
      local u = (x - xl + 0.5) / (xr - xl + 1)
      local lv = u < 0.28 and 4 or (u < 0.6 and 3 or 2)
      -- corteza: vetas verticales
      local v = nb(x * 2.5, y * 0.45)
      if v < 0.3 and lv > 2 then lv = lv - 1 end
      if v > 0.78 and lv == 3 then lv = 4 end
      G.lv[i] = lv
    end
  end
end

-- Sombrea ramas (no el tronco, que ya tiene su nivel).
local function sombrearMadera(G)
  local function madera(x, y) local k = G.k[I(x, y)]; return k == "rama" or k == "tronco" or k == "ramita" end
  for y = 0, H - 1 do for x = 0, W - 1 do
    local i = I(x, y)
    if G.k[i] == "rama" then
      local lv = 3
      if not madera(x - 1, y) or not madera(x, y - 1) then lv = 4 end
      if not madera(x + 1, y) or not madera(x, y + 1) then lv = (lv == 4) and 3 or 2 end
      G.lv[i] = lv
    elseif G.k[i] == "ramita" then
      G.lv[i] = (not madera(x - 1, y) and not madera(x, y - 1)) and 4 or 3
    end
  end end
end

---------------------------------------------------------------- copa
local function copa(G, mayores, op)
  local r = L.azar(op.sem)
  local esf = {}
  for _, m in ipairs(mayores) do
    esf[#esf + 1] = { x = m[1], y = m[2], r = m[3], z = m[4], ra = m.ra or op.rampa }
    local nsub = math.floor(m[3] * (op.subs or 1.3) + 0.5)
    for _ = 1, nsub do
      local a = r() * math.pi * 2
      local d = math.sqrt(r()) * (m[3] - 1.0)
      local rs = 1.8 + r() * (m[3] * 0.34)
      local sx, sy = m[1] + math.cos(a) * d, m[2] + math.sin(a) * d * 0.9
      local sup = m[4] + math.sqrt(math.max(0, m[3] * m[3] - d * d))
      esf[#esf + 1] = { x = sx, y = sy, r = rs, z = sup - rs * 0.55, ra = m.ra or op.rampa }
      for _ = 1, (op.micro or 3) do
        local b = r() * math.pi * 2
        local e = rs * (0.55 + r() * 0.5)
        local rm = 1.1 + r() * 0.9
        local zx = sup - rs * 0.55 + math.sqrt(math.max(0, rs * rs - e * e))
        esf[#esf + 1] = { x = sx + math.cos(b) * e, y = sy + math.sin(b) * e, r = rm, z = zx - rm * 0.5, ra = m.ra or op.rampa }
      end
    end
  end
  local Hh, own = {}, {}
  for ci, c in ipairs(esf) do
    for y = math.floor(c.y - c.r), math.ceil(c.y + c.r) do
      for x = math.floor(c.x - c.r), math.ceil(c.x + c.r) do
        if dentro(x, y) and y <= (op.ymax or H) and x >= (op.xmin or 0) and x <= (op.xmax or W) then
          local dx, dy = x + 0.5 - c.x, y + 0.5 - c.y
          local d2 = dx * dx + dy * dy
          if d2 <= c.r * c.r then
            local h = c.z + math.sqrt(c.r * c.r - d2)
            local i = I(x, y)
            if not Hh[i] or h > Hh[i] then Hh[i] = h; own[i] = ci end
          end
        end
      end
    end
  end
  if op.huecos then
    local nh = ruidoValor(op.sem + 7, op.celdaHueco or 3)
    for i in pairs(Hh) do
      local x, y = i % W, i // W
      if nh(x, y) < op.huecos then Hh[i] = nil end
    end
  end
  local nt = ruidoValor(op.sem + 3, 1.6)
  local vals, lista = {}, {}
  local function h(x, y) return Hh[I(x, y)] end
  for i, hv in pairs(Hh) do
    local x, y = i % W, i // W
    local function hn(xx, yy) return h(xx, yy) or (hv - 3.5) end
    local gx = (hn(x + 1, y) - hn(x - 1, y)) / 2
    local gy = (hn(x, y + 1) - hn(x, y - 1)) / 2
    local nx, ny, nz = -gx, -gy, 1
    local nl = math.sqrt(nx * nx + ny * ny + nz * nz)
    local s = (nx * LX + ny * LY + nz * LZ) / nl
    local sum, n = 0, 0
    for oy = -2, 2 do for ox = -2, 2 do sum = sum + (h(x + ox, y + oy) or hv - 4); n = n + 1 end end
    s = s + (hv - sum / n) * (op.ao or 0.07)
    s = s - (y - op.y0) / (op.y1 - op.y0) * (op.vert or 0.35) - (x - op.cx) / op.rx * (op.horiz or 0.15)
    s = s + (nt(x, y) - 0.5) * (op.tex or 0.3)
    vals[i] = s; lista[#lista + 1] = s
  end
  table.sort(lista)
  local pct = op.pct or { 0.13, 0.36, 0.62, 0.84, 0.95 }
  local thr = {}
  for j, p in ipairs(pct) do thr[j] = lista[math.max(1, math.floor(#lista * p))] or 0 end
  local lv = {}
  for i, s in pairs(vals) do
    local l = 1
    for j = 1, #thr do if s > thr[j] then l = j + 1 end end
    lv[i] = l
  end
  -- quitar píxeles sueltos de un nivel distinto a todos sus vecinos
  for _ = 1, 2 do
    for i, l in pairs(lv) do
      local x, y = i % W, i // W
      local cuenta, igual = {}, 0
      for _, d in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
        local q = lv[I(x + d[1], y + d[2])]
        if q then cuenta[q] = (cuenta[q] or 0) + 1; if q == l then igual = igual + 1 end end
      end
      if igual == 0 then
        local mejor, mc = l, 0
        for q, c in pairs(cuenta) do if c > mc then mejor, mc = q, c end end
        if mc >= 2 then lv[i] = mejor end
      end
    end
  end
  for i, l in pairs(lv) do
    G.k[i] = "hoja"; G.r[i] = esf[own[i]].ra; G.lv[i] = l
  end
end

-- Oscurece la madera justo bajo la copa.
local function sombraCopa(G, alto)
  for x = 0, W - 1 do
    local hoja = -99
    for y = 0, H - 1 do
      local i = I(x, y)
      if G.k[i] == "hoja" then hoja = y
      elseif (G.k[i] == "tronco" or G.k[i] == "rama") and y - hoja <= alto then
        G.lv[i] = math.max(1, (G.lv[i] or 3) - ((y - hoja <= alto // 2) and 2 or 1))
      end
    end
  end
end

---------------------------------------------------------------- pintar
local function volcar(img, G)
  -- huecos exteriores (conectados con el borde del lienzo): solo ahí va el contorno
  local ext, pila = {}, {}
  for x = 0, W - 1 do pila[#pila + 1] = { x, 0 }; pila[#pila + 1] = { x, H - 1 } end
  for y = 0, H - 1 do pila[#pila + 1] = { 0, y }; pila[#pila + 1] = { W - 1, y } end
  while #pila > 0 do
    local p = table.remove(pila)
    local x, y = p[1], p[2]
    local i = I(x, y)
    if dentro(x, y) and not ext[i] and (not G.k[i] or G.k[i] == "ramita") then
      ext[i] = true
      pila[#pila + 1] = { x + 1, y }; pila[#pila + 1] = { x - 1, y }
      pila[#pila + 1] = { x, y + 1 }; pila[#pila + 1] = { x, y - 1 }
    end
  end
  local borde = {}
  for y = 0, H - 1 do for x = 0, W - 1 do
    local i = I(x, y)
    if not G.k[i] and ext[i] then
      local function o(xx, yy) local j = I(xx, yy); return dentro(xx, yy) and G.k[j] and G.k[j] ~= "ramita" and j end
      local a = o(x - 1, y) or o(x, y - 1)        -- forma arriba/izquierda: este píxel es borde abajo/derecha
      local b = o(x + 1, y) or o(x, y + 1)
      if a then borde[i] = G.r[a][1]
      elseif b then borde[i] = G.r[b][G.k[b] == "hoja" and 2 or 1] end
    end
  end end
  for y = 0, H - 1 do for x = 0, W - 1 do
    local i = I(x, y)
    if G.k[i] then L.px(img, x, y, G.r[i][G.lv[i] or 3])
    elseif borde[i] then L.px(img, x, y, borde[i]) end
  end end
end

---------------------------------------------------------------- variantes
local MAYORES = {
  { 24, 12, 10, 6 },
  { 13, 18, 8, 4 }, { 35, 17, 8.5, 4 },
  { 8, 29, 6, 1 }, { 40, 30, 6, 1 },
  { 19, 26, 9, 5 }, { 31, 27, 9, 5 },
  { 14, 36, 6, 0 }, { 25, 37, 7, 1 }, { 36, 36, 5.5, 0 },
}

local function frondoso(img)
  local G = rejilla()
  tronco(G, CORTEZA, 30, 62, 24, 4.5, 6.5, 11)
  local r = L.azar(5)
  segmento(G, 23, 46, 16, 36, 2.5, CORTEZA)
  segmento(G, 25, 45, 32, 36, 2.5, CORTEZA)
  sombrearMadera(G)
  copa(G, MAYORES, { sem = 21, rampa = VERDE, y0 = 2, y1 = 44, cx = 24, rx = 22, vert = 0.5, horiz = 0.22 })
  sombraCopa(G, 5)
  volcar(img, G)
end

local function otonal(img)
  local G = rejilla()
  tronco(G, CORTEZA, 30, 62, 24, 4.5, 6.5, 11)
  local r = L.azar(9)
  ramas(G, 24, 40, -math.pi / 2 - 0.65, 10, 3, 3, r, CORTEZA, 0.7)
  ramas(G, 24, 38, -math.pi / 2 + 0.6, 10, 3, 3, r, CORTEZA, 0.7)
  ramas(G, 24, 34, -math.pi / 2, 10, 3, 2, r, CORTEZA, 0.65)
  sombrearMadera(G)
  local m = {}
  for j, v in ipairs(MAYORES) do
    if j ~= 4 and j ~= 9 then
      m[#m + 1] = { v[1], v[2], v[3] * 0.82, v[4], ra = (j % 3 == 0) and ROJIZO or OCRE }
    end
  end
  copa(G, m, { sem = 33, rampa = OCRE, y0 = 3, y1 = 42, cx = 24, rx = 22, huecos = 0.3, celdaHueco = 4,
               subs = 1.6, vert = 0.45, pct = { 0.14, 0.4, 0.7, 0.92 } })
  sombraCopa(G, 3)
  volcar(img, G)
end

local function seco(img)
  local G = rejilla()
  tronco(G, GRIS, 28, 62, 24, 4, 6.5, 17)
  local r = L.azar(14)
  ramas(G, 23, 40, -math.pi / 2 - 0.7, 11, 3.5, 3, r, GRIS, 0.7)
  ramas(G, 25, 37, -math.pi / 2 + 0.62, 11, 3.5, 3, r, GRIS, 0.7)
  ramas(G, 24, 30, -math.pi / 2 - 0.08, 10, 3, 2, r, GRIS, 0.75)
  segmento(G, 22, 50, 18, 47, 2, GRIS)   -- muñón de rama rota
  sombrearMadera(G)
  volcar(img, G)
end

L.construir("arbol", W, H, { frondoso, otonal, seco }, nil, nil, { base = { 24, 62 } })
