// Carga las hojas exportadas de Aseprite (assets/<nombre>.png + .json):
// fotogramas, etiquetas de animación y puntos de anclaje (slices de 1x1).

const NOMBRES = [
  "jugador", "zombi", "zombi_b", "zombi_c", "corredor",
  "brazos_pistola", "brazos_subfusil", "brazos_escopeta", "pistola", "subfusil", "escopeta", "fogonazo",
  "suelo", "manchas", "detalles",
  "coche", "barril", "caja", "sacos", "hoguera", "cono", "neumaticos", "contenedor", "barrera",
  "arbol", "arbusto", "farola",
  "joystick", "corazon", "moneda", "botiquin", "letra", "titulo",
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
  for (const n of ["jugador", "brazos_pistola", "brazos_subfusil", "brazos_escopeta"]) {
    S[n].roja = teñida(S[n].img, "#ff4a4a");
  }
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
