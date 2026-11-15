// Mapa principal: una carretera abandonada que sube hacia el norte, con campamento abajo.
import { S } from "./sprites.js";

export const T = 16;                    // tamaño de loseta
export const ANCHO = 16, ALTO = 70;     // en losetas

// Fotogramas de suelo.aseprite
const HIERBA = [0, 1, 2, 3], ASFALTO = [4, 5], GRIETA = 6, LINEA = 7, ACERA = 8,
  BORDILLO_I = 9, BORDILLO_D = 10, TIERRA = 11;

// Caja de choque de cada objeto, relativa a su base (centro inferior del sprite).
const CHOQUE = {
  coche: { w: 20, h: 30, dy: 2 },
  barril: { w: 10, h: 6 },
  caja: { w: 12, h: 7 },
  sacos: { w: 46, h: 10 },
  arbol: { w: 6, h: 4, dy: 1 },
  farola: { w: 4, h: 3, dy: 1 },
  hoguera: { w: 10, h: 5 },
};

function azar(semilla) {
  let s = semilla;
  return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296);
}

export function crearMapa() {
  const r = azar(2026);
  const losetas = [];
  for (let y = 0; y < ALTO; y++) {
    const fila = [];
    for (let x = 0; x < ANCHO; x++) {
      let t;
      if (x <= 3 || x >= 13) t = HIERBA[Math.floor(r() * r() * 4)];
      else if (x === 4 || x === 12) t = ACERA;
      else if (x === 5) t = BORDILLO_I;
      else if (x === 11) t = BORDILLO_D;
      else if (x === 8 && y % 2 === 0) t = LINEA;
      else t = r() < 0.08 ? GRIETA : ASFALTO[Math.floor(r() * 2)];
      fila.push(t);
    }
    losetas.push(fila);
  }
  // Calvas de tierra en la hierba
  for (let i = 0; i < 18; i++) {
    const x = r() < 0.5 ? Math.floor(r() * 3) : 13 + Math.floor(r() * 3);
    const y = Math.floor(r() * ALTO);
    losetas[y][x] = TIERRA;
    if (r() < 0.5 && y + 1 < ALTO) losetas[y + 1][x] = TIERRA;
  }

  const objetos = [];
  const poner = (tipo, x, y) => {
    const o = { tipo, x: Math.round(x), y: Math.round(y), t0: r() * 3 };
    const c = CHOQUE[tipo];
    if (c) o.caja = { x: o.x - c.w / 2, y: o.y - c.h - (c.dy || 0), w: c.w, h: c.h };
    objetos.push(o);
    return o;
  };

  const campamento = (ALTO - 7) * T;   // fila de sacos, abajo del todo

  // Árboles y arbustos en las cunetas
  for (let y = 2; y < ALTO - 2; y += 3 + Math.floor(r() * 3)) {
    poner("arbol", 14 + r() * 26, y * T + r() * 10);
    if (r() < 0.8) poner("arbol", 214 + r() * 30, y * T + 20 + r() * 12);
    if (r() < 0.6) poner("arbusto", 8 + r() * 50, y * T + 30);
    if (r() < 0.6) poner("arbusto", 210 + r() * 40, y * T + 8);
  }
  // Farolas en las aceras
  for (let y = 4; y < ALTO - 8; y += 7) {
    poner("farola", 4 * T + 8, y * T);
    poner("farola", 12 * T + 8, y * T + 3 * T);
  }
  // Coches abandonados y cosas tiradas en la carretera (no en el campamento)
  for (let y = 4; y < ALTO - 14; y += 7 + Math.floor(r() * 5)) {
    const carril = r() < 0.5 ? 6.5 : 9.6;
    const cx = carril * T + r() * 10;
    poner("coche", cx, y * T + 34);
    if (r() < 0.7) poner(r() < 0.5 ? "barril" : "caja", cx + (r() < 0.5 ? -20 : 20), y * T + 30 + r() * 20);
  }
  for (let i = 0; i < 10; i++) {
    const y = 3 + Math.floor(r() * (ALTO - 16));
    poner(r() < 0.5 ? "barril" : "caja", (r() < 0.5 ? 4 : 12) * T + 8 + (r() - 0.5) * 6, y * T);
  }
  // Campamento: sacos terreros con un hueco en el centro y dos hogueras
  poner("sacos", 5 * T + 24, campamento);
  poner("sacos", 11 * T - 8, campamento);
  poner("hoguera", 3 * T, campamento + 34);
  poner("hoguera", 13 * T, campamento + 34);
  poner("caja", 6 * T, campamento + 50);
  poner("barril", 10 * T + 8, campamento + 54);

  // Quita lo que caiga sobre el punto de salida del jugador
  const salida = { x: 8 * T, y: campamento + 40 };
  for (let i = objetos.length - 1; i >= 0; i--) {
    const o = objetos[i];
    if (o.tipo !== "sacos" && o.tipo !== "hoguera" && Math.hypot(o.x - salida.x, o.y - salida.y) < 22) objetos.splice(i, 1);
  }

  const cajas = objetos.filter((o) => o.caja).map((o) => o.caja);

  // El suelo se pinta una sola vez en un lienzo grande; la sangre se queda pintada encima.
  const suelo = document.createElement("canvas");
  suelo.width = ANCHO * T; suelo.height = ALTO * T;
  const g = suelo.getContext("2d");
  const ss = S.suelo;
  for (let y = 0; y < ALTO; y++) for (let x = 0; x < ANCHO; x++) {
    const f = ss.frames[losetas[y][x]];
    g.drawImage(ss.img, f.x, f.y, T, T, x * T, y * T, T, T);
  }
  // Manchas viejas para que la carretera no esté limpia
  for (let i = 0; i < 14; i++) manchar(g, 5 * T + r() * 6 * T, r() * (ALTO - 10) * T, Math.floor(r() * 3), 0.6);

  return {
    ancho: ANCHO * T, alto: ALTO * T, objetos, cajas, suelo, sueloCtx: g, salida,
    campamento,
  };
}

export function manchar(g, x, y, i, alfa = 1) {
  const m = S.manchas, f = m.frames[i % m.frames.length];
  g.globalAlpha = alfa;
  g.drawImage(m.img, f.x, f.y, f.w, f.h, Math.round(x - 8), Math.round(y - 8), f.w, f.h);
  g.globalAlpha = 1;
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
  e.y = Math.max(radio + 4, Math.min(mapa.alto - radio, e.y));
}

export function chocaCon(mapa, x, y, radio) {
  for (const c of mapa.cajas) {
    const nx = Math.max(c.x, Math.min(x, c.x + c.w));
    const ny = Math.max(c.y, Math.min(y, c.y + c.h));
    if ((x - nx) ** 2 + (y - ny) ** 2 < radio * radio) return true;
  }
  return false;
}
