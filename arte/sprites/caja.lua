-- caja (20x20, 2 variantes): caja de tablones clavados en vista 3/4.
-- 0 madera natural con marco y riostra; 1 caja militar verde oliva, gastada, con una tabla de la tapa rota.
local L = dofile(app.params.lib)
local W, H = 20, 20

local function rampa(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local MAD = L.rampa("madera")
local OLI = rampa({ "1c2015", "2b311f", "3e452e", "555d3f", "6f7652" })
local TIN = L.rampa("tinta")
local MET = L.rampa("metal")
local TEL = L.rampa("tela")

local function hash(i, j, s)
  local n = i * 374761393 + j * 668265263 + s * 1442695041
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65535
end

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

-- vetas: trazos de 2-4 px en la dirección de la tabla
local function vetas(img, x0, y0, x1, y1, horizontal, col, semilla, dens)
  local r = L.azar(semilla)
  if horizontal then
    for y = y0, y1 do
      local x = x0 + math.floor(r() * 3)
      while x <= x1 do
        if r() < dens then
          local l = 2 + math.floor(r() * 3)
          for i = 0, l - 1 do if x + i <= x1 then L.px(img, x + i, y, col) end end
          x = x + l + 2 + math.floor(r() * 4)
        else x = x + 3 end
      end
    end
  else
    for x = x0, x1 do
      local y = y0 + math.floor(r() * 2)
      while y <= y1 do
        if r() < dens then
          local l = 2 + math.floor(r() * 2)
          for i = 0, l - 1 do if y + i <= y1 then L.px(img, x, y + i, col) end end
          y = y + l + 2 + math.floor(r() * 3)
        else y = y + 3 end
      end
    end
  end
end

local function dibujar(img, v)
  local C = v == 0 and MAD or OLI
  -------------------------------------------------- tapa (y 1..6): tablas de delante a atrás
  L.rect(img, 1, 1, 18, 6, C[4])
  local tablas = { { 1, 4 }, { 6, 9 }, { 11, 13 }, { 15, 18 } }
  for i, t in ipairs(tablas) do
    vetas(img, t[1] + 1, 1, t[2], 5, false, C[3], 10 + i + v * 5, 0.35)
    L.px(img, t[1], 1, C[5]); L.px(img, t[1], 2, C[5])      -- canto con luz
  end
  for _, gx in ipairs({ 5, 10, 14 }) do L.rect(img, gx, 1, 1, 6, C[2]) end
  -- canto delantero de la tapa, la arista más iluminada
  L.rect(img, 1, 6, 18, 1, C[5])
  for _, gx in ipairs({ 5, 10, 14 }) do L.px(img, gx, 6, C[3]) end
  -- clavos de la tapa
  for _, nx in ipairs({ 3, 8, 12, 17 }) do L.px(img, nx, 5, C[2]) end

  -------------------------------------------------- frente (y 7..18)
  -- panel hundido de tablas horizontales
  L.rect(img, 4, 9, 12, 8, C[3])
  vetas(img, 4, 9, 15, 16, true, C[2], 40 + v, 0.22)
  L.rect(img, 4, 12, 12, 1, C[1])            -- junta entre tablas
  L.rect(img, 4, 13, 12, 1, C[2])
  L.rect(img, 4, 9, 12, 1, C[2])             -- sombra bajo el listón de arriba
  L.rect(img, 4, 9, 1, 8, C[2])              -- sombra del listón izquierdo
  -- marco en relieve
  L.rect(img, 1, 7, 3, 12, C[4]); L.rect(img, 16, 7, 3, 12, C[4])
  L.rect(img, 4, 7, 12, 2, C[4]); L.rect(img, 4, 17, 12, 2, C[4])
  L.rect(img, 1, 7, 1, 11, C[5])                 -- arista izquierda (mira a la luz)
  L.rect(img, 16, 9, 1, 8, C[5])                 -- canto interior del listón derecho (mira a la luz)
  L.rect(img, 4, 17, 12, 1, C[5])                -- canto superior del listón de abajo
  L.rect(img, 3, 9, 1, 8, C[3])                  -- canto interior del listón izquierdo (en sombra)
  L.rect(img, 4, 8, 12, 1, C[3])                 -- canto inferior del listón de arriba
  L.rect(img, 18, 8, 1, 11, C[2])                -- lado en sombra
  L.rect(img, 1, 18, 18, 1, C[2])                -- base en sombra
  vetas(img, 2, 8, 2, 16, false, C[3], 60 + v, 0.4)
  vetas(img, 17, 10, 17, 17, false, C[3], 61 + v, 0.4)
  vetas(img, 5, 7, 15, 7, true, C[3], 62 + v, 0.4)

  if v == 0 then
    -- riostra diagonal de abajo-izquierda a arriba-derecha
    for x = 4, 15 do
      local yc = math.floor(16 - (x - 4) * 7 / 11 + 0.5)
      L.px(img, x, yc - 1, C[5]); L.px(img, x, yc, C[4])
      if yc + 1 <= 16 and yc + 1 ~= 12 then L.px(img, x, yc + 1, C[2]) end
    end
    vetas(img, 6, 11, 13, 13, true, C[3], 70, 0.0)
    -- clavos
    for _, p in ipairs({ { 2, 8 }, { 17, 8 }, { 2, 17 }, { 17, 17 }, { 2, 12 }, { 17, 12 }, { 5, 15 }, { 14, 9 } }) do
      L.px(img, p[1], p[2], C[1])
    end
    -- astillas claras en las esquinas golpeadas
    L.px(img, 18, 7, C[5]); L.px(img, 18, 6, C[4]); L.px(img, 1, 17, C[4]); L.px(img, 1, 18, C[3])
    -- manchas de humedad en la parte baja
    L.px(img, 6, 16, C[2]); L.px(img, 7, 16, C[2]); L.px(img, 11, 16, C[2])
  else
    -- pintura gastada: la madera asoma en las aristas
    for _, p in ipairs({ { 2, 6 }, { 3, 6 }, { 8, 6 }, { 15, 6 }, { 16, 6 }, { 1, 8 }, { 1, 9 }, { 18, 1 }, { 17, 1 } }) do
      L.px(img, p[1], p[2], MAD[4])
    end
    L.px(img, 4, 17, MAD[3]); L.px(img, 5, 17, MAD[3]); L.px(img, 12, 7, MAD[4]); L.px(img, 13, 7, MAD[4])
    -- estarcido de marca (desvaído, con huecos)
    local glifos = {
      "###.#.#.###",
      "#.#.#.#...#",
      "###..#...#.",
      "#.#.#.#..#.",
    }
    for j, f in ipairs(glifos) do
      for i = 1, #f do
        if f:sub(i, i) == "#" and hash(i, j, 5) > 0.12 then L.px(img, 4 + i, 8 + j, TEL[2]) end
      end
    end
    -- franja amarilla de código en la tapa: no; asas de cuerda en los lados
    L.px(img, 1, 11, TEL[1]); L.px(img, 1, 12, TEL[2]); L.px(img, 18, 11, TEL[1]); L.px(img, 18, 12, TEL[1])
    -- cierre metálico en el centro del canto
    L.rect(img, 9, 7, 2, 2, MET[3]); L.px(img, 9, 7, MET[4]); L.px(img, 10, 8, MET[2])
    -- clavos
    for _, p in ipairs({ { 2, 8 }, { 17, 8 }, { 2, 17 }, { 17, 17 } }) do L.px(img, p[1], p[2], C[1]) end
    -- tabla rota en la tapa: hueco oscuro y astillas de madera clara
    L.rect(img, 11, 1, 3, 4, TIN[2])
    L.rect(img, 11, 1, 3, 1, TIN[3])
    L.px(img, 11, 4, MAD[4]); L.px(img, 12, 4, MAD[5]); L.px(img, 12, 3, MAD[5]); L.px(img, 13, 4, MAD[4]); L.px(img, 13, 3, MAD[4])
    L.px(img, 11, 3, TIN[1])
    L.px(img, 14, 2, C[5]); L.px(img, 14, 3, C[5])
    -- grieta en la tabla del panel
    L.px(img, 11, 14, C[1]); L.px(img, 12, 15, C[1]); L.px(img, 13, 15, C[1]); L.px(img, 12, 14, C[4])
  end
  -- esquinas gastadas
  L.borrar(img, 1, 1); L.borrar(img, 18, 1)
  contornoSel(img, C[2], TIN[2])
end

L.construir("caja", W, H, {
  function(img) dibujar(img, 0) end,
  function(img) dibujar(img, 1) end,
}, nil, nil, { base = { 10, 19 } })
