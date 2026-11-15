-- Corredor de Horda Pixel: zombi rápido, demacrado y pálido, camiseta de tirantes sucia,
-- pantalón oscuro hecho jirones, descalzo. Esprinta encorvado ~35° con los brazos atrás.
-- Se dibuja con un esqueleto (cadera, torso, cuello, miembros con ángulos) y cápsulas
-- sombreadas con luz de arriba a la izquierda; la cabeza es una pieza a mano.
-- Lienzo 40x40, suelas en y = 38, cuerpo centrado en x = 20.
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
local function pose(P, antes, despues)
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

local ETIQUETAS = { { "andar", 1, 8 }, { "atacar", 9, 12 }, { "morir", 13, 18 } }
local DURACIONES = {
  0.065, 0.065, 0.065, 0.065, 0.065, 0.065, 0.065, 0.065,
  0.10, 0.07, 0.09, 0.12,
  0.09, 0.09, 0.11, 0.13, 0.16, 1.0,
}
L.construir("corredor", 40, 40, cuadros, ETIQUETAS, DURACIONES, { pies = { 20, 38 } })
