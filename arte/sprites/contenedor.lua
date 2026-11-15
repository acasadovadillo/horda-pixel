-- Contenedor de basura metálico (34x30) en vista 3/4: tapa de dos hojas, cara frontal con nervios,
-- refuerzo horizontal, óxido y churretes, ruedas, y una bolsa negra de basura al lado.
-- Luz arriba a la izquierda.
local L = dofile(app.params.lib)
local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local VE = R({ "151c18", "212c25", "2e3d33", "3f5243", "556a57", "71846f" })  -- chapa verde
local TA = R({ "171d1a", "232b27", "303a34", "414d45", "57645a" })            -- tapa (plástico)
local OX = L.rampa("oxido")
local BO = R({ "0f1013", "1a1b20", "282a31", "3b3e47", "5a5e69" })            -- bolsa negra
local GO = R({ "121215", "222228", "34343b" })                                 -- ruedas
local MAT = {}
for _, r in ipairs({ VE, TA, BO, GO, OX }) do for i, c in ipairs(r) do MAT[c] = r end end

local function contorno(img)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) and img:getPixel(x, y) or false end end
  local function g(x, y) if x < 0 or y < 0 or x >= w or y >= h then return false end return s[y * w + x] end
  for y = 0, h - 1 do for x = 0, w - 1 do if not s[y * w + x] then
    local c, claro = g(x - 1, y) or g(x, y - 1), false
    if not c then c = g(x + 1, y) or g(x, y + 1); claro = true end
    if c then local r = MAT[c] or VE; img:drawPixel(x, y, claro and r[2] or r[1]) end
  end end end
end

local function cl(v) return math.max(1, math.min(6, v)) end

L.construir("contenedor", 34, 30, {
  function(img)
    local az = L.azar(5)
    -- cuerpo: cara frontal ligeramente troncocónica (más ancha arriba), y = 12..25
    for y = 12, 25 do
      local m = math.floor((y - 12) / 7)           -- 0..1 de estrechamiento
      local x0, x1 = 2 + m, 25 - m
      for x = x0, x1 do
        local t = 4
        if x <= x0 + 1 then t = 5 end
        if x >= x1 - 1 then t = 3 end
        -- nervios verticales: cara clara + sombra
        local k = (x - 3) % 5
        if x > x0 + 1 and x < x1 - 1 then
          if k == 0 then t = t + 1 elseif k == 1 then t = t - 1 end
        end
        if y >= 23 then t = t - 1 end                -- sombra baja
        L.px(img, x, y, VE[cl(t)])
      end
    end
    -- refuerzo horizontal (fila 15 luz, 16 sombra)
    for x = 2, 25 do L.px(img, x, 15, VE[cl(x <= 4 and 6 or 5)]); L.px(img, x, 16, VE[2]) end
    -- marco inferior
    for x = 4, 23 do L.px(img, x, 25, VE[2]) end
    -- tapa: cara superior (y = 3..10), dos hojas; labio frontal (11)
    for y = 3, 11 do for x = 1, 26 do
      local t
      if y == 11 then t = 2
      elseif y == 3 then t = 3                      -- bisagra/arista trasera
      else
        t = 4
        if y == 10 then t = 5 end                   -- canto delantero redondeado
        if x == 1 then t = 5 end
        if x >= 24 and y < 10 then t = 3 end
      end
      if x == 13 or x == 14 then                    -- junta entre hojas
        if y > 3 and y < 11 then t = (x == 13) and 2 or 5 end
      end
      L.px(img, x, y, TA[math.max(1, math.min(5, t))])
    end end
    -- mugre y hojas secas sobre la tapa
    for _, p in ipairs({ { 4, 8, TA[3] }, { 5, 8, TA[3] }, { 5, 9, TA[3] }, { 9, 5, TA[3] }, { 10, 5, TA[3] },
      { 22, 9, OX[2] }, { 23, 9, OX[1] }, { 16, 8, TA[3] }, { 17, 8, TA[3] } }) do L.px(img, p[1], p[2], p[3]) end
    -- abolladura en la hoja derecha y asas en el labio
    L.px(img, 18, 6, TA[3]); L.px(img, 19, 6, TA[3]); L.px(img, 18, 7, TA[5]); L.px(img, 19, 7, TA[4])
    for _, x0 in ipairs({ 6, 19 }) do L.px(img, x0, 11, TA[4]); L.px(img, x0 + 1, 11, TA[4]); L.px(img, x0, 12, TA[1]); L.px(img, x0 + 1, 12, TA[1]) end
    -- sombra bajo el labio de la tapa
    for x = 2, 25 do if L.get(img, x, 12) ~= TA[1] then L.px(img, x, 12, VE[2]) end end
    -- óxido: manchas en la parte baja y esquina, churretes desde la junta
    local manchas = { { 3, 21, 2, 2 }, { 4, 22, 4, 2 }, { 5, 24, 2, 1 }, { 16, 22, 3, 2 }, { 17, 21, 2, 1 }, { 21, 18, 2, 3 }, { 22, 20, 1, 2 }, { 9, 24, 3, 1 } }
    for _, m in ipairs(manchas) do
      for y = m[2], m[2] + m[4] - 1 do for x = m[1], m[1] + m[3] - 1 do
        if L.opaco(img, x, y) then L.px(img, x, y, (x == m[1] and y == m[2]) and OX[3] or OX[2]) end
      end end
    end
    L.px(img, 17, 22, OX[4]); L.px(img, 4, 21, OX[4])
    for y = 13, 19 do if y ~= 15 and y ~= 16 then L.px(img, 13, y, (y < 15) and OX[2] or OX[1]) end end
    L.px(img, 14, 13, OX[2]); L.px(img, 14, 14, OX[1])
    for y = 17, 20 do L.px(img, 8, y, (y < 19) and OX[2] or OX[1]) end
    -- ruedas
    for _, x0 in ipairs({ 4, 20 }) do
      L.rect(img, x0, 26, 3, 1, VE[2])
      L.rect(img, x0, 27, 3, 2, GO[2]); L.px(img, x0, 27, GO[3]); L.px(img, x0 + 2, 28, GO[1])
    end
    -- bolsa de basura negra (delante, a la derecha)
    local bcx, bcy = 27.5, 24.2
    for y = 16, 29 do for x = 20, 33 do
      local dx, dy = (x + 0.5 - bcx) / 5.6, (y + 0.5 - bcy) / 4.6
      local e = dx * dx + dy * dy
      if dy < 0 then e = dx * dx * 1.2 + dy * dy end
      if e <= 1 and y <= 28 then
        local luz = -0.6 * dx - 0.8 * dy
        local t = (luz > 0.5) and 4 or (luz > -0.05) and 3 or (luz > -0.5) and 2 or 1
        L.px(img, x, y, BO[t])
      end
    end end
    -- nudo arriba
    L.rect(img, 26, 18, 3, 2, BO[3]); L.px(img, 26, 18, BO[4]); L.px(img, 28, 19, BO[2])
    L.px(img, 25, 17, BO[3]); L.px(img, 29, 17, BO[2]); L.px(img, 24, 17, BO[4])
    -- pliegues y brillos del plástico
    for _, p in ipairs({ { 24, 21, 4 }, { 25, 21, 5 }, { 23, 22, 4 }, { 26, 23, 1 }, { 27, 24, 1 }, { 30, 22, 2 }, { 31, 23, 2 },
      { 29, 26, 1 }, { 30, 26, 1 }, { 23, 25, 2 }, { 24, 24, 4 } }) do L.px(img, p[1], p[2], BO[p[3]]) end
    -- sombra de la bolsa sobre la chapa
    L.px(img, 21, 21, VE[2]); L.px(img, 20, 22, VE[2]); L.px(img, 21, 22, VE[2])
    contorno(img)
  end,
}, nil, nil, { base = { 17, 29 } })
