-- Indicador de ronda pintado con sangre (al estilo de los palotes que se marcan en una pared).
-- Construye dos sprites:
--   palotes (64x26, 9 fotogramas): ronda 1 a 9; el quinto palote tacha los cuatro primeros.
--   cifras_sangre (16x26, 10 fotogramas): dígitos 0 a 9 para la ronda 10 en adelante.
-- Trazos de pincel: gruesos abajo, afinados arriba, con temblor, goterones y chorretones que caen.
local L = dofile(app.params.lib)

local S = L.rampa("sangre")                 -- 1 muy oscura ... 4 viva
local CLARA = L.hex("c23a33")               -- brillo húmedo
local BORDE = L.col("tinta", 1)

---------------------------------------------------------------- pincel
-- Recorre una polilínea pintando discos de radio variable: r0 al principio, r1 al final.
-- Devuelve la máscara (tabla de píxeles) para sombrearla después.
local function trazo(m, pts, r0, r1, temblor, r)
  local total = 0
  for i = 1, #pts - 1 do total = total + math.sqrt((pts[i + 1][1] - pts[i][1]) ^ 2 + (pts[i + 1][2] - pts[i][2]) ^ 2) end
  local hecho = 0
  for i = 1, #pts - 1 do
    local a, b = pts[i], pts[i + 1]
    local l = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
    local pasos = math.max(1, math.ceil(l * 3))
    for k = 0, pasos do
      local t = k / pasos
      local x, y = a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
      local u = total > 0 and (hecho + l * t) / total or 0
      local rad = r0 + (r1 - r0) * u + (r() - 0.5) * temblor
      for yy = math.floor(y - rad - 1), math.ceil(y + rad + 1) do
        for xx = math.floor(x - rad - 1), math.ceil(x + rad + 1) do
          if (xx + 0.5 - x) ^ 2 + (yy + 0.5 - y) ^ 2 <= rad * rad then m[yy * 1000 + xx] = true end
        end
      end
    end
    hecho = hecho + l
  end
end

-- Chorretón: un hilo de 1 px que cae desde (x, y) y acaba en una gota de 2 px.
local function chorreton(m, x, y, largo)
  for k = 0, largo do m[(y + k) * 1000 + x] = true end
  m[(y + largo + 1) * 1000 + x] = true
  m[(y + largo) * 1000 + x + 1] = true
  m[(y + largo + 1) * 1000 + x + 1] = true
end

-- Pinta la máscara: luz arriba a la izquierda, sombra abajo a la derecha, brillo húmedo, contorno oscuro.
local function sombrear(img, m, r, grumos)
  local function en(x, y) return m[y * 1000 + x] end
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    if en(x, y) then
      local c = S[3]
      if not en(x + 1, y) or not en(x, y + 1) then c = S[2] end              -- borde en sombra
      if not en(x - 1, y) and en(x + 1, y) then c = S[4] end                 -- canto iluminado
      if not en(x, y - 1) and not en(x - 1, y) then c = S[4] end
      if c == S[3] and r() < (grumos or 0.12) then c = S[2] end                          -- grumos
      L.px(img, x, y, c)
    end
  end end
  -- Brillo húmedo: algún píxel claro en el canto iluminado, separado del borde.
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    if en(x, y) and en(x + 1, y) and en(x - 1, y) and not en(x - 2, y) and en(x, y - 1) and en(x, y + 1) and r() < 0.35 then
      L.px(img, x, y, CLARA)
    end
  end end
  L.contorno(img, BORDE)
end

---------------------------------------------------------------- palotes
local PW, PH = 64, 26
local PASO, GRUPO = 7, 33         -- separación entre palotes y entre grupos de cinco

-- Un palote: de arriba (fino) a abajo (grueso), algo inclinado y con temblor.
local function palote(m, x, r, i)
  local inc = (r() - 0.4) * 1.8
  local arriba = 3 + math.floor(r() * 2)
  local abajo = 20 + math.floor(r() * 2)
  local medio = (arriba + abajo) / 2
  trazo(m, { { x + inc, arriba }, { x + inc * 0.4 + (r() - 0.5) * 0.8, medio }, { x, abajo } }, 0.85, 1.7, 0.35, r)
  if r() < 0.6 then chorreton(m, x + (r() < 0.5 and 0 or -1), abajo + 1, 1 + math.floor(r() * 3)) end
end

-- El quinto: un tajo en diagonal que tacha los cuatro anteriores.
local function tachon(m, x0, r)
  trazo(m, { { x0 - 3, 17 + r() }, { x0 + 10, 12 + r() }, { x0 + 25, 6 + r() } }, 1.6, 0.8, 0.35, r)
  chorreton(m, x0 - 2, 19, 1 + math.floor(r() * 2))
end

local function palotes(n)
  return function(img)
    local r = L.azar(97)                -- misma semilla: cada palote sale igual en todas las rondas
    local m = {}
    for k = 1, n do
      local grupo, pos = (k - 1) // 5, (k - 1) % 5
      local x0 = 4 + grupo * GRUPO
      if pos < 4 then palote(m, x0 + pos * PASO, r, k) else tachon(m, x0, r) end
    end
    sombrear(img, m, L.azar(5), 0.03)
  end
end

local fotos = {}
for n = 1, 9 do fotos[n] = palotes(n) end
L.construir("palotes", PW, PH, fotos, nil, nil, nil)

---------------------------------------------------------------- cifras
local CW, CH = 16, 26
-- Recorridos del pincel en una caja de 10x18 (se dibujan desplazados a x+3, y+2).
local CIFRAS = {
  [0] = { { { 5, 0 }, { 8.5, 2 }, { 9.5, 8 }, { 8.5, 15 }, { 5, 18 }, { 1.5, 15 }, { 0.5, 8 }, { 1.5, 2 }, { 5, 0 } } },
  [1] = { { { 2, 4 }, { 5.5, 0 }, { 5.5, 9 }, { 5, 18 } } },
  [2] = { { { 1, 4 }, { 4, 0.5 }, { 8, 1 }, { 9, 5 }, { 7, 10 }, { 1, 17.5 }, { 10, 17 } } },
  [3] = { { { 1, 2 }, { 5, 0 }, { 9, 3 }, { 8, 7 }, { 4, 8.5 } }, { { 4, 8.5 }, { 9, 11 }, { 9, 15 }, { 5, 18 }, { 1, 16 } } },
  [4] = { { { 7.5, 18 }, { 7.5, 9 }, { 7, 0 } }, { { 7, 0 }, { 1, 12 }, { 10, 12 } } },
  [5] = { { { 9, 0.5 }, { 2, 1 } }, { { 2, 1 }, { 1.5, 8 }, { 6, 7 }, { 9, 10 }, { 9, 15 }, { 5.5, 18 }, { 1, 16.5 } } },
  [6] = { { { 8.5, 1 }, { 4, 1.5 }, { 1, 7 }, { 1, 14 }, { 4, 18 }, { 8, 17 }, { 9.5, 13 }, { 7, 9.5 }, { 3, 10 }, { 1, 12.5 } } },
  [7] = { { { 0.5, 1 }, { 10, 0.5 }, { 6, 9 }, { 4, 18 } } },
  [8] = { { { 5, 8.5 }, { 8, 6 }, { 8, 2 }, { 5, 0 }, { 2, 2 }, { 2, 6 }, { 5, 8.5 }, { 9, 12 }, { 9, 16 }, { 5, 18 }, { 1, 16 }, { 1, 12 }, { 5, 8.5 } } },
  [9] = { { { 9, 7 }, { 6, 9.5 }, { 2, 9 }, { 1, 4.5 }, { 3.5, 0.5 }, { 7.5, 0.5 }, { 9.5, 4 }, { 9, 11 }, { 6, 18 } } },
}
-- Dónde caen los chorretones de cada cifra (x, y en la caja).
local GOTAS = {
  [0] = { { 2, 16 } }, [1] = { { 5, 19 } }, [2] = { { 2, 18 }, { 9, 18 } }, [3] = { { 8, 16 } }, [4] = { { 7, 19 } },
  [5] = { { 4, 19 } }, [6] = { { 3, 18 } }, [7] = { { 4, 19 } }, [8] = { { 7, 18 } }, [9] = { { 6, 19 } },
}

local cifras = {}
for d = 0, 9 do
  cifras[d + 1] = function(img)
    local r = L.azar(31 + d * 7)
    local m = {}
    for _, recorrido in ipairs(CIFRAS[d]) do
      local pts = {}
      for i, p in ipairs(recorrido) do pts[i] = { p[1] + 3 + (r() - 0.5) * 0.6, p[2] + 2 + (r() - 0.5) * 0.6 } end
      trazo(m, pts, 1.5, 1.2, 0.45, r)
    end
    for _, g in ipairs(GOTAS[d]) do chorreton(m, g[1] + 3, g[2] + 2, 1 + math.floor(r() * 3)) end
    sombrear(img, m, L.azar(9 + d))
  end
end
L.construir("cifras_sangre", CW, CH, cifras, nil, nil, nil)
