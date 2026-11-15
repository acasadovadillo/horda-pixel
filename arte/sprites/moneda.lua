-- moneda (10x10, 'girar' 6 fotogramas): moneda de oro girando sobre su eje vertical.
-- Cara con reborde en relieve y troquel central; canto estriado que asoma al girar.
local L = dofile(app.params.lib)
local O = L.rampa("oro")           -- 1 oscuro .. 5 claro
local borde = L.hex("3d2806")       -- contorno abajo-derecha
local W, H = 10, 10
local R = 5.0                       -- radio vertical (llena 10 filas)

local function cuadro(theta)
  return function(img)
    local c, s = math.cos(theta), math.sin(theta)
    local rx = math.max(0.55, R * math.abs(c))
    local lado = (c * s >= 0) and 1 or -1   -- hacia dónde asoma el canto
    local d = 2.2 * math.abs(s)             -- grosor visible del canto
    local fx = 5 - lado * d / 2             -- centro de la cara
    local bx = 5 + lado * d / 2             -- centro de la cara de atrás
    local function dentro(x, y, cx)
      local u, v = (x + 0.5 - cx) / rx, (y + 0.5 - 5) / R
      return u * u + v * v <= 1.0
    end
    local mascara, cara = {}, {}
    for y = 0, H - 1 do for x = 0, W - 1 do
      local k = y * W + x
      cara[k] = dentro(x, y, fx)
      local en = cara[k]
      if not en then
        for t = 0, 8 do
          if dentro(x, y, fx + (bx - fx) * t / 8) or dentro(x, y, bx) then en = true; break end
        end
      end
      mascara[k] = en
    end end
    local function m(x, y) return x >= 0 and y >= 0 and x < W and y < H and mascara[y * W + x] end
    for y = 0, H - 1 do for x = 0, W - 1 do
      local k = y * W + x
      if mascara[k] then
        local filo = not (m(x - 1, y) and m(x + 1, y) and m(x, y - 1) and m(x, y + 1))
        local col
        if cara[k] then
          local u, v = (x + 0.5 - fx) / rx, (y + 0.5 - 5) / R
          local r = math.sqrt(u * u + v * v)
          local luz = -(u * 0.75 + v * 0.66) / math.max(r, 0.01)
          if r > 0.66 then                        -- reborde en relieve
            if luz > 0.55 then col = O[5] elseif luz > 0.0 then col = O[4]
            elseif luz > -0.55 then col = O[3] else col = O[2] end
          else                                    -- campo rehundido
            col = O[3]
            if r > 0.42 and luz > 0.35 then col = O[2] end      -- sombra del reborde
            if r > 0.42 and luz < -0.45 then col = O[4] end     -- borde que recibe luz
            -- troquel central: barra en relieve (luz a la izquierda, sombra a la derecha)
            if rx >= 3 and math.abs(v) < 0.42 then
              if u > -0.30 and u <= 0.02 then col = O[4]
              elseif u > 0.02 and u <= 0.30 then col = O[2] end
            end
          end
        else                                      -- canto estriado
          if y <= 2 then col = O[3] elseif y >= 7 then col = O[1] else col = O[2] end
          if (y % 2 == 1) and y > 1 and y < 8 then col = (col == O[2]) and O[1] or O[2] end
        end
        if filo then
          local arribaIzq = (x + 0.5 < 5 and y < 5)
          col = arribaIzq and O[2] or borde
          if not cara[k] and arribaIzq then col = O[1] end
        end
        img:drawPixel(x, y, col)
      end
    end end
    -- destello en el canto cuando la moneda está de perfil
    if rx < 1.5 then L.px(img, math.floor(5 - d / 2 + 0.5), 2, O[5]); L.px(img, math.floor(5 - d / 2 + 0.5), 3, O[4]) end
  end
end

local cuadros = {}
for i = 0, 5 do cuadros[i + 1] = cuadro(i * math.pi / 6) end
L.construir("moneda", W, H, cuadros, { { "girar", 1, 6 } }, 0.09)
