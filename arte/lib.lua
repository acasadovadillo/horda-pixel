-- Librería común para dibujar los sprites de Horda Pixel dentro de Aseprite.
-- Cada archivo de arte/sprites/ empieza con:   local L = dofile(app.params.lib)
-- Los colores son enteros (app.pixelColor), así se pueden comparar con ==.

local L = {}
L.OUT = app.params.out or "."

local pc = app.pixelColor

---------------------------------------------------------------- color
-- "rrggbb" -> color entero opaco
function L.hex(h)
  h = h:gsub("#", "")
  return pc.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16), 255)
end

-- Paleta: rampas de oscuro (1) a claro (n). Tonos apagados, luz de atardecer nublado.
L.P = {
  tinta      = { "0e0d12", "1a1920", "26252e" },                          -- contornos y negros
  piel       = { "4a2f28", "7a4e3c", "a36f55", "c4937a", "deb89e" },
  pelo       = { "1c1512", "2e221b", "45342a", "5e4a3a" },
  chaqueta   = { "1b2430", "2a3a4d", "3b526b", "52708c", "7391ab" },      -- chaqueta del jugador (azul acero)
  caqui      = { "2a231b", "40362a", "5a4c3a", "77664f", "958463" },      -- pantalón del jugador
  cuero      = { "17120f", "261d18", "3a2c23", "524033", "6e5844" },      -- botas, mochila, correas
  vaquero    = { "1a2030", "28324a", "3a4866", "526285" },
  zombi      = { "2b3329", "45503f", "61705a", "7f8f74", "a0ad90" },      -- piel de zombi (gris verdoso)
  palido     = { "3a3d3a", "5a5f58", "7d8379", "a3a89c", "c4c8ba" },      -- piel del corredor
  carne      = { "3d0f12", "6b161b", "94222a", "b8433f" },                -- heridas
  sangre     = { "2e070b", "520c12", "7a121a", "a31d24" },
  ropa_a     = { "2e1814", "4a2620", "6b3a2e", "8a5340" },                -- camisa granate sucia
  ropa_b     = { "1e2a2c", "2f4244", "446062", "5f8082" },                -- sudadera gris azulada
  ropa_c     = { "33290f", "54441c", "78632c", "9c8444" },                -- mostaza sucio
  tela       = { "5c5a52", "85837a", "aeab9f", "d1cec0" },                -- blanco sucio, vendas
  metal      = { "121418", "1f2329", "323840", "4b535e", "6e7885", "9aa4b0" }, -- armas, acero
  madera     = { "26180e", "3f2917", "5c3d22", "7b5631", "9a7446" },
  oxido      = { "361a0e", "5c2c14", "86451d", "ad6a2e" },
  asfalto    = { "1e1f24", "292b31", "34363d", "41444c", "51545d" },
  hormigon   = { "4a4a4c", "626264", "7b7b7c", "949493", "adaca8" },
  hierba     = { "18261a", "24381f", "345028", "4a6a34", "668444" },
  tierra     = { "2a2018", "40301f", "594430", "765c40" },
  hojas      = { "132016", "1e3320", "2e4a2a", "426438", "5b7f48" },
  tronco     = { "1e1610", "32241a", "4a3626", "634a34" },
  fuego      = { "7a1c0a", "c2410c", "f08a1c", "ffc93a", "fff1a8" },
  cristal    = { "17222b", "24394a", "3b5a70", "6d93a8", "b5d0db" },
  pintura    = { "3a0f10", "5e1a1a", "872a26", "ad4236", "c96a55" },      -- chapa roja de coche
  senal      = { "6b5a1e", "9c8530", "c9ad45", "e0c966" },                -- pintura amarilla de carretera
  oro        = { "5a3d0c", "94680f", "cc9a1e", "f2c84a", "fff0a0" },
  rojo       = { "7a1218", "b81f26", "e0403a", "ff7a6b" },                -- cruz roja, interfaz
  saco       = { "4a3f2a", "6b5c3e", "8c7a54", "ab986e" },                -- arpillera
  blanco     = { "ffffff" },
}

-- Color i de una rampa (1 = el más oscuro). Se recorta al rango.
function L.col(nombre, i)
  local r = L.P[nombre]
  if not r then error("rampa desconocida: " .. tostring(nombre)) end
  i = math.max(1, math.min(#r, i or 1))
  return L.hex(r[i])
end

-- Toda la rampa como lista de colores.
function L.rampa(nombre)
  local r = L.P[nombre]
  if not r then error("rampa desconocida: " .. tostring(nombre)) end
  local t = {}
  for i, h in ipairs(r) do t[i] = L.hex(h) end
  return t
end

function L.alfa(c) return pc.rgbaA(c) end

---------------------------------------------------------------- píxeles
function L.px(img, x, y, c)
  if c == nil then return end
  x = math.floor(x + 0.5); y = math.floor(y + 0.5)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end

function L.get(img, x, y)
  if x < 0 or y < 0 or x >= img.width or y >= img.height then return 0 end
  return img:getPixel(x, y)
end

function L.opaco(img, x, y) return pc.rgbaA(L.get(img, x, y)) > 0 end

function L.borrar(img, x, y)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, 0) end
end

function L.rect(img, x, y, w, h, c)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do L.px(img, xx, yy, c) end end
end

-- Línea de 1 px (Bresenham).
function L.linea(img, x0, y0, x1, y1, c)
  x0 = math.floor(x0 + 0.5); y0 = math.floor(y0 + 0.5)
  x1 = math.floor(x1 + 0.5); y1 = math.floor(y1 + 0.5)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local e = dx + dy
  while true do
    L.px(img, x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * e
    if e2 >= dy then e = e + dy; x0 = x0 + sx end
    if e2 <= dx then e = e + dx; y0 = y0 + sy end
  end
end

-- Línea gruesa (un miembro, un cañón): grosor en píxeles, extremos redondeados.
function L.grueso(img, x0, y0, x1, y1, grosor, c)
  local r = grosor / 2
  local dx, dy = x1 - x0, y1 - y0
  local l2 = dx * dx + dy * dy
  for y = math.floor(math.min(y0, y1) - r - 1), math.ceil(math.max(y0, y1) + r + 1) do
    for x = math.floor(math.min(x0, x1) - r - 1), math.ceil(math.max(x0, x1) + r + 1) do
      local cx, cy = x + 0.5, y + 0.5
      local t = l2 > 0 and math.max(0, math.min(1, ((cx - x0) * dx + (cy - y0) * dy) / l2)) or 0
      local qx, qy = x0 + dx * t, y0 + dy * t
      if (cx - qx) ^ 2 + (cy - qy) ^ 2 <= r * r then L.px(img, x, y, c) end
    end
  end
end

-- Elipse rellena con centro (cx, cy) y radios (rx, ry); admite decimales.
function L.elipse(img, cx, cy, rx, ry, c)
  for y = math.floor(cy - ry), math.ceil(cy + ry) do
    for x = math.floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      if dx * dx + dy * dy <= 1 then L.px(img, x, y, c) end
    end
  end
end

-- Polígono relleno. pts = { {x, y}, {x, y}, ... }
function L.poligono(img, pts, c)
  local miny, maxy = math.huge, -math.huge
  for _, p in ipairs(pts) do miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2]) end
  for y = math.floor(miny), math.ceil(maxy) do
    local cy = y + 0.5
    local xs = {}
    for i = 1, #pts do
      local a, b = pts[i], pts[i % #pts + 1]
      if (a[2] <= cy and b[2] > cy) or (b[2] <= cy and a[2] > cy) then
        xs[#xs + 1] = a[1] + (cy - a[2]) / (b[2] - a[2]) * (b[1] - a[1])
      end
    end
    table.sort(xs)
    for i = 1, #xs - 1, 2 do
      for x = math.floor(xs[i] + 0.5), math.floor(xs[i + 1] - 0.5) do L.px(img, x, y, c) end
    end
  end
end

-- Pinta filas de caracteres. '.' y ' ' son transparentes; mapa: carácter -> color.
function L.pintar(img, filas, ox, oy, mapa)
  for y, fila in ipairs(filas) do
    for x = 1, #fila do
      local ch = fila:sub(x, x)
      if ch ~= "." and ch ~= " " then
        local c = mapa[ch]
        if c == nil then error("carácter sin color en el mapa: '" .. ch .. "'") end
        L.px(img, ox + x - 1, oy + y - 1, c)
      end
    end
  end
end

-- Comprueba que todas las filas miden lo mismo (evita dibujos torcidos).
function L.comprobar(nombre, filas, ancho)
  for i, f in ipairs(filas) do
    if #f ~= ancho then error(nombre .. ": la fila " .. i .. " mide " .. #f .. " y debe medir " .. ancho) end
  end
end

-- Contorno de 1 px alrededor de lo opaco. opciones: { diagonal = true, solo = función(x, y) -> bool }
function L.contorno(img, c, opciones)
  opciones = opciones or {}
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = pc.rgbaA(img:getPixel(x, y)) > 0 end end
  local function op(x, y) return x >= 0 and y >= 0 and x < w and y < h and s[y * w + x] end
  for y = 0, h - 1 do for x = 0, w - 1 do
    if not s[y * w + x] then
      local n = op(x - 1, y) or op(x + 1, y) or op(x, y - 1) or op(x, y + 1)
      if not n and opciones.diagonal then
        n = op(x - 1, y - 1) or op(x + 1, y - 1) or op(x - 1, y + 1) or op(x + 1, y + 1)
      end
      if n and (not opciones.solo or opciones.solo(x, y)) then img:drawPixel(x, y, c) end
    end
  end end
end

-- Sustituye un color por otro en toda la imagen (variantes de paleta).
function L.cambiar(img, de, a)
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    if img:getPixel(x, y) == de then img:drawPixel(x, y, a) end
  end end
end

-- Sustituye varios colores a la vez: mapa = { [colorViejo] = colorNuevo, ... }
function L.repaletar(img, mapa)
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    local n = mapa[img:getPixel(x, y)]
    if n then img:drawPixel(x, y, n) end
  end end
end

-- Copia src sobre dst en (dx, dy); los píxeles transparentes no tapan. espejo = voltear en horizontal.
function L.pegar(dst, src, dx, dy, espejo)
  for y = 0, src.height - 1 do for x = 0, src.width - 1 do
    local c = src:getPixel(espejo and (src.width - 1 - x) or x, y)
    if pc.rgbaA(c) > 0 then L.px(dst, dx + x, dy + y, c) end
  end end
end

function L.imagen(w, h) return Image(w, h, ColorMode.RGB) end

-- Generador pseudoaleatorio con semilla: el arte sale igual cada vez.
function L.azar(semilla)
  local s = semilla or 1
  return function()
    s = (s * 1103515245 + 12345) % 2147483648
    return s / 2147483648
  end
end

-- Salpica píxeles de varios colores en un rectángulo. densidad 0..1.
-- sobre = true solo pinta encima de píxeles ya opacos (textura sin salirse de la forma).
function L.ruido(img, x, y, w, h, colores, densidad, r, sobre)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do
    if r() < densidad and (not sobre or L.opaco(img, xx, yy)) then
      L.px(img, xx, yy, colores[1 + math.floor(r() * #colores)])
    end
  end end
end

---------------------------------------------------------------- construir sprite
-- nombre: nombre del archivo y del sprite.
-- fotogramas: lista de funciones (img, i) que dibujan cada fotograma (o de Image ya dibujadas).
-- etiquetas: { { "nombre", desde, hasta }, ... } con índices desde 1.
-- duraciones: segundos; un número para todos o una lista por fotograma.
-- puntos: anclajes en píxeles del lienzo. { hombro = { x, y } } fijo,
--         o por fotograma: { hombro = { { x, y }, { x, y }, ... } }.
function L.construir(nombre, w, h, fotogramas, etiquetas, duraciones, puntos)
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = nombre
  for _ = 2, #fotogramas do spr:newEmptyFrame() end
  for i, f in ipairs(fotogramas) do
    local img
    if type(f) == "function" then
      img = Image(w, h, ColorMode.RGB)
      f(img, i)
    else
      img = f
    end
    if img.width ~= w or img.height ~= h then
      error(nombre .. ": el fotograma " .. i .. " mide " .. img.width .. "x" .. img.height .. " y el lienzo " .. w .. "x" .. h)
    end
    -- Píxel art: alfa solo 0 o 255.
    for y = 0, h - 1 do for x = 0, w - 1 do
      local c = img:getPixel(x, y)
      local a = pc.rgbaA(c)
      if a > 0 and a < 255 then
        img:drawPixel(x, y, a >= 128 and pc.rgba(pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), 255) or 0)
      end
    end end
    spr:newCel(spr.layers[1], i, img, Point(0, 0))
    local d = type(duraciones) == "table" and duraciones[i] or duraciones
    spr.frames[i].duration = d or 0.1
  end
  for _, t in ipairs(etiquetas or {}) do
    if t[2] < 1 or t[3] > #fotogramas or t[2] > t[3] then
      error(nombre .. ": etiqueta '" .. t[1] .. "' fuera de rango")
    end
    local tag = spr:newTag(t[2], t[3])
    tag.name = t[1]
  end
  for nom, p in pairs(puntos or {}) do
    if type(p[1]) == "table" then
      if #p ~= #fotogramas then error(nombre .. ": el punto '" .. nom .. "' necesita un valor por fotograma") end
      for i, q in ipairs(p) do
        local s = spr:newSlice(Rectangle(q[1], q[2], 1, 1))
        s.name = nom .. "#" .. (i - 1)
      end
    else
      local s = spr:newSlice(Rectangle(p[1], p[2], 1, 1))
      s.name = nom
    end
  end
  spr:saveAs(L.OUT .. "/" .. nombre .. ".aseprite")
  spr:close()
  print("  " .. nombre .. ": " .. w .. "x" .. h .. ", " .. #fotogramas .. " fotogramas")
end

return L
