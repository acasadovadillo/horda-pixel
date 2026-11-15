-- Zombis lentos de Horda Pixel: `zombi` (hombre flaco, camisa granate, vaqueros, descalzo de un pie)
-- y `zombi_b` (otra persona). Dibujo píxel a píxel con filas de caracteres; las piezas (cabeza,
-- torso, brazos, piernas) se reutilizan entre fotogramas desplazándolas.
-- Luz: arriba a la izquierda. Lienzo 40x40, suelas en y = 38, cuerpo centrado en x = 20.
local L = dofile(app.params.lib)

---------------------------------------------------------------- colores
local Z, RA, VQ = L.rampa("zombi"), L.rampa("ropa_a"), L.rampa("vaquero")
local PE, CA, SA = L.rampa("pelo"), L.rampa("carne"), L.rampa("sangre")
local TI, CU, TE = L.rampa("tinta"), L.rampa("cuero"), L.rampa("tela")
local OJO = L.hex("c3c8ad")       -- ojo velado, sin pupila
local CUENCA = L.hex("1b2119")    -- cuenca hundida

-- Contorno selectivo: solo se perfila lo que es claro; el borde en sombra ya lo da el propio material.
local OSCURO, BORDE = {}, {}
local function registrar(rampa, nOscuros, borde)
  for i, c in ipairs(rampa) do
    BORDE[c] = borde or rampa[1]
    if i <= nOscuros then OSCURO[c] = true end
  end
end
registrar(Z, 2); registrar(RA, 2); registrar(VQ, 2); registrar(PE, 4, TI[1])
registrar(CA, 2, SA[1]); registrar(SA, 3); registrar(TI, 3); registrar(CU, 4); registrar(TE, 1)
local VQL = L.hex("303b56")       -- luz del vaquero de la pierna lejana
OSCURO[VQL] = true; BORDE[VQL] = VQ[1]
BORDE[OJO] = Z[1]; OSCURO[CUENCA] = true; BORDE[CUENCA] = Z[1]

local function contorno(img, ymax)
  local w, h = img.width, img.height
  local s = {}
  for y = 0, h - 1 do for x = 0, w - 1 do s[y * w + x] = img:getPixel(x, y) end end
  local function claro(x, y)
    if x < 0 or y < 0 or x >= w or y >= h then return nil end
    local c = s[y * w + x]
    if L.alfa(c) == 0 or OSCURO[c] then return nil end
    return BORDE[c] or TI[2]
  end
  for y = 0, math.min(h - 1, ymax or (h - 1)) do for x = 0, w - 1 do
    if L.alfa(s[y * w + x]) == 0 then
      local b = claro(x, y + 1) or claro(x + 1, y) or claro(x - 1, y) or claro(x, y - 1)
      if b then img:drawPixel(x, y, b) end
    end
  end end
end

---------------------------------------------------------------- piezas
local function pieza(nombre, ancho, filas)
  L.comprobar(nombre, filas, ancho)
  return filas
end

-- Mapa del zombi A (lado cercano).
local MA = {
  ["1"] = Z[1], ["2"] = Z[2], ["3"] = Z[3], ["4"] = Z[4], ["5"] = Z[5],
  a = RA[1], b = RA[2], c = RA[3], d = RA[4],
  J = VQ[1], K = VQ[2], L = VQ[3], M = VQ[4],
  h = PE[1], i = PE[2], j = PE[3], k = PE[4],
  e = CUENCA, o = OJO,
  r = CA[2], R = CA[3], v = CA[4],
  s = SA[1], S = SA[2], B = SA[3], X = SA[4],
  T = TI[1], t = TI[2], u = TI[3],
  W = TE[3], w = TE[2],
}
-- Pierna cercana: vaquero roto por la espinilla y pie descalzo.
local MC = {
  J = VQ[1], K = VQ[2], L = VQ[3], M = VQ[4],
  q = Z[4], Q = Z[3], g = Z[2],
  F = Z[4], f = Z[3], x = Z[1], y = Z[5],
  S = SA[2], B = SA[3],
}
-- Pierna lejana: un tono más oscura, con zapato.
local ML = {
  J = TI[2], K = VQ[1], L = VQ[2], M = VQL,
  q = VQ[2], Q = VQ[2], g = VQ[1],
  F = CU[4], f = CU[3], x = CU[1], y = CU[5],
  S = SA[1], B = SA[2],
}

-- Cabeza de perfil, vencida hacia delante. 6x6. Origen base (24, 7).
local CABEZA = pieza("cabeza", 6, {
  ".kjii.",
  "kjii33",
  "iiheo2",
  "hi2344",
  ".h23sX",
  "...2BB",
})
-- La misma con la mandíbula descolgada (ataque). 6x7.
local CABEZA_AB = pieza("cabeza_ab", 6, {
  ".kjii.",
  "kjii33",
  "iiheo2",
  "hi2344",
  ".h23sX",
  "..23sS",
  "...2BB",
})

-- Torso inclinado hacia delante, con la pelvis. 13x13. Origen base (14, 11).
local TORSO = pieza("torso", 13, {
  "........b322.",
  "......cddb221",
  ".....cdddcba.",
  "....cddcccba.",
  "....cdcccbba.",
  "....cccbcba..",
  "...cdcbcbba..",
  "...c3Rbcba...",
  "..ccRrbba....",
  "..cccbbaa....",
  ".ccbcbaa.....",
  ".bcLbaKa.....",
  ".aMLaLK......",
})
-- Torso erguido (toma de impulso, impacto del disparo). 9x13. Origen base (14, 11).
local TORSO_RECTO = pieza("torso_recto", 9, {
  "....cb32.",
  ".cdddcb2.",
  ".cddccbba",
  ".cdcccbba",
  ".ccccbcba",
  ".cdcbccb.",
  ".c3Rbcba.",
  ".cRrcbba.",
  "..ccbcba.",
  "..cbcbaa.",
  ".ccbcbaa.",
  ".bcLbaKa.",
  ".aMLaLK..",
})
-- Torso muy vencido (final del zarpazo). 15x10. Origen base (14, 14).
local TORSO_BAJO = pieza("torso_bajo", 15, {
  ".........cdd322",
  ".......cdddcb21",
  "......cddcccba.",
  ".....cdcccbba..",
  "....cdccbbba...",
  "...c3Rcbbaa....",
  "..ccRrbbaa.....",
  ".cccbbbaa......",
  ".bcLbaKa.......",
  ".aMLaLK........",
})

-- Brazo cercano colgando por delante del vientre. 6x15. Origen base (21, 12).
-- 1 = atrasado, 2 = neutro, 3 = adelantado (péndulo con retardo).
local BRAZO_C = {
  pieza("brazo_c1", 6, {
    ".dd...",
    "ddcb..",
    "dccb..",
    "adcb..",
    "accb..",
    "acbb..",
    ".cba..",
    ".42...",
    ".42...",
    ".R2...",
    ".r2...",
    ".42...",
    ".432..",
    ".432..",
    "..32..",
  }),
  pieza("brazo_c2", 6, {
    ".dd...",
    "ddcb..",
    "dccb..",
    "adcb..",
    "accb..",
    "acbb..",
    ".cba..",
    ".b42..",
    "..42..",
    "..R2..",
    "..r2..",
    "..42..",
    "..432.",
    "..432.",
    "...32.",
  }),
  pieza("brazo_c3", 6, {
    ".dd...",
    "ddcb..",
    "dccb..",
    "adcb..",
    "accb..",
    "acbb..",
    ".cba..",
    ".b42..",
    "..42..",
    "...R2.",
    "...r2.",
    "...42.",
    "...432",
    "...432",
    "....32",
  }),
}

-- Brazo lejano extendido al frente. 11x6. Origen base (25, 14).
local BRAZO_L = pieza("brazo_l", 11, {
  ".bbb.......",
  ".bbbb33....",
  ".aaaa22333.",
  ".......2233",
  ".........32",
  ".........2.",
})

-- Brazos recogidos con las manos en garra a la altura del pecho (toma de impulso).
-- Cercano: 8x9, hombro arriba a la izquierda. Lejano: solo asoma el antebrazo, 6x6.
local BRAZO_C_GARRA = pieza("brazo_c_garra", 8, {
  ".dd...3.",
  "ddcb.434",
  "dccb.432",
  "adcb.42.",
  "accb42..",
  "acb42...",
  ".c442...",
  ".b22....",
  "........",
})
local BRAZO_L_GARRA = pieza("brazo_l_garra", 6, {
  "...3.3",
  "...323",
  "...32.",
  "..32..",
  ".32...",
  "b2....",
})
-- Brazo cercano lanzado al frente (golpe). 16x5.
local BRAZO_C_GOLPE = pieza("brazo_c_golpe", 16, {
  ".ddd............",
  "ddddccc......4.4",
  "dcccccca44444434",
  ".bbbbbba2222332.",
  ".............2.2",
})
-- Brazo lejano lanzado al frente (golpe), más alto y en sombra. 13x4.
local BRAZO_L_GOLPE = pieza("brazo_l_golpe", 13, {
  ".bbbb.....3.3",
  ".bbbbb3333323",
  ".aaaaa222222.",
  "..........2.2",
})
-- Brazos cayendo en diagonal (final del zarpazo). 11x11.
local BRAZO_C_BAJA = pieza("brazo_c_baja", 11, {
  ".dd........",
  "cddd.......",
  "bccdd......",
  ".bccd......",
  "..bccd.....",
  "...bcca....",
  "....b244...",
  "......244..",
  ".......244.",
  "........343",
  ".........32",
})
local BRAZO_L_BAJA = pieza("brazo_l_baja", 11, {
  ".bb........",
  "abbb.......",
  "aabbb......",
  ".aabb......",
  "..aabb.....",
  "...aaba....",
  "....a233...",
  "......233..",
  ".......233.",
  "........232",
  ".........22",
})

-- Piernas del ciclo de andar. 24x16, origen (8, 23). La cercana (C) es la que arrastra.
local PC = {
  pieza("pc0", 24, {
    "........MLK.............",
    "........MLK.............",
    "........MLK.............",
    "........LLK.............",
    "........LMK.............",
    "........LLK.............",
    "........LMK.............",
    "........LMK.............",
    "........KLK.............",
    "........KLJ.............",
    "........JLK.............",
    "........KQg.............",
    ".........Qg.............",
    ".........Qg.............",
    "........gQFf............",
    "........ggQFf...........",
  }),
  pieza("pc1", 24, {
    "........MLK.............",
    "........MLK.............",
    "........MLK.............",
    "........LLK.............",
    "........LMK.............",
    "........LLK.............",
    ".......LMK..............",
    ".......LMK..............",
    ".......KLK..............",
    ".......KLJ..............",
    ".......JLK..............",
    ".......KQg..............",
    "........Qg..............",
    "........Qg..............",
    ".......gQFf.............",
    ".......ggQFf............",
  }),
  pieza("pc2", 24, {
    "........MLK.............",
    "........MLK.............",
    "........MLK.............",
    ".......LLK..............",
    ".......LMK..............",
    ".......LLK..............",
    ".......LMK..............",
    "......LMK...............",
    "......KLK...............",
    "......KLJ...............",
    ".....JLK................",
    ".....KQg................",
    "......Qg................",
    "......Qg................",
    ".....gQFf...............",
    ".....ggQFf..............",
  }),
  pieza("pc3", 24, {
    "........MLK.............",
    "........MLK.............",
    ".......MLK..............",
    ".......LLK..............",
    ".......LMK..............",
    "......LLK...............",
    "......LMK...............",
    "......LMK...............",
    ".....KLK................",
    ".....KLJ................",
    ".....JLK................",
    "....KQg.................",
    ".....Qg.................",
    ".....Qg.................",
    "....gQFf................",
    "....ggQFf...............",
  }),
  pieza("pc4", 24, {
    "........MLK.............",
    ".......MLK..............",
    ".......MLK..............",
    ".......LLK..............",
    "......LMK...............",
    "......LLK...............",
    ".....LMK................",
    ".....LMK................",
    "....KLK.................",
    "....KLJ.................",
    "...JLK..................",
    "...Qg...................",
    "..gQg...................",
    "...gQF..................",
    "....QFf.................",
    "....gQF.................",
  }),
  pieza("pc5", 24, {
    "........MLK.............",
    "........MLK.............",
    "........MLK.............",
    "........LLK.............",
    "........LMK.............",
    "........LLK.............",
    "........LMK.............",
    ".......KLMK.............",
    ".......KLK..............",
    "......KLJ...............",
    ".....JLK................",
    ".....Qg.................",
    ".....Qg.................",
    ".....Qg.................",
    ".....Fg.................",
    "....fFg.................",
  }),
  pieza("pc6", 24, {
    "........MLK.............",
    "........MLK.............",
    "........MLK.............",
    "........LLK.............",
    ".........LMK............",
    ".........LLK............",
    ".........LMK............",
    "........KLMK............",
    "........KLK.............",
    ".......KLJ..............",
    ".......JLK..............",
    ".......Qg...............",
    "......Qg................",
    "......Qg................",
    ".....FQg................",
    ".....fFg................",
  }),
  pieza("pc7", 24, {
    "........MLK.............",
    "........MLK.............",
    "........MLK.............",
    "........LLK.............",
    ".........LMK............",
    ".........LLK............",
    ".........LMK............",
    ".........LMK............",
    ".........KLK............",
    "........KLJ.............",
    "........JLK.............",
    "........KQg.............",
    ".........Qg.............",
    "........Qg..............",
    "........FQg.............",
    ".......fFfg.............",
  }),
}

local PL = {
  -- 0: despegue (talón arriba, puntera apoyada)
  pieza("pl0", 24, {
    ".........MLLK...........",
    ".........MLLK...........",
    ".........MLLK...........",
    ".........LLLK...........",
    "..........MLLK..........",
    "..........LLLK..........",
    "..........MLLK..........",
    "..........LMLK..........",
    "..........LLK...........",
    "..........MLK...........",
    ".........LLK............",
    ".........LKK............",
    ".........fFf............",
    ".........xfFf...........",
    "..........xfFf..........",
    "...........xxx..........",
  }),
  -- 1: recogida
  pieza("pl1", 24, {
    ".........MLLK...........",
    ".........MLLK...........",
    "..........MLLK..........",
    "..........LLLK..........",
    "...........MLLK.........",
    "...........LLLK.........",
    "............MLLK........",
    "............LLK.........",
    "............MLK.........",
    "...........LLK..........",
    "...........LLK..........",
    "..........LKK...........",
    "..........fFf...........",
    "..........xfFFf.........",
    "............xxx.........",
    "........................",
  }),
  -- 2: paso
  pieza("pl2", 24, {
    ".........MLLK...........",
    "..........MLLK..........",
    "..........LLLK..........",
    "...........MLLK.........",
    "...........LLLK.........",
    "............MLLK........",
    ".............MLLK.......",
    ".............LMLK.......",
    ".............LLK........",
    ".............MLK........",
    ".............LLK........",
    ".............LLK........",
    ".............LKK........",
    ".............fFFFf......",
    ".............xxxxx......",
    "........................",
  }),
  -- 3: alcance (talón por delante, puntera alta)
  pieza("pl3", 24, {
    ".........MLLK...........",
    ".........MLLK...........",
    "..........MLLK..........",
    "...........LLLK.........",
    "...........MLLK.........",
    "............LLLK........",
    "............MLLK........",
    ".............LMLK.......",
    "..............LLK.......",
    "..............MLK.......",
    "...............LLK......",
    "...............LLK......",
    "...............LKK......",
    "................fFFFf...",
    "................xxxx....",
    "........................",
  }),
  -- 4: apoyo del talón
  pieza("pl4", 24, {
    ".........MLLK...........",
    ".........MLLK...........",
    "..........MLLK..........",
    "..........LLLK..........",
    "...........MLLK.........",
    "...........LLLK.........",
    "............MLLK........",
    "............LMLK........",
    ".............LLK........",
    ".............MLK........",
    "..............LLK.......",
    "..............LLK.......",
    "...............LLK......",
    "...............LKK......",
    "...............fFFFf....",
    "...............xxxx.....",
  }),
  -- 5: carga del peso
  pieza("pl5", 24, {
    ".........MLLK...........",
    ".........MLLK...........",
    "..........MLLK..........",
    "...........LLLK.........",
    "...........MLLK.........",
    "............LLLK........",
    "............MLLK........",
    ".............LMLK.......",
    "..............LLK.......",
    "..............MLK.......",
    "..............LLK.......",
    "..............LLK.......",
    "..............LLK.......",
    "..............LKK.......",
    "..............fFFFf.....",
    "..............xxxxx.....",
  }),
  -- 6: vertical
  pieza("pl6", 24, {
    ".........MLLK...........",
    ".........MLLK...........",
    ".........MLLK...........",
    "..........LLLK..........",
    "..........MLLK..........",
    "..........LLLK..........",
    "..........MLLK..........",
    "..........LMLK..........",
    "...........LLK..........",
    "...........MLK..........",
    "...........LLK..........",
    "............LLK.........",
    "............LLK.........",
    "............LKK.........",
    "............fFFFf.......",
    "............xxxxx.......",
  }),
  -- 7: retrasada
  pieza("pl7", 24, {
    ".........MLLK...........",
    ".........MLLK...........",
    ".........MLLK...........",
    ".........LLLK...........",
    "..........MLLK..........",
    "..........LLLK..........",
    "..........MLLK..........",
    "..........LMLK..........",
    "...........LLK..........",
    "...........MLK..........",
    "...........LLK..........",
    "...........LLK..........",
    "...........LLK..........",
    "...........LKK..........",
    "...........fFFFf........",
    "...........xxxxx........",
  }),
}

-- Piernas de la embestida: la pelvis se adelanta 2 px y baja 1; los pies no se mueven de pc5/pl5.
local PC_EMB = pieza("pc_emb", 24, {
  "..........MLK...........",
  "..........MLK...........",
  "..........MLK...........",
  ".........LLK............",
  "........LMK.............",
  "........LLK.............",
  ".......LMK..............",
  ".......LMK..............",
  "......KLK...............",
  ".....KLJ................",
  ".....JLK................",
  ".....Qg.................",
  ".....Qg.................",
  ".....Qg.................",
  ".....Fg.................",
  "....fFg.................",
})
local PL_EMB = pieza("pl_emb", 24, {
  "...........MLLK.........",
  "...........MLLK.........",
  "............MLLK........",
  "............LLLK........",
  ".............MLLK.......",
  "..............LLLK......",
  "..............MLLK......",
  "...............LMLK.....",
  "...............LLK......",
  "...............MLK......",
  "..............LLK.......",
  "..............LLK.......",
  "..............LLK.......",
  "..............LKK.......",
  "..............fFFFf.....",
  "..............xxxxx.....",
})

---------------------------------------------------------------- piezas de la muerte
-- Cabeza echada atrás por el disparo (cara hacia arriba). 6x5.
local CABEZA_ATRAS = pieza("cabeza_atras", 6, {
  ".334..",
  "k3eo3X",
  "ji233B",
  "iih222",
  ".hhh1.",
})
-- Torso vencido hacia atrás (cae de espaldas). 13x12. Origen base (11, 13).
local TORSO_ATRAS = pieza("torso_atras", 13, {
  "..cddc2......",
  "cddddcc2.....",
  "bcdddccb.....",
  ".bcddccbb....",
  ".acc3Rccb....",
  "..acRrccb....",
  "...accbcb....",
  "...abccbcb...",
  "....abcbcb...",
  "....abbcbba..",
  ".....aLbaKa..",
  "......MLaLK..",
})
-- Brazos que quedan atrás por la inercia, hacia arriba y al frente. 11x7.
local BRAZO_C_VUELO = pieza("brazo_c_vuelo", 11, {
  "........43.",
  ".......4432",
  ".....4422..",
  "...dc422...",
  ".dddcb.....",
  "dcccb......",
  ".bbb.......",
})
local BRAZO_L_VUELO = pieza("brazo_l_vuelo", 11, {
  "........33.",
  ".......3322",
  ".....3322..",
  "...bb322...",
  ".bbbba.....",
  "bbbaa......",
  ".aaa.......",
})
-- Piernas que se doblan al caer. 24x14, origen (8, 25).
local PC_DOBLA = pieza("pc_dobla", 24, {
  "..........MLK...........",
  "...........MLK..........",
  "...........LLK..........",
  "............MLK.........",
  ".............MLK........",
  ".............LMK........",
  ".............LMK........",
  "............KLK.........",
  "...........JLK..........",
  "...........Qg...........",
  "..........Qg............",
  "..........Qg............",
  ".........gQFf...........",
  ".........ggQFf..........",
})
local PL_DOBLA = pieza("pl_dobla", 24, {
  "...........MLLK.........",
  "............MLLK........",
  ".............MLLK.......",
  "..............LLLK......",
  "..............MLLK......",
  "...............MLLK.....",
  "...............LMLK.....",
  "...............LLK......",
  "..............MLK.......",
  "..............LLK.......",
  ".............LLK........",
  ".............LKK........",
  "............fFFFf.......",
  "............xxxxx.......",
})

-- Caída a 60 grados (fotograma 3 de morir): piezas sueltas.
-- Torso en diagonal con la pelvis. 14x13. Origen (8, 22).
local TORSO_CAE = pieza("torso_cae", 14, {
  ".cdd..........",
  "cdddcc........",
  "ccddddcc......",
  "bccdddSBc.....",
  "abcccdBSccc...",
  ".abccc3RcccL..",
  "..abbccRrcbLM.",
  "...aabcccbbLLM",
  ".....aabbbaKLL",
  ".......aaaJKKL",
  ".........aJJKK",
  "...........JJJ",
  "..............",
})
-- Piernas de la caída: muslo casi horizontal, espinilla al suelo. 16x11. Origen (19, 28).
local PC_CAE = pieza("pc_cae", 16, {
  "......MMM.......",
  "..MMMMLLLK......",
  "MMLLLLLLLK......",
  "LLLKKKKLLK......",
  "KKK....LLK......",
  ".......JLK......",
  ".......Qg.......",
  "........Qg......",
  "........Qg......",
  ".......gQFf.....",
  ".......ggQFf....",
})
local PL_CAE = pieza("pl_cae", 16, {
  ".......MMMM.....",
  "...MMMMLLLLK....",
  "MMMLLLLLLLLK....",
  "LLLLKKKKLLLK....",
  ".........LLK....",
  ".........LLK....",
  ".........LLK....",
  "..........LLK...",
  "..........LKK...",
  "..........fFFFf.",
  "..........xxxxx.",
})

-- Cuerpo tendido boca arriba, cabeza a la izquierda. Cabeza, torso y pelvis: 24x9. Origen (2, 30).
local CUERPO_T = pieza("cuerpo_t", 24, {
  "........................",
  "...34....bcccccbbb......",
  ".k334sX2cdddccccbbbLMML.",
  ".jieo3B2dSBddccbcbbMLLL.",
  ".ii23322cSSdccbccbaLLLK.",
  ".hiih221ccccc3RcbbaLLKK.",
  "..hhhh..bbbbbrbbaaaKKKJ.",
  ".........aaaaaaaaa.JJJ..",
  "........................",
})
-- Brazo cercano caído junto al costado. 14x4. Origen (10, 35).
local BRAZO_T = pieza("brazo_t", 14, {
  ".ddc..........",
  ".dcccb........",
  "..bbccb44.....",
  "......aa22443.",
})
-- Brazo lejano abierto hacia el fondo. 11x5. Origen (2, 27).
local BRAZO_T_L = pieza("brazo_t_l", 11, {
  ".33........",
  ".4443......",
  "...224cd...",
  ".....2bcdd.",
  "........bc.",
})
-- Piernas tendidas; la lejana algo abierta. 16x10. Origen (22, 28).
local PIERNAS_T = pieza("piernas_t", 16, {
  "............fFx.",
  "............fFx.",
  ".....lmmmll.ffx.",
  "..lmmllllllnffx.",
  "..llllnnllnn....",
  "..nnnnnnn....43.",
  "..MMLLLMML...43.",
  "..LLLLLLLLK4342.",
  "..KKLKKKKKJ3232.",
  "..JJJJJJJJ.2.22.",
})
-- Charco de sangre bajo la cabeza y los hombros. 16x5. Origen (0, 35).
local CHARCO = pieza("charco", 16, {
  "..SSS...........",
  ".SBBBSS.........",
  "SBBXBBBSSSS.....",
  "SSBBBBBBBBBSS...",
  "..SSSBBBSSSS....",
})
-- Salpicadura del disparo.
local SALPICA = pieza("salpica", 4, {
  "X..B",
  ".XB.",
  "..XB",
})

-- Mapa del cuerpo tendido: añade la pierna lejana y el zapato.
local MT = {}
for k, v in pairs(MA) do MT[k] = v end
MT.m = VQL; MT.l = VQ[2]; MT.n = VQ[1]
MT.F = CU[4]; MT.f = CU[3]; MT.x = CU[1]

-- Copia una imagen inclinándola: cada columna sube k px por cada px de distancia a x0 (rebote).
local function inclinar(src, x0, k)
  local dst = L.imagen(src.width, src.height)
  for y = 0, src.height - 1 do for x = 0, src.width - 1 do
    local c = src:getPixel(x, y)
    if L.alfa(c) > 0 then
      local d = math.floor(math.abs(x - x0) * k + 0.5)
      L.px(dst, x, y - d, c)
    end
  end end
  return dst
end

local function poner(img, filas, x, y, mapa) L.pintar(img, filas, x, y, mapa) end

---------------------------------------------------------------- andar
-- t = desplazamiento del torso, c = de la cabeza, b = del brazo extendido (con retardo),
-- p = posición del péndulo del brazo que cuelga.
local PASO = {
  { tx = 0, ty = 0,  cx = 0, cy = 0,  bx = 0, by = 0,  p = 3 },
  { tx = 0, ty = -1, cx = 0, cy = 0,  bx = 0, by = 0,  p = 2 },
  { tx = 0, ty = -1, cx = 0, cy = -1, bx = 0, by = -1, p = 2 },
  { tx = 1, ty = 0,  cx = 0, cy = -1, bx = 0, by = -1, p = 1 },
  { tx = 1, ty = 1,  cx = 1, cy = 0,  bx = 1, by = 0,  p = 1 },
  { tx = 1, ty = 1,  cx = 1, cy = 1,  bx = 1, by = 1,  p = 2 },
  { tx = 0, ty = 0,  cx = 1, cy = 1,  bx = 1, by = 1,  p = 3 },
  { tx = 0, ty = 0,  cx = 0, cy = 0,  bx = 0, by = 0,  p = 3 },
}

local function andarA(i)
  return function(img)
    local t = PASO[i]
    poner(img, BRAZO_L, 25 + t.bx, 14 + t.by, MA)
    poner(img, PL[i], 8, 23, ML)
    poner(img, PC[i], 8, 23, MC)
    poner(img, TORSO, 14 + t.tx, 11 + t.ty, MA)
    poner(img, CABEZA, 24 + t.cx, 7 + t.cy, MA)
    poner(img, BRAZO_C[t.p], 21 + t.tx, 12 + t.ty, MA)
    contorno(img, 38)
  end
end

---------------------------------------------------------------- atacar
local ATAQUE = {
  -- 1: toma impulso: se yergue, cabeza atrás, manos en garra recogidas
  function(img)
    poner(img, BRAZO_L_GARRA, 21, 11, MA)
    poner(img, PL[6], 8, 23, ML)
    poner(img, PC[6], 8, 23, MC)
    poner(img, TORSO_RECTO, 14, 10, MA)
    poner(img, CABEZA, 19, 5, MA)
    poner(img, BRAZO_C_GARRA, 17, 11, MA)
    contorno(img, 38)
  end,
  -- 2: golpe: embestida con los dos brazos al frente
  function(img)
    poner(img, BRAZO_L_GOLPE, 27, 13, MA)
    poner(img, PL_EMB, 8, 23, ML)
    poner(img, PC_EMB, 8, 23, MC)
    poner(img, TORSO, 16, 12, MA)
    poner(img, CABEZA_AB, 27, 8, MA)
    poner(img, BRAZO_C_GOLPE, 23, 14, MA)
    contorno(img, 38)
  end,
  -- 3: sigue el movimiento: torso vencido, brazos cayendo
  function(img)
    poner(img, BRAZO_L_BAJA, 28, 15, MA)
    poner(img, PL_EMB, 8, 23, ML)
    poner(img, PC_EMB, 8, 23, MC)
    poner(img, TORSO_BAJO, 16, 15, MA)
    poner(img, CABEZA_AB, 29, 11, MA)
    poner(img, BRAZO_C_BAJA, 25, 15, MA)
    contorno(img, 38)
  end,
  -- 4: se recupera
  function(img)
    poner(img, BRAZO_L, 26, 16, MA)
    poner(img, PL[6], 8, 23, ML)
    poner(img, PC[6], 8, 23, MC)
    poner(img, TORSO, 15, 12, MA)
    poner(img, CABEZA, 26, 9, MA)
    poner(img, BRAZO_C[3], 22, 13, MA)
    contorno(img, 38)
  end,
}

---------------------------------------------------------------- morir
local function tendido(img, charco)
  if charco then poner(img, CHARCO, 0, 35, MT) end
  poner(img, BRAZO_T_L, 2, 27, MT)
  poner(img, PIERNAS_T, 22, 28, MT)
  poner(img, CUERPO_T, 2, 30, MT)
  poner(img, BRAZO_T, 10, 35, MT)
end

local MUERTE = {
  -- 1: impacto: la cabeza salta atrás, el torso se yergue
  function(img)
    poner(img, SALPICA, 10, 3, MA)
    poner(img, BRAZO_L, 21, 13, MA)
    poner(img, PL[8], 8, 23, ML)
    poner(img, PC[1], 8, 23, MC)
    poner(img, TORSO_RECTO, 13, 10, MA)
    poner(img, CABEZA_ATRAS, 14, 6, MA)
    poner(img, BRAZO_C_BAJA, 18, 11, MA)
    contorno(img, 38)
  end,
  -- 2: se vence de espaldas, se le doblan las rodillas
  function(img)
    poner(img, BRAZO_L_VUELO, 17, 9, MA)
    poner(img, PL_DOBLA, 8, 25, ML)
    poner(img, PC_DOBLA, 8, 25, MC)
    poner(img, TORSO_ATRAS, 11, 13, MA)
    poner(img, CABEZA_ATRAS, 6, 10, MA)
    poner(img, BRAZO_C_VUELO, 13, 8, MA)
    contorno(img, 38)
  end,
  -- 3: cae a plomo
  function(img)
    poner(img, BRAZO_L_VUELO, 13, 16, MA)
    poner(img, PL_CAE, 21, 27, ML)
    poner(img, PC_CAE, 19, 28, MC)
    poner(img, TORSO_CAE, 8, 22, MA)
    poner(img, CABEZA_ATRAS, 2, 19, MA)
    poner(img, BRAZO_C_VUELO, 9, 16, MA)
    contorno(img, 38)
  end,
  -- 4: golpea el suelo: piernas y cabeza rebotan
  function(img)
    local t = L.imagen(40, 40)
    tendido(t, false)
    L.pegar(img, inclinar(t, 16, 0.14), 0, 0)
    contorno(img, 39)
  end,
  -- 5: queda tendido
  function(img)
    tendido(img, false)
    contorno(img, 39)
  end,
  -- 6: charco de sangre
  function(img)
    tendido(img, false)
    contorno(img, 39)
    local c = L.imagen(40, 40)
    poner(c, CHARCO, 0, 35, MT)
    L.pegar(c, img, 0, 0)
    L.pegar(img, c, 0, 0)
  end,
}

---------------------------------------------------------------- 8 direcciones
-- Vistas nuevas de la misma persona: s (de frente), se (3/4 de frente), ne (3/4 de espaldas), n (de espaldas).
-- La vista e (perfil 3/4) son los fotogramas de arriba. La luz sigue arriba a la izquierda en todas.
-- Recordatorio: la derecha del zombi lleva el pie descalzo y el vaquero roto; su izquierda, el zapato.


-- Pega una pieza inclinándola: la fila de arriba se desplaza k px a la derecha y la de abajo nada
-- (el torso se vence hacia donde camina).
local function ponerInc(img, filas, x, y, mapa, k)
  local t = L.imagen(#filas[1], #filas)
  L.pintar(t, filas, 0, 0, mapa)
  local h = #filas
  for j = 0, h - 1 do
    local d = math.floor(k * (h - 1 - j) / math.max(1, h - 1) + 0.5)
    for i = 0, t.width - 1 do
      local c = t:getPixel(i, j)
      if L.alfa(c) > 0 then L.px(img, x + i + d, y + j, c) end
    end
  end
end

-- Tubo sombreado (manga o antebrazo): luz donde no hay nada arriba o a la izquierda, sombra abajo y a la derecha.
local function tubo(img, x0, y0, x1, y1, grosor, luz, base, sombra)
  local m = L.imagen(40, 40)
  local M = L.hex("ffffff")
  L.grueso(m, x0, y0, x1, y1, grosor, M)
  for y = 0, 39 do for x = 0, 39 do
    if L.opaco(m, x, y) then
      local c = base
      if not L.opaco(m, x, y + 1) or not L.opaco(m, x + 1, y) then c = sombra end
      if not L.opaco(m, x, y - 1) or not L.opaco(m, x - 1, y) then c = luz end
      L.px(img, x, y, c)
    end
  end end
end

-- Brazo por código: h = hombro, c = codo, m = muñeca. La manga llega al codo; el antebrazo va al aire.
-- La mano es una garra de 2x2 con tres dedos que siguen la dirección del antebrazo.
local function brazo(img, h, c, m, sombra)
  local s = sombra and 1 or 0
  tubo(img, c[1], c[2], m[1], m[2], 2, Z[4 - s], Z[3 - s], Z[2 - s])
  tubo(img, h[1], h[2], c[1], c[2], 3, RA[4 - s], RA[3 - s], RA[2 - s])
  local dx, dy = m[1] - c[1], m[2] - c[2]
  local l = math.sqrt(dx * dx + dy * dy)
  if l < 0.01 then dx, dy, l = 0, 1, 1 end
  dx, dy = dx / l, dy / l
  local px, py = -dy, dx
  L.px(img, m[1], m[2], Z[4 - s]); L.px(img, m[1] + dx, m[2] + dy, Z[3 - s])
  for k = -1, 1 do
    local fx, fy = m[1] + dx * 1.6 + px * k * 1.1, m[2] + dy * 1.6 + py * k * 1.1
    L.px(img, fx, fy, k == -1 and Z[4 - s] or Z[3 - s])
    if k ~= 0 then L.px(img, fx + dx, fy + dy, Z[2 - s]) end
  end
end

-- Formas de pie: a = luz, b = medio, c = sombra, d = suela o lo más oscuro.
local PIES = {
  s      = { "aabc", "bbcd" }, s_n = { ".abc", ".bcd" },
  se     = { "aabc.", ".bbcd" }, se_n = { "abc.", ".bcd" },
  n      = { "aabc", "bccd" }, n_n = { ".abc", ".ccd" },
  ne     = { ".aabc", "bbcd." }, ne_n = { ".abc", "bcd." },
  punta  = { "bcd" },
}

-- Pierna vista de frente, de espaldas o en 3/4, dibujada por código.
-- o.x, o.y0 = esquina de la cadera (x izquierda, fila de arriba); o.fx, o.yf = x izquierda del pie y fila de la suela;
-- o.sombra = pierna lejana o en sombra; o.desc = descalza con el vaquero roto;
-- o.vista = "s", "se", "n" o "ne"; o.pie = "grande", "normal" o "punta"; o.dentro = la espinilla se recoge
-- hacia la derecha (+1) o no (rodillas hacia dentro); o.dobla = rodilla doblada.
local function pierna(img, o)
  local c = o.sombra and { VQ[3], VQ[2], VQL, VQ[1] } or { VQ[4], VQ[3], VQ[2], VQ[1] }
  local pc = o.sombra and { Z[3], Z[2], Z[1] } or { Z[4], Z[3], Z[2] }
  local punta = o.pie == "punta"
  local yLeg = punta and (o.yf - 1) or (o.yf - 2)
  local largo = math.max(1, yLeg - o.y0)
  local yk = o.y0 + math.floor(largo * 0.5 + 0.5)
  for y = o.y0, yLeg do
    local t = (y - o.y0) / largo
    local x = math.floor(o.x + (o.fx - o.x) * t + 0.5)
    if y <= yk then
      local cols = { c[1], c[2], c[2], c[3] }
      if y == o.y0 + 3 then cols[3] = c[3] end              -- pliegue
      if o.dobla and y == yk then cols = { c[2], c[1], c[1], c[3] } end
      for i = 1, 4 do L.px(img, x + i - 1, y, cols[i]) end
    else
      local xs = x + ((o.dentro or 0) > 0 and 1 or 0)
      local cols = { c[1], c[2], c[4] }
      if o.dobla and y == yk + 1 then cols = { c[3], c[3], c[4] } end
      if o.desc and y >= yk + 3 then
        cols = { pc[1], pc[2], pc[3] }
        if y == yk + 4 then cols[2] = SA[2] end             -- herida en la espinilla
      elseif o.desc and y == yk + 2 then
        cols = { c[2], pc[1], c[4] }                         -- borde roto del vaquero
      elseif not o.desc and y == yLeg then
        cols = { c[3], c[3], c[4] }                          -- bajo del pantalón
      end
      for i = 1, 3 do L.px(img, xs + i - 1, y, cols[i]) end
    end
  end
  -- pie
  local forma
  if punta then forma = PIES.punta
  else forma = PIES[o.vista .. (o.pie == "grande" and "" or "_n")] end
  local R = o.desc and { Z[4], Z[3], Z[2], Z[1] } or { CU[4], CU[3], CU[2], CU[1] }
  if o.sombra then R = o.desc and { Z[3], Z[2], Z[2], Z[1] } or { CU[3], CU[3], CU[2], CU[1] } end
  local m = { a = R[1], b = R[2], c = R[3], d = R[4] }
  local px0 = o.fx + (punta and 1 or 0)
  for j, fila in ipairs(forma) do
    local y = o.yf - #forma + j
    for k = 1, #fila do
      local ch = fila:sub(k, k)
      if ch ~= "." then L.px(img, px0 + k - 1, y, m[ch]) end
    end
  end
end

-- Dos piernas. p: fotograma del paso con d = descalza { x, y, pie } y z = zapato { x, y, pie, dobla }.
-- cfg: caderas y qué pierna va en sombra.
local function piernas(img, cfg, p, tx, ty)
  local orden = cfg.primero == "z" and { "z", "d" } or { "d", "z" }
  for _, k in ipairs(orden) do
    local h, f = cfg[k], p[k]
    pierna(img, { x = h[1] + tx, y0 = h[2] + ty, fx = h[1] + f[1], yf = f[2], pie = f[3],
      dobla = f[4], desc = k == "d", sombra = h[3], dentro = h[4], vista = cfg.vista })
  end
  if cfg.ingle then
    local g = cfg.ingle
    L.px(img, g[1] + tx, g[2] + ty, VQ[1]); L.px(img, g[1] + tx, g[2] + 1 + ty, TI[2])
  end
end

-- Pasos de la cojera, compartidos por las cuatro vistas nuevas. El zapato da el paso; la descalza se arrastra.
-- avance: cuánto se ha movido cada pie en el suelo (-1 atrás .. 2 delante); la vista lo convierte en x e y.
local PASO8 = {
  { tx = 0,  ty = 0,  d = { -1, "punta" }, z = { 2, "grande" } },
  { tx = 1,  ty = -1, d = { -1, "punta" }, z = { 2, "grande" } },
  { tx = 1,  ty = 0,  d = { 0, "punta" },  z = { 1, "normal" } },
  { tx = 0,  ty = 1,  d = { 1, "grande" }, z = { 0, "normal" } },
  { tx = -1, ty = 1,  d = { 1, "grande" }, z = { -1, "punta" } },
  { tx = -1, ty = 1,  d = { 0, "normal" }, z = { 0, "punta", true, alza = 2 } },
  { tx = 0,  ty = 0,  d = { 0, "normal" }, z = { 1, "normal" } },
  { tx = 0,  ty = 0,  d = { -1, "punta" }, z = { 2, "grande" } },
}
-- Convierte el avance de cada pie en coordenadas de la vista: ax, ay = desplazamiento por paso de avance.
local function pasoVista(i, ax, ay, base)
  local p = PASO8[i]
  local r = { tx = p.tx, ty = p.ty }
  for _, k in ipairs({ "d", "z" }) do
    local f = p[k]
    local av = f[1]
    local y = base + math.floor(av * ay + 0.5) - (f.alza or 0)
    local pie = f[2]
    r[k] = { math.floor(av * ax + 0.5), math.min(38, y), pie, f[3] }
  end
  return r
end

---------------------------------------------------------------- vista s (de frente)
-- Cabeza de frente, vencida. 6x7. Origen base (18, 9).
local CABEZA_S = pieza("cabeza_s", 6, {
  ".kjji.",
  "kjjiih",
  "jie4eh",
  "4o32o2",
  "433221",
  "3sXXs1",
  ".2BS1.",
})
local CABEZA_S_AB = pieza("cabeza_s_ab", 6, {
  ".kjji.",
  "kjjiih",
  "jie4eh",
  "4o32o2",
  "433221",
  "3sXXs1",
  ".sBSs.",
  "..BS..",
})
-- Torso de frente: camisa por fuera, rota, y la cintura del vaquero. 9x13. Origen base (16, 12).
local TORSO_S = pieza("torso_s", 9, {
  "..dccbbba",
  "cdddcccba",
  "cddddcbba",
  "cdddccbba",
  "cddcbcbba",
  "cdccbccba",
  "ccccbcbba",
  "c3Rcbcbaa",
  "cRrcbbbaa",
  "bcccbcbaa",
  "bbccbbbaa",
  "aabbaabaa",
  "LaMLbKaKJ",
})
-- Brazo derecho del zombi (izquierda de la pantalla): estirado hacia la cámara, así que el brazo
-- casi no se ve y la mano en garra queda delante del pecho, con sombra debajo. 5x8. Origen (15, 13).
local BRAZO_S_I = pieza("brazo_s_i", 5, {
  ".dd..",
  "dddc.",
  "dccb.",
  "acbb.",
  ".a32.",
  ".432a",
  ".4442",
  ".343a",
  ".3.2.",
})
-- Brazo izquierdo (derecha de la pantalla), más alto y en sombra. 5x7. Origen (21, 12).
local BRAZO_S_D = pieza("brazo_s_d", 5, {
  "..bb.",
  ".cbbb",
  ".3443",
  ".3432",
  ".3322",
  ".2.2.",
  "..aa.",
})
local PIERNAS_S = { vista = "s", d = { 16, 25, false, 1 }, z = { 21, 25, true, -1 }, ingle = { 20, 25 } }

local function andarS(i)
  return function(img)
    local p, q = PASO8[i], PASO8[(i + 6) % 8 + 1]   -- q: fotograma anterior (retardo)
    piernas(img, PIERNAS_S, pasoVista(i, 0, 1, 37), p.tx, p.ty)
    poner(img, TORSO_S, 16 + p.tx, 12 + p.ty, MA)
    ponerInc(img, CABEZA_S, 18 + q.tx, 9 + q.ty, MA, 1)
    poner(img, BRAZO_S_D, 22 + q.tx, 12 + q.ty, MA)
    poner(img, BRAZO_S_I, 15 + p.tx, 13 + p.ty, MA)
    contorno(img, 38)
  end
end

---------------------------------------------------------------- vista se (3/4 de frente)
-- Cabeza girada a la derecha: nuca y oreja a la izquierda, cara a la derecha. 6x7. Origen (20, 9).
local CABEZA_SE = pieza("cabeza_se", 6, {
  ".kjji.",
  "kjiih3",
  "jhe4e3",
  "h3o3o4",
  "h23324",
  ".23sX1",
  "..2BB.",
})
local CABEZA_SE_AB = pieza("cabeza_se_ab", 6, {
  ".kjji.",
  "kjiih3",
  "jhe4e3",
  "h3o3o4",
  "h23324",
  ".23sX1",
  "..2sS.",
  "...BB.",
})
-- Torso 3/4: pecho hacia la derecha, costado derecho (con la herida) a la izquierda. 9x13. Origen (16, 12).
local TORSO_SE = pieza("torso_se", 9, {
  ".cddcbb..",
  "cdddccbb.",
  "cddccbbba",
  "cdcccbbba",
  "c3Rccbbba",
  "cRrccbbba",
  "ccccbcbba",
  "cccccbbaa",
  "bccccbbaa",
  "bcccbbbaa",
  "bbccbbba.",
  "aabbaaba.",
  "LaMLbKaK.",
})
-- Brazo lejano (izquierdo) estirado al frente, como en el perfil pero más corto. 9x5. Origen (22, 13).
local BRAZO_SE_L = pieza("brazo_se_l", 9, {
  ".bbb.....",
  ".bbbb33..",
  ".aaa2233.",
  "......232",
  ".......2.",
})
-- Brazo cercano (derecho) hacia delante y abajo, mano delante del vientre. 9x9. Origen (15, 12).
local BRAZO_SE_C = pieza("brazo_se_c", 9, {
  ".dd......",
  "dddc.....",
  "dccb.....",
  ".dccb....",
  "..acb4...",
  "...a443..",
  ".....4432",
  ".....3443",
  "......3.3",
})
local PIERNAS_SE = { vista = "se", d = { 16, 25, false, 1 }, z = { 20, 24, true, 0 }, primero = "z" }

local function andarSE(i)
  return function(img)
    local p, q = PASO8[i], PASO8[(i + 6) % 8 + 1]
    poner(img, BRAZO_SE_L, 24 + q.tx, 13 + q.ty, MA)
    piernas(img, PIERNAS_SE, pasoVista(i, 1, 1, 37), p.tx, p.ty)
    ponerInc(img, TORSO_SE, 16 + p.tx, 12 + p.ty, MA, 2)
    poner(img, CABEZA_SE, 22 + q.tx, 9 + q.ty, MA)
    poner(img, BRAZO_SE_C, 17 + p.tx, 12 + p.ty, MA)
    contorno(img, 38)
  end
end

---------------------------------------------------------------- vista ne (3/4 de espaldas)
-- Cabeza de espaldas girada: pelo, oreja y un poco de mejilla a la derecha; abajo, el cuello de la camisa. 6x7. Origen (20, 9).
local CABEZA_NE = pieza("cabeza_ne", 6, {
  ".kkji.",
  "kkjjii",
  "kjjii3",
  "jjih32",
  "jiih21",
  ".h221.",
  ".baab.",
})
-- Espalda 3/4: espalda a la izquierda, costado derecho (herida) a la derecha. 9x13. Origen (16, 12).
local TORSO_NE = pieza("torso_ne", 9, {
  "cddddcbb.",
  "cddddcdba",
  "cddddcbba",
  "cdddcbbba",
  "cdddcb3Ra",
  "cddccbRra",
  "cdcccbbaa",
  "ccccbbbaa",
  "cccbbbbaa",
  "bccbbbbaa",
  "bbccbbbaa",
  "aabbaabaa",
  "LaMLbKaKJ",
})
-- Brazo cercano (derecho) estirado hacia delante: sube hacia arriba a la derecha. 8x8. Origen (23, 7).
local BRAZO_NE_C = pieza("brazo_ne_c", 8, {
  "......3.",
  ".....343",
  "....3432",
  "...2332.",
  "..bba2..",
  ".cbbba..",
  "cbbba...",
  "bba.....",
})
local PIERNAS_NE = { vista = "ne", z = { 15, 24, false, 1 }, d = { 21, 25, true, 0 }, primero = "z", ingle = { 19, 25 } }

local function andarNE(i)
  return function(img)
    local p, q = PASO8[i], PASO8[(i + 6) % 8 + 1]
    piernas(img, PIERNAS_NE, pasoVista(i, 0.5, -1, 37), p.tx, p.ty)
    ponerInc(img, TORSO_NE, 16 + p.tx, 12 + p.ty, MA, 2)
    poner(img, CABEZA_NE, 22 + q.tx, 8 + q.ty, MA)
    local bx, by = q.tx, q.ty
    brazo(img, { 26 + bx, 14 + by }, { 28 + bx, 14 + by }, { 31 + bx, 12 + by }, true)
    contorno(img, 38)
  end
end

---------------------------------------------------------------- vista n (de espaldas)
-- Cabeza de espaldas, vencida y ladeada: pelo, orejas, nuca y el cuello de la camisa. 6x7. Origen (17, 9).
local CABEZA_N = pieza("cabeza_n", 6, {
  ".kkji.",
  "kkjjih",
  "kjjiih",
  "jjiihh",
  "2iihh1",
  ".h221.",
  ".baab.",
})
-- Espalda encorvada: lo alto de la espalda recibe la luz; omóplatos, pliegue de la columna
-- y la camisa rota con la herida en su costado derecho. 9x13. Origen (16, 12).
local TORSO_N = pieza("torso_n", 9, {
  "cdddddcbb",
  "cddddddcb",
  "cdddcddca",
  "cddcbdcba",
  "cdccbccba",
  "ccccbccba",
  "cccbbcbba",
  "cccbbc3Ra",
  "bcccbbRra",
  "bccbbbbaa",
  "bbccbbbaa",
  "aabbaabaa",
  "LaMLbKaKJ",
})
-- Hombros y codos que asoman a los lados (los brazos van por delante del cuerpo).
local BRAZO_N_I = pieza("brazo_n_i", 3, {
  ".d.",
  "dd.",
  "dc.",
  "cb.",
  "ab.",
})
local BRAZO_N_D = pieza("brazo_n_d", 3, {
  ".b.",
  ".bb",
  ".bb",
  ".ba",
  ".ba",
  "..2",
})
local PIERNAS_N = { vista = "n", z = { 16, 25, false, 1 }, d = { 21, 25, true, -1 }, ingle = { 20, 25 } }

local function andarN(i)
  return function(img)
    local p, q = PASO8[i], PASO8[(i + 6) % 8 + 1]
    piernas(img, PIERNAS_N, pasoVista(i, 0, -1, 37), p.tx, p.ty)
    poner(img, TORSO_N, 16 + p.tx, 12 + p.ty, MA)
    ponerInc(img, CABEZA_N, 18 + q.tx, 9 + q.ty, MA, -1)
    poner(img, BRAZO_N_I, 14 + q.tx, 12 + q.ty, MA)
    poner(img, BRAZO_N_D, 24 + p.tx, 13 + p.ty, MA)
    contorno(img, 38)
  end
end

---------------------------------------------------------------- ataques en las vistas nuevas
-- Cada ataque: 1 toma impulso (se yergue, garras arriba), 2 zarpazo (embiste con los dos brazos;
-- es el golpe), 3 sigue el movimiento (brazos cayendo), 4 se recupera.
-- Las piernas usan posturas del paso: los pies no se mueven del sitio.
-- a = { tx, ty } del torso; c = { x, y } de la cabeza; ab = boca abierta; k = inclinación;
-- bi / bd = brazos { hombro, codo, muñeca } (izquierda / derecha de la pantalla); paso = postura de piernas.

-- Garras grandes que se lanzan hacia la cámara (golpe de frente). 5x4.
local GARRA_S_I = pieza("garra_s_i", 5, {
  ".443.",
  "44443",
  "34432",
  "3.3.2",
})
local GARRA_S_D = pieza("garra_s_d", 5, {
  ".332.",
  "33432",
  "23321",
  "2.2.1",
})

local ATQ_S = {
  { t = { 0, -1 }, c = { 18, 7 }, paso = 7,
    bi = { { 16, 13 }, { 14, 14 }, { 14, 10 } }, bd = { { 24, 13 }, { 26, 14 }, { 26, 10 } } },
  { t = { 0, 1 }, c = { 18, 11 }, ab = true, paso = 1, garras = { { 13, 15 }, { 23, 14 } },
    bi = { { 16, 14 }, { 15, 15 }, { 15, 16 } }, bd = { { 24, 14 }, { 25, 15 }, { 25, 15 } } },
  { t = { 0, 2 }, c = { 18, 12 }, ab = true, paso = 1,
    bi = { { 16, 15 }, { 16, 19 }, { 18, 23 } }, bd = { { 24, 15 }, { 24, 19 }, { 22, 22 } } },
  { t = { 0, 1 }, c = { 18, 10 }, paso = 8 },
}
local function atacarS(i)
  return function(img)
    local a = ATQ_S[i]
    piernas(img, PIERNAS_S, pasoVista(a.paso, 0, 1, 37), a.t[1], a.t[2])
    poner(img, TORSO_S, 16 + a.t[1], 12 + a.t[2], MA)
    ponerInc(img, a.ab and CABEZA_S_AB or CABEZA_S, a.c[1], a.c[2], MA, 1)
    if a.bi then
      brazo(img, a.bd[1], a.bd[2], a.bd[3], true)
      brazo(img, a.bi[1], a.bi[2], a.bi[3], false)
      if a.garras then
        poner(img, GARRA_S_D, a.garras[2][1], a.garras[2][2], MA)
        poner(img, GARRA_S_I, a.garras[1][1], a.garras[1][2], MA)
      end
    else
      poner(img, BRAZO_S_D, 22 + a.t[1], 12 + a.t[2], MA)
      poner(img, BRAZO_S_I, 15 + a.t[1], 13 + a.t[2], MA)
    end
    contorno(img, 38)
  end
end

local ATQ_SE = {
  { t = { 0, -1 }, k = 0, c = { 19, 7 }, paso = 7,
    bl = { { 23, 12 }, { 25, 15 }, { 26, 12 } }, bc = { { 17, 13 }, { 16, 16 }, { 19, 13 } } },
  { t = { 2, 1 }, k = 4, c = { 26, 10 }, ab = true, paso = 1,
    bl = { { 26, 13 }, { 30, 14 }, { 34, 15 } }, bc = { { 20, 14 }, { 25, 17 }, { 30, 18 } } },
  { t = { 2, 2 }, k = 4, c = { 26, 12 }, ab = true, paso = 1,
    bl = { { 26, 14 }, { 29, 18 }, { 30, 22 } }, bc = { { 20, 15 }, { 23, 19 }, { 26, 23 } } },
  { t = { 1, 1 }, k = 3, c = { 23, 10 }, paso = 8 },
}
local function atacarSE(i)
  return function(img)
    local a = ATQ_SE[i]
    if a.bl then brazo(img, a.bl[1], a.bl[2], a.bl[3], true)
    else poner(img, BRAZO_SE_L, 24 + a.t[1], 13 + a.t[2], MA) end
    piernas(img, PIERNAS_SE, pasoVista(a.paso, 1, 1, 37), a.t[1], a.t[2])
    ponerInc(img, TORSO_SE, 16 + a.t[1], 12 + a.t[2], MA, a.k)
    poner(img, a.ab and CABEZA_SE_AB or CABEZA_SE, a.c[1], a.c[2], MA)
    if a.bc then brazo(img, a.bc[1], a.bc[2], a.bc[3], false)
    else poner(img, BRAZO_SE_C, 17 + a.t[1], 12 + a.t[2], MA) end
    contorno(img, 38)
  end
end

local ATQ_NE = {
  { t = { 0, -1 }, k = 0, c = { 19, 7 }, paso = 7,
    bc = { { 24, 12 }, { 26, 15 }, { 27, 12 } } },
  { t = { 2, 0 }, k = 4, c = { 24, 7 }, paso = 1,
    bl = { { 22, 12 }, { 27, 9 }, { 31, 7 } }, bc = { { 28, 13 }, { 31, 11 }, { 35, 9 } } },
  { t = { 2, 1 }, k = 4, c = { 24, 9 }, paso = 1,
    bl = { { 22, 13 }, { 26, 13 }, { 29, 16 } }, bc = { { 28, 14 }, { 31, 16 }, { 32, 20 } } },
  { t = { 1, 1 }, k = 3, c = { 23, 10 }, paso = 8,
    bc = { { 27, 14 }, { 29, 14 }, { 32, 12 } } },
}
local function atacarNE(i)
  return function(img)
    local a = ATQ_NE[i]
    if a.bl then brazo(img, a.bl[1], a.bl[2], a.bl[3], true) end
    piernas(img, PIERNAS_NE, pasoVista(a.paso, 0.5, -1, 37), a.t[1], a.t[2])
    ponerInc(img, TORSO_NE, 16 + a.t[1], 12 + a.t[2], MA, a.k)
    poner(img, CABEZA_NE, a.c[1], a.c[2], MA)
    brazo(img, a.bc[1], a.bc[2], a.bc[3], true)
    contorno(img, 38)
  end
end

local ATQ_N = {
  { t = { 0, -1 }, c = { 17, 8 }, paso = 7,
    bi = { { 16, 12 }, { 13, 13 }, { 14, 11 } }, bd = { { 24, 12 }, { 27, 13 }, { 26, 11 } } },
  { t = { 0, 0 }, c = { 17, 8 }, paso = 1,
    bi = { { 16, 12 }, { 15, 10 }, { 17, 8 } }, bd = { { 24, 12 }, { 25, 10 }, { 23, 8 } } },
  { t = { 0, 1 }, c = { 17, 10 }, paso = 1,
    bi = { { 16, 14 }, { 14, 17 }, { 17, 19 } }, bd = { { 24, 14 }, { 26, 17 }, { 23, 19 } } },
  { t = { 0, 1 }, c = { 17, 10 }, paso = 8 },
}
local function atacarN(i)
  return function(img)
    local a = ATQ_N[i]
    if a.bi then
      brazo(img, a.bi[1], a.bi[2], a.bi[3], false)
      brazo(img, a.bd[1], a.bd[2], a.bd[3], true)
    end
    piernas(img, PIERNAS_N, pasoVista(a.paso, 0, -1, 37), a.t[1], a.t[2])
    poner(img, TORSO_N, 16 + a.t[1], 12 + a.t[2], MA)
    ponerInc(img, CABEZA_N, a.c[1] + 1, a.c[2], MA, -1)
    if not a.bi then
      poner(img, BRAZO_N_I, 14 + a.t[1], 12 + a.t[2], MA)
      poner(img, BRAZO_N_D, 24 + a.t[1], 13 + a.t[2], MA)
    end
    contorno(img, 38)
  end
end

---------------------------------------------------------------- montaje
local cuadros, ETIQUETAS, DURACIONES = {}, {}, {}
local function tanda(nombre, lista, dur)
  local desde = #cuadros + 1
  for i, f in ipairs(lista) do
    cuadros[#cuadros + 1] = f
    DURACIONES[#DURACIONES + 1] = type(dur) == "table" and dur[i] or dur
  end
  ETIQUETAS[#ETIQUETAS + 1] = { nombre, desde, #cuadros }
end
local function lista(f, n) local t = {} for i = 1, n do t[i] = f(i) end return t end

local AT = { 0.12, 0.08, 0.10, 0.14 }
tanda("andar_s", lista(andarS, 8), 0.14)
tanda("andar_se", lista(andarSE, 8), 0.14)
tanda("andar_e", lista(andarA, 8), 0.14)
tanda("andar_ne", lista(andarNE, 8), 0.14)
tanda("andar_n", lista(andarN, 8), 0.14)
tanda("atacar_s", lista(atacarS, 4), AT)
tanda("atacar_se", lista(atacarSE, 4), AT)
tanda("atacar_e", ATAQUE, AT)
tanda("atacar_ne", lista(atacarNE, 4), AT)
tanda("atacar_n", lista(atacarN, 4), AT)
tanda("morir", MUERTE, { 0.09, 0.09, 0.11, 0.13, 0.16, 1.0 })

L.construir("zombi", 40, 40, cuadros, ETIQUETAS, DURACIONES, { pies = { 20, 38 } })
