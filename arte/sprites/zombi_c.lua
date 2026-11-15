-- zombi.lua — construye `zombi` y `zombi_b` (40x40, pies en {20,38}, miran a la derecha).
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

------------------------------------------------------------------ PIEZAS DE ZOMBI_B (mujer)
-- Melena larga castaña clara que le tapa media cara, túnica mostaza hasta medio muslo,
-- piernas desnudas y descalza. Más menuda que el hombre y con el brazo CERCANO extendido.
local B = { l1 = 7.5, l2 = 6.7, lu = 4.8, lf = 4.7, dy = 1 }

B.cabeza = {
  up = P({
    ".jllj.",
    "jlljj4",
    "ijjjE4",
    "hij343",
    "hij3Rr",
    ".hi23.",
  }, 2, 5),
  lol = P({
    "..jlj.",
    ".jlljj",
    "ijjlj4",
    "hijjE4",
    "hij343",
    ".hi3Rr",
  }, 2, 5),
  atras = P({
    "..j44.",
    ".jlEe4",
    "jlj335",
    "ijj3RR",
    "hij32.",
    "hhi2..",
  }, 3, 4),
  tumbada = P({
    "..345.",
    ".j4E4R",
    "jl4334",
    "ijj323",
    "hijh22",
    ".hhh..",
  }, 5, 3),
}
local MELENA = P({ "ij.", "hjj", "hjl", "hij", "hij", ".hj", ".hi" }, 1, 0)
local MELENA_H = P({ "..hi..", "hijjj.", "ijljji", ".hijj.", "..hh.." }, 5, 2)
B.melena = function(t, C, q, a, ctx)
  if a.tumbado then
    pegar(t, MELENA_H, a.cx - 5, a.cy, C.mapa)
  else
    local lag = max(-2, min(2, (ctx.ant and (ctx.ant.cx - a.cx) or 0)))
    for j = 0, MELENA.h - 1 do
      local dx = R(lag * j / (MELENA.h - 1))
      for i = 0, MELENA.w - 1 do punto(t, a.cx - 3 + i + dx, a.cy - 2 + j, MELENA.f[j + 1]:sub(i + 1, i + 1), C.mapa) end
    end
  end
end

B.torso = {
  enc = P({
    ".....cddc.",
    "....cdddcb",
    "...cdddcba",
    "...cdcccsa",
    "..cdccbssa",
    "..cdcbbSa.",
    "..ccbbba..",
    ".cdcbba...",
    ".ccbbba...",
    ".cdcbbba..",
    "cdccbbba..",
    "cdcbcbba..",
    "cdcbcbba..",
    "ccdbcbba..",
    "cc.bcb.a..",
    "c...c.....",
  }, 0, 0, { hip = { 2, 11 }, cuello = { 6, 0 }, hombroN = { 5, 2 }, hombroF = { 7, 2 } }),
  recto = P({
    ".cddc..",
    "cdddcb.",
    "cdddcba",
    "cdcccsa",
    "cdccssa",
    ".dcbbS.",
    ".ccbba.",
    ".cdbba.",
    "cdcbbba",
    "cdcbbba",
    "cdbcbba",
    "cdbcbba",
    "ccdbcba",
    "cdcbcba",
    "cb.bc.a",
    "c...c..",
  }, 0, 0, { hip = { 2, 11 }, cuello = { 2, 0 }, hombroN = { 2, 2 }, hombroF = { 4, 2 } }),
  H = P({
    "..cccc..........",
    ".cdddcccccddccc.",
    "cdddccccdddcccc.",
    "cddcsscccccccbcb",
    "ccccsSccbccbbbbb",
    "bbbbbbbbbbbbbbba",
    ".aaaaaaaaaaaaaa.",
  }, 0, 0, { hip = { 11, 4 }, cuello = { 0, 3 }, hombroN = { 2, 5 }, hombroF = { 2, 1 } }),
}

local musloVb = P({ "443", "543", "442", "432", "432", "431", "442", "431" }, 1, 0)
local musloHb = P({ "44544444", "33343333", "12222221" }, 0, 1)
local pantVb = P({ "442", "432", "431", "4r1", ".31", ".31", ".31" }, 1, 0)
local pantHb = P({ "4454444", "3333333", "122221." }, 0, 1)
B.piernaN = { musloV = musloVb, musloH = musloHb, pantV = pantVb, pantH = pantHb, pies = Z.piernaN.pies }
B.piernaF = { musloV = musloVb, musloH = musloHb, pantV = pantVb, pantH = pantHb, pies = {} }
for k, v in pairs(Z.piernaN.pies) do B.piernaF.pies[k] = v end
B.piernaF.pies.alza = Z.piernaN.pies.plano

B.brazoN = {      -- mangas largas mostaza con el puño roto
  upV = P({ "dcb", "dcb", "dca", "cba", "cba", "cba" }, 1, 0),
  upH = P({ "ddcddc", "cccbcb", "abbaab" }, 0, 1),
  foV = P({ "dca", "cba", "cba", ".31", ".31" }, 1, 0),
  foH = P({ "dcd44", "ccb33", "aba1." }, 0, 1),
  manoV = Z.brazoN.manoV, manoH = Z.brazoN.manoH,
}
B.brazoF = B.brazoN

prepararColores(B, {
  piel = L.rampa("zombi"), ropa = L.rampa("ropa_c"), pant = hexes({ "1c1a22", "2b2833", "3d3947", "544f60" }),
  pelo = hexes({ "2a211a", "473829", "6b563c", "8c7350" }), zapato = L.rampa("cuero"),
  ojo = L.hex("c4c8ba"), diente = L.hex("aeab9f"),
})
-- En `andar` ella lleva extendido el brazo cercano y colgando el lejano (al revés que él).
B.pose = function(q, anim)
  if anim ~= "andar" then return q end
  local c = {}
  for k, v in pairs(q) do c[k] = v end
  c.bn, c.bf = q.bf, q.bn
  return c
end

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

------------------------------------------------------------------ construir
local function construir(nombre, C)
  local cuadros = {}
  local k = 0
  for _, par in ipairs({ { "andar", ANDAR, true }, { "atacar", ATACAR, false }, { "morir", MORIR, false } }) do
    local anim, lista, bucle = par[1], par[2], par[3]
    local poses, anclas = {}, {}
    for i, q in ipairs(lista) do
      poses[i] = C.pose and C.pose(q, anim) or q
      anclas[i] = figura(nil, C, poses[i], nil)
    end
    for i, q in ipairs(poses) do
      local ant = anclas[i - 1] or (bucle and anclas[#anclas]) or nil
      local ctx = { nombre = nombre, k = k, ant = ant }
      cuadros[#cuadros + 1] = function(img) figura(img, C, q, ctx) end
      k = k + 1
    end
  end
  local dur = {}
  for i = 1, 8 do dur[i] = 0.14 end
  for _, d in ipairs({ 0.12, 0.08, 0.10, 0.14, 0.09, 0.09, 0.11, 0.13, 0.16, 1.0 }) do dur[#dur + 1] = d end
  L.construir(nombre, W, H, cuadros, { { "andar", 1, 8 }, { "atacar", 9, 12 }, { "morir", 13, 18 } }, dur, { pies = { 20, 38 } })
end

construir("zombi", Z)
construir("zombi_b", B)
