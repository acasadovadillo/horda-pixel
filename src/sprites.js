// Carga las hojas exportadas de Aseprite (assets/<nombre>.png + .json).

const NOMBRES = [
  "jugador", "zombi", "corredor", "pistola", "subfusil", "escopeta", "fogonazo",
  "moneda", "botiquin", "corazon", "suelo", "manchas", "coche", "barril", "caja",
  "sacos", "arbol", "arbusto", "farola", "hoguera", "joystick", "letra",
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

// Copia de la imagen pintada de un solo color (para el destello al recibir un golpe).
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
    S[n] = { img, frames, tags, w: frames[0].w, h: frames[0].h, blanca: null };
  }));
  for (const n of ["jugador", "zombi", "corredor"]) S[n].blanca = teñida(S[n].img, "#ffffff");
  S.jugador.roja = teñida(S.jugador.img, "#ff4a4a");
}

// Fotograma de una animación según el tiempo transcurrido.
export function fotograma(spr, tag, t, enBucle = true) {
  const r = spr.tags[tag];
  if (!r) return 0;
  let total = 0;
  for (let i = r.desde; i <= r.hasta; i++) total += spr.frames[i].dur;
  let tt = enBucle ? t % total : Math.min(t, total - 1e-6);
  for (let i = r.desde; i <= r.hasta; i++) {
    tt -= spr.frames[i].dur;
    if (tt < 0) return i;
  }
  return r.hasta;
}

export function duracion(spr, tag) {
  const r = spr.tags[tag];
  let total = 0;
  for (let i = r.desde; i <= r.hasta; i++) total += spr.frames[i].dur;
  return total;
}

// Dibuja el fotograma i con (x, y) en la esquina superior izquierda; voltear = mirar a la izquierda.
export function dibujar(g, spr, i, x, y, voltear = false, img = spr.img) {
  const f = spr.frames[i];
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

// ---------------------------------------------------------------- texto pixelado
const ORDEN = "0123456789ABCDEFGHIJKLMN#OPQRSTUVWXYZ:/!?.,+-%()* ";
const colores = new Map();
const QUITAR_TILDES = { "Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U", "Ñ": "#", "×": "*" };

function letraDe(color) {
  if (!colores.has(color)) colores.set(color, teñida(S.letra.img, color));
  return colores.get(color);
}

export function anchoTexto(t, k = 1) { return (String(t).length * 4 - 1) * k; }

// Texto con sombra. alinear: "izq" | "centro" | "der". k = tamaño (1, 2...)
export function texto(g, t, x, y, color = "#ffffff", alinear = "izq", k = 1, sombra = "#1a1423") {
  t = String(t);
  t = [...t.toUpperCase()].map((c) => QUITAR_TILDES[c] || c).join("");
  const w = anchoTexto(t, k);
  if (alinear === "centro") x -= Math.floor(w / 2);
  else if (alinear === "der") x -= w;
  x = Math.round(x); y = Math.round(y);
  const capas = sombra ? [[letraDe(sombra), k], [letraDe(color), 0]] : [[letraDe(color), 0]];
  for (const [img, d] of capas) {
    for (let i = 0; i < t.length; i++) {
      const idx = ORDEN.indexOf(t[i]);
      if (idx < 0) continue;
      g.drawImage(img, idx * 4, 0, 3, 5, x + i * 4 * k + d, y + d, 3 * k, 5 * k);
    }
  }
  return w;
}
