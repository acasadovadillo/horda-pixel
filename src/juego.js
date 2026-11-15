// Partida: jugador, zombis, balas, botín, oleadas, cámara, luces, interfaz.
import { PANTALLA, JUGADOR, ARMAS, ZOMBIS, OLEADAS, BOTIN } from "./config.js";
import { S, punto, fotograma, fotogramaPorAvance, duracion, primero, dibujar, dibujarAnclado, texto, anchoTexto } from "./sprites.js";
import { crearMapa, manchar, resolverChoques, chocaCon } from "./mapa.js";
import { entrada, leerMovimiento, leerApuntado, RADIO_STICK } from "./entrada.js";
import { sonar, sonarRecarga, sonarCartucho, sonarCorredera, cancelarRecarga, desbloquear, silenciar, silenciado } from "./audio.js";
import { pantallaCompletaHorizontal } from "./pantalla.js";
import { t, idioma, cambiarIdioma } from "./idioma.js";

const ORDEN_ARMAS = ["pistola", "subfusil", "escopeta"];
const PIES = { x: 20, y: 38 };          // punto de los pies por defecto en los lienzos de 40x40
const HOMBRO = { x: 20, y: 13 };
const PECHO = 19;                       // px sobre los pies: adonde se apunta y donde impactan las balas
const RADIO_CUERPO = 9;                 // radio del blanco que ofrece un zombi a las balas
const vibrar = (p) => { if (navigator.userActivation?.hasBeenActive) navigator.vibrate?.(p); };
const ALTURA_JUGADOR = 0.78;      // el jugador va algo por debajo del centro: se ve más de donde vienen
const ZOOMS = ["cerca", "media", "lejos"];
const CLAVE_ZOOM = "horda-pixel:camara";
function leerZoom() {
  try { const z = localStorage.getItem(CLAVE_ZOOM); if (ZOOMS.includes(z)) return z; } catch (e) { /* sin almacenamiento */ }
  return PANTALLA.vista;
}
const CLAVE_DISPARO = "horda-pixel:disparo";
function leerDisparo() {
  try { if (localStorage.getItem(CLAVE_DISPARO) === "manual") return "manual"; } catch (e) { /* sin almacenamiento */ }
  return "auto";
}
// 8 direcciones: se dibujan s, se, e, ne y n; w, sw y nw son el espejo de e, se y ne.
// Ángulos de pantalla (y hacia abajo): 0 = derecha, π/2 = abajo.
const OCTANTES = [["e", false], ["se", false], ["s", false], ["se", true], ["e", true], ["ne", true], ["n", false], ["ne", false]];
// Animación y espejo para mirar hacia «ang». Con sprites antiguos (sin _s, _ne...) se usa la de perfil.
function orientar(spr, base, ang) {
  const [d, espejo] = OCTANTES[((Math.round(ang / (Math.PI / 4)) % 8) + 8) % 8];
  if (spr.tags[base + "_" + d]) return { tag: base + "_" + d, voltear: espejo, dir: d };
  return { tag: spr.tags[base + "_e"] ? base + "_e" : base, voltear: Math.cos(ang) < 0, dir: "e" };
}
const rnd = (a, b) => a + Math.random() * (b - a);
const rndInt = (a, b) => Math.floor(rnd(a, b + 1));

export class Juego {
  constructor() {
    this.mapa = crearMapa();
    this.ancho = 270; this.alto = 480;     // lo que se ve del mundo, en píxeles de juego (cambia con el zoom)
    this.pantW = 270; this.pantH = 480;    // la pantalla en píxeles de interfaz
    this.seguro = { izq: 0, der: 0, arr: 0, aba: 0 };   // márgenes seguros en píxeles de juego
    this.zoom = leerZoom();                              // "cerca" | "media" | "lejos"
    this.disparo = leerDisparo();                        // "auto" | "manual" (joystick de apuntar a la derecha)
    entrada.manual = this.disparo === "manual";
    this.reiniciar();
    this.estado = "inicio";
    entrada.alPulsar.push((c) => this.tecla(c));
  }

  reiniciar() {
    if (this.mapa.usado) this.mapa = crearMapa();
    this.mapa.usado = true;
    const s = this.mapa.salida;
    this.jugador = {
      x: s.x, y: s.y, vida: JUGADOR.vida, arma: "pistola",
      cargador: Object.fromEntries(ORDEN_ARMAS.map((a) => [a, ARMAS[a].cargador])),
      recarga: 0, espera: 0, angulo: -Math.PI / 2, voltear: false, anim: 0, andando: false,
      golpe: 0, muerto: 0, sinBlanco: 0, tDisparo: 9,
    };
    this.zombis = []; this.balas = []; this.botin = []; this.flotantes = [];
    this.particulas = []; this.fogonazos = [];
    this.blanco = null;
    this.oleada = { n: 0, porSalir: 0, t: 0, descanso: 2.5, cartel: 0, superada: 0 };
    this.stats = { bajas: 0, monedas: 0, tiempo: 0, disparos: 0, impactos: 0, dano: 0, recibido: 0 };
    this.camara = { x: s.x - this.ancho / 2, y: s.y - this.alto * ALTURA_JUGADOR };
    this.sacudida = 0;
    this.t = 0;
    this.estado = "jugando";
  }

  tecla(c) {
    if (c === "Digit1" || c === "Digit2" || c === "Digit3") this.cambiarArma(ORDEN_ARMAS[+c.slice(5) - 1]);
    if (c === "KeyR") this.empezarRecarga();
    if (c === "KeyP" || c === "Escape") this.pausar();
    if ((c === "Enter" || c === "Space") && (this.estado === "inicio" || this.estado === "fin")) this.empezar();
  }

  empezar() {
    pantallaCompletaHorizontal();
    desbloquear();
    sonar("boton");
    this.reiniciar();
  }

  pausar() {
    if (this.estado === "jugando") this.estado = "pausa";
    else if (this.estado === "pausa") this.estado = "jugando";
  }

  cambiarArma(a) {
    const j = this.jugador;
    if (!a || a === j.arma || j.muerto) return;
    j.arma = a; j.recarga = 0; j.espera = 0.15; j.tDisparo = 9;
    cancelarRecarga();
    sonar("recargado");
  }

  empezarRecarga() {
    const j = this.jugador, a = ARMAS[j.arma];
    if (j.recarga > 0 || j.cargador[j.arma] >= a.cargador || j.muerto) return;
    if (a.porCartucho) {
      // Escopeta: se gira el arma y se meten los cartuchos de uno en uno por debajo.
      j.recamaraVacia = j.cargador[j.arma] === 0;
      j.recarga = a.preparar + a.recarga;
      j.recargaPaso = j.recarga;
      sonarRecarga(j.arma, a.preparar);
      return;
    }
    j.recarga = a.recarga;
    j.recargaPaso = a.recarga;
    sonarRecarga(j.arma, a.recarga);
  }

  // ------------------------------------------------------------------ actualizar
  actualizar(dt) {
    entrada.botones = [];
    if (this.estado === "inicio") this.moverCamara(1);
    if (this.estado === "pausa" || this.estado === "inicio") return;
    this.t += dt;
    if (this.estado === "jugando") this.stats.tiempo += dt;

    this.moverJugador(dt);
    this.disparar(dt);
    this.moverZombis(dt);
    this.moverBalas(dt);
    this.moverBotin(dt);
    this.moverEfectos(dt);
    this.oleadas(dt);
    this.moverCamara(dt);
  }

  moverJugador(dt) {
    const j = this.jugador;
    j.golpe = Math.max(0, j.golpe - dt);
    if (j.muerto) {
      j.muerto += dt;
      if (j.muerto > 2.4 && this.estado === "jugando") this.estado = "fin";
      return;
    }
    leerMovimiento();
    const mx = entrada.mx, my = entrada.my, fuerza = Math.hypot(mx, my);
    j.andando = fuerza > 0.1;
    j.x += mx * JUGADOR.velocidad * dt;
    j.y += my * JUGADOR.velocidad * dt;
    resolverChoques(this.mapa, j, JUGADOR.radio);
    j.anim += dt * (j.andando ? 0.45 + 0.55 * fuerza : 1);
    if (j.andando && !this.blanco) j.angulo = Math.atan2(my, mx);
  }

  // Solo se dispara a lo que se ve: con zoom, el alcance del arma puede salirse de la pantalla.
  seVe(z) {
    const c = this.camara;
    return z.x > c.x - 4 && z.x < c.x + this.ancho + 4 && z.y > c.y + 6 && z.y - 30 < c.y + this.alto;
  }

  zombiMasCercano(alcance) {
    const j = this.jugador;
    let mejor = null, md = alcance * alcance;
    for (const z of this.zombis) {
      if (z.muerto || z.aparece > 0.2 || !this.seVe(z)) continue;
      const d = (z.x - j.x) ** 2 + (z.y - j.y) ** 2;
      if (d < md) { md = d; mejor = z; }
    }
    return mejor;
  }

  cuadroJugador() {
    const j = this.jugador, spr = S.jugador;
    if (j.muerto) return fotograma(spr, "morir", j.muerto, false);
    const o = orientar(spr, j.andando ? "correr" : "quieto", j.angulo);
    j.voltear = o.voltear; j.dir = o.dir;
    return fotograma(spr, o.tag, j.anim);
  }

  // Posición en el mundo del hombro (donde giran los brazos), la boca del cañón y la ventana de expulsión.
  geometriaArma() {
    const j = this.jugador, cuerpo = S.jugador, br = S["brazos_" + j.arma];
    const i = this.cuadroJugador();
    const pies = punto(cuerpo, "pies", i, PIES), h = punto(cuerpo, "hombro", i, HOMBRO);
    const izq = Math.cos(j.angulo) < 0;          // los brazos se dan la vuelta al apuntar a la izquierda
    const hombro = { x: Math.round(j.x) + (j.voltear ? pies.x - h.x : h.x - pies.x), y: Math.round(j.y) - (pies.y - h.y) };
    const hb = punto(br, "hombro", 0, { x: 8, y: 10 });
    const c = Math.cos(j.angulo), s = Math.sin(j.angulo);
    const alMundo = (p) => {
      const vx = p.x - hb.x, vy = (p.y - hb.y) * (izq ? -1 : 1);
      return { x: hombro.x + 0.5 + vx * c - vy * s, y: hombro.y + 0.5 + vx * s + vy * c };
    };
    return {
      hombro, hb, izq,
      boca: alMundo(punto(br, "boca", 0, { x: 30, y: 9 })),
      casquillo: alMundo(punto(br, "casquillo", 0, { x: 20, y: 8 })),
    };
  }

  disparar(dt) {
    const j = this.jugador, a = ARMAS[j.arma];
    if (j.muerto) return;
    j.espera = Math.max(0, j.espera - dt);
    j.tDisparo += dt;
    // Automático: al zombi visible más cercano. Manual: hacia donde marca el joystick de la derecha.
    const manual = this.disparo === "manual";
    const apuntado = manual ? leerApuntado() : null;
    const z = manual ? null : this.zombiMasCercano(a.alcance);
    const quiere = manual ? apuntado !== null : !!z;     // quiere disparar ya
    if (j.recarga > 0) {
      j.recarga -= dt;
      if (j.recarga <= 0) {
        j.recarga = 0;
        if (!a.porCartucho) j.cargador[j.arma] = a.cargador;
        else {
          j.cargador[j.arma]++;
          sonarCartucho();
          if (j.cargador[j.arma] < a.cargador && !(quiere && j.cargador[j.arma] > 0)) {
            j.recarga = j.recargaPaso = a.recarga;            // siguiente cartucho
          } else if (j.recamaraVacia) {
            j.recamaraVacia = false;                          // corredera para meter el primero en la recámara
            sonarCorredera();
            j.espera = Math.max(j.espera, a.corredera);
          }
        }
      } else if (a.porCartucho && quiere && j.cargador[j.arma] > 0 && j.recarga < j.recargaPaso - 0.05) {
        // Aparece un zombi: deja de meter cartuchos y dispara con los que ya tiene.
        j.recarga = 0;
        if (j.recamaraVacia) { j.recamaraVacia = false; sonarCorredera(); j.espera = Math.max(j.espera, a.corredera); }
      }
    }
    this.blanco = z;
    if (quiere) {
      j.sinBlanco = 0;
      j.angulo = manual ? apuntado : Math.atan2((z.y - PECHO) - (j.y - 25), z.x - j.x);
    } else {
      j.sinBlanco += dt;
      if (j.sinBlanco > 1.2 && j.cargador[j.arma] < a.cargador) this.empezarRecarga();
    }
    if (!quiere || j.recarga > 0 || j.espera > 0) return;
    if (j.cargador[j.arma] <= 0) { this.empezarRecarga(); return; }

    // ¡Fuego!
    j.cargador[j.arma]--;
    j.espera = 1 / a.cadencia;
    j.tDisparo = 0;
    const geo = this.geometriaArma();
    for (let i = 0; i < a.perdigones; i++) {
      const ang = j.angulo + (Math.random() - 0.5) * (a.dispersion * Math.PI / 180);
      const v = a.velocidadBala * rnd(0.9, 1.1);
      this.balas.push({
        x: geo.boca.x, y: geo.boca.y, px: geo.hombro.x, py: geo.hombro.y, nueva: true,
        vx: Math.cos(ang) * v, vy: Math.sin(ang) * v, vida: (a.alcance * 1.25) / v, arma: j.arma,
      });
    }
    this.stats.disparos += a.perdigones;
    this.fogonazos.push({ x: geo.boca.x, y: geo.boca.y, ang: j.angulo, t: 0 });
    // Casquillo que sale volando hacia atrás
    const lado = Math.cos(j.angulo) < 0 ? 1 : -1;
    this.particulas.push({
      x: geo.casquillo.x, y: j.y - rnd(0, 5), z: j.y - geo.casquillo.y, vx: lado * rnd(25, 55), vy: rnd(-12, 12), vz: rnd(50, 90),
      color: a.perdigones > 1 ? "#a8322a" : "#d9b24a", vida: 3, casquillo: true,
    });
    this.sacudida = Math.max(this.sacudida, a.sacudida);
    sonar(a.sonido, a.cadencia > 5 ? 0.06 : 0);
    if (j.cargador[j.arma] === 0) this.empezarRecarga();
  }

  // ------------------------------------------------------------------ zombis
  aparecerZombi(tipo) {
    const c = this.camara, m = this.mapa, def = ZOMBIS[tipo];
    let x, y;
    for (let intento = 0; intento < 12; intento++) {
      if (Math.random() < 0.7 || c.y > m.alto - this.alto - 60) {   // por arriba, fuera de la pantalla
        x = rnd(14, m.ancho - 14);
        y = c.y - rnd(20, 70);
      } else {                                                      // por un lado
        x = Math.random() < 0.5 ? c.x - 20 : c.x + this.ancho + 20;
        y = c.y + rnd(14, this.alto * 0.5);
      }
      y = Math.max(y, this.jugador.y - OLEADAS.distanciaAparicion - rnd(0, 45));
      if (y < 30) y = rnd(30, 90);
      x = Math.max(12, Math.min(m.ancho - 12, x));
      if (!chocaCon(m, x, y, def.radio + 2)) break;
    }
    const fuerza = 1 + OLEADAS.vidaExtraPorOleada * (this.oleada.n - 1);
    const spr = S[def.sprites[rndInt(0, def.sprites.length - 1)]];
    this.zombis.push({
      tipo, def, spr, x, y, vida: def.vida * fuerza, vidaMax: def.vida * fuerza,
      vel: def.velocidad * rnd(0.85, 1.15), anim: rnd(0, 2), voltear: false,
      ataque: 0, espera: rnd(0, 0.5), golpe: 0, muerto: 0, barra: 0,
      atasco: 0, desvio: 0, aparece: 0.7, lado: Math.random() < 0.5 ? 1 : -1, gruñe: rnd(2, 8),
    });
  }

  moverZombis(dt) {
    const j = this.jugador, m = this.mapa;
    const vivos = this.zombis.filter((z) => !z.muerto);
    for (const z of this.zombis) {
      z.golpe = Math.max(0, z.golpe - dt);
      z.barra = Math.max(0, z.barra - dt);
      if (z.muerto) {
        z.muerto += dt;
        if (!z.charco && z.muerto > 0.6) {
          z.charco = true;
          manchar(m.sueloCtx, z.x + (z.voltear ? -4 : 4), z.y - 2, rndInt(0, 3), 0.85);
        }
        continue;
      }
      z.anim += dt;
      z.gruñe -= dt;
      if (z.aparece > 0) { z.aparece -= dt; continue; }
      if (z.gruñe <= 0) {
        z.gruñe = rnd(4, 10);
        if (this.enPantalla(z.x, z.y, 0)) sonar("gruñido", 0.6);
      }
      const dx = j.x - z.x, dy = j.y - z.y, d = Math.hypot(dx, dy) || 1;
      z.ang = Math.atan2(dy, dx);                 // siempre miran al jugador

      // Atacar: el golpe llega al empezar el segundo fotograma de la animación
      if (z.ataque > 0) {
        const antes = z.ataque;
        z.ataque -= dt;
        const tg = orientar(z.spr, "atacar", z.ang).tag;
        const total = duracion(z.spr, tg);
        const golpeEn = total - z.spr.frames[primero(z.spr, tg)].dur;
        if (antes > golpeEn && z.ataque <= golpeEn && d <= z.def.alcance + 9 && !j.muerto) this.herirJugador(z.def.dano);
        if (z.ataque <= 0) z.espera = Math.max(0, z.def.cadencia - total);
        continue;
      }
      z.espera = Math.max(0, z.espera - dt);
      if (d <= z.def.alcance && !j.muerto) {
        if (z.espera <= 0) { z.ataque = duracion(z.spr, orientar(z.spr, "atacar", z.ang).tag); sonar("zarpazo", 0.05); }
        continue;
      }
      // Andar hacia el jugador; si se atasca, rodea el obstáculo un rato
      let ux = dx / d, uy = dy / d;
      if (j.muerto) { ux = -ux * 0.2; uy = -uy * 0.2; }
      if (z.desvio > 0) {
        z.desvio -= dt;
        const px = -uy * z.lado, py = ux * z.lado;
        ux = ux * 0.3 + px; uy = uy * 0.3 + py;
        const l = Math.hypot(ux, uy); ux /= l; uy /= l;
      }
      const ox = z.x, oy = z.y;
      z.x += ux * z.vel * dt; z.y += uy * z.vel * dt;
      // Separarse de otros zombis
      for (const o of vivos) {
        if (o === z) continue;
        const sx = z.x - o.x, sy = z.y - o.y, sd = sx * sx + sy * sy;
        const r = z.def.radio + o.def.radio;
        if (sd < r * r && sd > 1e-4) {
          const k = (r - Math.sqrt(sd)) * 0.5 / Math.sqrt(sd);
          z.x += sx * k; z.y += sy * k;
        }
      }
      // No meterse dentro del jugador
      const rj = z.def.radio + JUGADOR.radio;
      const jx = z.x - j.x, jy = z.y - j.y, jd = Math.hypot(jx, jy);
      if (jd < rj && jd > 1e-4 && !j.muerto) { z.x = j.x + (jx / jd) * rj; z.y = j.y + (jy / jd) * rj; }
      resolverChoques(m, z, z.def.radio);
      const avance = Math.hypot(z.x - ox, z.y - oy);
      if (avance < z.vel * dt * 0.3) {
        z.atasco += dt;
        if (z.atasco > 0.3 && z.desvio <= 0) { z.desvio = rnd(0.6, 1.2); z.lado = Math.random() < 0.5 ? 1 : -1; z.atasco = 0; }
      } else z.atasco = Math.max(0, z.atasco - dt);
    }
    // Los cadáveres se desvanecen
    this.zombis = this.zombis.filter((z) => !z.muerto || z.muerto < 9);
  }

  herirJugador(dano) {
    const j = this.jugador;
    j.vida = Math.max(0, j.vida - dano);
    j.golpe = 0.18;
    this.stats.recibido += dano;
    this.sacudida = Math.max(this.sacudida, 3.5);
    this.flotantes.push({ x: j.x, y: j.y - 44, t: 0, txt: "-" + dano, color: "#ff5a5a" });
    for (let i = 0; i < 4; i++) this.gota(j.x, j.y, PECHO, rnd(-40, 40), rnd(-15, 15), rnd(20, 60));
    sonar("herido", 0.08);
    vibrar(40);
    if (j.vida <= 0) {
      j.muerto = 0.0001;
      j.recarga = 0;
      sonar("muerte");
      vibrar([80, 60, 160]);
      manchar(this.mapa.sueloCtx, j.x, j.y - 2, 0, 0.9);
    }
  }

  gota(x, y, z, vx, vy, vz) {
    this.particulas.push({
      x, y: y + rnd(-3, 3), z, vx, vy, vz, vida: 6, mancha: true,
      color: Math.random() < 0.5 ? "#7a121a" : "#520c12", tam: Math.random() < 0.3 ? 2 : 1,
    });
  }

  // ------------------------------------------------------------------ balas
  moverBalas(dt) {
    for (const b of this.balas) {
      if (b.nueva) b.nueva = false;                // el primer tramo sale del hombro: no se salta a los zombis pegados
      else { b.px = b.x; b.py = b.y; }
      b.x += b.vx * dt; b.y += b.vy * dt;
      b.vida -= dt;
      if (b.vida <= 0) continue;
      let mejor = null, mt = 2, mq = null;
      for (const z of this.zombis) {
        if (z.muerto || z.aparece > 0.2) continue;
        const cx = z.x, cy = z.y - PECHO;
        const sx = b.x - b.px, sy = b.y - b.py, l2 = sx * sx + sy * sy || 1;
        const t = Math.max(0, Math.min(1, ((cx - b.px) * sx + (cy - b.py) * sy) / l2));
        const qx = b.px + sx * t, qy = b.py + sy * t;
        if ((qx - cx) ** 2 + (qy - cy) ** 2 < RADIO_CUERPO * RADIO_CUERPO && t < mt) { mejor = z; mt = t; mq = { x: qx, y: qy }; }
      }
      if (mejor) { this.impacto(mejor, b, mq.x, mq.y); b.vida = 0; }
    }
    this.balas = this.balas.filter((b) => b.vida > 0);
  }

  impacto(z, b, x, y) {
    const a = ARMAS[b.arma];
    const critico = Math.random() < a.critico;
    const dano = a.dano * (critico ? 2 : 1);
    z.vida -= dano;
    z.golpe = 0.08;
    z.barra = 2;
    const v = Math.hypot(b.vx, b.vy);
    z.x += (b.vx / v) * a.empuje; z.y += (b.vy / v) * a.empuje;
    resolverChoques(this.mapa, z, z.def.radio);
    this.stats.impactos++;
    this.stats.dano += Math.min(dano, z.vida + dano);
    this.flotantes.push({
      x: x + rnd(-4, 4), y: y - 12, t: 0, txt: String(Math.round(dano)) + (critico ? "!" : ""),
      color: critico ? "#ffd84a" : "#ffffff",
    });
    for (let i = 0; i < (critico ? 8 : 4); i++) {
      this.gota(x, z.y, z.y - y, (b.vx / v) * rnd(20, 70) + rnd(-18, 18), rnd(-12, 12), rnd(15, 70));
    }
    sonar("impacto", 0.03);
    if (z.vida <= 0) this.matarZombi(z);
  }

  matarZombi(z) {
    z.muerto = 0.0001; z.ataque = 0;
    this.stats.bajas++;
    sonar("muereZombi", 0.05);
    const [a, b] = z.def.monedas;
    for (let i = 0, n = rndInt(a, b); i < n; i++) {
      this.botin.push({ tipo: "moneda", x: z.x + rnd(-6, 6), y: z.y + rnd(-4, 4), z: 10, vz: rnd(45, 90), vx: rnd(-38, 38), vy: rnd(-22, 22), t: 0, anim: rnd(0, 1) });
    }
    if (Math.random() < BOTIN.botiquin) {
      this.botin.push({ tipo: "botiquin", x: z.x, y: z.y, z: 10, vz: 75, vx: 0, vy: 0, t: 0, anim: 0 });
    }
  }

  moverBotin(dt) {
    const j = this.jugador;
    for (const o of this.botin) {
      o.t += dt; o.anim += dt;
      if (o.z > 0 || o.vz > 0) {                     // cae rebotando
        o.vz -= 330 * dt; o.z += o.vz * dt;
        o.x += o.vx * dt; o.y += o.vy * dt;
        if (o.z <= 0) { o.z = 0; o.vz = o.vz < -45 ? -o.vz * 0.35 : 0; o.vx *= 0.5; o.vy *= 0.5; }
      }
      if (j.muerto) continue;
      const dx = j.x - o.x, dy = j.y - 8 - o.y, d = Math.hypot(dx, dy) || 1;
      const iman = o.tipo === "moneda" ? JUGADOR.recogerMonedas : 15;
      if (d < iman && o.t > 0.35) {
        const v = 240 * (1 - d / (iman + 1)) + 60;
        o.x += (dx / d) * v * dt; o.y += (dy / d) * v * dt;
      }
      if (d < 9 && o.t > 0.35) {
        if (o.tipo === "moneda") { this.stats.monedas++; sonar("moneda", 0.03); }
        else if (o.tipo === "botiquin") {
          if (j.vida >= JUGADOR.vida) continue;
          const antes = j.vida;
          j.vida = Math.min(JUGADOR.vida, j.vida + BOTIN.curaBotiquin);
          this.flotantes.push({ x: j.x, y: j.y - 48, t: 0, txt: "+" + Math.round(j.vida - antes), color: "#7ee07e" });
          sonar("curar");
        }
        o.recogido = true;
      }
    }
    this.botin = this.botin.filter((o) => !o.recogido && o.t < BOTIN.duracionEnSuelo);
  }

  moverEfectos(dt) {
    for (const p of this.particulas) {
      p.vida -= dt;
      if (p.z > 0 || p.vz > 0) {
        p.vz -= 390 * dt; p.z += p.vz * dt;
        p.x += p.vx * dt; p.y += p.vy * dt;
        if (p.z <= 0) {
          p.z = 0; p.vz = 0;
          if (p.mancha) {                              // la gota se queda pintada en el suelo
            const g = this.mapa.sueloCtx;
            g.fillStyle = p.color; g.fillRect(Math.round(p.x), Math.round(p.y), p.tam, 1);
            p.vida = 0;
          }
        }
      }
    }
    this.particulas = this.particulas.filter((p) => p.vida > 0);
    for (const f of this.fogonazos) f.t += dt;
    const durFogonazo = duracion(S.fogonazo, "") || S.fogonazo.frames.reduce((s, f) => s + f.dur, 0);
    this.fogonazos = this.fogonazos.filter((f) => f.t < durFogonazo);
    for (const f of this.flotantes) f.t += dt;
    this.flotantes = this.flotantes.filter((f) => f.t < 0.8);
    this.sacudida = Math.max(0, this.sacudida - dt * 14);
  }

  // ------------------------------------------------------------------ oleadas
  oleadas(dt) {
    const o = this.oleada;
    o.cartel = Math.max(0, o.cartel - dt);
    o.superada = Math.max(0, o.superada - dt);
    if (this.jugador.muerto) return;
    if (o.descanso > 0) {
      o.descanso -= dt;
      if (o.descanso <= 0) {
        o.n++;
        o.porSalir = OLEADAS.zombisBase + OLEADAS.zombisPorOleada * (o.n - 1);
        o.t = 0.5;
        o.cartel = 2.2;
        o.superada = 0;
        sonar("oleada");
      }
      return;
    }
    const vivos = this.zombis.filter((z) => !z.muerto).length;
    if (o.porSalir > 0) {
      o.t -= dt;
      if (o.t <= 0 && vivos < OLEADAS.maximoVivos) {
        const prop = o.n >= OLEADAS.corredoresDesde
          ? Math.min(0.45, OLEADAS.corredoresPorOleada * (o.n - OLEADAS.corredoresDesde + 1)) : 0;
        this.aparecerZombi(Math.random() < prop ? "corredor" : "normal");
        o.porSalir--;
        o.t = Math.max(OLEADAS.intervaloMinimo, OLEADAS.intervaloBase * Math.pow(0.88, o.n - 1)) * rnd(0.6, 1.4);
      }
    } else if (vivos === 0) {
      o.descanso = OLEADAS.descanso;
      o.superada = 2;
    }
  }

  // ------------------------------------------------------------------ cámara
  moverCamara(dt) {
    const j = this.jugador, c = this.camara, m = this.mapa;
    const ox = j.x - this.ancho / 2;
    const oy = j.y - this.alto * ALTURA_JUGADOR;  // se ve más por delante (arriba), de donde vienen
    const k = 1 - Math.exp(-dt * 6);
    c.x += (ox - c.x) * k; c.y += (oy - c.y) * k;
    c.x = Math.max(0, Math.min(m.ancho - this.ancho, c.x));
    c.y = Math.max(0, Math.min(m.alto - this.alto, c.y));
    if (m.ancho < this.ancho) c.x = (m.ancho - this.ancho) / 2;
  }

  enPantalla(x, y, margen = 30) {
    const c = this.camara;
    return x > c.x - margen && x < c.x + this.ancho + margen && y > c.y - margen && y < c.y + this.alto + margen + 50;
  }

  // ------------------------------------------------------------------ dibujar
  dibujar(g) {
    const c = this.camara, j = this.jugador;
    g.fillStyle = "#0e0d12";
    g.fillRect(0, 0, this.ancho, this.alto);
    const sx = this.sacudida > 0 ? Math.round(rnd(-1, 1) * this.sacudida) : 0;
    const sy = this.sacudida > 0 ? Math.round(rnd(-1, 1) * this.sacudida) : 0;
    const cx = Math.round(c.x) - sx, cy = Math.round(c.y) - sy;
    g.save();
    g.translate(-cx, -cy);

    // Suelo
    g.drawImage(this.mapa.suelo, cx, cy, this.ancho, this.alto, cx, cy, this.ancho, this.alto);

    // Cadáveres debajo de todo
    for (const z of this.zombis) if (z.muerto && this.enPantalla(z.x, z.y)) this.dibujarZombi(g, z);

    // Sombras en el suelo
    g.fillStyle = "rgba(8,7,14,0.38)";
    const sombra = (x, y, rx, ry = rx * 0.38) => { g.beginPath(); g.ellipse(Math.round(x), Math.round(y), rx, ry, 0, 0, Math.PI * 2); g.fill(); };
    if (!j.muerto) sombra(j.x + 1, j.y, 8);
    for (const z of this.zombis) if (!z.muerto && z.aparece <= 0 && this.enPantalla(z.x, z.y)) sombra(z.x + 1, z.y, 8);
    for (const o of this.mapa.objetos) {
      if (!this.enPantalla(o.x, o.y, 60)) continue;
      if (o.tipo === "arbol") sombra(o.x + 5, o.y - 1, 17, 6);
      else if (o.tipo === "coche") sombra(o.x + 3, o.y - 24, 21, 29);
      else if (o.tipo === "barril" || o.tipo === "hoguera" || o.tipo === "neumaticos") sombra(o.x + 2, o.y - 1, 9);
      else if (o.tipo === "caja" || o.tipo === "contenedor" || o.tipo === "barrera" || o.tipo === "sacos") sombra(o.x + 3, o.y - 2, S[o.tipo].w * 0.52, 6);
      else if (o.tipo === "arbusto") sombra(o.x + 2, o.y - 1, 11, 4);
      else if (o.tipo === "farola" || o.tipo === "cono") sombra(o.x + 1, o.y, 5, 2);
    }
    for (const o of this.botin) if (this.enPantalla(o.x, o.y)) sombra(o.x, o.y, 4, 1.5);

    // Todo lo que está de pie, ordenado por la y de los pies
    const cosas = [];
    for (const o of this.mapa.objetos) if (this.enPantalla(o.x, o.y, 70)) cosas.push({ y: o.y, f: () => this.dibujarObjeto(g, o) });
    for (const z of this.zombis) if (!z.muerto && this.enPantalla(z.x, z.y)) cosas.push({ y: z.y, f: () => this.dibujarZombi(g, z) });
    for (const o of this.botin) cosas.push({ y: o.y - 0.5, f: () => this.dibujarBotin(g, o) });
    cosas.push({ y: j.y, f: () => this.dibujarJugador(g) });
    cosas.sort((a, b) => a.y - b.y);
    for (const k of cosas) k.f();

    // Balas (trazas), fogonazos, partículas
    g.lineWidth = 1;
    for (const b of this.balas) {
      const v = Math.hypot(b.vx, b.vy), l = 7;
      g.strokeStyle = "#fff1a8";
      g.beginPath();
      g.moveTo(Math.round(b.x) + 0.5, Math.round(b.y) + 0.5);
      g.lineTo(Math.round(b.x - (b.vx / v) * l) + 0.5, Math.round(b.y - (b.vy / v) * l) + 0.5);
      g.stroke();
      g.strokeStyle = "rgba(255,201,58,0.5)";
      g.beginPath();
      g.moveTo(Math.round(b.x - (b.vx / v) * l) + 0.5, Math.round(b.y - (b.vy / v) * l) + 0.5);
      g.lineTo(Math.round(b.x - (b.vx / v) * l * 2) + 0.5, Math.round(b.y - (b.vy / v) * l * 2) + 0.5);
      g.stroke();
    }
    const fg = S.fogonazo, og = punto(fg, "origen", 0, { x: 1, y: 7 });
    for (const f of this.fogonazos) {
      let i = 0, t = f.t;
      while (i < fg.frames.length - 1 && t >= fg.frames[i].dur) { t -= fg.frames[i].dur; i++; }
      g.save();
      g.translate(Math.round(f.x) + 0.5, Math.round(f.y) + 0.5);
      g.rotate(f.ang);
      const fr = fg.frames[i];
      g.drawImage(fg.img, fr.x, fr.y, fr.w, fr.h, -og.x - 0.5, -og.y - 0.5, fr.w, fr.h);
      g.restore();
    }
    for (const p of this.particulas) {
      g.globalAlpha = p.casquillo && p.vida < 0.5 ? p.vida * 2 : 1;
      g.fillStyle = p.color;
      g.fillRect(Math.round(p.x), Math.round(p.y - p.z), p.casquillo ? 2 : (p.tam || 1), 1);
    }
    g.globalAlpha = 1;
    g.restore();

    // Oscuridad del atardecer: las farolas, el fuego y los disparos iluminan
    this.dibujarLuces(g, cx, cy);

    // Barras de vida de zombis heridos y números de daño (encima de la oscuridad, para que se lean)
    g.save();
    g.translate(-cx, -cy);
    for (const z of this.zombis) {
      if (z.muerto || z.barra <= 0 || z.vida >= z.vidaMax) continue;
      const w = 16, x = Math.round(z.x - w / 2), y = Math.round(z.y - 44);
      g.fillStyle = "#0e0d12"; g.fillRect(x - 1, y - 1, w + 2, 5);
      g.fillStyle = "#520c12"; g.fillRect(x, y, w, 3);
      g.fillStyle = "#e0403a"; g.fillRect(x, y, Math.max(1, Math.round(w * z.vida / z.vidaMax)), 3);
    }
    for (const f of this.flotantes) {
      g.globalAlpha = f.t > 0.55 ? 1 - (f.t - 0.55) / 0.25 : 1;
      texto(g, f.txt, f.x, f.y - f.t * 26, f.color, "centro");
    }
    g.globalAlpha = 1;
    g.restore();

  }

  dibujarLuces(g, cx, cy) {
    const osc = PANTALLA.oscuridad;
    if (!osc) return;
    const W = this.ancho, H = this.alto;
    if (!this.capaLuz || this.capaLuz.width !== W || this.capaLuz.height !== H) {
      this.capaLuz = document.createElement("canvas");
      this.capaLuz.width = W; this.capaLuz.height = H;
    }
    const l = this.capaLuz.getContext("2d");
    l.globalCompositeOperation = "source-over";
    l.clearRect(0, 0, W, H);
    l.fillStyle = `rgba(6,8,22,${osc})`;
    l.fillRect(0, 0, W, H);
    l.globalCompositeOperation = "destination-out";
    const focos = [];
    const foco = (x, y, r, fuerza, color) => {
      x -= cx; y -= cy;
      if (x < -r || y < -r || x > W + r || y > H + r) return;
      const gr = l.createRadialGradient(x, y, 0, x, y, r);
      gr.addColorStop(0, `rgba(0,0,0,${fuerza})`);
      gr.addColorStop(0.55, `rgba(0,0,0,${fuerza * 0.55})`);
      gr.addColorStop(1, "rgba(0,0,0,0)");
      l.fillStyle = gr;
      l.fillRect(x - r, y - r, 2 * r, 2 * r);
      if (color) focos.push({ x, y, r, color });
    };
    for (const z of this.mapa.luces) {
      if (z.fuego) foco(z.x, z.y, z.r * (1 + 0.07 * Math.sin(this.t * 11 + z.x)), 1, "255,150,60");
      else foco(z.x, z.y, z.r, 0.95, "255,214,140");
    }
    const j = this.jugador;
    foco(j.x, j.y - 16, 76, 0.5);
    for (const f of this.fogonazos) foco(f.x, f.y, 64, 1, "255,200,110");
    g.drawImage(this.capaLuz, 0, 0);
    // Tinte cálido de las luces
    g.globalCompositeOperation = "lighter";
    for (const f of focos) {
      const gr = g.createRadialGradient(f.x, f.y, 0, f.x, f.y, f.r * 0.8);
      gr.addColorStop(0, `rgba(${f.color},0.16)`);
      gr.addColorStop(1, `rgba(${f.color},0)`);
      g.fillStyle = gr;
      g.fillRect(f.x - f.r, f.y - f.r, 2 * f.r, 2 * f.r);
    }
    g.globalCompositeOperation = "source-over";
  }

  dibujarJugador(g) {
    const j = this.jugador, spr = S.jugador;
    const i = this.cuadroJugador();
    const pies = punto(spr, "pies", i, PIES);
    if (j.muerto) {
      dibujarAnclado(g, spr, i, j.x, j.y, pies, j.voltear);
      return;
    }
    const destello = j.golpe > 0 ? (Math.floor(j.golpe * 30) % 2 ? "roja" : "blanca") : "img";
    // De espaldas (n, ne, nw) los brazos con el arma quedan detrás del cuerpo
    const detras = j.dir === "n" || j.dir === "ne";
    if (detras) this.dibujarBrazos(g, destello);
    dibujarAnclado(g, spr, i, j.x, j.y, pies, j.voltear, spr[destello]);
    if (!detras) this.dibujarBrazos(g, destello);
  }

  // Brazos con el arma, girados alrededor del hombro hacia donde apunta
  dibujarBrazos(g, destello) {
    const j = this.jugador, a = ARMAS[j.arma], br = S["brazos_" + j.arma];
    const geo = this.geometriaArma();
    let fi = primero(br, "apuntar");
    if (j.recarga > 0) fi = fotogramaPorAvance(br, "recargar", 1 - j.recarga / (j.recargaPaso || a.recarga));
    else if (j.tDisparo < duracion(br, "disparar")) fi = fotograma(br, "disparar", j.tDisparo, false);
    const f = br.frames[fi];
    g.save();
    g.translate(geo.hombro.x + 0.5, geo.hombro.y + 0.5);
    g.rotate(j.angulo);
    if (geo.izq) g.scale(1, -1);
    g.drawImage(br[destello], f.x, f.y, f.w, f.h, -geo.hb.x - 0.5, -geo.hb.y - 0.5, f.w, f.h);
    g.restore();
  }

  dibujarZombi(g, z) {
    const spr = z.spr;
    if (z.muerto) {
      const i = fotograma(spr, "morir", z.muerto, false);
      if (z.muerto > 7) g.globalAlpha = Math.max(0, 1 - (z.muerto - 7) / 2);
      dibujarAnclado(g, spr, i, z.x, z.y, punto(spr, "pies", i, PIES), z.voltear);
      g.globalAlpha = 1;
      return;
    }
    let i;
    const o = orientar(spr, z.ataque > 0 ? "atacar" : "andar", z.ang ?? 0);
    z.voltear = o.voltear;
    if (z.ataque > 0) i = fotograma(spr, o.tag, duracion(spr, o.tag) - z.ataque, false);
    else i = fotograma(spr, o.tag, z.anim * (z.vel / z.def.velocidad));
    const pies = punto(spr, "pies", i, PIES);
    if (z.aparece > 0) {                 // sale de la tierra
      const k = 1 - z.aparece / 0.7, alto = Math.round(38 * k);
      g.save();
      g.beginPath(); g.rect(Math.round(z.x) - 22, Math.round(z.y) - alto, 44, alto); g.clip();
      dibujarAnclado(g, spr, i, z.x, z.y + (38 - alto) * 0.45, pies, z.voltear);
      g.restore();
      g.fillStyle = "#40301f"; g.fillRect(Math.round(z.x) - 8, Math.round(z.y) - 2, 16, 3);
      g.fillStyle = "#594430"; g.fillRect(Math.round(z.x) - 6, Math.round(z.y) - 3, 5, 1); g.fillRect(Math.round(z.x) + 2, Math.round(z.y) - 3, 4, 1);
      return;
    }
    dibujarAnclado(g, spr, i, z.x, z.y, pies, z.voltear, z.golpe > 0 ? spr.blanca : spr.img);
  }

  dibujarObjeto(g, o) {
    const spr = S[o.tipo];
    const i = o.tipo === "hoguera" ? fotograma(spr, "arder", this.t + o.t0) : o.f;
    dibujar(g, spr, i, o.x - o.base.x, o.y - o.base.y);
  }

  dibujarBotin(g, o) {
    const spr = S[o.tipo];
    if (o.t > BOTIN.duracionEnSuelo - 3 && Math.floor(o.t * 8) % 2) return;   // parpadea antes de irse
    const i = o.tipo === "moneda" ? fotograma(spr, "girar", o.anim) : 0;
    const flota = o.tipo === "botiquin" && o.z === 0 ? Math.round(Math.sin(o.t * 4)) : 0;
    dibujar(g, spr, i, o.x - spr.w / 2, o.y - spr.h - o.z + flota);
  }

  // ------------------------------------------------------------------ interfaz
  // La interfaz se dibuja dentro de la zona segura (sin la muesca ni la barra de inicio del iPhone);
  // el juego en sí ocupa toda la pantalla.
  boton(x, y, w, h, accion) { entrada.botones.push({ x: x + this.seguro.izq, y: y + this.seguro.arr, w, h, accion }); }

  get uiW() { return this.pantW - this.seguro.izq - this.seguro.der; }
  get uiH() { return this.pantH - this.seguro.arr - this.seguro.aba; }

  // Se dibuja en su propio lienzo transparente, encima del mundo y a otra escala (el mundo lleva zoom).
  dibujarInterfaz(g) {
    const j = this.jugador;
    // Pantalla roja al recibir daño y borde rojo cuando queda poca vida
    if (j.golpe > 0) {
      g.fillStyle = `rgba(200,20,30,${j.golpe * 1.4})`;
      g.fillRect(0, 0, this.pantW, this.pantH);
    }
    if (!j.muerto && j.vida <= 30) {
      const a = 0.2 + 0.14 * Math.sin(this.t * 6);
      g.strokeStyle = `rgba(184,31,38,${a})`;
      g.lineWidth = 10;
      g.strokeRect(0, 0, this.pantW, this.pantH);
    }
    g.save();
    g.translate(this.seguro.izq, this.seguro.arr);
    this.dibujarInterfazSegura(g);
    g.restore();
  }

  dibujarInterfazSegura(g) {
    const W = this.uiW, H = this.uiH, j = this.jugador;

    if (this.estado === "inicio") return this.pantallaInicio(g);

    // Vida
    dibujar(g, S.corazon, 0, 5, 5);
    const bw = 84;
    g.fillStyle = "#0e0d12"; g.fillRect(20, 5, bw + 2, 10);
    g.fillStyle = "#3d0f12"; g.fillRect(21, 6, bw, 8);
    const pv = j.vida / JUGADOR.vida;
    g.fillStyle = pv > 0.5 ? "#5f9c44" : pv > 0.25 ? "#d9a233" : "#e0403a";
    g.fillRect(21, 6, Math.round(bw * pv), 8);
    g.fillStyle = "rgba(255,255,255,0.3)"; g.fillRect(21, 6, Math.round(bw * pv), 2);
    texto(g, Math.ceil(j.vida), 21 + bw + 5, 5);

    // Bajas, oleada y monedas
    const o = this.oleada;
    texto(g, t("bajas") + " " + this.stats.bajas, 5, 21, "#d1cec0");
    texto(g, t("oleada") + " " + Math.max(1, o.n), W / 2, 21, "#f2c84a", "centro");
    // Pausa: botón grande arriba a la derecha y zona tocable aún más grande alrededor
    const pw = 30, ph = 28, bx = W - pw - 4, by = 3;
    g.fillStyle = "#0e0d12"; g.fillRect(bx, by, pw, ph);
    g.fillStyle = "#34363d"; g.fillRect(bx + 1, by + 1, pw - 2, ph - 2);
    g.fillStyle = "rgba(255,255,255,0.18)"; g.fillRect(bx + 1, by + 1, pw - 2, 2);
    g.fillStyle = "#d1cec0"; g.fillRect(bx + 9, by + 7, 4, 14); g.fillRect(bx + 17, by + 7, 4, 14);
    this.boton(bx - 14, 0, pw + 18, ph + 16, () => { sonar("boton"); this.pausar(); });

    // Monedas, a la izquierda del botón de pausa
    const txtM = String(this.stats.monedas);
    texto(g, txtM, bx - 8, by + 9, "#f2c84a", "der");
    dibujar(g, S.moneda, 0, bx - 8 - anchoTexto(txtM) - 13, by + 9);

    // Armas (abajo a la derecha; en disparo manual, abajo en el centro porque ahí va el joystick de apuntar).
    // De momento se pueden elegir todas para probarlas.
    const manual = this.disparo === "manual";
    const slotW = 40, slotH = 24, gap = 3, totalW = (slotW + gap) * ORDEN_ARMAS.length - gap;
    const x0 = manual ? Math.round(W / 2 - totalW / 2) : W - totalW - 5, y0 = H - slotH - 8;
    const xDer = x0 + totalW;                         // borde derecho de las armas (para la munición)
    ORDEN_ARMAS.forEach((nombre, k) => {
      const x = x0 + k * (slotW + gap), sel = nombre === j.arma;
      g.fillStyle = "#0e0d12"; g.fillRect(x, y0, slotW, slotH);
      g.fillStyle = sel ? "#3b526b" : "#26252e"; g.fillRect(x + 1, y0 + 1, slotW - 2, slotH - 2);
      if (sel) { g.fillStyle = "#f2c84a"; g.fillRect(x + 1, y0 + 1, slotW - 2, 2); }
      const spr = S[nombre];
      g.globalAlpha = sel ? 1 : 0.7;
      dibujar(g, spr, 0, x + Math.floor((slotW - spr.w) / 2), y0 + 1 + Math.floor((slotH - spr.h) / 2));
      g.globalAlpha = 1;
      this.boton(x - 1, y0 - 6, slotW + 2, slotH + 14, () => this.cambiarArma(nombre));
    });
    // Munición y recarga encima de las armas
    const a = ARMAS[j.arma];
    const yMun = y0 - 14;
    if (j.recarga > 0) {
      const w = 56, x = xDer - w;
      g.fillStyle = "#0e0d12"; g.fillRect(x - 1, yMun + 1, w + 2, 8);
      const avance = 1 - j.recarga / (j.recargaPaso || a.recarga);
      const lleno = a.porCartucho ? (j.cargador[j.arma] + avance) / a.cargador : avance;
      g.fillStyle = "#d9a233"; g.fillRect(x, yMun + 2, Math.round(w * Math.min(1, lleno)), 6);
      if (a.porCartucho) {                            // una muesca por cartucho
        g.fillStyle = "#0e0d12";
        for (let k = 1; k < a.cargador; k++) g.fillRect(x + Math.round(w * k / a.cargador), yMun + 2, 1, 6);
      }
      texto(g, t("recargando") + (a.porCartucho ? " " + j.cargador[j.arma] + "/" + a.cargador : ""), x - 5, yMun, "#ffffff", "der");
    } else {
      const quedan = j.cargador[j.arma];
      texto(g, t(j.arma) + "  " + quedan + "/" + a.cargador, xDer, yMun, quedan === 0 ? "#ff5a5a" : "#ffffff", "der");
    }

    // Joystick fijo abajo a la izquierda (siempre visible mientras se juega)
    const st = entrada.stick, js = S.joystick, mitad = Math.floor(js.w / 2);
    const iBase = primero(js, "base"), iBoton = primero(js, "boton");
    const base = { x: PANTALLA.joystick.x, y: H - PANTALLA.joystick.y };
    entrada.base = { x: base.x + this.seguro.izq, y: base.y + this.seguro.arr }; entrada.ancho = this.pantW;
    if (this.estado === "jugando" && !j.muerto) {
      let dx = 0, dy = 0;
      if (st) {
        dx = st.x - entrada.base.x; dy = st.y - entrada.base.y;
        const l = Math.hypot(dx, dy);
        if (l > RADIO_STICK) { dx = dx / l * RADIO_STICK; dy = dy / l * RADIO_STICK; }
      } else if (entrada.mx || entrada.my) {     // con teclado también se ve moverse
        dx = entrada.mx * RADIO_STICK; dy = entrada.my * RADIO_STICK;
      }
      g.globalAlpha = st ? 0.75 : 0.5;
      dibujar(g, js, iBase, base.x - mitad, base.y - mitad);
      g.globalAlpha = st ? 0.95 : 0.7;
      dibujar(g, js, iBoton, Math.round(base.x + dx) - mitad, Math.round(base.y + dy) - mitad);
      g.globalAlpha = 1;
      if (this.t < 6) {
        g.globalAlpha = Math.min(1, (6 - this.t) / 1.5);
        texto(g, t("muevete"), base.x - mitad, base.y - mitad - 14);
        g.globalAlpha = 1;
      }
    }

    // Joystick de apuntar, abajo a la derecha (solo en disparo manual)
    const baseA = { x: W - PANTALLA.joystick.x, y: H - PANTALLA.joystick.y };
    entrada.baseApunta = { x: baseA.x + this.seguro.izq, y: baseA.y + this.seguro.arr };
    if (manual && this.estado === "jugando" && !j.muerto) {
      const ap = entrada.apunta;
      let dx = 0, dy = 0;
      if (ap) {
        dx = ap.x - entrada.baseApunta.x; dy = ap.y - entrada.baseApunta.y;
        const l = Math.hypot(dx, dy);
        if (l > RADIO_STICK) { dx = dx / l * RADIO_STICK; dy = dy / l * RADIO_STICK; }
      }
      g.globalAlpha = ap ? 0.75 : 0.5;
      dibujar(g, js, iBase, baseA.x - mitad, baseA.y - mitad);
      g.globalAlpha = ap ? 0.95 : 0.7;
      const kx = Math.round(baseA.x + dx), ky = Math.round(baseA.y + dy);
      dibujar(g, js, iBoton, kx - mitad, ky - mitad);
      // Mira roja en el botón para distinguirlo del de moverse
      g.fillStyle = "#e0403a";
      g.fillRect(kx - 4, ky, 3, 1); g.fillRect(kx + 2, ky, 3, 1); g.fillRect(kx, ky - 4, 1, 3); g.fillRect(kx, ky + 2, 1, 3);
      g.globalAlpha = 1;
      if (this.t < 6) {
        g.globalAlpha = Math.min(1, (6 - this.t) / 1.5);
        texto(g, t("apunta"), baseA.x + mitad, baseA.y - mitad - 14, "#ffffff", "der");
        g.globalAlpha = 1;
      }
    }

    // Carteles
    if (this.estado !== "jugando") { /* sin carteles detrás de los menús */ }
    else if (o.cartel > 0) {
      g.globalAlpha = Math.min(1, o.cartel * 2);
      texto(g, t("oleada") + " " + o.n, W / 2, H * 0.3, "#f2c84a", "centro", 3);
      g.globalAlpha = 1;
    } else if (o.superada > 0) {
      texto(g, t("oleadaSuperada"), W / 2, H * 0.3, "#7ee07e", "centro", 2);
    }

    if (this.estado === "pausa") this.pantallaPausa(g);
    if (this.estado === "fin") this.pantallaFin(g);
  }

  velo(g, a = 0.65) {
    g.fillStyle = `rgba(10,9,16,${a})`;
    g.fillRect(-this.seguro.izq, -this.seguro.arr, this.pantW, this.pantH);
  }

  // Sin x ni ancho, centrado y del ancho del texto.
  botonGrande(g, txt, y, accion, color = "#3b526b", x = null, w = null) {
    w ??= Math.max(150, anchoTexto(txt, 2) + 24);
    x ??= Math.round(this.uiW / 2 - w / 2);
    const h = 30;
    y = Math.round(y);
    g.fillStyle = "#0e0d12"; g.fillRect(x, y, w, h);
    g.fillStyle = color; g.fillRect(x + 1, y + 1, w - 2, h - 2);
    g.fillStyle = "rgba(255,255,255,0.22)"; g.fillRect(x + 1, y + 1, w - 2, 2);
    g.fillStyle = "rgba(0,0,0,0.25)"; g.fillRect(x + 1, y + h - 4, w - 2, 3);
    texto(g, txt, x + w / 2, y + 5, "#ffffff", "centro", 2);
    this.boton(x, y, w, h, accion);
  }

  pantallaInicio(g) {
    const W = this.uiW, H = this.uiH;
    this.velo(g, 0.5);
    const tit = S.titulo;
    dibujar(g, tit, 0, Math.round(W / 2 - tit.w / 2), Math.round(H * 0.06));
    // El superviviente y un zombi, a doble tamaño
    const ahora = performance.now() / 1000;
    const jug = S.jugador, br = S.brazos_pistola, z = S.zombi;
    const ij = fotograma(jug, orientar(jug, "quieto", 0).tag, ahora), h = punto(jug, "hombro", ij, HOMBRO), hb = punto(br, "hombro", 0, { x: 8, y: 10 });
    g.save();
    g.translate(Math.round(W / 2 - 78), Math.round(H * 0.29)); g.scale(2, 2);
    dibujar(g, jug, ij, 0, 0);
    dibujar(g, br, primero(br, "apuntar"), h.x - hb.x, h.y - hb.y);
    g.restore();
    g.save();
    g.translate(Math.round(W / 2 + 2), Math.round(H * 0.29)); g.scale(2, 2);
    dibujar(g, z, fotograma(z, orientar(z, "andar", 0).tag, ahora), 0, 0, true);
    g.restore();
    if (Math.floor(ahora * 2) % 2 === 0) texto(g, t("tocaEmpezar"), W / 2, H * 0.63, "#ffffff", "centro", 2);
    texto(g, t("ayudaMover"), W / 2, H * 0.77, "#d1cec0", "centro");
    texto(g, t(this.disparo === "manual" ? "ayudaManual" : "ayudaDisparo"), W / 2, H * 0.77 + 13, "#d1cec0", "centro");
    texto(g, t("prototipo") + " 0.4", W / 2, H - 16, "#85837a", "centro");
    this.boton(0, 0, W, H, () => this.empezar());
    this.selectorIdioma(g, W - 6 - this.anchoSelector(), 6);
  }

  // Dos banderas para elegir idioma (España = español, EE. UU. = inglés); la activa, resaltada.
  // (x, y) es la esquina superior izquierda; devuelve el ancho total.
  selectorIdioma(g, x, y, k = 1) {
    const b = S.banderas, w = b.w * k + 6, h = b.h * k + 6, gap = 4 * k;
    [["es", 0], ["en", 1]].forEach(([cod, f], i) => {
      const bx = x + i * (w + gap), sel = idioma() === cod;
      g.fillStyle = sel ? "#f2c84a" : "#0e0d12"; g.fillRect(bx, y, w, h);
      g.fillStyle = sel ? "#3b526b" : "#26252e"; g.fillRect(bx + 1, y + 1, w - 2, h - 2);
      g.globalAlpha = sel ? 1 : 0.45;
      g.save(); g.translate(bx + 3, y + 3); g.scale(k, k);
      dibujar(g, b, f, 0, 0);
      g.restore();
      g.globalAlpha = 1;
      this.boton(bx - 2, y - 4, w + 4, h + 8, () => { if (!sel) { cambiarIdioma(cod); sonar("boton"); } });
    });
    return 2 * w + gap;
  }

  anchoSelector(k = 1) { return 2 * (S.banderas.w * k + 6) + 4 * k; }

  // Cerca, media, lejos: cambia el zoom del mundo (main.js recalcula los lienzos).
  cambiarZoom() {
    this.zoom = ZOOMS[(ZOOMS.indexOf(this.zoom) + 1) % ZOOMS.length];
    try { localStorage.setItem(CLAVE_ZOOM, this.zoom); } catch (e) { /* no pasa nada si no se guarda */ }
    this.alCambiarCamara?.();
    this.moverCamara(1);
  }

  // Automático o manual (joystick de apuntar abajo a la derecha).
  cambiarDisparo() {
    this.disparo = this.disparo === "auto" ? "manual" : "auto";
    entrada.manual = this.disparo === "manual";
    entrada.apunta = null;
    try { localStorage.setItem(CLAVE_DISPARO, this.disparo); } catch (e) { /* no pasa nada si no se guarda */ }
  }

  pantallaPausa(g) {
    const W = this.uiW, H = this.uiH;
    this.velo(g);
    texto(g, t("pausa"), W / 2, H * 0.1, "#ffffff", "centro", 3);
    this.botonGrande(g, t("seguir"), H * 0.24, () => { sonar("boton"); this.pausar(); });
    // Sonido y cámara, uno al lado del otro
    const txtS = t(silenciado() ? "sonidoNo" : "sonidoSi"), txtC = t("camara") + ": " + t("zoom_" + this.zoom);
    const bw = Math.max(anchoTexto("SONIDO: NO", 2), anchoTexto(txtC, 2), anchoTexto(txtS, 2)) + 24, gap = 8;
    const x0 = Math.round(W / 2 - bw - gap / 2);
    this.botonGrande(g, txtS, H * 0.24 + 38, () => { silenciar(!silenciado()); sonar("boton"); }, "#34363d", x0, bw);
    this.botonGrande(g, txtC, H * 0.24 + 38, () => { this.cambiarZoom(); sonar("boton"); }, "#34363d", x0 + bw + gap, bw);
    // Modo de disparo e idioma, uno al lado del otro
    const txtD = t("disparo") + ": " + t("disparo_" + this.disparo);
    const dw = Math.max(anchoTexto(t("disparo") + ": " + t("disparo_manual"), 2), anchoTexto(t("disparo") + ": " + t("disparo_auto"), 2)) + 24;
    const sw = this.anchoSelector(2), x1 = Math.round(W / 2 - (dw + gap + sw) / 2);
    this.botonGrande(g, txtD, H * 0.24 + 76, () => { this.cambiarDisparo(); sonar("boton"); }, "#34363d", x1, dw);
    this.selectorIdioma(g, x1 + dw + gap, Math.round(H * 0.24 + 72), 2);
    this.botonGrande(g, t("reiniciar"), H * 0.24 + 122, () => this.empezar(), "#872a26");
  }

  pantallaFin(g) {
    const W = this.uiW, H = this.uiH, s = this.stats;
    this.velo(g, 0.72);
    texto(g, t("hasMuerto"), W / 2, H * 0.06, "#e0403a", "centro", 3);
    const filas = [
      [t("oleada"), this.oleada.n],
      [t("bajas"), s.bajas],
      [t("monedas"), s.monedas],
      [t("tiempo"), Math.floor(s.tiempo / 60) + ":" + String(Math.floor(s.tiempo % 60)).padStart(2, "0")],
      [t("punteria"), (s.disparos ? Math.round(100 * s.impactos / s.disparos) : 0) + "%"],
      [t("danoHecho"), Math.round(s.dano)],
      [t("danoRecibido"), Math.round(s.recibido)],
    ];
    filas.forEach(([k, v], i) => {
      const y = H * 0.2 + i * 14;
      texto(g, k, W / 2 - 84, y, "#d1cec0");
      texto(g, v, W / 2 + 84, y, "#f2c84a", "der");
    });
    this.botonGrande(g, t("otraVez"), H * 0.2 + filas.length * 14 + 10, () => this.empezar(), "#4a6a34");
  }
}
