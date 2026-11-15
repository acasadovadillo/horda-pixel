-- Barrera de hormigón tipo New Jersey (40x18) en vista 3/4: canto de arriba, cara alta casi vertical,
-- quiebro, faldón inclinado (recibe más luz) y zócalo. Desconchones con árido y ferralla oxidada,
-- churretes de óxido, suciedad abajo, ranuras de elevación. Luz arriba a la izquierda.
local L = dofile(app.params.lib)
local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local HO = R({ "3a3a3b", "4e4e4f", "656563", "7c7b78", "93918c", "aba9a2" })  -- hormigón
local AR = R({ "565350", "6f6b65" })                                          -- árido del desconchón
local OX = R({ "4a2a1a", "6e3f24", "8a5634" })                                 -- óxido
local SU = R({ "3f3e38", "55534b" })                                           -- mugre
local MAT = {}
for i, c in ipairs(HO) do MAT[c] = HO end

local function contorno(img)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) and img:getPixel(x, y) or false end end
  local function g(x, y) if x < 0 or y < 0 or x >= w or y >= h then return false end return s[y * w + x] end
  for y = 0, h - 1 do for x = 0, w - 1 do if not s[y * w + x] then
    local c, claro = g(x - 1, y) or g(x, y - 1), false
    if not c then c = g(x + 1, y) or g(x, y + 1); claro = true end
    if c then img:drawPixel(x, y, claro and HO[2] or HO[1]) end
  end end end
end

L.construir("barrera", 40, 18, {
  function(img)
    local az = L.azar(11)
    -- tono por fila (perfil)
    local fila = {}
    fila[1] = 6; fila[2] = 6                       -- canto superior
    for y = 3, 10 do fila[y] = 4 end               -- cara alta
    fila[3] = 5                                    -- arista redondeada del canto
    fila[10] = 3                                   -- quiebro (sombra)
    fila[11] = 5; fila[12] = 5; fila[13] = 4; fila[14] = 4   -- faldón inclinado
    fila[15] = 3; fila[16] = 2                     -- zócalo
    for y = 1, 16 do for x = 1, 38 do
      local t = fila[y]
      if x == 1 and y >= 3 and y <= 14 then t = t + 1 end          -- arista izquierda iluminada
      if x == 38 and y >= 3 then t = t - 1 end                       -- arista derecha en sombra
      L.px(img, x, y, HO[math.max(1, math.min(6, t))])
    end end
    -- moteado del hormigón en manchas de 2 px, poco contraste
    for i = 1, 12 do
      local x, y = 3 + math.floor(az() * 32), 4 + math.floor(az() * 6)
      local c = img:getPixel(x, y)
      for j, h in ipairs(HO) do
        if h == c and j > 2 then
          local d = ({ [3] = L.hex("5e5e5c"), [4] = L.hex("73726e"), [5] = L.hex("888682"), [6] = L.hex("a09e97") })[j]
          L.px(img, x, y, d); if az() < 0.5 then L.px(img, x + 1, y, d) else L.px(img, x, y + 1, d) end
        end
      end
    end
    -- mugre abajo, salpicada de la calzada
    for x = 2, 37 do
      local a = az()
      if a < 0.5 then L.px(img, x, 14, SU[2]); L.px(img, x + 1, 14, SU[2]) end
      if a < 0.18 then L.px(img, x, 13, SU[2]) end
      if az() < 0.4 then L.px(img, x, 15, SU[1]) end
    end
    -- ranuras de elevación en el zócalo
    for _, x0 in ipairs({ 7, 28 }) do
      L.rect(img, x0, 15, 5, 2, L.hex("2a2a2b"))
      L.rect(img, x0, 16, 5, 1, HO[1])
      L.px(img, x0 - 1, 15, HO[4]); L.px(img, x0 - 1, 16, HO[3])
    end
    -- desconchón grande en la esquina superior derecha con árido y ferralla
    for _, p in ipairs({ { 38, 1 }, { 37, 1 }, { 36, 1 }, { 38, 2 }, { 37, 2 }, { 38, 3 } }) do L.borrar(img, p[1], p[2]) end
    for _, p in ipairs({ { 35, 2 }, { 36, 2 }, { 36, 3 }, { 37, 3 }, { 37, 4 }, { 38, 4 }, { 38, 5 }, { 35, 1 } }) do
      L.px(img, p[1], p[2], AR[1])
    end
    L.px(img, 36, 3, AR[2]); L.px(img, 34, 2, AR[2])
    L.px(img, 37, 5, HO[2]); L.px(img, 36, 4, HO[2])
    L.px(img, 37, 2, OX[3]); L.px(img, 38, 2, OX[2])   -- varilla que asoma
    -- desconchón en el canto (muesca)
    L.borrar(img, 15, 1); L.borrar(img, 16, 1); L.borrar(img, 17, 1)
    L.px(img, 15, 2, AR[1]); L.px(img, 16, 2, AR[1]); L.px(img, 17, 2, AR[2]); L.px(img, 16, 3, HO[2])
    -- golpe en la esquina inferior izquierda
    L.borrar(img, 1, 16); L.borrar(img, 1, 15); L.borrar(img, 2, 16)
    L.px(img, 2, 15, AR[1]); L.px(img, 1, 14, AR[1]); L.px(img, 3, 16, AR[1])
    -- churretes de óxido bajo los anclajes
    for _, x0 in ipairs({ 9, 30 }) do
      L.px(img, x0, 2, HO[3]); L.px(img, x0 + 1, 2, HO[3])
      L.px(img, x0, 3, OX[1]); L.px(img, x0 + 1, 3, OX[2])
      local largo = (x0 == 9) and 9 or 7
      for y = 4, largo do L.px(img, x0, y, (y < 6) and OX[2] or L.hex("6a5848")) end
      L.px(img, x0 + 1, 4, L.hex("6a5848"))
    end
    -- fisura fina en la cara alta (oscura, con labio claro a la izquierda)
    local fis = { { 22, 3 }, { 22, 4 }, { 23, 5 }, { 23, 6 }, { 24, 7 }, { 25, 8 } }
    for _, p in ipairs(fis) do L.px(img, p[1], p[2], HO[2]) end
    L.px(img, 21, 4, HO[5]); L.px(img, 22, 6, HO[5]); L.px(img, 23, 8, HO[5])
    contorno(img)
  end,
}, nil, nil, { base = { 20, 17 } })
