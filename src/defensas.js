// Defensas compradas para la base: torretas sobre el muro, focos, trampas que pones tú (minas,
// barriles explosivos, cepos) y zonas (enfermería, taller, armería). Números en src/config.js.
import { S, punto, fotograma, dibujar } from "./sprites.js";
import { TORRETAS, FOCOS, TRAMPAS, ZONAS, MUNICION, ARMAS_FUEGO, JUGADOR } from "./config.js";
import { dentro } from "./base.js";
import { sonar } from "./audio.js";
import { t } from "./idioma.js";

const rnd = (a, b) => a + Math.random() * (b - a);
const tramoEn = (b, k) => b.tramos[k + 8];          // los tramos van de -8 a 8 (0 = portón)
const ALTO_MURO = 31;                                // de la base del tramo a lo alto del muro
// Bala de torreta: como las del jugador, con sus propios números
const DEF_TORRETA = { dano: TORRETAS.dano, empuje: TORRETAS.empuje, critico: TORRETAS.critico };

// Dónde va cada zona dentro de la base (relativo al centro del mapa y a la línea del muro) y su caja de choque.
const SITIO = {
  taller: { dx: -250, dy: 122, caja: { w: 54, h: 14 }, luz: { dy: -24, r: 60 } },
  enfermeria: { dx: 130, dy: 120, caja: { w: 52, h: 14 }, luz: { dy: -26, r: 60 } },
  armeria: { dx: 268, dy: 108, caja: { w: 50, h: 14 }, luz: { dy: -24, r: 56 } },
};

export function crearDefensas(base, mapa) {
  base.torretas = [];
  base.focos = false;
  base.zonas = { enfermeria: false, taller: false, armeria: false };
  base.sitios = Object.fromEntries(Object.entries(SITIO).map(([n, s]) => [n, { x: mapa.centro + s.dx, y: base.y + s.dy }]));
}

// ------------------------------------------------------------------ tienda
export const precioTorreta = (b) => TORRETAS.precios[b.torretas.length] ?? null;
export function comprarTorreta(b) {
  const tr = tramoEn(b, TORRETAS.tramos[b.torretas.length]);
  b.torretas.push({ tramo: tr, x: tr.x, y: tr.y, ang: -Math.PI / 2, espera: 0, municion: TORRETAS.municion, tDisparo: 9 });
}
export const faltaMunicionTorretas = (b) => b.torretas.reduce((s, x) => s + TORRETAS.municion - x.municion, 0);
export function rellenarTorretas(b) { for (const x of b.torretas) x.municion = TORRETAS.municion; }

export function construirZona(b, mapa, n) {
  b.zonas[n] = true;
  const s = b.sitios[n], d = SITIO[n];
  mapa.cajas.push({ x: s.x - d.caja.w / 2, y: s.y - d.caja.h, w: d.caja.w, h: d.caja.h });
  mapa.luces.push({ x: s.x, y: s.y + d.luz.dy, r: d.luz.r });
}

// ------------------------------------------------------------------ cada fotograma
export function moverDefensas(J, dt) {
  moverTorretas(J, dt);
  moverTrampas(J, dt);
  // Enfermería: dentro de la base te vas curando
  const j = J.jugador, b = J.base;
  if (b.zonas.enfermeria && !j.muerto && dentro(b, j.y) && j.vida < JUGADOR.vida) {
    j.vida = Math.min(JUGADOR.vida, j.vida + ZONAS.enfermeria.cura * dt);
    if (Math.random() < dt * 2) J.particulas.push({ x: j.x + rnd(-6, 6), y: j.y, z: rnd(20, 32), vx: 0, vy: 0, vz: 30, color: "#7ee07e", vida: 0.5 });
  }
}

function moverTorretas(J, dt) {
  const b = J.base;
  for (const x of b.torretas) {
    x.espera = Math.max(0, x.espera - dt); x.tDisparo += dt;
    if (x.tramo.vida <= 0 || x.municion <= 0) continue;
    let mejor = null, md = TORRETAS.alcance ** 2;
    for (const z of J.zombis) {
      if (z.muerto || z.aparece > 0.2 || z.y > b.y) continue;
      const d = (z.x - x.x) ** 2 + (z.y - x.y) ** 2;
      if (d < md) { md = d; mejor = z; }
    }
    if (!mejor) continue;
    const by = x.y - ALTO_MURO - 6;
    x.ang = Math.atan2(mejor.y - 19 - by, mejor.x - x.x);
    if (x.espera > 0) continue;
    x.espera = 1 / TORRETAS.cadencia; x.municion--; x.tDisparo = 0;
    const ang = x.ang + (Math.random() - 0.5) * TORRETAS.dispersion * Math.PI / 180, v = TORRETAS.velocidadBala;
    const bx = x.x + Math.cos(x.ang) * 11, bby = by + Math.sin(x.ang) * 11;
    J.balas.push({ x: bx, y: bby, px: x.x, py: by, nueva: true, vx: Math.cos(ang) * v, vy: Math.sin(ang) * v,
      vida: (TORRETAS.alcance * 1.3) / v, def: DEF_TORRETA, atraviesa: 1, tocados: null, alto: x.y - by });
    J.fogonazos.push({ x: bx, y: bby, ang: x.ang, t: 0 });
    sonar("torreta", 0.05);
  }
}

// Zombi deslumbrado por un foco (va más despacio).
export function deslumbrado(b, z) {
  if (!b.focos || z.y > b.y || z.y < b.y - FOCOS.fondo) return false;
  return FOCOS.tramos.some((k) => Math.abs(z.x - tramoEn(b, k).x) < FOCOS.ancho);
}

// ------------------------------------------------------------------ trampas
export function ponerTrampa(J, tipo) {
  const j = J.jugador;
  if (J.estado !== "jugando" || j.muerto || j.trampas[tipo] <= 0) return;
  if (dentro(J.base, j.y - 4)) { J.flotantes.push({ x: j.x, y: j.y - 48, t: 0, txt: t("fueraDeLaBase"), color: "#d1cec0" }); return; }
  if (J.trampas.some((x) => (x.x - j.x) ** 2 + (x.y - j.y) ** 2 < 14 * 14)) return;
  j.trampas[tipo]--;
  J.trampas.push({ tipo, x: Math.round(j.x), y: Math.round(j.y + 3), t: 0, usos: TRAMPAS.cepo.usos, rearme: 0, presa: null, mecha: null });
  sonar("poner");
}

function moverTrampas(J, dt) {
  for (const x of J.trampas) {
    x.t += dt;
    if (x.mecha !== null) {                      // barril o mina a punto de estallar (en cadena)
      x.mecha -= dt;
      if (x.mecha <= 0) { estallarTrampa(J, x); continue; }
    }
    if (x.tipo === "mina") {
      if (x.t < TRAMPAS.mina.activa) continue;
      for (const z of J.zombis) {
        if (!z.muerto && z.aparece <= 0 && (z.x - x.x) ** 2 + (z.y - x.y) ** 2 < TRAMPAS.mina.toque ** 2) { estallarTrampa(J, x); break; }
      }
    } else if (x.tipo === "barril") {
      // Se prende si toca fuego
      if (x.mecha === null && (J.fuegos.some((f) => (f.x - x.x) ** 2 + ((f.y - x.y) / 0.6) ** 2 < (f.r + 4) ** 2)
        || J.llamas.some((f) => (f.x - x.x) ** 2 + (f.y - (x.y - 9)) ** 2 < 64))) x.mecha = 0.35;
    } else if (x.tipo === "cepo") {
      const C = TRAMPAS.cepo;
      if (x.presa) {
        if (x.presa.muerto || !(x.presa.atrapado > 0)) { x.presa = null; x.rearme = C.rearme; if (x.usos <= 0) { x.fuera = true; sonar("impacto"); } }
        continue;
      }
      if (x.rearme > 0) { x.rearme -= dt; continue; }
      for (const z of J.zombis) {
        if (z.muerto || z.aparece > 0 || z.atrapado > 0) continue;
        if ((z.x - x.x) ** 2 + (z.y - x.y) ** 2 < C.toque ** 2) {
          z.atrapado = C.sujeta; z.x = x.x; z.y = x.y; z.vida -= C.dano; z.barra = 2; z.golpe = 0.1;
          J.stats.dano += C.dano;
          J.flotantes.push({ x: x.x, y: x.y - 44, t: 0, txt: String(C.dano), color: "#ffffff" });
          for (let i = 0; i < 6; i++) J.gota(x.x, x.y, rnd(2, 8), rnd(-40, 40), rnd(-12, 12), rnd(20, 50));
          x.presa = z; x.usos--;
          sonar("cepo");
          if (z.vida <= 0) J.matarZombi(z, { x: 0, y: -1 }, 0.7);
          break;
        }
      }
    }
  }
  J.trampas = J.trampas.filter((x) => !x.fuera);
}

function estallarTrampa(J, x) {
  if (x.fuera) return;
  x.fuera = true;
  const T = TRAMPAS[x.tipo];
  J.explotar(x.x, x.y, { radio: T.radio, dano: T.dano });
  if (x.tipo === "barril") J.romperMolotov(x.x, x.y, true);
}

// Una explosión hace estallar las minas y barriles que pille (con un instante de retraso: en cadena).
export function cadena(J, cx, cy, radio) {
  for (const x of J.trampas) {
    if (x.fuera || x.mecha !== null || x.tipo === "cepo") continue;
    if ((x.x - cx) ** 2 + (x.y - cy) ** 2 < radio * radio) x.mecha = rnd(0.08, 0.2);
  }
}

// ¿Una bala da a un barril? (los barriles se pueden disparar)
export function balaABarril(J, b) {
  for (const x of J.trampas) {
    if (x.tipo !== "barril" || x.fuera || x.mecha !== null) continue;
    if ((b.x - x.x) ** 2 + (b.y - (x.y - 9)) ** 2 < 49) { x.mecha = 0.05; return true; }
  }
  return false;
}

// ------------------------------------------------------------------ al acabar la ronda
export function finDeRonda(J) {
  const b = J.base, j = J.jugador;
  if (b.zonas.taller) {
    for (const tr of b.tramos) tr.vida = Math.min(tr.vidaMax, tr.vida + tr.vidaMax * ZONAS.taller.repara);
    for (const x of b.torretas) x.municion = Math.min(TORRETAS.municion, x.municion + ZONAS.taller.municionTorretas);
  }
  if (b.zonas.armeria) {
    let alguna = false;
    for (const n of ARMAS_FUEGO) {
      if (!j.armas[n]) continue;
      const m = MUNICION[n];
      if (j.reserva[n] < m.maximo) { j.reserva[n] = Math.min(m.maximo, j.reserva[n] + m.lote); alguna = true; }
    }
    if (alguna) J.flotantes.push({ x: j.x, y: j.y - 58, t: 0, txt: t("municionArmeria"), color: "#f2c84a" });
  }
}

// ------------------------------------------------------------------ dibujo
// Lo que va de pie, para ordenarlo por la y de los pies junto con todo lo demás.
export function cosasDefensas(J, g, cosas) {
  const b = J.base;
  for (const x of b.torretas) if (J.enPantalla(x.x, x.y, 40)) cosas.push({ y: x.y + 0.2, f: () => dibujarTorreta(g, x) });
  if (b.focos) for (const k of FOCOS.tramos) {
    const tr = tramoEn(b, k);
    if (J.enPantalla(tr.x, tr.y, 40)) cosas.push({ y: tr.y + 0.1, f: () => dibujarFoco(g, tr, J.t) });
  }
  for (const [n, hecha] of Object.entries(b.zonas)) {
    const s = b.sitios[n];
    if (hecha && J.enPantalla(s.x, s.y, 60)) cosas.push({ y: s.y, f: () => dibujarZona(g, n, s, J.t) });
  }
  for (const x of J.trampas) if (x.tipo === "barril" && J.enPantalla(x.x, x.y)) cosas.push({ y: x.y, f: () => dibujarTrampa(g, x, J.t) });
}

// Las trampas planas van en el suelo, por debajo de todo.
export function dibujarTrampasSuelo(J, g) {
  for (const x of J.trampas) if (x.tipo !== "barril" && J.enPantalla(x.x, x.y)) dibujarTrampa(g, x, J.t);
}

function dibujarTorreta(g, x) {
  const s = S.torreta, by = x.y - ALTO_MURO;
  if (!s) {
    g.fillStyle = "#323840"; g.fillRect(Math.round(x.x) - 4, Math.round(by) - 8, 8, 8);
    g.strokeStyle = "#6e7885"; g.beginPath(); g.moveTo(x.x, by - 6); g.lineTo(x.x + Math.cos(x.ang) * 10, by - 6 + Math.sin(x.ang) * 10); g.stroke();
    return;
  }
  // 5 fotogramas: e, ne, n, nw, w (la torreta solo apunta hacia fuera, al norte)
  const a = ((x.ang % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);    // 0 = derecha, 3π/2 = arriba
  let i = Math.round((2 * Math.PI - a) / (Math.PI / 4));                  // 0 e, 1 ne, 2 n, 3 nw, 4 w
  if (a < Math.PI * 0.5) i = 0; else if (a < Math.PI) i = 4;
  i = Math.max(0, Math.min(4, i));
  const voltear = i > 2, f = voltear ? 4 - i : i;
  const b0 = punto(s, "base", f, { x: 12, y: 21 });
  const sinBalas = x.municion <= 0 || x.tramo.vida <= 0;
  dibujar(g, s, f + (sinBalas ? 3 : 0), Math.round(x.x) - (voltear ? s.w - 1 - b0.x : b0.x), Math.round(by) - b0.y, voltear);
}

function dibujarFoco(g, tr, tt) {
  const s = S.foco, x = tr.x + 16, by = tr.y - ALTO_MURO + 1;
  if (!s) { g.fillStyle = "#4b535e"; g.fillRect(Math.round(x) - 1, Math.round(by) - 14, 2, 14); g.fillStyle = "#fff1a8"; g.fillRect(Math.round(x) - 3, Math.round(by) - 17, 6, 3); return; }
  const f = tr.vida > 0 ? 0 : 1, b0 = punto(s, "base", f, { x: 8, y: 23 });
  dibujar(g, s, f, Math.round(x) - b0.x, Math.round(by) - b0.y);
}

function dibujarZona(g, n, s0, tt) {
  const s = S[n];
  if (!s) { g.fillStyle = { taller: "#5c3d22", enfermeria: "#aeab9f", armeria: "#4a5432" }[n]; g.fillRect(Math.round(s0.x) - 26, Math.round(s0.y) - 30, 52, 30); return; }
  const f = s.frames.length > 1 ? Math.floor(tt * 3) % s.frames.length : 0;
  const b0 = punto(s, "base", f, { x: Math.floor(s.w / 2), y: s.h - 2 });
  dibujar(g, s, f, Math.round(s0.x) - b0.x, Math.round(s0.y) - b0.y);
}

function dibujarTrampa(g, x, tt) {
  const n = x.tipo === "barril" ? "barril_explosivo" : x.tipo, s = S[n];
  if (!s) {
    g.fillStyle = x.tipo === "barril" ? "#872a26" : "#4b535e";
    if (x.tipo === "barril") g.fillRect(Math.round(x.x) - 6, Math.round(x.y) - 18, 12, 18); else g.fillRect(Math.round(x.x) - 4, Math.round(x.y) - 2, 8, 3);
    return;
  }
  let f = 0;
  if (x.tipo === "mina") f = x.t >= TRAMPAS.mina.activa && Math.floor(tt * 2) % 2 ? 1 : 0;     // luz roja que parpadea
  if (x.tipo === "cepo") f = x.presa || x.rearme > 0 ? 1 : 0;                                // cerrado
  const b0 = punto(s, "base", f, { x: Math.floor(s.w / 2), y: s.h - 1 });
  if (x.tipo === "barril" && x.mecha !== null && Math.floor(tt * 20) % 2) { dibujar(g, s, f, x.x - b0.x, x.y - b0.y, false, s.blanca || s.img); return; }
  dibujar(g, s, f, x.x - b0.x, x.y - b0.y);
}

// Luces: los focos alumbran por delante del muro.
export function lucesDefensas(J, foco) {
  const b = J.base;
  if (b.focos) for (const k of FOCOS.tramos) {
    const tr = tramoEn(b, k);
    if (tr.vida <= 0) continue;
    foco(tr.x + 16, tr.y - ALTO_MURO - 14, 26, 1, "255,240,200");
    foco(tr.x + 10, b.y - FOCOS.fondo * 0.55, FOCOS.fondo * 0.62, 0.95, "235,235,210");
  }
  for (const x of J.trampas) if (x.tipo === "mina" && x.t >= TRAMPAS.mina.activa && Math.floor(J.t * 2) % 2) foco(x.x, x.y - 2, 10, 0.8, "255,60,50");
}
