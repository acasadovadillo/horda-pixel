-- Banderas para elegir idioma: 0 = España (español), 1 = Estados Unidos (inglés).
-- Lienzo 26x17: tela de 24x13 con contorno, ondeando un poco, con luz desde arriba a la izquierda.
local L = dofile(app.params.lib)

local W, H = 26, 17   -- la tela va de y = 2 a y = 14; se deja aire arriba y abajo
local TW, TH = 24, 13          -- tela

local function hex(h) return L.hex(h) end
local TINTA = L.col("tinta", 2)

-- Desplazamiento vertical de la onda por columna (la tela ondea) y brillo por columna.
local ONDA = {}
local LUZ = {}
for x = 0, TW - 1 do
  ONDA[x] = 0
  LUZ[x] = math.cos((x / TW) * math.pi * 2 - 0.9)   -- >0 cara iluminada, <0 pliegue en sombra
end

-- color(x, y) devuelve { base, sombra, luz } para el píxel de la tela.
local function tela(img, color)
  for x = 0, TW - 1 do
    for y = 0, TH - 1 do
      local c = color(x, y)
      local tono = c[1]
      if LUZ[x] < -0.8 then tono = c[2] elseif LUZ[x] > 0.9 and y < TH - 2 then tono = c[3] end
      if y == TH - 1 and c[2] then tono = c[2] end          -- borde inferior en sombra
      L.px(img, 1 + x, 2 + y, tono)
    end
  end
  L.contorno(img, TINTA)
end

local espana = function(img)
  local rojo = { hex("b8232a"), hex("8a1a20"), hex("d8403c") }
  local amar = { hex("f2c230"), hex("c99a1e"), hex("ffe070") }
  local escudo = { hex("9a3a24"), hex("6e2a1a"), hex("b8553a") }
  local corona = { hex("a8761a"), hex("80590f"), hex("c99a1e") }
  tela(img, function(x, y)
    if y < 3 or y > 9 then return rojo end
    -- escudo muy simplificado a un tercio del ancho
    if x >= 6 and x <= 8 and y >= 4 and y <= 7 then
      if y == 4 then return corona end                  -- corona
      if y == 7 and x ~= 7 then return amar end         -- punta redondeada del escudo
      return escudo
    end
    return amar
  end)
end

local eeuu = function(img)
  local rojo = { hex("b8232a"), hex("8a1a20"), hex("d8403c") }
  local blanco = { hex("e8e6dc"), hex("b9b6aa"), hex("ffffff") }
  local azul = { hex("2a3f7a"), hex("1d2c58"), hex("3b549a") }
  local estrella = { hex("f4f2ea"), hex("c9c6ba"), hex("ffffff") }
  tela(img, function(x, y)
    if x <= 10 and y <= 6 then                       -- cantón azul con estrellas
      if (x % 2 == 1) and (y % 2 == 1) and ((x + y) % 4 == 2) then return estrella end
      if (x % 2 == 1) and (y % 2 == 1) then return estrella end
      return azul
    end
    return (y % 2 == 0) and rojo or blanco             -- 13 franjas, la de arriba roja
  end)
end

L.construir("banderas", W, H, { espana, eeuu }, nil, nil, nil)
