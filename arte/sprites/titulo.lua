-- titulo (150x56): logotipo «HORDA PIXEL».
local L = dofile(app.params.lib)
local W, H = 150, 56

-- Rampas: sangre (oscuro -> claro) y hueso gastado
local R = { L.hex("2a080c"), L.hex("4e0d13"), L.hex("74141b"), L.hex("982025"), L.hex("b8372f"), L.hex("d0614a") }
local B = { L.hex("3a3226"), L.hex("62563f"), L.hex("8e7f5c"), L.hex("b7a77e"), L.hex("d6c9a0") }
local TINTA = L.col("tinta", 1)

-- Glifos de HORDA en rejilla 12x13 (cada celda = 2x2 px)
local G = {
  H = { "###......###","###......###","###......###","###......###","###......###",
        "############","############","###......###","###......###","###......###",
        "###......###","###......###","###......###" },
  O = { ".##########.","############","###......###","###......###","###......###",
        "###......###","###......###","###......###","###......###","###......###",
        "###......###","############",".##########." },
  R = { "##########..","###########.","###......###","###......###","###......###",
        "###.....####","###########.","##########..","###...####..","###....####.",
        "###.....####","###......###","###......###" },
  D = { "##########..","###########.","###.....####","###......###","###......###",
        "###......###","###......###","###......###","###......###","###......###",
        "###.....####","###########.","##########.." },
  A = { "..########..",".##########.","####....####","###......###","###......###",
        "###......###","############","############","###......###","###......###",
        "###......###","###......###","###......###" },
}
-- PIXEL en rejilla 6x7 (celda 2x2 px)
local P = {
  P = { "#####.","##..##","##..##","#####.","##....","##....","##...." },
  I = { "######","..##..","..##..","..##..","..##..","..##..","######" },
  X = { "##..##","##..##",".####.","..##..",".####.","##..##","##..##" },
  E = { "######","##....","##....","#####.","##....","##....","######" },
  L = { "##....","##....","##....","##....","##....","##....","######" },
}

-- máscaras: 0 vacío, 1 cara, 2 extrusión
local function nueva() local m = {} for y = 0, H - 1 do m[y] = {} end return m end
local cara, ext, mat = nueva(), nueva(), nueva()   -- mat: "r" sangre, "b" hueso
local function en(m, x, y) return y >= 0 and y < H and x >= 0 and x < W and m[y][x] end

local function glifo(g, ox, oy, k, tipo)
  for gy, fila in ipairs(g) do for gx = 1, #fila do
    if fila:sub(gx, gx) == "#" then
      for yy = 0, k - 1 do for xx = 0, k - 1 do
        local x, y = ox + (gx - 1) * k + xx, oy + (gy - 1) * k + yy
        cara[y][x] = true; mat[y][x] = tipo
      end end
    end
  end end
end

-- HORDA: letras de 24x26, ligero desorden vertical
local offs = { 1, 0, 2, 0, 1 }
local x0 = 5
for i, ch in ipairs({ "H", "O", "R", "D", "A" }) do
  glifo(G[ch], x0 + (i - 1) * 28, 2 + offs[i], 2, "r")
end
-- esquinas achaflanadas a 1 px en HORDA (no en celdas: solo esquinas exteriores)
-- muescas de desgaste en los bordes (mordiscos de 1-2 px)
local rnd = L.azar(77)
local muescas = { {9,3},{30,8},{44,2},{61,14},{70,27},{90,6},{100,29},{121,3},{139,18},{6,22},{52,26},{113,12} }
for _, m in ipairs(muescas) do
  local x, y = m[1], m[2]
  for dy = -1, 1 do for dx = -1, 1 do
    if math.abs(dx) + math.abs(dy) <= 1 and en(cara, x + dx, y + dy) then cara[y + dy][x + dx] = nil end
  end end
end

-- goterones: {x, y inicio (borde inferior), ancho, largo}
local gotas = {
  { 9, 28, 3, 8 }, { 24, 28, 2, 5 }, { 39, 27, 3, 4 }, { 59, 29, 2, 4 }, { 73, 29, 3, 3 },
  { 91, 27, 2, 4 }, { 103, 25, 2, 3 }, { 122, 28, 3, 6 }, { 137, 28, 2, 6 }, { 19, 16, 2, 2 },
}
for _, g in ipairs(gotas) do
  local gx, gy, gw, gl = g[1], g[2], g[3], g[4]
  for y = gy, gy + gl do for x = gx, gx + gw - 1 do cara[y][x] = true; mat[y][x] = "r" end end
  -- menisco: el goterón se ensancha donde nace
  for x = gx - 1, gx + gw do cara[gy - 1][x] = cara[gy - 1][x] or (cara[gy - 2][x] and true) ; if cara[gy-1][x] then mat[gy-1][x] = "r" end end
  for x = gx - 1, gx + gw do if cara[gy - 1][x] then cara[gy][x] = true; mat[gy][x] = "r" end end
  -- gota final: bulbo redondo (lados rectos, esquinas cortadas)
  local bw = gw + 2
  local bx, by = gx - 1, gy + gl + 1
  for y = 0, bw - 1 do for x = 0, bw - 1 do
    local esquina = (x == 0 or x == bw - 1) and (y == 0 or y == bw - 1)
    if not esquina then cara[by + y][bx + x] = true; mat[by + y][bx + x] = "r" end
  end end
end

-- PIXEL: letras 12x14 centradas, con barras a los lados
local px0 = math.floor((W - (5 * 12 + 4 * 4)) / 2)
for i, ch in ipairs({ "P", "I", "X", "E", "L" }) do
  glifo(P[ch], px0 + (i - 1) * 16, 38, 2, "b")
end
for x = px0 - 22, px0 - 6 do for y = 44, 45 do cara[y][x] = true; mat[y][x] = "b" end end
for x = px0 + 76 + 4, px0 + 76 + 20 do for y = 44, 45 do cara[y][x] = true; mat[y][x] = "b" end end

-- extrusión hacia abajo a la derecha (bloque)
for y = 0, H - 1 do for x = 0, W - 1 do
  if cara[y][x] then
    local d = mat[y][x] == "r" and 3 or 2
    for k = 1, d do
      local xx, yy = x + (k >= 2 and 1 or 0), y + k
      if mat[y][x] == "b" then xx = x + (k == 2 and 1 or 0) end
      if yy < H and xx < W and not cara[yy][xx] then ext[yy][xx] = true; mat[yy][xx] = mat[yy][xx] or mat[y][x] end
    end
  end
end end

local img0
L.construir("titulo", W, H, {
  function(img)
    local r = L.azar(5)
    -- extrusión
    for y = 0, H - 1 do for x = 0, W - 1 do
      if ext[y][x] and not cara[y][x] then
        local c = mat[y][x] == "r" and R[1] or B[1]
        L.px(img, x, y, c)
      end
    end end
    -- cara con bisel: luz arriba-izquierda, sombra abajo-derecha
    for y = 0, H - 1 do for x = 0, W - 1 do
      if cara[y][x] then
        local rr = mat[y][x] == "r"
        local up, lf = en(cara, x, y - 1), en(cara, x - 1, y)
        local dn, rt = en(cara, x, y + 1), en(cara, x + 1, y)
        local up2 = en(cara, x, y - 2)
        local c
        if rr then
          c = R[4]
          if not up then c = R[6] elseif not lf then c = R[5] elseif not up2 then c = R[5] end
          if not dn or not rt then c = R[3] end
          if not up and not rt then c = R[5] end
        else
          c = B[4]
          if not up or not lf then c = B[5] end
          if not dn or not rt then c = B[3] end
        end
        L.px(img, x, y, c)
      end
    end end
    -- desgaste: manchas oscuras de 2-4 px (sangre coagulada / pintura saltada)
    local function mancha(cx, cy, cs)
      for i = 1, #cs do
        local p = cs[i]
        local x, y = cx + p[1], cy + p[2]
        if en(cara, x, y) and en(cara, x - 1, y) and en(cara, x + 1, y) and en(cara, x, y - 1) and en(cara, x, y + 1) then
          L.px(img, x, y, p[3])
        end
      end
    end
    local formas = {
      { {0,0,R[3]},{1,0,R[3]},{1,1,R[2]},{2,1,R[3]} },
      { {0,0,R[3]},{0,1,R[3]},{1,1,R[3]} },
      { {0,0,R[5]},{1,0,R[5]} },
    }
    for i = 1, 45 do
      local x, y = 6 + math.floor(r() * 138), 4 + math.floor(r() * 26)
      if en(cara, x, y) and mat[y][x] == "r" then mancha(x, y, formas[1 + math.floor(r() * #formas)]) end
    end
    -- rayones finos diagonales en hueso
    for i = 1, 14 do
      local x, y = px0 + math.floor(r() * 76), 39 + math.floor(r() * 12)
      if en(cara, x, y) and en(cara, x + 1, y + 1) and mat[y][x] == "b" then
        L.px(img, x, y, B[3]); L.px(img, x + 1, y + 1, B[3])
      end
    end
    -- brillo húmedo en las gotas
    for _, g in ipairs(gotas) do
      local gx, gy, gw, gl = g[1], g[2], g[3], g[4]
      for y = gy + 1, gy + gl do L.px(img, gx, y, R[5]); if gw > 2 then L.px(img, gx + 1, y, R[4]) end; L.px(img, gx + gw - 1, y, R[3]) end
      local bw, bx, by = gw + 2, gx - 1, gy + gl + 1
      for y = by, by + bw - 1 do for x = bx, bx + bw - 1 do
        if en(cara, x, y) then
          local c = R[4]
          if not en(cara, x, y - 1) or not en(cara, x - 1, y) then c = R[5] end
          if not en(cara, x, y + 1) or not en(cara, x + 1, y) then c = R[2] end
          L.px(img, x, y, c)
        end
      end end
      L.px(img, bx + 1, by + 1, R[6])
    end
    L.contorno(img, TINTA, { diagonal = false })
  end,
})
