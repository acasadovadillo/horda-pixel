// Comercios de la base: cada vendedor tiene su caseta y vende solo lo suyo (las pestañas de tienda.js).
// Van en una fila pegada al muro, a los dos lados de la carretera, para que al volver a por balas en
// mitad de una ronda estén a pocos pasos del portón. Al acercarte al mostrador aparece su botón.
import { S, punto, dibujar, texto } from "./sprites.js";
import { dentro } from "./base.js";
import { t } from "./idioma.js";

// x relativa al centro del mapa; y relativa a la línea del muro (el punto base de la caseta).
export const COMERCIOS = [
  { id: "constructor", dx: -250, pestanas: ["base"] },
  { id: "armero", dx: -190, pestanas: ["armas", "mejoras"] },
  { id: "intendente", dx: -130, pestanas: ["municion", "equipo"] },
  { id: "medico", dx: 130, pestanas: ["curacion"] },
  { id: "mecanico", dx: 190, pestanas: ["defensas"] },
];
// Orden de los dibujos en la hoja «comercios» (dos fotogramas cada uno)
const HOJA = ["armero", "intendente", "medico", "mecanico", "constructor"];
const DY = 66;
const CAJA = { w: 50, h: 12 };            // el mostrador
const CERCA = { x: 30, delante: 30 };      // dónde tienes que estar para comprar

export function crearComercios(base, mapa) {
  base.comercios = COMERCIOS.map((c, i) => ({ ...c, i, x: mapa.centro + c.dx, y: base.y + DY }));
  for (const c of base.comercios) {
    mapa.cajas.push({ x: c.x - CAJA.w / 2, y: c.y - CAJA.h, w: CAJA.w, h: CAJA.h });
    mapa.luces.push({ x: c.x, y: c.y - 26, r: 54 });
  }
}

// Comercio delante del cual está el jugador (o null).
export function comercioCerca(J) {
  const j = J.jugador, b = J.base;
  if (j.muerto || !dentro(b, j.y)) return null;
  let mejor = null, md = Infinity;
  for (const c of b.comercios) {
    const dx = Math.abs(j.x - c.x), dy = j.y - c.y;
    if (dx < CERCA.x && dy > -4 && dy < CERCA.delante && dx < md) { md = dx; mejor = c; }
  }
  return mejor;
}

export function cosasComercios(J, g, cosas) {
  for (const c of J.base.comercios) {
    if (J.enPantalla(c.x, c.y, 60)) cosas.push({ y: c.y, f: () => dibujarComercio(g, c, J.t) });
  }
}

function dibujarComercio(g, c, tiempo) {
  const s = S.comercios;
  if (!s) {
    g.fillStyle = "#3f2917"; g.fillRect(c.x - 25, c.y - 16, 50, 16);
    g.fillStyle = "#5c3d22"; g.fillRect(c.x - 27, c.y - 46, 54, 8);
    return;
  }
  // Cada uno parpadea a su ritmo
  const ciclo = (tiempo + c.i * 0.83) % 2.6;
  const f = HOJA.indexOf(c.id) * 2 + (ciclo > 2.45 ? 1 : 0);
  const b = punto(s, "base", f, { x: 28, y: 49 });
  dibujar(g, s, f, Math.round(c.x - b.x), Math.round(c.y - b.y));
}

// Nombre de cada comercio encima del toldo, mientras estás dentro de la base (el de delante, en amarillo).
export function marcasComercios(J, g) {
  const j = J.jugador;
  if (J.estado !== "jugando" || j.muerto || !dentro(J.base, j.y)) return;
  const cerca = comercioCerca(J);
  for (const c of J.base.comercios) {
    if (!J.enPantalla(c.x, c.y, 40)) continue;
    texto(g, t(c.id), c.x, c.y - 56, c === cerca ? "#f2c84a" : "#d1cec0", "centro");
  }
}
