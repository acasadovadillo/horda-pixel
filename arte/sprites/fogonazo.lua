-- FOGONAZO de Horda Pixel (18x14): llamarada de la boca del cañón hacia la derecha.
-- 3 fotogramas: grande con núcleo blanco amarillento, más pequeña, y resto de humo.
-- Punto «origen» = { 1, 7 }: el píxel que toca la boca del cañón.
local L = dofile(app.params.lib)
local W, H = 18, 14
local F = L.rampa("fuego")
local BL = L.hex("fffbe6")
local HUMO = { L.hex("3e3e40"), L.hex("58585a"), L.hex("727272"), L.hex("8c8b88") }
local OX, CY = 1, 7.5

-- Forma de estrella alargada: largo hacia la derecha, alto de las puntas laterales, grosor.
local function llama(img, largo, alto, grueso, c)
  L.poligono(img, {
    { OX, CY - grueso * 0.7 },
    { OX + largo * 0.28, CY - grueso },
    { OX + largo * 0.45, CY - alto },
    { OX + largo * 0.55, CY - grueso * 0.9 },
    { OX + largo, CY },
    { OX + largo * 0.55, CY + grueso * 0.9 },
    { OX + largo * 0.45, CY + alto },
    { OX + largo * 0.28, CY + grueso },
    { OX, CY + grueso * 0.7 },
  }, c)
end

local function grande(img)
  llama(img, 17, 7, 3.6, F[2])
  llama(img, 15, 5.6, 2.9, F[3])
  llama(img, 12, 4.0, 2.1, F[4])
  L.elipse(img, 5, CY, 4.6, 1.6, F[5])
  L.elipse(img, 3.5, CY, 2.8, 1.0, BL)
  -- chispas sueltas en grupos
  L.rect(img, 15, 4, 1, 1, F[3]); L.rect(img, 16, 10, 1, 1, F[3]); L.px(img, 13, 2, F[2])
end

local function pequena(img)
  llama(img, 11, 4.2, 2.6, F[2])
  llama(img, 9, 3.2, 2.0, F[3])
  llama(img, 7, 2.2, 1.4, F[4])
  L.elipse(img, 3.2, CY, 2.6, 1.0, F[5])
  L.px(img, 2, 7, BL)
  -- primer humo por encima
  L.rect(img, 9, 3, 2, 1, HUMO[3]); L.px(img, 11, 3, HUMO[2])
end

local function bocanada(img, cx, cy, rx, ry)
  L.elipse(img, cx, cy, rx, ry, HUMO[2])
  L.elipse(img, cx - 0.5, cy - 0.5, rx - 0.8, ry - 0.7, HUMO[3])
  L.elipse(img, cx - 1, cy - 1, rx * 0.4, ry * 0.4, HUMO[4])
end

local function humo(img)
  bocanada(img, 4.5, 7.5, 2.4, 2.0)
  bocanada(img, 8.5, 6.2, 3.0, 2.4)
  bocanada(img, 13, 4.6, 2.6, 2.2)
  L.elipse(img, 16, 2.6, 1.3, 1.1, HUMO[2])
  -- jirones sueltos que se deshacen
  L.rect(img, 11, 8, 2, 1, HUMO[2]); L.px(img, 16, 6, HUMO[2])
  -- última brasa en la boca
  L.px(img, 1, 7, F[3]); L.px(img, 2, 7, F[2])
end

L.construir("fogonazo", W, H, { grande, pequena, humo }, nil, 0.03, { origen = { 1, 7 } })
