-- BRAZOS CON PISTOLA de Horda Pixel (44x20): los dos brazos del jugador sujetando el arma, apuntando a la derecha.
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

---------------------------------------------------------------- pistola
local PX, PY = 21.5, 10.5             -- centro de la mano que empuña en «apuntar»
local FX, FY = 8.8, 9.0               -- hombro lejano: casi tapado por el cercano

-- r = retroceso de la corredera en píxeles
local function pistola(img, T, r)
  -- empuñadura (la tapa la mano) y talón con la base del cargador
  caja(img, T, 20, 9, 22, 11, ME[2])
  caja(img, T, 19, 12, 21, 12, ME[1])
  pix(img, T, 19, 12, ME[2])
  -- armazón y guardamonte
  caja(img, T, 20, 9, 26, 9, ME[2])
  pix(img, T, 26, 9, ME[1])
  pix(img, T, 24, 10, ME[1])
  -- cañón: asoma cuando la corredera retrocede
  if r > 0 then caja(img, T, 29 - r, 7, 28, 7, ME[4]) end
  -- corredera
  caja(img, T, 20 - r, 7, 28 - r, 7, ME[5])
  caja(img, T, 20 - r, 8, 28 - r, 8, ME[3])
  pix(img, T, 21 - r, 7, ME[6]); pix(img, T, 22 - r, 7, ME[6])
  pix(img, T, 28 - r, 7, ME[4]); pix(img, T, 28 - r, 8, ME[2])
  pix(img, T, 20 - r, 8, ME[2])
  pix(img, T, 24 - r, 8, ME[1]); pix(img, T, 25 - r, 8, ME[1])     -- ventana de expulsión
  pix(img, T, 20 - r, 6, ME[2])                                    -- alza
end

local function cuadro(p)
  p = p or {}
  local img = L.imagen(W, H)
  local gx, gy = PX + (p.dx or 0), PY + (p.dy or 0)
  local T = marco(PX, PY, gx, gy, math.rad(p.ang or 0))
  -- 1. brazo lejano
  local lx, ly
  if p.lejos then lx, ly = p.lejos[1] + 0.5, p.lejos[2] + 0.5
  elseif p.lejosT then lx, ly = T(p.lejosT[1], p.lejosT[2])
  else lx, ly = T(PX + 0.6, PY - 0.9) end
  manga(img, FX, FY, lx, ly, p.ladoL or -1, true)
  -- 2. arma
  pistola(img, T, p.corredera or 0)
  -- 3. mano lejana suelta y lo que lleva
  if p.cae then                         -- el cargador vacío cae
    caja(img, T, 19, 14, 20, 16, ME[2])
    pix(img, T, 19, 14, ME[4]); pix(img, T, 20, 16, ME[1])
  end
  if p.trae then                        -- cargador nuevo en la mano
    local x, y = math.floor(lx), math.floor(ly)
    caja(img, fijo, x + 1, y - 3, x + 2, y - 1, ME[3])
    L.px(img, x + 1, y - 3, ME[5]); L.px(img, x + 2, y - 1, ME[1])
  end
  if p.lejos or p.lejosT then mano(img, lx, ly, true) end
  -- 4. mano cercana en la empuñadura y, delante, los dedos de la otra mano
  mano(img, gx, gy, false)
  if not (p.lejos or p.lejosT) then pix(img, T, 23, 10, PI[3]); pix(img, T, 23, 11, PI[2]) end
  -- 5. manga cercana
  manga(img, SX, SY, gx, gy, 1, false)
  return img
end

local fotos = {
  cuadro(),                                                          -- apuntar
  cuadro({ dx = -2, dy = -1, ang = -10, corredera = 2, ladoL = 1 }),          -- disparar: retroceso
  cuadro({ dx = -1, ladoL = 1 }),                                    --           vuelta a medias
  cuadro({ dx = -3, dy = 3, ang = -22, lejos = { 12, 17 }, ladoL = 1, cae = true }),   -- recargar: baja, suelta el cargador
  cuadro({ dx = -3, dy = 3, ang = -22, lejos = { 15, 17 }, ladoL = 1, trae = true }),  --           trae el nuevo
  cuadro({ dx = -3, dy = 2, ang = -22, lejosT = { 20.4, 14.2 }, ladoL = 1 }),          --           lo mete de un golpe
  cuadro({ dx = -1, dy = 1, ang = -8, ladoL = 1 }),                           --           vuelve arriba
}

L.construir("brazos_pistola", W, H, fotos,
  { { "apuntar", 1, 1 }, { "disparar", 2, 3 }, { "recargar", 4, 7 } },
  { 0.1, 0.04, 0.04, 0.25, 0.25, 0.25, 0.25 },
  { hombro = HOMBRO, boca = { 28, 7 }, casquillo = { 24, 7 } })
