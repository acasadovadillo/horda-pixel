-- barril (16x22, 2 variantes): bidón metálico de 200 l en vista 3/4.
-- 0 azul grisáceo muy oxidado, 1 rojo con franja de peligro.
local L = dofile(app.params.lib)
local W, H = 16, 22
local CX, RX, RY, TY, BY = 8, 5.8, 2.8, 3.8, 17.7
local RIB = { 7, 13 }           -- filas "planas" (vv) donde empiezan los nervios

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

-- tono 1..5 de un cilindro vertical según la columna (luz arriba-izquierda)
local function tonoCol(nx)
  local nz = math.sqrt(math.max(0, 1 - nx * nx))
  local b = -0.6 * nx + 0.8 * nz
  if b > 0.95 then return 5 elseif b > 0.78 then return 4 elseif b > 0.45 then return 3
  elseif b > -0.1 then return 2 else return 1 end
end

local function rampa(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local AZUL = rampa({ "1b2228", "2a3640", "3d4f5b", "566e7c", "7a909a" })
local ROJO = rampa({ "2c1110", "4b1b17", "6e281f", "8f3d30", "ad5f4a" })
local OX = L.rampa("oxido")
local OXT = { OX[1], OX[1], OX[2], OX[2], OX[3] }       -- óxido según tono
local SEN = L.rampa("senal")
local SENT = { SEN[1], SEN[1], SEN[2], SEN[3], SEN[4] }
local TIN = L.rampa("tinta")
local MET = L.rampa("metal")
local METT = { MET[2], MET[3], MET[4], MET[5], MET[6] }  -- metal desnudo (desconchones)

-- Contorno selectivo: claro arriba/izquierda, oscuro abajo/derecha.
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

-- máscara limpia: quita píxeles sin vecinos (no hay píxeles sueltos)
local function limpiar(m)
  local out = {}
  for k, v in pairs(m) do
    if v then
      local x, y = k % 100, k // 100
      local n = 0
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        if m[(y + d[2]) * 100 + x + d[1]] then n = n + 1 end
      end
      if n >= 1 then out[k] = true end
    end
  end
  return out
end

local function dibujar(img, variante)
  local C = variante == 0 and AZUL or ROJO
  local semilla = variante == 0 and 11 or 29
  local umbral = variante == 0 and 0.72 or 1.05

  -- 1) clasificar cada píxel
  local celdas = {}
  for y = 0, H - 1 do for x = 0, W - 1 do
    local px, py = x + 0.5, y + 0.5
    local nx = (px - CX) / RX
    if math.abs(nx) <= 1 then
      local s = math.sqrt(1 - nx * nx)
      local dl = ((px - CX) / RX) ^ 2 + ((py - TY) / RY) ^ 2
      if dl <= 1 then
        celdas[y * 100 + x] = { tipo = "tapa", nx = nx, dl = dl, py = py }
      elseif py > TY and py <= BY + RY * s then
        local vv = math.floor(py - RY * s)
        celdas[y * 100 + x] = { tipo = "cuerpo", nx = nx, vv = vv, s = s }
      end
    end
  end end

  -- 2) máscara de óxido (manchas en grupo, más abajo y en los nervios)
  local ox = {}
  for k, c in pairs(celdas) do
    local x, y = k % 100, k // 100
    local n = ruidoV(x, y, 3, 2.2, semilla) * 0.75 + ruidoV(x, y, 1.6, 1.3, semilla + 7) * 0.25
    local extra = 0
    if c.tipo == "cuerpo" then
      if c.vv >= 15 then extra = 0.3 elseif c.vv >= 13 then extra = 0.12 end
      if c.vv == RIB[1] + 1 or c.vv == RIB[2] + 1 then extra = extra + 0.12 end
    else
      if c.dl > 0.45 and variante == 0 then extra = 0.08 end
    end
    if n + extra > umbral then ox[k] = true end
  end
  -- chorretones de óxido bajo los nervios (2-4 px)
  local r = L.azar(semilla * 3)
  for _, rib in ipairs(RIB) do
    for x = 3, 12 do
      if r() < (variante == 0 and 0.3 or 0.12) then
        local largo = 2 + math.floor(r() * 3)
        for y = 0, H - 1 do
          local c = celdas[y * 100 + x]
          if c and c.tipo == "cuerpo" and c.vv > rib + 1 and c.vv <= rib + 1 + largo then ox[y * 100 + x] = true end
        end
      end
    end
  end
  ox = limpiar(ox)

  -- desconchones de pintura (metal desnudo) en el rojo
  local chip = {}
  if variante == 1 then
    for k, c in pairs(celdas) do
      local x, y = k % 100, k // 100
      if ruidoV(x, y, 2, 1.5, 77) > 0.9 and not ox[k] and not (c.tipo == "cuerpo" and c.vv >= RIB[1] + 2 and c.vv <= RIB[2] - 1) then chip[k] = true end
    end
    chip = limpiar(chip)
  end

  -- 3) pintar
  for k, c in pairs(celdas) do
    local x, y = k % 100, k // 100
    local t = tonoCol(c.nx)
    local col
    if c.tipo == "cuerpo" then
      local vv = c.vv
      local pr = vv == math.floor(TY + 0.5) + 0 and true or false
      -- sombra bajo el reborde de la tapa
      local yl = TY + RY * c.s
      if y + 0.5 - yl < 1.0 then t = t - 1 end
      -- nervios: cara de arriba con luz, cara de abajo en sombra
      for _, rib in ipairs(RIB) do
        if vv == rib then t = t + 1 elseif vv == rib + 1 then t = t - 1 end
      end
      -- aro inferior y oclusión con el suelo
      local fondo = math.floor(BY)
      if vv == fondo - 1 then t = t + 1 elseif vv >= fondo then t = t - 1 end
      t = clamp(t, 1, 5)
      col = C[t]
      -- franja de peligro entre los nervios (rojo)
      if variante == 1 and vv >= RIB[1] + 2 and vv <= RIB[2] - 1 then
        if (x + vv) % 6 < 3 then col = SENT[t] else col = TIN[2 + (t >= 4 and 1 or 0)] end
      end
      if chip[k] then col = METT[t] end
      if ox[k] then col = OXT[t] end
    else
      -- tapa: aro exterior con luz, interior hundido
      local dli = ((x + 0.5 - CX) / (RX - 1.3)) ^ 2 + ((y + 0.5 - TY) / (RY - 1.0)) ^ 2
      local atras = (y + 0.5) < TY
      if dli > 1 then
        -- aro (borde superior del bidón)
        if atras then t = (c.nx < 0.2) and 5 or 4 else t = (c.nx < -0.2) and 4 or 3 end
      else
        t = 3
        -- sombra del aro dentro, en el lado de atrás-izquierda
        if atras and c.nx < 0.35 then t = 2 end
        if not atras and c.nx > 0.3 then t = 4 end
      end
      col = C[t]
      if ox[k] and dli <= 1 then col = OXT[t] end
    end
    L.px(img, x, y, col)
  end
  -- tapones de la tapa (uno grande, uno pequeño)
  L.px(img, CX + 2, 3, C[1]); L.px(img, CX + 3, 3, C[2]); L.px(img, CX + 2, 2, C[4]); L.px(img, CX + 3, 2, C[4])
  L.px(img, CX - 3, 4, C[2]); L.px(img, CX - 2, 4, C[2])

  if variante == 1 then
    -- un golpe (abolladura) en la parte baja derecha
    L.px(img, 10, 16, C[1]); L.px(img, 11, 16, C[2]); L.px(img, 10, 17, C[3]); L.px(img, 11, 17, C[3])
  end

  contornoSel(img, C[2], TIN[2])
end

L.construir("barril", W, H, {
  function(img) dibujar(img, 0) end,
  function(img) dibujar(img, 1) end,
}, nil, nil, { base = { 8, 21 } })
