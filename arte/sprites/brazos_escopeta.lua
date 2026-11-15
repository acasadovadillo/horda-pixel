-- BRAZOS CON ESCOPETA de Horda Pixel (44x20): los dos brazos del jugador sujetando el arma, apuntando a la derecha.
-- El hombro { 8, 10 } es el eje: el juego coloca ese píxel sobre el hombro del cuerpo y gira el sprite.
-- Cada brazo es un esqueleto de dos huesos (cinemática inversa hasta la mano) vestido con la misma
-- manga y los mismos tonos que el cuerpo; el arma se describe pieza a pieza en los píxeles de «apuntar»
-- y se desplaza e inclina en cada fotograma.
local L = dofile(app.params.lib)
local W, H = 44, 20
local CH, PI, ME, MA, TI = L.rampa("chaqueta"), L.rampa("piel"), L.rampa("metal"), L.rampa("madera"), L.rampa("tinta")
local M = L.hex("ff00ff")             -- color de marca para las máscaras
local HOMBRO = { 8, 10 }              -- eje de giro: el juego lo coloca sobre el hombro del cuerpo
local SX, SY = HOMBRO[1] + 0.5, HOMBRO[2] + 0.5

local function capa() return L.imagen(W, H) end

local function mascara(img)
  local s = {}
  for y = 0, H - 1 do for x = 0, W - 1 do s[y * W + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < W and y < H and s[y * W + x] end
end

-- Miembro: cápsula con grosor distinto en cada extremo (la misma que usa el cuerpo del jugador).
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

-- Volumen de una pieza estrecha (el mismo del cuerpo): t = { borde, sombra, base, luz }.
-- Borde oscuro abajo y a la derecha, luz arriba y a la izquierda.
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

-- Codo por cinemática inversa (dos huesos). lado = 1: el codo cae hacia abajo cuando el brazo va a la derecha.
local function codo(ax, ay, bx, by, l1, l2, lado)
  local dx, dy = bx - ax, by - ay
  local d = math.sqrt(dx * dx + dy * dy)
  local dd = math.max(math.abs(l1 - l2) + 0.02, math.min(d, l1 + l2 - 0.02))
  local a = (l1 * l1 - l2 * l2 + dd * dd) / (2 * dd)
  local h = math.sqrt(math.max(0, l1 * l1 - a * a))
  local ux, uy = dx / d, dy / d
  return ax + ux * a - uy * h * lado, ay + uy * a + ux * h * lado
end

-- Manga: del hombro (ax, ay) hasta la muñeca, que queda MANO px antes del centro de la mano (hx, hy).
-- Mismos grosores y tonos que los brazos de «morir» del cuerpo.
local LARGO1, LARGO2, MANO = 6.0, 5.0, 2.4
local function manga(img, ax, ay, hx, hy, lado, lejos, retoque)
  local ex, ey = codo(ax, ay, hx, hy, LARGO1, LARGO2 + MANO, lado)
  local dx, dy = hx - ex, hy - ey
  local d = math.sqrt(dx * dx + dy * dy)
  local wx, wy = hx - dx / d * MANO, hy - dy / d * MANO
  local m = capa()
  miembro(m, ax, ay, ex, ey, 3.7, 3.2, M)
  miembro(m, ex, ey, wx, wy, 3.2, 2.7, M)
  volumen(m, lejos and { CH[1], CH[2], CH[2], CH[3] } or { CH[1], CH[2], CH[3], CH[4] })
  if retoque then retoque(m, ex, ey, wx, wy) end
  L.pegar(img, m, 0, 0)
  return ex, ey, wx, wy
end

-- Manos de 3x3: la cercana con luz, la lejana un tono más oscura (como en el cuerpo).
local MAPA_P = { a = PI[1], b = PI[2], c = PI[3], d = PI[4], e = PI[5] }
local MANO_C = { "ddc", "dcb", "cbb" }
local MANO_L = { "ccb", "cbb", "baa" }
local function mano(img, cx, cy, lejos)
  L.pintar(img, lejos and MANO_L or MANO_C, math.floor(cx) - 1, math.floor(cy) - 1, MAPA_P)
end

-- Sistema de coordenadas del arma: las piezas se describen en los píxeles de la pose «apuntar»;
-- (px, py) es el centro de la mano que empuña y se lleva a (gx, gy) girando ang radianes.
local function marco(px, py, gx, gy, ang)
  local c, s = math.cos(ang), math.sin(ang)
  return function(x, y)
    local u, v = x - px, y - py
    return gx + u * c - v * s, gy + u * s + v * c
  end
end
-- Rectángulo de píxeles x0..x1, y0..y1 (ambos incluidos).
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
local function fijo(x, y) return x, y end        -- marco sin transformar (cosas sueltas en la mano)

---------------------------------------------------------------- escopeta
local PX, PY = 16.5, 11.5             -- centro de la mano que empuña en «apuntar»
local FX, FY = 11.5, 11.0             -- el brazo lejano asoma por delante del pecho
local CARTUCHO, LATON = L.hex("8a2f28"), L.col("oro", 2)

-- r = recorrido de la corredera (guardamanos) hacia atrás
local function escopeta(img, T, r)
  -- culata de madera con cantonera
  caja(img, T, 10, 8, 15, 8, MA[4])
  caja(img, T, 10, 9, 16, 9, MA[3])
  caja(img, T, 10, 10, 15, 10, MA[2])
  caja(img, T, 10, 11, 12, 11, MA[1])
  pix(img, T, 12, 8, MA[5]); pix(img, T, 13, 8, MA[5])
  pix(img, T, 13, 10, MA[1]); pix(img, T, 14, 10, MA[1])
  caja(img, T, 10, 8, 10, 11, TI[3])
  -- garganta de la culata (la tapa la mano) y guardamonte
  caja(img, T, 15, 10, 17, 11, MA[2])
  pix(img, T, 18, 10, ME[1]); pix(img, T, 19, 10, ME[1])
  -- cañón y, debajo, tubo del cargador
  caja(img, T, 22, 7, 36, 7, ME[4])
  caja(img, T, 22, 8, 34, 8, ME[2])
  pix(img, T, 24, 7, ME[5]); pix(img, T, 25, 7, ME[5]); pix(img, T, 26, 7, ME[5])
  pix(img, T, 31, 7, ME[5]); pix(img, T, 32, 7, ME[5])
  pix(img, T, 36, 7, ME[5]); pix(img, T, 34, 8, ME[3])
  -- cajón de mecanismos
  caja(img, T, 16, 7, 21, 7, ME[5])
  caja(img, T, 16, 8, 21, 8, ME[3])
  caja(img, T, 16, 9, 21, 9, ME[2])
  pix(img, T, 17, 7, ME[6]); pix(img, T, 18, 7, ME[6])
  pix(img, T, 19, 8, ME[1]); pix(img, T, 20, 8, ME[1])             -- ventana de expulsión
  pix(img, T, 21, 9, ME[1])
  -- guardamanos de madera (corredera)
  caja(img, T, 22 - r, 8, 27 - r, 8, MA[4])
  caja(img, T, 22 - r, 9, 27 - r, 9, MA[3])
  caja(img, T, 22 - r, 10, 27 - r, 10, MA[1])
  pix(img, T, 23 - r, 8, MA[5])
  pix(img, T, 22 - r, 9, MA[2]); pix(img, T, 27 - r, 9, MA[2]); pix(img, T, 27 - r, 8, MA[3])
end

local function cuadro(p)
  p = p or {}
  local img = L.imagen(W, H)
  local gx, gy = PX + (p.dx or 0), PY + (p.dy or 0)
  local r = p.corredera or 0
  local T = marco(PX, PY, gx, gy, math.rad(p.ang or 0))
  -- 1. brazo lejano
  local lx, ly
  if p.lejos then lx, ly = p.lejos[1] + 0.5, p.lejos[2] + 0.5
  elseif p.lejosT then lx, ly = T(p.lejosT[1], p.lejosT[2])
  else lx, ly = T(24.5 - r, 10.5) end
  manga(img, FX, FY, lx, ly, 1, true)
  -- 2. arma
  escopeta(img, T, r)
  -- 3. mano lejana y lo que lleva
  if p.cartucho then
    local x, y = math.floor(lx), math.floor(ly)
    L.px(img, x + 1, y - 2, CARTUCHO); L.px(img, x + 2, y - 3, CARTUCHO); L.px(img, x + 1, y - 1, LATON)
  end
  mano(img, lx, ly, true)
  -- 4. mano cercana en la garganta de la culata
  mano(img, gx, gy, false)
  -- 5. manga cercana
  manga(img, SX, SY, gx, gy, 1, false)
  return img
end

local fotos = {
  cuadro(),                                                          -- apuntar
  cuadro({ dx = -2, ang = -5 }),                                     -- disparar: culatazo
  cuadro({ dx = -1, ang = -2 }),                                     --           vuelta a medias
  cuadro({ dy = 2, ang = 15, lejos = { 15, 18 } }),                  -- recargar: baja, mano a los cartuchos
  cuadro({ dy = 2, ang = 15, lejos = { 18, 16 }, cartucho = true }), --           trae un cartucho
  cuadro({ dy = 2, ang = 15, lejosT = { 20.0, 11.6 } }),             --           lo mete por debajo
  cuadro({ dy = 1, ang = 7, corredera = 2 }),                        --           acciona la corredera y sube
}

L.construir("brazos_escopeta", W, H, fotos,
  { { "apuntar", 1, 1 }, { "disparar", 2, 3 }, { "recargar", 4, 7 } },
  { 0.1, 0.04, 0.04, 0.25, 0.25, 0.25, 0.25 },
  { hombro = HOMBRO, boca = { 36, 7 }, casquillo = { 19, 8 } })
