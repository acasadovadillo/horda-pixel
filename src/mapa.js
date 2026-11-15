// Mapa principal: una carretera abandonada que sube hacia el norte, con campamento abajo.
import { S, punto, primero, cuantos } from "./sprites.js";

export const T = 24;                    // tamaño de loseta
export const ANCHO = 31, ALTO = 70;     // en losetas
const DES = 7;                          // columnas de campo a cada lado antes de la carretera
const X = (col) => (col + DES) * T;     // x de una columna contando desde el borde de la carretera

// Columnas: 0-3 hierba, 4 acera, 5 bordillo, 6-10 asfalto (8 = línea), 11 bordillo, 12 acera, 13-16 hierba.
const COLUMNAS = [...Array(DES).fill("hierba"), "hierba", "hierba", "hierba", "hierba", "acera", "bordillo_i", "asfalto", "asfalto", "linea",
  "asfalto", "asfalto", "bordillo_d", "acera", "hierba", "hierba", "hierba", "hierba", ...Array(DES - 1).fill("hierba")];
const CENTRO = X(8.5);                 // x del centro de la carretera
const CALZADA = [X(6), X(11)];        // x de inicio y fin del asfalto

// Caja de choque de cada objeto, relativa a su punto base (centro inferior apoyado en el suelo).
const CHOQUE = {
  coche: { w: 32, h: 48, dy: 2 },
  barril: { w: 13, h: 7 },
  caja: { w: 18, h: 10 },
  sacos: { w: 68, h: 14 },
  arbol: { w: 8, h: 5, dy: 1 },
  farola: { w: 5, h: 4 },
  hoguera: { w: 14, h: 7 },
  neumaticos: { w: 18, h: 9 },
  contenedor: { w: 32, h: 16 },
  barrera: { w: 38, h: 9 },
};

function azar(semilla) {
  let s = semilla;
  return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296);
}

export function crearMapa() {
  const r = azar(2026);
  const entero = (n) => Math.floor(r() * n);
  const variante = (tipo, pesos) => {
    const n = S[tipo].frames.length;
    if (!pesos) return entero(n);
    let x = r(), i = 0;
    while (i < pesos.length - 1 && x > pesos[i]) { x -= pesos[i]; i++; }
    return Math.min(i, n - 1);
  };

  // ------------------------------------------------------------ suelo
  const su = S.suelo;
  const loseta = (tag, i) => primero(su, tag) + (i % cuantos(su, tag));
  const suelo = document.createElement("canvas");
  suelo.width = ANCHO * T; suelo.height = ALTO * T;
  const g = suelo.getContext("2d");
  for (let y = 0; y < ALTO; y++) for (let x = 0; x < ANCHO; x++) {
    let tag = COLUMNAS[x], i = 0;
    if (tag === "hierba") {
      if (r() < (x < DES || x > ANCHO - DES ? 0.11 : 0.07)) { tag = "tierra"; i = entero(8); }
      else i = r() < 0.55 ? 0 : 1 + entero(3);
    } else if (tag === "asfalto") {
      if (r() < 0.07) { tag = "grieta"; i = entero(8); }
      else i = r() < 0.5 ? 0 : 1 + entero(3);
    } else if (tag === "linea") {
      if (y % 2) { tag = "asfalto"; i = entero(4); }
    } else if (tag === "acera") i = entero(8);
    const f = su.frames[loseta(tag, i)];
    g.drawImage(su.img, f.x, f.y, T, T, x * T, y * T, T, T);
  }
  const calco = (nombre, i, x, y, alfa = 1) => {
    const sp = S[nombre], f = sp.frames[i % sp.frames.length];
    g.globalAlpha = alfa;
    g.drawImage(sp.img, f.x, f.y, f.w, f.h, Math.round(x - f.w / 2), Math.round(y - f.h / 2), f.w, f.h);
    g.globalAlpha = 1;
  };
  const enCalzada = () => CALZADA[0] + 14 + r() * (CALZADA[1] - CALZADA[0] - 28);
  const enAcera = () => X(r() < 0.5 ? 4 : 12) + 12 + (r() - 0.5) * 8;
  const enHierba = () => (r() < 0.5 ? 14 + r() * (X(4) - 28) : X(13) + 12 + r() * (X(4) - 28));
  const alto = ALTO * T;
  // detalles: 0 papeles, 1 hojas, 2 frenada, 3 aceite, 4 alcantarilla, 5 cascotes, 6 cristales, 7 hierbajos
  for (let i = 0; i < 4; i++) calco("detalles", 4, CALZADA[0] + 30 + r() * 60, 120 + i * 400 + r() * 200);
  for (let i = 0; i < 9; i++) calco("detalles", 2, enCalzada(), r() * alto, 0.8);
  for (let i = 0; i < 9; i++) calco("detalles", 3, enCalzada(), r() * alto, 0.85);
  for (let i = 0; i < 16; i++) calco("detalles", 0, r() < 0.6 ? enCalzada() : enAcera(), r() * alto);
  for (let i = 0; i < 26; i++) calco("detalles", 1, r() < 0.6 ? enHierba() : enAcera(), r() * alto);
  for (let i = 0; i < 12; i++) calco("detalles", 5, r() < 0.5 ? enCalzada() : enAcera(), r() * alto);
  for (let i = 0; i < 14; i++) calco("detalles", 7, X(r() < 0.5 ? 5 : 11) + 12 + (r() - 0.5) * 14, r() * alto);
  for (let i = 0; i < 16; i++) calco("manchas", entero(8), enCalzada(), r() * (alto - 240), 0.7);

  // ------------------------------------------------------------ objetos
  const objetos = [];
  const poner = (tipo, x, y, v) => {
    const sp = S[tipo];
    const f = v === undefined ? variante(tipo) : Math.min(v, sp.frames.length - 1);
    const o = { tipo, x: Math.round(x), y: Math.round(y), f, t0: r() * 3 };
    o.base = punto(sp, "base", f, { x: Math.floor(sp.w / 2), y: sp.h - 2 });
    const c = CHOQUE[tipo];
    if (c) o.caja = { x: o.x - c.w / 2, y: o.y - c.h - (c.dy || 0), w: c.w, h: c.h };
    if (tipo === "farola" && f === 0) {
      const l = punto(sp, "luz", f, { x: 8, y: 6 });
      o.luz = { x: o.x - o.base.x + l.x, y: o.y - o.base.y + l.y + 40, r: 78 };
    }
    if (tipo === "hoguera") o.luz = { x: o.x, y: o.y - 12, r: 66, fuego: true };
    objetos.push(o);
    return o;
  };

  const campamento = (ALTO - 7) * T;   // fila de sacos, abajo del todo

  // Campamento dentro de la base (el muro y la tienda los pone base.js): dos hogueras y cosas tiradas
  poner("hoguera", X(5) + 4, campamento + 52);
  poner("hoguera", X(12) - 4, campamento + 52);
  poner("barril", CENTRO + 50, campamento + 82, 0);
  poner("neumaticos", CENTRO + 70, campamento + 88);

  // Árboles y arbustos en las cunetas
  for (let y = 2; y < ALTO - 8; y += 3 + entero(3)) {
    // Cuneta junto a la carretera
    poner("arbol", X(0) + 18 + r() * 44, y * T + r() * 14, variante("arbol", [0.55, 0.25, 0.2]));
    if (r() < 0.85) poner("arbol", X(13) + 30 + r() * 44, y * T + 30 + r() * 18, variante("arbol", [0.55, 0.25, 0.2]));
    if (r() < 0.7) poner("arbusto", X(0) + 12 + r() * 70, y * T + 44, variante("arbusto", [0.6, 0.4]));
    if (r() < 0.7) poner("arbusto", X(13) + 14 + r() * 70, y * T + 12, variante("arbusto", [0.6, 0.4]));
    // Campo abierto a los lados, con árboles sueltos
    for (const [x0, x1] of [[16, X(0) - 10], [X(17) + 10, ANCHO * T - 16]]) {
      if (r() < 0.55) poner("arbol", x0 + r() * (x1 - x0), y * T + r() * 40, variante("arbol", [0.45, 0.3, 0.25]));
      if (r() < 0.45) poner("arbusto", x0 + r() * (x1 - x0), y * T + 20 + r() * 40, variante("arbusto", [0.5, 0.5]));
    }
  }
  // Farolas en las aceras (unas encendidas y otras rotas)
  for (let y = 4; y < ALTO - 9; y += 7) {
    poner("farola", X(4) + 13, y * T, r() < 0.6 ? 0 : 1);
    poner("farola", X(12) + 11, y * T + 3 * T, r() < 0.6 ? 0 : 1);
  }
  // Coches abandonados y cosas tiradas en la carretera (no en el campamento)
  for (let y = 4; y < ALTO - 15; y += 7 + entero(5)) {
    const izq = r() < 0.5;
    const cx = (izq ? X(6) + 26 : X(9) + 22) + r() * 12;
    const cy = y * T + 50;
    poner("coche", cx, cy);
    calco("detalles", 6, cx + (izq ? 22 : -22), cy - 30 + r() * 20);
    calco("detalles", 3, cx, cy - 20, 0.8);
    const lado = izq ? 26 : -26;
    if (r() < 0.7) poner(r() < 0.5 ? "barril" : "caja", cx + lado, cy - 10 - r() * 30);
    if (r() < 0.5) poner("cono", cx + lado * (1 + r() * 0.6), cy + 6 + r() * 14);
    if (r() < 0.35) poner("neumaticos", cx - lado * 0.2, cy + 16);
  }
  for (let i = 0; i < 9; i++) {
    const y = 3 + entero(ALTO - 18);
    poner(r() < 0.5 ? "barril" : "caja", enAcera(), y * T);
  }
  for (let i = 0; i < 4; i++) poner("contenedor", (r() < 0.5 ? X(4) + 2 : X(13) - 2), (8 + i * 13 + entero(5)) * T);
  for (let i = 0; i < 3; i++) poner("barrera", enCalzada(), (10 + i * 16 + entero(6)) * T);
  for (let i = 0; i < 5; i++) poner("cono", enCalzada(), (6 + entero(ALTO - 24)) * T);

  // Quita lo que caiga sobre el punto de salida del jugador o encima de otra cosa
  const salida = { x: CENTRO, y: campamento + 44 };
  for (let i = objetos.length - 1; i >= 0; i--) {
    const o = objetos[i];
    if (o.tipo !== "sacos" && o.tipo !== "hoguera" && Math.hypot(o.x - salida.x, o.y - salida.y) < 30) objetos.splice(i, 1);
  }
  const solapan = (a, b) => a.x < b.x + b.w + 2 && b.x < a.x + a.w + 2 && a.y < b.y + b.h + 2 && b.y < a.y + a.h + 2;
  for (let i = objetos.length - 1; i >= 0; i--) {
    const o = objetos[i];
    if (!o.caja) continue;
    if (objetos.some((p, k) => k < i && p.caja && solapan(o.caja, p.caja))) objetos.splice(i, 1);
  }

  const cajas = objetos.filter((o) => o.caja).map((o) => o.caja);
  const luces = objetos.filter((o) => o.luz).map((o) => o.luz);

  return { ancho: ANCHO * T, alto, objetos, cajas, luces, suelo, sueloCtx: g, salida, campamento, centro: CENTRO };
}

// Pinta una mancha de sangre en el suelo para siempre.
export function manchar(g, x, y, i, alfa = 1) {
  const m = S.manchas, f = m.frames[i % m.frames.length];
  g.globalAlpha = alfa;
  g.drawImage(m.img, f.x, f.y, f.w, f.h, Math.round(x - f.w / 2), Math.round(y - f.h / 2), f.w, f.h);
  g.globalAlpha = 1;
}

// Empuja un círculo (x, y, radio) fuera de una caja { x, y, w, h }. Devuelve true si chocaba.
export function fueraDeCaja(c, e, radio) {
  const nx = Math.max(c.x, Math.min(e.x, c.x + c.w));
  const ny = Math.max(c.y, Math.min(e.y, c.y + c.h));
  const dx = e.x - nx, dy = e.y - ny, d2 = dx * dx + dy * dy;
  if (d2 >= radio * radio) return false;
  if (d2 > 1e-6) {
    const d = Math.sqrt(d2);
    e.x = nx + (dx / d) * radio; e.y = ny + (dy / d) * radio;
  } else {
    const izq = e.x - c.x, der = c.x + c.w - e.x, arr = e.y - c.y, aba = c.y + c.h - e.y;
    const m = Math.min(izq, der, arr, aba);
    if (m === izq) e.x = c.x - radio; else if (m === der) e.x = c.x + c.w + radio;
    else if (m === arr) e.y = c.y - radio; else e.y = c.y + c.h + radio;
  }
  return true;
}

// Empuja un círculo (x, y, radio) fuera de las cajas del mapa y de los bordes.
export function resolverChoques(mapa, e, radio) {
  for (const c of mapa.cajas) {
    const nx = Math.max(c.x, Math.min(e.x, c.x + c.w));
    const ny = Math.max(c.y, Math.min(e.y, c.y + c.h));
    let dx = e.x - nx, dy = e.y - ny;
    const d2 = dx * dx + dy * dy;
    if (d2 >= radio * radio) continue;
    if (d2 > 1e-6) {
      const d = Math.sqrt(d2);
      e.x = nx + (dx / d) * radio; e.y = ny + (dy / d) * radio;
    } else {                               // el centro quedó dentro: sale por el lado más cercano
      const izq = e.x - c.x, der = c.x + c.w - e.x, arr = e.y - c.y, aba = c.y + c.h - e.y;
      const m = Math.min(izq, der, arr, aba);
      if (m === izq) e.x = c.x - radio; else if (m === der) e.x = c.x + c.w + radio;
      else if (m === arr) e.y = c.y - radio; else e.y = c.y + c.h + radio;
    }
  }
  e.x = Math.max(radio, Math.min(mapa.ancho - radio, e.x));
  e.y = Math.max(radio + 6, Math.min(mapa.alto - radio, e.y));
}

export function chocaCon(mapa, x, y, radio) {
  for (const c of mapa.cajas) {
    const nx = Math.max(c.x, Math.min(x, c.x + c.w));
    const ny = Math.max(c.y, Math.min(y, c.y + c.h));
    if ((x - nx) ** 2 + (y - ny) ** 2 < radio * radio) return true;
  }
  return false;
}
