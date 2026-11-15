-- Cono de obra (10x14): plástico naranja sucio, dos bandas reflectantes, base cuadrada de goma.
-- Vista 3/4: se ve la cara de arriba de la base. Luz arriba a la izquierda.
local L = dofile(app.params.lib)
local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local NA = R({ "3e1c10", "6a2e16", "94431f", "b65e2a", "cf7c40" })   -- naranja apagado
local BA = R({ "5a5850", "7f7d74", "a3a195", "c2bfb2", "d6d3c6" })   -- banda reflectante sucia
local GO = R({ "141418", "202026", "2e2f36", "41434b" })             -- goma de la base
local MAT = {}
for _, r in ipairs({ NA, BA, GO }) do for i, c in ipairs(r) do MAT[c] = { r, i } end end

-- Contorno selectivo: material propio; algo más claro arriba/izquierda.
local function contorno(img)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) and img:getPixel(x, y) or false end end
  local function g(x, y) if x < 0 or y < 0 or x >= w or y >= h then return false end return s[y * w + x] end
  for y = 0, h - 1 do for x = 0, w - 1 do if not s[y * w + x] then
    local c, claro = g(x - 1, y) or g(x, y - 1), false
    if not c then c = g(x + 1, y) or g(x, y + 1); claro = true end
    if c then
      local m = MAT[c]
      local r = m and m[1] or GO
      img:drawPixel(x, y, claro and r[2] or r[1])
    end
  end end end
end

L.construir("cono", 10, 14, {
  function(img)
    -- base: cara superior (filas 9-11) y canto frontal (fila 12)
    for y = 9, 12 do for x = 1, 8 do
      local skip = (y == 9 and (x == 1 or x == 8))
      if not skip then
        local c
        if y == 12 then c = (x <= 2) and GO[2] or GO[1]
        else c = (x <= 4) and GO[4] or GO[3] end
        if y == 11 and x >= 6 then c = GO[3] end
        if y < 12 and x == 8 then c = GO[2] end
        L.px(img, x, y, c)
      end
    end end
    -- cuerpo cónico
    for y = 1, 10 do
      local hw = 0.7 + (y - 1) * 0.3
      for x = 0, 9 do
        local u = (x + 0.5 - 5) / hw
        if math.abs(u) <= 1.0 then
          local t
          if u < -0.62 then t = 4 elseif u < -0.12 then t = 5 elseif u < 0.38 then t = 3 elseif u < 0.78 then t = 2 else t = 1 end
          if y <= 2 and t == 5 then t = 4 end
          local banda = (y == 4 or y == 5 or y == 8)
          local r = banda and BA or NA
          if banda and t == 1 then r = NA end
          -- suciedad en la parte baja
          if y >= 9 and not banda and t >= 3 then t = t - 1 end
          L.px(img, x, y, r[t])
        end
      end
    end
    -- borde inferior del cono sobre la base (sombra de contacto)
    L.px(img, 6, 11, GO[2]); L.px(img, 7, 11, GO[2])
    -- rozaduras en las bandas y una mancha de barro
    L.px(img, 6, 4, BA[2]); L.px(img, 6, 5, BA[2])
    L.px(img, 3, 8, BA[3])
    L.px(img, 3, 10, NA[2]); L.px(img, 4, 10, NA[2])
    contorno(img)
  end,
}, nil, nil, { base = { 5, 13 } })
