-- ESCOPETA de Horda Pixel (36x18): icono del arma sola de perfil, apuntando a la derecha (botón de la interfaz).
local L = dofile(app.params.lib)
local W, H = 36, 18
local ME, MA, TI = L.rampa("metal"), L.rampa("madera"), L.rampa("tinta")
local M = L.hex("ff00ff")

local function capa() return L.imagen(W, H) end
local function mascara(img)
  local s = {}
  for y = 0, H - 1 do for x = 0, W - 1 do s[y * W + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < W and y < H and s[y * W + x] end
end

-- Volumen de una pieza: t = { borde, sombra, base, luz }. Luz arriba a la izquierda,
-- borde oscuro abajo y a la derecha, sombra a dos píxeles del borde de abajo.
local function volumen(m, t)
  local op = mascara(m)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if op(x, y) then
      local c = t[3]
      if not op(x, y + 1) or not op(x + 1, y) then c = t[1]
      elseif not op(x, y - 1) or not op(x - 1, y) then c = t[4]
      elseif not op(x, y + 2) then c = t[2]
      end
      m:drawPixel(x, y, c)
    end
  end end
end

-- Pieza: dibuja la silueta con M, le da volumen con la rampa t, añade detalles y la pega.
local function pieza(img, dibujar, t, detalles)
  local m = capa()
  dibujar(m)
  volumen(m, t)
  if detalles then detalles(m) end
  L.pegar(img, m, 0, 0)
end

-- Contorno selectivo: tinta oscura abajo y a la derecha, un tono más claro arriba y a la izquierda.
-- hueco(x, y) = true deja ese píxel transparente (el hueco del guardamonte).
local function contorno(img, hueco)
  local op = mascara(img)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if not op(x, y) and not (hueco and hueco(x, y)) then
      local arriba = op(x, y + 1) or op(x + 1, y)          -- el contorno queda arriba/izquierda de la forma
      local abajo = op(x, y - 1) or op(x - 1, y)
      if arriba or abajo then
        img:drawPixel(x, y, abajo and TI[1] or TI[2])
      end
    end
  end end
end
local function puntos(img, lista, c) for _, p in ipairs(lista) do L.px(img, p[1], p[2], c) end end

---------------------------------------------------------------- escopeta
local function dibujar(img)
  -- culata de madera: talón de 6 px, garganta estrecha hacia el cajón
  pieza(img, function(m)
    L.poligono(m, { { 2, 7 }, { 14, 7 }, { 14, 10 }, { 11, 10 }, { 6, 12 }, { 2, 13 } }, M)
  end, { MA[1], MA[2], MA[3], MA[4] }, function(m)
    -- veta de la madera en trazos largos
    for _, p in ipairs({ { 4, 9, 4 }, { 3, 11, 3 }, { 9, 10, 2 } }) do L.rect(m, p[1], p[2], p[3], 1, MA[2]) end
    puntos(m, { { 4, 7 }, { 5, 7 }, { 6, 7 }, { 10, 7 } }, MA[5])
    puntos(m, { { 7, 11 }, { 8, 11 } }, MA[1])                   -- golpe
  end)
  -- cantonera de goma
  pieza(img, function(m) L.rect(m, 1, 7, 2, 6, M) end, { TI[1], TI[2], TI[3], ME[2] })
  -- guardamonte
  pieza(img, function(m)
    L.rect(m, 14, 11, 4, 1, M); L.rect(m, 18, 10, 1, 2, M)
  end, { ME[1], ME[2], ME[2], ME[3] })
  L.px(img, 16, 10, ME[3])                                        -- gatillo
  -- cajón de mecanismos pavonado
  pieza(img, function(m)
    L.rect(m, 13, 6, 9, 4, M)
  end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
    L.rect(m, 16, 7, 4, 1, ME[1])                                -- ventana de expulsión
    puntos(m, { { 14, 6 }, { 15, 6 }, { 16, 6 } }, ME[5])
  end)
  -- tubo del cargador bajo el cañón
  pieza(img, function(m) L.rect(m, 22, 8, 11, 1, M) end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
    L.px(m, 32, 8, ME[3])
  end)
  -- cañón largo
  pieza(img, function(m) L.rect(m, 22, 6, 14, 2, M) end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    puntos(m, { { 24, 6 }, { 25, 6 }, { 26, 6 }, { 31, 6 }, { 32, 6 } }, ME[6])
    L.px(m, 35, 7, ME[1]); L.px(m, 35, 6, ME[3])
  end)
  -- guardamanos de madera (corredera) con estrías
  pieza(img, function(m)
    L.rect(m, 23, 8, 7, 2, M); L.rect(m, 24, 10, 5, 1, M)
  end, { MA[1], MA[2], MA[3], MA[4] }, function(m)
    for _, x in ipairs({ 25, 27 }) do L.rect(m, x, 9, 1, 2, MA[2]) end
    puntos(m, { { 24, 8 }, { 26, 8 } }, MA[5])
  end)
  L.px(img, 34, 5, ME[5])                                         -- punto de mira
end

L.construir("escopeta", W, H, { function(img)
  dibujar(img)
  contorno(img, function(x, y) return x >= 14 and x <= 17 and y == 10 end)
end })
