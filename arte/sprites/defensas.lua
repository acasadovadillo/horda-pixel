-- DEFENSAS DE LA BASE de Horda Pixel. Construye:
--   torreta (24x24, 6 fotogramas): ametralladora sobre trípode encima del muro, mirando a e, ne y n
--     (el juego voltea e y ne para w y nw); 3 a 5 = lo mismo, apagada (sin balas o con el tramo roto).
--     Punto base { 12, 21 }: se apoya en lo alto del muro.
--   foco (16x24, 2 fotogramas: encendido, roto): foco sobre un poste, alumbrando hacia fuera (al norte).
--   mina (12x7, 2 fotogramas: luz apagada, luz roja), barril_explosivo (16x22), cepo (16x9: abierto, cerrado).
local L = dofile(app.params.lib)
local ME, MA, TI, FU = L.rampa("metal"), L.rampa("madera"), L.rampa("tinta"), L.rampa("fuego")
local PN, SE, RO, OX, CU = L.rampa("pintura"), L.rampa("senal"), L.rampa("rojo"), L.rampa("oxido"), L.rampa("cuero")
local OLIVA = { L.hex("1f2416"), L.hex("323a22"), L.hex("4a5432"), L.hex("66713f"), L.hex("858f55") }
local CRIS = L.rampa("cristal")
local M = L.hex("ff00ff")

local function mascara(img)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < w and y < h and s[y * w + x] end
end
-- Volumen: t = { borde, sombra, base, luz }; luz arriba a la izquierda.
local function volumen(m, t)
  local op = mascara(m)
  for y = 0, m.height - 1 do for x = 0, m.width - 1 do
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
local function pieza(img, dibujar, t, detalles)
  local m = L.imagen(img.width, img.height)
  dibujar(m)
  volumen(m, t)
  if detalles then detalles(m) end
  L.pegar(img, m, 0, 0)
end
local function puntos(img, lista, c) for _, p in ipairs(lista) do L.px(img, p[1], p[2], c) end end
local function contorno(img) L.contorno(img, TI[1]) end
local function oscurecer(img, k)
  local pc = app.pixelColor
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    local c = img:getPixel(x, y)
    if pc.rgbaA(c) > 0 then img:drawPixel(x, y, pc.rgba(math.floor(pc.rgbaR(c) * k), math.floor(pc.rgbaG(c) * k), math.floor(pc.rgbaB(c) * k), 255)) end
  end end
end

---------------------------------------------------------------- torreta
local TW = 24
-- dir: "e", "ne", "n"
local function torreta(dir, apagada)
  return function(img)
    -- trípode: tres patas abiertas apoyadas en el muro
    puntos(img, { { 7, 21 }, { 8, 20 }, { 9, 19 }, { 10, 18 } }, ME[2])
    puntos(img, { { 17, 21 }, { 16, 20 }, { 15, 19 }, { 14, 18 } }, ME[2])
    puntos(img, { { 12, 22 }, { 12, 21 }, { 12, 20 }, { 12, 19 } }, ME[3])
    -- pivote
    pieza(img, function(m) L.rect(m, 10, 15, 5, 4, M) end, { ME[1], ME[2], ME[3], ME[4] })
    -- cuerpo del arma, caja de munición y cañón según la dirección
    if dir == "e" then
      pieza(img, function(m) L.rect(m, 6, 11, 11, 5, M) end, OLIVA, function(m)
        L.rect(m, 7, 11, 9, 1, OLIVA[5]); puntos(m, { { 9, 13 }, { 12, 13 } }, OLIVA[2])
      end)
      pieza(img, function(m) L.rect(m, 4, 12, 3, 3, M) end, { ME[1], ME[2], ME[3], ME[4] })        -- culata
      pieza(img, function(m) L.rect(m, 17, 12, 7, 2, M) end, { ME[1], ME[2], ME[3], ME[5] })       -- cañón
      pieza(img, function(m) L.rect(m, 8, 16, 5, 3, M) end, { OLIVA[1], OLIVA[2], OLIVA[2], OLIVA[3] })   -- caja de balas
      puntos(img, { { 7, 16 }, { 6, 17 } }, L.col("oro", 3))                                         -- cinta de balas
    elseif dir == "ne" then
      pieza(img, function(m) L.poligono(m, { { 6, 13 }, { 14, 8 }, { 18, 11 }, { 10, 16 } }, M) end, OLIVA, function(m)
        puntos(m, { { 11, 11 }, { 12, 12 } }, OLIVA[2])
      end)
      pieza(img, function(m) L.poligono(m, { { 3, 15 }, { 6, 13 }, { 8, 15 }, { 5, 17 } }, M) end, { ME[1], ME[2], ME[3], ME[4] })
      pieza(img, function(m) L.grueso(m, 17, 9, 22, 4, 2, M) end, { ME[1], ME[2], ME[3], ME[5] })
      pieza(img, function(m) L.rect(m, 9, 16, 5, 3, M) end, { OLIVA[1], OLIVA[2], OLIVA[2], OLIVA[3] })
      puntos(img, { { 8, 16 }, { 7, 17 } }, L.col("oro", 3))
    else -- n: de espaldas, el cañón se aleja hacia arriba
      pieza(img, function(m) L.rect(m, 8, 9, 9, 7, M) end, OLIVA, function(m)
        L.rect(m, 9, 9, 7, 1, OLIVA[5]); puntos(m, { { 10, 12 }, { 14, 12 } }, OLIVA[2])
      end)
      pieza(img, function(m) L.rect(m, 11, 2, 3, 8, M) end, { ME[1], ME[2], ME[3], ME[5] })       -- cañón (escorzo)
      pieza(img, function(m) L.rect(m, 10, 15, 5, 3, M) end, { ME[1], ME[2], ME[3], ME[4] })      -- empuñaduras
      pieza(img, function(m) L.rect(m, 16, 12, 4, 4, M) end, { OLIVA[1], OLIVA[2], OLIVA[2], OLIVA[3] })
    end
    -- escudo de chapa delante (no en «n», que lo tapa)
    contorno(img)
    if not apagada then
      -- piloto verde encendido
      L.px(img, dir == "n" and 12 or 9, dir == "n" and 13 or 14, L.hex("7ee07e"))
    else
      oscurecer(img, 0.7)
      L.px(img, dir == "n" and 12 or 9, dir == "n" and 13 or 14, RO[2])
    end
  end
end
L.construir("torreta", TW, TW, {
  torreta("e"), torreta("ne"), torreta("n"), torreta("e", true), torreta("ne", true), torreta("n", true),
}, {}, 0.1, { base = { 12, 21 } })

---------------------------------------------------------------- foco
local function foco(roto)
  return function(img)
    -- poste
    pieza(img, function(m) L.rect(m, 7, 8, 2, 15, M) end, { ME[1], ME[2], ME[3], ME[4] })
    pieza(img, function(m) L.rect(m, 5, 21, 6, 2, M) end, { ME[1], ME[2], ME[2], ME[3] })
    -- carcasa del foco, vista de espaldas (alumbra hacia el norte, lejos de la cámara)
    pieza(img, function(m) L.rect(m, 3, 2, 10, 7, M); L.rect(m, 4, 1, 8, 1, M) end, { ME[1], ME[2], ME[3], ME[4] }, function(m)
      for _, y in ipairs({ 4, 6 }) do L.rect(m, 5, y, 6, 1, ME[2]) end                          -- aletas
    end)
    contorno(img)
    if not roto then
      -- el borde de la lente asoma arriba, encendido
      L.rect(img, 4, 0, 8, 1, FU[5]); L.px(img, 3, 1, FU[4]); L.px(img, 12, 1, FU[4])
    else
      puntos(img, { { 5, 0 }, { 9, 0 } }, CRIS[2]); puntos(img, { { 7, 0 } }, CRIS[4])
    end
  end
end
L.construir("foco", 16, 24, { foco(false), foco(true) }, {}, 0.1, { base = { 8, 23 } })

---------------------------------------------------------------- mina
local function mina(luz)
  return function(img)
    pieza(img, function(m) L.elipse(m, 6, 4, 5, 2.4, M) end, OLIVA)
    pieza(img, function(m) L.rect(m, 4, 2, 4, 2, M) end, { ME[1], ME[2], ME[3], ME[4] })     -- placa de presión
    contorno(img)
    L.px(img, 9, 4, luz and RO[4] or RO[1])
  end
end
L.construir("mina", 12, 7, { mina(false), mina(true) }, {}, 0.1, { base = { 6, 6 } })

---------------------------------------------------------------- barril explosivo
L.construir("barril_explosivo", 16, 22, { function(img)
  pieza(img, function(m)
    L.rect(m, 2, 3, 12, 18, M); L.rect(m, 3, 2, 10, 1, M); L.rect(m, 3, 21, 10, 1, M)
  end, PN, function(m)
    -- luz vertical del cilindro
    L.rect(m, 4, 3, 1, 18, PN[5]); L.rect(m, 5, 3, 1, 18, PN[4]); L.rect(m, 12, 3, 1, 18, PN[2])
    -- aros
    for _, y in ipairs({ 6, 16 }) do L.rect(m, 2, y, 12, 1, PN[1]); L.rect(m, 3, y - 1, 10, 1, PN[4]) end
    -- franja amarilla de peligro con rayas
    L.rect(m, 3, 9, 10, 4, SE[3])
    for k = 0, 4 do L.px(m, 3 + k * 2, 9 + (k % 2), TI[2]); L.px(m, 4 + k * 2, 10 + (k % 2), TI[2]) end
    L.rect(m, 3, 9, 10, 1, SE[4])
    -- tapa con tapón
    L.rect(m, 3, 2, 10, 2, PN[3]); L.px(m, 10, 2, ME[4])
    -- óxido
    puntos(m, { { 6, 18 }, { 7, 19 }, { 11, 4 } }, OX[2])
  end)
  contorno(img)
end }, {}, 0.1, { base = { 8, 21 } })

---------------------------------------------------------------- cepo
local function cepo(cerrado)
  return function(img)
    -- base y muelles
    pieza(img, function(m) L.rect(m, 2, 6, 12, 2, M); L.rect(m, 6, 5, 4, 1, M) end, { ME[1], ME[2], ME[3], ME[4] })
    if not cerrado then
      -- mandíbulas abiertas en el suelo, dientes hacia dentro
      pieza(img, function(m) L.rect(m, 1, 4, 14, 1, M); L.rect(m, 1, 8, 14, 1, M); L.rect(m, 1, 4, 1, 5, M); L.rect(m, 14, 4, 1, 5, M) end,
        { ME[2], ME[3], ME[4], ME[5] })
      for x = 3, 13, 2 do L.px(img, x, 5, ME[6]); L.px(img, x, 7, ME[5]) end
      L.rect(img, 7, 6, 2, 1, OX[3])                                -- plato
    else
      -- cerradas: las dos mandíbulas arriba, dientes trabados
      pieza(img, function(m) L.rect(m, 3, 1, 10, 5, M) end, { ME[2], ME[3], ME[4], ME[5] }, function(m)
        for x = 4, 12, 2 do L.px(m, x, 3, ME[1]); L.px(m, x + 1, 4, ME[6]) end
        L.rect(m, 3, 3, 10, 1, ME[2])
      end)
      puntos(img, { { 6, 2 }, { 9, 4 } }, L.col("sangre", 3))
    end
    contorno(img)
  end
end
L.construir("cepo", 16, 9, { cepo(false), cepo(true) }, {}, 0.1, { base = { 8, 8 } })
