-- hoguera (18x32, «arder» 4 fotogramas): bidón oxidado con agujeros por los que se ven las brasas
-- y llamas que salen por arriba.
local L = dofile(app.params.lib)
local W, H = 18, 32
local CX, RX, RY, TY, BY = 9, 6.4, 2.6, 15.2, 28.3

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
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function tonoCol(nx)
  local nz = math.sqrt(math.max(0, 1 - nx * nx))
  local b = -0.6 * nx + 0.8 * nz
  if b > 0.975 then return 5 elseif b > 0.78 then return 4 elseif b > 0.45 then return 3
  elseif b > -0.1 then return 2 else return 1 end
end
local function rampa(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local B = rampa({ "21140f", "37201a", "52301f", "6e4428", "8a5a34" })   -- chapa quemada y oxidada
local OX = L.rampa("oxido")
local F = L.rampa("fuego")
local TIN = L.rampa("tinta")

local function contornoSel(img, claro, oscuro)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) end end
  local function op(x, y) return x >= 0 and y >= 0 and x < w and y < h and s[y * w + x] end
  for y = 0, h - 1 do for x = 0, w - 1 do
    if not s[y * w + x] then
      if op(x - 1, y) or op(x, y - 1) then img:drawPixel(x, y, oscuro)
      elseif op(x + 1, y) or op(x, y + 1) then img:drawPixel(x, y, claro) end
    end
  end end
end

-- lengua de fuego: devuelve true si (px,py) está dentro con escala k
local function lengua(px, py, t, k)
  local base = t.y
  local alto = t.h * k
  local u = (base - py) / alto
  if u < -0.15 or u > 1 then return false end
  local uu = math.max(u, 0)
  local xc = t.x + t.lean * uu * uu + math.sin(uu * 3.4 + t.ph) * 0.9 * uu
  local hw = t.w * k * (1 - uu) ^ 0.75 * (1 + 0.18 * math.sin(uu * 7 + t.ph * 2))
  return math.abs(px - xc) <= hw
end

local function fotograma(img, f)
  local fase = (f - 1) / 4 * 2 * math.pi
  -- llamas: tres lenguas que cambian de altura y ondulan
  local ls = {
    { x = 9.2, y = 15.5, w = 3.6, h = 13.0 + 1.6 * math.sin(fase), lean = 0.6, ph = fase },
    { x = 6.4, y = 15.5, w = 2.4, h = 8.0 + 1.8 * math.sin(fase + 2.1), lean = -1.0, ph = fase + 1.3 },
    { x = 12.0, y = 15.5, w = 2.5, h = 9.0 + 1.8 * math.sin(fase + 4.0), lean = 1.2, ph = fase + 2.6 },
  }
  local capas = { { k = 1.0, c = F[2] }, { k = 0.72, c = F[3] }, { k = 0.45, c = F[4] }, { k = 0.24, c = F[5] } }

  -- 1) boca del bidón por dentro: pared trasera iluminada por el fuego y brasas
  for y = 0, H - 1 do for x = 0, W - 1 do
    local px, py = x + 0.5, y + 0.5
    local dl = ((px - CX) / RX) ^ 2 + ((py - TY) / RY) ^ 2
    local di = ((px - CX) / (RX - 1.1)) ^ 2 + ((py - TY) / (RY - 0.8)) ^ 2
    if di <= 1 then
      if py < TY - 0.4 then L.px(img, x, y, F[1]) else
        local n = ruidoV(x, y + f * 3, 2, 1.2, 33 + f)
        L.px(img, x, y, n > 0.62 and F[4] or (n > 0.35 and F[3] or F[2]))
      end
    end
  end end
  -- 2) llamas
  for y = 0, 17 do for x = 0, W - 1 do
    local px, py = x + 0.5, y + 0.5
    local col
    for _, cp in ipairs(capas) do
      for _, t in ipairs(ls) do if lengua(px, py, t, cp.k) then col = cp.c end end
    end
    if col then L.px(img, x, y, col) end
  end end
  -- lengua suelta que sube (se separa de la llama)
  local sy = ({ 4, 2, 6, 3 })[f]
  local sx = ({ 8, 10, 11, 7 })[f]
  if f ~= 3 then
    L.px(img, sx, sy, F[2]); L.px(img, sx, sy + 1, F[3]); L.px(img, sx + 1, sy + 1, F[2])
  end
  -- chispa
  local cx2, cy2 = ({ 13, 5, 12, 6 })[f], ({ 3, 5, 1, 2 })[f]
  L.px(img, cx2, cy2, F[4]); L.px(img, cx2, cy2 + 1, F[3])

  -- 3) bidón: aro superior y cuerpo
  for y = 0, H - 1 do for x = 0, W - 1 do
    local px, py = x + 0.5, y + 0.5
    local nx = (px - CX) / RX
    if math.abs(nx) <= 1 then
      local s = math.sqrt(1 - nx * nx)
      local dl = ((px - CX) / RX) ^ 2 + ((py - TY) / RY) ^ 2
      local di = ((px - CX) / (RX - 1.1)) ^ 2 + ((py - TY) / (RY - 0.8)) ^ 2
      local t = tonoCol(nx)
      if dl <= 1 and di > 1 then
        -- aro: el de delante se ve por arriba, iluminado por el fuego
        if py >= TY then L.px(img, x, y, (math.abs(nx) < 0.6) and OX[4] or OX[3])
        else L.px(img, x, y, (math.abs(nx) < 0.7) and OX[3] or B[4]) end
      elseif dl > 1 and py > TY and py <= BY + RY * s then
        local vv = math.floor(py - RY * s)
        local yl = TY + RY * s
        if py - yl < 1.2 then t = t - 1 end
        if vv == 20 then t = t + 1 elseif vv == 21 then t = t - 2 end
        if vv >= 27 then t = t - 1 end
        t = clamp(t, 1, 5)
        local col = B[t]
        -- óxido claro en manchas (grupos)
        local n = ruidoV(x, y, 2.6, 2.0, 5)
        if n > 0.66 then col = OX[clamp(t - 1, 1, 4)] end
        -- hollín cerca de la boca
        if vv <= 17 and ruidoV(x, y, 2, 1.5, 9) > 0.5 then col = B[clamp(t - 1, 1, 5)] end
        L.px(img, x, y, col)
      end
    end
  end end
  -- 4) agujeros con brasas (parpadean)
  local hol = { { 4, 26, 1, 2 }, { 7, 26, 2, 2 }, { 10, 26, 2, 2 }, { 13, 26, 1, 2 } }
  for i, h in ipairs(hol) do
    local brillo = (i + f) % 3
    for yy = 0, h[4] - 1 do for xx = 0, h[3] - 1 do
      local c = (yy == 0) and F[2] or (brillo == 0 and F[4] or F[3])
      if h[4] == 1 then c = brillo == 0 and F[3] or F[2] end
      L.px(img, h[1] + xx, h[2] + yy, c)
    end end
    -- borde roto: chapa doblada (oscuro arriba, reflejo cálido abajo)
    for xx = 0, h[3] - 1 do L.px(img, h[1] + xx, h[2] - 1, B[1]) end
    for xx = 0, h[3] - 1 do L.px(img, h[1] + xx, h[2] + h[4], OX[2]) end
  end
  contornoSel(img, B[2], TIN[2])
  -- las llamas no llevan contorno oscuro: se quita el que quedó encima del bidón
  for y = 0, 13 do for x = 0, W - 1 do
    local c = img:getPixel(x, y)
    if c == TIN[2] or c == B[2] then
      local esFuego = false
      for _, d in ipairs({ { 0, 1 }, { 1, 0 }, { -1, 0 }, { 0, -1 } }) do
        local q = L.get(img, x + d[1], y + d[2])
        for i = 1, 5 do if q == F[i] then esFuego = true end end
      end
      if esFuego then
        -- borde exterior de la llama: rojo oscuro, solo abajo/derecha
        if c == TIN[2] then img:drawPixel(x, y, F[1]) else L.borrar(img, x, y) end
      end
    end
  end end
end

local fs = {}
for i = 1, 4 do fs[i] = function(img) fotograma(img, i) end end
L.construir("hoguera", W, H, fs, { { "arder", 1, 4 } }, 0.1, { base = { 9, 31 } })
