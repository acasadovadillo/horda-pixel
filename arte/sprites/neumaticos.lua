-- Pila de dos neumáticos viejos (20x18) en vista 3/4: flanco de arriba, banda de rodadura con
-- tacos y el hueco central. Goma polvorienta. Luz arriba a la izquierda.
local L = dofile(app.params.lib)
local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local GO = R({ "121215", "1c1c21", "29292f", "38383f", "4b4b51", "616067", "7a7672" })  -- goma (el último, polvo)
local PO = R({ "4a4640", "625d55" })                                          -- polvo
local MAT = {}
for i, c in ipairs(GO) do MAT[c] = { GO, i } end
for i, c in ipairs(PO) do MAT[c] = { GO, 4 } end

local function contorno(img)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) and img:getPixel(x, y) or false end end
  local function g(x, y) if x < 0 or y < 0 or x >= w or y >= h then return false end return s[y * w + x] end
  for y = 0, h - 1 do for x = 0, w - 1 do if not s[y * w + x] then
    local c, claro = g(x - 1, y) or g(x, y - 1), false
    if not c then c = g(x + 1, y) or g(x, y + 1); claro = true end
    if c then img:drawPixel(x, y, claro and GO[2] or GO[1]) end
  end end end
end

local function cl(v, a, b) return math.max(a, math.min(b, v)) end

-- Un neumático: centro del flanco superior (cx, cy), radios rx, ry, alto de la banda th.
local function neumatico(img, cx, cy, rx, ry, th, semilla, mask)
  local az = L.azar(semilla)
  local k = 0.5                                  -- radio del hueco / radio exterior
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    local px, py = x + 0.5, y + 0.5
    local dx = (px - cx) / rx
    if math.abs(dx) <= 1 then
      local sq = math.sqrt(1 - dx * dx)
      local dy = (py - cy) / ry
      local e = dx * dx + dy * dy
      local ey = cy + ry * sq                     -- borde frontal del flanco
      local c
      if e <= 1 then
        if e > k * k then
          -- flanco superior: toro visto desde arriba
          local r = math.sqrt(e)
          local s = (r - (1 + k) / 2) / ((1 - k) / 2)  -- -1 interior .. 1 exterior
          local nx, ny = dx / r, dy / r
          local luz = 0.55 + 0.75 * s * (-0.6 * nx - 0.8 * ny) - 0.25 * s * s
          local t = cl(math.floor(3.6 + luz * 3.0), 3, 7)
          c = GO[t]
        else
          -- hueco: pared interior del lado lejano y oscuridad
          local dk = dx / k
          local rim = cy - ry * k * math.sqrt(math.max(0, 1 - dk * dk))
          if math.abs(dk) <= 1 and py - rim < th * 0.75 then
            c = (dk > 0.3) and GO[4] or GO[3]
          else
            c = GO[1]
          end
        end
      elseif py <= ey + th then
        -- banda de rodadura (rueda abombada)
        local t = (py - ey) / th
        local tono = 4
        if t < 0.25 then tono = 5 elseif t > 0.75 then tono = 3 end
        if dx < -0.3 and dx > -0.85 and t < 0.75 then tono = tono + 1 end
        if dx > 0.5 then tono = tono - 1 end
        -- tacos: surcos rectos espaciados en ángulo (se apiñan hacia los bordes)
        local ang = math.asin(cl(dx, -1, 1))
        local f = (ang * 7 / math.pi + 10.5) % 1
        if f < 0.3 and t > 0.25 and t < 0.78 and math.abs(dx) < 0.9 then tono = tono - 2 end
        c = GO[cl(tono, 1, 6)]
        if mask then mask[y * img.width + x] = true end
      end
      if c then L.px(img, x, y, c); if mask then mask[y * img.width + x] = true end end
    end
  end end
end

L.construir("neumaticos", 20, 18, {
  function(img)
    neumatico(img, 10.6, 9.3, 8.1, 4.3, 3.9, 3)      -- el de abajo
    local m = {}
    neumatico(img, 9.4, 5.3, 8.0, 4.3, 4.0, 7, m)    -- el de arriba, algo desplazado
    -- sombra de contacto del de arriba sobre el de abajo
    for y = 1, 17 do for x = 0, 19 do
      if m[(y - 1) * 20 + x] and not m[y * 20 + x] and L.opaco(img, x, y) then
        L.px(img, x, y, GO[1]); if L.opaco(img, x, y + 1) and x > 12 then L.px(img, x, y + 1, GO[2]) end
      end
      if m[y * 20 + x - 1] and not m[y * 20 + x] and x > 0 and L.opaco(img, x, y) and y > 6 then L.px(img, x, y, GO[2]) end
    end end
    -- polvo y barro seco sobre el flanco de arriba
    -- grieta en el flanco
    L.px(img, 11, 1, GO[3]); L.px(img, 12, 1, GO[3])
    contorno(img)
  end,
}, nil, nil, { base = { 10, 17 } })
