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

local cuadros = {}
for i = 1, 8 do cuadros[#cuadros + 1] = andarA(i) end
for i = 1, 4 do cuadros[#cuadros + 1] = ATAQUE[i] end
for i = 1, 6 do cuadros[#cuadros + 1] = MUERTE[i] end

local ETIQUETAS = { { "andar", 1, 8 }, { "atacar", 9, 12 }, { "morir", 13, 18 } }
local DURACIONES = {
  0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14,
  0.12, 0.08, 0.10, 0.14,
  0.09, 0.09, 0.11, 0.13, 0.16, 1.0,
}

L.construir("zombi", 40, 40, cuadros, ETIQUETAS, DURACIONES, { pies = { 20, 38 } })
