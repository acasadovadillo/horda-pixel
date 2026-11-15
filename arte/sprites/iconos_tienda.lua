-- iconos_tienda (24x24, 14 fotogramas): iconos de las tarjetas de la tienda de la base.
-- Se ven sobre un panel oscuro (#26252e / #34363d). Luz arriba a la izquierda, contorno de 1 px
-- (tono oscuro del propio material arriba a la izquierda, tinta abajo a la derecha).
-- Cada pieza se dibuja en su propia capa y se perfila antes de pegarla: así las piezas que se
-- solapan quedan separadas por su contorno.
local L = dofile(app.params.lib)
local pc = app.pixelColor
local W = 24
local floor, sqrt, abs, min, max = math.floor, math.sqrt, math.abs, math.min, math.max

---------------------------------------------------------------- colores
local H = L.hex
local function rgb(c) return pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c) end
local function osc(c, k)
  local r, g, b = rgb(c)
  return pc.rgba(floor(r * k), floor(g * k), floor(b * k), 255)
end
local function rampa(t) local r = {} for i, h in ipairs(t) do r[i] = H(h) end return r end

local TINTA  = L.col("tinta", 1)
local MET    = L.rampa("metal")                                        -- 1..6
local MAD    = L.rampa("madera")
local TELA   = L.rampa("tela")
local ROJO   = L.rampa("rojo")
local HORM   = L.rampa("hormigon")
local FUEGO  = L.rampa("fuego")
local AZUL   = L.rampa("chaqueta")
local LATON  = rampa({ "4a3812", "7a5e1e", "a8862e", "c9a84a", "e6cf7e" })
local COBRE  = rampa({ "3d1c0e", "6b3418", "9a5528", "c27a42", "e0a26a" })
local CARTON = rampa({ "2e2416", "4a3a22", "6b5533", "8a7045", "a88c5a" })
local PLAST  = rampa({ "3d0e10", "6e1a1a", "9c2a26", "c0443a", "dc7262" })  -- cartucho de escopeta
local OLIVA  = rampa({ "1f2416", "323a22", "4a5432", "66713f", "858f55" })
local VERDE  = rampa({ "1f4a1c", "357a2c", "55a83f", "8cd66a", "c4f0a0" })  -- flechas y «+» de mejora

---------------------------------------------------------------- capas y contorno
local function perfilar(img)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do
    local c = img:getPixel(x, y)
    s[y * w + x] = pc.rgbaA(c) > 0 and c or false
  end end
  local function g(x, y)
    if x < 0 or y < 0 or x >= w or y >= h then return false end
    return s[y * w + x]
  end
  for y = 0, h - 1 do for x = 0, w - 1 do
    if not s[y * w + x] then
      if g(x - 1, y) or g(x, y - 1) then
        img:drawPixel(x, y, TINTA)                       -- borde abajo-derecha
      else
        local n = g(x + 1, y) or g(x, y + 1)
        if n then img:drawPixel(x, y, osc(n, 0.40)) end  -- borde arriba-izquierda
      end
    end
  end end
end

-- Dibuja fn en una capa nueva, la perfila y la pega encima.
local function capa(dst, fn, sinPerfil)
  local t = L.imagen(W, W)
  fn(t)
  if not sinPerfil then perfilar(t) end
  L.pegar(dst, t, 0, 0)
end

---------------------------------------------------------------- formas
local LX, LY = -0.7071, -0.7071

-- Barra (cilindro) de (x0,y0) a (x1,y1) con radio r. color(t, s) -> color o nil;
-- t va de 0 a 1 a lo largo del eje y s de -1 (sombra) a 1 (luz) a través.
-- radio puede ser una función de t (para puntas). redondo = extremos redondeados.
local function barra(img, x0, y0, x1, y1, r, color, redondo)
  local dx, dy = x1 - x0, y1 - y0
  local len = sqrt(dx * dx + dy * dy)
  local ux, uy = dx / len, dy / len
  local nx, ny = -uy, ux
  if nx * LX + ny * LY < 0 or (abs(nx * LX + ny * LY) < 0.01 and nx > 0) then nx, ny = -nx, -ny end
  local rmax = type(r) == "number" and r or 4
  for y = floor(min(y0, y1) - rmax - 1), math.ceil(max(y0, y1) + rmax + 1) do
    for x = floor(min(x0, x1) - rmax - 1), math.ceil(max(x0, x1) + rmax + 1) do
      local px, py = x + 0.5 - x0, y + 0.5 - y0
      local tl = px * ux + py * uy
      local sp = px * nx + py * ny
      local t = tl / len
      local rr = type(r) == "number" and r or r(max(0, min(1, t)))
      local dentro
      if redondo then
        local ex = tl - max(0, min(len, tl))
        dentro = ex * ex + sp * sp <= rr * rr
      else
        dentro = tl >= 0 and tl <= len and abs(sp) <= rr
      end
      if dentro and rr > 0 then
        local c = color(t, sp / rr)
        if c then L.px(img, x, y, c) end
      end
    end
  end
end

-- Tono de una rampa según s (-1 sombra .. 1 luz): base en el centro, brillo cerca del lado de luz.
local function tono(R, s, brillo)
  local n = #R
  local i
  if s > 0.55 then i = n - 1
  elseif s > 0.15 then i = n
  elseif s > -0.35 then i = n - 1
  elseif s > -0.7 then i = n - 2
  else i = n - 3 end
  if not brillo and i == n then i = n - 1 end
  return R[max(1, i)]
end

local function caja(img, x, y, w, alto, R, i)          -- rectángulo con luz arriba-izq
  L.rect(img, x, y, w, alto, R[i])
  L.rect(img, x, y, w, 1, R[i + 1])
  L.rect(img, x, y, 1, alto, R[i + 1])
  L.rect(img, x + w - 1, y + 1, 1, alto - 1, R[i - 1])
  L.rect(img, x + 1, y + alto - 1, w - 1, 1, R[i - 1])
end

-- Cruz o «+»: centro (cx, cy) en píxeles enteros, brazo b (largo desde el centro), grosor g impar.
local function cruz(img, cx, cy, b, g, c)
  local m = (g - 1) / 2
  L.rect(img, cx - b, cy - m, 2 * b + 1, g, c)
  L.rect(img, cx - m, cy - b, g, 2 * b + 1, c)
end

-- Cruz con volumen (luz arriba-izq, sombra abajo-der).
local function cruz3d(img, cx, cy, b, g, R)
  local m = (g - 1) / 2
  cruz(img, cx, cy, b, g, R[2])
  L.rect(img, cx - b, cy - m, 2 * b + 1, 1, R[3])
  L.rect(img, cx - m, cy - b, g, 1, R[3])
  L.rect(img, cx - m, cy - b, 1, b - m, R[3])
  L.rect(img, cx - b, cy - m, 1, g, R[3])
  L.rect(img, cx + m + 1, cy + m, b - m, 1, R[1])
  L.rect(img, cx + m, cy + m + 1, 1, b - m, R[1])
end

local function flechaArriba(img, cx, ytop, ancho, alto, tallo)   -- cx centro (entero), ancho impar
  local m = floor(ancho / 2)
  local pts = {}
  for k = 0, m do
    local y = ytop + k
    L.rect(img, cx - k, y, 2 * k + 1, 1, VERDE[3])
    L.px(img, cx - k, y, VERDE[4])
    L.px(img, cx + k, y, VERDE[2])
  end
  L.px(img, cx, ytop, VERDE[5])
  local ty = ytop + m + 1
  local tm = floor(tallo / 2)
  L.rect(img, cx - tm, ty, tallo, alto - m - 1, VERDE[3])
  L.rect(img, cx - tm, ty, 1, alto - m - 1, VERDE[4])
  L.rect(img, cx + tm, ty, 1, alto - m - 1, VERDE[2])
end

local function signoMas(img, cx, cy)                -- «+» de 7x7 con brazos de 3
  cruz(img, cx, cy, 3, 3, VERDE[3])
  L.rect(img, cx - 3, cy - 1, 7, 1, VERDE[4])
  L.rect(img, cx - 1, cy - 3, 3, 1, VERDE[4])
  L.rect(img, cx - 1, cy - 3, 1, 3, VERDE[4])
  L.px(img, cx - 3, cy - 1, VERDE[5]); L.px(img, cx - 1, cy - 3, VERDE[5])
  L.rect(img, cx + 2, cy + 1, 2, 1, VERDE[2])
  L.rect(img, cx + 1, cy + 2, 1, 2, VERDE[2])
end

---------------------------------------------------------------- piezas comunes
-- Bala de pie (3 px de ancho): punta de cobre y vaina de latón.
local function balaPie(img, x, y, alto)
  L.px(img, x + 1, y, COBRE[5])
  L.px(img, x, y + 1, COBRE[4]); L.px(img, x + 1, y + 1, COBRE[5]); L.px(img, x + 2, y + 1, COBRE[3])
  L.px(img, x, y + 2, COBRE[3]); L.px(img, x + 1, y + 2, COBRE[4]); L.px(img, x + 2, y + 2, COBRE[2])
  for yy = y + 3, y + alto - 1 do
    L.px(img, x, yy, LATON[4]); L.px(img, x + 1, yy, LATON[5]); L.px(img, x + 2, yy, LATON[3])
  end
end

-- Bala tumbada de (x0,y0) (culote) a (x1,y1) (punta), radio r; la punta ocupa la fracción fp.
local function balaTumbada(img, x0, y0, x1, y1, r, fp)
  fp = fp or 0.4
  barra(img, x0, y0, x1, y1, function(t)
    if t < 1 - fp then return r end
    local u = (t - (1 - fp)) / fp
    return r * sqrt(max(0, 1 - u * u * 0.92))
  end, function(t, s)
    if t < 0.06 then return tono(LATON, s) end
    if t < 1 - fp then return tono(LATON, s, true) end
    return tono(COBRE, s, true)
  end)
end

-- Cargador recto de subfusil: x izquierda, de y0 a y1 (sin contar la base), ancho 6.
local function cargador(img, x, y0, y1)
  L.rect(img, x, y0, 6, y1 - y0 + 1, MET[4])
  L.rect(img, x, y0, 1, y1 - y0 + 1, MET[5])
  L.rect(img, x + 1, y0, 1, y1 - y0 + 1, MET[6])
  L.rect(img, x + 4, y0, 1, y1 - y0 + 1, MET[3])
  L.rect(img, x + 5, y0, 1, y1 - y0 + 1, MET[2])
  -- nervio central rehundido
  L.rect(img, x + 2, y0 + 2, 1, y1 - y0 - 3, MET[3])
  L.rect(img, x + 3, y0 + 2, 1, y1 - y0 - 3, MET[5])
  -- base más ancha
  L.rect(img, x - 1, y1 + 1, 8, 2, MET[3])
  L.rect(img, x - 1, y1 + 1, 8, 1, MET[5])
  L.px(img, x - 1, y1 + 2, MET[4])
end

-- Bala que asoma arriba del cargador (tumbada, mirando a la derecha).
local function balaArriba(img, x, y)
  L.rect(img, x, y, 6, 3, LATON[3])
  L.rect(img, x, y, 6, 1, LATON[5])
  L.rect(img, x, y + 1, 6, 1, LATON[4])
  L.rect(img, x + 6, y, 2, 3, COBRE[3])
  L.px(img, x + 6, y, COBRE[5]); L.px(img, x + 7, y, COBRE[4])
  L.px(img, x + 6, y + 1, COBRE[4]); L.px(img, x + 8, y + 1, COBRE[3])
  L.px(img, x + 7, y + 2, COBRE[2]); L.px(img, x + 6, y + 2, COBRE[2])
end

---------------------------------------------------------------- iconos
local iconos = {}

-- 0. Munición de pistola: caja abierta de cartón con balas de 9 mm de pie.
iconos[1] = function(img)
  capa(img, function(t)                          -- fondo interior de la caja
    L.rect(t, 3, 10, 18, 5, CARTON[1])
    L.rect(t, 3, 10, 18, 1, CARTON[3])
  end)
  capa(img, function(t)                          -- fila de atrás
    for i = 0, 3 do balaPie(t, 4 + i * 4, 5, 7) end
  end)
  capa(img, function(t)                          -- fila de delante
    for i = 0, 3 do balaPie(t, 6 + i * 4, 8, 7) end
  end)
  capa(img, function(t)                          -- cara frontal de la caja
    caja(t, 3, 14, 18, 7, CARTON, 3)
    L.rect(t, 3, 14, 18, 1, CARTON[5])
    L.rect(t, 6, 16, 12, 3, CARTON[2])           -- etiqueta impresa
    L.rect(t, 7, 17, 4, 1, CARTON[4])
    L.rect(t, 12, 17, 5, 1, CARTON[4])
  end)
end

-- 1. Munición de subfusil: cargador recto con balas arriba, y dos sueltas.
iconos[2] = function(img)
  capa(img, function(t) balaArriba(t, 4, 3) end)
  capa(img, function(t) cargador(t, 4, 6, 18) end)
  capa(img, function(t) balaTumbada(t, 13, 12.5, 21, 12.5, 1.6, 0.4) end)
  capa(img, function(t) balaTumbada(t, 14, 16.5, 22, 16.5, 1.6, 0.4) end)
  capa(img, function(t) balaTumbada(t, 12.5, 20.5, 20.5, 20.5, 1.6, 0.4) end)
end

-- 2. Munición de escopeta: montón de cartuchos rojos con culote de latón.
local function cartucho(img, x0, y0, x1, y1)
  barra(img, x0, y0, x1, y1, 2.6, function(t, s)
    if t < 0.06 then return tono(LATON, s - 0.3) end   -- reborde del culote
    if t < 0.3 then return tono(LATON, s, true) end
    if t > 0.93 then return tono(PLAST, s - 0.5) end   -- cierre en estrella
    return tono(PLAST, s, true)
  end)
end
iconos[3] = function(img)
  capa(img, function(t) cartucho(t, 15, 15, 15, 3) end)        -- de pie, detrás
  capa(img, function(t) cartucho(t, 3, 12, 15.5, 16) end)
  capa(img, function(t) cartucho(t, 21, 18, 7.5, 20.5) end)
end

-- 3. Curar un poco: rollo de venda con una cruz roja pequeña.
iconos[4] = function(img)
  capa(img, function(t)                          -- tira que se desenrolla
    L.poligono(t, { { 13, 14 }, { 18, 14 }, { 21, 20 }, { 16, 21 } }, TELA[2])
    L.poligono(t, { { 13, 14 }, { 15, 14 }, { 18, 21 }, { 16, 21 } }, TELA[3])
  end)
  capa(img, function(t)                          -- cuerpo del rollo
    barra(t, 8, 10.5, 18, 10.5, 6, function(_, s) return tono(TELA, s, true) end)
    L.rect(t, 13, 7, 2, 6, ROJO[2]); L.rect(t, 11, 9, 6, 2, ROJO[2])
    L.rect(t, 13, 7, 1, 2, ROJO[3]); L.rect(t, 11, 9, 2, 1, ROJO[3]); L.px(t, 13, 7, ROJO[4])
    L.rect(t, 15, 10, 2, 1, ROJO[1]); L.rect(t, 14, 11, 1, 2, ROJO[1])
  end)
  capa(img, function(t)                          -- cara del rollo con la espiral
    L.elipse(t, 8, 10.5, 3.2, 6, TELA[4])
    L.elipse(t, 8.3, 10.8, 2.5, 4.6, TELA[2])
    L.elipse(t, 8.2, 10.6, 2.0, 3.7, TELA[4])
    L.elipse(t, 8.4, 10.9, 1.4, 2.6, TELA[2])
    L.elipse(t, 8.4, 10.9, 0.9, 1.7, TELA[1])
    L.px(t, 6, 6, H("e8e4d4")); L.px(t, 6, 7, H("e8e4d4"))
  end)
end

-- 4. Curar del todo: maletín grande de primeros auxilios.
iconos[5] = function(img)
  capa(img, function(t)                          -- asa
    L.rect(t, 8, 2, 8, 2, MET[3])
    L.rect(t, 8, 2, 8, 1, MET[5])
    L.rect(t, 8, 4, 2, 3, MET[3]); L.rect(t, 14, 4, 2, 3, MET[2])
    L.px(t, 8, 4, MET[4])
  end)
  capa(img, function(t)
    -- tapa
    L.rect(t, 2, 7, 20, 3, TELA[4])
    L.rect(t, 2, 7, 20, 1, H("e6e2d2"))
    L.rect(t, 20, 8, 2, 2, TELA[3])
    -- junta
    L.rect(t, 2, 10, 20, 1, H("5a574e"))
    -- cara frontal
    L.rect(t, 2, 11, 20, 10, TELA[3])
    L.rect(t, 2, 11, 1, 10, TELA[4])
    L.rect(t, 20, 11, 2, 10, TELA[2])
    L.rect(t, 3, 20, 19, 1, TELA[2])
    -- cantoneras
    for _, p in ipairs({ { 2, 7 }, { 20, 7 }, { 2, 19 }, { 20, 19 } }) do
      L.rect(t, p[1], p[2], 2, 2, MET[3])
    end
    L.px(t, 2, 7, MET[5]); L.px(t, 2, 19, MET[4])
    -- cierres
    L.rect(t, 5, 9, 2, 3, MET[4]); L.px(t, 5, 9, MET[6])
    L.rect(t, 17, 9, 2, 3, MET[3]); L.px(t, 17, 9, MET[5])
    -- cruz grande
    cruz(t, 12, 15, 4, 3, ROJO[2])
    L.rect(t, 8, 14, 9, 1, ROJO[3]); L.rect(t, 11, 11, 3, 1, ROJO[3])
    L.rect(t, 11, 11, 1, 3, ROJO[3]); L.rect(t, 8, 14, 1, 3, ROJO[3])
    L.rect(t, 14, 16, 3, 1, ROJO[1]); L.rect(t, 13, 17, 1, 3, ROJO[1])
    L.px(t, 8, 14, ROJO[4]); L.px(t, 11, 11, ROJO[4])
    -- mugre
    L.rect(t, 3, 18, 2, 1, H("8a877a")); L.px(t, 19, 12, H("6e6b60"))
  end)
end

-- 5. Llevar un botiquín: bolsa pequeña de cinturón con cruz roja y un «+».
iconos[6] = function(img)
  capa(img, function(t)                          -- cinturón
    L.rect(t, 2, 8, 20, 4, CARTON[2])
    L.rect(t, 2, 8, 20, 1, CARTON[4])
    L.rect(t, 2, 11, 20, 1, CARTON[1])
    L.rect(t, 2, 9, 20, 2, CARTON[3])
    L.px(t, 3, 10, CARTON[1]); L.px(t, 20, 9, CARTON[4])
  end)
  capa(img, function(t)                          -- cuerpo de la bolsa
    L.rect(t, 6, 10, 12, 10, OLIVA[3])
    L.rect(t, 6, 10, 1, 10, OLIVA[4])
    L.rect(t, 16, 10, 2, 10, OLIVA[2])
    L.rect(t, 7, 19, 10, 1, OLIVA[2])
    L.rect(t, 7, 17, 9, 1, OLIVA[2])            -- costura de la base
    L.px(t, 6, 20, OLIVA[2])
  end)
  capa(img, function(t)                          -- solapa
    L.rect(t, 6, 5, 12, 8, OLIVA[4])
    L.rect(t, 7, 13, 10, 1, OLIVA[3])
    L.rect(t, 6, 5, 12, 1, OLIVA[5])
    L.rect(t, 6, 5, 1, 8, OLIVA[5])
    L.rect(t, 16, 6, 2, 7, OLIVA[3])
    L.rect(t, 8, 12, 9, 1, OLIVA[3])
    L.px(t, 17, 12, nil)
    cruz3d(t, 11, 9, 2, 1, ROJO)
  end)
  capa(img, function(t) signoMas(t, 18, 4) end)
end

-- 6. Chaleco antibalas: placas azul marino con correas.
iconos[7] = function(img)
  capa(img, function(t)
    -- hombreras
    L.rect(t, 5, 2, 4, 6, AZUL[3]); L.rect(t, 15, 2, 4, 6, AZUL[2])
    L.rect(t, 5, 2, 1, 6, AZUL[4]); L.rect(t, 15, 2, 1, 6, AZUL[3])
    L.rect(t, 5, 2, 4, 1, AZUL[4]); L.rect(t, 15, 2, 4, 1, AZUL[3])
    -- cuerpo
    L.poligono(t, { { 3, 9 }, { 5, 7 }, { 9, 7 }, { 10, 9 }, { 14, 9 }, { 15, 7 }, { 19, 7 }, { 21, 9 },
                    { 21, 21 }, { 3, 21 } }, AZUL[3])
    L.rect(t, 3, 9, 1, 12, AZUL[4])
    L.rect(t, 20, 9, 1, 12, AZUL[2])
    L.rect(t, 4, 20, 17, 1, AZUL[2])
  end)
  capa(img, function(t)                          -- placa frontal
    L.rect(t, 6, 9, 12, 7, AZUL[3])
    L.rect(t, 6, 9, 12, 1, AZUL[5])
    L.rect(t, 6, 9, 1, 7, AZUL[4])
    L.rect(t, 16, 10, 2, 6, AZUL[2])
  end)
  capa(img, function(t)                          -- portacargadores
    for i = 0, 2 do
      local x = 6 + i * 4
      L.rect(t, x, 15, 4, 5, AZUL[2])
      L.rect(t, x, 15, 4, 2, AZUL[4])
      L.rect(t, x, 15, 4, 1, AZUL[5])
      L.rect(t, x + 3, 17, 1, 3, AZUL[1])
    end
  end)
  capa(img, function(t)                          -- correas laterales con hebilla
    L.rect(t, 3, 12, 3, 2, OLIVA[3]); L.rect(t, 18, 12, 3, 2, OLIVA[2])
    L.rect(t, 3, 12, 3, 1, OLIVA[4])
    L.px(t, 4, 12, MET[5]); L.px(t, 19, 12, MET[4])
  end)
end

-- 7. Mejorar daño: bala con chispa de impacto y flecha hacia arriba.
local function chispa(img, cx, cy)
  local F = FUEGO
  L.linea(img, cx - 5, cy, cx + 5, cy, F[3]); L.linea(img, cx, cy - 5, cx, cy + 5, F[3])
  L.linea(img, cx - 3, cy - 3, cx + 3, cy + 3, F[2]); L.linea(img, cx - 3, cy + 3, cx + 3, cy - 3, F[2])
  L.linea(img, cx - 3, cy, cx + 3, cy, F[4]); L.linea(img, cx, cy - 3, cx, cy + 3, F[4])
  L.rect(img, cx - 1, cy - 1, 3, 3, F[4])
  L.px(img, cx, cy, F[5]); L.px(img, cx - 1, cy, F[5]); L.px(img, cx, cy - 1, F[5])
end
iconos[8] = function(img)
  capa(img, function(t) chispa(t, 16, 7) end)
  capa(img, function(t) balaTumbada(t, 3, 18, 13.5, 9.5, 2.6, 0.45) end)
  capa(img, function(t) flechaArriba(t, 18, 13, 7, 8, 3) end)
end

-- 8. Mejorar cargador: cargador alargado con un «+».
iconos[9] = function(img)
  capa(img, function(t) balaArriba(t, 5, 2) end)
  capa(img, function(t)
    cargador(t, 5, 5, 19)
    L.rect(t, 5, 13, 6, 1, MET[2])                -- junta de la extensión
    L.rect(t, 5, 14, 6, 6, MET[3])
    L.rect(t, 5, 14, 1, 6, MET[4]); L.rect(t, 6, 14, 1, 6, MET[5])
    L.rect(t, 9, 14, 1, 6, MET[2]); L.rect(t, 10, 14, 1, 6, MET[1])
    L.rect(t, 7, 15, 2, 4, MET[2])
  end)
  capa(img, function(t) signoMas(t, 17, 11) end)
end

-- 9. Mejorar recarga: cargador con flechas de giro alrededor.
local function arco(img, cx, cy, r0, r1, a0, a1)
  for y = 0, W - 1 do for x = 0, W - 1 do
    local dx, dy = x + 0.5 - cx, y + 0.5 - cy
    local d = sqrt(dx * dx + dy * dy)
    if d >= r0 and d <= r1 then
      local a = math.deg(math.atan(dy, dx)) % 360
      local ok = (a0 <= a1) and (a >= a0 and a <= a1) or (a0 > a1 and (a >= a0 or a <= a1))
      if ok then
        local luz = -(dx * LX + dy * LY) / max(d, 0.01)
        local c = VERDE[3]
        if d - r0 < 0.9 then c = luz < 0 and VERDE[2] or VERDE[4] end
        if r1 - d < 0.9 then c = luz > 0 and VERDE[2] or VERDE[4] end
        L.px(img, x, y, c)
      end
    end
  end end
end
local function punta(img, pts)
  L.poligono(img, pts, VERDE[3])
end
iconos[10] = function(img)
  capa(img, function(t) balaArriba(t, 9, 5) end)
  capa(img, function(t) cargador(t, 9, 8, 16) end)
  capa(img, function(t)
    arco(t, 12, 12, 7.6, 9.8, 200, 330)
    punta(t, { { 17, 2 }, { 22, 7 }, { 16, 8 } })
    arco(t, 12, 12, 7.6, 9.8, 20, 150)
    punta(t, { { 7, 22 }, { 2, 17 }, { 8, 16 } })
  end)
end

-- 10. Reparar muros: martillo y llave inglesa cruzados sobre tablones.
iconos[11] = function(img)
  capa(img, function(t)                          -- tablones
    for i = 0, 1 do
      local y = 14 + i * 4
      L.rect(t, 2, y, 20, 3, MAD[3 + (1 - i)])
      L.rect(t, 2, y, 20, 1, MAD[4 + (1 - i)])
      L.rect(t, 2, y + 3, 20, 1, MAD[1])
      L.rect(t, 6 + i * 7, y + 1, 4, 1, MAD[2 + (1 - i)])
      L.px(t, 4 + i * 13, y + 1, MET[4])
      L.px(t, 19 - i * 12, y + 1, MET[4])
    end
  end)
  capa(img, function(t)                          -- llave: mango
    barra(t, 18, 19, 7.5, 8.5, 1.3, function(_, s) return tono(MET, s, true) end, true)
  end)
  capa(img, function(t)                          -- llave: boca abierta
    L.elipse(t, 6.5, 7.5, 3.6, 3.6, MET[4])
    L.elipse(t, 6, 7, 2.6, 2.6, MET[5])
    L.px(t, 4, 5, MET[6]); L.px(t, 5, 5, MET[6])
    for y = 0, 12 do for x = 0, 12 do
      local px, py = x + 0.5, y + 0.5
      -- ranura de la boca orientada hacia arriba a la izquierda
      local u = (px - 6.5) * 0.7071 + (py - 7.5) * 0.7071
      local v = -(px - 6.5) * 0.7071 + (py - 7.5) * 0.7071
      if u < 0.4 and abs(v) < 1.2 then L.borrar(t, x, y) end
    end end
  end)
  capa(img, function(t)                          -- martillo: mango de madera
    barra(t, 5, 20, 15, 8.5, 1.3, function(t2, s)
      if t2 < 0.32 then return tono(CARTON, s - 0.4) end   -- empuñadura con cinta
      return tono(MAD, s, true)
    end, true)
  end)
  capa(img, function(t)                          -- martillo: cabeza de acero
    -- de la uña (arriba-izq) a la cara de golpeo (abajo-der), perpendicular al mango
    barra(t, 11.6, 4.9, 19.2, 11.5, function(u)
      if u < 0.4 then return 0.8 + u * 2.2 end
      if u < 0.55 then return 1.7 end
      return 2.8
    end, function(t2, s)
      if t2 > 0.9 then return tono(MET, s - 0.5) end
      return tono(MET, s, true)
    end)
    L.borrar(t, 12, 5)                           -- uña partida
  end)
end

-- 11. Reforzar muros: muro de bloques de hormigón con chapa de acero y flecha hacia arriba.
local function muro(t, x0, x1, y0, filas)
  -- cara de arriba (2 filas) con los huecos de los bloques
  L.rect(t, x0, y0, x1 - x0 + 1, 2, HORM[4])
  L.rect(t, x0, y0, x1 - x0 + 1, 1, HORM[5])
  for x = x0 + 1, x1 - 2, 6 do L.rect(t, x + 1, y0 + 1, 3, 1, HORM[1]) end
  for f = 0, filas - 1 do
    local y = y0 + 2 + f * 4
    L.rect(t, x0, y, x1 - x0 + 1, 4, HORM[3])
    L.rect(t, x0, y + 3, x1 - x0 + 1, 1, HORM[1])           -- llaga horizontal
    local desde = (f % 2 == 0) and x0 or x0 - 3
    for x = desde, x1, 6 do
      if x > x0 then L.rect(t, x, y, 1, 3, HORM[1]) end      -- llaga vertical
      local bx = max(x + 1, x0)
      L.rect(t, bx, y, min(x + 5, x1) - bx + 1, 1, HORM[4])   -- canto con luz
      L.px(t, min(x + 5, x1), y + 1, HORM[2])
    end
  end
  L.rect(t, x0, y0, 1, 2 + filas * 4, HORM[4])
  L.rect(t, x1, y0 + 2, 1, filas * 4, HORM[2])
end
local function bloque(t, x, y)                   -- bloque de 9x9: 3 filas de cara de arriba, 6 de frente
  L.rect(t, x, y, 9, 4, HORM[4])
  L.rect(t, x, y, 9, 1, HORM[5])
  for _, hx in ipairs({ x + 1, x + 5 }) do       -- huecos: sombra arriba, fondo con luz abajo
    L.rect(t, hx, y + 1, 3, 2, HORM[1])
    L.rect(t, hx, y + 2, 3, 1, HORM[2])
  end
  L.rect(t, x, y + 4, 9, 5, HORM[3])
  L.rect(t, x, y + 4, 1, 5, HORM[4])
  L.rect(t, x + 8, y + 4, 1, 5, HORM[2])
  L.rect(t, x + 1, y + 8, 8, 1, HORM[2])
  L.rect(t, x + 3, y + 5, 2, 1, HORM[2]); L.px(t, x + 6, y + 6, HORM[2])
end
iconos[12] = function(img)
  capa(img, function(t) bloque(t, 6, 5) end)
  capa(img, function(t) bloque(t, 2, 12) end)
  capa(img, function(t) bloque(t, 10, 12) end)
  capa(img, function(t)                          -- chapa de acero apoyada delante
    L.poligono(t, { { 14, 10 }, { 20, 9 }, { 21, 21 }, { 14, 21 } }, MET[4])
    L.linea(t, 14, 10, 20, 9, MET[6])
    L.rect(t, 14, 11, 1, 10, MET[5])
    L.rect(t, 15, 11, 1, 10, MET[6])
    L.linea(t, 20, 10, 20, 21, MET[3])
    L.rect(t, 15, 20, 6, 1, MET[2])
    for _, q in ipairs({ { 17, 12 }, { 17, 18 } }) do
      L.px(t, q[1], q[2], MET[6]); L.px(t, q[1] + 1, q[2], MET[2]); L.px(t, q[1], q[2] + 1, MET[2])
    end
  end)
  capa(img, function(t) flechaArriba(t, 18, 1, 7, 7, 3) end)
end

-- 12. Alambre de cuchillas: rollo de concertina sobre una estaca.
iconos[13] = function(img)
  capa(img, function(t)                          -- estaca de madera con punta
    L.rect(t, 10, 4, 4, 18, MAD[4])
    L.rect(t, 10, 4, 1, 18, MAD[5])
    L.rect(t, 12, 4, 1, 18, MAD[3])
    L.rect(t, 13, 4, 1, 18, MAD[2])
    L.rect(t, 11, 2, 2, 2, MAD[4]); L.px(t, 11, 2, MAD[5]); L.px(t, 12, 3, MAD[3])
    L.rect(t, 11, 19, 1, 2, MAD[3])
  end)
  -- espiras: la mitad de atrás oscura, la de delante clara, con cuchillas
  local vueltas, x0, x1, cy, R, A = 3, 4, 19.5, 12.5, 5.2, 3.0
  local function pos(u)
    local th = u * vueltas * 2 * math.pi
    return x0 + (x1 - x0) * u + A * math.sin(th), cy - R * math.cos(th), math.sin(th), th
  end
  capa(img, function(t)
    for k = 0, 1200 do
      local x, y, z = pos(k / 1200)
      if z < 0 then L.px(t, x, y, MET[4]) end
    end
  end)
  capa(img, function(t)
    for k = 0, 1200 do
      local x, y, z = pos(k / 1200)
      if z >= 0 then L.px(t, x, y, (y < cy - 1) and H("c3cbd3") or MET[6]) end
    end
    for j = 0, vueltas - 1 do                    -- cuchillas: dos por vuelta en la parte de delante
      for _, g in ipairs({ 50, 130 }) do
        local x, y = pos((j + g / 360) / vueltas)
        x, y = floor(x + 0.5), floor(y + 0.5)
        L.px(t, x - 1, y - 1, MET[6]); L.px(t, x + 1, y + 1, MET[4])
        L.px(t, x - 1, y + 1, MET[5]); L.px(t, x + 1, y - 1, MET[5])
      end
    end
  end)
end

-- 13. Bloqueado: candado grande.
iconos[14] = function(img)
  capa(img, function(t)                          -- arco
    arco(t, 12, 9, 3.4, 6.6, 180, 360)
    L.rect(t, 5, 9, 4, 3, MET[5]); L.rect(t, 15, 9, 4, 3, MET[3])
    L.rect(t, 5, 9, 1, 3, MET[4]); L.rect(t, 6, 9, 1, 3, MET[6])
    L.rect(t, 18, 9, 1, 3, MET[2])
    for y = 0, W - 1 do for x = 0, W - 1 do       -- repintar el arco en acero
      local c = L.get(t, x, y)
      if c == VERDE[3] then L.px(t, x, y, MET[5])
      elseif c == VERDE[4] then L.px(t, x, y, MET[6])
      elseif c == VERDE[2] then L.px(t, x, y, MET[3]) end
    end end
  end)
  capa(img, function(t)                          -- cuerpo
    L.rect(t, 3, 11, 18, 11, LATON[3])
    L.rect(t, 3, 11, 18, 1, LATON[5])
    L.rect(t, 3, 11, 1, 11, LATON[4])
    L.rect(t, 4, 12, 1, 9, LATON[4])
    L.rect(t, 19, 12, 2, 10, LATON[2])
    L.rect(t, 4, 21, 17, 1, LATON[1])
    for _, y in ipairs({ 14, 17 }) do L.rect(t, 5, y, 14, 1, LATON[2]) end   -- láminas
    -- bocallave
    L.rect(t, 11, 15, 2, 2, TINTA); L.rect(t, 11, 17, 2, 3, TINTA)
    L.px(t, 10, 15, LATON[1]); L.px(t, 13, 16, LATON[4])
    L.rect(t, 10, 14, 4, 1, LATON[4])
  end)
end

L.construir("iconos_tienda", W, W, iconos, {}, 0.1)
