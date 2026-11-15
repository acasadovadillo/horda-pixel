-- Corredor de Horda Pixel: zombi rápido, demacrado y pálido, camiseta de tirantes sucia,
-- pantalón oscuro hecho jirones, descalzo. Esprinta encorvado ~35° con los brazos atrás.
-- Se dibuja con un esqueleto (cadera, torso, cuello, miembros con ángulos) y cápsulas
-- sombreadas con luz de arriba a la izquierda; la cabeza es una pieza a mano.
-- Lienzo 40x40, suelas en y = 38, cuerpo centrado en x = 20.
-- 8 direcciones: el perfil e es el dibujo de siempre; s, se, ne y n salen del mismo esqueleto
-- montado en 3D (ver "vistas s, se, ne, n" más abajo). morir es una sola.
local L = dofile(app.params.lib)

---------------------------------------------------------------- colores
local PA = L.rampa("palido")                                   -- piel
local TA = { L.hex("2e2a21"), L.hex("4a4535"), L.hex("686049"), L.hex("877d61"), L.hex("a39878") } -- tirantes sucios
local PN = { L.hex("17171c"), L.hex("25252c"), L.hex("35353e"), L.hex("4a4954") }                  -- pantalón
local SA, CA, TI, PE = L.rampa("sangre"), L.rampa("carne"), L.rampa("tinta"), L.rampa("pelo")
local OJO = L.hex("d6d9c6")
local CUENCA = L.hex("1c1f1c")

-- Contorno selectivo (como los zombis lentos): solo se perfila lo claro.
local OSCURO, BORDE, MASOSC = {}, {}, {}
local function registrar(rampa, nOscuros, borde)
  for i, c in ipairs(rampa) do
    BORDE[c] = borde or rampa[1]
    if i <= nOscuros then OSCURO[c] = true end
    MASOSC[c] = rampa[math.max(1, i - 1)]
  end
end
registrar(PA, 1); registrar(TA, 1); registrar(PN, 2, PN[1]); registrar(SA, 3); registrar(CA, 2, SA[1])
registrar(TI, 3); registrar(PE, 4, TI[1])
BORDE[OJO] = PA[1]; OSCURO[CUENCA] = true; BORDE[CUENCA] = PA[1]; MASOSC[OJO] = PA[3]; MASOSC[CUENCA] = CUENCA

local function contorno(img, ymax)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = img:getPixel(x, y) end end
  local function claro(x, y)
    if x < 0 or y < 0 or x >= w or y >= h then return nil end
    local c = s[y * w + x]
    if L.alfa(c) == 0 or OSCURO[c] then return nil end
    return BORDE[c] or TI[2]
  end
  for y = 0, math.min(h - 1, ymax or (h - 1)) do for x = 0, w - 1 do
    if L.alfa(s[y * w + x]) == 0 then
      local b = claro(x, y + 1) or claro(x + 1, y) or claro(x - 1, y) or claro(x, y - 1)
      if b then img:drawPixel(x, y, b) end
    end
  end end
end

---------------------------------------------------------------- utilidades
local floor, sqrt, sin, cos, rad = math.floor, math.sqrt, math.sin, math.cos, math.rad
local function hash(a, b) local v = sin(a * 12.9898 + b * 78.233) * 43758.5453; return v - floor(v) end
-- punto a distancia len desde (x, y) con ángulo absoluto (0 = hacia abajo, 90 = hacia la derecha)
local function pt(x, y, ang, len) return x + sin(rad(ang)) * len, y + cos(rad(ang)) * len end

local function tono(r, base, luz)
  local i = base
  if luz > 0.3 then i = base + 1 elseif luz < -0.12 then i = base - 1 end
  if luz < -0.75 then i = base - 2 end
  return r[math.max(1, math.min(#r, i))]
end

-- Cápsula ahusada sombreada. f(t, lado, luz, x, y) -> color o nil.
-- t: 0 en A, 1 en B. lado: perpendicular con signo (positivo = a la derecha del sentido A->B, girado).
local function capsula(img, ax, ay, bx, by, ra, rb, f)
  local dx, dy = bx - ax, by - ay
  local l2 = dx * dx + dy * dy
  local len = sqrt(l2)
  local ux, uy = 0, 1
  if len > 0 then ux, uy = dx / len, dy / len end
  local nx, ny = -uy, ux
  local rm = math.max(ra, rb)
  for y = floor(math.min(ay, by) - rm - 1), math.ceil(math.max(ay, by) + rm + 1) do
    for x = floor(math.min(ax, bx) - rm - 1), math.ceil(math.max(ax, bx) + rm + 1) do
      local cx, cy = x + 0.5, y + 0.5
      local t = 0
      if l2 > 0 then t = math.max(0, math.min(1, ((cx - ax) * dx + (cy - ay) * dy) / l2)) end
      local qx, qy = ax + dx * t, ay + dy * t
      local r = ra + (rb - ra) * t
      local ox, oy = cx - qx, cy - qy
      if ox * ox + oy * oy <= r * r then
        local luz = -(ox + oy) * 0.7071 / r
        local lado = (ox * nx + oy * ny) / r
        local c = f(t, lado, luz, x, y)
        if c and x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
      end
    end
  end
end

-- Oscurece lo ya pintado bajo una cápsula (sombra de oclusión).
local function sombra(img, ax, ay, bx, by, r)
  capsula(img, ax, ay, bx, by, r, r, function(_, _, _, x, y)
    local c = L.get(img, x, y)
    if L.alfa(c) > 0 then return MASOSC[c] or c end
    return nil
  end)
end

---------------------------------------------------------------- cabezas (piezas a mano)
local MH = {
  ["1"] = PA[1], ["2"] = PA[2], ["3"] = PA[3], ["4"] = PA[4], ["5"] = PA[5],
  h = PE[1], i = PE[2], e = CUENCA, o = OJO,
  s = SA[1], S = SA[2], B = SA[3], X = SA[4], T = TI[1],
}
local function pieza(nombre, ancho, filas) L.comprobar(nombre, filas, ancho); return filas end
-- calva con mechones largos detrás, cuenca hundida, boca abierta. ancla del cuello (2, 5)
local CABEZA = { ax = 2, ay = 5, f = pieza("cabeza", 7, {
  "..444..",
  ".34454.",
  "h33444.",
  "h32eo4.",
  "hi2234X",
  ".h22sB.",
  "...2B..",
}) }
local CABEZA_AB = { ax = 2, ay = 5, f = pieza("cabeza_ab", 7, {
  "..445..",
  ".34554.",
  "h33445.",
  "h33eo4.",
  "hi2334.",
  ".h22sTX",
  "...2sB.",
  "....2B.",
}) }
-- echada atrás por el disparo (cara hacia arriba)
local CABEZA_ATRAS = { ax = 3, ay = 5, f = pieza("cabeza_atras", 7, {
  "...4o..",
  "..44e4X",
  ".3345sB",
  "h33442.",
  "hi332..",
  ".h22...",
}) }
-- de bruces, vista desde la nuca. ancla (0, 3)
local CABEZA_SUELO = { ax = 0, ay = 3, f = pieza("cabeza_suelo", 6, {
  ".hii..",
  "h3445.",
  "i34554",
  "233443",
  ".2232S",
  "..22BB",
}) }

---------------------------------------------------------------- partes
local function piel(base) return function(_, _, luz) return tono(PA, base, luz) end end

local function pierna(img, hx, hy, Lg, cerca)
  local kx, ky = pt(hx, hy, Lg[1], 8.5)
  local ax, ay = pt(kx, ky, Lg[2], 8.5)
  local fx, fy = pt(ax, ay, Lg[3], 2.6)
  local b = cerca and 4 or 3
  local pb = cerca and 4 or 3
  -- pie descalzo
  capsula(img, ax, ay, fx, fy, 0.95, 0.8, function(t, lado, luz)
    if t > 0.8 then return PA[2] end
    return tono(PA, cerca and 3 or 2, luz)
  end)
  -- espinilla: pantalón roto, jirón irregular
  local corte = cerca and 0.62 or 0.9
  capsula(img, kx, ky, ax, ay, 1.35, 1.05, function(t, lado, luz, x, y)
    local c = corte + (hash(x, y) - 0.5) * 0.22
    if t > c then return tono(PA, pb, luz) end
    return tono(PN, b, luz)
  end)
  -- muslo con desgarrón
  capsula(img, hx, hy, kx, ky, 1.9, 1.5, function(t, lado, luz)
    if cerca and t > 0.45 and t < 0.68 and lado < -0.15 then
      if t > 0.5 and t < 0.62 then return tono(PA, 3, luz) end
      return PN[1]
    end
    return tono(PN, b, luz)
  end)
  return kx, ky, ax, ay
end

local function brazo(img, sx, sy, A, cerca)
  local ex, ey = pt(sx, sy, A[1], 6.5)
  local wx, wy = pt(ex, ey, A[2], 6)
  local hx2, hy2 = pt(wx, wy, A[3], 2.2)
  local b = cerca and 4 or 3
  capsula(img, sx, sy, ex, ey, 1.3, 1.0, piel(b))
  capsula(img, ex, ey, wx, wy, 1.05, 0.95, function(t, lado, luz, x, y)
    if cerca and t > 0.3 and t < 0.55 and lado > 0.1 then return CA[2] end -- mordisco
    return tono(PA, b, luz)
  end)
  capsula(img, wx, wy, hx2, hy2, 0.95, 0.75, piel(b - 1))
  -- dedos en garra
  local gx, gy = pt(hx2, hy2, A[3] + 35, 1.3)
  L.px(img, floor(gx), floor(gy), PA[b - 2])
  return ex, ey, wx, wy, hx2, hy2
end

local function torso(img, hx, hy, ang, len, g)
  g = g or 1
  local sx, sy = pt(hx, hy, ang, len)
  -- pelvis (cintura del pantalón)
  local px2, py2 = pt(hx, hy, ang, 2.5)
  capsula(img, hx, hy, px2, py2, 2.3 * g, 2.3 * g, function(_, _, luz) return tono(PN, 3, luz) end)
  -- tronco: camiseta de tirantes, agujero con costillas, hombro desnudo
  capsula(img, px2, py2, sx, sy, 2.3 * g, 2.7 * g, function(t, lado, luz, x, y)
    local tl = t * (len - 2.5)
    if t > 0.9 then
      if lado < 0.1 and lado > -0.6 then return tono(TA, 3, luz) end   -- tirante
      return tono(PA, 4, luz)
    end
    if t > 0.8 and lado > 0.35 then return tono(PA, 4, luz) end        -- escote
    if t > 0.84 and lado < -0.6 then return tono(PA, 4, luz) end       -- espalda
    if t > 0.3 and t < 0.66 and lado > -0.05 + hash(floor(tl), 5) * 0.2 then -- roto: costillas
      if floor(tl) % 2 == 0 then return PA[2] end
      return tono(PA, 4, luz)
    end
    if t < 0.12 + hash(x, 3) * 0.1 then return tono(TA, 2, luz) end         -- bajo sucio
    local c = tono(TA, 3, luz)
    if hash(x * 3, y * 7) > 0.86 then c = MASOSC[c] end                     -- mugre
    if t > 0.55 and t < 0.75 and lado > 0.0 and hash(x, y * 2) > 0.45 then c = SA[2] end -- sangre seca
    return c
  end)
  return sx, sy
end

local function cabeza(img, P, nx, ny)
  local H = P.cabeza or CABEZA
  local ox, oy = floor(nx + 0.5) - H.ax, floor(ny + 0.5) - H.ay
  L.pintar(img, H.f, ox, oy, MH)
end

---------------------------------------------------------------- figura
-- P: hx, hy, torso (ángulo), cuello (ángulo), pN/pF (muslo, espinilla, pie), bN/bF (brazo, antebrazo, mano)
local function figura(img, P, oy)
  local hx, hy = P.hx, P.hy + oy
  local tl = P.largo or 10.5
  local sx, sy = pt(hx, hy, P.torso, tl)
  -- lado lejano: un poco más arriba y atrás
  brazo(img, sx + 0.6, sy - 0.8, P.bF, false)
  pierna(img, hx + 0.8, hy - 0.6, P.pF, false)
  torso(img, hx, hy, P.torso, tl, P.grueso)
  -- cuello flaco
  local nx, ny = pt(sx, sy, P.cuello or 125, 3)
  capsula(img, sx, sy, nx, ny, 1.05, 0.95, piel(3))
  -- sombra bajo la barbilla y de la pierna cercana sobre la pelvis
  pierna(img, hx - 0.3, hy + 0.2, P.pN, true)
  cabeza(img, P, nx, ny)
  -- brazo cercano con su sombra sobre el tronco
  local ex, ey = pt(sx, sy, P.bN[1], 6.5)
  sombra(img, sx + 0.8, sy + 0.9, ex + 0.8, ey + 0.9, 1.2)
  brazo(img, sx - 0.4, sy + 0.4, P.bN, true)
end

local function fondo(img)
  local b = -1
  for y = img.height - 1, 0, -1 do
    for x = 0, img.width - 1 do if L.alfa(img:getPixel(x, y)) > 0 then b = y; break end end
    if b >= 0 then break end
  end
  return b
end

-- Dibuja la pose. Con P.suelo, la apoya en y = 38 (menos P.alto en el aire).
local POSES = {}  -- poses del perfil e: las vistas nuevas reutilizan sus ángulos
local function pose(P, antes, despues)
  POSES[#POSES + 1] = P
  return function(img)
    local tmp = L.imagen(40, 64)
    figura(tmp, P, 12)
    local dy = -12
    if P.suelo then dy = (38 - (P.alto or 0)) - fondo(tmp) end
    if antes then antes(img) end
    L.pegar(img, tmp, 0, dy)
    contorno(img, P.suelo and 38 or 39)
    if despues then despues(img) end
  end
end

---------------------------------------------------------------- andar (esprint)
-- Pierna A (cercana): muslo, espinilla, pie (ángulos absolutos, 0 = abajo, + = adelante)
local PA_C = {
  { 30, 8, 96 },     -- contacto
  { 14, -16, 90 },   -- carga
  { -2, -22, 88 },   -- apoyo medio
  { -24, -30, 58 },  -- impulso
  { -30, -78, 14 },  -- patada atrás
  { -4, -108, -18 }, -- recogida
  { 40, -38, 45 },   -- rodilla arriba
  { 46, -4, 80 },    -- alcance
}
local ALTO = { 0, 0, 0, 1, 0, 0, 0, 1 }
local cuadros = {}
for i = 1, 8 do
  local A = PA_C[i]
  local B = PA_C[(i + 3) % 8 + 1]
  local ph = (i - 1.6) / 8 * 2 * math.pi
  local uN = -48 - 13 * cos(ph)
  local uF = -48 + 13 * cos(ph)
  cuadros[#cuadros + 1] = pose({
    suelo = true, alto = ALTO[i],
    hx = 17, hy = 21, torso = 145 + ((i % 4 == 2) and -2 or 0), cuello = 118 + ((i % 4 == 3) and 6 or 0),
    pN = A, pF = B,
    bN = { uN, uN - 32, uN - 15 }, bF = { uF, uF - 32, uF - 15 },
  })
end

---------------------------------------------------------------- atacar (embestida)
cuadros[#cuadros + 1] = pose({ -- 1: se agacha, brazos muy atrás
  suelo = true, hx = 16, hy = 22, torso = 125, cuello = 105,
  pN = { 42, -28, 85 }, pF = { -18, -42, 50 },
  bN = { -72, -95, -110 }, bF = { -62, -88, -100 },
})
cuadros[#cuadros + 1] = pose({ -- 2: golpe: salta con las garras al frente
  suelo = true, alto = 2, hx = 14, hy = 21, torso = 112, cuello = 100, cabeza = CABEZA_AB,
  pN = { 58, 12, 95 }, pF = { -42, -62, 10 },
  bN = { 108, 78, 55 }, bF = { 122, 92, 70 },
})
cuadros[#cuadros + 1] = pose({ -- 3: sigue el zarpazo hacia abajo, aterriza
  suelo = true, hx = 20, hy = 22, torso = 122, cuello = 108, cabeza = CABEZA_AB,
  pN = { 32, 6, 92 }, pF = { -30, -55, 25 },
  bN = { 55, 25, 15 }, bF = { 70, 40, 30 },
})
cuadros[#cuadros + 1] = pose({ -- 4: se recupera
  suelo = true, hx = 18, hy = 21, torso = 140, cuello = 118,
  pN = PA_C[2], pF = PA_C[6],
  bN = { -20, -45, -60 }, bF = { -35, -60, -75 },
})

---------------------------------------------------------------- morir (de bruces)
local function salpica(img)
  local m = { { 11, 6, SA[4] }, { 12, 7, SA[3] }, { 10, 8, SA[3] }, { 9, 6, SA[4] }, { 8, 9, SA[2] }, { 13, 5, SA[3] } }
  for _, p in ipairs(m) do L.px(img, p[1], p[2], p[3]) end
end
local function charco(img)
  local r = L.azar(7)
  L.elipse(img, 31, 37.4, 8.5, 2.2, SA[2])
  L.elipse(img, 26, 37.8, 5, 1.6, SA[2])
  L.elipse(img, 31.5, 37.2, 6, 1.5, SA[3])
  L.elipse(img, 33, 37, 2.5, 0.8, SA[4])
  for _ = 1, 6 do L.px(img, 22 + floor(r() * 18), 39, SA[1 + floor(r() * 2)]) end
end
local TENDIDO = function(bote, cab)
  return {
    hx = 15, hy = 34.5 - bote, torso = 90, grueso = 1.25, largo = 10.5, cuello = 96 - bote * 6, cabeza = cab or CABEZA_SUELO,
    pN = { -84 + bote * 6, -100 + bote * 10, -10 }, pF = { -92 + bote * 4, -90 + bote * 8, 0 },
    bN = { -84, -96, -100 }, bF = { 70 - bote * 10, 105, 120 },
  }
end
cuadros[#cuadros + 1] = pose({ -- 1: impacto: se yergue, cabeza atrás
  suelo = true, hx = 17, hy = 21, torso = 162, cuello = 150, cabeza = CABEZA_ATRAS,
  pN = PA_C[1], pF = PA_C[5],
  bN = { -20, 10, 30 }, bF = { -35, -5, 15 },
}, nil, salpica)
cuadros[#cuadros + 1] = pose({ -- 2: tropieza hacia delante, se le doblan las rodillas
  suelo = true, hx = 19, hy = 22, torso = 128, cuello = 112,
  pN = { 38, -22, 80 }, pF = { -12, -58, 30 },
  bN = { 25, 15, 10 }, bF = { 10, 0, -5 },
})
cuadros[#cuadros + 1] = pose({ -- 3: cae de bruces
  hx = 17, hy = 29, torso = 104, cuello = 100,
  pN = { -40, -70, -10 }, pF = { -55, -50, 0 },
  bN = { 75, 85, 95 }, bF = { 60, 70, 80 },
})
local T4 = TENDIDO(2); T4.hy = 33.5
cuadros[#cuadros + 1] = pose(T4)     -- 4: golpea el suelo, rebota
cuadros[#cuadros + 1] = pose(TENDIDO(0)) -- 5: tendido
cuadros[#cuadros + 1] = pose(TENDIDO(0), charco) -- 6: charco

---------------------------------------------------------------- vistas s, se, ne, n (3D)
-- El mismo esqueleto del perfil (ángulos de POSES) se monta en 3D y se proyecta con cámara
-- ortográfica 3/4 desde el sur. Cada pieza es un elipsoide (o una cadena de esferas) con
-- búfer de profundidad y normal real: la luz viene siempre de arriba a la izquierda de la pantalla.
local ELEV = rad(24)
local CE, SEL = cos(ELEV), sin(ELEV)
local LX, LY, LD = -0.62, -0.66, -0.42          -- hacia la luz, en ejes de cámara (x der, y abajo, d adentro)
do local n = sqrt(LX * LX + LY * LY + LD * LD); LX, LY, LD = LX / n, LY / n, LD / n end

local V = {}                                     -- vista actual
local W3, H3 = 40, 64
local ZB, CB, IB = {}, {}, {}
local function vista(phi, ox, oy)
  V.fx, V.fy = cos(rad(phi)), sin(rad(phi))
  V.rx, V.ry = sin(rad(phi)), -cos(rad(phi))
  V.ox, V.oy = ox, oy
  for k = 0, W3 * H3 - 1 do ZB[k] = 1e9; CB[k] = nil; IB[k] = 0 end
end
local function proy(p)
  local wx = p[1] * V.fx + p[2] * V.rx
  local wy = p[1] * V.fy + p[2] * V.ry
  return V.ox + wx, V.oy - (p[3] * CE + wy * SEL), wy * CE - p[3] * SEL
end
local function dcam(v)
  local wx = v[1] * V.fx + v[2] * V.rx
  local wy = v[1] * V.fy + v[2] * V.ry
  return wx, -(v[3] * CE + wy * SEL), wy * CE - v[3] * SEL
end
local function dloc(x, y, d)
  local wy, wz = -y * SEL + d * CE, -y * CE - d * SEL
  return x * V.fx + wy * V.fy, x * V.rx + wy * V.ry, wz
end
local function suma(p, d, k) return { p[1] + d[1] * k, p[2] + d[2] * k, p[3] + d[3] * k } end
local function dif(a, b) return { a[1] - b[1], a[2] - b[2], a[3] - b[3] } end
local function pp(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
-- dirección local desde un ángulo sagital (0 = abajo, 90 = adelante) y una abertura lateral
local function dir(a, b, lado)
  local ca, sa, cb, sb = cos(rad(a)), sin(rad(a)), cos(rad(b or 0)), sin(rad(b or 0))
  return { sa * cb, (lado or 1) * sb, -ca * cb }
end

local I = { p = { 0, 0, 0 }, n = { 0, 0, 0 } }   -- datos del fragmento para los materiales
local function escribir(x, y, depth, id, mat)
  if x < 0 or y < 0 or x >= W3 or y >= H3 then return end
  local k = y * W3 + x
  if depth >= ZB[k] then return end
  I.x, I.y = x, y
  local c = mat(I)
  if c then ZB[k] = depth; CB[k] = c; IB[k] = id end
end

-- Elipsoide de centro c (local), ejes locales e1, e2, e3 y radios r1, r2, r3.
local function elipsoide(id, c, e, r, mat, info)
  local cx, cy, cd = proy(c)
  local E = {}
  for i = 1, 3 do local x, y, d = dcam(e[i]); E[i] = { x / r[i], y / r[i], d / r[i] } end
  local A = E[1][3] ^ 2 + E[2][3] ^ 2 + E[3][3] ^ 2
  local rm = math.max(r[1], r[2], r[3])
  for y = floor(cy - rm - 1), math.ceil(cy + rm + 1) do
    for x = floor(cx - rm - 1), math.ceil(cx + rm + 1) do
      local dx, dy = x + 0.5 - cx, y + 0.5 - cy
      local B, C = 0, -1
      local m = {}
      for i = 1, 3 do
        m[i] = dx * E[i][1] + dy * E[i][2]
        B = B + 2 * m[i] * E[i][3]; C = C + m[i] * m[i]
      end
      local disc = B * B - 4 * A * C
      if disc >= 0 then
        local dd = (-B - sqrt(disc)) / (2 * A)
        local q1, q2, q3 = m[1] + dd * E[1][3], m[2] + dd * E[2][3], m[3] + dd * E[3][3]
        local gx = q1 * E[1][1] + q2 * E[2][1] + q3 * E[3][1]
        local gy = q1 * E[1][2] + q2 * E[2][2] + q3 * E[3][2]
        local gd = q1 * E[1][3] + q2 * E[2][3] + q3 * E[3][3]
        local gl = sqrt(gx * gx + gy * gy + gd * gd)
        gx, gy, gd = gx / gl, gy / gl, gd / gl
        I.q1, I.q2, I.q3 = q1, q2, q3
        I.luz = gx * LX + gy * LY + gd * LD
        I.n[1], I.n[2], I.n[3] = dloc(gx, gy, gd)
        local ox, oy, oz = dloc(dx, dy, dd)
        I.p[1], I.p[2], I.p[3] = c[1] + ox, c[2] + oy, c[3] + oz
        I.t = info
        escribir(x, y, cd + dd, id, mat)
      end
    end
  end
end
local EJES = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
-- Miembro: cadena de esferas de a a b con radio de ra a rb; el material recibe t en I.t.
local function miembro(id, a, b, ra, rb, mat)
  local l = sqrt(pp(dif(b, a), dif(b, a)))
  local n = math.max(1, math.ceil(l / 0.3))
  for k = 0, n do
    local t = k / n
    local r = ra + (rb - ra) * t
    elipsoide(id, { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t },
      EJES, { r, r, r }, mat, t)
  end
end

-- luz del fragmento en la escala de tono() (centro de la forma ~ 0)
local function luz3() return (I.luz - 0.22) * 1.5 + (V.luz or 0) end
local function piel3(base) return function() return tono(PA, base, luz3()) end end

-- partes 3D -----------------------------------------------------------------
local function pierna3(id, cad, Lg, base)
  local lado = cad[2] > 0 and 1 or -1
  local k = suma(cad, dir(Lg[1], 5, lado), 8.5)
  local a = suma(k, dir(Lg[2], 1, lado), 8.5)
  local f = suma(a, dir(Lg[3]), 2.6)
  miembro(id, cad, k, 1.8, 1.45, function()
    local t = I.t
    if base == 4 and t > 0.45 and t < 0.68 and I.n[2] > 0.35 then
      if t > 0.5 and t < 0.62 then return tono(PA, 3, luz3()) end
      return PN[1]
    end
    return tono(PN, base, luz3())
  end)
  local corte = base == 4 and 0.62 or 0.9
  miembro(id, k, a, 1.35, 1.05, function()
    local c = corte + (hash(I.x, I.y) - 0.5) * 0.22
    if I.t > c then return tono(PA, base, luz3()) end
    return tono(PN, base, luz3())
  end)
  miembro(id, a, f, 0.95, 0.8, function()
    if I.t > 0.8 then return PA[2] end
    return tono(PA, base - 1, luz3())
  end)
end

local function brazo3(id, s, A, abre, lado, base)
  local e = suma(s, dir(A[1], abre[1], lado), 6.5)
  local w = suma(e, dir(A[2], abre[2], lado), 6)
  local h = suma(w, dir(A[3], abre[3], lado), 2.2)
  miembro(id, s, e, 1.3, 1.0, piel3(base))
  miembro(id, e, w, 1.05, 0.95, function()
    if base == 4 and lado > 0 and I.t > 0.3 and I.t < 0.55 and I.n[3] < -0.1 then return CA[2] end
    return tono(PA, base, luz3())
  end)
  miembro(id, w, h, 0.95, 0.75, piel3(base - 1))
end

-- tronco: pelvis, vientre, costillar y hombros como elipsoides en el marco del torso
local function torso3(hip, T, len)
  local s = dir(T)
  local c = { s[3], 0, -s[1] }                  -- pecho (adelante y abajo)
  local r = { 0, 1, 0 }
  local ejes = { s, r, c }
  local function mat()
    local d = dif(I.p, hip)
    local a, l = pp(d, s), pp(d, r)
    local nc = pp(I.n, c)
    local lz = luz3()
    if a < 0.9 + hash(floor(l * 2), 1) * 0.5 then return tono(PN, 3, lz) end         -- cintura del pantalón
    local top = len - 0.2
    if a > top - 1.6 then                                                             -- hombros
      if math.abs(math.abs(l) - 1.6) < 0.6 and a < top + 0.6 then return tono(TA, 3, lz) end -- tirantes
      return tono(PA, 4, lz)
    end
    if nc > 0.15 and a > top - 3.4 + math.abs(l) * 0.35 then return tono(PA, 4, lz) end      -- escote
    if nc < -0.2 then                                                                -- espalda
      local sl, sa = math.abs(l) - 1.9, a - (top - 3.0)                              -- omóplatos
      local esc = a > top - 4.6 + hash(floor(l * 1.5), 9) * 1.0                      -- escote trasero roto
      local col
      if esc then col = tono(PA, 3, lz) else col = tono(TA, 3, lz) end
      if math.abs(l) < 0.45 then                                                      -- columna
        if floor(a) % 2 == 0 then return esc and PA[4] or TA[4] end
        return MASOSC[col]
      end
      if sl > -1.3 and sl < 1.0 and sa > -2.0 and sa < 1.3 then
        if sa < -1.3 or sl < -0.9 then return MASOSC[col] end
        if sa > 0.5 then return esc and tono(PA, 4, lz + 0.5) or tono(TA, 4, lz + 0.5) end
      end
      if not esc and a < 2.0 + hash(I.x, 3) * 0.8 then return tono(TA, 2, lz) end
      return col
    end
    local an = a / len
    if an > 0.3 and an < 0.66 and nc > -0.05 and l > -0.6 + hash(floor(a), 5) * 0.8 then -- roto: costillas
      if floor(a + math.abs(l) * 0.4) % 2 == 0 then return PA[2] end
      return tono(PA, 4, lz)
    end
    if a < 2.0 + hash(I.x, 3) * 0.8 then return tono(TA, 2, lz) end                   -- bajo sucio
    local col = tono(TA, 3, lz)
    if hash(I.x * 3, I.y * 7) > 0.86 then col = MASOSC[col] end                       -- mugre
    if an > 0.55 and an < 0.75 and nc > 0 and hash(I.x, I.y * 2) > 0.45 then col = SA[2] end
    return col
  end
  elipsoide(1, suma(hip, s, 1.0), ejes, { 2.0, 2.6, 2.0 }, mat)
  elipsoide(1, suma(hip, s, 4.2), ejes, { 2.6, 2.1, 1.7 }, mat)
  elipsoide(1, suma(hip, s, 7.2), ejes, { 2.9, 2.7, 2.2 }, mat)
  elipsoide(1, suma(hip, s, len - 1.1), ejes, { 1.5, 2.9, 1.9 }, mat)
  return s, c
end

-- cabezas a mano para cada vista: { ax, ay = centro de la cabeza en la pieza, f = filas }
local CAB3 = {
  s = { ax = 3, ay = 3, f = pieza("cab_s", 7, {
    "..445..",
    ".34554.",
    "345443.",
    "i3e4e22",
    "i2o3o2i",
    ".2sBs2.",
    "..2X2..",
  }) },
  se = { ax = 3, ay = 3, f = pieza("cab_se", 7, {
    "..445..",
    ".34554.",
    "h34444.",
    "h3e44e.",
    "i3o32o.",
    ".h2sB2.",
    "...2X..",
  }) },
  ne = { ax = 3, ay = 3, f = pieza("cab_ne", 7, {
    "..i44..",
    ".hi455.",
    "hhi443.",
    "hih343.",
    "hhi232.",
    ".hih2..",
    "..i....",
  }) },
  n = { ax = 3, ay = 3, frente = 4, f = pieza("cab_n", 7, {
    "..343..",
    ".3i43i.",
    "i3ii3hh",
    "hihihih",
    "hihhihh",
    "ihihhi.",
    ".hi.hi.",
    ".h..i..",
  }) },
}
local function cabeza3(H, centro)
  local cx, cy, cd = proy(centro)
  local ox, oy = floor(cx + 0.5) - H.ax, floor(cy + 0.5) - H.ay
  for yy, fila in ipairs(H.f) do
    for xx = 1, #fila do
      local ch = fila:sub(xx, xx)
      if ch ~= "." then
        local col = MH[ch]
        local z = (H.frente and yy > H.frente) and -100 or cd - 1.6
        escribir(ox + xx - 1, oy + yy - 1, z, 2, function() return col end)
      end
    end
  end
end

local CALCO = {
  ["1"] = PA[1], ["2"] = PA[2], ["3"] = PA[3], ["4"] = PA[4], ["5"] = PA[5],
  a = TA[1], b = TA[2], c = TA[3], d = TA[4], e = TA[5], S = SA[2], s = SA[1], n = PN[2], N = PN[3],
}
-- espalda (vista n): trapecios, omóplatos y columna; la camiseta rota empieza abajo
local ESPALDA = { ax = 4, ay = 0, f = pieza("espalda", 9, {
  "44c545c33",
  "45c444c33",
  "4dc434cc3",
  "cd54243bb",
  "cd43233bb",
  "cdc434cbb",
  "cdc323cbb",
  "cddc4cbbb",
  "cdcbcbcba",
  "ccbccbbba",
  "bcbbbbbaa",
  "bbbbabbaa",
}) }
-- pecho (vista s): tirantes, escote, costillas al aire en su lado derecho, sangre seca
local PECHO = { ax = 4, ay = 0, f = pieza("pecho", 9, {
  "45c444c43",
  "4dc444cc3",
  "dcd444ccb",
  "2424ddccb",
  "4343cScbb",
  "2424cSSbb",
  "4343dcSbb",
  "2c2ccccbb",
  "bcbccbcba",
  "bbbbbbbaa",
}) }

-- brazos propios del ataque de frente (por pose del perfil)
local GOLPE_S = {}

-- Ajustes de cada vista sobre la pose del perfil (trampas de dibujante para que se lea).
local AJ = {
  s  = { incl = 0.45, cuello = 0, cab = { 1.0, 2.6 }, atras = true, calco = PECHO, golpe = GOLPE_S, luz = 0.3, flex = 14 },
  se = { incl = 0.8, cuello = 0, cab = { 1.0, 1.8 }, luz = 0.15, flex = 6 },
  ne = { incl = 1.0, cuello = -15, cab = { 0.5, 0.6 }, flex = 6 },
  n  = { incl = 1.0, cuello = -22, cab = { 1.4, 1.4 }, bombeo = true, calco = ESPALDA, flex = 14 },
}
local function figura3(P, H, aj, anda)
  local hip = { 0, 0, 17 }
  local len = P.largo or 10.5
  local T = 180 - (180 - P.torso) * aj.incl
  local s = dir(T)
  local top = suma(hip, s, len)
  local _, _, dc = proy(suma(hip, s, 5))
  local function base(p) local _, _, d = proy(p); return d > dc + 0.6 and 3 or 4 end
  -- lado cercano del perfil = derecha (+r); lejano = izquierda (-r)
  local hN, hF = { 0, 2.0, 17 }, { 0, -2.0, 17 }
  local sN, sF = suma(top, { 0, 1, 0 }, 2.6), suma(top, { 0, -1, 0 }, 2.6)
  sN, sF = suma(sN, s, -0.6), suma(sF, s, -0.6)
  local fl = aj.flex or 0
  local function flex(Lg) return { Lg[1] + fl, Lg[2] - fl * 0.8, Lg[3] } end
  pierna3(5, hN, flex(P.pN), base(hN))
  pierna3(6, hF, flex(P.pF), base(hF))
  torso3(hip, T, len)
  elipsoide(1, sN, EJES, { 1.15, 1.15, 1.15 }, piel3(4))
  elipsoide(1, sF, EJES, { 1.15, 1.15, 1.15 }, piel3(4))
  local nb = suma(top, s, -0.4)
  local ne = suma(nb, dir((P.cuello or 125) + aj.cuello), 3)
  miembro(7, nb, ne, 1.05, 0.95, piel3(3))
  cabeza3(H, suma(suma(ne, { 1, 0, 0 }, aj.cab[1]), { 0, 0, 1 }, aj.cab[2]))
  local bN, bF, abre = P.bN, P.bF, { 16, 10, 6 }
  if aj.golpe and aj.golpe[P] then
    local g = aj.golpe[P]
    bN, bF, abre = g[1], g[2], g[3]
  end
  if aj.atras and anda then
    -- de frente: brazos echados atrás y abiertos, se ven a los lados del tronco
    local a1, a2 = -26 + (P.bN[1] + 48) * 1.1, -26 + (P.bF[1] + 48) * 1.1
    bN, bF, abre = { a1, a1 - 8, a1 + 4 }, { a2, a2 - 8, a2 + 4 }, { 30, 22, 10 }
  end
  if aj.bombeo and anda then
    -- de frente y de espaldas: los brazos bombean a los lados, codo doblado
    local a1, a2 = (P.bN[1] + 48) * 2.2 - 12, (P.bF[1] + 48) * 2.2 - 12
    bN, bF, abre = { a1, a1 + 85, a1 + 95 }, { a2, a2 + 85, a2 + 95 }, { 28, 6, 0 }
  end
  if aj.calco then
    -- calco pintado a mano sobre el tronco (solo donde lo de delante es el tronco)
    local D = aj.calco
    local x0, y0 = proy(suma(top, s, 0.6))
    local ox, oy = floor(x0 + 0.5) - D.ax, floor(y0 + 0.5) - D.ay
    for yy, fila in ipairs(D.f) do for xx = 1, #fila do
      local ch = fila:sub(xx, xx)
      local x, y = ox + xx - 1, oy + yy - 1
      if ch ~= "." and x >= 0 and y >= 0 and x < W3 and y < H3 and IB[y * W3 + x] == 1 then
        CB[y * W3 + x] = CALCO[ch]
      end
    end end
  end
  brazo3(3, sN, bN, abre, 1, base(sN))
  brazo3(4, sF, bF, abre, -1, base(sF))
end

-- Pasa el búfer a una imagen: sombra de 1 px que lo de delante arroja abajo a la derecha.
local function revelar(img)
  for y = 0, H3 - 1 do for x = 0, W3 - 1 do
    local k = y * W3 + x
    local c = CB[k]
    if c then
      local function delante(xx, yy)
        if xx < 0 or yy < 0 then return false end
        local j = yy * W3 + xx
        return CB[j] and IB[j] ~= IB[k] and ZB[j] < ZB[k] - 0.9
      end
      if delante(x - 1, y) or delante(x, y - 1) or delante(x + 1, y) or delante(x, y + 1) then c = MASOSC[c] or c end
      img:drawPixel(x, y, c)
    end
  end end
end

local VISTAS = { s = -90, se = -45, ne = 45, n = 90 }
local OX = { s = 20, se = 19, ne = 19, n = 20 }
local function pose3(dirn, P, anda)
  return function(img)
    vista(VISTAS[dirn], OX[dirn], 50)
    V.luz = AJ[dirn].luz
    figura3(P, CAB3[dirn], AJ[dirn], anda)
    local tmp = L.imagen(W3, H3)
    revelar(tmp)
    local dy = (38 - (P.alto or 0)) - fondo(tmp)
    L.pegar(img, tmp, 0, dy)
    contorno(img, 38)
  end
end

GOLPE_S[POSES[9]] = { { -30, -55, -70 }, { -30, -55, -70 }, { 50, 40, 30 } }   -- abre los brazos atrás
GOLPE_S[POSES[10]] = { { 100, 75, 60 }, { 105, 80, 65 }, { 38, 26, 18 } }     -- zarpazo hacia la cámara
GOLPE_S[POSES[11]] = { { 45, 25, 10 }, { 55, 30, 15 }, { 10, -24, -34 } }         -- arrastra las garras abajo
---------------------------------------------------------------- montaje
local E = cuadros
local final, ETIQUETAS, DURACIONES = {}, {}, {}
local function bloque(nombre, lista, dur)
  local a = #final + 1
  for i, f in ipairs(lista) do final[#final + 1] = f; DURACIONES[#DURACIONES + 1] = dur[i] end
  ETIQUETAS[#ETIQUETAS + 1] = { nombre, a, #final }
end
local DA = { 0.065, 0.065, 0.065, 0.065, 0.065, 0.065, 0.065, 0.065 }
local DT = { 0.10, 0.07, 0.09, 0.12 }
local function serie(dirn, desde, n)
  local t = {}
  for i = desde, desde + n - 1 do t[#t + 1] = pose3(dirn, POSES[i], desde == 1) end
  return t
end
local function rango(a, b) local t = {}; for i = a, b do t[#t + 1] = E[i] end; return t end
bloque("andar_s", serie("s", 1, 8), DA)
bloque("andar_se", serie("se", 1, 8), DA)
bloque("andar_e", rango(1, 8), DA)
bloque("andar_ne", serie("ne", 1, 8), DA)
bloque("andar_n", serie("n", 1, 8), DA)
bloque("atacar_s", serie("s", 9, 4), DT)
bloque("atacar_se", serie("se", 9, 4), DT)
bloque("atacar_e", rango(9, 12), DT)
bloque("atacar_ne", serie("ne", 9, 4), DT)
bloque("atacar_n", serie("n", 9, 4), DT)
bloque("morir", rango(13, 18), { 0.09, 0.09, 0.11, 0.13, 0.16, 1.0 })
L.construir("corredor", 40, 40, final, ETIQUETAS, DURACIONES, { pies = { 20, 38 } })
