-- SUBFUSIL de Horda Pixel (36x18): icono del arma sola de perfil, apuntando a la derecha (botón de la interfaz).
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

---------------------------------------------------------------- subfusil
local function dibujar(img)
  -- culata plegable de varilla: cantonera, varilla de arriba y tirante inclinado
  pieza(img, function(m)
    L.rect(m, 1, 4, 2, 8, M)
    L.rect(m, 3, 5, 7, 1, M)
    L.linea(m, 3, 10, 9, 7, M)
  end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
    L.px(m, 1, 11, ME[2]); L.px(m, 2, 11, ME[1])
  end)
  -- empuñadura de polímero
  pieza(img, function(m)
    L.poligono(m, { { 11, 9 }, { 15.5, 9 }, { 14.5, 16 }, { 10, 16 } }, M)
  end, { ME[1], ME[2], ME[2], ME[4] }, function(m)
    puntos(m, { { 12, 11 }, { 13, 11 }, { 12, 13 }, { 11, 14 }, { 13, 14 } }, ME[1])
    L.rect(m, 10, 15, 4, 1, ME[3])
  end)
  -- guardamonte
  pieza(img, function(m)
    L.rect(m, 16, 12, 3, 1, M); L.rect(m, 19, 9, 1, 4, M)
  end, { ME[1], ME[2], ME[2], ME[3] })
  puntos(img, { { 17, 9 }, { 17, 10 } }, ME[3])                 -- gatillo
  -- cargador recto
  pieza(img, function(m)
    L.rect(m, 21, 9, 4, 8, M)
  end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
    L.rect(m, 21, 16, 5, 1, ME[2]); L.px(m, 21, 16, ME[3]); L.px(m, 25, 16, ME[1])
    puntos(m, { { 23, 11 }, { 23, 13 } }, ME[2])
    L.px(m, 22, 10, ME[5])
  end)
  -- cajón de mecanismos (tubo)
  pieza(img, function(m)
    L.rect(m, 8, 4, 18, 5, M)
    L.borrar(m, 8, 4)
  end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    -- ranura y palanca de montar
    L.rect(m, 12, 5, 7, 1, ME[1]); L.rect(m, 17, 4, 2, 2, ME[5]); L.px(m, 18, 5, ME[3])
    -- ventana de expulsión
    L.rect(m, 20, 6, 3, 1, ME[1])
    -- brillo y desgaste
    puntos(m, { { 10, 4 }, { 11, 4 }, { 22, 4 }, { 23, 4 } }, ME[6])
    puntos(m, { { 10, 7 }, { 14, 7 }, { 15, 7 } }, ME[3])
    -- brocal del cargador
    L.rect(m, 20, 8, 6, 1, ME[2])
  end)
  -- camisa del cañón perforada
  pieza(img, function(m)
    L.rect(m, 26, 5, 6, 4, M)
  end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    for _, x in ipairs({ 27, 30 }) do L.rect(m, x, 6, 2, 1, ME[1]) end
    L.px(m, 28, 7, ME[1]); L.px(m, 29, 7, ME[1])
  end)
  -- cañón y bocacha
  pieza(img, function(m)
    L.rect(m, 32, 6, 3, 2, M)
  end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    L.px(m, 34, 6, ME[3]); L.px(m, 34, 7, ME[1])
  end)
  -- miras
  puntos(img, { { 9, 3 }, { 10, 3 } }, ME[3])
  L.px(img, 30, 4, ME[3])
end

L.construir("subfusil", W, H, { function(img)
  dibujar(img)
  contorno(img, function(x, y)
    return (x >= 16 and x <= 18 and y >= 9 and y <= 11)              -- hueco del guardamonte
        or (x >= 3 and x <= 8 and y >= 6 and y <= 9 and y < 10 - (x - 3) * 0.5)   -- hueco de la culata
  end)
end })
