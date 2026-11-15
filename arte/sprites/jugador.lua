-- JUGADOR de Horda Pixel (40x40). Construcción por anatomía:
-- un esqueleto (cadera, rodillas, tobillos, columna, hombro, codos, cabeza) define cada fotograma;
-- los miembros se construyen con formas en capas de atrás adelante y después se visten,
-- se iluminan (luz de arriba a la izquierda) y se retocan a mano píxel a píxel.
local L = dofile(app.params.lib)
local W, H = 40, 40

local CH, CQ, CU = L.rampa("chaqueta"), L.rampa("caqui"), L.rampa("cuero")
local PI, PE, TI = L.rampa("piel"), L.rampa("pelo"), L.rampa("tinta")
local SA, TE = L.rampa("sangre"), L.rampa("tela")
local BARBA, BARBA2 = L.hex("6a4a3b"), L.hex("4f372d")
local M = L.hex("ff00ff")             -- color de marca para las máscaras

local function capa() return L.imagen(W, H) end
local function red(v) return math.floor(v + 0.5) end

local function mascara(img)
  local s = {}
  for y = 0, H - 1 do for x = 0, W - 1 do s[y * W + x] = L.opaco(img, x, y) end end
  return function(x, y) return x >= 0 and y >= 0 and x < W and y < H and s[y * W + x] end
end

---------------------------------------------------------------- formas
-- Miembro: cápsula con grosor distinto en cada extremo.
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

-- Tramo anatómico: polígono a lo largo de un hueso con perfil distinto por delante y por detrás.
-- delante / detras = { { t, separación }, ... } con t de 0 (origen) a 1 (extremo).
local function tramo(m, x0, y0, x1, y1, delante, detras)
  local dx, dy = x1 - x0, y1 - y0
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.01 then return end
  local nx, ny = dy / d, -dx / d            -- normal «hacia delante» (derecha si el hueso baja)
  local pts = {}
  for _, q in ipairs(delante) do pts[#pts + 1] = { x0 + dx * q[1] + nx * q[2], y0 + dy * q[1] + ny * q[2] } end
  for i = #detras, 1, -1 do
    local q = detras[i]
    pts[#pts + 1] = { x0 + dx * q[1] - nx * q[2], y0 + dy * q[1] - ny * q[2] }
  end
  L.poligono(m, pts, M)
end

---------------------------------------------------------------- luz
-- Volumen de una pieza estrecha: t = { borde, sombra, base, luz }.
-- Borde oscuro abajo y a la derecha (contorno selectivo), luz arriba y a la izquierda.
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

-- Volumen de una pieza ancha (torso caído): cilindro iluminado desde arriba a la izquierda.
-- Se mide la posición del píxel en el tramo más corto (fila o columna). r = rampa de 5 tonos.
local function volumenAncho(m, r)
  local op = mascara(m)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if op(x, y) then
      local x0, x1, y0, y1 = x, x, y, y
      while op(x0 - 1, y) do x0 = x0 - 1 end
      while op(x1 + 1, y) do x1 = x1 + 1 end
      while op(x, y0 - 1) do y0 = y0 - 1 end
      while op(x, y1 + 1) do y1 = y1 + 1 end
      local w, h = x1 - x0 + 1, y1 - y0 + 1
      local i, n
      if w <= h then i, n = x - x0, w else i, n = y - y0, h end
      local c
      if x == x1 or y == y1 then c = r[1]
      elseif y == y0 then c = (x - x0 < w * 0.6) and r[5] or r[4]
      elseif x == x0 then c = r[4]
      elseif i < n * 0.4 then c = r[4]
      elseif i < n * 0.8 then c = r[3]
      else c = r[2] end
      m:drawPixel(x, y, c)
    end
  end end
end

-- Volumen de una bota: suela oscura, empeine con luz, puntera con brillo.
local function volumenBota(m, t)
  local op = mascara(m)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if op(x, y) then
      local c = t[3]
      if not op(x, y + 1) then c = t[1]
      elseif not op(x + 1, y) then c = t[2]
      elseif not op(x, y - 1) then c = op(x - 1, y - 1) and t[4] or t[5]
      elseif not op(x - 1, y) then c = t[4]
      end
      m:drawPixel(x, y, c)
    end
  end end
end

---------------------------------------------------------------- esqueleto
-- Rodilla por cinemática inversa (dos huesos). La rodilla dobla hacia delante.
local MUSLO, TIBIA = 8.5, 7.5
local function rodilla(hx, hy, ax, ay, k)
  k = k or 1
  local l1, l2 = MUSLO * k, TIBIA * k
  local dx, dy = ax - hx, ay - hy
  local d = math.sqrt(dx * dx + dy * dy)
  local dd = math.min(d, l1 + l2 - 0.02)
  local a = (l1 * l1 - l2 * l2 + dd * dd) / (2 * dd)
  local h = math.sqrt(math.max(0, l1 * l1 - a * a))
  local ux, uy = dx / d, dy / d
  return hx + ux * a + uy * h, hy + uy * a - ux * h
end

---------------------------------------------------------------- piezas
local PIE = { { -1.6, -1.0 }, { 1.4, -1.0 }, { 2.8, 0.2 }, { 3.9, 1.1 }, { 3.9, 2.5 }, { -1.6, 2.5 } }

local function bota(img, kx, ky, ax, ay, ang, lejos)
  local m = capa()
  local dx, dy = kx - ax, ky - ay
  local d = math.sqrt(dx * dx + dy * dy)
  dx, dy = dx / d, dy / d
  miembro(m, ax + dx * 1.6, ay + dy * 1.6, ax, ay, 3.0, 3.0, M)
  local c, s = math.cos(ang), math.sin(ang)
  local pts = {}
  for _, p in ipairs(PIE) do
    pts[#pts + 1] = { ax + p[1] * c - p[2] * s, ay + p[1] * s + p[2] * c }
  end
  L.poligono(m, pts, M)
  volumenBota(m, lejos and { CU[1], CU[1], CU[2], CU[3], CU[3] } or { CU[1], CU[2], CU[3], CU[4], CU[5] })
  L.pegar(img, m, 0, 0)
end

-- Pierna: bota, y encima el pantalón (muslo + pantorrilla; la cercana lleva la pelvis).
-- pie = { x del tobillo, y del tobillo, ángulo del pie }
local function pierna(img, hx, hy, pie, lejos, pelvis)
  local ax, ay = pie[1], pie[2]
  local kx, ky = rodilla(hx, hy, ax, ay, pie[4])
  bota(img, kx, ky, ax, ay, pie[3] or 0, lejos)
  local m = capa()
  if pelvis then L.poligono(m, pelvis, M) end
  -- el bajo del pantalón queda 1 px por encima del tobillo
  local bx, by = ax + (kx - ax) / TIBIA * 1.0, ay + (ky - ay) / TIBIA * 1.0
  L.elipse(m, hx, hy, 2.3, 2.3, M)
  tramo(m, hx, hy, kx, ky, { { 0, 2.3 }, { 0.5, 2.4 }, { 1, 1.8 } }, { { 0, 2.4 }, { 0.5, 2.1 }, { 1, 1.7 } })
  L.elipse(m, kx, ky, 1.75, 1.75, M)
  tramo(m, kx, ky, bx, by, { { 0, 1.8 }, { 0.5, 1.5 }, { 1, 1.6 } }, { { 0, 1.7 }, { 0.3, 2.1 }, { 0.65, 1.8 }, { 1, 1.5 } })
  volumen(m, lejos and { CQ[1], CQ[2], CQ[2], CQ[3] } or { CQ[1], CQ[2], CQ[3], CQ[4] })
  if not lejos then
    -- pliegue de la corva: rompe la línea de luz por detrás de la rodilla
    local dx, dy = ax - hx, ay - hy
    local d = math.sqrt(dx * dx + dy * dy)
    local qx, qy = math.floor(kx - dy / d * 1.3), math.floor(ky + dx / d * 1.3)
    if L.opaco(m, qx, qy) and L.get(m, qx, qy) == CQ[4] then m:drawPixel(qx, qy, CQ[2]) end
  end
  L.pegar(img, m, 0, 0)
  return kx, ky
end

-- Brazo (solo en «morir»). Ángulos absolutos: 0 = hacia abajo, 90 = hacia delante, 180 = arriba.
local BRAZO, ANTEBRAZO = 5.5, 5.0
local function brazo(img, sx, sy, a1, a2, lejos, k)
  k = k or 1
  a1, a2 = math.rad(a1), math.rad(a2)
  local ex, ey = sx + math.sin(a1) * BRAZO * k, sy + math.cos(a1) * BRAZO * k
  local mx, my = ex + math.sin(a2) * ANTEBRAZO * k, ey + math.cos(a2) * ANTEBRAZO * k
  local hx, hy = mx + math.sin(a2) * 1.3, my + math.cos(a2) * 1.3
  local h = capa()
  L.elipse(h, hx, hy, 1.45, 1.45, M)
  volumen(h, lejos and { PI[1], PI[2], PI[2], PI[3] } or { PI[2], PI[3], PI[3], PI[4] })
  L.pegar(img, h, 0, 0)
  local m = capa()
  miembro(m, sx, sy, ex, ey, 3.7, 3.2, M)
  miembro(m, ex, ey, mx, my, 3.2, 2.7, M)
  volumen(m, lejos and { CH[1], CH[2], CH[2], CH[3] } or { CH[1], CH[2], CH[3], CH[4] })
  L.pegar(img, m, 0, 0)
end

-- Transformación del torso: (u, v) locales (u = delante, v = arriba) respecto a la cadera.
local function torsoT(p)
  local c, s = math.cos(p.incl or 0), math.sin(p.incl or 0)
  return function(u, v)
    if v > 3 then v = v + (p.sube or 0) end
    return p.cx + u * c + v * s, p.cy - v * c + u * s
  end
end

local TORSO = { { -3.5, -1.3 }, { -3.3, 2 }, { -3.6, 6 }, { -3.3, 8.5 }, { -2.3, 9.6 }, { -0.9, 10.0 },
  { 2.1, 9.9 }, { 4.05, 8.9 }, { 4.3, 6.5 }, { 3.7, 2.5 }, { 3.7, -1.3 } }
local PELVIS = { { -3.4, 1.5 }, { 3.6, 1.5 }, { 3.7, -1.2 }, { 1.0, -2.6 }, { -3.2, -1.6 } }
local MOCHILA_P = { { -2.6, 9.4 }, { -5.0, 9.6 }, { -6.3, 8.4 }, { -6.5, 4.0 }, { -5.6, 2.6 }, { -2.6, 2.6 } }

local function poli(T, pts)
  local r = {}
  for _, q in ipairs(pts) do
    local x, y = T(q[1], q[2])
    r[#r + 1] = { x, y }
  end
  return r
end

local MAPA = {
  h = PE[1], i = PE[2], j = PE[3], k = PE[4],
  a = PI[1], b = PI[2], c = PI[3], d = PI[4], e = PI[5],
  x = BARBA, X = BARBA2, o = TI[1],
  ["1"] = CU[1], ["2"] = CU[2], ["3"] = CU[3], ["4"] = CU[4], ["5"] = CU[5],
}
local CABEZAS = {
  A = {             -- erguida, mirando a la derecha
    ".jkj.",
    "ijjii",
    "hiida",
    "hicdd",
    ".hxdc",
    "..xxX",
  },
  B = {             -- echada hacia atrás unos 40º
    ".jkj..",
    "ijjda.",
    "hiiddd",
    "hicdxc",
    ".hhxx.",
    "..h...",
  },
  C = {             -- tendido boca arriba, coronilla a la izquierda
    "....d.",
    ".jkddc",
    "jjiadx",
    "iiicdx",
    "hiiix.",
    ".hhh..",
  },
}
local MOCHILA = {
  ".454",
  "4553",
  "4543",
  "4322",
  "4432",
  "3432",
  ".221",
}

-- Torso erguido pintado a mano (chaqueta sin brazos; columnas x = 16..23 y filas y = 10..21 de «quieto»).
-- Va colgado de la cadera y se cizalla fila a fila con la inclinación de la columna.
local TORSO_A = {
  "..3.....",
  ".Ss5542.",
  "335544s1",
  "335443s1",
  "33343231",
  "33322321",
  "34333321",
  "34333221",
  "3433321.",
  "4433321.",
  "4333221.",
  "2222111.",
}
local MAPA_T = { ["1"] = CH[1], ["2"] = CH[2], ["3"] = CH[3], ["4"] = CH[4], ["5"] = CH[5], s = CU[3], S = CU[4], t = TE[1] }

local function torsoErguido(img, p)
  local tg = math.tan(p.incl or 0)
  local ox, oy = p.cx - 19.5, p.cy - 20.7          -- desplazamiento respecto a «quieto»
  for r, fila in ipairs(TORSO_A) do
    local y = 10 + r - 1
    local dx = red((21.5 - (y + 0.5)) * tg + ox)
    local yy = y
    if y <= 16 then yy = y - (p.sube or 0) end
    for c = 1, #fila do
      local ch = fila:sub(c, c)
      if ch ~= "." then
        L.px(img, 16 + c - 1 + dx, red(yy + oy), MAPA_T[ch])
        if y == 16 and (p.sube or 0) > 0 then L.px(img, 16 + c - 1 + dx, red(y + oy), MAPA_T[ch]) end
      end
    end
  end
end

local function figura(img, p)
  local T = torsoT(p)
  local nhx, nhy = p.cx - 0.3, p.cy + (p.cercady or 0)
  local fhx, fhy = p.cx + 0.7 + (p.lejosdx or 0), p.cy + (p.lejosdy or 0)
  local sx, sy = T(0.5, 8.0)
  sx, sy = red(sx), red(sy)
  if not p.caido then
    -- articulación del hombro (centro del remate redondeado) sobre el torso cizallado
    local tg = math.tan(p.incl or 0)
    sx = 20 + red((21.5 - 13.5) * tg + p.cx - 19.5)
    sy = red(13 + p.cy - 20.7) - (p.sube or 0)
  end
  if p.fondo then p.fondo(img) end
  -- 1. brazo lejano, mochila caída y pierna lejana
  if p.brazoL and not p.brazoLencima then brazo(img, sx + 0.5 + (p.hlx or 0), sy - 0.5 + (p.hly or 0), p.brazoL[1], p.brazoL[2], true, p.brazoL[3]) end
  if p.caido then
    local m = capa()
    L.poligono(m, poli(T, MOCHILA_P), M)
    volumen(m, { CU[1], CU[2], CU[3], CU[4] })
    L.pegar(img, m, 0, 0)
  end
  pierna(img, fhx, fhy, p.lejos, true)
  -- 2. pelvis + pierna cercana
  pierna(img, nhx, nhy, p.cerca, false, poli(T, PELVIS))
  -- 3. cuello
  do
    local x0, y0 = T(0.3, 9.5)
    local x1, y1 = T(0.5, 11.6)
    L.grueso(img, x0, y0, x1, y1, 2.2, PI[2])
  end
  -- 4. torso
  if p.caido then
    local m = capa()
    L.poligono(m, poli(T, TORSO), M)
    volumenAncho(m, CH)
    L.pegar(img, m, 0, 0)
  else
    torsoErguido(img, p)
  end
  -- 5. mochila
  if not p.caido then
    local x, y = T(-6.5, 9.5)
    L.pintar(img, MOCHILA, red(x), red(y) + (p.mochila or 0), MAPA)
  end
  -- 6. cabeza
  do
    local x, y = T(-1.5, 17)
    x, y = red(x) + (p.cabx or 0), red(y) + (p.caby or 0)
    if p.cabpos then x, y = p.cabpos[1], p.cabpos[2] end
    L.pintar(img, CABEZAS[p.cabeza or "A"], x, y, MAPA)
  end
  -- 7. hombro (remate redondeado): en las poses erguidas ya va pintado en el torso
  if p.caido then
    L.pintar(img, {
      ".55.",
      "5544",
      "5443",
      ".43.",
    }, sx - 2, sy - 2, MAPA_T)
  end
  if p.brazoL and p.brazoLencima then brazo(img, sx + 0.5 + (p.hlx or 0), sy - 0.5 + (p.hly or 0), p.brazoL[1], p.brazoL[2], true, p.brazoL[3]) end
  if p.brazoC then brazo(img, sx + (p.hcx or 0), sy + (p.hcy or 0), p.brazoC[1], p.brazoC[2], false, p.brazoC[3]) end
  if p.retoque then p.retoque(img) end
  return sx, sy
end

---------------------------------------------------------------- poses
local fotos, hombros = {}, {}
local function foto(p)
  local img = L.imagen(W, H)
  local sx, sy = figura(img, p)
  fotos[#fotos + 1] = img
  hombros[#hombros + 1] = { sx, sy }
end

-- quieto: respiración (sube el pecho y la cabeza; la mochila llega un fotograma después)
local sube = { 0, 1, 1, 0 }
local moch = { 0, 0, -1, -1 }
for i = 1, 4 do
  foto({ cx = 19.5, cy = 20.7, sube = sube[i], mochila = moch[i],
    cerca = { 16.6, 36.5, 0 }, lejos = { 23.4, 36.5, 0 } })
end

-- correr: 8 fotogramas. Fases de una pierna: 0 contacto, 1 recepción, 2 paso, 3 impulso, 4-7 vuelo.
local bob = { 0, 1, 0, -1, 0, 1, 0, -1 }
local incl = { 12, 14, 12, 10, 12, 14, 12, 10 }
local FASE = {
  { 6.5, 36.15, -15 }, { 2.0, 36.5, 0 }, { -2.5, 36.5, 0 }, { -6.6, 34.5, 35 },
  { -9.5, 30.5, 65 }, { -7.5, 28, 85 }, { 0.5, 31, 30 }, { 7, 33, -20 },
}
for i = 1, 8 do
  local cx, cy = 19, 22 + bob[i]
  local function pie(f)
    local q = FASE[(f - 1) % 8 + 1]
    return { cx + q[1], q[2], math.rad(q[3]) }
  end
  local ant = bob[(i - 2) % 8 + 1]
  foto({ cx = cx, cy = cy, incl = math.rad(incl[i]), mochila = ant - bob[i],
    cerca = pie(i), lejos = pie(i + 4) })
end

-- morir: cae de espaldas sobre la mochila
local function charco(img)
  local m = capa()
  L.elipse(m, 11, 38.4, 9.5, 1.7, M)
  L.elipse(m, 19, 38.6, 6.5, 1.4, M)
  L.elipse(m, 4.5, 37.8, 3.4, 1.4, M)
  volumen(m, { SA[1], SA[2], SA[2], SA[3] })
  L.pegar(img, m, 0, 0)
end
-- 1 sacudida del impacto
foto({ cx = 19.2, cy = 21, incl = math.rad(-8), cerca = { 16.6, 36.5, 0 }, lejos = { 23.8, 35.9, math.rad(-10) },
  cabx = -1, brazoC = { 50, 140 }, brazoL = { -40, -10 } })
-- 2 se le doblan las rodillas
foto({ cx = 18.5, cy = 25.5, incl = math.rad(-18), cerca = { 16.6, 36.5, 0 }, lejos = { 23.4, 36.5, 0 },
  cabeza = "B", cabx = -1, brazoC = { 110, 150 }, brazoL = { 60, 120 } })
-- 3 cae de espaldas, las piernas salen hacia delante
foto({ cx = 18.5, cy = 31, incl = math.rad(-50), caido = true, cerca = { 31, 33.5, math.rad(-40) }, lejos = { 30.5, 29.5, math.rad(-60) },
  cabeza = "B", cabpos = { 5, 20 }, brazoC = { 150, 185 }, brazoL = { 120, 170 } })
-- 4 golpea el suelo
foto({ cx = 20.3, cy = 34.5, incl = math.rad(-86), caido = true, cerca = { 31.5, 30.5, math.rad(-50) }, lejos = { 30, 27.5, math.rad(-75) },
  lejosdy = -1.5, cabeza = "C", cabpos = { 3, 30 }, brazoC = { 230, 260 }, brazoL = { 200, 240 } })
-- 5 tendido
local function tendido(extra)
  local p = { cx = 20.3, cy = 34.3, incl = math.rad(-80), caido = true, cercady = 1.2, lejosdy = -1.5,
    cerca = { 35.6, 36.2, math.rad(-75) }, lejos = { 35.2, 30.4, math.rad(-100), 0.9 },
    cabeza = "C", cabpos = { 3, 31 }, brazoC = { 50, 85 }, hcy = 1, brazoL = { 100, -60 }, brazoLencima = true, hly = -2 }
  for k, v in pairs(extra or {}) do p[k] = v end
  return p
end
foto(tendido())
-- 6 con charco
foto(tendido({ fondo = charco }))


---------------------------------------------------------------- 8 direcciones
-- Vistas s (de frente), se (3/4 de frente), ne (3/4 de espaldas) y n (de espaldas).
-- Mismo personaje que la vista e: cabeza, torso y mochila pintados a mano por vista;
-- las piernas salen de un esqueleto por fases (el mismo ciclo que la vista e) y se pintan
-- con las mismas cápsulas y la misma luz. La luz viene siempre de arriba a la izquierda.
local fotosE, hombrosE = fotos, hombros

local MAPA8 = {
  h = PE[1], i = PE[2], j = PE[3], k = PE[4],
  a = PI[1], b = PI[2], c = PI[3], d = PI[4], e = PI[5],
  x = BARBA, X = BARBA2, o = TI[1], O = TI[2],
  ["1"] = CH[1], ["2"] = CH[2], ["3"] = CH[3], ["4"] = CH[4], ["5"] = CH[5],
  m = CU[1], n = CU[2], y = CU[3], z = CU[4], Z = CU[5],
  F = CQ[1], G = CQ[2], Q = CQ[3], R = CQ[4],
  u = TE[1], U = TI[3], s = CU[3], S = CU[4],
}

-- Pinta un mapa; las filas con y <= corte suben «sube» px (respiración del pecho).
local CIZ, CIZY = 0, 0        -- cizalla de la inclinación al correr (se, ne)
local function pintar8(img, filas, ox, oy, sube, corte)
  for r, fila in ipairs(filas) do
    local y = oy + r - 1
    local yy = y
    local ox = ox + red((21.5 + CIZY - y) * CIZ)
    if sube and sube ~= 0 and y <= corte then yy = y - sube end
    for c = 1, #fila do
      local ch = fila:sub(c, c)
      if ch ~= "." and ch ~= " " then
        local col = MAPA8[ch]
        if col == nil then error("carácter sin color: '" .. ch .. "'") end
        L.px(img, ox + c - 1, yy, col)
        if sube and sube > 0 and y == corte then L.px(img, ox + c - 1, y, col) end
      end
    end
  end
end

---------------------------------------------------------------- cabezas (filas y = 4..9)
local CAB8 = {
  s = {
    ".jkjh.",
    "ijjiih",
    "hadcah",
    "cddcbb",
    "xdXXbX",
    ".xxXX.",
  },
  se = {
    ".jkji.",
    "ijjidd",
    "hcdada",
    "hbxddc",
    ".xxXxX",
    "..xxX.",
  },
  ne = {
    ".jkj..",
    "ijjih.",
    "jiihhb",
    "iihhcb",
    ".hhhxX",
    "..ba..",
  },
  n = {
    ".jkjh.",
    "ijjiih",
    "jjiihh",
    "ciihhb",
    ".hhhh.",
    "..ba..",
  },
}

---------------------------------------------------------------- torsos (filas y = 10..21)
-- s/S correas de la mochila, z hebilla.
local TOR8 = {
  s = { x = 15,
    "..44ba32..",
    ".5S5443s2.",
    "45S4432s21",
    "44S4432s21",
    "44S4432s21",
    "34z4432z21",
    "3444332221",
    "3444332221",
    "3444332221",
    "3444332221",
    "3444332221",
    ".222122211",
  },
  se = { x = 15,
    "...4ba2..",
    ".55S443s.",
    "454S423s1",
    "444S423s1",
    "444S423s1",
    "344z423z1",
    "344442321",
    "344442321",
    "344442321",
    "344442321",
    "344442321",
    ".2221221.",
  },
  ne = { x = 16,
    "...4b2...",
    "..5543...",
    ".455432..",
    "44433221.",
    "44333221.",
    "43333221.",
    "43433221.",
    "43333221.",
    "43433221.",
    "43433211.",
    "33333221.",
    ".2222211.",
  },
  n = { x = 15,
    "...4ab3...",
    ".55443332.",
    "4554433321",
    "4443333321",
    "4433333221",
    "4433333221",
    "3433332221",
    "3433332221",
    "3433332221",
    "3433332211",
    "3433332221",
    ".222222211",
  },
}

---------------------------------------------------------------- mochilas
local MOCH8 = {
  n = { dx = 16, dy = 10,
    ".S....s.",
    ".SzZzys.",
    "zZZzzzyn",
    "zZzzzyyn",
    "zzyyyynm",
    "yzZZzyym",
    "yzyyyynm",
    "yzyyyynm",
    "yyyyynnm",
    ".nnnnmm.",
  },
  ne = { dx = 13, dy = 11,
    ".zZzy..",
    "zZzzyn.",
    "zzzyynm",
    "zyZzynm",
    "zyyyynm",
    "yyyyynm",
    "yyynnnm",
    ".nnnmm.",
  },
  se = { dx = 12, dy = 11,
    ".zZ",
    "zZz",
    "zzy",
    "zyy",
    "yyn",
    "yyn",
    ".nm",
  },
}

---------------------------------------------------------------- botas
local BOTA8 = {
  frente = {     -- de frente: caña, empeine y puntera con brillo
    "yzzy",
    "zZzn",
    "mnnm",
  },
  frenteG = {    -- más cerca de la cámara
    ".yzy.",
    "yzZzn",
    "zZzyn",
    "mnnnm",
  },
  punta = {      -- talón levantado: el pie se encoge
    "yzzn",
    "mnnm",
  },
  suela = {      -- de frente, pie echado atrás: se ve la suela bajo la espinilla
    "nyyn",
    "mOOm",
  },
  espalda = {    -- de espaldas: talón
    "nyyn",
    "yzyn",
    "mmmm",
  },
  espaldaP = {   -- lejos (pie adelantado hacia el norte)
    "nyyn",
    "mmmm",
  },
  talon = {      -- de espaldas, el talón empieza a subir
    "nyyn",
    "OOOm",
  },
  suelaG = {     -- de espaldas, pie echado atrás hacia la cámara: suela grande
    "nzyn",
    "mOOm",
    "mOOm",
  },
}

local function pintarBota(img, b, ax, base)
  local f = BOTA8[b]
  local w = #f[1]
  pintar8(img, f, red(ax - w / 2), base - #f + 1)
end

---------------------------------------------------------------- piernas
-- Pierna por puntos: cadera, rodilla y tobillo ya proyectados en pantalla.
local function piernaP(img, hx, hy, kx, ky, ax, ay, rampa, pelvis, gk)
  local m = capa()
  if pelvis then L.poligono(m, pelvis, M) end
  gk = gk or 1
  L.elipse(m, hx, hy, 2.3 * gk, 2.3, M)
  miembro(m, hx, hy, kx, ky, 4.5 * gk, 3.7 * gk, M)
  L.elipse(m, kx, ky, 1.8 * gk, 1.8, M)
  if ay - 1 > ky then miembro(m, kx, ky, ax, ay - 1, 3.6 * gk, 3.0 * gk, M) end
  volumen(m, rampa)
  L.pegar(img, m, 0, 0)
end

-- Fases de una pierna vista de frente (s) o de espaldas (n), relativas a la cadera:
-- { rodilla dy, tobillo dy (nil = apoyado, suela en la fila 38), bota, grosor (cerca > 1, lejos < 1), rodilla grande }
local FASE_S = {
  { 7.0, nil, "frente", 1.05 },        -- 0 contacto
  { 6.6, nil, "frente", 1.0 },         -- 1 recepción (rodilla doblada)
  { 7.2, nil, "frente", 1.0 },         -- 2 paso
  { 7.0, 13.6, "punta", 0.95 },        -- 3 impulso: talón arriba
  { 6.8, 8.8, "suela", 0.95 },         -- 4 vuelo: el pie se va atrás y enseña la suela
  { 6.0, 7.6, "suela", 0.95 },         -- 5 el pie más alto
  { 4.6, 12.6, "frenteG", 1.15, true },-- 6 la rodilla viene hacia la cámara
  { 6.2, 15.0, "frenteG", 1.12 },      -- 7 alcanza: más baja y más grande
}
local FASE_N = {
  { 6.8, nil, "espalda", 0.95 },       -- 0 contacto (el pie de delante, lejos)
  { 6.6, nil, "espalda", 1.0 },        -- 1 recepción
  { 7.2, nil, "espalda", 1.05 },       -- 2 paso
  { 7.2, 13.4, "talon", 1.08 },        -- 3 impulso: el talón sube hacia la cámara
  { 7.6, 10.6, "suelaG", 1.15 },       -- 4 vuelo: pie atrás, hacia la cámara
  { 7.0, 9.6, "suelaG", 1.12 },        -- 5
  { 3.0, 10.8, "espaldaP", 0.9 },      -- 6 la pierna pasa hacia delante (rodilla tapada)
  { 5.0, 12.8, "espaldaP", 0.9 },      -- 7 alcanza (lejos, más arriba)
}

local LUZ_I = { CQ[1], CQ[2], CQ[3], CQ[4] }
local LUZ_D = { CQ[1], CQ[2], CQ[3], CQ[3] }
local LUZ_L = { CQ[1], CQ[2], CQ[2], CQ[3] }

-- Piernas de frente o de espaldas. fi, fd = fases de la pierna izquierda y derecha de la pantalla.
local function piernasSN(img, tabla, hy, fi, fd, quieto)
  local lados = {
    { hx = 17.5, ax = quieto and 17.3 or 17.5, f = fi, rampa = LUZ_I, lado = -1 },
    { hx = 21.7, ax = quieto and 21.9 or 21.8, f = fd, rampa = LUZ_D, lado = 1 },
  }
  for _, l in ipairs(lados) do
    l.q = quieto and { 7.4, nil, tabla == FASE_S and "frente" or "espalda", 1.0 } or tabla[l.f + 1]
  end
  -- la más cercana a la cámara se pinta la última (y lleva la pelvis)
  table.sort(lados, function(a, b)
    if a.q[4] ~= b.q[4] then return a.q[4] < b.q[4] end
    return a.hx > b.hx
  end)
  local pelvis = { { 15.6, hy - 1.3 }, { 23.4, hy - 1.3 }, { 23.4, hy + 1.6 }, { 19.6, hy + 2.6 }, { 15.6, hy + 1.6 } }
  for n, l in ipairs(lados) do
    local q = l.q
    local ay = q[2] and (hy + q[2]) or 36.5
    local ky = hy + q[1]
    local gk = q[4]
    local kx = (l.hx + l.ax) / 2 + l.lado * 0.3
    local m = capa()
    if n == 2 then L.poligono(m, pelvis, M) end
    L.elipse(m, l.hx, hy, 2.3 * gk, 2.3, M)
    miembro(m, l.hx, hy, kx, ky, 4.4 * gk, 3.8 * gk, M)
    local rk = q[5] and 2.2 or 1.8
    L.elipse(m, kx, ky, rk * gk, rk, M)
    if q[3] == "suela" or q[3] == "suelaG" then
      -- espinilla encogida: el pie va hacia atrás (s) o hacia la cámara (n)
      miembro(m, kx, ky, l.ax, ay, 3.6 * gk, 3.2 * gk, M)
    elseif ay - 1 > ky then
      miembro(m, kx, ky, l.ax, ay - 1, 3.6 * gk, 3.0 * gk, M)
    end
    volumen(m, gk < 1 and LUZ_L or l.rampa)
    L.pegar(img, m, 0, 0)
    local base = red(ay + 1.5)
    if q[3] == "suela" or q[3] == "suelaG" then base = red(ay) + #BOTA8[q[3]] end
    pintarBota(img, q[3], l.ax, base)
  end
end

---------------------------------------------------------------- piernas en 3/4 (se, ne)
-- Se usa el ciclo de la vista e (FASE) y se proyecta: lo que va «hacia delante» se encoge en x
-- y se desplaza en y (hacia la cámara en se, alejándose en ne). Los pies apoyados no se mueven de la fila.
local function piernas34(img, vista, cx, hy, fn, ff, quieto)
  local fx = 0.62
  local fy = vista == "se" and 0.30 or -0.30
  local cercaDx = vista == "se" and -1.6 or 1.6     -- pierna derecha del personaje (más cerca de la cámara)
  local orden = {
    { dx = -cercaDx, f = ff, lejos = true },
    { dx = cercaDx, f = fn, lejos = false },
  }
  local pelvis
  do
    local a = fy * 2
    pelvis = { { cx - 3.4, hy - 1.4 + a }, { cx + 3.6, hy - 1.4 - a }, { cx + 3.6, hy + 1.4 - a }, { cx, hy + 2.5 }, { cx - 3.4, hy + 1.4 + a } }
  end
  for n, o in ipairs(orden) do
    local hx = cx + o.dx
    local hyy = hy + (o.lejos and -0.4 or 0.4)
    local q
    if quieto then q = o.lejos and { 1.4, 36.5, 0 } or { -1.0, 36.5, 0 }
    else q = FASE[(o.f) % 8 + 1] end
    local fwd, ay0, ang = q[1], q[2], math.rad(q[3])
    if quieto then ang = 0 end
    -- rodilla en el plano de la pierna (sin proyectar)
    local kx0, ky0 = rodilla(0, hyy, fwd, ay0)
    local planted = ay0 >= 36.0
    local ax = hx + fwd * fx
    local ay = planted and 36.5 or math.min(37.2, ay0 + fwd * fy)
    local kx = hx + kx0 * fx
    local ky = ky0 + kx0 * fy
    -- bota: el perfil de la vista e, encogido en x y girado hacia la cámara
    local m = capa()
    local dx, dy = kx - ax, ky - ay
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 0.01 then
      miembro(m, ax + dx / d * 1.6, ay + dy / d * 1.6, ax, ay, 3.0, 3.0, M)
    end
    local c, s = math.cos(ang), math.sin(ang)
    local pts = {}
    local sx = vista == "se" and 1 or 1
    for _, p in ipairs(PIE) do
      local u, v = p[1] * c - p[2] * s, p[1] * s + p[2] * c
      pts[#pts + 1] = { ax + u * 0.75 * sx, ay + v + u * fy * 0.9 }
    end
    L.poligono(m, pts, M)
    -- ancho del pie hacia el lado
    local pts2 = {}
    for _, p in ipairs(pts) do pts2[#pts2 + 1] = { p[1] - 1, p[2] + (vista == "se" and 0.4 or -0.4) } end
    L.poligono(m, pts2, M)
    volumenBota(m, o.lejos and { CU[1], CU[1], CU[2], CU[3], CU[3] } or { CU[1], CU[2], CU[3], CU[4], CU[5] })
    if vista == "ne" and not planted and fwd < 0 then
      -- de espaldas, el pie echado atrás enseña la suela
      for yy = 0, H - 1 do for xx = 0, W - 1 do
        if L.opaco(m, xx, yy) and xx < ax then m:drawPixel(xx, yy, CU[1]) end
      end end
    end
    -- la suela nunca baja de la fila 38
    local baja = 0
    for yy = H - 1, 0, -1 do
      local hay = false
      for xx = 0, W - 1 do if L.opaco(m, xx, yy) then hay = true; break end end
      if hay then baja = math.max(0, yy - 38); break end
    end
    L.pegar(img, m, 0, -baja)
    piernaP(img, hx, hyy, kx, ky, ax, ay, o.lejos and { CQ[1], CQ[2], CQ[2], CQ[3] } or LUZ_I, n == 2 and pelvis or nil)
  end
end

---------------------------------------------------------------- figura por vista
local HOMBRO8 = { s = { 20, 13 }, n = { 20, 13 }, se = { 18, 13 }, ne = { 22, 13 } }

-- p = { vista, dy (desplazamiento del cuerpo), sube (pecho), moch (mochila), fi, fd (fases), quieto }
local function figura8(img, p)
  local v = p.vista
  local dy, sube = p.dy or 0, p.sube or 0
  local hy = 21.2 + dy
  CIZ, CIZY = (not p.quieto and (v == "se" or v == "ne")) and 0.13 or 0, dy
  local bx = p.bx or 0
  local delante = (v == "n" or v == "ne")
  -- mochila detrás del cuerpo (s y se)
  if v == "se" then
    local mo = MOCH8.se
    pintar8(img, mo, mo.dx, mo.dy + dy + (p.moch or 0) - sube)
  end
  -- piernas
  if v == "s" or v == "n" then
    piernasSN(img, v == "s" and FASE_S or FASE_N, hy, p.fi, p.fd, p.quieto)
  else
    piernas34(img, v, 19.6, hy, p.fi, p.fd, p.quieto)
  end
  -- torso
  local t = TOR8[v]
  pintar8(img, t, t.x + bx, 10 + dy, sube, 16 + dy)
  -- mochila a la espalda (n, ne)
  if delante then
    local mo = MOCH8[v]
    pintar8(img, mo, mo.dx + bx, mo.dy + dy + (p.moch or 0) - sube)
  end
  -- cabeza
  local cab = CAB8[v]
  local cx = (v == "ne") and 17 or ((v == "se") and 18 or 17)
  pintar8(img, cab, cx + bx, 4 + dy - sube + (p.caby or 0))
  local hb = HOMBRO8[v]
  local hx = hb[1] + red((21.5 - 13) * CIZ) + bx
  CIZ = 0
  return hx, hb[2] + dy - sube
end

local vistas = {}
for _, v in ipairs({ "s", "se", "ne", "n" }) do
  local q, c, hq, hc = {}, {}, {}, {}
  for i = 1, 4 do
    local img = L.imagen(W, H)
    local x, y = figura8(img, { vista = v, sube = sube[i], moch = moch[i], quieto = true, fi = 1, fd = 1 })
    q[i] = img; hq[i] = { x, y }
  end
  for i = 1, 8 do
    local img = L.imagen(W, H)
    local ant = bob[(i - 2) % 8 + 1]
    local x, y = figura8(img, { vista = v, dy = 1 + bob[i], moch = ant - bob[i], fi = (i - 1) % 8, fd = (i + 3) % 8,
      bx = (v == "s" or v == "n") and (i >= 5 and 1 or 0) or 0 })
    c[i] = img; hc[i] = { x, y }
  end
  vistas[v] = { q = q, c = c, hq = hq, hc = hc }
end
vistas.e = { q = {}, c = {}, hq = {}, hc = {} }
for i = 1, 4 do vistas.e.q[i] = fotosE[i]; vistas.e.hq[i] = hombrosE[i] end
for i = 1, 8 do vistas.e.c[i] = fotosE[4 + i]; vistas.e.hc[i] = hombrosE[4 + i] end

local fotos8, hombros8, etiquetas, dur = {}, {}, {}, {}
local function anadir(nombre, lista, hs, d)
  local desde = #fotos8 + 1
  for i, f in ipairs(lista) do
    fotos8[#fotos8 + 1] = f; hombros8[#hombros8 + 1] = hs[i]
    dur[#dur + 1] = type(d) == "table" and d[i] or d
  end
  etiquetas[#etiquetas + 1] = { nombre, desde, #fotos8 }
end
for _, v in ipairs({ "s", "se", "e", "ne", "n" }) do anadir("quieto_" .. v, vistas[v].q, vistas[v].hq, 0.22) end
for _, v in ipairs({ "s", "se", "e", "ne", "n" }) do anadir("correr_" .. v, vistas[v].c, vistas[v].hc, 0.075) end
do
  local mf, mh = {}, {}
  for i = 1, 6 do mf[i] = fotosE[12 + i]; mh[i] = hombrosE[12 + i] end
  anadir("morir", mf, mh, { 0.09, 0.09, 0.11, 0.13, 0.16, 1.0 })
end

L.construir("jugador", W, H, fotos8, etiquetas, dur, { pies = { 20, 38 }, hombro = hombros8 })
