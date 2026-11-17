// Todo destruible (estilo Streets of Rogue): las cosas del mapa tienen vida y se rompen a tiros, con el
// cuerpo a cuerpo, con explosiones o con el fuego. Al romperse dejan restos pintados en el suelo, dejan de
// chocar y algunas sueltan botín. La madera, las plantas y la goma arden y el fuego pasa a lo que tienen al
// lado; los coches, cuando arden, acaban estallando y queda el coche calcinado.
import { S, punto, teñida } from "./sprites.js";
import { sonar } from "./audio.js";

const rnd = (a, b) => a + Math.random() * (b - a);
const rndInt = (a, b) => Math.floor(rnd(a, b + 1));

// vida; restos = fotograma de «restos»; alto = para las balas (a la altura del pecho); arde = se prende;
// botin = qué puede soltar; trozos = colores de lo que salta al golpearlo.
const MADERA = ["#5c3d22", "#7b5631", "#9a7446"], METAL = ["#323840", "#4b535e", "#6e7885"];
export const OBJETOS = {
  caja: { vida: 30, restos: 0, arde: true, botin: "caja", trozos: MADERA, sonido: "madera" },
  barrera: { vida: 70, restos: 0, arde: true, trozos: MADERA, sonido: "madera" },
  sacos: { vida: 90, restos: 7, trozos: ["#6b5c3e", "#8c7a54", "#ab986e"], sonido: "impacto" },
  cono: { vida: 10, restos: 4, trozos: ["#a8461a", "#d9702e", "#d1cec0"], sonido: "impacto" },
  neumaticos: { vida: 45, restos: 5, arde: true, trozos: ["#141317", "#222127", "#33323a"], sonido: "impacto" },
  barril: { vida: 55, restos: 1, alto: true, trozos: METAL, sonido: "metal" },
  contenedor: { vida: 160, restos: 1, alto: true, botin: "contenedor", trozos: METAL, sonido: "metal" },
  farola: { vida: 70, restos: 6, alto: true, trozos: METAL, sonido: "metal" },
  arbusto: { vida: 20, restos: 3, arde: true, trozos: ["#1e3320", "#2e4a2a", "#426438"], sonido: "hojas" },
  arbol: { vida: 130, restos: 2, alto: true, arde: true, trozos: ["#2e4a2a", "#426438", "#4a3626"], sonido: "madera" },
  coche: { vida: 240, alto: true, arde: true, botin: "coche", trozos: ["#323840", "#6e7885", "#b5d0db"], sonido: "metal" },
  // Edificios (edificios.js): cada tramo de pared y la puerta
  pared_ladrillo: { vida: 130, restos: 8, alto: true, trozos: ["#5c3024", "#7d4432", "#7b7b7c"], sonido: "impacto" },
  pared_madera: { vida: 70, restos: 0, alto: true, arde: true, trozos: MADERA, sonido: "madera" },
  puerta: { vida: 45, restos: 0, alto: true, arde: true, trozos: MADERA, sonido: "madera" },
};

export function prepararDestruibles(mapa) {
  for (const o of mapa.objetos) {
    const d = OBJETOS[o.tipo];
    if (d) { o.vida = o.vidaMax = d.vida; o.golpe = 0; o.barra = 0; o.arde = 0; o.chispa = 0; }
  }
  // Copias para el destello al golpear, el oscurecido al estar dañado y el coche calcinado
  for (const n of [...Object.keys(OBJETOS), "pared", "pared_v"]) {
    const s = S[n];
    if (s && !s.blanca) s.blanca = teñida(s.img, "#ffffff");
    if (s && !s.sombra) s.sombra = teñida(s.img, "#0e0d12");
  }
  if (S.coche && !S.coche.quemado) S.coche.quemado = calcinar(S.coche.img);
}

// El coche calcinado: los mismos píxeles pasados a negro, gris ceniza y óxido según su brillo.
function calcinar(img) {
  const c = document.createElement("canvas"); c.width = img.width; c.height = img.height;
  const g = c.getContext("2d");
  g.drawImage(img, 0, 0);
  const d = g.getImageData(0, 0, c.width, c.height), p = d.data;
  // Negro, ceniza y gris; el óxido sale a manchas (por bloques de 3x3 píxeles, no píxel a píxel).
  const R = [[14, 13, 18], [30, 31, 36], [41, 43, 49], [65, 68, 76], [82, 84, 93]], OXIDO = [[58, 34, 22], [92, 44, 20]];
  const azar = (x, y) => { let n = (x * 374761393 + y * 668265263) | 0; n = Math.imul(n ^ (n >>> 13), 1274126177); return ((n ^ (n >>> 16)) >>> 0) / 4294967296; };
  for (let i = 0; i < p.length; i += 4) {
    if (!p[i + 3]) continue;
    const x = (i / 4) % c.width, y = Math.floor(i / 4 / c.width);
    const l = (p[i] * 0.3 + p[i + 1] * 0.59 + p[i + 2] * 0.11) / 255;
    const k = Math.min(4, Math.floor(l * 4.6));
    const mancha = azar(Math.floor(x / 3), Math.floor(y / 3)) < 0.18 && k >= 1 && k <= 3;
    [p[i], p[i + 1], p[i + 2]] = mancha ? OXIDO[k >= 2 ? 1 : 0] : R[k];
  }
  g.putImageData(d, 0, 0);
  c.pixeles = d;
  return c;
}

// ------------------------------------------------------------------ daño
// Daña un objeto. fuego = lo prende si es de los que arden.
export function danarObjeto(J, o, dano, fuego = false) {
  const d = OBJETOS[o.tipo];
  if (!d || o.roto || o.quemado) return;
  o.vida -= dano; o.golpe = 0.08; o.barra = 2;
  for (let i = 0; i < Math.min(6, 1 + dano / 8); i++) {
    J.particulas.push({ x: o.x + rnd(-6, 6), y: o.y + rnd(-2, 2), z: rnd(4, 16), vx: rnd(-50, 50), vy: rnd(-20, 20), vz: rnd(30, 90),
      color: d.trozos[rndInt(0, d.trozos.length - 1)], vida: 2 });
  }
  sonar(d.sonido === "metal" ? "golpeMetal" : d.sonido === "madera" ? "golpeMadera" : d.sonido === "hojas" ? "golpeHojas" : "impacto", 0.04);
  if (fuego && d.arde) o.arde = Math.max(o.arde, 99);
  if (o.tipo === "coche" && o.vida < o.vidaMax * 0.35) o.arde = 99;            // el coche malherido empieza a arder
  if (o.vida <= 0) romper(J, o);
}

function romper(J, o) {
  const d = OBJETOS[o.tipo], m = J.mapa;
  o.vida = 0; o.arde = 0;
  if (o.tipo === "coche") {
    // Estalla y queda el coche calcinado (sigue estorbando)
    o.quemado = true;
    J.explotar(o.x, o.y - 20, { radio: 56, dano: 110 });
    J.romperMolotov(o.x, o.y - 10, true);
    soltarBotin(J, o, d.botin);
    return;
  }
  o.roto = true;
  if (o.caja) m.cajas = m.cajas.filter((c) => c !== o.caja);
  if (o.luz) m.luces = m.luces.filter((l) => l !== o.luz);
  m.objetos = m.objetos.filter((x) => x !== o);
  // Restos pintados en el suelo para siempre
  const s = S.restos;
  if (s && d.restos !== undefined) {
    const f = s.frames[d.restos], b = punto(s, "base", d.restos, { x: 20, y: 20 });
    m.sueloCtx.drawImage(s.img, f.x, f.y, f.w, f.h, Math.round(o.x - b.x), Math.round(o.y - b.y), f.w, f.h);
  }
  for (let i = 0; i < 12; i++) {
    J.particulas.push({ x: o.x + rnd(-8, 8), y: o.y + rnd(-3, 3), z: rnd(4, 20), vx: rnd(-70, 70), vy: rnd(-30, 30), vz: rnd(40, 120),
      color: d.trozos[rndInt(0, d.trozos.length - 1)], vida: 2.5 });
  }
  sonar("romper", 0.05);
  J.sacudida = Math.max(J.sacudida, o.tipo === "arbol" || o.tipo === "contenedor" ? 2.5 : 1);
  soltarBotin(J, o, d.botin);
}

// Lo que sale al romper: monedas, munición, granadas o un botiquín.
function soltarBotin(J, o, tipo) {
  if (!tipo) return;
  const echar = (t) => J.botin.push({ tipo: t, x: o.x + rnd(-6, 6), y: o.y + rnd(-3, 4), z: 10, vz: rnd(55, 95), vx: rnd(-40, 40), vy: rnd(-20, 20), t: 0, anim: rnd(0, 1) });
  const monedas = { caja: [0, 3], contenedor: [4, 8], coche: [3, 6] }[tipo];
  for (let i = 0, n = rndInt(...monedas); i < n; i++) echar("moneda");
  const r = Math.random();
  if (tipo === "caja") { if (r < 0.35) echar("municion"); else if (r < 0.5) echar("botiquin"); }
  if (tipo === "contenedor") { echar("municion"); if (r < 0.4) echar("granada"); else if (r < 0.6) echar("botiquin"); }
  if (tipo === "coche") { if (r < 0.5) echar("municion"); if (Math.random() < 0.25) echar("granada"); }
}

// ------------------------------------------------------------------ quién los daña
// Bala: choca con lo alto (coches, contenedores, barriles, troncos, farolas) si pasa por encima de su base.
export function balaAObjeto(J, b) {
  const alto = b.alto ?? 19;
  const sx = b.x - b.px, sy = b.y - b.py, l = Math.hypot(sx, sy), pasos = Math.max(1, Math.ceil(l / 4));
  for (let k = 1; k <= pasos; k++) {
    const gx = b.px + sx * (k / pasos), gy = b.py + sy * (k / pasos) + alto;
    for (const o of J.mapa.objetos) {
      const d = OBJETOS[o.tipo];
      if (!d || !d.alto || !o.caja || o.roto || o.tipo === "puerta") continue;   // tus balas cruzan la puerta
      const c = o.caja;
      if (gx >= c.x - 1 && gx <= c.x + c.w + 1 && gy >= c.y - 2 && gy <= c.y + c.h + 2) {
        if (o.quemado) return { o, x: gx, y: gy };                 // el coche calcinado para las balas
        const def = b.def || J.arma(b.arma);
        danarObjeto(J, o, def.dano || 10, false);
        return { o, x: gx, y: gy };
      }
    }
  }
  return null;
}

// Explosión o golpe en un círculo (en el suelo).
export function golpeArea(J, x, y, radio, dano, fuego) {
  for (const o of [...J.mapa.objetos]) {
    if (!OBJETOS[o.tipo] || o.roto) continue;
    const d = Math.hypot(o.x - x, (o.y - y) * 1.3);
    if (d < radio + 8) danarObjeto(J, o, dano * (1 - 0.5 * Math.min(1, d / radio)), fuego);
  }
}

// Bate o machete: lo que haya en el arco del golpe.
export function golpeCuerpo(J, a) {
  const j = J.jugador, medio = (a.arco / 2) * Math.PI / 180;
  let alguno = false;
  for (const o of [...J.mapa.objetos]) {
    if (!OBJETOS[o.tipo] || o.roto || o.quemado || o.tipo === "puerta") continue;      // tu puerta no la rompes tú
    const cy = o.caja ? o.caja.y + o.caja.h / 2 : o.y;
    const dx = o.x - j.x, dy = cy - j.y, d = Math.hypot(dx, dy);
    if (d > a.alcance + 12) continue;
    const dif = Math.atan2(Math.sin(Math.atan2(dy, dx) - j.angulo), Math.cos(Math.atan2(dy, dx) - j.angulo));
    if (Math.abs(dif) > medio && d > 14) continue;
    danarObjeto(J, o, a.dano, false);
    alguno = true;
  }
  return alguno;
}

// Prende lo que arda cerca de (x, y) (llamas del lanzallamas, charcos de fuego).
export function prender(J, x, y, r) {
  for (const o of J.mapa.objetos) {
    const d = OBJETOS[o.tipo];
    if (!d || !d.arde || o.roto || o.quemado || o.arde > 0) continue;
    if ((o.x - x) ** 2 + ((o.y - y) * 1.3) ** 2 < r * r) o.arde = 99;
  }
}

// ------------------------------------------------------------------ cada fotograma
export function moverObjetos(J, dt) {
  for (const o of [...J.mapa.objetos]) {
    if (!o.vidaMax) continue;
    o.golpe = Math.max(0, o.golpe - dt); o.barra = Math.max(0, o.barra - dt);
    if (!(o.arde > 0) || o.roto || o.quemado) continue;
    o.arde -= dt;
    o.vida -= (o.tipo === "coche" ? 12 : 7) * dt;
    if (Math.random() < dt * 8) J.particulas.push({ x: o.x + rnd(-8, 8), y: o.y, z: rnd(10, 30), vx: rnd(-6, 6), vy: 0, vz: rnd(25, 55), color: Math.random() < 0.5 ? "#ffc93a" : "#f08a1c", vida: 0.6 });
    // El fuego pasa a lo que está al lado y a los zombis que se acercan
    o.chispa -= dt;
    if (o.chispa <= 0) {
      o.chispa = 0.6;
      for (const p of J.mapa.objetos) {
        const d = OBJETOS[p.tipo];
        if (p === o || !d || !d.arde || p.roto || p.quemado || p.arde > 0) continue;
        if ((p.x - o.x) ** 2 + (p.y - o.y) ** 2 < 34 * 34 && Math.random() < 0.35) p.arde = p.tipo === "coche" ? 99 : 5;
      }
      for (const z of J.zombis) if (!z.muerto && (z.x - o.x) ** 2 + (z.y - o.y) ** 2 < 16 * 16) z.arde = Math.max(z.arde || 0, 2.5);
    }
    if (o.vida <= 0) romper(J, o);
    else if (o.arde <= 0 && o.tipo !== "coche") o.arde = 0;
  }
}

// ------------------------------------------------------------------ dibujo
// Dibuja un objeto del mapa con su estado: destello al golpearlo, más oscuro si está muy dañado, en llamas.
export function dibujarDestruible(J, g, o, dibujar, i) {
  const s = S[o.tipo], x = o.x - o.base.x, y = o.y - o.base.y;
  const tiembla = o.golpe > 0 ? Math.round(rnd(-1, 1)) : 0;
  if (o.quemado) { dibujar(g, s, i, x, y, false, s.quemado || s.img); }
  else {
    dibujar(g, s, i, x + tiembla, y, false, o.golpe > 0 && s.blanca ? s.blanca : s.img);
    if (o.vidaMax && o.vida < o.vidaMax * 0.5 && s.sombra) {
      g.globalAlpha = 0.28 * (1 - o.vida / (o.vidaMax * 0.5)) + 0.1;
      dibujar(g, s, i, x + tiembla, y, false, s.sombra);
      g.globalAlpha = 1;
    }
  }
  if (o.arde > 0 && !o.roto) {
    const n = o.tipo === "coche" || o.tipo === "arbol" ? 3 : o.tipo === "arbusto" || o.tipo === "neumaticos" ? 1 : 2;
    const sobre = o.tipo === "arbol" ? 30 : o.tipo === "coche" ? 26 : 4;
    for (let k = 0; k < n; k++) J.dibujarLlama(g, o.x + (k - (n - 1) / 2) * 8, o.y - sobre + (k % 2) * 4, J.t * 1.2 + k * 0.31 + o.x * 0.01);
  }
  if (o.quemado && Math.random() < 0.05) J.particulas.push({ x: o.x + rnd(-8, 8), y: o.y - 20, z: 20, vx: rnd(-4, 4), vy: 0, vz: 20, color: "rgba(65,68,76,0.6)", vida: 1.5 });
}

// Barras de vida de lo que se está golpeando (encima de la oscuridad).
export function barrasObjetos(J, g) {
  for (const o of J.mapa.objetos) {
    if (!o.vidaMax || o.barra <= 0 || o.roto || o.quemado || o.vida >= o.vidaMax || !J.enPantalla(o.x, o.y)) continue;
    const w = 18, x = Math.round(o.x - w / 2), y = Math.round(o.y - (S[o.tipo]?.h || 20) - 4);
    g.fillStyle = "#0e0d12"; g.fillRect(x - 1, y - 1, w + 2, 4);
    g.fillStyle = "#34363d"; g.fillRect(x, y, w, 2);
    g.fillStyle = "#d1cec0"; g.fillRect(x, y, Math.max(1, Math.round(w * o.vida / o.vidaMax)), 2);
  }
}

// Luz de lo que arde.
export function lucesObjetos(J, foco) {
  for (const o of J.mapa.objetos) if (o.arde > 0 && !o.roto) foco(o.x, o.y - 14, o.tipo === "coche" || o.tipo === "arbol" ? 70 : 46, 1, "255,150,60");
}
