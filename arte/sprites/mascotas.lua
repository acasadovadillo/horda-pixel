-- MASCOTAS de Horda Pixel, de perfil mirando a la derecha (el juego las voltea). Construye:
--   perro (24x20; quieto 2, andar 4, atacar 2; pies { 12, 19 }): perro pastor marrón con el lomo oscuro.
--   gato (20x16; quieto 2, andar 4; pies { 10, 15 }): gato gris atigrado.
--   cuervo (16x14; volar 4, picar 2; pies { 8, 13 }): cuervo negro azulado (el juego lo dibuja en el aire).
local L = dofile(app.params.lib)
local TI, TIERRA, PELO, CARNE = L.rampa("tinta"), L.rampa("tierra"), L.rampa("pelo"), L.rampa("carne")
local GRIS = { L.hex("2b2c2f"), L.hex("414348"), L.hex("5a5d62"), L.hex("777a7e"), L.hex("94979a") }
local NEGRO = { L.hex("0e0d12"), L.hex("1c1a22"), L.hex("2c2a36"), L.hex("434056"), L.hex("5e5a78") }
local MARRON = { L.hex("2c1f15"), L.hex("47331f"), L.hex("664a2e"), L.hex("85643f"), L.hex("a3804f") }
local M = L.hex("ff00ff")

local function mascara(img)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < w and y < h and s[y * w + x] end
end
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
-- Pata: de (x, y0) a (x + dx, y1), 2 px de ancho, con la pezuña más oscura.
local function pata(m, x, y0, y1, dx, ancho)
  ancho = ancho or 2
  for y = y0, y1 do
    local u = (y - y0) / math.max(1, y1 - y0)
    local xx = math.floor(x + dx * u + 0.5)
    L.rect(m, xx, y, ancho, 1, M)
  end
end

---------------------------------------------------------------- perro
-- f = fase: piernas (cada par: delantera y trasera), cola, salto (y del cuerpo), boca abierta.
local function perro(p)
  return function(img)
    local by = p.by or 0
    -- patas del lado lejano (más oscuras), detrás del cuerpo
    pieza(img, function(m)
      pata(m, 15, 12 + by, 18, p.dl or 0); pata(m, 6, 12 + by, 18, p.tl or 0)
    end, { MARRON[1], MARRON[1], MARRON[2], MARRON[3] })
    -- cola
    pieza(img, function(m)
      local c = p.cola or 0
      L.grueso(m, 4, 9 + by, 1, 5 + by + c, 2, M)
    end, MARRON)
    -- cuerpo
    pieza(img, function(m)
      L.elipse(m, 10.5, 9.5 + by, 6.5, 3.2, M)
      L.elipse(m, 15, 9 + by, 3, 3.2, M)          -- pecho
      L.rect(m, 15, 5 + by, 3, 4, M)              -- cuello
    end, MARRON, function(m)
      -- lomo oscuro (manta)
      for x = 6, 15 do for y = 6 + by, 8 + by do if L.opaco(m, x, y) and (y < 8 + by or x % 3 ~= 0) then L.px(m, x, y, PELO[2]) end end end
      L.px(m, 5, 8 + by, PELO[3])
      -- vientre claro
      for x = 8, 15 do if L.opaco(m, x, 12 + by) then L.px(m, x, 12 + by, MARRON[5]) end end
    end)
    -- cabeza con hocico y orejas
    pieza(img, function(m)
      L.elipse(m, 18.5, 5.5 + by, 2.6, 2.4, M)
      L.rect(m, 20, 5 + by + (p.boca and 0 or 0), 3, 3, M)       -- hocico
      L.poligono(m, { { 16, 4 + by }, { 17, 0 + by }, { 18.5, 3.5 + by } }, M)   -- oreja
    end, MARRON, function(m)
      L.px(m, 18, 4 + by, TI[1])                                -- ojo
      L.px(m, 22, 5 + by, TI[1])                                -- trufa
      puntos(m, { { 17, 1 + by }, { 17, 2 + by } }, PELO[2])
    end)
    if p.boca then                                               -- boca abierta: lengua y dientes
      L.rect(img, 20, 8 + by, 3, 1, TI[1]); L.px(img, 21, 9 + by, CARNE[4]); L.px(img, 22, 7 + by, L.col("tela", 4))
    end
    -- patas del lado cercano
    pieza(img, function(m)
      pata(m, 16, 12 + by, 18, p.dc or 0); pata(m, 7, 12 + by, 18, p.tc or 0)
    end, MARRON)
    L.contorno(img, TI[1])
  end
end
L.construir("perro", 24, 20, {
  perro({ cola = 0 }), perro({ cola = -2 }),                                             -- quieto (mueve la cola)
  perro({ dc = 2, tl = 2, dl = -2, tc = -2, cola = -1 }),                                -- andar (trote)
  perro({ by = -1, cola = 0 }),
  perro({ dc = -2, tl = -2, dl = 2, tc = 2, cola = -1 }),
  perro({ by = -1, cola = -2 }),
  perro({ by = -1, dc = 3, dl = 3, tc = -1, tl = -1, boca = true, cola = -3 }),          -- atacar: se lanza con la boca abierta
  perro({ by = 0, dc = 1, dl = 1, boca = true, cola = -1 }),
}, { { "quieto", 1, 2 }, { "andar", 3, 6 }, { "atacar", 7, 8 } },
  { 0.4, 0.4, 0.09, 0.09, 0.09, 0.09, 0.1, 0.15 }, { pies = { 12, 19 } })

---------------------------------------------------------------- gato
local function gato(p)
  return function(img)
    local by = p.by or 0
    pieza(img, function(m) pata(m, 13, 11 + by, 15, p.dl or 0, 1); pata(m, 6, 11 + by, 15, p.tl or 0, 1) end, { GRIS[1], GRIS[1], GRIS[2], GRIS[2] })
    -- cola levantada en curva
    pieza(img, function(m)
      local c = p.cola or 0
      L.grueso(m, 4, 9 + by, 2, 6 + by, 1.6, M); L.grueso(m, 2, 6 + by, 2 + c, 2 + by, 1.6, M)
    end, GRIS)
    pieza(img, function(m) L.elipse(m, 9, 9.5 + by, 5, 2.4, M) end, GRIS, function(m)
      for _, x in ipairs({ 6, 9, 12 }) do L.px(m, x, 8 + by, GRIS[2]); L.px(m, x, 9 + by, GRIS[2]) end      -- rayas
    end)
    pieza(img, function(m)
      L.elipse(m, 14.5, 7 + by, 2.4, 2.1, M)
      L.poligono(m, { { 12.5, 6 + by }, { 13, 3 + by }, { 14.5, 5 + by } }, M)
      L.poligono(m, { { 15, 5 + by }, { 16.5, 3 + by }, { 17, 6 + by } }, M)
    end, GRIS, function(m)
      L.px(m, 15, 6 + by, L.hex("c9c25a")); L.px(m, 17, 7 + by, CARNE[4])
    end)
    pieza(img, function(m) pata(m, 14, 11 + by, 15, p.dc or 0, 1); pata(m, 7, 11 + by, 15, p.tc or 0, 1) end, GRIS)
    L.contorno(img, TI[1])
  end
end
L.construir("gato", 20, 16, {
  gato({ cola = 0 }), gato({ cola = 1 }),
  gato({ dc = 2, tl = 2, dl = -2, tc = -2 }), gato({ by = -1, cola = 1 }),
  gato({ dc = -2, tl = -2, dl = 2, tc = 2 }), gato({ by = -1 }),
}, { { "quieto", 1, 2 }, { "andar", 3, 6 } }, { 0.45, 0.45, 0.08, 0.08, 0.08, 0.08 }, { pies = { 10, 15 } })

---------------------------------------------------------------- cuervo
-- ala: -1 arriba, 0 en medio, 1 abajo; picar = cabeza abajo y alas plegadas.
local function cuervo(ala, picar)
  return function(img)
    local hy = picar and 9 or 6
    -- ala lejana
    if not picar then
      pieza(img, function(m)
        if ala < 0 then L.poligono(m, { { 6, 7 }, { 10, 7 }, { 7, 0 } }, M)
        elseif ala == 0 then L.poligono(m, { { 5, 7 }, { 10, 7 }, { 3, 4 } }, M)
        else L.poligono(m, { { 6, 8 }, { 10, 8 }, { 6, 13 } }, M) end
      end, { NEGRO[1], NEGRO[1], NEGRO[2], NEGRO[3] })
    end
    -- cuerpo y cola
    pieza(img, function(m)
      L.elipse(m, 8, 8, 4, 2, M)
      L.poligono(m, { { 4, 7 }, { 1, 8 }, { 1, 10 }, { 4, 9 } }, M)
    end, NEGRO)
    -- cabeza y pico
    pieza(img, function(m) L.elipse(m, 12, hy, 1.8, 1.6, M) end, NEGRO, function(m) L.px(m, 12, hy - 1, L.hex("c9c25a")) end)
    puntos(img, { { 14, hy }, { 15, hy + (picar and 1 or 0) } }, GRIS[3])
    -- ala cercana
    pieza(img, function(m)
      if picar then L.poligono(m, { { 5, 7 }, { 11, 7 }, { 6, 9 } }, M)
      elseif ala < 0 then L.poligono(m, { { 7, 7 }, { 11, 7 }, { 9, 1 } }, M)
      elseif ala == 0 then L.poligono(m, { { 6, 7 }, { 11, 7 }, { 4, 3 } }, M)
      else L.poligono(m, { { 7, 8 }, { 11, 8 }, { 8, 13 } }, M) end
    end, NEGRO, function(m) for x = 5, 10 do if L.opaco(m, x, 7) then L.px(m, x, 7, NEGRO[5]) end end end)
    L.contorno(img, TI[1])
  end
end
L.construir("cuervo", 16, 14, {
  cuervo(-1), cuervo(0), cuervo(1), cuervo(0), cuervo(0, true), cuervo(1, true),
}, { { "volar", 1, 4 }, { "picar", 5, 6 } }, { 0.08, 0.08, 0.08, 0.08, 0.12, 0.12 }, { pies = { 8, 13 } })
