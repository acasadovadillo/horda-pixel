-- Dibuja todo el arte del juego dentro de Aseprite y guarda un .aseprite por sprite.
-- Uso: aseprite -b --script-param out=<carpeta> --script dibujar.lua
-- Cada .aseprite se puede abrir y retocar a mano; construir.sh exporta las hojas.

local OUT = app.params.out or "."

---------------------------------------------------------------- paleta
local function hex(h)
  return Color{ r = tonumber(h:sub(1, 2), 16), g = tonumber(h:sub(3, 4), 16),
                b = tonumber(h:sub(5, 6), 16), a = 255 }
end

local PAL = {
  K = "1a1423", k = "3b2f4a",                         -- contorno, sombra suave
  h = "5a3524", H = "3e2418",                         -- pelo
  s = "f4c7a1", S = "d39a74",                         -- piel
  b = "3d7cc9", B = "2a5590", c = "6fa8e8",           -- chaqueta
  p = "3a3f58", P = "272a3d",                         -- pantalón
  o = "6b4429", O = "4a2e1b",                         -- botas
  w = "ffffff", W = "c9d3dd",
  g = "9bbf63", G = "6c8d3f", j = "c3dd8a",           -- piel zombi
  e = "ff3b30",                                       -- ojo
  r = "9c5a45", R = "6e3a2c",                         -- camisa zombi
  u = "4f6386", U = "34425e",                         -- pantalón zombi
  x = "b0202c", X = "6e1119",                         -- sangre
  y = "ffe066", f = "ffb03a", F = "e0701f",           -- oro / fogonazo
  m = "a7adb8", M = "6b717d", n = "3a3e47",           -- metal
  d = "9a6536", D = "663f1f",                         -- madera
  l = "a4a4ad", L = "7d7d88",                         -- acera
}
local C = {}
for k, v in pairs(PAL) do C[k] = hex(v) end

---------------------------------------------------------------- ayudas
local function px(img, x, y, c)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end

-- Pinta filas de caracteres; '.' es transparente.
local function paint(img, rows, ox, oy, map)
  for y, row in ipairs(rows) do
    for x = 1, #row do
      local ch = row:sub(x, x)
      if ch ~= "." then
        local key = (map and map[ch]) or ch
        local c = C[key]
        if not c then error("color desconocido '" .. ch .. "'") end
        px(img, ox + x - 1, oy + y - 1, c)
      end
    end
  end
end

local function check(name, rows, w)
  for i, r in ipairs(rows) do
    if #r ~= w then error(name .. " fila " .. (i - 1) .. " mide " .. #r .. " y debe medir " .. w) end
  end
end

local function rect(img, x, y, w, h, c)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do px(img, xx, yy, c) end end
end

-- Rectángulo con contorno de 1 px.
local function box(img, x, y, w, h, fill, line)
  rect(img, x, y, w, h, line or C.K)
  rect(img, x + 1, y + 1, w - 2, h - 2, fill)
end

local function ellipse(img, cx, cy, rx, ry, c)
  for yy = math.floor(cy - ry), math.ceil(cy + ry) do
    for xx = math.floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (xx + 0.5 - cx) / rx, (yy + 0.5 - cy) / ry
      if dx * dx + dy * dy <= 1 then px(img, xx, yy, c) end
    end
  end
end

-- Generador pseudoaleatorio fijo para que el arte salga igual cada vez.
local seed = 12345
local function rnd()
  seed = (seed * 1103515245 + 12345) % 2147483648
  return seed / 2147483648
end

-- Contorno automático: pinta K alrededor de lo opaco.
local function outline(img, c)
  c = c or C.K
  local w, h = img.width, img.height
  local solid = {}
  for y = 0, h - 1 do for x = 0, w - 1 do
    solid[y * w + x] = app.pixelColor.rgbaA(img:getPixel(x, y)) > 0
  end end
  for y = 0, h - 1 do for x = 0, w - 1 do
    if not solid[y * w + x] then
      local n = (x > 0 and solid[y * w + x - 1]) or (x < w - 1 and solid[y * w + x + 1])
             or (y > 0 and solid[(y - 1) * w + x]) or (y < h - 1 and solid[(y + 1) * w + x])
      if n then img:drawPixel(x, y, c) end
    end
  end end
end

-- Crea un sprite con varios fotogramas y etiquetas y lo guarda.
-- frames: lista de funciones(img); tags: { {nombre, desde, hasta}, ... }
local function build(name, w, h, frames, tags, dur)
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = name
  for i = 2, #frames do spr:newEmptyFrame() end
  for i, f in ipairs(frames) do
    local img = Image(w, h, ColorMode.RGB)
    f(img)
    spr:newCel(spr.layers[1], i, img, Point(0, 0))
    local d = type(dur) == "table" and dur[i] or dur
    spr.frames[i].duration = d or 0.1
  end
  for _, t in ipairs(tags or {}) do
    local tag = spr:newTag(t[2], t[3])
    tag.name = t[1]
  end
  spr:saveAs(OUT .. "/" .. name .. ".aseprite")
  spr:close()
end

---------------------------------------------------------------- personaje (16x20, mira a la derecha)
local HERO_UP = {
  "................",
  "....KKKKKK......",
  "...KhhhhhhKK....",
  "..KhhhhhhhhhK...",
  "..KhHhhhhhhhK...",
  "..KhHhhhSsssK...",
  "..KhHhSssKssK...",
  "..KhHSsssKssK...",
  "...KhSssssssK...",
  "....KKSSSSKK....",
  "....KBbbbbK.....",
  "...KBbbcbbbK....",
  "...KBbbcbbsK....",
  "...KBbbbbbbK....",
  "....KPppppK.....",
}
check("heroe", HERO_UP, 16)

local LEGS = {
  quieto = {
    "....KppKppK.....",
    "....KppKppK.....",
    "....KppKppK.....",
    "....KooKoooK....",
    "....KKKKKKKK....",
  },
  pasoA = {
    "....KppKppK.....",
    "...KppK.KppK....",
    "..KppK...KppK...",
    "..KooK...KoooK..",
    "..KKK.....KKKK..",
  },
  pasoB = {
    "....KppKppK.....",
    "....KppKppK.....",
    "....KPPKppK.....",
    "....KKKKoooK....",
    "........KKKK....",
  },
  rodilla = {
    "................",
    "................",
    "................",
    "...KppppppK.....",
    "...KKKKKKKKK....",
  },
}
for k, v in pairs(LEGS) do check("piernas " .. k, v, 16) end

-- Intercambia el tono de las dos piernas para el segundo paso.
local SWAP_LEGS = { p = "P", P = "p", o = "O", O = "o" }

local HERO_LYING = {
  ".KKKKK..........",
  "KhhhhhKKKKKKKKK.",
  "KhsKshKBbbbbKppK",
  "KhsssSKBbbbbKpoK",
  ".KKKKKKKKKKKKKKK",
}
check("heroe tumbado", HERO_LYING, 16)

local function blood_pool(img, cx, cy, rx, ry)
  ellipse(img, cx, cy, rx, ry, C.X)
  ellipse(img, cx - 1, cy - 0.5, rx - 2, ry - 1, C.x)
end

local function hero_frame(legs, up_dx, up_dy, legmap)
  return function(img)
    paint(img, legs, 0, 15, legmap)
    paint(img, HERO_UP, up_dx or 0, up_dy or 0)
  end
end

build("jugador", 16, 20, {
  hero_frame(LEGS.quieto, 0, 0),                    -- 1 quieto
  hero_frame(LEGS.quieto, 0, 1),                    -- 2 quieto (respira)
  hero_frame(LEGS.pasoA, 0, 1),                     -- 3 correr
  hero_frame(LEGS.pasoB, 0, 0),                     -- 4
  hero_frame(LEGS.pasoA, 0, 1, SWAP_LEGS),          -- 5
  hero_frame(LEGS.pasoB, 0, 0, SWAP_LEGS),          -- 6
  hero_frame(LEGS.quieto, -1, 0),                   -- 7 morir: retrocede
  hero_frame(LEGS.rodilla, -1, 4),                  -- 8 de rodillas
  function(img) paint(img, HERO_LYING, 0, 14) end,  -- 9 en el suelo
  function(img)                                     -- 10 en el suelo con sangre
    blood_pool(img, 7, 18, 8, 2.5)
    paint(img, HERO_LYING, 0, 14)
  end,
}, {
  { "quieto", 1, 2 }, { "correr", 3, 6 }, { "morir", 7, 10 },
}, { 0.5, 0.5, 0.1, 0.1, 0.1, 0.1, 0.12, 0.16, 0.2, 1.0 })

---------------------------------------------------------------- zombi (16x20, mira a la derecha)
local ZOMB_UP = {
  "................",
  "................",
  ".....KKKKK......",
  "....KgggggK.....",
  "...KgjgggggK....",
  "...KGgggggggK...",
  "...KGggggeggK...",
  "...KGggggggXK...",
  "...KGGggKXXK....",
  "....KKGGKKK.....",
  "....KRrrrK......",
  "...KRrrrrrKKKKK.",
  "...KRrrrrGgggggK",
  "...KRrrxrrKKKKK.",
  "...KRrxxrrK.....",
  "....KUuuuK......",
}
check("zombi", ZOMB_UP, 16)

local ZOMB_ARMS_UP = {   -- brazos levantados para atacar (sustituye filas 10-13)
  "....KRrrrK..KK..",
  "...KRrrrrrKKgK..",
  "...KRrrrrGggK...",
  "...KRrrxrrKK....",
}
check("zombi brazos", ZOMB_ARMS_UP, 16)

local ZLEGS = {
  pasoA = {
    "....KuKKuK......",
    "...KuK..KuK.....",
    "...KoK..KooK....",
    "...KKK..KKKK....",
  },
  pasoB = {
    "....KuKKuK......",
    "....KuKKuK......",
    "....KoKKooK.....",
    "....KKKKKKK.....",
  },
  rodilla = {
    "................",
    "................",
    "...KuuuuuuK.....",
    "...KKKKKKKKK....",
  },
}
for k, v in pairs(ZLEGS) do check("piernas zombi " .. k, v, 16) end
local ZSWAP = { u = "U", U = "u", o = "O", O = "o" }

local ZOMB_LYING = {
  ".KKKKK..........",
  "KgggggKKKKKKKKK.",
  "KgeggGKRrrxrKuuK",
  "KggXgGKRrrrrKuoK",
  ".KKKKKKKKKKKKKKK",
}
check("zombi tumbado", ZOMB_LYING, 16)

local function zombie_frame(legs, dx, dy, legmap, arms, map)
  return function(img)
    local lm = map
    if legmap then                      -- primero cambia la pierna, luego la paleta
      lm = {}
      for ch, _ in pairs(PAL) do
        local k = legmap[ch] or ch
        lm[ch] = (map and map[k]) or k
      end
    end
    paint(img, legs, 0, 16, lm)
    local up = ZOMB_UP
    if arms then
      up = {}
      for i, r in ipairs(ZOMB_UP) do up[i] = r end
      for i, r in ipairs(arms) do up[10 + i] = r end
    end
    paint(img, up, dx or 0, dy or 0, map)
  end
end

local function zombie_sprite(name, map, speed)
  local k = speed or 1
  build(name, 16, 20, {
    zombie_frame(ZLEGS.pasoA, 0, 0, nil, nil, map),             -- 1 andar
    zombie_frame(ZLEGS.pasoB, 0, 1, nil, nil, map),             -- 2
    zombie_frame(ZLEGS.pasoA, 0, 0, ZSWAP, nil, map),           -- 3
    zombie_frame(ZLEGS.pasoB, 0, 1, ZSWAP, nil, map),           -- 4
    zombie_frame(ZLEGS.pasoB, 0, -1, nil, ZOMB_ARMS_UP, map),   -- 5 atacar: alza los brazos
    zombie_frame(ZLEGS.pasoA, 2, 1, nil, nil, map),             -- 6 zarpazo
    zombie_frame(ZLEGS.pasoB, -1, 0, nil, nil, map),            -- 7 morir: retrocede
    zombie_frame(ZLEGS.rodilla, -1, 4, nil, nil, map),          -- 8 de rodillas
    function(img) paint(img, ZOMB_LYING, 0, 14, map) end,       -- 9 en el suelo
    function(img)                                               -- 10 charco
      blood_pool(img, 7, 18, 8, 2.5)
      paint(img, ZOMB_LYING, 0, 14, map)
    end,
  }, {
    { "andar", 1, 4 }, { "atacar", 5, 6 }, { "morir", 7, 10 },
  }, { 0.18 * k, 0.18 * k, 0.18 * k, 0.18 * k, 0.25, 0.2, 0.1, 0.14, 0.2, 1.0 })
end

zombie_sprite("zombi", nil, 1)

-- Corredor: piel gris pálida, ropa oscura. Mismo dibujo con otra paleta.
C.t = hex("c2c6b4"); C.T = hex("8b917d"); C.i = hex("d9dccb")
C.v = hex("4b5160"); C.V = hex("343844")
C.a = hex("3b3046"); C.A = hex("2a2233")
zombie_sprite("corredor", { g = "t", G = "T", j = "i", r = "v", R = "V", u = "a", U = "A" }, 0.6)

---------------------------------------------------------------- armas (miran a la derecha)
local GUNS = {
  pistola = {
    ".KKKKKKKK",
    "KMmmmmmmK",
    "KMMnnnnK.",
    ".KnK.....",
    ".KKK.....",
  },
  subfusil = {
    "...KKKKKKKK.",
    "KKKMmmmmmmmK",
    "KnnMMMMMMMK.",
    "K.KnKKnK....",
    "..KnK.nK....",
    "..KKK.KK....",
  },
  escopeta = {
    "......KKKKKKKKK",
    "KKKKKKMmmmmmmmK",
    "KDddddKMMMMMMK.",
    ".KDDKnK........",
    "..KKKK.........",
  },
}
for name, rows in pairs(GUNS) do
  check(name, rows, #rows[1])
  build(name, #rows[1], #rows, { function(img) paint(img, rows, 0, 0) end })
end

build("fogonazo", 7, 7, {
  function(img) paint(img, {
    "...f...",
    "..fyf..",
    ".fywyF.",
    "fywwwyF",
    ".fywyF.",
    "..fyF..",
    "...F...",
  }, 0, 0) end,
  function(img) paint(img, {
    ".......",
    "...f...",
    "..fyF..",
    ".fywyF.",
    "..fyF..",
    "...F...",
    ".......",
  }, 0, 0) end,
}, {}, 0.04)

---------------------------------------------------------------- objetos que caen
build("moneda", 7, 7, {
  function(img) paint(img, {
    ".KKKKK.", "KyyyyfK", "KywyyfK", "KyyyyfK", "KyyyyfK", "KyffffK", ".KKKKK." }, 0, 0) end,
  function(img) paint(img, {
    "..KKK..", ".KyyfK.", ".KwyfK.", ".KyyfK.", ".KyyfK.", ".KyffK.", "..KKK.." }, 0, 0) end,
  function(img) paint(img, {
    "...K...", "..KfK..", "..KwK..", "..KfK..", "..KfK..", "..KfK..", "...K..." }, 0, 0) end,
  function(img) paint(img, {
    "..KKK..", ".KfyyK.", ".KfwyK.", ".KfyyK.", ".KfyyK.", ".KffyK.", "..KKK.." }, 0, 0) end,
}, { { "girar", 1, 4 } }, 0.12)

build("botiquin", 9, 8, {
  function(img) paint(img, {
    ".KKKKKKK.",
    "KwwwwwwwK",
    "KwwwxwwwK",
    "KwwxxxwwK",
    "KwwwxwwwK",
    "KWWWWWWWK",
    "KlLLLLLlK",
    ".KKKKKKK.",
  }, 0, 0) end,
})

---------------------------------------------------------------- suelo (losetas de 16x16)
local G1, G2, G3, G4 = hex("4f8a3a"), hex("3f7230"), hex("66a447"), hex("2f5a25")
local A1, A2, A3 = hex("4a4d57"), hex("3d3f48"), hex("5a5e69")
local S1, S2, S3 = hex("a4a4ad"), hex("8a8a94"), hex("6c6c76")
local T1, T2 = hex("8a6a45"), hex("6b5033")

local function grass(img, variant)
  seed = 100 + variant * 77
  rect(img, 0, 0, 16, 16, G1)
  for i = 1, 26 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), G2) end
  for i = 1, 10 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), G3) end
  for i = 1, 3 do                           -- matojos
    local x, y = math.floor(rnd() * 14) + 1, math.floor(rnd() * 13) + 2
    px(img, x, y, G3); px(img, x - 1, y + 1, G3); px(img, x + 1, y + 1, G3)
    px(img, x, y + 1, G4)
  end
  if variant == 2 then                      -- florecillas
    for i = 1, 3 do
      local x, y = math.floor(rnd() * 14) + 1, math.floor(rnd() * 14) + 1
      px(img, x, y, C.y)
    end
  elseif variant == 3 then                  -- piedrecitas
    for i = 1, 3 do
      local x, y = math.floor(rnd() * 14) + 1, math.floor(rnd() * 14) + 1
      px(img, x, y, S2); px(img, x + 1, y, S3)
    end
  end
end

local function asphalt(img, variant)
  seed = 300 + variant * 31
  rect(img, 0, 0, 16, 16, A1)
  for i = 1, 30 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), A2) end
  for i = 1, 14 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), A3) end
  if variant == 2 then                      -- grieta
    local x, y = 3, 2
    for i = 1, 12 do
      px(img, x, y, C.K)
      if rnd() < 0.5 then x = x + 1 else y = y + 1 end
      if i == 6 then px(img, x + 1, y - 1, C.K); px(img, x + 2, y - 1, C.K) end
    end
  end
end

local tiles = {
  function(img) grass(img, 0) end,
  function(img) grass(img, 1) end,
  function(img) grass(img, 2) end,
  function(img) grass(img, 3) end,
  function(img) asphalt(img, 0) end,
  function(img) asphalt(img, 1) end,
  function(img) asphalt(img, 2) end,
  function(img)                               -- 8 línea central
    asphalt(img, 1)
    rect(img, 7, 2, 2, 12, C.y)
    px(img, 7, 13, hex("c9a94a")); px(img, 8, 2, hex("c9a94a"))
  end,
  function(img)                               -- 9 acera
    rect(img, 0, 0, 16, 16, S1)
    rect(img, 0, 0, 16, 1, S2); rect(img, 0, 8, 16, 1, S2)
    rect(img, 7, 1, 1, 7, S2); rect(img, 15, 9, 1, 7, S2)
    seed = 909
    for i = 1, 8 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), S2) end
  end,
  function(img)                               -- 10 bordillo izquierdo (asfalto a la derecha)
    asphalt(img, 0)
    rect(img, 0, 0, 3, 16, S1); rect(img, 3, 0, 1, 16, S3)
  end,
  function(img)                               -- 11 bordillo derecho
    asphalt(img, 1)
    rect(img, 13, 0, 3, 16, S1); rect(img, 12, 0, 1, 16, S3)
  end,
  function(img)                               -- 12 tierra
    seed = 1212
    rect(img, 0, 0, 16, 16, T1)
    for i = 1, 30 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), T2) end
    for i = 1, 6 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), S2) end
  end,
}
build("suelo", 16, 16, tiles, {})

-- Manchas de sangre para el suelo
build("manchas", 16, 16, {
  function(img)
    seed = 51
    ellipse(img, 8, 8, 5, 3.5, C.X); ellipse(img, 7, 7.5, 3, 2, C.x)
    for i = 1, 7 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), C.X) end
  end,
  function(img)
    seed = 52
    ellipse(img, 6, 9, 3, 2, C.X); ellipse(img, 11, 6, 2, 1.5, C.X)
    for i = 1, 10 do px(img, math.floor(rnd() * 16), math.floor(rnd() * 16), C.x) end
  end,
  function(img)
    for i = 0, 9 do px(img, 3 + i, 8 + (i % 3 == 0 and 1 or 0), C.X) end
    ellipse(img, 13, 8.5, 2, 1.5, C.x)
  end,
}, {})

---------------------------------------------------------------- objetos del mapa
-- Coche abandonado visto desde arriba (mira hacia arriba)
build("coche", 22, 34, {
  function(img)
    local R1, R2, R3 = hex("8a3a3a"), hex("5e2626"), hex("b0584a")
    local GL, GL2 = hex("6a8aa0"), hex("2e3f50")
    rect(img, 0, 5, 3, 7, C.K); rect(img, 19, 5, 3, 7, C.K)       -- ruedas
    rect(img, 0, 22, 3, 7, C.K); rect(img, 19, 22, 3, 7, C.K)
    box(img, 2, 1, 18, 32, R1)
    rect(img, 3, 2, 16, 2, R3)                                    -- capó con brillo
    rect(img, 18, 3, 1, 28, R2)
    box(img, 4, 8, 14, 6, GL2); rect(img, 5, 9, 7, 2, GL)         -- parabrisas roto
    px(img, 12, 10, C.W); px(img, 13, 11, C.W)
    box(img, 4, 14, 14, 10, R2); rect(img, 5, 15, 12, 1, R1)      -- techo
    box(img, 4, 24, 14, 4, GL2); rect(img, 5, 25, 5, 1, GL)       -- luna trasera
    px(img, 3, 1, C.y); px(img, 18, 1, C.y)                       -- faros
    px(img, 3, 32, C.e); px(img, 18, 32, C.e)
    seed = 77
    for i = 1, 14 do px(img, 3 + math.floor(rnd() * 16), 2 + math.floor(rnd() * 30), hex("9c6a3a")) end
  end,
})

build("barril", 10, 13, {
  function(img)
    local B1, B2, B3 = hex("b5652e"), hex("7d401c"), hex("d8894a")
    box(img, 0, 1, 10, 12, B1)
    rect(img, 1, 4, 8, 1, B2); rect(img, 1, 9, 8, 1, B2)
    rect(img, 2, 2, 1, 9, B3)
    rect(img, 1, 1, 8, 2, B2); rect(img, 2, 1, 6, 1, C.K)
    rect(img, 7, 2, 2, 10, B2)
  end,
})

build("caja", 12, 12, {
  function(img)
    box(img, 0, 0, 12, 12, C.d)
    rect(img, 1, 1, 10, 1, hex("b9824c"))
    rect(img, 1, 5, 10, 1, C.D); rect(img, 1, 6, 10, 1, C.D)
    for i = 1, 10 do px(img, i, i, C.D) end
    rect(img, 10, 1, 1, 10, C.D)
  end,
})

build("sacos", 48, 16, {
  function(img)
    local Y1, Y2, Y3 = hex("c2a66e"), hex("8f7448"), hex("dcc48c")
    local function bag(x, y)
      ellipse(img, x + 4, y + 3, 5, 3.4, C.K)
      ellipse(img, x + 4, y + 3, 4, 2.4, Y1)
      rect(img, x + 1, y + 4, 7, 1, Y2)
      px(img, x + 2, y + 1, Y3); px(img, x + 3, y + 1, Y3)
    end
    for i = 0, 4 do bag(1 + i * 9, 8) end
    for i = 0, 3 do bag(5 + i * 9, 2) end
  end,
})

build("arbol", 26, 32, {
  function(img)
    local L1, L2, L3 = hex("3f8a3a"), hex("2c6528"), hex("5fae4a")
    local TR, TR2 = hex("6b4429"), hex("4a2e1b")
    rect(img, 11, 18, 5, 12, TR); rect(img, 14, 18, 2, 12, TR2)
    rect(img, 9, 28, 9, 2, TR2)
    local blobs = { {13, 9, 10, 8}, {7, 13, 6, 5}, {19, 13, 6, 5}, {13, 4, 6, 4} }
    for _, b in ipairs(blobs) do ellipse(img, b[1], b[2], b[3], b[4], L2) end
    for _, b in ipairs(blobs) do ellipse(img, b[1] - 1, b[2] - 1, b[3] - 1.5, b[4] - 1.5, L1) end
    seed = 404
    for i = 1, 26 do
      local x, y = math.floor(rnd() * 20) + 3, math.floor(rnd() * 12) + 1
      if app.pixelColor.rgbaA(img:getPixel(x, y)) > 0 then px(img, x, y, L3) end
    end
    outline(img)
  end,
})

build("arbusto", 14, 10, {
  function(img)
    local L1, L2, L3 = hex("3f8a3a"), hex("2c6528"), hex("5fae4a")
    ellipse(img, 4, 6, 4, 3.5, L2); ellipse(img, 9, 5, 4.5, 4, L2)
    ellipse(img, 4, 5.5, 3, 2.5, L1); ellipse(img, 9, 4.5, 3.5, 3, L1)
    px(img, 8, 2, L3); px(img, 3, 4, L3); px(img, 10, 3, L3)
    outline(img)
  end,
})

build("farola", 9, 32, {
  function(img)
    rect(img, 3, 6, 3, 24, C.K); rect(img, 4, 7, 1, 22, C.M)
    box(img, 1, 0, 7, 6, C.n); rect(img, 2, 4, 5, 1, C.y)
    box(img, 2, 28, 5, 4, C.n)
  end,
})

-- Bidón con fuego (3 fotogramas)
local function fire_barrel(phase)
  return function(img)
    local B1, B2 = hex("6b717d"), hex("3a3e47")
    box(img, 1, 8, 10, 10, B1)
    rect(img, 2, 11, 8, 1, B2); rect(img, 2, 15, 8, 1, B2)
    rect(img, 8, 9, 2, 8, B2)
    seed = 600 + phase * 13
    for i = 1, 22 do
      local x = 2 + math.floor(rnd() * 8)
      local hgt = math.floor(rnd() * 7) + 1
      local c = hgt > 5 and C.y or (hgt > 2 and C.f or C.F)
      px(img, x, 8 - hgt, C.F)
      if hgt > 1 then px(img, x, 9 - hgt, c) end
    end
    rect(img, 2, 7, 8, 1, C.f)
    rect(img, 3, 6, 6, 1, C.y)
  end
end
build("hoguera", 12, 18, { fire_barrel(0), fire_barrel(1), fire_barrel(2) },
  { { "arder", 1, 3 } }, 0.12)

---------------------------------------------------------------- interfaz
build("joystick", 34, 34, {
  function(img)
    ellipse(img, 17, 17, 16.5, 16.5, C.K)
    ellipse(img, 17, 17, 15.5, 15.5, hex("2a2438"))
    ellipse(img, 17, 17, 13.5, 13.5, C.K)
    ellipse(img, 17, 17, 12.5, 12.5, hex("3b3450"))
  end,
  function(img)
    ellipse(img, 17, 17, 8, 8, C.K)
    ellipse(img, 17, 17, 7, 7, hex("c9d3dd"))
    ellipse(img, 16, 16, 5, 5, C.w)
    ellipse(img, 18.5, 18.5, 3, 3, hex("c9d3dd"))
  end,
}, { { "base", 1, 1 }, { "boton", 2, 2 } })

build("corazon", 9, 8, {
  function(img) paint(img, {
    ".KK...KK.",
    "KxwxKxxxK",
    "KwxxxxxXK",
    "KxxxxxxXK",
    ".KxxxxXK.",
    "..KxxXK..",
    "...KXK...",
    "....K....",
  }, 0, 0) end,
})

-- Letra pixelada 3x5 (cada carácter ocupa 4x6). '#' es la Ñ, '*' el signo por.
local GLYPHS = {
  ["0"] = {"###","#.#","#.#","#.#","###"}, ["1"] = {".#.","##.",".#.",".#.","###"},
  ["2"] = {"###","..#","###","#..","###"}, ["3"] = {"###","..#",".##","..#","###"},
  ["4"] = {"#.#","#.#","###","..#","..#"}, ["5"] = {"###","#..","###","..#","###"},
  ["6"] = {"###","#..","###","#.#","###"}, ["7"] = {"###","..#",".#.",".#.",".#."},
  ["8"] = {"###","#.#","###","#.#","###"}, ["9"] = {"###","#.#","###","..#","###"},
  A = {".#.","#.#","###","#.#","#.#"}, B = {"##.","#.#","##.","#.#","##."},
  C = {".##","#..","#..","#..",".##"}, D = {"##.","#.#","#.#","#.#","##."},
  E = {"###","#..","##.","#..","###"}, F = {"###","#..","##.","#..","#.."},
  G = {".##","#..","#.#","#.#",".##"}, H = {"#.#","#.#","###","#.#","#.#"},
  I = {"###",".#.",".#.",".#.","###"}, J = {"..#","..#","..#","#.#",".#."},
  K = {"#.#","#.#","##.","#.#","#.#"}, L = {"#..","#..","#..","#..","###"},
  M = {"#.#","###","###","#.#","#.#"}, N = {"##.","#.#","#.#","#.#","#.#"},
  ["#"] = {"###","...","##.","#.#","#.#"},
  O = {".#.","#.#","#.#","#.#",".#."}, P = {"##.","#.#","##.","#..","#.."},
  Q = {".#.","#.#","#.#","##.",".##"}, R = {"##.","#.#","##.","#.#","#.#"},
  S = {".##","#..",".#.","..#","##."}, T = {"###",".#.",".#.",".#.",".#."},
  U = {"#.#","#.#","#.#","#.#","###"}, V = {"#.#","#.#","#.#","#.#",".#."},
  W = {"#.#","#.#","###","###","#.#"}, X = {"#.#","#.#",".#.","#.#","#.#"},
  Y = {"#.#","#.#",".#.",".#.",".#."}, Z = {"###","..#",".#.","#..","###"},
  [":"] = {"...",".#.","...",".#.","..."}, ["/"] = {"..#","..#",".#.","#..","#.."},
  ["!"] = {".#.",".#.",".#.","...",".#."}, ["?"] = {"##.","..#",".#.","...",".#."},
  ["."] = {"...","...","...","...",".#."}, [","] = {"...","...","...",".#.","#.."},
  ["+"] = {"...",".#.","###",".#.","..."}, ["-"] = {"...","...","###","...","..."},
  ["%"] = {"#.#","..#",".#.","#..","#.#"}, ["("] = {".#.","#..","#..","#..",".#."},
  [")"] = {".#.","..#","..#","..#",".#."}, ["*"] = {"...","#.#",".#.","#.#","..."},
  [" "] = {"...","...","...","...","..."},
}
local ORDER = "0123456789ABCDEFGHIJKLMN#OPQRSTUVWXYZ:/!?.,+-%()* "
build("letra", #ORDER * 4, 6, {
  function(img)
    for i = 1, #ORDER do
      local g = GLYPHS[ORDER:sub(i, i)]
      for y = 1, 5 do for x = 1, 3 do
        if g[y]:sub(x, x) == "#" then px(img, (i - 1) * 4 + x - 1, y - 1, C.w) end
      end end
    end
  end,
})

print("Arte dibujado en " .. OUT)
