// La base fortificada, abajo del todo: un muro de lado a lado del mapa con un portón en la carretera,
// alambre de espino delante (si se compra) y la tienda dentro.
// Los zombis no pueden cruzar el muro: lo golpean hasta romper un tramo y entran por el hueco.
// El jugador sí pasa por el portón (se abre a su paso); los zombis no.
import { S, punto, dibujar } from "./sprites.js";
import { BASE } from "./config.js";
import { fueraDeCaja } from "./mapa.js";

const GRUESO = 9;          // fondo del muro en el suelo (px)

export function crearBase(mapa) {
  const y = mapa.campamento, tramos = [];
  for (let k = -8; k <= 8; k++) {
    tramos.push({ x: mapa.centro + k * BASE.tramo, y, porton: k === 0, vida: BASE.vida[0], vidaMax: BASE.vida[0], barra: 0 });
  }
  const tienda = { x: mapa.centro - 110, y: y + 112 };
  // La tienda es un mueble fijo: choca como las demás cosas del mapa
  mapa.cajas.push({ x: tienda.x - 28, y: tienda.y - 16, w: 56, h: 16 });
  mapa.luces.push({ x: tienda.x + 14, y: tienda.y - 20, r: 70 });
  return { y, tramos, nivel: 0, alambre: false, tienda, abierto: 0 };
}

export const cajaTramo = (t) => ({ x: t.x - BASE.tramo / 2, y: t.y - GRUESO, w: BASE.tramo, h: GRUESO });

// Saca a alguien de los tramos en pie. El jugador atraviesa el portón.
export function chocarMuro(base, e, radio, esJugador) {
  let tocado = null;
  for (const t of base.tramos) {
    if (t.vida <= 0 || (esJugador && t.porton)) continue;
    if (Math.abs(e.x - t.x) > BASE.tramo / 2 + radio + 1 || Math.abs(e.y - t.y) > GRUESO + radio + 1) continue;
    if (fueraDeCaja(cajaTramo(t), e, radio)) tocado = t;
  }
  return tocado;
}

// Tramo en pie que toca un zombi (para golpearlo), o null.
export function tramoTocado(base, z, radio) {
  for (const t of base.tramos) {
    if (t.vida <= 0) continue;
    const c = cajaTramo(t);
    const nx = Math.max(c.x, Math.min(z.x, c.x + c.w)), ny = Math.max(c.y, Math.min(z.y, c.y + c.h));
    if ((z.x - nx) ** 2 + (z.y - ny) ** 2 <= (radio + 3) ** 2) return t;
  }
  return null;
}

// Hueco más cercano (tramo roto) a la x dada, o null.
export function huecoCercano(base, x, maximo = 220) {
  let mejor = null, md = maximo;
  for (const t of base.tramos) if (t.vida <= 0 && Math.abs(t.x - x) < md) { md = Math.abs(t.x - x); mejor = t; }
  return mejor;
}

export const dentro = (base, y) => y > base.y;

// Daño a la vida que falta en todo el muro (para el precio de reparar).
export function faltaMuro(base) { return base.tramos.reduce((s, t) => s + (t.vidaMax - Math.max(0, t.vida)), 0); }

export function repararMuro(base) { for (const t of base.tramos) t.vida = t.vidaMax; }

export function reforzarMuro(base) {
  base.nivel = Math.min(BASE.vida.length - 1, base.nivel + 1);
  for (const t of base.tramos) { t.vidaMax = BASE.vida[base.nivel]; t.vida = t.vidaMax; }
}

// ------------------------------------------------------------------ dibujo
// Fotograma del tramo: material (madera, chapa, hormigón) × estado (entero, dañado, roto; el portón: cerrado, abierto, roto).
function cuadro(base, t) {
  if (t.vida <= 0) return base.nivel * 3 + 2;
  if (t.porton) return base.nivel * 3 + (base.abierto > 0 ? 1 : 0);
  return base.nivel * 3 + (t.vida < t.vidaMax * 0.5 ? 1 : 0);
}

const COLORES = [["#5c3d22", "#7b5631"], ["#4b535e", "#6e7885"], ["#7b7b7c", "#949493"]];

export function dibujarTramo(g, base, t) {
  const spr = S[t.porton ? "porton" : "muro"];
  const f = cuadro(base, t);
  if (spr) {
    const b = punto(spr, "base", f, { x: 24, y: 37 });
    dibujar(g, spr, f, t.x - b.x, t.y - b.y);
    return;
  }
  // Sin arte todavía: bloques de color
  const [osc, cla] = COLORES[base.nivel], x = Math.round(t.x - 24), y = Math.round(t.y);
  if (t.vida <= 0) { g.fillStyle = osc; g.fillRect(x + 4, y - 4, 40, 4); return; }
  if (t.porton && base.abierto > 0) { g.fillStyle = osc; g.fillRect(x, y - 22, 8, 22); g.fillRect(x + 40, y - 22, 8, 22); return; }
  g.fillStyle = osc; g.fillRect(x, y - 22, 48, 22);
  g.fillStyle = cla; g.fillRect(x, y - 30, 48, 8);
  if (t.vida < t.vidaMax * 0.5) { g.fillStyle = "#1a1920"; g.fillRect(x + 14, y - 18, 6, 10); g.fillRect(x + 30, y - 12, 5, 7); }
}

// El alambre va en el suelo, delante del muro (por fuera).
export function dibujarAlambre(g, base) {
  if (!base.alambre) return;
  const spr = S.alambre;
  for (const [i, t] of base.tramos.entries()) {
    if (spr) {
      const b = punto(spr, "base", i % 2, { x: 24, y: 14 });
      dibujar(g, spr, i % 2, t.x - b.x, t.y - 40 - b.y);   // justo por fuera, delante de la cara norte
    } else {
      g.fillStyle = "#6e7885";
      for (let k = 0; k < 48; k += 6) g.fillRect(Math.round(t.x - 24 + k), Math.round(t.y - 44 + (k % 12 ? 1 : 0)), 4, 1);
    }
  }
}

export function dibujarTienda(g, base, t) {
  const spr = S.tienda, b0 = base.tienda;
  if (spr) {
    const f = Math.floor(t * 6) % 2, b = punto(spr, "base", f, { x: 32, y: 45 });
    dibujar(g, spr, f, b0.x - b.x, b0.y - b.y);
    return;
  }
  g.fillStyle = "#3f2917"; g.fillRect(b0.x - 28, b0.y - 20, 56, 20);
  g.fillStyle = "#5c3d22"; g.fillRect(b0.x - 30, b0.y - 24, 60, 5);
  g.fillStyle = "#4a3f2a"; g.fillRect(b0.x - 30, b0.y - 44, 60, 6);
}
