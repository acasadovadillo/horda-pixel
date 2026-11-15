-- Farola (16x60), vista 3/4. 0 encendida, 1 rota y apagada.
-- Poste metálico pintado de gris verdoso sobre zapata de hormigón, brazo curvo y luminaria tipo cabeza.
local L = dofile(app.params.lib)
local W, H = 16, 60

local function R(t) local r = {} for i, h in ipairs(t) do r[i] = L.hex(h) end return r end
local PINT = R{ "15191a", "232a2b", "34403f", "4c5a57", "687872", "8a9890" }
local OX   = L.rampa("oxido")
local HOR  = L.rampa("hormigon")
local FU   = L.rampa("fuego")
local CR   = L.rampa("cristal")
local TI   = L.rampa("tinta")
local CALIDO = R{ "4a3a2a", "6e5538", "97764a" }   -- metal teñido por la luz de la lámpara

local function I(x, y) return y * W + x end
local function dentro(x, y) return x >= 0 and y >= 0 and x < W and y < H end

local function rejilla() return { c = {}, r = {}, k = {} } end
local function pon(G, x, y, rampa, lv, k)
  if not dentro(x, y) then return end
  local i = I(x, y)
  G.c[i] = rampa[math.max(1, math.min(#rampa, lv))]; G.r[i] = rampa; G.k[i] = k or "m"
end
local function hueco(G, x, y) local i = I(x, y); G.c[i] = nil; G.r[i] = nil; G.k[i] = nil end

-- Cilindro vertical: columnas de x0 a x1, luz a la izquierda.
local function cilindro(G, x0, x1, y0, y1, rampa, base)
  base = base or 4
  for y = y0, y1 do
    for x = x0, x1 do
      local u = (x - x0 + 0.5) / (x1 - x0 + 1)
      local lv = u < 0.34 and base + 1 or (u < 0.67 and base or base - 1)
      if x1 - x0 == 1 then lv = (x == x0) and base + 1 or base - 1 end
      pon(G, x, y, rampa, lv)
    end
  end
end

local function volcar(img, G)
  local borde = {}
  for y = 0, H - 1 do for x = 0, W - 1 do
    local i = I(x, y)
    if not G.c[i] then
      local function o(xx, yy) local j = I(xx, yy); return dentro(xx, yy) and G.c[j] and G.k[j] ~= "fino" and j end
      local a = o(x - 1, y) or o(x, y - 1)
      local b = o(x + 1, y) or o(x, y + 1)
      if a then borde[i] = G.r[a][1]
      elseif b then borde[i] = G.r[b][2] end
    end
  end end
  for y = 0, H - 1 do for x = 0, W - 1 do
    local i = I(x, y)
    if G.c[i] then L.px(img, x, y, G.c[i]) elseif borde[i] then L.px(img, x, y, borde[i]) end
  end end
end

-- Poste común a las dos variantes.
local function poste(G, roto)
  -- zapata de hormigón (cara de arriba y cara sur)
  for x = 1, 9 do pon(G, x, 55, HOR, x < 4 and 5 or 4) end
  for x = 1, 9 do pon(G, x, 56, HOR, x < 3 and 4 or 3) end
  for y = 57, 59 do for x = 1, 9 do pon(G, x, y, HOR, x < 3 and 3 or (x > 7 and 1 or 2)) end end
  pon(G, 3, 58, HOR, 1); pon(G, 4, 58, HOR, 1); pon(G, 7, 57, HOR, 3)   -- desconchones
  -- basa del poste: tronco de cono con anillos
  cilindro(G, 3, 7, 49, 55, PINT, 4)
  cilindro(G, 2, 8, 54, 55, PINT, 4)
  cilindro(G, 2, 8, 49, 49, PINT, 5)
  for x = 3, 7 do pon(G, x, 50, PINT, x < 5 and 2 or 1) end              -- sombra bajo el anillo
  -- portezuela de registro
  for y = 51, 53 do pon(G, 5, y, PINT, 2) end
  pon(G, 4, 51, PINT, 5)
  -- fuste inferior
  cilindro(G, 3, 6, 38, 48, PINT, 4)
  cilindro(G, 3, 6, 37, 37, PINT, 5)
  for x = 3, 6 do pon(G, x, 38, PINT, x < 5 and 2 or 1) end
  -- fuste superior, más fino
  cilindro(G, 4, 6, 6, 36, PINT, 4)
  pon(G, 4, 4, PINT, 4); pon(G, 5, 4, PINT, 3); pon(G, 6, 5, PINT, 2)
  pon(G, 4, 5, PINT, 5); pon(G, 5, 5, PINT, 4)
  -- óxido y pintura saltada
  local function ox(x, y, l) if G.c[I(x, y)] then pon(G, x, y, OX, l) end end
  ox(6, 44, 2); ox(6, 45, 2); ox(5, 45, 3); ox(6, 46, 1)
  ox(4, 27, 3); ox(5, 27, 2); ox(5, 28, 2)
  ox(6, 52, 2); ox(7, 53, 1); ox(7, 52, 2)
  if roto then
    ox(5, 16, 3); ox(6, 16, 2); ox(6, 17, 1); ox(4, 33, 3); ox(5, 34, 2); ox(6, 35, 1)
    ox(4, 41, 3); ox(4, 42, 2); ox(3, 46, 3); ox(5, 9, 2); ox(6, 10, 1)
    -- chorreones de óxido bajo los anillos
    ox(6, 39, 2); ox(6, 40, 1); ox(5, 51, 2); ox(5, 52, 1)
  end
  -- cartel de pegatinas / papel: una tira clara de 2x3 a media altura
  pon(G, 4, 30, HOR, 4); pon(G, 4, 31, HOR, 3); pon(G, 5, 31, HOR, 2)
end

local function encendida(img)
  local G = rejilla()
  poste(G, false)
  -- brazo curvo de 2 px
  local brazo = { { 6, 9 }, { 7, 8 }, { 8, 7 }, { 9, 6 }, { 10, 6 } }
  for _, p in ipairs(brazo) do pon(G, p[1], p[2], PINT, 5); pon(G, p[1], p[2] + 1, PINT, 2) end
  pon(G, 7, 9, PINT, 2)
  -- carcasa de la luminaria
  for x = 9, 15 do pon(G, x, 5, PINT, x < 12 and 6 or 5) end
  for x = 9, 15 do pon(G, x, 6, PINT, x < 11 and 5 or 4) end
  for x = 9, 15 do pon(G, x, 7, PINT, x < 13 and 3 or 2) end
  pon(G, 10, 4, PINT, 5); pon(G, 11, 4, PINT, 5); pon(G, 12, 4, PINT, 4); pon(G, 13, 4, PINT, 3)
  -- canto inferior de la carcasa, iluminado por la propia lámpara
  for x = 9, 15 do pon(G, x, 8, CALIDO, x == 9 and 1 or 2) end
  -- cristal encendido
  for x = 10, 14 do pon(G, x, 9, FU, (x >= 11 and x <= 13) and 5 or 4) end
  for x = 11, 13 do pon(G, x, 10, FU, x == 12 and 5 or 4) end
  pon(G, 10, 10, FU, 3); pon(G, 14, 10, FU, 3)
  -- reflejo cálido en la cara derecha del fuste, bajo la lámpara
  pon(G, 6, 11, CALIDO, 2); pon(G, 6, 12, CALIDO, 1)
  volcar(img, G)
end

local function rota(img)
  local G = rejilla()
  poste(G, true)
  -- brazo doblado hacia abajo
  local brazo = { { 6, 9 }, { 7, 8 }, { 8, 8 }, { 9, 8 }, { 10, 9 } }
  for _, p in ipairs(brazo) do pon(G, p[1], p[2], PINT, 4); pon(G, p[1], p[2] + 1, PINT, 2) end
  -- carcasa inclinada, colgando
  local filas = {
    { 10, 9, { 5, 5, 4 } },
    { 11, 10, { 5, 4, 4, 3 } },
    { 12, 11, { 4, 4, 3, 3 } },
    { 13, 12, { 2, 2, 2, 1 } },
  }
  for _, f in ipairs(filas) do
    for j, lv in ipairs(f[3]) do pon(G, f[2] + j - 1, f[1], PINT, lv) end
  end
  -- cristal roto: hueco oscuro con esquirlas
  pon(G, 13, 14, TI, 2); pon(G, 14, 14, CR, 4); pon(G, 15, 14, TI, 2)
  pon(G, 14, 15, CR, 3)
  -- cable colgando
  pon(G, 12, 14, TI, 3, "fino"); pon(G, 12, 15, TI, 3, "fino"); pon(G, 11, 16, TI, 3, "fino")
  volcar(img, G)
end

L.construir("farola", W, H, { encendida, rota }, nil, nil, { base = { 5, 59 }, luz = { { 12, 9 }, { 13, 12 } } })
