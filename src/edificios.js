// Edificios abandonados a los lados de la carretera: casas de ladrillo y cabañas de madera con cajas dentro para
// saquear. Cada tramo de pared es un objeto destruible más (ver destruir.js): las balas, las explosiones, el
// cuerpo a cuerpo y los zombis lo rompen y deja un hueco. La puerta se abre a tu paso; los zombis la tienen que romper.
// Vista 3/4: los tramos tienen 8 px de grueso y 24 de alto; se ve su cara de arriba y la cara sur.
import { S, punto, dibujar } from "./sprites.js";
import { fueraDeCaja } from "./mapa.js";
import { danarObjeto } from "./destruir.js";

const T = 24, ALTO = 24, GRUESO = 8;
const ANCHO_CASA = 5 * T, FONDO_CASA = GRUESO + 3 * T + GRUESO;      // 120 x 88
// Dónde va cada edificio: lado del mapa, fila (en losetas) y material
const SITIOS = [
  { lado: "izq", fila: 9, mat: "ladrillo" },
  { lado: "der", fila: 21, mat: "madera" },
  { lado: "izq", fila: 34, mat: "madera" },
  { lado: "der", fila: 46, mat: "ladrillo" },
];
const CHOQUE = { caja: { w: 18, h: 10 }, barril: { w: 13, h: 7 } };

export function crearEdificios(mapa) {
  mapa.puertas = [];
  const r = azar(77);
  for (const s of SITIOS) {
    const x0 = s.lado === "izq" ? T : mapa.ancho - T - ANCHO_CASA, y0 = s.fila * T;
    // Fuera lo que hubiera en el solar (árboles, arbustos...)
    const solar = { x: x0 - 12, y: y0 - 34, w: ANCHO_CASA + 24, h: FONDO_CASA + 50 };
    const dentroSolar = (o) => o.x > solar.x && o.x < solar.x + solar.w && o.y > solar.y && o.y < solar.y + solar.h;
    const fuera = mapa.objetos.filter(dentroSolar);
    mapa.objetos = mapa.objetos.filter((o) => !dentroSolar(o));
    mapa.cajas = mapa.cajas.filter((c) => !fuera.some((o) => o.caja === c));
    mapa.luces = mapa.luces.filter((l) => !fuera.some((o) => o.luz === l));
    // Suelo de tablas
    const su = S.suelo_casa;
    if (su) for (let i = 0; i < 5; i++) for (let j = 0; j < 4; j++) {
      const f = su.frames[r() < 0.15 ? 1 : 0];
      mapa.sueloCtx.drawImage(su.img, f.x, f.y, f.w, f.h, x0 + i * T, y0 + j * T - 4, f.w, f.h);
    }
    // Paredes: norte, sur (con la puerta en medio), oeste y este
    for (let i = 0; i < 5; i++) pared(mapa, s.mat, "h", x0 + i * T, y0);
    for (let i = 0; i < 5; i++) pared(mapa, s.mat, "h", x0 + i * T, y0 + FONDO_CASA - GRUESO, i === 2);
    for (let k = 0; k < 3; k++) {
      pared(mapa, s.mat, "v", x0, y0 + GRUESO + k * T);
      pared(mapa, s.mat, "v", x0 + ANCHO_CASA - GRUESO, y0 + GRUESO + k * T);
    }
    // Cajas y un barril para saquear
    poner(mapa, "caja", x0 + 26, y0 + 44, r);
    poner(mapa, "caja", x0 + 94, y0 + 72, r);
    if (r() < 0.6) poner(mapa, "caja", x0 + 30, y0 + 72, r);
    poner(mapa, "barril", x0 + 96, y0 + 36, r);
  }
}

function azar(semilla) {
  let s = semilla;
  return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296);
}

function pared(mapa, mat, dir, x, y, esPuerta = false) {
  const caja = dir === "h" ? { x, y, w: T, h: GRUESO } : { x, y, w: GRUESO, h: T };
  const o = {
    tipo: esPuerta ? "puerta" : "pared_" + mat, pared: dir, mat, caja, abierta: 0,
    x: caja.x + caja.w / 2, y: caja.y + caja.h, base: { x: 0, y: 0 }, f: 0,
  };
  mapa.objetos.push(o);
  if (esPuerta) mapa.puertas.push(o);     // la puerta no está en las cajas: el jugador la cruza
  else mapa.cajas.push(caja);
}

function poner(mapa, tipo, x, y, r) {
  const sp = S[tipo], f = Math.floor(r() * sp.frames.length), c = CHOQUE[tipo];
  const o = { tipo, x: Math.round(x), y: Math.round(y), f, t0: 0, base: punto(sp, "base", f, { x: Math.floor(sp.w / 2), y: sp.h - 2 }) };
  o.caja = { x: o.x - c.w / 2, y: o.y - c.h, w: c.w, h: c.h };
  mapa.objetos.push(o);
  mapa.cajas.push(o.caja);
}

// ------------------------------------------------------------------ cada fotograma
// La puerta se abre mientras el jugador (o un superviviente) está cerca.
export function moverEdificios(J, dt) {
  const j = J.jugador;
  for (const p of J.mapa.puertas) {
    if (p.roto) continue;
    const cerca = (e) => Math.abs(e.x - p.x) < 20 && Math.abs(e.y - (p.caja.y + 4)) < 22;
    p.abierta = (!j.muerto && cerca(j)) || J.supervivientes.some((s) => !s.muerto && s.estado !== "atrapado" && cerca(s)) ? 0.4 : Math.max(0, p.abierta - dt);
  }
}

// Los zombis chocan con las puertas cerradas (el jugador y los supervivientes, no).
export function chocarPuertas(J, e, radio) {
  for (const p of J.mapa.puertas) if (!p.roto && p.abierta <= 0) fueraDeCaja(p.caja, e, radio);
}

// Tramo de pared o puerta que tiene pegado un zombi (para que lo golpee si se atasca).
export function paredCerca(J, z, radio) {
  for (const o of J.mapa.objetos) {
    if (!o.pared || o.roto) continue;
    const c = o.caja, nx = Math.max(c.x, Math.min(z.x, c.x + c.w)), ny = Math.max(c.y, Math.min(z.y, c.y + c.h));
    if ((z.x - nx) ** 2 + (z.y - ny) ** 2 <= (radio + 3) ** 2) return o;
  }
  return null;
}

export function golpearPared(J, o, dano) { danarObjeto(J, o, dano, false); }

// ------------------------------------------------------------------ dibujo
export function dibujarPared(J, g, o) {
  const v = o.pared === "v", s = S[v ? "pared_v" : "pared"];
  const x = o.caja.x, y = o.caja.y - ALTO;
  const danada = o.vida < o.vidaMax * 0.5;
  let f;
  if (o.tipo === "puerta") f = o.abierta > 0 ? 5 : danada ? 6 : 4;
  else f = (o.mat === "madera" ? 2 : 0) + (danada ? 1 : 0);
  if (!s) { g.fillStyle = o.mat === "madera" ? "#5c3d22" : "#7d4432"; g.fillRect(x, y, o.caja.w, o.caja.h + ALTO); return; }
  // Si el jugador está justo detrás de una pared horizontal, se ve a través
  const j = J.jugador;
  const tapa = !v && j.x > o.caja.x - 8 && j.x < o.caja.x + T + 8 && j.y < o.caja.y && j.y > o.caja.y - 34;
  const tiembla = o.golpe > 0 ? Math.round(Math.random() * 2 - 1) : 0;
  if (tapa) g.globalAlpha = 0.45;
  dibujar(g, s, f, x + tiembla, y, false, o.golpe > 0 && s.blanca ? s.blanca : s.img);
  g.globalAlpha = 1;
  if (o.arde > 0) {
    J.dibujarLlama(g, o.x - (v ? 0 : 5), o.y - (v ? 10 : 14), J.t * 1.2 + o.x * 0.01);
    if (!v) J.dibujarLlama(g, o.x + 6, o.y - 10, J.t * 1.2 + 0.4 + o.x * 0.01);
  }
}
