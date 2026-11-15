// Carga las hojas exportadas de Aseprite (assets/<nombre>.png + .json):
// fotogramas, etiquetas de animación y puntos de anclaje (slices de 1x1).

const NOMBRES = [
  "jugador", "zombi", "zombi_b", "zombi_c", "corredor",
  "brazos_pistola", "brazos_subfusil", "brazos_escopeta", "pistola", "subfusil", "escopeta", "fogonazo",
  "suelo", "manchas", "detalles",
  "coche", "barril", "caja", "sacos", "hoguera", "cono", "neumaticos", "contenedor", "barrera",
  "arbol", "arbusto", "farola",
  "joystick", "corazon", "moneda", "botiquin", "letra", "titulo", "banderas", "palotes", "cifras_sangre",
];

export const S = {};

function cargarImagen(url) {
  return new Promise((ok, mal) => {
    const im = new Image();
    im.onload = () => ok(im);
    im.onerror = () => mal(new Error("No se pudo cargar " + url));
    im.src = url;
  });
}

// Copia de la imagen pintada de un solo color (destello al recibir un golpe, letra de colores).
export function teñida(img, color) {
  const c = document.createElement("canvas");
  c.width = img.width; c.height = img.height;
  const g = c.getContext("2d");
  g.drawImage(img, 0, 0);
  g.globalCompositeOperation = "source-in";
  g.fillStyle = color;
  g.fillRect(0, 0, c.width, c.height);
  return c;
}

// Sprites que pueden no estar todavía (el juego dibuja algo sencillo en su lugar).
const OPCIONALES = ["muro", "porton", "alambre", "tienda", "iconos_tienda",
  "bate", "machete", "francotirador", "ballesta", "lanzallamas",
  "brazos_bate", "brazos_machete", "brazos_francotirador", "brazos_ballesta", "brazos_lanzallamas",
  "proyectiles", "fuego", "explosion",
  "torreta", "foco", "mina", "barril_explosivo", "cepo", "enfermeria", "taller", "armeria",
  "perro", "gato", "cuervo"];
const BRAZOS = ["brazos_pistola", "brazos_subfusil", "brazos_escopeta", "brazos_bate", "brazos_machete",
  "brazos_francotirador", "brazos_ballesta", "brazos_lanzallamas"];

export async function cargarSprites(base = "assets/") {
  await Promise.all([...NOMBRES, ...OPCIONALES].map(async (n) => {
    if (OPCIONALES.includes(n)) {
      try { await cargarUno(base, n); } catch (e) { /* aún sin dibujar */ }
      return;
    }
    await cargarUno(base, n);
  }));
  await prepararVariantes(base);
  prepararSupervivientes();
  for (const n of ["palotes", "cifras_sangre"]) S[n].blanca = teñida(S[n].img, "#f2ece4");
  for (const n of ["jugador", "zombi", "zombi_b", "zombi_c", "corredor", ...BRAZOS]) {
    if (S[n]) S[n].blanca = teñida(S[n].img, "#ffffff");
  }
  for (const n of ["jugador", ...BRAZOS]) {
    if (S[n]) S[n].roja = teñida(S[n].img, "#ff4a4a");
  }
}

async function cargarUno(base, n) {
  {
    const [img, data] = await Promise.all([
      cargarImagen(base + n + ".png"),
      fetch(base + n + ".json").then((r) => r.json()),
    ]);
    const frames = data.frames.map((f) => ({ ...f.frame, dur: f.duration / 1000 }));
    const tags = {};
    for (const t of data.meta.frameTags || []) tags[t.name] = { desde: t.from, hasta: t.to };
    // Puntos: "hombro" (igual en todos los fotogramas) o "hombro#3" (solo el fotograma 3).
    const puntos = {};
    for (const s of data.meta.slices || []) {
      const [nombre, idx] = s.name.split("#");
      const b = s.keys[0].bounds;
      (puntos[nombre] ??= {})[idx === undefined ? "*" : +idx] = { x: b.x, y: b.y };
    }
    S[n] = { img, frames, tags, puntos, w: frames[0].w, h: frames[0].h };
  }
}

// Variantes de color de los zombis (assets/variantes.json, de arte/variantes.py): otra ropa y otro pelo.
// Cada variante guarda su hoja recoloreada y una capa solo con los ojos en amarillo, que el juego
// pinta encima de la oscuridad para que brillen.
const AMARILLO = [255, 214, 64];
async function prepararVariantes(base) {
  let datos = {};
  try { datos = await fetch(base + "variantes.json").then((r) => (r.ok ? r.json() : {})); } catch (e) { /* sin variantes */ }
  for (const n of ["zombi", "zombi_b", "zombi_c", "corredor"]) {
    const d = datos[n] || { ojo: null, variantes: [{}] };
    S[n].variantes = d.variantes.map((cambios) => recolorear(S[n].img, cambios, d.ojo));
  }
}

// Supervivientes: el mismo dibujo que el jugador con otra chaqueta, otro pantalón, otro pelo y otra piel.
const RAMPAS = {
  chaqueta: ["1b2430", "2a3a4d", "3b526b", "52708c", "7391ab"],
  caqui: ["2a231b", "40362a", "5a4c3a", "77664f", "958463"],
  pelo: ["1c1512", "2e221b", "45342a", "5e4a3a"],
  piel: ["4a2f28", "7a4e3c", "a36f55", "c4937a", "deb89e"],
};
const ROPA_SUPERVIVIENTES = [
  { chaqueta: ["1f2416", "323a22", "4a5432", "66713f", "858f55"], caqui: ["1a2030", "28324a", "3a4866", "526285", "6a7ba0"], pelo: ["4a3a1e", "6e5a30", "917a45", "b09a5e"] },
  { chaqueta: ["2e1814", "4a2620", "6b3a2e", "8a5340", "a8705a"], caqui: ["17171c", "25252c", "35353e", "4a4954", "5e5d68"], pelo: ["0f0e10", "1c1a1d", "2c2a2e", "3e3b40"], piel: ["2e1a14", "4f3022", "6b4330", "875a40", "a37658"] },
  { chaqueta: ["33290f", "54441c", "78632c", "9c8444", "b39c5a"], caqui: ["2b2c2f", "414348", "5a5d62", "777a7e", "94979a"], pelo: ["3d1a10", "63301c", "8a4a2a", "a8663d"] },
  { chaqueta: ["3a3a38", "5c5a52", "85837a", "aeab9f", "d1cec0"], caqui: ["2a2018", "40301f", "594430", "765c40", "8f7350"], pelo: ["4a4a48", "6e6e6a", "93938d", "b3b2aa"], piel: ["5c3b30", "8a5c48", "b5836a", "d4a68e", "ecc8b0"] },
];
// Trajes del jugador (se desbloquean con logros; ver perfil.js).
const ROPA_TRAJES = {
  militar: { chaqueta: ["1f2416", "323a22", "4a5432", "66713f", "858f55"], caqui: ["22281a", "343d26", "4a5636", "637048", "7d8a5c"] },
  motero: { chaqueta: ["141317", "222127", "33323a", "4a4952", "5f5e68"], caqui: ["1a2030", "28324a", "3a4866", "526285", "6a7ba0"], pelo: ["0f0e10", "1c1a1d", "2c2a2e", "3e3b40"] },
  medico: { chaqueta: ["5c5a52", "85837a", "aeab9f", "d1cec0", "e8e5d8"], caqui: ["23332f", "365049", "4d6d64", "6b8c82", "88a8a0"] },
  lenador: { chaqueta: ["3a1210", "62201c", "8a3229", "a94a3b", "c46a58"], caqui: ["1a2030", "28324a", "3a4866", "526285", "6a7ba0"], pelo: ["3d1a10", "63301c", "8a4a2a", "a8663d"] },
  piromano: { chaqueta: ["3d1c0e", "6b3418", "9a5528", "c27a42", "e0a26a"], caqui: ["17171c", "25252c", "35353e", "4a4954", "5e5d68"] },
  veterano: { chaqueta: ["2b2c2f", "414348", "5a5d62", "777a7e", "94979a"], caqui: ["1e1f24", "292b31", "34363d", "41444c", "51545d"], pelo: ["4a4a48", "6e6e6a", "93938d", "b3b2aa"] },
};
function cambiosDe(ropa) {
  const cambios = {};
  for (const [rampa, dest] of Object.entries(ropa)) RAMPAS[rampa].forEach((h, i) => { cambios[h] = dest[Math.min(i, dest.length - 1)]; });
  return cambios;
}
const vestidos = new Map();
// Hoja del sprite «n» (el jugador o unos brazos) con la ropa del traje; la original si no hay traje.
export function vestido(n, traje) {
  if (!traje || traje === "original" || !ROPA_TRAJES[traje] || !S[n]) return S[n]?.img;
  const k = n + "|" + traje;
  if (!vestidos.has(k)) vestidos.set(k, recolorear(S[n].img, cambiosDe(ROPA_TRAJES[traje]), null).img);
  return vestidos.get(k);
}

function prepararSupervivientes() {
  S.supervivientes = ROPA_SUPERVIVIENTES.map((v) => {
    const cambios = {};
    for (const [rampa, dest] of Object.entries(v)) RAMPAS[rampa].forEach((h, i) => { cambios[h] = dest[Math.min(i, dest.length - 1)]; });
    return { cuerpo: recolorear(S.jugador.img, cambios, null).img, brazos: recolorear(S.brazos_pistola.img, cambios, null).img };
  });
}

function recolorear(img, cambios, ojo) {
  const w = img.width, h = img.height;
  const c = document.createElement("canvas"); c.width = w; c.height = h;
  const o = document.createElement("canvas"); o.width = w; o.height = h;
  const g = c.getContext("2d"), go = o.getContext("2d");
  g.drawImage(img, 0, 0);
  const px = g.getImageData(0, 0, w, h), ojos = go.createImageData(w, h);
  const mapa = new Map(Object.entries(cambios).map(([a, b]) => [parseInt(a, 16), [parseInt(b.slice(0, 2), 16), parseInt(b.slice(2, 4), 16), parseInt(b.slice(4, 6), 16)]]));
  const ojoN = ojo ? parseInt(ojo, 16) : -1;
  const p = px.data;
  for (let i = 0; i < p.length; i += 4) {
    if (!p[i + 3]) continue;
    const k = (p[i] << 16) | (p[i + 1] << 8) | p[i + 2];
    if (k === ojoN) {
      [p[i], p[i + 1], p[i + 2]] = AMARILLO;
      ojos.data.set([...AMARILLO, 255], i);
      continue;
    }
    const n = mapa.get(k);
    if (n) { p[i] = n[0]; p[i + 1] = n[1]; p[i + 2] = n[2]; }
  }
  g.putImageData(px, 0, 0);
  go.putImageData(ojos, 0, 0);
  c.pixeles = px;              // el ragdoll los necesita al morir: así no hay que leerlos de la tarjeta gráfica
  return { img: c, ojos: o };
}

// Punto de anclaje de un sprite en el fotograma i (o el valor por defecto si no existe).
export function punto(spr, nombre, i = 0, defecto = null) {
  const p = spr.puntos[nombre];
  if (!p) return defecto;
  return p[i] ?? p["*"] ?? defecto;
}

// Fotograma de una animación según el tiempo transcurrido.
export function fotograma(spr, tag, t, enBucle = true) {
  const r = spr.tags[tag];
  if (!r) return 0;
  let total = 0;
  for (let i = r.desde; i <= r.hasta; i++) total += spr.frames[i].dur;
  let tt = enBucle ? ((t % total) + total) % total : Math.max(0, Math.min(t, total - 1e-6));
  for (let i = r.desde; i <= r.hasta; i++) {
    tt -= spr.frames[i].dur;
    if (tt < 0) return i;
  }
  return r.hasta;
}

// Fotograma de una animación según el avance de 0 a 1 (para estirarla a cualquier duración).
export function fotogramaPorAvance(spr, tag, p) {
  const r = spr.tags[tag];
  if (!r) return 0;
  const n = r.hasta - r.desde + 1;
  return r.desde + Math.max(0, Math.min(n - 1, Math.floor(p * n)));
}

export function duracion(spr, tag) {
  const r = spr.tags[tag];
  if (!r) return 0;
  let total = 0;
  for (let i = r.desde; i <= r.hasta; i++) total += spr.frames[i].dur;
  return total;
}

export function primero(spr, tag) { return spr.tags[tag] ? spr.tags[tag].desde : 0; }
export function cuantos(spr, tag) { return spr.tags[tag] ? spr.tags[tag].hasta - spr.tags[tag].desde + 1 : spr.frames.length; }

// Dibuja el fotograma i con (x, y) en la esquina superior izquierda; voltear = espejo horizontal.
export function dibujar(g, spr, i, x, y, voltear = false, img = spr.img) {
  const f = spr.frames[i] || spr.frames[0];
  x = Math.round(x); y = Math.round(y);
  if (!voltear) {
    g.drawImage(img, f.x, f.y, f.w, f.h, x, y, f.w, f.h);
  } else {
    g.save();
    g.translate(x + f.w, y);
    g.scale(-1, 1);
    g.drawImage(img, f.x, f.y, f.w, f.h, 0, 0, f.w, f.h);
    g.restore();
  }
}

// Dibuja el fotograma i de forma que su punto de anclaje caiga en (wx, wy).
export function dibujarAnclado(g, spr, i, wx, wy, ancla, voltear = false, img = spr.img) {
  const ax = voltear ? spr.w - 1 - ancla.x : ancla.x;
  dibujar(g, spr, i, Math.round(wx) - ax, Math.round(wy) - ancla.y, voltear, img);
}

// ---------------------------------------------------------------- texto pixelado
// La hoja "letra" tiene celdas de 6x10 con estos caracteres, en este orden.
const ORDEN = [..."ABCDEFGHIJKLMNÑOPQRSTUVWXYZÁÉÍÓÚÜ0123456789.,:;!¡?¿+-×/%()'\" "];
const INDICE = new Map(ORDEN.map((c, i) => [c, i]));
const CW = 6, CH = 10;
const colores = new Map();

function letraDe(color) {
  if (!colores.has(color)) colores.set(color, teñida(S.letra.img, color));
  return colores.get(color);
}

export const ALTO_LETRA = CH;
export function anchoTexto(t, k = 1) { return ([...String(t)].length * CW - 1) * k; }

// Texto con sombra. alinear: "izq" | "centro" | "der". k = tamaño (1, 2...). y = borde superior de la celda.
export function texto(g, t, x, y, color = "#ffffff", alinear = "izq", k = 1, sombra = "#0e0d12") {
  const letras = [...String(t).toUpperCase()];
  const w = (letras.length * CW - 1) * k;
  if (alinear === "centro") x -= Math.floor(w / 2);
  else if (alinear === "der") x -= w;
  x = Math.round(x); y = Math.round(y);
  const capas = sombra ? [[letraDe(sombra), k], [letraDe(color), 0]] : [[letraDe(color), 0]];
  for (const [img, d] of capas) {
    for (let i = 0; i < letras.length; i++) {
      const idx = INDICE.get(letras[i]);
      if (idx === undefined || letras[i] === " ") continue;
      g.drawImage(img, idx * CW, 0, CW, CH, x + i * CW * k + d, y + d, CW * k, CH * k);
    }
  }
  return w;
}
