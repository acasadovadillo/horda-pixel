-- joystick (52x52): 'base' = aro exterior oscuro con plato rehundido; 'boton' = seta de goma
-- de unos 26 px centrada en {26,26}. Luz arriba a la izquierda. Todo opaco (el juego pone la transparencia).
local L = dofile(app.params.lib)
local W = 52
local C = 26
local lx, ly = -0.62, -0.78                    -- dirección de la luz en el plano
local M = L.rampa("metal")
local T = L.rampa("tinta")
local goma = { L.hex("141519"), L.hex("202227"), L.hex("2d3036"), L.hex("3e424a"), L.hex("565b65"), L.hex("7a808b") }

local function dist(x, y) local dx, dy = x + 0.5 - C, y + 0.5 - C; return math.sqrt(dx * dx + dy * dy), dx, dy end

local function base(img)
  local r = L.azar(7)
  for y = 0, W - 1 do for x = 0, W - 1 do
    local d, dx, dy = dist(x, y)
    if d <= 25.6 then
      local nd = (dx * lx + dy * ly) / math.max(d, 0.01)   -- 1 = mira a la luz
      local col
      if d > 24.6 then col = T[1]                                          -- filo exterior
      elseif d > 21.5 then                                                 -- lomo del aro (convexo)
        if nd > 0.55 then col = M[4] elseif nd > 0.0 then col = M[3] elseif nd > -0.6 then col = M[2] else col = M[1] end
        if d > 23.6 and nd > 0.75 then col = M[5] end
      elseif d > 19.5 then                                                 -- talud interior (cóncavo)
        if nd < -0.5 then col = M[3] elseif nd < 0.2 then col = M[2] else col = M[1] end
      else                                                                 -- plato rehundido
        col = T[3]
        if d > 17 and nd > 0.1 then col = T[2] end                          -- sombra del aro
        if d > 16 and nd < -0.55 then col = M[2] end                        -- luz rebotada abajo a la derecha
      end
      img:drawPixel(x, y, col)
    end
  end end
  -- muescas de agarre en el lomo del aro (grupos de 2 px)
  for k = 0, 23 do
    local a = k * math.pi / 12 + math.pi / 24
    local px, py = C + math.cos(a) * 23, C + math.sin(a) * 23
    local nd = math.cos(a) * lx + math.sin(a) * ly
    local c = nd > 0.3 and M[2] or M[1]
    L.px(img, px - 0.5, py - 0.5, c)
    L.px(img, px + math.cos(a) - 0.5, py + math.sin(a) - 0.5, c)
  end
  -- flechas de dirección en el plato
  local function flecha(ax, ay, c, cs)
    -- triángulo de 5 px de base apuntando hacia fuera (ax, ay unitario)
    local bx, by = C + ax * 13, C + ay * 13
    local px, py = -ay, ax
    L.poligono(img, { { bx + ax * 3.2 + 0.0, by + ay * 3.2 }, { bx + px * 3, by + py * 3 }, { bx - px * 3, by - py * 3 } }, c)
    -- sombra del relieve hacia abajo a la derecha
  end
  flecha(0, -1, M[4]); flecha(1, 0, M[3]); flecha(0, 1, M[3]); flecha(-1, 0, M[4])
  -- desgaste: rozaduras claras en el lomo superior izquierdo
  for _ = 1, 10 do
    local a = math.pi + r() * math.pi * 0.5
    local rr = 22.2 + r() * 1.5
    local x, y = C + math.cos(a) * rr, C + math.sin(a) * rr
    L.px(img, x - 0.5, y - 0.5, M[4]); L.px(img, x + 0.5, y - 0.5, M[4])
  end
end

local function boton(img)
  local R = 13.0
  for y = 0, W - 1 do for x = 0, W - 1 do
    local d, dx, dy = dist(x, y)
    if d <= R then
      local u, v = dx / R, dy / R
      local col
      if d > R - 1 then
        col = (u * lx + v * ly) > 0.35 and M[2] or T[1]                    -- contorno
      elseif d > R - 2.6 then                                              -- aro metálico
        local nd = (u * lx + v * ly) / math.max(d / R, 0.01)
        if nd > 0.6 then col = M[6] elseif nd > 0.1 then col = M[5] elseif nd > -0.5 then col = M[4] else col = M[3] end
      else                                                                 -- goma abombada
        local rr = d / (R - 2.6)
        local nz = math.sqrt(math.max(0, 1 - rr * rr * 0.75))
        local nx, ny = u * 0.9, v * 0.9
        local lum = -(nx * 0.55 + ny * 0.68) + nz * 0.48                   -- luz arriba-izquierda
        if d < 5.5 then                                                    -- hueco del pulgar (cóncavo)
          local e = (u * 0.55 + v * 0.68) / math.max(d / R, 0.01)          -- >0 abajo a la derecha
          if d > 4.3 then lum = (e > 0.3) and 0.5 or ((e < -0.3) and -0.1 or 0.25)
          else lum = (e < -0.2 and d > 2.5) and 0.1 or 0.3 end
        end
        if lum > 0.62 then col = goma[6] elseif lum > 0.45 then col = goma[5] elseif lum > 0.22 then col = goma[4]
        elseif lum > -0.05 then col = goma[3] elseif lum > -0.3 then col = goma[2] else col = goma[1] end
      end
      img:drawPixel(x, y, col)
    end
  end end
  -- estrías de agarre: puntos en anillo sobre la goma (grupos de 2 px)
  for k = 0, 11 do
    local a = k * math.pi / 6
    local px, py = C + math.cos(a) * 8, C + math.sin(a) * 8
    local nd = math.cos(a) * lx + math.sin(a) * ly
    L.px(img, px - 0.5, py - 0.5, nd > 0.2 and goma[5] or goma[4])
    L.px(img, px + 0.5, py + 0.5, goma[1])
  end
  -- brillo de la goma
  L.rect(img, 19, 18, 2, 1, goma[6]); L.px(img, 18, 19, goma[6])
end

L.construir("joystick", W, W, { base, boton }, { { "base", 1, 1 }, { "boton", 2, 2 } }, 0.1)
