# Guía de arte de Horda Pixel — estilo realista

Horda Pixel es un juego de zombis para móvil en vertical. Todo el arte es pixel art **dibujado por scripts de Lua que se ejecutan dentro de Aseprite** (`aseprite -b --script`). El usuario pidió que los sprites sean **más realistas** que la primera versión (que era de muñecos cabezones de 16×20 con colores planos).

## 1. Qué significa «realista» aquí

1. **Proporciones humanas reales.** Un adulto mide 35 px de alto y unas 6,5–7 cabezas: cabeza de 5–6 px, hombros de 9–10 px, piernas de casi la mitad de la altura. Nada de cabezas grandes ni cuerpos de muñeco.
2. **Paleta apagada y sucia.** Usa las rampas de `L.P` (en `arte/lib.lua`). Luz de atardecer nublado: tonos desaturados. Los únicos colores vivos son el fuego, el fogonazo, la sangre fresca y la interfaz. Puedes añadir colores propios con `L.hex` si siguen esa línea (apagados, con rampa de 3–5 tonos).
3. **Volumen con luz coherente.** La luz viene de **arriba a la izquierda**. Cada forma lleva tono base, sombra (abajo y a la derecha) y luz (arriba y a la izquierda), con 3–5 tonos por material. Sombra de oclusión bajo la barbilla, bajo los aleros, entre las piernas, bajo los objetos.
4. **Contorno selectivo de 1 px.** Usa el tono más oscuro del propio material o `tinta`; nunca negro puro. Más marcado abajo y a la derecha; arriba a la izquierda puede aclararse. Pocas líneas interiores: las formas se separan por cambio de tono.
5. **Materiales y desgaste.** Tela con arrugas, metal con brillo fino, óxido, suciedad, sangre seca, madera astillada. Trabaja con **grupos de píxeles** (manchas de 2–4 px), no con píxeles sueltos. El granulado fino solo va en suelos (asfalto, tierra) y con poco contraste.
6. **Prohibido:** degradados suaves, suavizado (anti-aliasing) contra la transparencia, semitransparencias (el alfa es 0 o 255), sombreado «de almohada» (oscurecer todo el borde por igual), bandas paralelas al contorno, colores saturados puros, caras de dibujo animado.
7. **Legible a tamaño de juego.** En el móvil cada píxel se ve a ×3–×4. La silueta y los colores deben distinguirse sobre asfalto oscuro, acera gris y hierba. Mira siempre la tira «tamaño de juego ×3» de la vista.
8. **Animación con peso.** Arcos, anticipación, balanceo de cabeza y torso, ropa y pelo con retardo. Los pies apoyados no resbalan y pisan siempre en la misma fila.
9. **Original.** No copies personajes, logotipos ni diseños de juegos, marcas o armas reales concretas: todo genérico y propio.

## 2. Vista y escala

- **Vista 3/4 cenital:** la cámara mira desde arriba y desde el sur. De cada cosa se ve su parte de arriba y su cara sur (la que mira al borde inferior de la pantalla). Las alturas se dibujan casi completas; la profundidad se comprime al 60 %.
- **Personas y zombis:** de perfil 3/4 **mirando a la derecha** (el juego los voltea para mirar a la izquierda). Se intuye la parte alta de la cabeza y de los hombros.
- **Escala:** 20 px = 1 m. Persona 35 px; loseta de suelo 24×24 px; carretera de 5 losetas de ancho.
- Las sombras en el suelo las pinta el juego: **no dibujes la sombra proyectada** de personajes y objetos.

### 8 direcciones (personas y zombis, desde 2026-11-15)
Jugador y zombis miran en 8 direcciones. Se dibujan **5** y el juego voltea 3 en espejo:
- `s`: hacia abajo de la pantalla, de frente a la cámara (se ve la cara entera, el pecho y las puntas de los pies).
- `se`: abajo a la derecha, 3/4 de frente (cara y pecho girados unos 45°).
- `e`: a la derecha, el perfil 3/4 de siempre (los fotogramas que ya existían).
- `ne`: arriba a la derecha, 3/4 de espaldas (se ve la nuca, la espalda y un poco de perfil de la cara).
- `n`: hacia arriba, de espaldas a la cámara (nuca, espalda, mochila del jugador muy visible).
- `w`, `sw` y `nw` son el espejo de `e`, `se` y `ne`: no se dibujan.
Cada animación lleva el sufijo de la dirección: `quieto_s`, `correr_ne`, `andar_n`, `atacar_se`... `morir` es una sola (el juego la voltea). Con la cámara 3/4, al andar hacia `s` o `n` las piernas se mueven sobre todo arriba y abajo (la de delante baja 1–2 px y se ve más grande); los pies siguen pisando la fila 38 y el punto `pies` sigue en { 20, 38 }. El jugador no lleva brazos en ninguna dirección: el juego pinta los brazos con el arma girando alrededor del punto `hombro` (en `n` y `ne`, por detrás del cuerpo).

## 3. Cómo se trabaja

- Lee `arte/lib.lua` (la API) y `arte/ejemplo/ejemplo.lua` (ejemplo de uso; **no** es referencia de calidad).
- Trabaja **solo dentro de tu carpeta** `arte/intentos/<tu-carpeta>/`. Un archivo `.lua` por sprite, con el nombre del sprite (`jugador.lua`...). Excepción: `zombi.lua` construye `zombi` y `zombi_b`.
- Cada archivo empieza con `local L = dofile(app.params.lib)` y termina llamando a `L.construir(nombre, ancho, alto, fotogramas, etiquetas, duraciones, puntos)`.
- Para probar: `arte/probar.sh arte/intentos/<tu-carpeta>/salida arte/intentos/<tu-carpeta>/<sprite>.lua` (admite varios archivos). Ejecuta Aseprite, exporta, comprueba el contrato y genera `salida/vista_<sprite>.png`.
- **Mira la vista con la herramienta Read después de cada cambio.** Es la única forma de saber cómo queda. Itera: dibujar → mirar → criticar con dureza → corregir. Mínimo 4 rondas por sprite; los personajes necesitan más.
- Si te falta una función, defínela como `local` en tu archivo. **No modifiques** `lib.lua`, `contrato.json`, `probar.sh`, `src/`, `assets/` ni carpetas de otros.
- No uses imágenes externas, descargas ni extensiones de generación por IA: todo píxel sale de tu código Lua. No abras la interfaz de Aseprite.
- Las medidas, etiquetas, número de fotogramas y puntos de anclaje son **obligatorios** (los comprueba `comprobar.py`): el juego depende de ellos.
- Puntos de anclaje: último argumento de `L.construir`, por ejemplo `{ pies = { 20, 38 } }`, o un valor por fotograma: `{ hombro = { { 20, 13 }, { 20, 14 }, ... } }`.
- El código debe ser determinista (usa `L.azar(semilla)`, no `math.random`).

## 4. Contrato por grupo

### jugador — `jugador` (40×40)
Superviviente adulto, unos 30 años, pelo corto oscuro, barba de varios días. Chaqueta azul acero gastada (rampa `chaqueta`), pantalón caqui oscuro (`caqui`), botas (`cuero`), mochila pequeña de cuero a la espalda. Mira a la derecha.
- Suelas apoyadas en la fila y = 38, cuerpo centrado en x = 20. Punto `pies` = { 20, 38 }. Coronilla hacia y = 4.
- **`quieto` (4 fotogramas, 0,22 s):** respiración sutil (torso y cabeza suben 1 px).
- **`correr` (8 fotogramas, 0,075 s):** ciclo de carrera completo (contacto, recepción, paso, impulso; dos zancadas), torso algo inclinado hacia delante, vaivén de 1–2 px, la mochila rebota con retardo.
- **En `quieto` y `correr` el cuerpo se dibuja SIN BRAZOS.** Los brazos van en los sprites `brazos_*` (grupo armas), que el juego pinta encima girándolos alrededor del hombro para apuntar. Dibuja el hombro como un remate redondeado de la chaqueta. Punto `hombro` = articulación del hombro, hacia { 20, 13 }; si el torso sube o baja, da un valor por fotograma.
- **`morir` (6 fotogramas; 0,09 · 0,09 · 0,11 · 0,13 · 0,16 · 1,0 s):** aquí **sí se dibujan los brazos**. Sacudida del impacto, se le doblan las rodillas, cae, golpea el suelo, queda tendido (cuerpo horizontal en las filas bajas del lienzo), y el último fotograma añade un charco de sangre.

### zombi — `zombi` y `zombi_b` (40×40)
Zombis lentos. `pies` = { 20, 38 }. Miran a la derecha. Piel gris verdosa (`zombi`), ropa rota y sucia, heridas (`carne`), boca ensangrentada, mirada vacía (ojos claros o hundidos, **no** rojos brillantes).
- `zombi`: hombre con camisa granate rota (`ropa_a`) y vaqueros (`vaquero`), descalzo de un pie.
- `zombi_b`: otra persona distinta (por ejemplo una mujer o un hombre corpulento con sudadera `ropa_b` o ropa `ropa_c`), con otro pelo. Debe distinguirse del primero a tamaño de juego.
- **`andar` (8 fotogramas, 0,14 s):** arrastra un pie, torso vencido hacia delante, cabeza ladeada, un brazo extendido al frente y el otro colgando.
- **`atacar` (4 fotogramas; 0,12 · 0,08 · 0,10 · 0,14 s):** toma impulso, zarpazo con los dos brazos hacia delante (el golpe es el 2.º fotograma), sigue el movimiento, se recupera.
- **`morir` (6 fotogramas; 0,09 · 0,09 · 0,11 · 0,13 · 0,16 · 1,0 s):** el disparo le echa la cabeza atrás, cae, queda tendido y el último fotograma añade un charco de sangre.

### corredor — `corredor` (40×40)
Zombi rápido. `pies` = { 20, 38 }. Demacrado, piel pálida (`palido`), costillas marcadas, camiseta de tirantes sucia (`tela`) o torso desnudo, pantalón oscuro hecho jirones. Debe leerse como **otro tipo de enemigo** a simple vista: más delgado, más inclinado, más claro.
- **`andar` (8 fotogramas, 0,065 s):** esprint encorvado unos 30° hacia delante, brazos atrás o dando zarpazos.
- **`atacar` (4 fotogramas; 0,10 · 0,07 · 0,09 · 0,12 s):** salto o embestida; el golpe es el 2.º fotograma.
- **`morir` (6 fotogramas; 0,09 · 0,09 · 0,11 · 0,13 · 0,16 · 1,0 s):** cae de bruces por la inercia y queda tendido con charco de sangre en el último.

### armas — `brazos_pistola`, `brazos_subfusil`, `brazos_escopeta` (44×20), `pistola`, `subfusil`, `escopeta` (36×18), `fogonazo` (18×14)
- **`brazos_*`:** los **dos brazos del jugador** (mangas con la rampa `chaqueta`, manos con `piel`) sujetando el arma, apuntando **a la derecha en horizontal**. Punto `hombro` = { 8, 10 }: de ahí sale el brazo; el juego coloca ese píxel sobre el hombro del cuerpo y gira el sprite. Grosor de la manga 3–4 px, manos de unos 3×3 px (a escala de un cuerpo de 35 px).
  - Punto `boca` = último píxel del cañón (por donde sale la bala). Punto `casquillo` = ventana de expulsión.
  - `pistola`: pistola semiautomática sujeta con las dos manos, brazos casi estirados (`boca` hacia x = 27–29).
  - `subfusil`: subfusil compacto con cargador vertical, una mano en la empuñadura y otra delante (`boca` hacia x = 30–33).
  - `escopeta`: escopeta de corredera con culata y guardamanos de madera, cañón largo (`boca` hacia x = 36–40).
  - Etiquetas: **`apuntar`** (1 fotograma), **`disparar`** (2 fotogramas de 0,04 s: retroceso de 2 px y vuelta a medias), **`recargar`** (4 fotogramas de 0,25 s: baja el arma, la mano va al cargador o a los cartuchos, lo mete, vuelve arriba).
  - El hombro no se mueve de { 8, 10 } en ningún fotograma.
- **`pistola`, `subfusil`, `escopeta` (iconos, 1 fotograma):** el arma sola de perfil, más grande y detallada, centrada. Son los botones de la interfaz.
- **`fogonazo` (3 fotogramas, 0,03 s):** llamarada hacia la derecha; punto `origen` = { 1, 7 } (donde toca la boca del cañón). Grande con núcleo blanco amarillento, más pequeño, y resto de humo.

### suelo — `suelo` (24×24), `manchas` (24×24), `detalles` (24×24)
- **`suelo`**, etiquetas en este orden: `hierba` ×4, `asfalto` ×4, `grieta` ×2, `linea` ×1, `acera` ×2, `bordillo_i` ×1, `bordillo_d` ×1, `tierra` ×2. Todas las losetas deben repetirse sin que se noten las juntas, consigo mismas y con las demás variantes de su tipo.
  - `hierba`: hierba seca y descuidada, briznas en mechones; variantes: lisa, con hierbajos, con hojas secas, más rala.
  - `asfalto`: asfalto viejo de grano fino y poco contraste; variantes con un parche, una mancha de aceite, desgaste.
  - `grieta`: asfalto con grietas finas (línea oscura con borde claro) que no tocan los bordes de la loseta.
  - `linea`: asfalto con un tramo de línea amarilla gastada, vertical, de 3 px de ancho (x = 11 a 13), de y = 3 a y = 20, desconchada.
  - `acera`: losas de hormigón con juntas, suciedad y alguna fisura. Forma una tira vertical de una loseta de ancho.
  - `bordillo_i`: loseta de asfalto cuyos 5 px de la izquierda son el bordillo (piedra clara arriba y cara en sombra hacia la calzada). `bordillo_d`: lo mismo en los 5 px de la derecha, con la cara iluminada.
  - `tierra`: loseta de **hierba** con una calva irregular de tierra y piedrecitas en el centro que **no toca los bordes** (se coloca suelta entre la hierba).
- **`manchas` (4 fotogramas, fondo transparente):** sangre seca oscura: charco, salpicadura, rastro de arrastre, gotas. Formas irregulares.
- **`detalles` (8 fotogramas, fondo transparente):** 0 papeles y basura, 1 hojas secas, 2 marcas de frenada, 3 mancha de aceite, 4 tapa de alcantarilla, 5 cascotes, 6 cristales rotos, 7 hierbajos saliendo de una grieta.

### coche — `coche` (40×64)
Coche abandonado en vista 3/4 cenital, con el morro hacia arriba: se ven el techo, el capó, las lunas y, abajo, unos 10–12 px de la cara trasera (maletero, pilotos, parachoques, matrícula). Carrocería de unos 34 px de ancho y 56 de largo. Sucio, con óxido, lunas rotas, alguna rueda desinflada. Punto `base` = { 20, 62 }.
- 3 fotogramas = 3 variantes: 0 berlina roja (`pintura`), 1 utilitario gris azulado o blanco sucio, 2 coche calcinado (negro y óxido, sin cristales).

### objetos — vista 3/4 (cara de arriba + cara frontal); punto `base` = centro inferior apoyado en el suelo
- `barril` (16×22, 2 variantes): bidón metálico con tapa elíptica y nervios; 0 azul grisáceo oxidado, 1 rojo con franja de peligro.
- `caja` (20×20, 2 variantes): caja de madera de tablones con clavos; 0 cerrada, 1 rota o con marca militar.
- `sacos` (72×26): parapeto de sacos terreros de arpillera (`saco`) en dos o tres hiladas al tresbolillo, vencidos por el peso, con costuras.
- `hoguera` (18×32, etiqueta `arder` de 4 fotogramas, 0,1 s): bidón oxidado con agujeros por los que se ven las brasas y llamas por arriba que se mueven.
- `cono` (10×14): cono de obra sucio con banda reflectante.
- `neumaticos` (20×18): pila de dos o tres neumáticos viejos.
- `contenedor` (34×30): contenedor de basura metálico con tapa, óxido y una bolsa al lado.
- `barrera` (40×18): barrera de hormigón tipo New Jersey, desconchada.

### vegetacion — punto `base` = pie del tronco o del poste
- `arbol` (48×64, 3 variantes): 0 frondoso con copa densa en masas de hojas iluminadas desde arriba a la izquierda, 1 otoñal medio pelado con hojas ocres, 2 seco con ramas desnudas. `base` hacia { 24, 62 }.
- `arbusto` (24×18, 2 variantes): 0 verde, 1 seco con ramitas. `base` hacia { 12, 16 }.
- `farola` (16×60, 2 variantes): poste metálico con brazo y luminaria; 0 encendida (cristal con `fuego` 4–5), 1 rota y apagada. Puntos `base` y `luz` (centro de la luminaria).

### interfaz
- `joystick` (52×52): etiqueta `base` (aro exterior oscuro) y etiqueta `boton` (botón de unos 26 px centrado en { 26, 26 }, aspecto de goma o metal). Píxeles opacos; el juego aplica la transparencia.
- `corazon` (11×10): icono de vida.
- `moneda` (10×10, etiqueta `girar` de 6 fotogramas, 0,09 s): moneda de oro girando, con canto y brillo.
- `botiquin` (14×12): botiquín en vista 3/4 con cruz roja y asa.
- `letra`: tipografía pixelada en mayúsculas, legible y con carácter (tipo plantilla militar). Celda de 6×10 por carácter: el dibujo ocupa 5×7 en las columnas 0–4 y las filas 2–8; las filas 0–1 son para las tildes y la fila 9 para la cola de la coma y el punto y coma. Blanco puro (`ffffff`) sobre transparente. Un solo fotograma de 366×10 con estos 61 caracteres en este orden exacto (el último es el espacio):
  `A B C D E F G H I J K L M N Ñ O P Q R S T U V W X Y Z Á É Í Ó Ú Ü 0 1 2 3 4 5 6 7 8 9 . , : ; ! ¡ ? ¿ + - × / % ( ) ' " (espacio)`
  En Lua guarda los glifos en una lista ordenada (las letras con tilde ocupan varios bytes: no indexes una cadena).
- `titulo` (150×56): logotipo «HORDA PIXEL» en dos líneas: HORDA grande en letras de bloque rojo sangre, gastadas y con goterones; PIXEL más pequeño en color hueso o amarillo gastado. Fondo transparente, contorno oscuro.
- `icono` (64×64): icono de la app, cuadrado **opaco** sin transparencias: una imagen potente y legible en pequeño (por ejemplo la cara de un zombi de cerca, o el superviviente a contraluz frente a la horda al atardecer). Lo importante dentro del cuadrado central de 44×44.
