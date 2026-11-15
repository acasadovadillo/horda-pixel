-- icono (64x64, opaco): superviviente a contraluz frente a la horda al atardecer.
local L = dofile(app.params.lib)
local W, H = 64, 64
local h = L.hex

local CIELO = { h("1a1220"), h("2b1525"), h("441b27"), h("672322"), h("8f3119"), h("b44c1a"), h("d47426"), h("eba046") }
local SOL = { h("f0b54c"), h("fbd277"), h("ffe9a8") }
local LEJOS = h("4a1c24")      -- edificios lejanos (bruma)
local CIUDAD = h("2a141c")     -- edificios cercanos
local SUELO = { h("140d13"), h("1d1219"), h("2a161c") }
local SOMBRA = h("100b10")     -- siluetas de la horda
local SURV = h("141019")       -- silueta del superviviente
local SURV2 = h("1f1d2a")      -- matices de la ropa
local BORDE = { h("8f3119"), h("d47426"), h("f0b54c") } -- luz de contorno

local SX, SY, SR = 45, 34, 15  -- sol
local HOR = 49                 -- línea del horizonte

local function silueta() local m = {} for y = 0, H - 1 do m[y] = {} end return m end
local function marcar(m, x, y) x = math.floor(x); y = math.floor(y) if x >= 0 and y >= 0 and x < W and y < H then m[y][x] = true end end
local function mgrueso(m, x0, y0, x1, y1, g)
  local r = g / 2
  local dx, dy = x1 - x0, y1 - y0
  local l2 = dx * dx + dy * dy
  for y = math.floor(math.min(y0, y1) - r - 1), math.ceil(math.max(y0, y1) + r + 1) do
    for x = math.floor(math.min(x0, x1) - r - 1), math.ceil(math.max(x0, x1) + r + 1) do
      local cx, cy = x + 0.5, y + 0.5
      local t = l2 > 0 and math.max(0, math.min(1, ((cx - x0) * dx + (cy - y0) * dy) / l2)) or 0
      if (cx - x0 - dx * t) ^ 2 + (cy - y0 - dy * t) ^ 2 <= r * r then marcar(m, x, y) end
    end
  end
end
local function melipse(m, cx, cy, rx, ry)
  for y = math.floor(cy - ry), math.ceil(cy + ry) do for x = math.floor(cx - rx), math.ceil(cx + rx) do
    local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
    if dx * dx + dy * dy <= 1 then marcar(m, x, y) end
  end end
end
local function mpoli(m, pts)
  local tmp = L.imagen(W, H)
  L.poligono(tmp, pts, h("ffffff"))
  for y = 0, H - 1 do for x = 0, W - 1 do if L.opaco(tmp, x, y) then m[y][x] = true end end end
end

-- zombi de perfil caminando a la izquierda; pies en (x, yb), altura hz
local function zombi(m, x, yb, hz, var)
  local u = hz / 16
  local cad = (var % 2 == 0) and 1 or -1
  mgrueso(m, x, yb - 7 * u, x - 2 * u * cad, yb - 0.5, 1.8 * u)          -- pierna
  mgrueso(m, x, yb - 7 * u, x + 2.2 * u * cad, yb - 0.5, 1.8 * u)        -- pierna
  mgrueso(m, x + 0.2 * u, yb - 7.5 * u, x - 1.3 * u, yb - 12 * u, 3.4 * u) -- torso vencido
  melipse(m, x - 2.6 * u, yb - 13.6 * u, 1.45 * u, 1.6 * u)               -- cabeza caída
  mgrueso(m, x - 1.2 * u, yb - 11.6 * u, x - 6.5 * u, yb - 11.2 * u + var % 3 * 0.4 * u, 1.3 * u) -- brazo al frente
  if var % 3 == 0 then
    mgrueso(m, x - 0.6 * u, yb - 11.2 * u, x - 1.4 * u, yb - 6.5 * u, 1.3 * u) -- brazo colgando
  else
    mgrueso(m, x - 0.8 * u, yb - 11 * u, x - 5.6 * u, yb - 9.8 * u, 1.3 * u)
  end
end

L.construir("icono", W, H, {
  function(img)
    local r = L.azar(31)
    -- 1. cielo en bandas con bordes de nube irregulares
    local lim = { 9, 17, 24, 30, 35, 39, 43 }
    for x = 0, W - 1 do
      local ond = math.floor(1.6 * math.sin(x * 0.21) + 1.1 * math.sin(x * 0.53 + 1.3))
      for y = 0, H - 1 do
        local b = 1
        for i, l in ipairs(lim) do if y >= l + ond * ((i % 2 == 0) and 1 or -1) then b = i + 1 end end
        L.px(img, x, y, CIELO[math.min(b, #CIELO)])
      end
    end
    -- jirones de nube oscuros con panza iluminada
    local nubes = { { 4, 12, 16 }, { 32, 8, 20 }, { 50, 18, 14 }, { 0, 26, 14 }, { 22, 21, 12 } }
    for _, n in ipairs(nubes) do
      local nx, ny, nl = n[1], n[2], n[3]
      for i = 0, nl - 1 do
        local x = nx + i
        local base = img:getPixel(math.max(0, math.min(W - 1, x)), ny)
        local k = 1
        for j = 1, #CIELO do if CIELO[j] == base then k = j end end
        local medio = i >= math.floor(nl / 4) and i < nl - math.floor(nl / 4)
        L.px(img, x, ny, CIELO[math.max(1, k - 1)])
        if medio then L.px(img, x, ny - 1, CIELO[math.max(1, k - 1)]) end
        if medio and i > nl / 3 then L.px(img, x, ny + 1, CIELO[math.min(#CIELO, k + 1)]) end
      end
    end
    -- 2. sol grande y bajo
    L.elipse(img, SX, SY, SR + 2, SR + 2, CIELO[7])
    L.elipse(img, SX, SY, SR, SR, SOL[1])
    L.elipse(img, SX - 1, SY - 1, SR - 3, SR - 3, SOL[2])
    L.elipse(img, SX - 2, SY - 3, SR - 7, SR - 7, SOL[3])
    -- franja de nube cruzando el sol

    -- 3. ciudad lejana en bruma
    local lej = { {0,41},{4,41},{4,38},{8,38},{8,42},{12,42},{12,36},{14,35},{16,36},{16,43},{21,43},{21,40},{26,40},{26,45},
                  {30,45},{30,47},{60,47},{60,41},{62,40},{64,40},{64,HOR},{0,HOR} }
    L.poligono(img, lej, LEJOS)
    local cer = { {0,44},{3,44},{3,42},{7,42},{8,43},{8,46},{11,46},{11,43},{14,43},{15,44},{16,42},{18,43},{18,47},{24,47},{24,48},
                  {29,48},{29,49},{61,49},{61,45},{64,45},{64,HOR + 1},{0,HOR + 1} }
    L.poligono(img, cer, CIUDAD)
    -- poste torcido con cables, a la izquierda del sol

    -- 4. suelo: calle oscura con reflejo del sol
    for y = HOR, H - 1 do for x = 0, W - 1 do
      local c = SUELO[2]
      if y >= 56 then c = SUELO[1] end
      L.px(img, x, y, c)
    end end
    for y = HOR, HOR + 1 do for x = 0, W - 1 do L.px(img, x, y, CIUDAD) end end
    local refl = { { 52, 4, CIELO[4] }, { 54, 3, CIELO[3] } }
    for i, f in ipairs(refl) do
      local off = (i % 2 == 0) and 1 or -1
      for x = SX - f[2] + off, SX + f[2] + off do L.px(img, x, f[1], f[3]) end
    end
    -- 5. la horda: siluetas con luz de contorno hacia el sol
    local fondo = img:clone()
    local m = silueta()
    local horda = { -- x, pies, altura, variante
      { 33, 50, 12, 4 }, { 47, 51, 13, 2 }, { 63, 50, 13, 5 },
      { 40, 57, 23, 1 }, { 52, 56, 25, 3 }, { 61, 62, 30, 0 },
    }
    for _, z in ipairs(horda) do zombi(m, z[1], z[2], z[3], z[4]) end
    for y = 0, H - 1 do for x = 0, W - 1 do if m[y][x] then L.px(img, x, y, SOMBRA) end end end
    -- luz que envuelve el borde: solo donde la silueta toca el cielo o el sol encendidos
    local function brillo(c)
      for j = 5, #CIELO do if c == CIELO[j] then return j >= 7 and 2 or 1 end end
      for j = 1, #SOL do if c == SOL[j] then return 3 end end
      return 0
    end
    local function borde(mm, cols, fondo)
      local pintar = {}
      for y = 0, H - 1 do for x = 0, W - 1 do
        if mm[y][x] then
          local best = 0
          for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, -1 }, { 1, -1 } }) do
            local nx, ny = x + d[1], y + d[2]
            if nx >= 0 and ny >= 0 and nx < W and ny < H and not mm[ny][nx] then
              best = math.max(best, brillo(fondo:getPixel(nx, ny)))
            end
          end
          if best > 0 then pintar[#pintar + 1] = { x, y, cols[best] } end
        end
      end end
      for _, p in ipairs(pintar) do L.px(img, p[1], p[2], p[3]) end
    end
    borde(m, BORDE, fondo)
    -- 6. superviviente de espaldas, mirando a la derecha, con escopeta baja
    local fondo2 = img:clone()
    local s = silueta()
    melipse(s, 17.5, 20, 4.2, 4.6)                                  -- cabeza
    melipse(s, 21.6, 21, 1.1, 1.4)                                  -- oreja
    mpoli(s, { {15.5,23},{20,23},{20.5,28},{15,28} })               -- cuello
    mpoli(s, { {5,33},{8,28},{14,26.5},{21,26.5},{26,28},{29,32},{28,47},{26,52},{9,52},{7,46} }) -- torso
    mpoli(s, { {9,52},{17,52},{16,64},{8,64} })                     -- pierna izquierda
    mpoli(s, { {18,52},{26,52},{28,64},{20,64} })                   -- pierna derecha
    mgrueso(s, 7.5, 31, 6.5, 43, 4.4)                               -- brazo izquierdo colgando
    melipse(s, 7, 45, 2, 2.3)                                       -- mano
    mgrueso(s, 26, 30, 29, 37, 4.2)                                 -- brazo derecho
    mgrueso(s, 29, 37, 34, 38.5, 3.6)                               -- antebrazo
    mgrueso(s, 22, 35, 35, 44, 2.2)                                 -- escopeta
    mgrueso(s, 29, 38.5, 32, 41.5, 3.2)                             -- guardamanos y mano
    for y = 0, H - 1 do for x = 0, W - 1 do if s[y][x] then L.px(img, x, y, SURV) end end end
    -- chaqueta azul acero muy oscura y mochila de cuero en sombra
    local CHQ = h("131620")
    for y = 27, 52 do for x = 5, 29 do if s[y][x] then L.px(img, x, y, CHQ) end end end
    L.poligono(img, { {10,31},{21,31},{22,45},{20,47},{12,47},{10,44} }, h("19141a"))
    L.rect(img, 11, 39, 11, 1, h("17120f"))
    L.linea(img, 11, 32, 11, 44, h("231b1c"))
    L.linea(img, 10, 28, 11, 31, h("17120f")); L.linea(img, 22, 28, 21, 31, h("17120f")) -- correas
    borde(s, { BORDE[1], BORDE[2], BORDE[3] }, fondo2)
    -- luz de contorno del sol en el lado derecho de cabeza, hombro y brazo
    for y = 15, 46 do
      for x = W - 2, 0, -1 do
        if s[y][x] and not s[y][x + 1] then
          L.px(img, x, y, (y < 30) and BORDE[2] or BORDE[1])
          if y < 24 and y > 16 then L.px(img, x - 1, y, BORDE[1]) end
          break
        end
      end
    end
    -- filo del cañón iluminado por el sol
    L.linea(img, 31, 41, 34, 43, h("e0a050"))
  end,
})
