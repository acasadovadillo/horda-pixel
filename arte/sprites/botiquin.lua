-- botiquin (14x12): botiquín en vista 3/4 (tapa arriba, cara sur delante), cruz roja y asa.
local L = dofile(app.params.lib)
local T = L.rampa("tela")
local R = L.rampa("rojo")
local mapa = {
  K = L.col("tinta", 2),        -- contorno abajo-derecha
  o = L.hex("4a4840"),          -- contorno arriba-izquierda
  H = L.col("metal", 2),        -- asa oscura
  h = L.col("metal", 4),        -- asa con luz
  t = T[4],                     -- tapa iluminada
  u = T[3],                     -- tapa en sombra (derecha)
  l = L.hex("e6e2d2"),          -- filo de la tapa con luz
  s = L.hex("3c3a33"),          -- junta de la tapa
  f = T[3],                     -- cara frontal
  g = T[2],                     -- cara frontal en sombra
  d = L.hex("6e6b60"),          -- mugre
  r = R[2],                     -- cruz
  w = R[3],                     -- cruz con luz
  R = R[1],                     -- cruz en sombra
  c = L.hex("8a8574"),          -- cierre
}
local filas = {
  "....ohhhhK....",
  "....H....H....",
  ".oooHooooHooo.",
  "otttttttttttuK",
  "ollllllllllluK",
  "offfffwrffffgK",
  "offfffwrffffgK",
  "offfwwwwrrffgK",
  "offfrrrrRRffgK",
  "offfffrRffffgK",
  "odffffrRfffdgK",
  ".KKKKKKKKKKKK.",
}
L.comprobar("botiquin", filas, 14)
L.construir("botiquin", 14, 12, { function(img) L.pintar(img, filas, 0, 0, mapa) end })
