-- PISTOLA de Horda Pixel (36x18): icono del arma sola de perfil, apuntando a la derecha (botón de la interfaz).
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

---------------------------------------------------------------- pistola
local function dibujar(img)
  -- armazón de polímero oscuro: empuñadura inclinada, cola de castor y riel delantero
  pieza(img, function(m)
    L.poligono(m, { { 5, 8 }, { 29, 8 }, { 29, 10 }, { 21, 10 }, { 14, 10 }, { 12.5, 17 }, { 4, 17 }, { 6, 10 }, { 3.5, 9.5 } }, M)
    L.rect(m, 3, 7, 3, 2, M)
  end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
    -- picado de la empuñadura en grupos
    for _, p in ipairs({ { 8, 11 }, { 9, 11 }, { 10, 12 }, { 11, 12 }, { 7, 13 }, { 8, 13 }, { 9, 14 }, { 10, 14 }, { 7, 15 }, { 8, 15 } }) do
      L.px(m, p[1], p[2], ME[2])
    end
    puntos(m, { { 7, 10 }, { 6, 12 }, { 9, 10 } }, ME[3])
    -- base del cargador
    L.rect(m, 4, 16, 9, 1, ME[3]); L.px(m, 4, 16, ME[4]); L.px(m, 12, 16, ME[1])
    -- ranuras del riel
    puntos(m, { { 23, 9 }, { 25, 9 }, { 27, 9 } }, ME[1])
    -- palanca de retenida y pasador
    L.rect(m, 13, 8, 4, 1, ME[4]); L.px(m, 16, 8, ME[3])
    L.px(m, 25, 8, ME[4])
  end)
  -- guardamonte
  pieza(img, function(m)
    L.rect(m, 15, 13, 5, 1, M); L.rect(m, 20, 10, 1, 3, M); L.px(m, 14, 12, M)
  end, { ME[1], ME[2], ME[2], ME[3] })
  -- gatillo
  puntos(img, { { 17, 10 }, { 17, 11 }, { 16, 12 } }, ME[3])
  -- corredera de acero
  pieza(img, function(m)
    L.rect(m, 3, 3, 30, 5, M)
    L.borrar(m, 32, 3); L.borrar(m, 3, 3)
  end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
    -- estrías de agarre atrás
    for _, x in ipairs({ 6, 8, 10 }) do L.rect(m, x, 4, 1, 3, ME[2]) end
    -- ventana de expulsión con el cañón asomando
    L.rect(m, 18, 3, 6, 1, ME[1]); L.rect(m, 18, 4, 6, 1, ME[3]); L.px(m, 23, 4, ME[2])
    -- brillo fino del metal
    puntos(m, { { 12, 3 }, { 13, 3 }, { 14, 3 }, { 26, 3 }, { 27, 3 }, { 28, 3 } }, ME[6])
    -- desgaste en la arista de la corredera
    puntos(m, { { 15, 7 }, { 16, 7 }, { 29, 6 } }, ME[4])
    -- boca: frente del cañón
    L.px(m, 32, 5, ME[1]); L.px(m, 32, 4, ME[3])
  end)
  -- miras
  puntos(img, { { 4, 2 }, { 5, 2 }, { 30, 2 } }, ME[3])
  L.px(img, 4, 2, ME[4])
end

L.construir("pistola", W, H, { function(img)
  dibujar(img)
  contorno(img, function(x, y) return x >= 15 and x <= 19 and y >= 10 and y <= 12 end)
end })
