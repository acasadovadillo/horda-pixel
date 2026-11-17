-- BRAZOS CON LAS ARMAS NUEVAS de Horda Pixel (44x20): los dos brazos del jugador sujetando el arma,
-- apuntando a la derecha. Construye brazos_bate, brazos_machete, brazos_francotirador, brazos_ballesta
-- y brazos_lanzallamas. El hombro { 8, 10 } es el eje: el juego coloca ese píxel sobre el hombro del
-- cuerpo y gira el sprite (con el bate y el machete, además, lo hace barrer al golpear).
-- Mismo esqueleto que brazos_escopeta.lua: cada brazo, dos huesos con cinemática inversa hasta la mano.
local L = dofile(app.params.lib)
local W, H = 44, 20
local CH, PI, ME, MA, TI = L.rampa("chaqueta"), L.rampa("piel"), L.rampa("metal"), L.rampa("madera"), L.rampa("tinta")
local SA, OX, PN, FU, CU = L.rampa("sangre"), L.rampa("oxido"), L.rampa("pintura"), L.rampa("fuego"), L.rampa("cuero")
local CINTA = { L.hex("17171c"), L.hex("25252c"), L.hex("35353e"), L.hex("4a4954") }
local OLIVA = { L.hex("1f2416"), L.hex("323a22"), L.hex("4a5432"), L.hex("66713f"), L.hex("858f55") }
local CUERDA = L.col("tela", 2)
local M = L.hex("ff00ff")
local HOMBRO = { 8, 10 }
local SX, SY = HOMBRO[1] + 0.5, HOMBRO[2] + 0.5
local FX, FY = 11.5, 11.0             -- el brazo lejano asoma por delante del pecho

local function capa() return L.imagen(W, H) end
local function mascara(img)
  local s = {}
  for y = 0, H - 1 do for x = 0, W - 1 do s[y * W + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < W and y < H and s[y * W + x] end
end

local function miembro(img, x0, y0, x1, y1, g0, g1, c)
  local dx, dy = x1 - x0, y1 - y0
  local l2 = dx * dx + dy * dy
  local rm = math.max(g0, g1) / 2
  for y = math.floor(math.min(y0, y1) - rm - 1), math.ceil(math.max(y0, y1) + rm + 1) do
    for x = math.floor(math.min(x0, x1) - rm - 1), math.ceil(math.max(x0, x1) + rm + 1) do
      local px, py = x + 0.5, y + 0.5
      local t = l2 > 0 and math.max(0, math.min(1, ((px - x0) * dx + (py - y0) * dy) / l2)) or 0
      local qx, qy = x0 + dx * t, y0 + dy * t
      local r = (g0 + (g1 - g0) * t) / 2
      if (px - qx) ^ 2 + (py - qy) ^ 2 <= r * r then L.px(img, x, y, c) end
    end
  end
end

local function volumen(m, t)
  local op = mascara(m)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if op(x, y) then
      local c = t[3]
      if not op(x + 1, y) or not op(x, y + 1) then c = t[1]
      elseif not op(x - 1, y) or not op(x, y - 1) then c = t[4]
      elseif (not op(x + 2, y) and op(x - 2, y)) or (not op(x, y + 2) and op(x, y - 2)) then c = t[2]
      end
      m:drawPixel(x, y, c)
    end
  end end
end

local function codo(ax, ay, bx, by, l1, l2, lado)
  local dx, dy = bx - ax, by - ay
  local d = math.sqrt(dx * dx + dy * dy)
  local dd = math.max(math.abs(l1 - l2) + 0.02, math.min(d, l1 + l2 - 0.02))
  local a = (l1 * l1 - l2 * l2 + dd * dd) / (2 * dd)
  local h = math.sqrt(math.max(0, l1 * l1 - a * a))
  local ux, uy = dx / d, dy / d
  return ax + ux * a - uy * h * lado, ay + uy * a + ux * h * lado
end

local LARGO1, LARGO2, MANO = 6.0, 5.0, 2.4
local function manga(img, ax, ay, hx, hy, lado, lejos)
  local ex, ey = codo(ax, ay, hx, hy, LARGO1, LARGO2 + MANO, lado)
  local dx, dy = hx - ex, hy - ey
  local d = math.sqrt(dx * dx + dy * dy)
  local wx, wy = hx - dx / d * MANO, hy - dy / d * MANO
  local m = capa()
  miembro(m, ax, ay, ex, ey, 3.7, 3.2, M)
  miembro(m, ex, ey, wx, wy, 3.2, 2.7, M)
  volumen(m, lejos and { CH[1], CH[2], CH[2], CH[3] } or { CH[1], CH[2], CH[3], CH[4] })
  L.pegar(img, m, 0, 0)
end

local MAPA_P = { a = PI[1], b = PI[2], c = PI[3], d = PI[4], e = PI[5] }
local MANO_C = { "ddc", "dcb", "cbb" }
local MANO_L = { "ccb", "cbb", "baa" }
local function mano(img, cx, cy, lejos)
  L.pintar(img, lejos and MANO_L or MANO_C, math.floor(cx) - 1, math.floor(cy) - 1, MAPA_P)
end

-- Marco del arma: piezas descritas en los píxeles de la pose «apuntar»; (px, py) es la mano que empuña,
-- que se lleva a (gx, gy) girando ang radianes.
local function marco(px, py, gx, gy, ang)
  local c, s = math.cos(ang), math.sin(ang)
  return function(x, y)
    local u, v = x - px, y - py
    return gx + u * c - v * s, gy + u * s + v * c
  end
end
local function caja(img, T, x0, y0, x1, y1, col)
  local ax, ay = T(x0, y0)
  local bx, by = T(x1 + 1, y0)
  local cx, cy = T(x1 + 1, y1 + 1)
  local dx, dy = T(x0, y1 + 1)
  L.poligono(img, { { ax, ay }, { bx, by }, { cx, cy }, { dx, dy } }, col)
end
local function pix(img, T, x, y, col)
  local cx, cy = T(x + 0.5, y + 0.5)
  L.px(img, math.floor(cx), math.floor(cy), col)
end

-- Monta un fotograma: brazo lejano, arma, mano lejana, mano cercana, brazo cercano.
-- arma(img, T, p) dibuja el arma; P = { px, py } mano que empuña; lejosT = mano lejana en el marco del arma.
local function montar(arma, P, lejosT, p)
  p = p or {}
  local img = L.imagen(W, H)
  local gx, gy = P[1] + (p.dx or 0), P[2] + (p.dy or 0)
  local T = marco(P[1], P[2], gx, gy, math.rad(p.ang or 0))
  local lx, ly
  if p.lejos then lx, ly = p.lejos[1] + 0.5, p.lejos[2] + 0.5
  else lx, ly = T((p.lejosT or lejosT)[1], (p.lejosT or lejosT)[2]) end
  manga(img, FX, FY, lx, ly, 1, true)
  arma(img, T, p)
  if p.encima then p.encima(img, lx, ly) end
  mano(img, lx, ly, true)
  mano(img, gx, gy, false)
  manga(img, SX, SY, gx, gy, 1, false)
  return img
end

---------------------------------------------------------------- bate
-- Las dos manos juntas en el mango; el bate sale recto hacia la derecha (el juego lo levanta y lo hace barrer).
local function bate(img, T)
  -- mango con cinta
  caja(img, T, 12, 10, 20, 10, CINTA[3]); caja(img, T, 12, 11, 20, 11, CINTA[2])
  caja(img, T, 11, 9, 11, 12, MA[2])                            -- pomo
  -- cuerpo que se ensancha
  caja(img, T, 21, 10, 27, 10, MA[5]); caja(img, T, 21, 11, 27, 11, MA[3])
  caja(img, T, 28, 9, 38, 9, MA[5]); caja(img, T, 28, 10, 38, 10, MA[4]); caja(img, T, 28, 11, 38, 11, MA[3]); caja(img, T, 28, 12, 38, 12, MA[2])
  caja(img, T, 32, 8, 38, 8, MA[4]); caja(img, T, 32, 13, 38, 13, MA[1])
  pix(img, T, 39, 10, MA[3]); pix(img, T, 39, 11, MA[2])
  -- sangre
  for _, c in ipairs({ { 35, 11 }, { 36, 12 }, { 37, 11 }, { 38, 12 }, { 34, 12 } }) do pix(img, T, c[1], c[2], SA[3]) end
  pix(img, T, 37, 12, SA[2]); pix(img, T, 29, 10, MA[2])
end

---------------------------------------------------------------- machete
local function machete(img, T)
  -- mango de madera con remaches y guarda
  caja(img, T, 12, 9, 19, 9, MA[4]); caja(img, T, 12, 10, 19, 11, MA[3]); caja(img, T, 12, 12, 19, 12, MA[2])
  pix(img, T, 14, 10, ME[6]); pix(img, T, 18, 10, ME[6])
  caja(img, T, 20, 8, 20, 13, ME[2])
  -- hoja: lomo oscuro arriba, cuerpo, bisel claro y filo
  caja(img, T, 21, 8, 33, 8, ME[3])
  caja(img, T, 21, 9, 35, 10, ME[4])
  caja(img, T, 21, 11, 35, 11, ME[5])
  caja(img, T, 21, 12, 34, 12, ME[6])
  caja(img, T, 34, 9, 36, 9, ME[4]); pix(img, T, 37, 9, ME[5]); pix(img, T, 36, 10, ME[5])
  -- óxido y sangre
  for _, c in ipairs({ { 23, 10 }, { 24, 10 }, { 27, 9 } }) do pix(img, T, c[1], c[2], OX[3]) end
  for _, c in ipairs({ { 29, 11 }, { 30, 11 }, { 31, 12 }, { 32, 11 }, { 33, 12 } }) do pix(img, T, c[1], c[2], SA[3]) end
  pix(img, T, 31, 11, SA[2])
end

---------------------------------------------------------------- fusil de cerrojo
local function fusil(img, T, p)
  local c = p.cerrojo or 0          -- el cerrojo abierto se va hacia atrás
  -- culata de madera
  caja(img, T, 10, 8, 15, 8, MA[4]); caja(img, T, 10, 9, 16, 9, MA[3]); caja(img, T, 10, 10, 15, 10, MA[2]); caja(img, T, 10, 11, 13, 11, MA[1])
  caja(img, T, 10, 8, 10, 11, CU[2])
  -- guardamanos de madera bajo el cañón
  caja(img, T, 22, 9, 30, 9, MA[4]); caja(img, T, 22, 10, 30, 10, MA[2])
  -- cajón y cañón
  caja(img, T, 16, 7, 23, 7, ME[5]); caja(img, T, 16, 8, 23, 8, ME[3])
  caja(img, T, 24, 7, 40, 7, ME[4]); caja(img, T, 24, 8, 39, 8, ME[2])
  pix(img, T, 27, 7, ME[6]); pix(img, T, 28, 7, ME[6]); pix(img, T, 34, 7, ME[6]); pix(img, T, 41, 7, ME[3])
  -- palanca del cerrojo
  pix(img, T, 18 - c, 9, ME[4]); pix(img, T, 18 - c, 10, ME[5])
  -- mira telescópica
  caja(img, T, 15, 4, 25, 4, ME[3]); caja(img, T, 15, 5, 25, 5, ME[2])
  caja(img, T, 14, 3, 15, 6, ME[2]); caja(img, T, 24, 3, 26, 6, ME[2])
  pix(img, T, 17, 4, ME[5]); pix(img, T, 18, 4, ME[5]); pix(img, T, 26, 4, L.col("cristal", 4))
  pix(img, T, 18, 6, ME[1]); pix(img, T, 23, 6, ME[1])
end

---------------------------------------------------------------- ballesta
-- p.cuerda = cuánto está tensada (0 = suelta, en la línea de las palas; 1 = montada); p.virote = lleva virote.
local function ballesta(img, T, p)
  local tension = p.cuerda == nil and 1 or p.cuerda
  -- culata
  caja(img, T, 10, 8, 16, 8, MA[4]); caja(img, T, 10, 9, 17, 10, MA[3]); caja(img, T, 10, 11, 14, 11, MA[2])
  -- riel
  caja(img, T, 17, 8, 33, 8, MA[5]); caja(img, T, 17, 9, 33, 9, MA[3]); caja(img, T, 18, 10, 31, 10, MA[1])
  -- estribo
  caja(img, T, 34, 6, 34, 11, ME[4]); pix(img, T, 35, 6, ME[3]); pix(img, T, 35, 11, ME[3])
  -- palas del arco (vistas en vertical, algo curvadas)
  for y = 1, 17 do
    local d = math.abs(y - 9) / 8
    local x = 31 - math.floor(d * d * 3)
    pix(img, T, x, y, OLIVA[4]); pix(img, T, x + 1, y, OLIVA[2])
  end
  -- cuerda: de las puntas de las palas hacia el centro, más atrás cuanto más tensa
  local xc = 31 - tension * 9
  for y = 2, 16 do
    local d = 1 - math.abs(y - 9) / 7
    pix(img, T, math.floor(28 + (xc - 28) * d + 0.5), y, CUERDA)
  end
  -- virote montado
  if p.virote ~= false and tension > 0.9 then
    caja(img, T, 22, 7, 35, 7, MA[4])
    pix(img, T, 36, 7, ME[6]); pix(img, T, 35, 6, ME[4]); pix(img, T, 35, 8, ME[4])
    pix(img, T, 23, 6, L.col("rojo", 2)); pix(img, T, 24, 6, L.col("rojo", 2))
  end
end

---------------------------------------------------------------- lanzallamas
local function lanzallamas(img, T, p)
  -- depósito rojo debajo (se quita al cambiarlo)
  if not p.sinDeposito then
    caja(img, T, 13, 11, 24, 11, PN[4]); caja(img, T, 13, 12, 24, 13, PN[3]); caja(img, T, 13, 14, 24, 14, PN[2])
    caja(img, T, 18, 11, 18, 14, PN[2]); pix(img, T, 14, 12, PN[5]); pix(img, T, 15, 12, PN[5])
  end
  -- cuerpo de acero
  caja(img, T, 10, 7, 29, 7, ME[5]); caja(img, T, 10, 8, 29, 9, ME[3]); caja(img, T, 10, 10, 29, 10, ME[2])
  for _, x in ipairs({ 14, 19, 24 }) do pix(img, T, x, 8, ME[2]) end
  -- empuñadura delantera
  caja(img, T, 26, 11, 27, 13, ME[2])
  -- tubo y boquilla
  caja(img, T, 30, 8, 37, 8, ME[4]); caja(img, T, 30, 9, 37, 9, ME[2])
  caja(img, T, 38, 7, 39, 10, ME[3]); pix(img, T, 38, 7, ME[5])
  -- llama piloto
  if not p.sinDeposito then pix(img, T, 40, 8, FU[4]); pix(img, T, 40, 9, FU[3]) end
end

---------------------------------------------------------------- construir
-- Cuerpo a cuerpo: un solo fotograma; «boca» es la punta (para la estela del barrido).
L.construir("brazos_bate", W, H, { montar(bate, { 17.5, 10.5 }, { 14.0, 10.6 }) },
  { { "apuntar", 1, 1 } }, 0.1, { hombro = HOMBRO, boca = { 39, 10 } })
L.construir("brazos_machete", W, H, { montar(machete, { 16.5, 10.5 }, { 13.6, 10.8 }) },
  { { "apuntar", 1, 1 } }, 0.1, { hombro = HOMBRO, boca = { 37, 10 } })

local FP = { 16.5, 11.5 }
L.construir("brazos_francotirador", W, H, {
  montar(fusil, FP, { 25.0, 10.6 }),                                                     -- apuntar
  montar(fusil, FP, { 25.0, 10.6 }, { dx = -2, ang = -6 }),                               -- disparar: culatazo
  montar(fusil, FP, { 25.0, 10.6 }, { dx = -1, ang = -3 }),
  montar(fusil, FP, { 25.0, 10.6 }, { dy = 1, ang = 8, lejosT = { 18.5, 9.5 } }),         -- recargar: mano al cerrojo
  montar(fusil, FP, { 25.0, 10.6 }, { dy = 1, ang = 8, lejosT = { 15.5, 9.5 }, cerrojo = 3 }),   -- lo abre
  montar(fusil, FP, { 25.0, 10.6 }, { dy = 2, ang = 12, lejos = { 15, 17 }, cerrojo = 3 }),       -- mete balas
  montar(fusil, FP, { 25.0, 10.6 }, { dy = 1, ang = 6, lejosT = { 18.5, 9.5 } }),         -- lo cierra
}, { { "apuntar", 1, 1 }, { "disparar", 2, 3 }, { "recargar", 4, 7 } },
  { 0.1, 0.04, 0.04, 0.25, 0.25, 0.25, 0.25 }, { hombro = HOMBRO, boca = { 41, 7 }, casquillo = { 18, 7 } })

local BP = { 16.5, 11.0 }
L.construir("brazos_ballesta", W, H, {
  montar(ballesta, BP, { 27.0, 11.0 }),                                                   -- apuntar (montada)
  montar(ballesta, BP, { 27.0, 11.0 }, { dx = -1, ang = -2, cuerda = 0 }),                -- disparar: la cuerda salta
  montar(ballesta, BP, { 27.0, 11.0 }, { cuerda = 0 }),
  montar(ballesta, BP, { 27.0, 11.0 }, { dy = 2, ang = 10, cuerda = 0, lejosT = { 29.5, 9.5 } }),   -- recargar: coge la cuerda
  montar(ballesta, BP, { 27.0, 11.0 }, { dy = 2, ang = 10, cuerda = 0.6, virote = false, lejosT = { 25.0, 9.5 } }),   -- tira
  montar(ballesta, BP, { 27.0, 11.0 }, { dy = 2, ang = 10, cuerda = 1, virote = false, lejosT = { 22.5, 9.5 } }),     -- montada
  montar(ballesta, BP, { 27.0, 11.0 }, { dy = 1, ang = 5, lejosT = { 25.5, 7.5 } }),       -- pone el virote
}, { { "apuntar", 1, 1 }, { "disparar", 2, 3 }, { "recargar", 4, 7 } },
  { 0.1, 0.05, 0.05, 0.2, 0.2, 0.2, 0.2 }, { hombro = HOMBRO, boca = { 36, 7 }, casquillo = { 24, 7 } })

local LP = { 15.5, 11.5 }
L.construir("brazos_lanzallamas", W, H, {
  montar(lanzallamas, LP, { 26.5, 12.0 }),                                                -- apuntar
  montar(lanzallamas, LP, { 26.5, 12.0 }, { dx = -1, ang = -1 }),                         -- disparar: tiembla
  montar(lanzallamas, LP, { 26.5, 12.0 }, { dx = 0, ang = 1 }),
  montar(lanzallamas, LP, { 26.5, 12.0 }, { dy = 2, ang = 10, lejosT = { 20.0, 13.0 } }),  -- recargar: mano al depósito
  montar(lanzallamas, LP, { 26.5, 12.0 }, { dy = 2, ang = 10, sinDeposito = true, lejos = { 16, 18 } }),   -- lo quita
  montar(lanzallamas, LP, { 26.5, 12.0 }, { dy = 2, ang = 10, lejosT = { 19.0, 14.0 } }),  -- pone uno lleno
  montar(lanzallamas, LP, { 26.5, 12.0 }, { dy = 1, ang = 5 }),                           -- vuelve arriba
}, { { "apuntar", 1, 1 }, { "disparar", 2, 3 }, { "recargar", 4, 7 } },
  { 0.1, 0.04, 0.04, 0.3, 0.3, 0.3, 0.3 }, { hombro = HOMBRO, boca = { 40, 8 }, casquillo = { 20, 8 } })
