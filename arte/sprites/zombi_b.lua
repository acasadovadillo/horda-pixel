-- zombi_b.lua — la mujer del vestido mostaza (40x40), en 5 direcciones (s, se, e, ne, n).
-- Construcción por anatomía: cada fotograma parte de un esqueleto (articulaciones) y se viste
-- por capas de atrás adelante; luego contorno selectivo y retoques a mano.
local L = dofile(app.params.lib)
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


---------------------------------------------------------------- 8 direcciones: esqueleto 3D proyectado
-- Para s, se, ne y n la misma pose se monta en 3D y se proyecta.
-- Cuerpo: r = lateral (+ = su derecha), f = hacia delante, u = altura sobre la suela.
-- Mundo: x = este (derecha de la pantalla), y = sur (hacia la cámara).
local VISTAS = {
  s  = { F = { 0, 1 },            R = { -1, 0 } },
  se = { F = { 0.7071, 0.7071 },  R = { -0.7071, 0.7071 } },
  ne = { F = { 0.7071, -0.7071 }, R = { 0.7071, 0.7071 } },
  n  = { F = { 0, -1 },           R = { 1, 0 } },
}
local KY = 0.3            -- la profundidad del suelo se aplasta en pantalla

local function v3(a, b, k) return { a[1] + b[1] * (k or 1), a[2] + b[2] * (k or 1), a[3] + b[3] * (k or 1) } end
local function dif(a, b) return { b[1] - a[1], b[2] - a[2], b[3] - a[3] } end
local function lon(a) return sqrt(a[1] * a[1] + a[2] * a[2] + a[3] * a[3]) end
local function nor(a) local l = lon(a); if l < 1e-6 then return { 0, 0, -1 } end return { a[1] / l, a[2] / l, a[3] / l } end
local function pe(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
local function mezcla(a, b, t) return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t } end

-- Proyección: punto de pantalla y profundidad (mayor = más cerca de la cámara).
local function proy(v, q)
  local wx = q[1] * v.R[1] + q[2] * v.F[1]
  local wy = q[1] * v.R[2] + q[2] * v.F[2]
  local ky = KY + 0.22 * max(0, min(1, q[3] / 14))   -- el cuerpo se ve algo más inclinado que el suelo
  return { 20 + wx, 38 - q[3] + wy * ky }, wy
end

-- IK de dos huesos en 3D; doblez = hacia dónde sale la articulación.
local function ik3(a, b, l1, l2, doblez)
  local d = dif(a, b)
  local l = lon(d)
  if l >= l1 + l2 - 0.01 or l < 0.01 then return mezcla(a, b, l1 / (l1 + l2)) end
  local n = { d[1] / l, d[2] / l, d[3] / l }
  local q = (l1 * l1 - l2 * l2 + l * l) / (2 * l)
  local h = sqrt(max(0, l1 * l1 - q * q))
  local pd = nor(v3(doblez, n, -pe(doblez, n)))
  return v3(v3(a, n, q), pd, h)
end

-- dirección de un hueso a partir del ángulo de perfil (0 abajo, 90 delante, 180 arriba) y un lateral
local function dir3(ang, lat) return nor({ lat or 0, sin(rad(ang)), -cos(rad(ang)) }) end

local V3 = { cadera = 1.7, hombro = 3.0 }

local function esqueleto3(p, V)
  local w = {}
  local lat = p.lat or 0
  w.cad = { lat * 0.4, p.cad[1] - 20, 38 - p.cad[2] }
  w.cin = v3(w.cad, { lat * 0.3 / V.lumbar, sin(rad(p.t1)), cos(rad(p.t1)) }, V.lumbar)
  w.cue = v3(w.cin, { lat * 0.4 / V.torax, sin(rad(p.t2)), cos(rad(p.t2)) }, V.torax)
  local esp = nor(dif(w.cin, w.cue))
  w.hom = v3(w.cue, esp, -1.0)
  local cu = p.cuello or (p.t2 + 12)
  w.cab = v3(w.cue, { (p.lad or 0) * 0.4, sin(rad(cu)), cos(rad(cu)) }, V.cuello)
  w.hom_d = v3(w.hom, { V3.hombro, 0, p.hd or 0 })
  w.hom_i = v3(w.hom, { -V3.hombro, 0, p.hi or 0 })
  w.cad_d = v3(w.cad, { V3.cadera, 0, 0 })
  w.cad_i = v3(w.cad, { -V3.cadera, 0, 0 })
  w.tob_d = { V3.cadera + (p.abre or 0.2), p.pd[1], p.pd[2] }
  w.tob_i = { -V3.cadera - (p.abre or 0.2), p.pi[1], p.pi[2] }
  w.inc_d, w.inc_i = p.pd[3] or 0, p.pi[3] or 0
  w.rod_d = ik3(w.cad_d, w.tob_d, V.muslo, V.pierna, { 0.15, 1, 0 })
  w.rod_i = ik3(w.cad_i, w.tob_i, V.muslo, V.pierna, { -0.15, 1, 0 })
  -- brazos: { ángulo brazo, antebrazo, mano }, lat = hacia dentro (+) o fuera (-)
  local function brazo(h, b, lt, lado, k)
    k = k or 1
    local c1 = v3(h, dir3(b[1], -lado * lt[1]), V.brazo * k)
    local m = v3(c1, dir3(b[2], -lado * lt[2]), V.antebrazo * k)
    local d = v3(m, dir3(b[3] or b[2], -lado * (lt[3] or lt[2])), V.mano)
    return c1, m, d
  end
  local kl = p.kl or 1
  local function k2(t) return { t[1], t[2] * kl, (t[3] or t[2]) * kl } end
  w.cod_d, w.mun_d, w.ded_d = brazo(w.hom_d, p.bd, k2(p.ld or { -0.15, 0.6 }), 1)
  w.cod_i, w.mun_i, w.ded_i = brazo(w.hom_i, p.bi, k2(p.li or { -0.1, 0.0 }), -1)
  return w
end

local function proyectar(v, w)
  local s, d, f = {}, {}, {}
  for k, q in pairs(w) do
    if type(q) == "table" then
      local pt, dd = proy(v, q)
      f[k] = pt
      s[k] = { floor(pt[1]) + 0.5, floor(pt[2]) + 0.5 }
      d[k] = dd
    end
  end
  s.f, s.d, s.w = f, d, w
  -- ningún pie baja de la fila 38: si la proyección lo saca, se sube ese tobillo
  for _, lado in ipairs({ "d", "i" }) do
    local k = "tob_" .. lado
    local baja = f[k][2] + 1.0 - 38.5
    if baja > 0 then
      f[k] = { f[k][1], f[k][2] - baja }
      s[k] = { floor(f[k][1]) + 0.5, floor(f[k][2]) + 0.5 }
    end
  end
  return s
end

-- Sombreado de volumen: tono por posición en la fila (luz a la izquierda, sombra a la derecha)
-- más el borde de luz arriba-izquierda y de sombra abajo-derecha.
local function volumen(c, r, base, op)
  op = op or {}
  local o = mascara(c)
  local claro, oscuro = op.claro or 0.3, op.oscuro or 0.68
  for y = 0, H - 1 do
    local x = 0
    while x < W do
      if o(x, y) then
        local x0 = x
        while x < W and o(x, y) do x = x + 1 end
        local x1 = x - 1
        local n = x1 - x0 + 1
        for xx = x0, x1 do
          local t = (xx - x0 + 0.5) / n
          local k = base
          if n >= 4 and t < claro then k = k + 1 elseif n >= 3 and t > oscuro then k = k - 1 end
          if not o(xx, y - 1) and t < 0.75 then k = k + 1 end
          if not o(xx, y + 1) or not o(xx + 1, y) then k = k - 1 end
          k = max(1, min(#r, k))
          c:drawPixel(xx, y, r[k])
        end
      else
        x = x + 1
      end
    end
  end
end

-- Puntos de una sección horizontal elíptica (a = semiancho lateral, b = semifondo) proyectada.
local function seccion(v, cen, a, b, pts)
  for k = 0, 15 do
    local t = k * math.pi / 8
    local q = { cen[1] + cos(t) * a, cen[2] + sin(t) * b, cen[3] }
    pts[#pts + 1] = (proy(v, q))
  end
  return pts
end

local function envolver(c, pts) L.poligono(c, casco(pts), MARCA) end

-- Pie visto desde cualquier dirección. Plano: sello a mano por vista; inclinado: tobillo -> puntera.
local PIES8 = {
  s  = { zapato = { "bcc", "fef" },   descalzo = { "LSD", "SDd" } },
  n  = { zapato = { "bcc", "fff" },   descalzo = { "SSD", "dDd" } },
  se = { zapato = { "bcc.", "fffe" }, descalzo = { "LSS.", "dDDS" } },
  ne = { zapato = { ".bcc", "fffe" }, descalzo = { ".LSS", "dDDd" } },
}
local function pie3(dst, v, nom, s, lado, tipo)
  local w = s.w
  local t = w["tob_" .. lado]
  local inc = w["inc_" .. lado]
  local ta = s.f["tob_" .. lado]
  local c = capa()
  if abs(inc) < 7 then
    local filas = PIES8[nom][tipo]
    sello(c, filas, MAPA_PIE, ta[1], min(37, floor(ta[2])) + 1, { 1, #filas - 1 })
    pegar(dst, c)
    return
  end
  local ca, sa = cos(rad(inc)), sin(rad(inc))
  local q0 = v3(t, { 0, -0.6 * ca, -0.9 })
  local q1 = v3(t, { 0, 3.0 * ca, -0.9 - 3.0 * sa })
  local a, b = proy(v, q0), proy(v, q1)
  local t0 = proy(v, t)
  local ox, oy = ta[1] - t0[1], ta[2] - t0[2]
  a = { a[1] + ox, a[2] + oy }; b = { b[1] + ox, b[2] + oy }
  local g = 2.0 + (1 - abs(v.F[1])) * 0.6
  L.grueso(c, a[1], a[2], b[1], b[2], g, MARCA)
  if tipo == "zapato" then
    sombrear(c, CUERO, 3)
    local o = mascara(c)
    for y = 0, H - 1 do for x = 0, W - 1 do
      if o(x, y) and not o(x, y + 1) then c:drawPixel(x, y, CUERO[1]) end
    end end
  else
    sombrear(c, PIEL, 4, { ds = -1 })
  end
  pegar(dst, c)
end

---------------------------------------------------------------- cabezas de las otras direcciones
local CAB8 = {
  s = { ancla = { 3, 5 }, filas = {
    ".hhhHH.",
    "hhLSSHH",
    "hdoSodH",
    "hSSdSDH",
    "HdbKbdH",
    ".HdMdH.",
  } },
  s_abierta = { ancla = { 3, 5 }, filas = {
    ".hhhHH.",
    "hhLSSHH",
    "hdoSodH",
    "hSSdSDH",
    "HdKKKdH",
    ".HbMbH.",
    "..dmd..",
  } },
  se = { ancla = { 3, 5 }, filas = {
    ".hhHH.",
    "hhHLSL",
    "hHdoSo",
    "HHSSdS",
    "HHdbKM",
    ".HHdM.",
  } },
  se_abierta = { ancla = { 3, 5 }, filas = {
    ".hhHH.",
    "hhHLSL",
    "hHdoSo",
    "HHSSdS",
    "HHdKKK",
    ".HHbMm",
    "...dM.",
  } },
  ne = { ancla = { 2, 5 }, filas = {
    "..hhH.",
    ".phhHH",
    "phhHHk",
    "hhHHkS",
    "hHHHkD",
    ".HHkd.",
  } },
  n = { ancla = { 3, 5 }, filas = {
    "..phH..",
    ".phhHH.",
    "phhHHHk",
    "hhHHHkk",
    "hHHHkHk",
    ".HHkHk.",
  } },
}

---------------------------------------------------------------- figura B en 3D
local function figura_b3(img, v, nom, s, p)
  local partes = {}
  local function pon_parte(d, f) partes[#partes + 1] = { d = d, f = f, i = #partes } end
  local w, d = s.w, s.d
  local frente = (nom == "s" or nom == "se")

  -- piernas (siempre detrás de la falda)
  local function pierna(lado)
    local izq = s["rod_" .. lado][1] < s.cad[1]
    local base = izq and 4 or 3
    pon_parte(-50 + d["rod_" .. lado], function()
      parte(img, PIEL, base, { ds = 0 }, function(c)
        miembro2(c, s["cad_" .. lado], s["rod_" .. lado], s["tob_" .. lado], 3, 2, 2)
      end)
      if lado == "d" and nom ~= "n" then
        raya(img, loc(s.rod_d, s.tob_d, 0.5, 0.4), loc(s.rod_d, s.tob_d, 0.7, 0.4), CARNE[2])
      end
      pie3(img, v, nom, s, lado, lado == "i" and "zapato" or "descalzo")
    end)
  end
  pierna("d"); pierna("i")

  -- falda: envolvente de la cadera y los muslos hasta encima de la rodilla
  pon_parte(-40, function()
    parte(img, MOSTAZA, 3, nil, function(c)
      local pts = {}
      seccion(v, w.cin, 2.6, 1.7, pts)
      seccion(v, w.cad, 3.4, 2.2, pts)
      local kd, ki = mezcla(w.cad_d, w.rod_d, 0.68), mezcla(w.cad_i, w.rod_i, 0.68)
      seccion(v, kd, 1.9, 1.8, pts)
      seccion(v, ki, 1.9, 1.8, pts)
      envolver(c, pts)
      -- jirón que cuelga del bajo, del lado derecho (como en el perfil)
      local j = proy(v, v3(kd, { 0.6 - (p.vai or 0) * 0.4, 1.2, -1.6 }))
      pon(c, j)
    end)
  end)

  -- cuerpo del vestido
  pon_parte(0, function()
    local c = capa()
    local a = {}
    seccion(v, w.cad, 3.3, 2.3, a); seccion(v, w.cin, 2.6, 1.8, a)
    envolver(c, a)
    local b = {}
    seccion(v, w.cin, 2.6, 1.8, b); seccion(v, mezcla(w.cin, w.cue, 0.55), 3.4, 2.2, b)
    seccion(v, w.hom, 3.6, 1.8, b); seccion(v, w.cue, 2.0, 1.3, b)
    envolver(c, b)
    volumen(c, MOSTAZA, 3)
    pegar(img, c, { sin_oclusion = true })
    -- arruga en la cintura
    local cl = proy(v, v3(w.cin, { -2, 1.6, 0 }))
    local cr = proy(v, v3(w.cin, { 2, 1.6, 0 }))
    if frente then raya(img, cl, cr, MOSTAZA[2]) end
    if frente then
      -- reguero de sangre desde la boca por la pechera
      local a0 = proy(v, v3(w.cue, { 0.6, 2.0, -0.3 }))
      local a1 = proy(v, v3(w.cin, { 0.9, 2.4, 1.0 }))
      raya(img, a0, a1, SANGRE[2])
      sobre(img, a0, SANGRE[3])
      sobre(img, { a0[1] - 1, a0[2] }, SANGRE[2])
    else
      -- desgarrón en la espalda con piel a la vista
      local b0 = proy(v, v3(w.cin, { -0.8, -2.2, 2.2 }))
      local b1 = proy(v, v3(w.cin, { 0.6, -2.2, 0.8 }))
      raya(img, b0, b1, PIEL[3])
      sobre(img, { b1[1], b1[2] + 1 }, MOSTAZA[1])
    end
  end)

  -- cuello y cabeza
  pon_parte(0.5, function()
    parte(img, PIEL, 3, { sin_oclusion = true }, function(c) tira(c, s.hom, s.cab, 2, 2) end)
  end)
  local cabeza = CAB8[p.abierta and (nom .. "_abierta") or nom] or CAB8[nom]
  local hx, hy = s.cab[1] + (p.cab_dx or 0), s.cab[2] + (p.cab_dy or 0)
  pon_parte(1, function()
    local c = capa()
    sello(c, cabeza.filas, MAPA_CAB, hx, hy, cabeza.ancla, nom == "ne" and 0 or p.cab_inc)
    pegar(img, c)
  end)

  -- melena: masa que cae por la espalda (detrás en s y se, encima en n y ne)
  local raiz = v3(w.cab, { 0, -1.2, 1.8 })
  local punta = v3(w.hom, { -(p.vai or 0) * 0.8, -2.0, -1.4 })
  local dpelo = frente and -3 or 0.8
  pon_parte(dpelo, function()
    parte(img, PELO, 2, nil, function(c)
      local pr, pp = proy(v, raiz), proy(v, punta)
      -- ancho en pantalla de la melena según la vista
      local ga = 2 * sqrt((2.8 * v.R[1]) ^ 2 + (1.4 * v.F[1]) ^ 2)
      local gb = 2 * sqrt((2.0 * v.R[1]) ^ 2 + (1.0 * v.F[1]) ^ 2)
      cono(c, pr, pp, ga, gb)
    end)
  end)

  -- mechones que caen por delante de los hombros (s, se)
  if frente then
    pon_parte(0.9, function()
      local c = capa()
      local function mechon(lr, largo)
        local a = proy(v, v3(w.cab, { lr, 0.3, 2.0 }))
        local b = proy(v, v3(w.hom, { lr * 0.9 + (p.vai or 0) * 0.3, 0.8, -largo }))
        tira(c, a, b, 2, 1)
      end
      if nom == "s" then mechon(2.3, 0.2); mechon(-2.4, 2.0) else mechon(-2.2, 2.0) end
      sombrear(c, PELO, 2)
      pegar(img, c)
    end)
  end

  -- brazos
  local function brazo(lado)
    local der = lado == "d"
    local hom, cod, mun, ded = s["hom_" .. lado], s["cod_" .. lado], s["mun_" .. lado], s.f["ded_" .. lado]
    local dd = (d["cod_" .. lado] + d["mun_" .. lado]) / 2
    local izq = mun[1] < s.cue[1]
    local base = (izq or der) and 4 or 3
    pon_parte(dd, function()
      -- lo que se acerca a la cámara se ve más grueso
      local g = (d["mun_" .. lado] - d["hom_" .. lado] > 4.5) and 3 or 2
      parte(img, PIEL, base, { ds = 0 }, function(c) miembro2(c, hom, cod, mun, 2, 2, g) end)
      if der then raya(img, loc(cod, mun, 0.3, 0.3), loc(cod, mun, 0.55, 0.3), CARNE[2]) end
      mano(img, mun, ded, PIEL, base, p.garra)
      -- resto de manga corta (solo el brazo derecho, como en el perfil)
      if der then
        parte(img, MOSTAZA, 3, nil, function(c)
          tira(c, hom, loc(hom, cod, 0.25, 0), 2, 2)
        end)
      end
    end)
  end
  brazo("d"); brazo("i")

  table.sort(partes, function(a, b) if a.d ~= b.d then return a.d < b.d end return a.i < b.i end)
  for _, q in ipairs(partes) do q.f() end
end

---------------------------------------------------------------- poses 3D
-- Mismos números que poses_andar (variante b: brazo derecho extendido, izquierdo colgando).
local function poses3_andar()
  local t = {}
  local lx   = { 5, 3, 1, -1, -3, -1, 3, 6 }
  local lsub = { 0, 0, 0, 0, 0, 2.2, 2, 0.8 }
  local linc = { 0, 0, 0, 0, 32, 22, -8, -18 }
  local cx   = { -6, -5, -3, -1, 1, -1, -3, -5 }
  local cinc = { 38, 34, 28, 14, 0, 0, 0, 16 }
  local hy   = { 22.2, 22.6, 22.0, 21.4, 21.2, 21.0, 21.2, 21.7 }
  local hxs  = { 19.4, 19.6, 19.3, 19.0, 18.8, 18.8, 19.0, 19.2 }
  local t1   = { 14, 16, 13, 10, 8, 8, 10, 12 }
  local t2   = { 32, 36, 32, 27, 24, 23, 26, 30 }
  local ext  = { 80, 76, 73, 75, 79, 83, 85, 83 }
  local col1 = { -8, -2, 5, 10, 8, 2, -5, -10 }
  local col2 = { 4, 12, 20, 24, 18, 10, 2, -2 }
  local vai  = { 0, 1, 1, 0, 0, -1, -1, 0 }
  local inc  = { 0.2, 0.3, 0.3, 0.2, 0.1, 0.1, 0.1, 0.2 }
  for i = 1, 8 do
    local hx = hxs[i]
    -- altura del tobillo con la puntera arrastrando (cinc > 0: puntera abajo)
    local function alto(sub, a)
      if abs(a) < 7 then return 1 + sub end
      local sa, ca = sin(rad(abs(a))), cos(rad(abs(a)))
      return 1 + sub + (3.0 * sa) * (a > 0 and 1 or 0.25)
    end
    t[i] = {
      cad = { hx, hy[i] }, t1 = t1[i], t2 = t2[i] - 5,
      pi = { hx + lx[i] - 20, alto(lsub[i], linc[i]), linc[i] },
      pd = { hx + cx[i] - 20, alto(0, cinc[i]), cinc[i] },
      bd = { ext[i], ext[i] + 8, ext[i] + 40 },
      bi = { col1[i], col2[i], col2[i] + 5 },
      vai = vai[i], lat = vai[i] * 0.6, cab_inc = inc[i],
    }
  end
  return t
end

local function poses3_atacar()
  return {
    { cad = { 18.2, 21.6 }, t1 = -3, t2 = 2, cuello = -8,
      pi = { 1.5, 1, 0 }, pd = { -5.5, 1.5, 8 },
      bi = { 165, 200, 215 }, li = { 0.1, 0.1 }, bd = { -52, 38, 55 }, ld = { -0.2, 0.3 },
      abierta = true, cab_inc = 0, garra = true, vai = 1, lat = 0.5 },
    { cad = { 19.2, 22.3 }, t1 = 26, t2 = 44, cuello = 62,
      pi = { 5, 1, 0 }, pd = { -7, 2, 30 },
      bi = { 100, 92, 100 }, li = { -0.35, 0.05 }, bd = { 92, 84, 95 }, ld = { -0.35, 0.05 },
      abierta = true, cab_inc = 0.3, garra = true, vai = -1, lat = -0.4 },
    { cad = { 19.6, 22.7 }, t1 = 30, t2 = 54, cuello = 78,
      pi = { 5, 1, 0 }, pd = { -6, 2, 24 },
      bi = { 60, 46, 36 }, li = { -0.3, 0.0 }, bd = { 44, 30, 24 }, ld = { -0.25, 0.1 },
      cab_inc = 0.4, garra = true, vai = -1, lat = -0.4 },
    { cad = { 19.2, 22.2 }, t1 = 18, t2 = 36,
      pi = { 3.5, 1, 0 }, pd = { -5, 1.5, 12 },
      bi = { 14, 28, 34 }, li = { -0.1, 0 }, bd = { 68, 80, 105 }, ld = { 0.25, 0.35 },
      cab_inc = 0.2, vai = 0, lat = 0 },
  }
end

local KLAT = { s = 1, se = 0.8, ne = 0.15, n = 1 }   -- cuánto se cierran los antebrazos hacia el centro
local function fotograma3(nom, p)
  local v = VISTAS[nom]
  p.kl = KLAT[nom]
  if nom == "n" and p.garra then
    -- de espaldas, las garras quedan tapadas por el cuerpo: solo asoman los codos
    p.ld = { 0.25, 0.4 }; p.li = { 0.25, 0.4 }
    if p.bd[1] > 80 then
      p.bd = { p.bd[1] - 25, p.bd[2] - 25, p.bd[3] - 25 }
      p.bi = { p.bi[1] - 25, p.bi[2] - 25, p.bi[3] - 25 }
    end
  end
  return function(img)
    local c = capa()
    local s = proyectar(v, esqueleto3(p, VB))
    figura_b3(c, v, nom, s, p)
    contornear(c, { suelo = 38 })
    for x = 0, W - 1 do c:drawPixel(x, 39, 0) end
    L.pegar(img, c, 0, 0)
  end
end

---------------------------------------------------------------- montaje
local DIRS = { "s", "se", "e", "ne", "n" }
local fot, etq, dur = {}, {}, {}
local function anadir(nombre, lista, d)
  local a = #fot + 1
  for i, f in ipairs(lista) do fot[#fot + 1] = f; dur[#dur + 1] = type(d) == "table" and d[i] or d end
  etq[#etq + 1] = { nombre, a, #fot }
end

for _, nd in ipairs(DIRS) do
  local l = {}
  if nd == "e" then
    for _, p in ipairs(poses_andar()) do
      p.bc, p.bl = p.ext, p.col; p.t2 = p.t2 - 5
      l[#l + 1] = fotograma(figura_b, VB, p)
    end
  else
    for _, p in ipairs(poses3_andar()) do l[#l + 1] = fotograma3(nd, p) end
  end
  anadir("andar_" .. nd, l, 0.14)
end
for _, nd in ipairs(DIRS) do
  local l = {}
  if nd == "e" then
    for _, p in ipairs(poses_atacar()) do l[#l + 1] = fotograma(figura_b, VB, p) end
  else
    for _, p in ipairs(poses3_atacar()) do l[#l + 1] = fotograma3(nd, p) end
  end
  anadir("atacar_" .. nd, l, { 0.12, 0.08, 0.10, 0.14 })
end
do
  local l = {}
  for _, p in ipairs(poses_morir()) do l[#l + 1] = fotograma(figura_b, VB, p) end
  anadir("morir", l, { 0.09, 0.09, 0.11, 0.13, 0.16, 1.0 })
end

L.construir("zombi_b", W, H, fot, etq, dur, { pies = { 20, 38 } })
