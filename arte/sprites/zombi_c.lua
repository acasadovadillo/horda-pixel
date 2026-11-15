-- zombi_c.lua — construye `zombi_c` (40x40, pies en {20,38}) en 5 direcciones: s, se, e, ne y n (+ morir).
-- ENFOQUE HÍBRIDO POR PIEZAS: cabeza, torso, muslo, pierna, pie, brazo, antebrazo y mano son
-- mini-sprites dibujados a mano con filas de caracteres (variante vertical y variante tumbada,
-- más las variantes de cabeza y de pie). Cada fotograma se monta colocando las piezas sobre un
-- esqueleto sencillo (cadera, rodilla, tobillo, hombro, codo, muñeca) con desplazamientos por
-- fila o por columna; después se retocan las uniones y se añaden sombras de contacto.
-- Luz: arriba a la izquierda. Contorno: el tono oscuro de cada material, más marcado abajo/derecha.
local L = dofile(app.params.lib)
-- Este archivo solo construye la variante «zombi_c» (su zombi principal, con otro nombre).
do local c = L.construir; L.construir = function(n, ...) if n == "zombi" then c("zombi_c", ...) end end end
local floor, abs, max, min, sqrt = math.floor, math.abs, math.max, math.min, math.sqrt
local sin, cos, rad = math.sin, math.cos, math.rad
local function R(v) return floor(v + 0.5) end
local W, H = 40, 40

------------------------------------------------------------------ piezas y pintura
-- Pieza: filas de caracteres + punto de anclaje (columna, fila) contado desde 0.
local function P(filas, ax, ay, extra)
  local w = #filas[1]
  for i, f in ipairs(filas) do
    if #f ~= w then error("pieza: la fila " .. i .. " ('" .. f .. "') mide " .. #f .. " y debe medir " .. w) end
  end
  local p = { f = filas, w = w, h = #filas, ax = ax or 0, ay = ay or 0 }
  if extra then for k, v in pairs(extra) do p[k] = v end end
  return p
end

local function punto(img, x, y, ch, mapa)
  if ch == "." or ch == " " then return end
  local c = mapa[ch]
  if c == nil then error("carácter sin color en el mapa: '" .. ch .. "'") end
  L.px(img, x, y, c)
end

-- Pega una pieza con su ancla en (x, y). vx / vy = volteada en horizontal / vertical.
local function pegar(img, p, x, y, mapa, vx, vy)
  for j = 0, p.h - 1 do
    local f = p.f[j + 1]
    for i = 0, p.w - 1 do
      local px = vx and (x + p.ax - i) or (x - p.ax + i)
      local py = vy and (y + p.ay - j) or (y - p.ay + j)
      punto(img, px, py, f:sub(i + 1, i + 1), mapa)
    end
  end
end

-- Tramo de un miembro con la pieza VERTICAL: una fila de la pieza por cada fila de píxeles,
-- desplazada en x para seguir la línea entre las dos articulaciones.
local function tramoV(img, p, mapa, x0, y0, x1, y1, incl)
  local n = abs(y1 - y0)
  local m = n + (incl and 1 or 0)
  if m <= 0 then return end
  local sy = (y1 >= y0) and 1 or -1
  local gordo = n > 0 and abs(x1 - x0) / n > 0.45      -- en diagonal se repinta la fila anterior para no adelgazar
  local xa
  for j = 0, m - 1 do
    local src = (m > 1) and R(j * (p.h - 1) / (m - 1)) or 0
    local x = R(x0 + (x1 - x0) * ((n > 0) and (j / n) or 0))
    local f = p.f[src + 1]
    if gordo and xa and xa ~= x then
      for i = 0, p.w - 1 do punto(img, xa - p.ax + i, y0 + j * sy, f:sub(i + 1, i + 1), mapa) end
    end
    for i = 0, p.w - 1 do punto(img, x - p.ax + i, y0 + j * sy, f:sub(i + 1, i + 1), mapa) end
    xa = x
  end
end

-- Tramo con la pieza TUMBADA: una columna de la pieza por cada columna de píxeles.
local function tramoH(img, p, mapa, x0, y0, x1, y1, incl)
  local n = abs(x1 - x0)
  local m = n + (incl and 1 or 0)
  if m <= 0 then return end
  local sx = (x1 >= x0) and 1 or -1
  local gordo = n > 0 and abs(y1 - y0) / n > 0.45
  local ya
  for i = 0, m - 1 do
    local src = (m > 1) and R(i * (p.w - 1) / (m - 1)) or 0
    local y = R(y0 + (y1 - y0) * ((n > 0) and (i / n) or 0))
    if gordo and ya and ya ~= y then
      for j = 0, p.h - 1 do punto(img, x0 + i * sx, ya - p.ay + j, p.f[j + 1]:sub(src + 1, src + 1), mapa) end
    end
    for j = 0, p.h - 1 do punto(img, x0 + i * sx, y - p.ay + j, p.f[j + 1]:sub(src + 1, src + 1), mapa) end
    ya = y
  end
end

local function tramo(img, pv, ph, mapa, x0, y0, x1, y1, incl)
  if abs(y1 - y0) >= abs(x1 - x0) then tramoV(img, pv, mapa, x0, y0, x1, y1, incl)
  else tramoH(img, ph, mapa, x0, y0, x1, y1, incl) end
end

-- Rodilla o codo a partir de los dos extremos y las longitudes (dir = hacia dónde dobla).
local function doblar(hx, hy, ax, ay, l1, l2, dir)
  local dx, dy = ax - hx, ay - hy
  local d = sqrt(dx * dx + dy * dy)
  if d < 0.001 then return hx + l1 * dir, hy end
  if d >= l1 + l2 then
    local t = l1 / (l1 + l2)
    return hx + dx * t, hy + dy * t
  end
  local dd = max(d, abs(l1 - l2) + 0.01)
  local a = (l1 * l1 - l2 * l2 + dd * dd) / (2 * dd)
  local h = sqrt(max(0, l1 * l1 - a * a))
  local ux, uy = dx / d, dy / d
  return hx + ux * a + uy * dir * h, hy + uy * a - ux * dir * h
end

-- Dibuja en una capa aparte y la funde; opcionalmente oscurece un tono lo que queda justo
-- debajo o a la derecha de la capa (sombra de contacto, la luz viene de arriba a la izquierda).
-- prot = máscara de píxeles que el contorno automático no debe tocar (cabeza, dibujada a mano).
local function capa(img, C, prot, op, fn)
  local t = L.imagen(W, H)
  fn(t)
  local oscuro = C.oscuro
  for y = 0, H - 1 do for x = 0, W - 1 do
    if L.opaco(t, x, y) then
      prot[y * W + x] = op.fijo or nil
      if op.abajo and not L.opaco(t, x, y + 1) and L.opaco(img, x, y + 1) then
        local d = oscuro[L.get(img, x, y + 1)]
        if d then L.px(img, x, y + 1, d) end
      end
      if op.derecha and not L.opaco(t, x + 1, y) and L.opaco(img, x + 1, y) then
        local d = oscuro[L.get(img, x + 1, y)]
        if d then L.px(img, x + 1, y, d) end
      end
    end
  end end
  L.pegar(img, t, 0, 0)
end

-- Contorno selectivo dentro de la silueta: el borde de abajo y de la derecha toma el tono más
-- oscuro de su propio material; el de arriba y la izquierda se queda con su tono de luz.
local function contornoSelectivo(img, C, prot)
  local cambios = {}
  for y = 0, H - 1 do for x = 0, W - 1 do
    if L.opaco(img, x, y) and not prot[y * W + x] then
      if not L.opaco(img, x + 1, y) or not L.opaco(img, x, y + 1) then
        local f = C.fondo[L.get(img, x, y)]
        if f then cambios[#cambios + 1] = { x, y, f } end
      end
    end
  end end
  for _, c in ipairs(cambios) do L.px(img, c[1], c[2], c[3]) end
end

------------------------------------------------------------------ colores
local function hexes(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local SANGRE, CARNE, TINTA = L.rampa("sangre"), L.rampa("carne"), L.rampa("tinta")

local pc = app.pixelColor
local function mezcla(c1, c2, k)   -- k = cuánto de c2
  local function m(a, b) return R(a + (b - a) * k) end
  return pc.rgba(m(pc.rgbaR(c1), pc.rgbaR(c2)), m(pc.rgbaG(c1), pc.rgbaG(c2)), m(pc.rgbaB(c1), pc.rgbaB(c2)), 255)
end
-- Rampa para el lado lejano del cuerpo: cada tono a medio camino del anterior.
local function rampaLejos(r)
  local t = {}
  for i = 1, #r do t[i] = (i == 1) and mezcla(r[1], TINTA[2], 0.35) or mezcla(r[i], r[i - 1], 0.65) end
  return t
end

-- def = { piel, ropa, pant, pelo, zapato } (rampas de oscuro a claro).
local function crearMapa(def, lejos)
  local m = {}
  local rampas = {}
  local function pon(chars, r)
    if lejos then r = rampaLejos(r) end
    rampas[#rampas + 1] = r
    for i = 1, #chars do m[chars:sub(i, i)] = r[min(i, #r)] end
  end
  pon("12345", def.piel); pon("abcd", def.ropa); pon("wxyz", def.pant)
  pon("hijl", def.pelo); pon("mnopq", def.zapato)
  m.S = SANGRE[1]; m.s = SANGRE[2]; m.T = SANGRE[3]; m.U = SANGRE[4]
  m.r = CARNE[2]; m.R = CARNE[3]; m.Q = CARNE[4]
  m.K = TINTA[1]; m.k = TINTA[2]; m.G = TINTA[3]
  m.e = def.ojo; m.t = def.diente; m.E = def.piel[1]
  return m, rampas
end

-- oscuro[c] = un tono menos de la misma rampa · fondo[c] = el tono más oscuro de su rampa
local function crearTonos(listas)
  local o, f = {}, {}
  for _, r in ipairs(listas) do
    for i = 1, #r do
      if i > 1 then o[r[i]] = r[i - 1] end
      f[r[i]] = r[1]
    end
  end
  return o, f
end

local function prepararColores(C, def)
  local r1, r2
  C.mapa, r1 = crearMapa(def, false)
  C.lejos, r2 = crearMapa(def, true)
  local listas = { CARNE, SANGRE }
  for _, r in ipairs(r1) do listas[#listas + 1] = r end
  for _, r in ipairs(r2) do listas[#listas + 1] = r end
  C.oscuro, C.fondo = crearTonos(listas)
end

------------------------------------------------------------------ montaje de la figura
-- Brazo: hombro -> codo -> muñeca por ángulos (0 = colgando, 90 = al frente, 180 = arriba).
-- Devuelve cómo pegar la mano (se pinta aparte para que el contorno automático no la toque).
local function brazo(img, B, mapa, sx, sy, a1, a2, lu, lf)
  local ex, ey = sx + lu * sin(rad(a1)), sy + lu * cos(rad(a1))
  local wx, wy = ex + lf * sin(rad(a2)), ey + lf * cos(rad(a2))
  ex, ey, wx, wy = R(ex), R(ey), R(wx), R(wy)
  tramo(img, B.upV, B.upH, mapa, sx, sy, ex, ey, false)
  tramo(img, B.foV, B.foH, mapa, ex, ey, wx, wy, true)
  if B.hombrera and abs(ey - sy) >= abs(ex - sx) and ey > sy then pegar(img, B.hombrera, sx, sy, mapa) end
  local dx, dy = wx - ex, wy - ey
  if abs(dy) >= abs(dx) then
    if dy >= 0 then return { B.manoV, wx, wy + 1, false, false } else return { B.manoV, wx, wy - 1, false, true } end
  else
    if dx >= 0 then return { B.manoH, wx + 1, wy, false, false } else return { B.manoH, wx - 1, wy, true, false } end
  end
end

-- Pierna: cadera -> rodilla -> tobillo; la rodilla sale de las longitudes (dobla hacia delante).
local function pierna(img, Pn, mapa, hx, hy, obj, l1, l2)
  local ax, ay = obj[1], obj[2]
  local kx, ky
  if obj.recta then kx, ky = hx + (ax - hx) * l1 / (l1 + l2), hy + (ay - hy) * l1 / (l1 + l2)
  else kx, ky = doblar(hx, hy, ax, ay, l1, l2, obj.dir or 1) end
  kx, ky = R(kx), R(ky)
  tramo(img, Pn.musloV, Pn.musloH, mapa, hx, hy, kx, ky, false)
  tramo(img, Pn.pantV, Pn.pantH, mapa, kx, ky, ax, ay, true)
  local pie = Pn.pies[obj[3]]
  if not pie then error("pie desconocido: " .. tostring(obj[3])) end
  return { pie, ax, ay, false, false }
end

local function figura(img, C, q, ctx)
  local mapa, lejos = C.mapa, C.lejos
  local prot = {}
  local hx, hy = q.hip[1], q.hip[2] + (C.dy or 0) * ((q.torso == "H") and 0 or 1)
  local tumbado = (q.torso == "H")
  local T = C.torso[q.torso]
  local off, pt
  if tumbado then
    off = function(col) return -R((q.rise or 0) * (T.hip[1] - col) / T.hip[1]) end
    pt = function(c) return hx - T.hip[1] + c[1], hy - T.hip[2] + c[2] + off(c[1]) end
  else
    off = function(row)
      local t = max(0, (T.hip[2] - row) / T.hip[2])
      return R((q.lean or 0) * t)
    end
    pt = function(c) return hx - T.hip[1] + c[1] + off(c[2]), hy - T.hip[2] + c[2] end
  end
  local nx, ny = pt(T.cuello)
  local snx, sny = pt(T.hombroN)
  local sfx, sfy = pt(T.hombroF)
  local hfx, hfy = hx + 1, hy
  if tumbado then hfx, hfy = hx + 1, hy - 3 end
  local cab = C.cabeza[q.cab[1]]
  local cx, cy
  if tumbado then cx, cy = nx - 1 + (q.cab[2] or 0), ny + (q.cab[3] or 0)
  else cx, cy = nx + (q.cab[2] or 0), ny - 2 + (q.cab[3] or 0) end
  local a = { cx = cx, cy = cy, nx = nx, ny = ny, hx = hx, hy = hy, tumbado = tumbado }
  if not img then return a end

  local function fijo(pz, m)   -- manos y pies: dibujados a mano con su contorno
    capa(img, C, prot, { fijo = true }, function(t) pegar(t, pz[1], pz[2], pz[3], m, pz[4], pz[5]) end)
  end

  if q.antes then q.antes(img, C, q, a) end
  -- 1. brazo y pierna del lado lejano (más oscuros)
  local pz
  capa(img, C, prot, {}, function(t) pz = brazo(t, C.brazoF, lejos, sfx, sfy, q.bf[1], q.bf[2], C.lu, C.lf) end)
  fijo(pz, lejos)
  capa(img, C, prot, {}, function(t) pz = pierna(t, C.piernaF, lejos, hfx, hfy, q.pf, C.l1, C.l2) end)
  fijo(pz, lejos)
  -- 2. pelvis (une los dos muslos bajo la ropa) y pierna cercana
  if not tumbado then L.rect(img, hx - 1, hy - 1, 5, 4, mapa.x) end
  capa(img, C, prot, { derecha = true }, function(t) pz = pierna(t, C.piernaN, mapa, hx, hy, q.pn, C.l1, C.l2) end)
  fijo(pz, mapa)
  -- 3. cuello y torso
  if not tumbado then
    L.px(img, nx - 1, ny - 1, mapa["3"]); L.px(img, nx, ny - 1, mapa["2"]); L.px(img, nx + 1, ny - 1, mapa["1"])
    L.px(img, nx, ny - 2, mapa["2"]); L.px(img, nx + 1, ny - 2, mapa["1"])
  end
  capa(img, C, prot, { abajo = not tumbado }, function(t)
    if tumbado then
      for c = 0, T.w - 1 do
        for j = 0, T.h - 1 do
          punto(t, hx - T.hip[1] + c, hy - T.hip[2] + j + off(c), T.f[j + 1]:sub(c + 1, c + 1), mapa)
        end
      end
    else
      for j = 0, T.h - 1 do
        local f = T.f[j + 1]
        for c = 0, T.w - 1 do punto(t, hx - T.hip[1] + c + off(j), hy - T.hip[2] + j, f:sub(c + 1, c + 1), mapa) end
      end
    end
  end)
  -- 4. melena (si la hay) y cabeza, dibujadas a mano con su contorno
  if C.melena then capa(img, C, prot, { fijo = true }, function(t) C.melena(t, C, q, a, ctx) end) end
  capa(img, C, prot, { abajo = not tumbado, fijo = true }, function(t) pegar(t, cab, cx, cy, mapa) end)
  -- 5. brazo cercano
  capa(img, C, prot, { derecha = not tumbado, abajo = (q.bn[1] > 45 and not tumbado) }, function(t)
    pz = brazo(t, C.brazoN, mapa, snx, sny, q.bn[1], q.bn[2], C.lu, C.lf)
  end)
  fijo(pz, mapa)
  -- 6. contorno selectivo y retoques del fotograma
  contornoSelectivo(img, C, prot)
  if q.extra then q.extra(img, C, q, a) end
  -- aviso si algo toca el borde del lienzo
  for y = 0, H - 1 do for x = 0, W - 1 do
    if L.opaco(img, x, y) and (x == W - 1 or y == 0 or (y == H - 1 and not q.antes)) then
      print("  AVISO " .. ctx.nombre .. " fotograma " .. ctx.k .. ": píxel en el borde (" .. x .. "," .. y .. ")")
      return a
    end
  end end
  return a
end

------------------------------------------------------------------ PIEZAS DEL ZOMBI (hombre)
-- Caracteres: 1-5 piel · a-d ropa de arriba · w-z pantalón · h,i,j,l pelo · m-q cuero
--             S,s,T,U sangre · r,R,Q carne · K,k,G tinta · e ojo · E cuenca · t diente
local Z = { l1 = 7.7, l2 = 6.9, lu = 5, lf = 5 }

Z.cabeza = {
  up = P({
    ".jlji.",
    "jlji4.",
    "iji4E4",
    "hi3435",
    ".h33Rr",
    "..232.",
  }, 2, 5),
  lol = P({
    "..jlj.",
    ".jllji",
    "ijji44",
    "hi3Ee3",
    ".h3343",
    "..23Rr",
  }, 2, 5),
  atras = P({
    "...44.",
    ".j4Ee4",
    "jl4335",
    "ijh3RR",
    "hih32.",
    ".hh2..",
  }, 3, 4),
  tumbada = P({
    "..345.",
    ".j4E4R",
    "jl4334",
    "ijh323",
    "hiih22",
    ".hhh..",
  }, 5, 3),
}

Z.torso = {
  -- encorvado: la postura de andar, con la espalda redondeada dibujada a mano
  enc = P({
    "......cddc.",
    ".....cdddcb",
    "....cdddcba",
    "...cddccba.",
    "...cdccbsa.",
    "..cdccbssa.",
    "..cccbbSa..",
    ".cdccbba...",
    ".ccbbbba...",
    ".c33bba....",
    "cdaabba....",
    "cccbbba....",
    "cb.bb.a....",
  }, 0, 0, { hip = { 2, 11 }, cuello = { 7, 0 }, hombroN = { 6, 2 }, hombroF = { 8, 2 } }),
  recto = P({
    "..cddc.",
    ".cdddcb",
    "cdddcba",
    "cddccsa",
    "cdccssa",
    "cdcbbSa",
    "ccccbba",
    ".cdcbba",
    ".ccbbba",
    ".33bba.",
    "caabbba",
    "cccbbba",
    "cb.bb.a",
  }, 0, 0, { hip = { 2, 11 }, cuello = { 3, 0 }, hombroN = { 2, 2 }, hombroF = { 4, 2 } }),
  -- tumbado boca arriba: plano del pecho arriba (iluminado) y costado cercano abajo (en sombra)
  H = P({
    "..cccc.......",
    ".cddddccccc..",
    "cdddcdccccccc",
    "cddcsscccccbc",
    "cdccsSccbccbb",
    "cccccccbbbbbb",
    "bbbbbbbbbbbba",
    ".aaaaaaaaaaa.",
  }, 0, 0, { hip = { 11, 5 }, cuello = { 0, 3 }, hombroN = { 2, 6 }, hombroF = { 2, 1 } }),
}

local musloV = P({ "yzyx", "yzyx", "zzyx", "zyyw", "zyxw", "yzyw", "yyxw", "yzxw" }, 1, 0)
local musloH = P({ "yzzzyzzy", "zyyzyyyy", "yxyxxyxx", "xwwwwxww" }, 0, 1)
local pantH = P({ "zzyzz..", "yzyyyzy", "xyxxyxx", "wwwwwww" }, 0, 1)

Z.piernaN = {     -- pierna cercana: bajo del vaquero roto, pie descalzo
  musloV = musloV, musloH = musloH, pantH = pantH,
  pantV = P({ "yzyw", "zyyw", "zyxw", ".zyw", ".zxw", ".y.w", ".431" }, 1, 0),
  pies = {
    plano = P({ ".443..", "223431" }, 1, -1),
    punta = P({ ".43...", ".243..", "..2331" }, 1, -1),
    arrastra = P({ ".43.", ".42.", "231." }, 1, -1),
    tumbado = P({ "43", "44", "33", "21" }, -1, 2),
  },
}
Z.piernaF = {     -- pierna lejana: con zapato
  musloV = musloV, musloH = musloH, pantH = pantH,
  pantV = P({ "yzyw", "zyyw", "zyxw", ".zyw", ".zxw", ".yxw", ".yxw" }, 1, 0),
  pies = {
    plano = P({ ".pon...", ".ppoon.", "mmmmmmm" }, 1, 0),
    punta = P({ ".pon..", "mppoo.", ".mmnnm" }, 1, 0),
    alza = P({ ".po.on.", ".ppoomm", "mmmmm.." }, 1, 0),
    tumbado = P({ "po.", "pom", "oom", "onm", "nmm" }, -1, 3),
  },
}
Z.piernaF.pies.arrastra = Z.piernaF.pies.punta

Z.brazoN = {      -- brazo cercano: manga arrancada, piel al aire y un mordisco
  upV = P({ "443", "543", "542", "432", "432", "431" }, 1, 0),
  upH = P({ "445444", "334333", "122221" }, 0, 1),
  foV = P({ "432", "4R2", "4r1", ".31", ".31" }, 1, 0),
  foH = P({ "44544", "3R332", "2221." }, 0, 1),
  manoV = P({ "442", "431", "3.1" }, 1, 0),
  manoH = P({ "444.", "3342", "1.1." }, 0, 1),
  hombrera = P({ ".dd.", "cddc", "c..a" }, 1, 1),
}
Z.brazoF = {      -- brazo lejano: manga hasta el codo
  upV = P({ "dcb", "dcb", "dca", "cba", "cba", "c.a" }, 1, 0),
  upH = P({ "ddcddc", "cccbcb", "abbaa." }, 0, 1),
  foV = P({ "432", "432", "431", ".31", ".31" }, 1, 0),
  foH = P({ "44544", "33332", "2221." }, 0, 1),
  manoV = Z.brazoN.manoV, manoH = Z.brazoN.manoH,
}

prepararColores(Z, {
  piel = L.rampa("zombi"), ropa = L.rampa("ropa_a"), pant = L.rampa("vaquero"),
  pelo = L.rampa("pelo"), zapato = L.rampa("cuero"),
  ojo = L.hex("c4c8ba"), diente = L.hex("aeab9f"),
})

------------------------------------------------------------------ POSES
local CHARCO = P({
  "......sssss.......",
  "...sssTTTssss.....",
  ".ssTTTTTTTsssss...",
  "ssTTUUTTTTTssssss.",
  "sTTUTTTTTTTsssssss",
  "sTTTTTTTTsssssssss",
  ".sTTTTTsssssssss..",
  "..sssssssssssS....",
  "....sSSsss........",
}, 0, 0)

local function salpicadura(img, C, q, a)
  local m = C.mapa
  L.px(img, a.cx - 4, a.cy - 3, m.R); L.px(img, a.cx - 5, a.cy - 4, m.R)
  L.px(img, a.cx - 6, a.cy - 2, m.r); L.px(img, a.cx - 5, a.cy - 1, m.T)
  L.px(img, a.cx - 7, a.cy - 5, m.T)
end
local function charco(img, C) pegar(img, CHARCO, 0, 31, C.mapa) end

local ANDAR = {
  { torso = "enc", hip = { 18, 23 }, lean = 0,  cab = { "lol", 1, 1 }, pn = { 12, 36, "plano" },    pf = { 24, 36, "plano" }, bn = { 8, 18 },  bf = { 66, 98 } },
  { torso = "enc", hip = { 18, 23 }, lean = 1,  cab = { "lol", 1, 2 }, pn = { 11, 35, "punta" },    pf = { 23, 36, "plano" }, bn = { 14, 28 }, bf = { 62, 94 } },
  { torso = "enc", hip = { 18, 22 }, lean = 1,  cab = { "lol", 1, 2 }, pn = { 12, 35, "arrastra" }, pf = { 22, 36, "plano" }, bn = { 16, 34 }, bf = { 60, 96 } },
  { torso = "enc", hip = { 17, 22 }, lean = 0,  cab = { "lol", 1, 1 }, pn = { 14, 35, "arrastra" }, pf = { 21, 36, "plano" }, bn = { 12, 26 }, bf = { 64, 100 } },
  { torso = "enc", hip = { 17, 22 }, lean = 0,  cab = { "lol", 1, 1 }, pn = { 16, 36, "plano" },    pf = { 20, 36, "plano" }, bn = { 6, 16 },  bf = { 68, 102 } },
  { torso = "enc", hip = { 17, 22 }, lean = 0,  cab = { "lol", 1, 1 }, pn = { 15, 36, "plano" },    pf = { 19, 35, "punta" }, bn = { 0, 8 },   bf = { 70, 102 } },
  { torso = "enc", hip = { 17, 22 }, lean = -1, cab = { "lol", 1, 1 }, pn = { 14, 36, "plano" },    pf = { 21, 34, "plano" }, bn = { -4, 4 },  bf = { 72, 100 } },
  { torso = "enc", hip = { 18, 23 }, lean = 0,  cab = { "lol", 1, 1 }, pn = { 13, 36, "plano" },    pf = { 24, 35, "alza" },  bn = { 2, 10 },  bf = { 70, 98 } },
}
local ATACAR = {
  { torso = "recto", hip = { 16, 22 }, lean = -1, cab = { "up", 0, 0 }, pn = { 12, 36, "plano" }, pf = { 23, 36, "plano" }, bn = { -28, 72 },  bf = { 135, 168 } },
  { torso = "enc",   hip = { 16, 23 }, lean = 2, cab = { "lol", 1, 1 }, pn = { 11, 35, "punta" }, pf = { 23, 36, "plano" }, bn = { 82, 86 },   bf = { 100, 94 } },
  { torso = "enc",   hip = { 17, 23 }, lean = 3, cab = { "lol", 1, 2 }, pn = { 11, 35, "punta" }, pf = { 23, 36, "plano" }, bn = { 45, 60 },   bf = { 62, 72 } },
  { torso = "enc",   hip = { 17, 23 }, lean = 1, cab = { "lol", 1, 1 }, pn = { 12, 36, "plano" }, pf = { 23, 36, "plano" }, bn = { 25, 50 },   bf = { 66, 92 } },
}
local MORIR = {
  { torso = "recto", hip = { 18, 22 }, lean = -2, cab = { "atras", -1, 0 }, pn = { 13, 36, "plano" }, pf = { 23, 36, "plano" }, bn = { 35, 75 },  bf = { 100, 125 }, extra = salpicadura },
  { torso = "recto", hip = { 16, 24 }, lean = -4, cab = { "atras", -1, 0 }, pn = { 13, 36, "plano" }, pf = { 23, 36, "plano" }, bn = { 70, 110 }, bf = { 115, 150 } },
  { torso = "H", hip = { 19, 31 }, rise = 7, cab = { "tumbada", 0, 0 },  pn = { 26, 36, "plano" }, pf = { 28, 36, "plano" }, bn = { 120, 140 }, bf = { 150, 170 } },
  { torso = "H", hip = { 20, 36 }, rise = 2, cab = { "tumbada", 0, -1 }, pn = { 33, 34, "tumbado" }, pf = { 33, 30, "tumbado" }, bn = { 100, 120 }, bf = { -160, -130 } },
  { torso = "H", hip = { 20, 36 }, rise = 0, cab = { "tumbada", 0, 0 },  pn = { 34, 36, "tumbado", recta = true }, pf = { 34, 31, "tumbado", recta = true }, bn = { 86, 92 }, bf = { -150, -110 } },
  { torso = "H", hip = { 20, 36 }, rise = 0, cab = { "tumbada", 0, 0 },  pn = { 34, 36, "tumbado", recta = true }, pf = { 34, 31, "tumbado", recta = true }, bn = { 86, 92 }, bf = { -150, -110 }, antes = charco },
}


------------------------------------------------------------------ 8 DIRECCIONES (s, se, ne, n)
-- La vista `e` es la de siempre (figura). Las otras cuatro se montan con piezas propias de
-- cada vista (cabeza, torso, pies, manos de frente) sobre el mismo esqueleto: las piernas
-- siguen el mismo ciclo de arrastre que la vista `e` (el pie izquierdo calzado va delante y el
-- derecho descalzo se arrastra detrás), proyectado al suelo de la cámara 3/4.
-- En la vista `s` su derecha queda a la izquierda de la pantalla; en `n`, a la derecha.

-- Ciclo del suelo, sacado de ANDAR: avance (px, + = hacia donde mira) y altura del pie.
local CICLO = {}
for i, q in ipairs(ANDAR) do
  CICLO[i] = { fR = q.pn[1] - 17.5, uR = 36 - q.pn[2], fL = q.pf[1] - 17.5, uL = 36 - q.pf[2],
               bob = q.hip[2] - 23, cab = q.cab[3] - 1 }
end
-- Vaivén lateral (hacia su izquierda +): carga en el pie izquierdo y luego en el derecho.
local VAIVEN = { 0, 1, 1, 1, 0, -1, -1, 0 }

-- Piezas del cuerpo en las vistas nuevas -------------------------------------------------
local Z8 = {}

Z8.cabeza = {
  s = P({
    ".ijjh.",
    "iljjih",
    "jl4j4h",
    "4E33E2",
    "3e33e1",
    "23RR21",
    ".2rT1.",
  }, 3, 6),
  se = P({
    ".ijjh.",
    "iljjjh",
    "hjj444",
    "hi4E3E",
    ".33e3e",
    ".2233R",
    "..22rT",
  }, 3, 6),
  ne = P({
    ".ijjh.",
    "iljjjh",
    "ljjjjh",
    "jjjih4",
    "ijih34",
    "hih233",
    ".h2232",
  }, 3, 6),
  n = P({
    ".ijjh.",
    "iljjjh",
    "ljjjih",
    "jjjjih",
    "3ijih2",
    ".hiih.",
    ".3322.",
  }, 3, 6),
}

-- Torsos: hip = centro de la cadera; hombros en pantalla izquierda (I) y derecha (D).
Z8.torso = {
  s = P({
    "..cdddddc..",
    ".cdddddddcb",
    "cddddcccccb",
    "cdddccsccba",
    "cddcccsSbba",
    "cdcccssSbba",
    ".ccccsbbba.",
    ".cdcc3bbba.",
    ".ccc334bba.",
    ".cccbbbbba.",
    ".ccbbbbbba.",
    "..cbb.bb.a.",
  }, 0, 0, { hip = { 5, 11 }, cuello = { 5, 0 }, hI = { 0, 1 }, hD = { 10, 1 } }),
  se = P({
    "...cdddc..",
    "..cddddccb",
    ".cdddcccba",
    "cdddccscba",
    "cddccssSba",
    "cdcccsSbba",
    "ccccc3bba.",
    ".cdc33bba.",
    ".ccc3bbba.",
    ".cccbbbba.",
    ".ccbbbbaa.",
    "..cb.bb.a.",
  }, 0, 0, { hip = { 5, 11 }, cuello = { 5, 0 }, hI = { 1, 2 }, hD = { 8, 1 } }),
  ne = P({
    "..cddc....",
    ".cddddcb..",
    "cdddddccb.",
    "cddddcccba",
    "cdddccc3ba",
    "cddcccc33a",
    ".cdccbbbba",
    ".cdccbbba.",
    ".cccbbbba.",
    "..ccbbba..",
    "..cbbbaa..",
    "..cb.b.a..",
  }, 0, 0, { hip = { 5, 11 }, cuello = { 4, 0 }, hI = { 1, 1 }, hD = { 8, 2 } }),
  n = P({
    "..cddddc...",
    ".cddddddcS.",
    "cdddddccSba",
    "cddddddccba",
    "cddddcbccba",
    ".cddccbcbba",
    ".cdcccbcbba",
    ".ccccbbbba.",
    ".ccc3bbbba.",
    "..c33bbba..",
    "..cbbbbaa..",
    "..cb.bb.a..",
  }, 0, 0, { hip = { 5, 11 }, cuello = { 5, 0 }, hI = { 0, 2 }, hD = { 10, 2 } }),
}

-- Piernas de frente / de espaldas (4 px de ancho; luz a la izquierda).
local musloF = P({ "zzyx", "zyyx", "zyyx", "zyxw", "zyxw", "yyxw" }, 1, 0)
Z8.pR = {    -- pierna derecha: vaquero roto y pie descalzo
  muslo = musloF,
  tibia = P({ "zyx", "zyx", "zyx", "yxw", "y.x", "343" }, 1, 0),
  pies = {
    s = P({ "4443", "2331" }, 1, 0),        -- dedos hacia la cámara
    n = P({ ".43.", "2331" }, 1, 0),        -- talón
    se = P({ "443..", "23431" }, 1, 0),
    ne = P({ ".443", "2331" }, 1, 0),
  },
}
Z8.pL = {    -- pierna izquierda: con zapato
  muslo = musloF,
  tibia = P({ "zyx", "zyx", "zyx", "zyx", "yxw" }, 1, 0),
  pies = {
    s = P({ "popn", "nonm", "mmmm" }, 1, 0),
    n = P({ "ponm", "oonm", "mmmm" }, 1, 0),
    se = P({ "pon..", "pooon", "mmmmm" }, 1, 0),
    ne = P({ "pon.", "oonm", "mmmm" }, 1, 0),
  },
}

-- Brazos: tramos verticales/tumbados de la vista `e` más un antebrazo ancho en escorzo
-- y una mano vista de frente (los dedos cuelgan hacia la cámara).
Z8.bR = {   -- brazo derecho: manga arrancada y mordisco
  upV = Z.brazoN.upV, upH = Z.brazoN.upH, foV = Z.brazoN.foV, foH = Z.brazoN.foH,
  foF = P({ "4554", "4R43", "3r32" }, 1, 0),
  manoV = Z.brazoN.manoV, manoH = Z.brazoN.manoH,
  manoF = P({ "4554", "4443", "3.32" }, 1, 0),
  manoG = P({ ".445.", "45543", "34432", "2.2.1" }, 2, 0),
  hombrera = P({ ".dd.", "cddc", "c..a" }, 1, 1),
}
Z8.bL = {   -- brazo izquierdo: manga hasta el codo
  upV = Z.brazoF.upV, upH = Z.brazoF.upH, foV = Z.brazoF.foV, foH = Z.brazoF.foH,
  foF = P({ "4554", "4443", "3432" }, 1, 0),
  manoV = Z.brazoN.manoV, manoH = Z.brazoN.manoH,
  manoF = P({ "4554", "4443", "3.32" }, 1, 0),
  manoG = P({ ".445.", "45543", "34432", "2.2.1" }, 2, 0),
}

-- Brazo por puntos: { hombro x, y, codo x, y, muñeca x, y, mano = "F"|"V"|"U"|"H"|"I"|nil, ancho = bool }
local function brazoP(img, B, mapa, a)
  tramo(img, B.upV, B.upH, mapa, a[1], a[2], a[3], a[4], false)
  tramo(img, a.ancho and B.foF or B.foV, B.foH, mapa, a[3], a[4], a[5], a[6], true)
  if B.hombrera and a.hombrera then pegar(img, B.hombrera, a[1], a[2], mapa) end
  local wx, wy = a[5], a[6]
  local m = a.mano
  if m == nil then
    local dx, dy = wx - a[3], wy - a[4]
    if abs(dy) >= abs(dx) then m = dy >= 0 and "V" or "U" else m = dx >= 0 and "H" or "I" end
  end
  if m == "F" then return { B.manoF, wx, wy + 1, false, false } end
  if m == "G" then return { B.manoG, wx, wy + 1, false, false } end
  if m == "V" then return { B.manoV, wx, wy + 1, false, false } end
  if m == "U" then return { B.manoV, wx, wy - 1, false, true } end
  if m == "H" then return { B.manoH, wx + 1, wy, false, false } end
  if m == "I" then return { B.manoH, wx - 1, wy, true, false } end
  return nil
end

-- Vistas: dirección de la mirada en el suelo y qué se pinta detrás del cuerpo.
local VISTA = {
  s  = { d = { 0, 1 } },
  se = { d = { 0.71, 0.71 } },
  ne = { d = { 0.71, -0.71 } },
  n  = { d = { 0, -1 } },
}
local SY = 0.2     -- compresión de la profundidad para el paso
local G = 38 - 6.5 * SY

-- Dibuja un fotograma de las vistas nuevas. q = { v, k (fase del ciclo), bob, dx, cab = {dx, dy},
-- R = brazo derecho, Lb = brazo izquierdo } ; los brazos van relativos al hombro.
local function figura8(img, C, q, ctx)
  local mapa, lejos = C.mapa, C.lejos
  local prot = {}
  local V = VISTA[q.v]
  local dxs, dys = V.d[1], V.d[2]
  local rx, ry = -dys, dxs                 -- su derecha en el suelo
  local c = CICLO[q.k]
  local sway = (q.sway or VAIVEN[q.k])
  local hx = 20 + R(-sway * rx) + (q.dx or 0)
  local hy = 23 + c.bob + (q.bob or 0)
  local T = Z8.torso[q.v]
  local ox, oy = hx - T.hip[1], hy - T.hip[2]
  local nx, ny = ox + T.cuello[1], oy + T.cuello[2]
  local hIx, hIy = ox + T.hI[1], oy + T.hI[2] + 1
  local hDx, hDy = ox + T.hD[1], oy + T.hD[2] + 1
  -- su derecha / izquierda en pantalla
  local derI = (q.v == "s" or q.v == "se")
  local shR = derI and { hIx, hIy } or { hDx, hDy }
  local shL = derI and { hDx, hDy } or { hIx, hIy }

  -- pies en el suelo
  local function pie(f, u, l)
    local gx = f * dxs + l * rx
    local gy = f * dys + l * ry
    return R(20 + gx * 0.8), R(G + gy * SY - u)
  end
  local fRx, fRy = pie(c.fR, c.uR, 2.5)
  local fLx, fLy = pie(c.fL, c.uL, -2.5)
  local hipRx, hipRy = R(hx + 2 * rx), hy
  local hipLx, hipLy = R(hx - 2 * rx), hy
  if q.pies then fRx, fRy, fLx, fLy = q.pies[1], q.pies[2], q.pies[3], q.pies[4] end

  local function fijo(pz, m)
    if not pz then return end
    capa(img, C, prot, { fijo = true }, function(t) pegar(t, pz[1], pz[2], pz[3], m, pz[4], pz[5]) end)
  end
  local function pierna8(Pz, m, hpx, hpy, fx, fy, u)
    local pz = Pz.pies[q.v]
    local ay = fy - pz.h        -- fila del tobillo
    local kx, ky = R((hpx + fx) / 2 + u * 0.5 * (dxs >= 0 and 1 or -1) * (abs(dxs) > 0.1 and 1 or 0)), R((hpy + ay) / 2)
    capa(img, C, prot, { derecha = true }, function(t)
      tramoV(t, Pz.muslo, m, hpx, hpy, kx, ky, false)
      tramoV(t, Pz.tibia, m, kx, ky, fx, ay, true)
    end)
    fijo({ pz, fx, ay + 1, false, false }, m)
  end
  local function brazo8(B, m, sh, a, op)
    if not a then return end
    local pts = { sh[1], sh[2], sh[1] + a[1], sh[2] + a[2], sh[1] + a[3], sh[2] + a[4], mano = a.mano, ancho = a.ancho, hombrera = a.hombrera }
    local pz
    capa(img, C, prot, op or { derecha = true, abajo = true }, function(t) pz = brazoP(t, B, m, pts) end)
    fijo(pz, m)
  end

  -- su brazo derecho es el cercano en se y ne; el izquierdo, el lejano
  local mR = mapa
  local mL = (q.v == "se" or q.v == "ne") and lejos or mapa
  -- 1. lo que queda detrás del cuerpo
  if q.v == "n" then
    brazo8(Z8.bL, mapa, shL, q.Lb, {}); brazo8(Z8.bR, mapa, shR, q.R, {})
  elseif q.v == "ne" or (q.Lb and q.Lb.atras) then
    brazo8(Z8.bL, lejos, shL, q.Lb, {})
  end
  -- 2. piernas: la que pisa más lejos de la cámara primero
  local pR = function() pierna8(Z8.pR, (q.v == "ne" or q.v == "se") and mapa or mapa, hipRx, hipRy, fRx, fRy, c.uR) end
  local pL = function() pierna8(Z8.pL, (q.v == "ne" or q.v == "se") and lejos or mapa, hipLx, hipLy, fLx, fLy, c.uL) end
  L.rect(img, hx - 3, hy - 1, 7, 3, mapa.x)
  if fRy + (q.v == "se" and 1 or 0) >= fLy then pL(); pR() else pR(); pL() end
  -- 3. torso y cabeza
  capa(img, C, prot, { abajo = true }, function(t) pegar(t, T, ox, oy, mapa) end)
  local cab = Z8.cabeza[q.v]
  local cx, cy = nx + (q.cab and q.cab[1] or 0), ny + (q.cab and q.cab[2] or 0) + c.cab
  capa(img, C, prot, { abajo = true, fijo = true }, function(t) pegar(t, cab, cx, cy, mapa) end)
  -- 4. brazos por delante
  if q.v == "s" then
    brazo8(Z8.bR, mapa, shR, q.R); brazo8(Z8.bL, mapa, shL, q.Lb)
  elseif q.v == "se" then
    if not q.Lb.atras then brazo8(Z8.bL, lejos, shL, q.Lb) end
    brazo8(Z8.bR, mapa, shR, q.R)
  elseif q.v == "ne" then
    brazo8(Z8.bR, mapa, shR, q.R)
  end
  contornoSelectivo(img, C, prot)
  for y = 0, H - 1 do for x = 0, W - 1 do
    if L.opaco(img, x, y) and (x == 0 or x == W - 1 or y == 0 or y == H - 1) then
      print("  AVISO " .. ctx.nombre .. " " .. ctx.tag .. ": píxel en el borde (" .. x .. "," .. y .. ")")
      return
    end
  end end
end

-- Poses de los brazos por vista (relativas al hombro: codo dx, dy, muñeca dx, dy).
-- andar: brazos al frente con un vaivén alterno de 1 px.
local ALCE = {
  s  = { R = { 0, 2, 1, 3, mano = "F", ancho = true, hombrera = true }, Lb = { 0, 2, -1, 3, mano = "F", ancho = true } },
  se = { R = { 1, 3, 5, 5, mano = "H" }, Lb = { 2, 3, 5, 4, mano = "H" } },
  ne = { R = { 3, 0, 7, -1, mano = "H" }, Lb = { 4, 0, 9, -2, mano = "H" } },
  n  = { R = { 2, 1, -1, -3 }, Lb = { -2, 1, 1, -3 } },
}
local VAIVEN_BR = { 0, 0, 1, 1, 0, 0, -1, -1 }
local function mover(a, dy, dx)
  local b = {}
  for k, v in pairs(a) do b[k] = v end
  b[2] = b[2] + R(dy * 0.5); b[4] = b[4] + dy; b[3] = b[3] + (dx or 0) ; b[1] = b[1] + R((dx or 0) * 0.5)
  return b
end

local function posesAndar(v)
  local t = {}
  for k = 1, 8 do
    local s = VAIVEN_BR[k]
    t[k] = { v = v, k = k, R = mover(ALCE[v].R, s), Lb = mover(ALCE[v].Lb, -s) }
  end
  return t
end

-- atacar: toma impulso con los brazos arriba, zarpazo (2.º), sigue y se recupera.
local ATAQUE = {
  s = {
    { bob = -1, cab = { 0, -1 }, R = { -2, -4, -1, -8, mano = "U", hombrera = true }, Lb = { 2, -4, 1, -8, mano = "U" } },
    { bob = 1, cab = { 0, 1 }, R = { -2, 2, -2, 4, mano = "G", ancho = true, hombrera = true }, Lb = { 2, 2, 2, 4, mano = "G", ancho = true } },
    { bob = 1, cab = { 0, 1 }, R = { 0, 4, 4, 7, mano = "F", ancho = true, hombrera = true }, Lb = { 0, 4, -4, 7, mano = "F", ancho = true } },
    { bob = 0, cab = { 0, 0 }, R = { 0, 3, 1, 4, mano = "F", ancho = true, hombrera = true }, Lb = { 0, 3, -1, 4, mano = "F", ancho = true } },
  },
  se = {
    { bob = -1, cab = { -1, -1 }, R = { -2, -4, -1, -8, mano = "U" }, Lb = { 1, -4, 1, -8, mano = "U", atras = true } },
    { bob = 1, cab = { 1, 1 }, R = { 3, 3, 8, 5, mano = "H" }, Lb = { 3, 2, 7, 4, mano = "H" } },
    { bob = 1, cab = { 1, 1 }, R = { 2, 4, 6, 7 }, Lb = { 3, 3, 5, 7 } },
    { bob = 0, cab = { 0, 0 }, R = { 1, 3, 5, 5, mano = "H" }, Lb = { 2, 3, 5, 4, mano = "H" } },
  },
  ne = {
    { bob = -1, cab = { -1, -1 }, R = { 1, -4, 0, -8, mano = "U" }, Lb = { -1, -4, 0, -8, mano = "U" } },
    { bob = 1, cab = { 1, 1 }, R = { 4, -1, 8, -2, mano = "H" }, Lb = { 4, -3, 9, -4, mano = "H" } },
    { bob = 1, cab = { 1, 1 }, R = { 3, 0, 7, 1, mano = "H" }, Lb = { 4, -2, 8, -2, mano = "H" } },
    { bob = 0, cab = { 0, 0 }, R = { 3, -1, 6, -3, mano = "H" }, Lb = { 4, -3, 8, -5, mano = "H" } },
  },
  n = {
    { bob = -1, cab = { 0, -1 }, R = { 2, -4, 1, -8, mano = "U" }, Lb = { -2, -4, -1, -8, mano = "U" } },
    { bob = 1, cab = { 0, 1 }, R = { 1, -1, -2, -4 }, Lb = { -1, -1, 2, -4 } },
    { bob = 1, cab = { 0, 1 }, R = { 1, 0, -2, -3 }, Lb = { -1, 0, 2, -3 } },
    { bob = 0, cab = { 0, 0 }, R = { 1, -2, -1, -5 }, Lb = { -1, -2, 1, -5 } },
  },
}
-- El ataque se da con los pies quietos en el fotograma 1 del ciclo.
local function posesAtacar(v)
  local t = {}
  for i, a in ipairs(ATAQUE[v]) do
    local q = { v = v, k = 1, sway = 0 }
    for kk, vv in pairs(a) do q[kk] = vv end
    t[i] = q
  end
  return t
end

------------------------------------------------------------------ construir
local function construir(nombre, C)
  local cuadros, etiquetas, dur = {}, {}, {}
  local function poner(tag, lista, durs, fn)
    local desde = #cuadros + 1
    for i, q in ipairs(lista) do
      local ctx = { nombre = nombre, tag = tag .. " " .. i, k = #cuadros }
      cuadros[#cuadros + 1] = function(img) fn(img, q, ctx) end
      dur[#dur + 1] = type(durs) == "table" and durs[i] or durs
    end
    etiquetas[#etiquetas + 1] = { tag, desde, #cuadros }
  end
  local function figE(lista, bucle)
    -- prepara anclas como en la versión de una sola dirección
    local anclas = {}
    for i, q in ipairs(lista) do anclas[i] = figura(nil, C, q, nil) end
    local t = {}
    for i, q in ipairs(lista) do
      t[i] = { q = q, ant = anclas[i - 1] or (bucle and anclas[#anclas]) or nil }
    end
    return t
  end
  local function dibE(img, e, ctx) ctx.ant = e.ant; figura(img, C, e.q, ctx) end
  local function dib8(img, q, ctx) figura8(img, C, q, ctx) end
  local DA = { 0.12, 0.08, 0.10, 0.14 }
  for _, v in ipairs({ "s", "se", "e", "ne", "n" }) do
    if v == "e" then poner("andar_e", figE(ANDAR, true), 0.14, dibE)
    else poner("andar_" .. v, posesAndar(v), 0.14, dib8) end
  end
  for _, v in ipairs({ "s", "se", "e", "ne", "n" }) do
    if v == "e" then poner("atacar_e", figE(ATACAR, false), DA, dibE)
    else poner("atacar_" .. v, posesAtacar(v), DA, dib8) end
  end
  poner("morir", figE(MORIR, false), { 0.09, 0.09, 0.11, 0.13, 0.16, 1.0 }, dibE)
  L.construir(nombre, W, H, cuadros, etiquetas, dur, { pies = { 20, 38 } })
end

construir("zombi", Z)
