// Mascota que te acompaña (se elige en PERSONAJE y se desbloquea con logros, ver perfil.js).
// El perro muerde a los zombis que se te acercan (y los frena); el gato recoge monedas y virotes del suelo;
// el cuervo vuela, pica a los zombis (los para un momento) y también trae monedas. No mueren.
import { S, punto, fotograma } from "./sprites.js";
import { resolverChoques } from "./mapa.js";
import { chocarMuro } from "./base.js";
import { MUNICION } from "./config.js";
import { sonar } from "./audio.js";

const rnd = (a, b) => a + Math.random() * (b - a);
const DATOS = {
  perro: { vel: 125, alcance: 95, dano: 8, cada: 0.6, frena: 0.6 },
  gato: { vel: 118, recoge: 150 },
  cuervo: { vel: 135, alcance: 110, dano: 4, cada: 0.9, recoge: 120, altura: 24 },
};

export function crearMascota(J, id) {
  const j = J.jugador;
  J.mascota = !DATOS[id] ? null : { id, x: j.x - 18, y: j.y + 6, z: id === "cuervo" ? DATOS.cuervo.altura : 0, anim: 0, voltear: false, espera: 0, ataca: 0, andando: false };
}

function zombiCerca(J, cx, cy, r) {
  let mejor = null, md = r * r;
  for (const z of J.zombis) {
    if (z.muerto || z.aparece > 0.2) continue;
    const d = (z.x - cx) ** 2 + (z.y - cy) ** 2;
    if (d < md) { md = d; mejor = z; }
  }
  return mejor;
}
function botinCerca(J, cx, cy, r) {
  const j = J.jugador;
  let mejor = null, md = r * r;
  for (const o of J.botin) {
    if (o.recogido || o.iman || o.z > 0 || o.t < 0.4) continue;
    if (o.tipo !== "moneda" && !(o.tipo === "flecha" && j.armas.ballesta && j.reserva.ballesta < MUNICION.ballesta.maximo)) continue;
    const d = (o.x - cx) ** 2 + (o.y - cy) ** 2;
    if (d < md) { md = d; mejor = o; }
  }
  return mejor;
}

function recoger(J, o) {
  const j = J.jugador;
  if (o.tipo === "moneda") { J.monedas++; J.stats.monedas++; sonar("moneda", 0.03); }
  else if (o.tipo === "flecha") { j.reserva.ballesta++; sonar("recargado", 0.05); }
  o.recogido = true;
}

export function moverMascota(J, dt) {
  const m = J.mascota, j = J.jugador;
  if (!m) return;
  const D = DATOS[m.id];
  m.espera = Math.max(0, m.espera - dt); m.ataca = Math.max(0, m.ataca - dt);
  // Muy lejos (por ejemplo, al empezar): aparece a tu lado
  if ((m.x - j.x) ** 2 + (m.y - j.y) ** 2 > 320 * 320) { m.x = j.x - 18; m.y = j.y + 6; }
  let tx = j.x - 18 * Math.sign(Math.cos(j.angulo) || 1), ty = j.y + 6, vel = D.vel, quieto = 24;
  let presa = null, cosa = null;
  if (!j.muerto) {
    if (m.id === "perro") presa = zombiCerca(J, j.x, j.y, D.alcance);
    if (m.id === "cuervo") presa = zombiCerca(J, j.x, j.y, D.alcance);
    if (m.id === "gato" || (m.id === "cuervo" && !presa)) cosa = botinCerca(J, j.x, j.y, D.recoge);
  }
  if (presa) { tx = presa.x - Math.sign(presa.x - m.x || 1) * 8; ty = presa.y + 1; quieto = 3; }
  else if (cosa) { tx = cosa.x; ty = cosa.y; quieto = 0; }
  const dx = tx - m.x, dy = ty - m.y, d = Math.hypot(dx, dy);
  m.andando = d > quieto + 1;
  if (m.andando) {
    const v = Math.min(d, vel * dt * (d > 80 ? 1.25 : 1));
    m.x += (dx / d) * v; m.y += (dy / d) * v;
    if (m.id !== "cuervo") { resolverChoques(J.mapa, m, 4); chocarMuro(J.base, m, 4, true); }
    if (Math.abs(dx) > 0.5) m.voltear = dx < 0;
  }
  m.anim += dt * (m.andando ? 1 : 0.5);
  // Morder o picar
  if (presa && Math.hypot(presa.x - m.x, presa.y - m.y) < 14 && m.espera <= 0) {
    m.espera = D.cada; m.ataca = 0.25; m.voltear = presa.x < m.x;
    presa.vida -= D.dano; presa.barra = 2; presa.golpe = 0.06;
    J.stats.dano += D.dano;
    if (m.id === "perro") presa.mordido = D.frena;
    else { presa.ataque = 0; presa.espera = Math.max(presa.espera, 0.5); }
    for (let i = 0; i < 3; i++) J.gota(presa.x, presa.y, rnd(8, 20), rnd(-30, 30), rnd(-10, 10), rnd(10, 40));
    sonar(m.id === "perro" ? "mordisco" : "picotazo", 0.1);
    if (presa.vida <= 0) J.matarZombi(presa, { x: presa.x - m.x, y: presa.y - m.y }, 0.6);
  }
  if (cosa && Math.hypot(cosa.x - m.x, cosa.y - m.y) < 7) recoger(J, cosa);
  // El cuervo sube y baja un poco al volar, y baja al picar
  if (m.id === "cuervo") m.z = (m.ataca > 0 ? 8 : D.altura) + Math.sin(J.t * 5) * 2;
}

export function cosasMascota(J, g, cosas, sombra) {
  const m = J.mascota;
  if (!m || !J.enPantalla(m.x, m.y)) return;
  sombra(m.x, m.y, m.id === "perro" ? 7 : 5, 2);
  cosas.push({ y: m.y, f: () => dibujar(g, m) });
}

function dibujar(g, m) {
  const s = S[m.id];
  if (!s) { g.fillStyle = { perro: "#6b4a2e", gato: "#85837a", cuervo: "#1c1a1d" }[m.id]; g.fillRect(Math.round(m.x) - 5, Math.round(m.y - m.z) - 8, 10, 8); return; }
  const tag = m.ataca > 0 ? (s.tags.atacar ? "atacar" : "picar") : m.id === "cuervo" ? "volar" : m.andando ? "andar" : "quieto";
  const i = fotograma(s, s.tags[tag] ? tag : Object.keys(s.tags)[0], m.anim * (m.andando ? 1.6 : 1));
  const p = punto(s, "pies", i, { x: Math.floor(s.w / 2), y: s.h - 1 });
  const ax = m.voltear ? s.w - 1 - p.x : p.x;
  const x = Math.round(m.x) - ax, y = Math.round(m.y - m.z) - p.y;
  const f = s.frames[i];
  if (!m.voltear) g.drawImage(s.img, f.x, f.y, f.w, f.h, x, y, f.w, f.h);
  else { g.save(); g.translate(x + f.w, y); g.scale(-1, 1); g.drawImage(s.img, f.x, f.y, f.w, f.h, 0, 0, f.w, f.h); g.restore(); }
}
