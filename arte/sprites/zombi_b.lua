-- zombi.lua — construye «zombi» y «zombi_b» (40x40).
-- Construcción por anatomía: cada fotograma parte de un esqueleto (articulaciones) y se viste
-- por capas de atrás adelante; luego contorno selectivo y retoques a mano.
local L = dofile(app.params.lib)
-- Este archivo solo construye la variante «zombi_b» (la mujer del vestido mostaza).
do local c = L.construir; L.construir = function(n, ...) if n == "zombi_b" then c(n, ...) end end end
local W, H = 40, 40
local floor, ceil, sin, cos, sqrt, abs = math.floor, math.ceil, math.sin, math.cos, math.sqrt, math.abs
local max, min = math.max, math.min
local function rad(g) return g * math.pi / 180 end
local function red(v) return floor(v + 0.5) end

---------------------------------------------------------------- paleta
local INFO = {}      -- color -> { r = rampa, i = índice }
local function rampa(def)
  local r = {}
  if type(def) == "string" then r = L.rampa(def) else for i, h in ipairs(def) do r[i] = L.hex(h) end end
  for i, c in ipairs(r) do INFO[c] = { r = r, i = i } end
  return r
end
local TINTA  = rampa("tinta")
local PIEL   = rampa("zombi")
local CARNE  = rampa("carne")
local SANGRE = rampa("sangre")
local PELO   = rampa("pelo")
local CUERO  = rampa("cuero")
local CAMISA = rampa({ "2e1814", "4a2620", "6b3a2e", "8a5340", "a1694f" })   -- ropa_a + luz polvorienta
local VAQ    = rampa({ "1a2030", "28324a", "3a4866", "526285", "6c7b99" })   -- vaquero + tono gastado
local MOSTAZA = rampa({ "33290f", "54441c", "78632c", "9c8444", "b39c5a" })  -- ropa_c + luz
local OJO    = L.hex("c4c8ba")
local MARCA  = L.hex("ff00ff")

local function tono(c, d)
  local f = INFO[c]
  if not f then return c end
  local i = f.i + d
  if i < 1 then return TINTA[2] end
  if i > #f.r then i = #f.r end
  return f.r[i]
end

---------------------------------------------------------------- utilidades de dibujo
local function capa() return L.imagen(W, H) end

local function mascara(c)
  local m = {}
  for y = 0, H - 1 do for x = 0, W - 1 do m[y * W + x] = L.alfa(c:getPixel(x, y)) > 0 end end
  return function(x, y) return x >= 0 and y >= 0 and x < W and y < H and m[y * W + x] end
end

-- Cápsula de grosor variable (g0 en el origen, g1 en el extremo): masas anchas (tronco, falda).
local function cono(img, a, b, g0, g1, c)
  c = c or MARCA
  local x0, y0, x1, y1 = a[1], a[2], b[1], b[2]
  local dx, dy = x1 - x0, y1 - y0
  local l2 = dx * dx + dy * dy
  local rm = max(g0, g1) / 2
  for y = floor(min(y0, y1) - rm - 1), ceil(max(y0, y1) + rm + 1) do
    for x = floor(min(x0, x1) - rm - 1), ceil(max(x0, x1) + rm + 1) do
      local cx, cy = x + 0.5, y + 0.5
      local t = l2 > 0 and max(0, min(1, ((cx - x0) * dx + (cy - y0) * dy) / l2)) or 0
      local r = (g0 + (g1 - g0) * t) / 2
      local qx, qy = x0 + dx * t, y0 + dy * t
      if (cx - qx) ^ 2 + (cy - qy) ^ 2 <= r * r then L.px(img, x, y, c) end
    end
  end
end

-- Miembro limpio: línea de píxeles ensanchada a w px en perpendicular al eje mayor (sin dientes).
-- sesgo 0 = el píxel de más (anchos pares) va a la derecha/abajo; 0.5 = a la izquierda/arriba.
local function tira(c, a, b, w0, w1, sesgo)
  local x0, y0, x1, y1 = floor(a[1]), floor(a[2]), floor(b[1]), floor(b[2])
  local dx, dy = x1 - x0, y1 - y0
  local n = max(abs(dx), abs(dy))
  local emp = abs(dy) >= abs(dx)
  local k = n > 0 and sqrt(dx * dx + dy * dy) / n or 1
  for i = 0, n do
    local t = n > 0 and i / n or 0
    local x, y = red(x0 + dx * t), red(y0 + dy * t)
    local w = max(1, red((w0 + (w1 - w0) * t) * k - 0.01))
    local k0 = -floor((w - 1) / 2 + (sesgo or 0))
    for j = 0, w - 1 do
      if emp then L.px(c, x + k0 + j, y, MARCA) else L.px(c, x, y + k0 + j, MARCA) end
    end
  end
end

-- Relleno de la articulación entre dos tiras.
local function nudo(c, p, w)
  local x, y = floor(p[1]), floor(p[2])
  local k0 = floor((w - 1) / 2)
  L.rect(c, x - k0, y - k0, w, w, MARCA)
end

-- Miembro de dos huesos; solo rellena la articulación si un tramo es empinado y el otro tendido.
local function empinada(a, b) return abs(floor(b[2]) - floor(a[2])) >= abs(floor(b[1]) - floor(a[1])) end
local function miembro2(c, a, j, b, w0, w1, w2)
  tira(c, a, j, w0, w1); tira(c, j, b, w1, w2)
  if empinada(a, j) ~= empinada(j, b) then nudo(c, j, w1) end
end

-- Sombreado direccional de una capa: luz arriba-izquierda, sombra abajo-derecha.
-- op: luz, sombra (px de ancho), dl, ds (saltos de tono)
local function sombrear(c, r, b, op)
  op = op or {}
  local o = mascara(c)
  local nl, ns = op.luz or 1, op.sombra or 1
  local dl, ds = op.dl or 1, op.ds or -1
  for y = 0, H - 1 do for x = 0, W - 1 do
    if o(x, y) then
      local lit, shd = false, false
      for k = 1, nl do if not o(x - k, y) or not o(x, y - k) then lit = true end end
      for k = 1, ns do if not o(x + k, y) or not o(x, y + k) then shd = true end end
      local t = b
      if lit and not shd then t = b + dl
      elseif shd and not lit then t = b + ds end
      t = max(1, min(#r, t))
      c:drawPixel(x, y, r[t])
    end
  end end
end

-- Pega una capa sobre el destino con sombra de oclusión (1 px a la derecha y debajo).
local function pegar(dst, c, op)
  if not (op and op.sin_oclusion) then
    local o = mascara(c)
    for y = 0, H - 1 do for x = 0, W - 1 do
      if not o(x, y) and L.opaco(dst, x, y) and (o(x - 1, y) or o(x, y - 1)) then
        dst:drawPixel(x, y, tono(dst:getPixel(x, y), -1))
      end
    end end
  end
  L.pegar(dst, c, 0, 0)
end

-- Punto local a un hueso a->b: u a lo largo (0..1), v px hacia el frente.
local function loc(a, b, u, v)
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local l = sqrt(dx * dx + dy * dy)
  if l < 0.001 then return { a[1], a[2] } end
  return { a[1] + dx * u + (dy / l) * (v or 0), a[2] + dy * u - (dx / l) * (v or 0) }
end

-- Pinta un píxel solo si ya hay figura debajo (detalles que no cambian la silueta).
local function sobre(img, p, c)
  local x, y = floor(p[1]), floor(p[2])
  if L.opaco(img, x, y) then img:drawPixel(x, y, c) end
end
local function pon(img, p, c) L.px(img, floor(p[1]), floor(p[2]), c or MARCA) end

-- Línea de detalle solo sobre la figura (regueros, costuras).
local function raya(img, a, b, c)
  local x0, y0, x1, y1 = floor(a[1]), floor(a[2]), floor(b[1]), floor(b[2])
  local n = max(abs(x1 - x0), abs(y1 - y0))
  for i = 0, n do
    local t = n > 0 and i / n or 0
    local x, y = red(x0 + (x1 - x0) * t), red(y0 + (y1 - y0) * t)
    if L.opaco(img, x, y) then img:drawPixel(x, y, c) end
  end
end

-- Envolvente convexa (para la falda).
local function casco(pts)
  table.sort(pts, function(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end)
  local function cruz(o, a, b) return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1]) end
  local h = {}
  for i = 1, #pts do
    while #h >= 2 and cruz(h[#h - 1], h[#h], pts[i]) <= 0 do h[#h] = nil end
    h[#h + 1] = pts[i]
  end
  local t = #h + 1
  for i = #pts - 1, 1, -1 do
    while #h >= t and cruz(h[#h - 1], h[#h], pts[i]) <= 0 do h[#h] = nil end
    h[#h + 1] = pts[i]
  end
  h[#h] = nil
  return h
end

-- Sello de píxeles a mano. ancla (0-based) cae en (ax, ay). inc = px de desplazamiento por fila hacia arriba.
local function sello(img, filas, mapa, ax, ay, ancla, inc)
  ax, ay = floor(ax), floor(ay)
  for j = 1, #filas do
    local fila = filas[j]
    local dx = red((ancla[2] - (j - 1)) * (inc or 0))
    for i = 1, #fila do
      local ch = fila:sub(i, i)
      if ch ~= "." then
        local c = mapa[ch]
        if c == nil then error("sello: sin color para '" .. ch .. "'") end
        L.px(img, ax - ancla[1] + (i - 1) + dx, ay - ancla[2] + (j - 1), c)
      end
    end
  end
end

-- Contorno selectivo del color del material: solo abajo y a la derecha (lado en sombra).
-- Arriba y a la izquierda el borde es la propia luz de la forma.
local function contornear(img, op)
  op = op or {}
  local src = {}
  for y = 0, H - 1 do for x = 0, W - 1 do src[y * W + x] = img:getPixel(x, y) end end
  local function g(x, y) if x < 0 or y < 0 or x >= W or y >= H then return 0 end return src[y * W + x] end
  local function op_(c) return L.alfa(c) > 0 end
  for y = 0, min(H - 1, op.suelo or 38) do for x = 0, W - 1 do
    if not op_(g(x, y)) then
      local iz, ar = g(x - 1, y), g(x, y - 1)
      if op_(iz) or op_(ar) then
        local v = op_(iz) and iz or ar
        local f = INFO[v]
        local c = (f and f.i >= 3) and f.r[1] or TINTA[2]
        if f and f.r == PIEL then c = PIEL[1] end
        img:drawPixel(x, y, c)
      end
    end
  end end
end

---------------------------------------------------------------- esqueleto
-- IK de dos huesos: devuelve la articulación intermedia; sentido = hacia dónde dobla.
local function ik(a, b, l1, l2, sentido)
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local d = sqrt(dx * dx + dy * dy)
  if d >= l1 + l2 - 0.01 or d < 0.01 then
    local k = l1 / (l1 + l2)
    return { a[1] + dx * k, a[2] + dy * k }
  end
  local q = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
  local hh = sqrt(max(0, l1 * l1 - q * q))
  local mx, my = a[1] + dx * q / d, a[2] + dy * q / d
  local px, py = -dy / d, dx / d
  if px * sentido[1] + py * sentido[2] < 0 then px, py = -px, -py end
  return { mx + px * hh, my + py * hh }
end

-- Ángulos: 0 = hacia abajo, 90 = hacia delante (derecha), 180 = arriba, negativos = atrás.
local function hacia(o, ang, l) return { o[1] + sin(rad(ang)) * l, o[2] + cos(rad(ang)) * l } end

local function esqueleto(p, V)
  local s = {}
  local hx, hy = p.cad[1], p.cad[2]
  s.cad = { hx, hy }
  s.cin = hacia(s.cad, 180 - p.t1, V.lumbar)          -- t1, t2: inclinación del tronco hacia delante
  s.cue = hacia(s.cin, 180 - p.t2, V.torax)
  local prof = p.prof or { 1.6, -1.0 }                -- desplazamiento del lado lejano (vista 3/4)
  local hom = hacia(s.cue, -p.t2, 1.0)
  s.hom = hom
  s.hom_l = { hom[1] + prof[1] * 0.6, hom[2] + prof[2] * 0.6 }
  s.hom_c = { hom[1] - prof[1] * 0.4, hom[2] - prof[2] * 0.4 }
  s.cad_l = { hx + prof[1] * 0.35, hy + prof[2] * 0.35 }
  s.cad_c = { hx - prof[1] * 0.25, hy - prof[2] * 0.25 }
  s.cab = hacia(s.cue, 180 - (p.cuello or (p.t2 + 12)), V.cuello)
  local rd = p.rod or { 1, 0 }
  s.tob_l = { p.pl[1], p.pl[2] }
  s.tob_c = { p.pc[1], p.pc[2] }
  s.rod_l = ik(s.cad_l, s.tob_l, V.muslo, V.pierna, p.rod_l or rd)
  s.rod_c = ik(s.cad_c, s.tob_c, V.muslo, V.pierna, p.rod_c or rd)
  local function brazo(h, b, k)
    k = k or 1                                         -- escorzo (brazos hacia el fondo, cuerpo tendido)
    local c1 = hacia(h, b[1], V.brazo * k)
    local m = hacia(c1, b[2], V.antebrazo * k)
    local d = hacia(m, b[3] or b[2], V.mano)
    return c1, m, d
  end
  s.cod_l, s.mun_l, s.ded_l = brazo(s.hom_l, p.bl, p.kbl)
  s.cod_c, s.mun_c, s.ded_c = brazo(s.hom_c, p.bc, p.kbc)
  -- Ajuste a la rejilla: cada articulación en el centro de su píxel (sin temblores de subpíxel).
  local f = {}
  for k, v in pairs(s) do
    f[k] = v
    s[k] = { floor(v[1]) + 0.5, floor(v[2]) + 0.5 }
  end
  s.f = f
  return s
end

---------------------------------------------------------------- piezas comunes
-- Una pieza: dibuja la forma en una capa, la sombrea con su rampa y la pega con oclusión.
local function parte(dst, r, base, op, forma)
  local c = capa()
  forma(c)
  sombrear(c, r, base, op)
  pegar(dst, c, op)
  return c
end

local MAPA_PIE = {
  L = PIEL[5], S = PIEL[4], D = PIEL[3], d = PIEL[2],
  a = CUERO[5], b = CUERO[4], c = CUERO[3], e = CUERO[2], f = CUERO[1],
}
local PIE_DESCALZO = { ".LS..", "DSSSL" }
local PIE_DESCALZO_L = { ".SD..", "dDDDS" }
local PIE_ZAPATO = { "bcc..", "cccce", "fffff" }

-- Pie: tobillo t (flotante), cabeceo inc (>0 puntera abajo). tipo: "descalzo", "descalzo_l", "zapato".
local function pie(dst, t, inc, tipo)
  local c = capa()
  if abs(inc) < 7 then
    local filas = tipo == "zapato" and PIE_ZAPATO or (tipo == "descalzo_l" and PIE_DESCALZO_L or PIE_DESCALZO)
    -- la suela cae en la fila del tobillo + 1
    sello(c, filas, MAPA_PIE, t[1], floor(t[2]) + 1, { 1, #filas - 1 })
  else
    local ca, sa = cos(rad(inc)), sin(rad(inc))
    local function R(x, y) return { t[1] + x * ca - y * sa, t[2] + x * sa + y * ca } end
    local a, b = R(-0.6, 1), R(3.2, 1)
    L.grueso(c, a[1], a[2], b[1], b[2], 2, MARCA)
    if tipo == "zapato" then
      sombrear(c, CUERO, 3)
      local o = mascara(c)
      for y = 0, H - 1 do for x = 0, W - 1 do
        if o(x, y) and not o(x, y + 1) then c:drawPixel(x, y, CUERO[1]) end
      end end
    else
      sombrear(c, PIEL, tipo == "descalzo_l" and 3 or 4, { ds = -1 })
    end
  end
  pegar(dst, c)
end

-- Mano: palma + dedos. abierta = dedos separados (garra).
local function mano(dst, m, d, r, base, abierta)
  local c = capa()
  local q = loc(m, d, 0.45, 0)
  L.grueso(c, m[1], m[2], q[1], q[2], 2.0, MARCA)
  pon(c, loc(m, d, 0.75, 0.4))
  pon(c, d)
  if abierta then pon(c, loc(m, d, 0.8, -1.3)) end
  sombrear(c, r, base, { ds = -1 })
  pegar(dst, c)
end

local function unidad(a, b)
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local l = sqrt(dx * dx + dy * dy)
  if l < 0.001 then return 0, 1 end
  return dx / l, dy / l
end

---------------------------------------------------------------- cabezas (sellos a mano)
local MAPA_CAB = {
  p = PELO[4], h = PELO[3], H = PELO[2], k = PELO[1],
  L = PIEL[5], S = PIEL[4], D = PIEL[3], d = PIEL[2], e = PIEL[1], o = OJO,
  M = SANGRE[3], m = SANGRE[4], b = SANGRE[2], K = SANGRE[1],
  c = CARNE[3], C = CARNE[2],
}
local CAB_A = {
  frente = { ancla = { 2, 5 }, filas = {
    ".phhH.",
    "phhHHS",
    "hHHDSL",
    ".HDeoS",
    ".dDSSL",
    "..dDMM",
  } },
  abierta = { ancla = { 2, 5 }, filas = {
    ".phhH.",
    "phhHHS",
    "hHHDSL",
    ".HDeoS",
    ".dDSSL",
    "..dDKK",
    "..ddMm",
  } },
  atras = { ancla = { 3, 5 }, filas = {
    "..hSL.",
    ".phSoS",
    "phHDSL",
    "hhHDSM",
    ".HHDDM",
    "..Hd..",
  } },
  tumbada = { ancla = { 5, 3 }, filas = {
    ".SLSLM",
    "hHSoSM",
    "hHDeSD",
    "phHDDd",
    ".hHHd.",
  } },
}
local CAB_B = {
  frente = { ancla = { 2, 5 }, filas = {
    ".hhHH.",
    "hhHHHH",
    "hHHHSL",
    "HHHeoS",
    "HHkSSL",
    "HHkDMM",
  } },
  abierta = { ancla = { 2, 5 }, filas = {
    ".hhHH.",
    "hhHHHH",
    "hHHHSL",
    "HHHeoS",
    "HHkSSL",
    "HHkSKK",
    ".HkdMm",
  } },
  atras = { ancla = { 3, 5 }, filas = {
    "..HSL.",
    ".hHSoS",
    "hHHHSL",
    "HHHkSM",
    "HHHkDM",
    ".HHd..",
  } },
  tumbada = { ancla = { 5, 3 }, filas = {
    ".HLSLM",
    "hHHoSM",
    "hHHeSD",
    "hHHHDd",
    ".HHHk.",
  } },
}

---------------------------------------------------------------- figura A: hombre, camisa granate rota, vaqueros
local VA = { muslo = 8.5, pierna = 8.3, lumbar = 5.0, torax = 5.6, cuello = 1.4, brazo = 6.0, antebrazo = 5.0, mano = 2.8 }

local function figura_a(img, s, p)
  local vai = p.vai or 0
  -- brazo lejano (manga entera, más oscuro)
  parte(img, CAMISA, 2, { ds = 0 }, function(c)
    miembro2(c, s.hom_l, s.cod_l, s.mun_l, 2, 2, 2)
  end)
  mano(img, s.mun_l, s.f.ded_l, PIEL, 4, p.garra)
  -- pierna lejana (vaquero, zapato)
  parte(img, VAQ, 3, nil, function(c)
    miembro2(c, s.cad_l, s.rod_l, s.tob_l, 3, 3, 2)
  end)
  pie(img, s.f.tob_l, p.pl[3] or 0, "zapato")
  -- pierna cercana: espinilla y pie desnudos, herida
  parte(img, PIEL, 4, { ds = 0 }, function(c)
    tira(c, s.rod_c, s.tob_c, 2, 2)
    pon(c, loc(s.rod_c, s.tob_c, 0.38, -1.4)); pon(c, loc(s.rod_c, s.tob_c, 0.52, -1.4))
  end)
  raya(img, loc(s.rod_c, s.tob_c, 0.62, 0.4), loc(s.rod_c, s.tob_c, 0.8, 0.4), CARNE[2])
  pie(img, s.f.tob_c, p.pc[3] or 0, "descalzo")
  -- vaquero cercano, roto bajo la rodilla
  parte(img, VAQ, 4, nil, function(c)
    miembro2(c, s.cad_c, s.rod_c, loc(s.rod_c, s.tob_c, 0.3, 0), 3, 3, 3)
  end)
  sobre(img, loc(s.cad_c, s.rod_c, 0.95, -1.2), VAQ[2])
  -- pelvis
  parte(img, VAQ, 4, { sin_oclusion = true }, function(c)
    L.elipse(c, s.cad[1], s.cad[2] + 1.0, 2.6, 2.4, MARCA)
  end)
  -- tronco (camisa por fuera, bajo irregular)
  local dx, dy = unidad(s.cin, s.cad)
  local fx, fy = dy, -dx
  parte(img, CAMISA, 3, { sombra = 2 }, function(c)
    cono(c, s.cad, s.cin, 4.6, 4.6)
    cono(c, s.cin, s.hom, 4.8, 5.6)
    L.elipse(c, s.hom_c[1], s.hom_c[2], 1.9, 1.7, MARCA)
  end)
  -- roto con piel en el costado, arruga en la cintura, reguero de sangre en la pechera
  raya(img, loc(s.cin, s.cad, 0.15, 0.6), loc(s.cin, s.cad, 0.5, 0.9), PIEL[3])
  sobre(img, loc(s.cin, s.cad, 0.62, 1.0), CARNE[2])
  raya(img, loc(s.cue, s.cin, 0.9, -1.6), loc(s.cue, s.cin, 1.05, -0.4), CAMISA[2])
  raya(img, loc(s.cue, s.cin, 0.18, 2.0), loc(s.cue, s.cin, 0.6, 1.9), SANGRE[2])
  sobre(img, loc(s.cue, s.cin, 0.18, 2.0), SANGRE[3])
  -- cuello y cabeza
  parte(img, PIEL, 3, { sin_oclusion = true }, function(c) tira(c, s.hom, s.cab, 2, 2) end)
  do
    local cb = CAB_A[p.cabeza or "frente"]
    local c = capa()
    sello(c, cb.filas, MAPA_CAB, s.cab[1] + (p.cab_dx or 0), s.cab[2] + (p.cab_dy or 0), cb.ancla, p.cab_inc)
    pegar(img, c)
  end
  -- brazo cercano: antebrazo desnudo y manga hasta el codo
  parte(img, PIEL, 4, { ds = 0 }, function(c) tira(c, s.cod_c, s.mun_c, 2, 2) end)
  mano(img, s.mun_c, s.f.ded_c, PIEL, 4, p.garra)
  parte(img, CAMISA, 3, nil, function(c)
    tira(c, s.hom_c, s.cod_c, 3, 2)
  end)
end

---------------------------------------------------------------- figura B: mujer, vestido mostaza, melena oscura
local VB = { muslo = 8.1, pierna = 8.0, lumbar = 4.6, torax = 5.2, cuello = 1.4, brazo = 5.6, antebrazo = 4.8, mano = 2.6 }

local function figura_b(img, s, p)
  local vai = p.vai or 0
  -- brazo lejano (desnudo)
  parte(img, PIEL, 3, { ds = 0 }, function(c)
    miembro2(c, s.hom_l, s.cod_l, s.mun_l, 2, 2, 2)
  end)
  mano(img, s.mun_l, s.f.ded_l, PIEL, 3, p.garra)
  -- pierna lejana (desnuda, zapato plano)
  parte(img, PIEL, 3, nil, function(c)
    miembro2(c, s.cad_l, s.rod_l, s.tob_l, 3, 2, 2)
  end)
  pie(img, s.f.tob_l, p.pl[3] or 0, "zapato")
  -- pierna cercana (desnuda, descalza)
  parte(img, PIEL, 4, { ds = 0 }, function(c)
    miembro2(c, s.cad_c, s.rod_c, s.tob_c, 3, 2, 2)
    pon(c, loc(s.rod_c, s.tob_c, 0.3, -1.4)); pon(c, loc(s.rod_c, s.tob_c, 0.45, -1.4))
  end)
  raya(img, loc(s.rod_c, s.tob_c, 0.5, 0.4), loc(s.rod_c, s.tob_c, 0.7, 0.4), CARNE[2])
  pie(img, s.f.tob_c, p.pc[3] or 0, "descalzo")
  -- falda: envolvente de la cadera y los dos muslos hasta encima de la rodilla
  local kl, kc = loc(s.cad_l, s.rod_l, 0.66, 0), loc(s.cad_c, s.rod_c, 0.7, 0)
  local dx, dy = unidad(s.cin, s.cad)
  local fx, fy = dy, -dx
  parte(img, MOSTAZA, 3, nil, function(c)
    local pts = {
      { s.cad[1] - fx * 2.5 - dx, s.cad[2] - fy * 2.5 - dy }, { s.cad[1] + fx * 2.3 - dx, s.cad[2] + fy * 2.3 - dy },
      loc(s.cad_l, kl, 1, 2.0), loc(s.cad_l, kl, 1, -2.0), loc(s.cad_c, kc, 1, 2.3), loc(s.cad_c, kc, 1, -2.3),
    }
    L.poligono(c, casco(pts), MARCA)
    pon(c, { kc[1] - 1.5 - vai, kc[2] + 1.5 })
  end)
  raya(img, loc(s.cad_c, kc, 0.3, -0.4), loc(s.cad_c, kc, 0.95, -1.0), MOSTAZA[2])
  -- cuerpo del vestido
  parte(img, MOSTAZA, 3, { sombra = 2, sin_oclusion = true }, function(c)
    cono(c, s.cad, s.cin, 4.4, 3.8)
    cono(c, s.cin, s.hom, 4.0, 5.0)
    L.elipse(c, s.hom_c[1], s.hom_c[2], 1.6, 1.5, MARCA)
  end)
  raya(img, loc(s.cue, s.cin, 1.0, -1.4), loc(s.cue, s.cin, 1.0, 0.6), MOSTAZA[2])
  raya(img, loc(s.cue, s.cin, 0.2, 1.8), loc(s.cue, s.cin, 0.62, 1.7), SANGRE[2])
  sobre(img, loc(s.cue, s.cin, 0.2, 1.8), SANGRE[3])
  -- cuello
  parte(img, PIEL, 3, { sin_oclusion = true }, function(c) tira(c, s.hom, s.cab, 2, 2) end)
  -- melena por la espalda (con retardo)
  local hx, hy = s.cab[1] + (p.cab_dx or 0), s.cab[2] + (p.cab_dy or 0)
  local punta = p.pelo and { hx + p.pelo[1], hy + p.pelo[2] } or { s.hom[1] - 2.6 - vai * 1.5, s.hom[2] + 4.2 }
  parte(img, PELO, 2, nil, function(c)
    cono(c, { hx - 1.6, hy - 2.5 }, punta, 3.2, 1.8)
  end)
  do
    local cb = CAB_B[p.cabeza or "frente"]
    local c = capa()
    sello(c, cb.filas, MAPA_CAB, hx, hy, cb.ancla, p.cab_inc)
    pegar(img, c)
  end
  -- brazo cercano (desnudo, mordisco en el antebrazo) con resto de manga corta
  parte(img, PIEL, 4, { ds = 0 }, function(c)
    miembro2(c, s.hom_c, s.cod_c, s.mun_c, 2, 2, 2)
  end)
  raya(img, loc(s.cod_c, s.mun_c, 0.3, 0.3), loc(s.cod_c, s.mun_c, 0.55, 0.3), CARNE[2])
  mano(img, s.mun_c, s.f.ded_c, PIEL, 4, p.garra)
  parte(img, MOSTAZA, 3, nil, function(c)
    tira(c, s.hom_c, loc(s.hom_c, s.cod_c, 0.3, 0), 3, 3)
  end)
end

---------------------------------------------------------------- poses
local SUELO_C, SUELO_L = 37, 36          -- y del tobillo con el pie plano (cercano / lejano)

-- tobillo con el punto más bajo del pie apoyado (o levantado «sub» px)
local function tobillo(x, sub, inc, base)
  if abs(inc) < 7 then return { x, base - sub, inc } end
  local sa, ca = sin(rad(inc)), cos(rad(inc))
  local bajo = max(3.2 * sa + ca, -0.6 * sa + ca)
  return { x, base - sub - (bajo - 1), inc }
end

local function poses_andar()
  local t = {}
  -- pierna lejana (la buena): apoyo 0-3, vuelo 4-7. pierna cercana (la mala): apoyo 4-7, arrastre 0-3.
  local lx   = { 5, 3, 1, -1, -3, -1, 3, 6 }
  local lsub = { 0, 0, 0, 0, 0, 2.2, 2, 0.8 }
  local linc = { 0, 0, 0, 0, 32, 22, -8, -18 }
  local cx   = { -6, -5, -3, -1, 1, -1, -3, -5 }
  local csub = { 0, 0, 0, 0, 0, 0, 0, 0 }
  local cinc = { 38, 34, 28, 14, 0, 0, 0, 16 }
  local hy   = { 22.2, 22.6, 22.0, 21.4, 21.2, 21.0, 21.2, 21.7 }
  local hxs  = { 19.4, 19.6, 19.3, 19.0, 18.8, 18.8, 19.0, 19.2 }
  local t1   = { 14, 16, 13, 10, 8, 8, 10, 12 }
  local t2   = { 32, 36, 32, 27, 24, 23, 26, 30 }
  local ext  = { 80, 76, 73, 75, 79, 83, 85, 83 }      -- brazo extendido
  local col1 = { -8, -2, 5, 10, 8, 2, -5, -10 }        -- brazo colgando (péndulo con retardo)
  local col2 = { 4, 12, 20, 24, 18, 10, 2, -2 }
  local vai  = { 0, 1, 1, 0, 0, -1, -1, 0 }
  local inc  = { 0.2, 0.3, 0.3, 0.2, 0.1, 0.1, 0.1, 0.2 }
  for i = 1, 8 do
    local hx = hxs[i]
    t[i] = {
      cad = { hx, hy[i] }, t1 = t1[i], t2 = t2[i],
      pl = tobillo(hx + lx[i], lsub[i], linc[i], SUELO_L),
      pc = tobillo(hx + cx[i], csub[i], cinc[i], SUELO_C),
      ext = { ext[i], ext[i] + 8, ext[i] + 40 },
      col = { col1[i], col2[i], col2[i] + 5 },
      cabeza = "frente", cab_inc = inc[i], vai = vai[i],
    }
  end
  return t
end

local function poses_atacar()
  return {
    -- toma impulso: se echa atrás, garra lejana en alto, codo cercano atrás
    { cad = { 18.2, 21.6 }, t1 = -3, t2 = 2, cuello = -8,
      pl = tobillo(21.5, 0, 0, SUELO_L), pc = tobillo(14.5, 0, 8, SUELO_C),
      bl = { 165, 200, 215 }, bc = { -52, 38, 55 }, cabeza = "abierta", cab_inc = 0, garra = true, vai = 1 },
    -- zarpazo: todo el cuerpo se lanza, los dos brazos al frente
    { cad = { 19.2, 22.3 }, t1 = 26, t2 = 44, cuello = 62,
      pl = tobillo(25, 0, 0, SUELO_L), pc = tobillo(13, 0, 30, SUELO_C),
      bl = { 100, 92, 100 }, bc = { 92, 84, 95 }, cabeza = "abierta", cab_inc = 0.3, garra = true, vai = -1 },
    -- sigue el movimiento: los brazos caen, el tronco se vence
    { cad = { 19.6, 22.7 }, t1 = 30, t2 = 54, cuello = 78,
      pl = tobillo(25, 0, 0, SUELO_L), pc = tobillo(14, 0, 24, SUELO_C),
      bl = { 60, 46, 36 }, bc = { 44, 30, 24 }, cabeza = "frente", cab_inc = 0.4, garra = true, vai = -1 },
    -- se recupera
    { cad = { 19.2, 22.2 }, t1 = 18, t2 = 36,
      pl = tobillo(23.5, 0, 0, SUELO_L), pc = tobillo(15, 0, 12, SUELO_C),
      bl = { 68, 80, 105 }, bc = { 14, 28, 34 }, cabeza = "frente", cab_inc = 0.2, vai = 0 },
  }
end

local function poses_morir()
  local tendido = {
    cad = { 20.0, 34.0 }, t1 = -90, t2 = -90, cuello = -90,
    pl = { 35.0, 32.6, -82 }, pc = { 36.4, 35.8, -78 }, rod = { 0, -1 },
    bl = { -150, -82, -70 }, kbl = 0.72, bc = { 68, 96, 100 },
    cabeza = "tumbada", prof = { 0, -4.4 }, pelo = { -4, 1 }, tendido = true,
  }
  local con_charco = {}
  for k, v in pairs(tendido) do con_charco[k] = v end
  con_charco.charco = true
  return {
    -- el disparo le echa la cabeza atrás
    { cad = { 18.6, 21.6 }, t1 = -4, t2 = -16, cuello = -30,
      pl = tobillo(21.5, 0, 0, SUELO_L), pc = tobillo(15, 0, 0, SUELO_C),
      bl = { 95, 110, 120 }, bc = { 70, 95, 100 }, cabeza = "atras", vai = -1, pelo = { 0, 5 }, salpica = 1 },
    -- se le doblan las rodillas, cae de espaldas
    { cad = { 17.2, 23.5 }, t1 = -20, t2 = -36, cuello = -50,
      pl = tobillo(22, 1.5, -25, SUELO_L), pc = tobillo(15.5, 0, 0, SUELO_C),
      bl = { 120, 135, 140 }, bc = { 100, 120, 125 }, cabeza = "atras", vai = -1, pelo = { 1, 5 }, salpica = 2 },
    { cad = { 17.5, 28.5 }, t1 = -52, t2 = -64, cuello = -75,
      pl = tobillo(26, 3, -40, SUELO_L), pc = tobillo(22, 0, -20, SUELO_C), rod = { 1, -0.6 },
      bl = { 150, 160, 160 }, bc = { 125, 140, 140 }, cabeza = "atras", prof = { 1.0, -2.2 }, pelo = { 2, 4 } },
    -- golpea el suelo: piernas y brazos aún en el aire
    { cad = { 19.6, 33.6 }, t1 = -88, t2 = -86, cuello = -84,
      pl = { 32.5, 29.0, -60 }, pc = { 34.5, 33.6, -62 }, rod = { 0, -1 },
      bl = { 185, 210, 215 }, kbl = 0.9, bc = { 115, 100, 100 },
      cabeza = "tumbada", cab_dy = -1, prof = { 0, -4.4 }, pelo = { -3, -3 }, tendido = true },
    tendido,
    con_charco,
  }
end

---------------------------------------------------------------- montaje
-- Charco de sangre bajo la cabeza y los hombros (solo en el último fotograma).
local function charco(img)
  local c = capa()
  L.elipse(c, 8.5, 35.0, 8.2, 3.6, SANGRE[2])
  L.elipse(c, 15, 37.6, 6.5, 1.9, SANGRE[2])
  L.elipse(c, 4.5, 37.0, 3.6, 1.6, SANGRE[2])
  L.elipse(c, 12, 31.6, 4.0, 1.5, SANGRE[2])
  local o = mascara(c)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if o(x, y) then
      if not o(x - 1, y) or not o(x, y - 1) then c:drawPixel(x, y, SANGRE[3])
      elseif not o(x + 1, y) or not o(x, y + 1) then c:drawPixel(x, y, SANGRE[1]) end
    end
  end end
  L.pegar(img, c, 0, 0)
end

local function fotograma(figura, V, p)
  return function(img)
    if p.charco then charco(img) end
    local c = capa()
    local s = esqueleto(p, V)
    figura(c, s, p)
    contornear(c, { suelo = 38 })
    L.pegar(img, c, 0, 0)
  end
end

-- variante: "a" extiende el brazo lejano y le cuelga el cercano; "b" al revés.
local function construir(nombre, figura, V, variante)
  local fot = {}
  for _, p in ipairs(poses_andar()) do
    if variante == "b" then p.bc, p.bl = p.ext, p.col; p.t2 = p.t2 - 5
    else p.bl, p.bc = p.ext, p.col end
    fot[#fot + 1] = fotograma(figura, V, p)
  end
  for _, p in ipairs(poses_atacar()) do fot[#fot + 1] = fotograma(figura, V, p) end
  for _, p in ipairs(poses_morir()) do fot[#fot + 1] = fotograma(figura, V, p) end
  L.construir(nombre, W, H, fot,
    { { "andar", 1, 8 }, { "atacar", 9, 12 }, { "morir", 13, 18 } },
    { 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.12, 0.08, 0.10, 0.14, 0.09, 0.09, 0.11, 0.13, 0.16, 1.0 },
    { pies = { 20, 38 } })
end

construir("zombi", figura_a, VA, "a")
construir("zombi_b", figura_b, VB, "b")
