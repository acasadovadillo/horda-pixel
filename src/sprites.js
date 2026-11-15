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

export async function cargarSprites(base = "assets/") {
  await Promise.all(NOMBRES.map(async (n) => {
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
  }));
  for (const n of ["jugador", "zombi", "zombi_b", "zombi_c", "corredor", "brazos_pistola", "brazos_subfusil", "brazos_escopeta"]) {
    S[n].blanca = teñida(S[n].img, "#ffffff");
  }
  await prepararVariantes(base);
  for (const n of ["palotes", "cifras_sangre"]) S[n].blanca = teñida(S[n].img, "#f2ece4");
  for (const n of ["jugador", "brazos_pistola", "brazos_subfusil", "brazos_escopeta"]) {
    S[n].roja = teñida(S[n].img, "#ff4a4a");
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
