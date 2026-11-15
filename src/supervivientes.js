// Supervivientes: de vez en cuando aparece uno atrapado fuera de la base pidiendo ayuda. Si llegas hasta él
// te sigue (y dispara con su pistola); si lo llevas vivo dentro de la base, sube al muro y defiende desde allí.
// Los zombis van a por el que tengan más cerca: tú o un superviviente.
import { S, punto, fotograma, duracion, primero, dibujarAnclado, texto } from "./sprites.js";
import { SUPERVIVIENTES as SV, OLEADAS } from "./config.js";
import { resolverChoques, chocaCon } from "./mapa.js";
import { chocarMuro, dentro } from "./base.js";
import { crearRagdoll } from "./ragdoll.js";
import { sonar } from "./audio.js";
import { t } from "./idioma.js";

const rnd = (a, b) => a + Math.random() * (b - a);
const PIES = { x: 20, y: 38 }, HOMBRO = { x: 20, y: 13 };
const DEF_PISTOLA = { dano: SV.dano, empuje: 4, critico: 0.08 };

// Al empezar una ronda, a veces aparece uno atrapado lejos de la base (nunca dos atrapados a la vez).
export function quizaSuperviviente(J) {
  const vivos = J.supervivientes.filter((s) => !s.muerto);
  if (J.oleada.n < SV.desdeRonda || vivos.length >= SV.max || vivos.some((s) => s.estado === "atrapado")) return;
  if (Math.random() > SV.probabilidad) return;
  const m = J.mapa;
  let x, y;
  for (let k = 0; k < 20; k++) {
    x = rnd(40, m.ancho - 40); y = rnd(J.base.y - 720, J.base.y - 300);
    if (!chocaCon(m, x, y, 10)) break;
  }
  const usadas = new Set(J.supervivientes.map((s) => s.variante));
  const libres = S.supervivientes.map((_, i) => i).filter((i) => !usadas.has(i));
  J.supervivientes.push({
    estado: "atrapado", x, y, vida: SV.vida, variante: libres.length ? libres[Math.floor(Math.random() * libres.length)] : 0,
    anim: rnd(0, 2), ang: Math.PI / 2, espera: 0, tDisparo: 9, golpe: 0, andando: false, grito: 1, puesto: null, muerto: false,
  });
}

export function moverSupervivientes(J, dt) {
  const j = J.jugador, b = J.base;
  for (const s of J.supervivientes) {
    if (s.muerto) continue;
    s.espera = Math.max(0, s.espera - dt); s.tDisparo += dt; s.golpe = Math.max(0, s.golpe - dt);
    let tx = s.x, ty = s.y;
    if (s.estado === "atrapado") {
      s.grito -= dt;
      if (s.grito <= 0 && J.enPantalla(s.x, s.y, 20)) { s.grito = 3; J.flotantes.push({ x: s.x, y: s.y - 50, t: 0, txt: t("ayuda"), color: "#f2c84a" }); }
      if (!j.muerto && (j.x - s.x) ** 2 + (j.y - s.y) ** 2 < 26 * 26) {
        s.estado = "sigue";
        J.flotantes.push({ x: s.x, y: s.y - 50, t: 0, txt: t("gracias"), color: "#7ee07e" });
        sonar("curar");
      }
    } else if (s.estado === "sigue") {
      // Detrás de ti, a unos pasos
      const d = Math.hypot(j.x - s.x, j.y - s.y);
      if (d > 20) { tx = j.x; ty = j.y; }
      if (s.y > b.y + 8) {                                  // ya dentro: a su puesto en el muro
        s.estado = "muro";
        const ocupados = new Set(J.supervivientes.filter((o) => o.puesto).map((o) => o.puesto.k));
        const k = SV.puestos.find((p) => !ocupados.has(p)) ?? 0;
        s.puesto = { k, x: b.tramos[k + 8].x + 12, y: b.y + 13 };
        J.stats.rescatados = (J.stats.rescatados || 0) + 1;
        J.flotantes.push({ x: s.x, y: s.y - 50, t: 0, txt: t("aSalvo"), color: "#7ee07e" });
      }
    } else if (s.estado === "muro") {
      tx = s.puesto.x; ty = s.puesto.y;
    }
    // Andar
    const dx = tx - s.x, dy = ty - s.y, d = Math.hypot(dx, dy);
    s.andando = d > 3;
    if (s.andando) {
      const v = Math.min(d, SV.velocidad * dt * (s.estado === "sigue" && d > 60 ? 1.15 : 1));
      s.x += (dx / d) * v; s.y += (dy / d) * v;
      resolverChoques(J.mapa, s, 6);
      chocarMuro(b, s, 6, true);
      s.anim += dt;
    } else s.anim += dt * 0.6;
    // Disparar al zombi más cercano a su alcance (desde el muro, solo a los de fuera)
    let mejor = null, md = SV.alcance ** 2;
    for (const z of J.zombis) {
      if (z.muerto || z.aparece > 0.2) continue;
      if (s.estado === "muro" && z.y > b.y) { /* dentro: también */ }
      const e = (z.x - s.x) ** 2 + (z.y - s.y) ** 2;
      if (e < md) { md = e; mejor = z; }
    }
    if (mejor) {
      s.ang = Math.atan2((mejor.y - 19) - (s.y - 25), mejor.x - s.x);
      if (s.espera <= 0 && s.estado !== "atrapado") disparar(J, s);
    } else if (s.andando) s.ang = Math.atan2(dy, dx);
  }
}

function cuadro(s) {
  const spr = S.jugador;
  const o = orientarS(spr, s.andando ? "correr" : "quieto", s.ang);
  s.voltear = o.voltear; s.dir = o.dir;
  return fotograma(spr, o.tag, s.anim);
}

// (como orientar() de juego.js)
const OCT = [["e", false], ["se", false], ["s", false], ["se", true], ["e", true], ["ne", true], ["n", false], ["ne", false]];
function orientarS(spr, base, ang) {
  const [d, espejo] = OCT[((Math.round(ang / (Math.PI / 4)) % 8) + 8) % 8];
  if (spr.tags[base + "_" + d]) return { tag: base + "_" + d, voltear: espejo, dir: d };
  return { tag: base + "_e", voltear: Math.cos(ang) < 0, dir: "e" };
}

// Hombro y boca del arma en el mundo (igual que el jugador, con los brazos de la pistola).
function geometria(s) {
  const cuerpo = S.jugador, br = S.brazos_pistola, i = cuadro(s);
  const pies = punto(cuerpo, "pies", i, PIES), h = punto(cuerpo, "hombro", i, HOMBRO);
  const izq = Math.cos(s.ang) < 0;
  const hombro = { x: Math.round(s.x) + (s.voltear ? pies.x - h.x : h.x - pies.x), y: Math.round(s.y) - (pies.y - h.y) };
  const hb = punto(br, "hombro", 0, { x: 8, y: 10 });
  const c = Math.cos(s.ang), sn = Math.sin(s.ang);
  const boca = punto(br, "boca", 0, { x: 30, y: 9 });
  const vx = boca.x - hb.x, vy = (boca.y - hb.y) * (izq ? -1 : 1);
  return { i, pies, hombro, hb, izq, boca: { x: hombro.x + 0.5 + vx * c - vy * sn, y: hombro.y + 0.5 + vx * sn + vy * c } };
}

function disparar(J, s) {
  const g = geometria(s), v = SV.velocidadBala, ang = s.ang + (Math.random() - 0.5) * 0.08;
  J.balas.push({ x: g.boca.x, y: g.boca.y, px: g.hombro.x, py: g.hombro.y, nueva: true, vx: Math.cos(ang) * v, vy: Math.sin(ang) * v,
    vida: (SV.alcance * 1.25) / v, def: DEF_PISTOLA, atraviesa: 1, tocados: null, alto: s.y - g.boca.y });
  J.fogonazos.push({ x: g.boca.x, y: g.boca.y, ang: s.ang, t: 0 });
  s.espera = (1 / SV.cadencia) * rnd(0.85, 1.2); s.tDisparo = 0;
  if (J.enPantalla(s.x, s.y)) sonar("pistola", 0.08);
}

export function herirSuperviviente(J, s, dano, desde) {
  s.vida -= dano; s.golpe = 0.15;
  J.flotantes.push({ x: s.x, y: s.y - 44, t: 0, txt: "-" + dano, color: "#ff8a5a" });
  for (let i = 0; i < 4; i++) J.gota(s.x, s.y, 19, rnd(-40, 40), rnd(-15, 15), rnd(20, 60));
  if (s.vida > 0) return;
  // Muere: ragdoll con su ropa
  const spr = S.jugador, i = cuadro(s), v = S.supervivientes[s.variante];
  const r = crearRagdoll({ img: v.cuerpo, frame: spr.frames[i], pies: punto(spr, "pies", i, PIES), voltear: s.voltear,
    x: s.x, y: s.y, dir: desde ? { x: s.x - desde.x, y: s.y - desde.y } : { x: 0, y: 1 }, fuerza: 1.3, arrancar: 0.35 });
  if (r) J.ragdolls.push(r);
  J.salpicar(s.x, s.y, 26);
  s.muerto = true;
  J.flotantes.push({ x: s.x, y: s.y - 50, t: 0, txt: t("superviviente") , color: "#ff5a5a" });
  sonar("muerte");
}

export function cosasSupervivientes(J, g, cosas) {
  for (const s of J.supervivientes) if (!s.muerto && J.enPantalla(s.x, s.y)) cosas.push({ y: s.y, f: () => dibujar(J, g, s) });
}

function dibujar(J, g, s) {
  const spr = S.jugador, br = S.brazos_pistola, v = S.supervivientes[s.variante];
  const geo = geometria(s);
  let fi = primero(br, "apuntar");
  if (s.estado === "atrapado") fi = -1;                         // atrapado: con los brazos en alto, sin arma
  else if (s.tDisparo < duracion(br, "disparar")) fi = fotograma(br, "disparar", s.tDisparo, false);
  const brazos = () => {
    if (fi < 0) return;
    const f = br.frames[fi];
    g.save();
    g.translate(geo.hombro.x + 0.5, geo.hombro.y + 0.5);
    g.rotate(s.ang);
    if (geo.izq) g.scale(1, -1);
    g.drawImage(v.brazos, f.x, f.y, f.w, f.h, -geo.hb.x - 0.5, -geo.hb.y - 0.5, f.w, f.h);
    g.restore();
  };
  const detras = s.dir === "n" || s.dir === "ne";
  if (detras) brazos();
  dibujarAnclado(g, spr, geo.i, s.x, s.y, geo.pies, s.voltear, s.golpe > 0 ? spr.blanca : v.cuerpo);
  if (!detras) brazos();
  if (s.estado === "atrapado") {
    // Agita los brazos: dos manos que suben y bajan sobre la cabeza
    const k = Math.floor(s.anim * 6) % 2, x = Math.round(s.x), y = Math.round(s.y) - 34 - k;
    g.fillStyle = "#c4937a"; g.fillRect(x - 6, y, 2, 2); g.fillRect(x + 4, y + k * 2 - 1, 2, 2);
    g.fillStyle = "#3b526b"; g.fillRect(x - 6, y + 2, 2, 4); g.fillRect(x + 4, y + 1 + k * 2, 2, 4);
  }
}

// Encima de la oscuridad: «!» sobre el que espera rescate.
export function marcasSupervivientes(J, g) {
  for (const s of J.supervivientes) {
    if (s.muerto || s.estado !== "atrapado") continue;
    texto(g, "!", s.x, s.y - 52 + Math.round(Math.sin(J.t * 5) * 2), "#f2c84a", "centro", 2);
  }
}

// Flecha en el borde de la pantalla hacia el superviviente que espera (si no se ve).
export function flechaSuperviviente(J, g) {
  const s = J.supervivientes.find((o) => !o.muerto && o.estado === "atrapado");
  if (!s || J.enPantalla(s.x, s.y, -10)) return;
  const c = J.camara, W = J.uiW, H = J.uiH;
  const k = J.pantW / J.ancho;                     // píxeles de interfaz por píxel de mundo
  const cx = W / 2, cy = H / 2;
  const sx = (s.x - c.x) * k - J.seguro.izq, sy = (s.y - 20 - c.y) * k - J.seguro.arr;
  const dx = sx - cx, dy = sy - cy;
  const m = Math.max(Math.abs(dx) / (W / 2 - 22), Math.abs(dy) / (H / 2 - 22));
  const x = cx + dx / m, y = cy + dy / m, a = Math.atan2(dy, dx);
  g.save();
  g.translate(Math.round(x), Math.round(y)); g.rotate(a);
  g.fillStyle = "#0e0d12";
  g.beginPath(); g.moveTo(10, 0); g.lineTo(-6, -8); g.lineTo(-6, 8); g.closePath(); g.fill();
  g.fillStyle = Math.floor(J.t * 3) % 2 ? "#f2c84a" : "#ffffff";
  g.beginPath(); g.moveTo(8, 0); g.lineTo(-4, -6); g.lineTo(-4, 6); g.closePath(); g.fill();
  g.restore();
  texto(g, "!", Math.round(x - Math.cos(a) * 16), Math.round(y - Math.sin(a) * 16) - 5, "#f2c84a", "centro");
}
