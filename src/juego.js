// Partida: jugador, zombis, balas, botín, oleadas, cámara, luces, interfaz.
import { PANTALLA, JUGADOR, ARMAS, ARMAS_FUEGO, CUERPO, LANZABLES, FUEGO, ZOMBIS, OLEADAS, BOTIN, BASE, MUNICION, MEJORAS, PRECIOS } from "./config.js";
import { S, punto, fotograma, fotogramaPorAvance, duracion, primero, dibujar, dibujarAnclado, texto, anchoTexto } from "./sprites.js";
import { crearMapa, manchar, resolverChoques, chocaCon } from "./mapa.js";
import { entrada, leerMovimiento, leerApuntado, RADIO_STICK } from "./entrada.js";
import { sonar, sonarRecarga, sonarCartucho, sonarCorredera, cancelarRecarga, desbloquear, silenciar, silenciado } from "./audio.js";
import { pantallaCompletaHorizontal } from "./pantalla.js";
import { crearRagdoll, moverRagdoll, dibujarRagdoll, asentado } from "./ragdoll.js";
import { crearBase, chocarMuro, tramoTocado, huecoCercano, dentro, dibujarTramo, dibujarAlambre, dibujarTienda } from "./base.js";
import { pantallaTienda } from "./tienda.js";
import { t, idioma, cambiarIdioma } from "./idioma.js";

const ORDEN_ARMAS = ARMAS_FUEGO;               // armas de fuego, en el orden de la barra
const CASILLAS = ["cuerpo", ...ARMAS_FUEGO];    // la primera casilla es el arma de cuerpo a cuerpo que llevas
const TODAS = [...CUERPO, ...ARMAS_FUEGO];
const G = 330;                                  // gravedad de lo que se lanza (px/s²)
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
    this.base = crearBase(this.mapa);
    this.jugador = {
      x: s.x, y: s.y, vida: JUGADOR.vida, arma: "pistola",
      // La Glock y el bate al empezar; lo demás se compra en la tienda de la base
      armas: Object.fromEntries(TODAS.map((n) => [n, n === "pistola" || n === "bate"])),
      cuerpo: "bate",                    // el arma de la casilla de cuerpo a cuerpo
      cargador: Object.fromEntries(ARMAS_FUEGO.map((n) => [n, n === "pistola" ? ARMAS.pistola.cargador : 0])),
      reserva: Object.fromEntries(ARMAS_FUEGO.map((n) => [n, n === "pistola" ? MUNICION.pistola.inicial : 0])),
      mejoras: Object.fromEntries(TODAS.map((a) => [a, { dano: 0, cargador: 0, recarga: 0 }])),
      lanzables: { granada: 0, molotov: 0 },
      botiquines: 0, chaleco: 0, golpeT: 0, golpeDur: 1, tLanzar: 0,
      recarga: 0, espera: 0, angulo: -Math.PI / 2, voltear: false, anim: 0, andando: false,
      golpe: 0, muerto: 0, sinBlanco: 0, tDisparo: 9,
    };
    this.zombis = []; this.balas = []; this.botin = []; this.flotantes = [];
    this.particulas = []; this.fogonazos = [];
    this.llamas = [];            // llamas del lanzallamas
    this.lanzados = [];          // granadas y molotov en el aire (o la granada en el suelo, a punto de estallar)
    this.fuegos = [];            // charcos de fuego de los molotov
    this.explosiones = [];
    this.cuerpoJugador = null;   // al morir, la cámara sigue al cuerpo
    this.ragdolls = [];          // cuerpos cayendo y trozos volando (después se quedan pintados en el suelo)
    this.blanco = null;
    this.oleada = { n: 0, porSalir: 0, t: 0, descanso: 2.5, cartel: 0, superada: 0, esperando: false };
    this.stats = { bajas: 0, monedas: 0, tiempo: 0, disparos: 0, impactos: 0, dano: 0, recibido: 0 };
    this.monedas = 0;              // las que llevas para gastar (stats.monedas = todas las recogidas)
    this.camara = { x: s.x - this.ancho / 2, y: s.y - this.alto * ALTURA_JUGADOR };
    this.sacudida = 0;
    this.t = 0;
    this.estado = "jugando";
  }

  tecla(c) {
    if (/^Digit[1-7]$/.test(c)) this.cambiarArma(CASILLAS[+c.slice(5) - 1]);
    if (c === "KeyG") this.lanzar("granada");
    if (c === "KeyF") this.lanzar("molotov");
    if (c === "KeyR") this.empezarRecarga();
    if (c === "KeyH") this.usarBotiquin();
    if (c === "KeyT" && this.puedeComprar()) this.abrirTienda();
    if (c === "KeyL" && this.oleada.esperando && this.estado === "jugando") this.listo();
    if (c === "KeyP" || c === "Escape") this.pausar();
    if ((c === "Enter" || c === "Space") && (this.estado === "inicio" || this.estado === "fin")) this.empezar();
  }

  empezar() {
    pantallaCompletaHorizontal();
    desbloquear();
    sonar("boton");
    this.reiniciar();
  }

  // ------------------------------------------------------------------ base y tienda
  // Estadísticas de un arma con sus mejoras compradas.
  arma(n) {
    const a = ARMAS[n], m = this.jugador.mejoras[n];
    if (a.cuerpo) {          // cuerpo a cuerpo: daño y velocidad del golpe
      const k = MEJORAS.recarga.factor[m.recarga];
      return { ...a, dano: a.dano * MEJORAS.dano.factor[m.dano], cadencia: a.cadencia / k, golpe: a.golpe * k };
    }
    return {
      ...a,
      dano: a.dano * MEJORAS.dano.factor[m.dano],
      recarga: a.recarga * MEJORAS.recarga.factor[m.recarga],
      preparar: (a.preparar || 0) * MEJORAS.recarga.factor[m.recarga],
      cargador: MEJORAS.cargador[n][m.cargador],
    };
  }

  // Se compra dentro de la base, entre rondas o en mitad de una (el juego queda parado mientras compras).
  puedeComprar() {
    return this.estado === "jugando" && !this.jugador.muerto && dentro(this.base, this.jugador.y);
  }
  abrirTienda() { this.estado = "tienda"; this.pestana ??= "armas"; sonar("boton"); }
  cerrarTienda() { this.estado = "jugando"; sonar("boton"); }

  // LISTO: empieza la siguiente ronda.
  listo() {
    const o = this.oleada;
    if (!o.esperando) return;
    o.esperando = false; o.descanso = 1.2;
    sonar("boton");
  }

  usarBotiquin() {
    const j = this.jugador;
    if (j.muerto || j.botiquines <= 0 || j.vida >= JUGADOR.vida) return;
    j.botiquines--;
    const antes = j.vida;
    j.vida = Math.min(JUGADOR.vida, j.vida + BASE.curaBotiquin);
    this.flotantes.push({ x: j.x, y: j.y - 48, t: 0, txt: "+" + Math.round(j.vida - antes), color: "#7ee07e" });
    sonar("curar");
  }

  // ¿Le quedan balas a esta arma (en el cargador o en la reserva)?
  conBalas(n) {
    const j = this.jugador;
    if (ARMAS[n].cuerpo) return j.armas[n];
    return j.armas[n] && (j.cargador[n] > 0 || j.reserva[n] > 0);
  }

  // Sprites de un arma: brazos que la sujetan e icono (con los de la pistola si aún no está dibujada).
  brazos(n) { return S["brazos_" + n] || S.brazos_pistola; }
  iconoArma(n) { return S[n] || S.pistola; }

  pausar() {
    this.verEstadisticas = false;
    if (this.estado === "jugando") this.estado = "pausa";
    else if (this.estado === "pausa") this.estado = "jugando";
  }

  cambiarArma(a) {
    const j = this.jugador;
    if (a === "cuerpo") {
      // Ya con el cuerpo a cuerpo en la mano: cambia entre el bate y el machete (si tienes los dos)
      if (CUERPO.includes(j.arma)) {
        const otra = CUERPO.find((n) => n !== j.arma && j.armas[n]);
        if (!otra) return;
        j.cuerpo = otra; a = otra;
      } else a = j.cuerpo;
    }
    if (!a || a === j.arma || j.muerto) return;
    if (!j.armas[a]) {                       // aún no comprada
      this.flotantes.push({ x: j.x, y: j.y - 48, t: 0, txt: t("seCompra"), color: "#d1cec0" });
      return;
    }
    j.arma = a; j.recarga = 0; j.espera = 0.15; j.tDisparo = 9; j.golpeT = 0;
    if (CUERPO.includes(a)) j.cuerpo = a;
    cancelarRecarga();
    sonar("recargado");
  }

  empezarRecarga() {
    const j = this.jugador, a = this.arma(j.arma);
    if (a.cuerpo) return;
    if (j.recarga > 0 || j.cargador[j.arma] >= a.cargador || j.muerto || j.reserva[j.arma] <= 0) return;
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
    if (this.estado === "pausa" || this.estado === "inicio" || this.estado === "tienda") return;
    this.t += dt;
    if (this.estado === "jugando") this.stats.tiempo += dt;

    this.moverJugador(dt);
    this.disparar(dt);
    this.moverZombis(dt);
    this.moverBalas(dt);
    this.moverLlamas(dt);
    this.moverLanzados(dt);
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
    chocarMuro(this.base, j, JUGADOR.radio, true);
    // El portón se abre mientras el jugador está cerca
    const p = this.base.tramos.find((tr) => tr.porton);
    this.base.abierto = Math.abs(j.x - p.x) < 30 && Math.abs(j.y - p.y) < 28 ? 0.4 : Math.max(0, this.base.abierto - dt);
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
    const j = this.jugador, cuerpo = S.jugador, br = this.brazos(j.arma);
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
    const j = this.jugador, a = this.arma(j.arma);
    if (j.muerto) return;
    j.espera = Math.max(0, j.espera - dt);
    j.tDisparo += dt;
    j.tLanzar = Math.max(0, j.tLanzar - dt);
    if (a.cuerpo) return this.golpear(dt, a);
    // Automático: al zombi visible más cercano. Manual: hacia donde marca el joystick de la derecha.
    const manual = this.disparo === "manual";
    const apuntado = manual ? leerApuntado() : null;
    const z = manual ? null : this.zombiMasCercano(a.alcance);
    const quiere = manual ? apuntado !== null : !!z;     // quiere disparar ya
    if (j.recarga > 0) {
      j.recarga -= dt;
      if (j.recarga <= 0) {
        j.recarga = 0;
        if (!a.porCartucho) {
          const toma = Math.min(a.cargador - j.cargador[j.arma], j.reserva[j.arma]);
          j.cargador[j.arma] += toma; j.reserva[j.arma] -= toma;
        } else {
          j.cargador[j.arma]++; j.reserva[j.arma]--;
          sonarCartucho();
          if (j.cargador[j.arma] < a.cargador && j.reserva[j.arma] > 0 && !(quiere && j.cargador[j.arma] > 0)) {
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
    if (j.cargador[j.arma] <= 0) {
      if (j.reserva[j.arma] > 0) this.empezarRecarga();
      else {                                  // sin balas: a otra arma que tenga, y si no, al cuerpo a cuerpo
        const otra = ORDEN_ARMAS.find((n) => n !== j.arma && this.conBalas(n));
        if (otra) this.cambiarArma(otra);
        else {
          this.flotantes.push({ x: j.x, y: j.y - 48, t: 0, txt: t("sinBalas"), color: "#ff5a5a" });
          this.cambiarArma("cuerpo");
        }
      }
      return;
    }

    // ¡Fuego!
    j.cargador[j.arma]--;
    j.espera = 1 / a.cadencia;
    j.tDisparo = 0;
    const geo = this.geometriaArma();
    if (a.llama) {
      // Lanzallamas: una llama que avanza, crece, sube y se apaga; prende a los zombis que toca
      const ang = j.angulo + (Math.random() - 0.5) * (a.dispersion * Math.PI / 180);
      const v = a.velocidadBala * rnd(0.8, 1.15);
      this.llamas.push({ x: geo.boca.x, y: geo.boca.y, vx: Math.cos(ang) * v + rnd(-6, 6), vy: Math.sin(ang) * v, t: 0,
        vida: (a.alcance / a.velocidadBala) * rnd(0.85, 1.25), dano: a.dano, quema: a.quema, tocados: new Set() });
      this.stats.disparos++;
      this.sacudida = Math.max(this.sacudida, a.sacudida);
      sonar("lanzallamas", 0.11);
      if (j.cargador[j.arma] === 0 && j.reserva[j.arma] > 0) this.empezarRecarga();
      return;
    }
    for (let i = 0; i < a.perdigones; i++) {
      const ang = j.angulo + (Math.random() - 0.5) * (a.dispersion * Math.PI / 180);
      const v = a.velocidadBala * rnd(0.9, 1.1);
      this.balas.push({
        x: geo.boca.x, y: geo.boca.y, px: geo.hombro.x, py: geo.hombro.y, nueva: true,
        vx: Math.cos(ang) * v, vy: Math.sin(ang) * v, vida: (a.alcance * 1.25) / v, arma: j.arma,
        atraviesa: a.atraviesa || 1, tocados: null, flecha: !!a.flecha, alto: j.y - geo.boca.y,
      });
    }
    this.stats.disparos += a.perdigones;
    if (!a.flecha) {
      this.fogonazos.push({ x: geo.boca.x, y: geo.boca.y, ang: j.angulo, t: 0 });
      // Casquillo que sale volando hacia atrás
      const lado = Math.cos(j.angulo) < 0 ? 1 : -1;
      this.particulas.push({
        x: geo.casquillo.x, y: j.y - rnd(0, 5), z: j.y - geo.casquillo.y, vx: lado * rnd(25, 55), vy: rnd(-12, 12), vz: rnd(50, 90),
        color: a.perdigones > 1 ? "#a8322a" : "#d9b24a", vida: 3, casquillo: true,
      });
    }
    this.sacudida = Math.max(this.sacudida, a.sacudida);
    sonar(a.sonido, a.cadencia > 5 ? 0.06 : 0);
    if (j.cargador[j.arma] === 0 && j.reserva[j.arma] > 0) this.empezarRecarga();
  }


  // ------------------------------------------------------------------ cuerpo a cuerpo
  // Barrido con el bate o el machete: en automático, cuando un zombi está a su alcance; en manual,
  // hacia donde marca el joystick. El golpe llega a mitad del barrido a todos los del arco.
  golpear(dt, a) {
    const j = this.jugador, manual = this.disparo === "manual";
    const apuntado = manual ? leerApuntado() : null;
    const z = manual ? null : this.zombiMasCercano(a.alcance + 12);
    this.blanco = z;
    if (j.golpeT > 0) {
      const antes = j.golpeT;
      j.golpeT = Math.max(0, j.golpeT - dt);
      if (antes > j.golpeDur * 0.45 && j.golpeT <= j.golpeDur * 0.45) this.impactoCuerpo(a);
      return;
    }
    const quiere = manual ? apuntado !== null : !!z;
    if (quiere) { j.sinBlanco = 0; j.angulo = manual ? apuntado : Math.atan2(z.y - j.y, z.x - j.x); }
    if (!quiere || j.espera > 0) return;
    j.golpeT = j.golpeDur = a.golpe;
    j.espera = 1 / a.cadencia;
    this.stats.disparos++;
    sonar("barrido");
  }

  impactoCuerpo(a) {
    const j = this.jugador, medio = (a.arco / 2) * Math.PI / 180;
    let alguno = false;
    for (const z of this.zombis) {
      if (z.muerto || z.aparece > 0.2) continue;
      const dx = z.x - j.x, dy = z.y - j.y, d = Math.hypot(dx, dy) || 1;
      if (d > a.alcance + z.def.radio) continue;
      const dif = Math.atan2(Math.sin(Math.atan2(dy, dx) - j.angulo), Math.cos(Math.atan2(dy, dx) - j.angulo));
      if (Math.abs(dif) > medio && d > 11) continue;
      const critico = Math.random() < a.critico, dano = a.dano * (critico ? 2 : 1);
      const ux = dx / d, uy = dy / d;
      z.vida -= dano; z.golpe = 0.1; z.barra = 2;
      z.x += ux * a.empuje; z.y += uy * a.empuje;
      resolverChoques(this.mapa, z, z.def.radio);
      chocarMuro(this.base, z, z.def.radio, false);
      if (a.empuje > 10) { z.ataque = 0; z.espera = Math.max(z.espera, 0.6); }   // el bate los deja aturdidos
      this.stats.impactos++;
      this.stats.dano += Math.min(dano, z.vida + dano);
      this.flotantes.push({ x: z.x + rnd(-4, 4), y: z.y - PECHO - 12, t: 0, txt: String(Math.round(dano)) + (critico ? "!" : ""), color: critico ? "#ffd84a" : "#ffffff" });
      for (let i = 0; i < (critico ? 10 : 5); i++) this.gota(z.x, z.y, rnd(10, 26), ux * rnd(20, 80) + rnd(-20, 20), uy * rnd(10, 40) + rnd(-10, 10), rnd(15, 70));
      if (!alguno && j.tDisparo > 0.05) { j.tDisparo = 0; }
      alguno = true;
      if (z.vida <= 0) this.matarZombi(z, { x: ux, y: uy }, a.empuje / 7 + (critico ? 1 : 0.4), critico);
    }
    if (alguno) {
      this.stats.disparos += 0;   // el barrido ya contó como un disparo
      sonar(a.sonido, 0.03);
      this.sacudida = Math.max(this.sacudida, a.sacudida);
      vibrar(15);
    }
  }

  // ------------------------------------------------------------------ granadas y molotov
  // Se lanzan al zombi visible que tenga más compañía alrededor (en manual, de los que hay hacia donde apuntas);
  // si no hay ninguno, hacia delante.
  lanzar(tipo) {
    const j = this.jugador, L = LANZABLES[tipo];
    if (this.estado !== "jugando" || j.muerto || j.lanzables[tipo] <= 0 || j.tLanzar > 0) return;
    const manual = this.disparo === "manual";
    const hacia = manual ? (leerApuntado() ?? j.angulo) : null;
    let mejor = null, puntos = -1;
    for (const z of this.zombis) {
      if (z.muerto || z.aparece > 0.2 || !this.seVe(z)) continue;
      const dx = z.x - j.x, dy = z.y - j.y, d = Math.hypot(dx, dy);
      if (d < 28 || d > L.alcance) continue;
      if (hacia !== null) {
        const dif = Math.atan2(Math.sin(Math.atan2(dy, dx) - hacia), Math.cos(Math.atan2(dy, dx) - hacia));
        if (Math.abs(dif) > 0.6) continue;
      }
      let n = 0;
      for (const o of this.zombis) if (!o.muerto && (o.x - z.x) ** 2 + (o.y - z.y) ** 2 < 32 * 32) n++;
      const p = n * 1000 - d;
      if (p > puntos) { puntos = p; mejor = z; }
    }
    const ang = hacia ?? j.angulo;
    const tx = mejor ? mejor.x : j.x + Math.cos(ang) * L.alcance * 0.7;
    const ty = mejor ? mejor.y : j.y + Math.sin(ang) * L.alcance * 0.7;
    const d = Math.hypot(tx - j.x, ty - j.y), T = Math.max(0.35, Math.min(0.85, d / 150)), z0 = 24;
    this.lanzados.push({ tipo, x: j.x, y: j.y, z: z0, vx: (tx - j.x) / T, vy: (ty - j.y) / T, vz: (0.5 * G * T * T - z0) / T, t: 0, giro: 0 });
    j.lanzables[tipo]--;
    j.tLanzar = 0.45;
    j.angulo = Math.atan2(ty - j.y, tx - j.x);
    sonar("lanzar");
  }

  moverLanzados(dt) {
    for (const o of this.lanzados) {
      o.t += dt;
      if (!o.quieto) {
        o.vz -= G * dt; o.z += o.vz * dt;
        o.x += o.vx * dt; o.y += o.vy * dt;
        o.giro += dt * 15;
        resolverChoques(this.mapa, o, 2);
        if (o.z <= 0) {
          o.z = 0;
          if (o.tipo === "molotov") { this.romperMolotov(o.x, o.y); o.fuera = true; continue; }
          if (o.vz < -60) { o.vz = -o.vz * 0.3; o.vx *= 0.45; o.vy *= 0.45; sonar("impacto", 0.05); }
          else { o.quieto = true; o.vz = 0; }
        }
      }
      if (o.tipo === "granada" && o.t >= LANZABLES.granada.mecha) { this.explotar(o.x, o.y); o.fuera = true; }
    }
    this.lanzados = this.lanzados.filter((o) => !o.fuera);
    // Charcos de fuego: prenden a los zombis que los pisan
    for (const f of this.fuegos) {
      f.t += dt;
      for (const z of this.zombis) {
        if (z.muerto || z.aparece > 0) continue;
        if ((z.x - f.x) ** 2 + ((z.y - f.y) / 0.6) ** 2 < f.r * f.r) {
          z.arde = Math.max(z.arde || 0, 1.5);
          z.vida -= FUEGO.danoSuelo * dt;
          z.barra = 2;
          if (z.vida <= 0) this.matarZombi(z, { x: 0, y: -1 }, 0.5);
        }
      }
      if (f.t >= f.dur) {
        f.fuera = true;
        this.marcaQuemada(f.x, f.y, f.r);
      }
    }
    this.fuegos = this.fuegos.filter((f) => !f.fuera);
    for (const e of this.explosiones) e.t += dt;
    this.explosiones = this.explosiones.filter((e) => e.t < 0.6);
  }

  explotar(x, y) {
    const L = LANZABLES.granada;
    this.explosiones.push({ x, y, t: 0 });
    this.sacudida = Math.max(this.sacudida, 7);
    sonar("explosion");
    vibrar(70);
    for (const z of this.zombis) {
      if (z.muerto || z.aparece > 0.3) continue;
      const dx = z.x - x, dy = z.y - y, d = Math.hypot(dx, dy) || 1;
      if (d > L.radio + z.def.radio) continue;
      const k = 1 - 0.55 * Math.min(1, d / L.radio), dano = L.dano * k;
      z.vida -= dano; z.golpe = 0.1; z.barra = 2;
      this.stats.dano += Math.min(dano, z.vida + dano);
      if (z.vida <= 0) { this.stats.impactos++; this.matarZombi(z, { x: dx, y: dy }, 2.4 + k, Math.random() < 0.35); }
      else { z.x += (dx / d) * 18 * k; z.y += (dy / d) * 18 * k; z.ataque = 0; z.espera = Math.max(z.espera, 0.8); resolverChoques(this.mapa, z, z.def.radio); }
    }
    // Esquirlas, tierra y humo
    for (let i = 0; i < 26; i++) {
      const a = rnd(0, Math.PI * 2), v = rnd(40, 160);
      this.particulas.push({ x: x + rnd(-4, 4), y: y + rnd(-3, 3), z: rnd(2, 10), vx: Math.cos(a) * v, vy: Math.sin(a) * v * 0.6, vz: rnd(40, 170),
        color: ["#3a2c23", "#594430", "#26252e", "#ffc93a"][i % 4], vida: 2.5 });
    }
    this.marcaQuemada(x, y, 16);
  }

  romperMolotov(x, y) {
    const L = LANZABLES.molotov;
    sonar("cristal");
    sonar("prender");
    // Llamas repartidas por el charco (fijas: cada una con su momento de la animación)
    const llamas = [];
    for (let i = 0; i < 9; i++) {
      const a = rnd(0, Math.PI * 2), r = Math.sqrt(Math.random()) * L.radio * 0.85;
      llamas.push({ x: x + Math.cos(a) * r, y: y + Math.sin(a) * r * 0.6, t0: rnd(0, 1), tam: r < L.radio * 0.4 ? 1 : 0 });
    }
    this.fuegos.push({ x, y, r: L.radio, t: 0, dur: L.duracion, llamas });
    for (let i = 0; i < 10; i++) {
      const a = rnd(0, Math.PI * 2), v = rnd(30, 90);
      this.particulas.push({ x, y, z: 2, vx: Math.cos(a) * v, vy: Math.sin(a) * v * 0.6, vz: rnd(30, 90), color: "#b5d0db", vida: 1 });
    }
  }

  // Suelo chamuscado donde estalla una granada o se apaga un molotov.
  marcaQuemada(x, y, r) {
    const g = this.mapa.sueloCtx;
    g.save();
    g.globalAlpha = 0.32;
    g.fillStyle = "#0e0d12";
    for (let i = 0; i < 18; i++) {
      const a = rnd(0, Math.PI * 2), d = Math.sqrt(Math.random()) * r;
      const w = rndInt(2, 5);
      g.fillRect(Math.round(x + Math.cos(a) * d - w / 2), Math.round(y + Math.sin(a) * d * 0.6), w, rndInt(1, 3));
    }
    g.restore();
  }

  // Llamas del lanzallamas: frenan, suben un poco y crecen; cada una prende a cada zombi una vez.
  moverLlamas(dt) {
    for (const f of this.llamas) {
      f.t += dt;
      f.x += f.vx * dt; f.y += f.vy * dt;
      f.vx *= 1 - 1.6 * dt; f.vy = f.vy * (1 - 1.6 * dt) - 14 * dt;
      const r = 5 + 9 * (f.t / f.vida);
      for (const z of this.zombis) {
        if (z.muerto || z.aparece > 0.2 || f.tocados.has(z)) continue;
        if ((z.x - f.x) ** 2 + (z.y - PECHO - f.y) ** 2 < r * r) {
          f.tocados.add(z);
          z.vida -= f.dano; z.barra = 2;
          z.arde = Math.max(z.arde || 0, f.quema);
          this.stats.impactos += 0.1;      // muchas llamas por zombi: cuentan poco para la puntería
          this.stats.dano += f.dano;
          if (z.vida <= 0) this.matarZombi(z, { x: f.vx, y: f.vy }, 0.5);
        }
      }
    }
    this.llamas = this.llamas.filter((f) => f.t < f.vida);
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
      y = Math.min(y, this.base.y - 50);          // nunca dentro de la base
      x = Math.max(12, Math.min(m.ancho - 12, x));
      if (!chocaCon(m, x, y, def.radio + 2)) break;
    }
    const fuerza = 1 + OLEADAS.vidaExtraPorOleada * (this.oleada.n - 1);
    const spr = S[def.sprites[rndInt(0, def.sprites.length - 1)]];
    this.zombis.push({
      tipo, def, spr, x, y, vida: def.vida * fuerza, vidaMax: def.vida * fuerza,
      vel: def.velocidad * rnd(0.85, 1.15), anim: rnd(0, 2), voltear: false,
      variante: rndInt(0, spr.variantes.length - 1),    // ropa y pelo distintos
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
      if (z.muerto) continue;            // el cuerpo ya es un ragdoll
      z.anim += dt;
      if (z.arde > 0) {                  // ardiendo: pierde vida y suelta chispas
        z.arde -= dt;
        z.vida -= FUEGO.dano * dt;
        z.barra = 2;
        this.stats.dano += FUEGO.dano * dt;
        if (Math.random() < dt * 10) this.particulas.push({ x: z.x + rnd(-5, 5), y: z.y, z: rnd(14, 30), vx: rnd(-8, 8), vy: 0, vz: rnd(20, 50), color: Math.random() < 0.5 ? "#ffc93a" : "#f08a1c", vida: 0.5, chispa: true });
        if (z.vida <= 0) { this.matarZombi(z, { x: 0, y: -1 }, 0.5); continue; }
      }
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
        if (antes > golpeEn && z.ataque <= golpeEn) {
          if (z.objetivo) this.golpearMuro(z.objetivo, z.def.dano);
          else if (d <= z.def.alcance + 9 && !j.muerto) this.herirJugador(z.def.dano, z);
        }
        if (z.objetivo) z.ang = z.objetivo.y > z.y ? Math.PI / 2 : -Math.PI / 2;
        if (z.ataque <= 0) z.espera = Math.max(0, z.def.cadencia - total);
        continue;
      }
      z.espera = Math.max(0, z.espera - dt);
      z.objetivo = null;
      if (d <= z.def.alcance && !j.muerto) {
        if (z.espera <= 0) { z.ataque = duracion(z.spr, orientar(z.spr, "atacar", z.ang).tag); sonar("zarpazo", 0.05); }
        continue;
      }
      // El muro en medio: si toca un tramo en pie, lo golpea
      const otroLado = !j.muerto && dentro(this.base, j.y) !== dentro(this.base, z.y);
      if (otroLado) {
        const tr = tramoTocado(this.base, z, z.def.radio);
        if (tr) {
          z.ang = tr.y > z.y ? Math.PI / 2 : -Math.PI / 2;
          if (z.espera <= 0) {
            z.objetivo = tr;
            z.ataque = duracion(z.spr, orientar(z.spr, "atacar", z.ang).tag);
          }
          continue;
        }
      }
      // Andar hacia el jugador (o hacia un hueco del muro si está al otro lado); si se atasca, rodea el obstáculo
      let mx = j.x, my = j.y;
      if (otroLado) {
        const h = huecoCercano(this.base, z.x);
        if (h) { mx = h.x; my = h.y + (dentro(this.base, z.y) ? -14 : 14); if (Math.abs(z.x - h.x) < 14 && Math.abs(z.y - h.y) < 16) { mx = j.x; my = j.y; } }
        else {
          // Sin hueco: van al tramo de muro que tiene delante el jugador (cada uno algo desviado), no al más cercano
          z.desvioMuro ??= rnd(-70, 70);
          mx = j.x + z.desvioMuro; my = this.base.y + (dentro(this.base, z.y) ? 12 : -12);
        }
      }
      const ex = mx - z.x, ey = my - z.y, ed = Math.hypot(ex, ey) || 1;
      let ux = ex / ed, uy = ey / ed;
      if (j.muerto) { ux = -ux * 0.2; uy = -uy * 0.2; }
      if (z.desvio > 0) {
        z.desvio -= dt;
        const px = -uy * z.lado, py = ux * z.lado;
        ux = ux * 0.3 + px; uy = uy * 0.3 + py;
        const l = Math.hypot(ux, uy); ux /= l; uy /= l;
      }
      const ox = z.x, oy = z.y;
      // Alambre de espino delante del muro: frena y hiere
      const enAlambre = this.base.alambre && z.y > this.base.y - 50 && z.y < this.base.y - 8;
      const vel = z.vel * (enAlambre ? BASE.alambre.lentitud : 1);
      if (enAlambre) {
        z.vida -= BASE.alambre.dano * dt;
        if (Math.random() < dt * 3) this.gota(z.x, z.y, rnd(2, 12), rnd(-20, 20), rnd(-8, 8), rnd(10, 40));
        if (z.vida <= 0) { this.matarZombi(z, { x: 0, y: -1 }, 0.6); continue; }
      }
      z.x += ux * vel * dt; z.y += uy * vel * dt;
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
      chocarMuro(this.base, z, z.def.radio, false);
      const avance = Math.hypot(z.x - ox, z.y - oy);
      if (avance < z.vel * dt * 0.3) {
        z.atasco += dt;
        if (z.atasco > 0.3 && z.desvio <= 0) { z.desvio = rnd(0.6, 1.2); z.lado = Math.random() < 0.5 ? 1 : -1; z.atasco = 0; }
      } else z.atasco = Math.max(0, z.atasco - dt);
    }
    // Los cadáveres se desvanecen
    this.zombis = this.zombis.filter((z) => !z.muerto);
  }

  // Un zombi golpea un tramo del muro.
  golpearMuro(tr, dano) {
    if (tr.vida <= 0) return;
    tr.vida = Math.max(0, tr.vida - dano);
    tr.barra = 2;
    sonar("impacto", 0.05);
    for (let i = 0; i < 3; i++) this.particulas.push({ x: tr.x + rnd(-20, 20), y: tr.y - 4, z: rnd(8, 20), vx: rnd(-30, 30), vy: rnd(-25, 0), vz: rnd(30, 70), color: ["#5c3d22", "#6e7885", "#949493"][this.base.nivel], vida: 1.2 });
    if (tr.vida <= 0) { sonar("muereZombi"); this.sacudida = Math.max(this.sacudida, 2); }
  }

  herirJugador(dano, desde = null) {
    const j = this.jugador;
    const para = Math.min(j.chaleco, dano);        // el chaleco se gasta primero
    j.chaleco -= para; dano -= para;
    j.vida = Math.max(0, j.vida - dano);
    j.golpe = 0.18;
    this.stats.recibido += dano;
    this.sacudida = Math.max(this.sacudida, 3.5);
    this.flotantes.push({ x: j.x, y: j.y - 44, t: 0, txt: "-" + dano, color: "#ff5a5a" });
    for (let i = 0; i < 4; i++) this.gota(j.x, j.y, PECHO, rnd(-40, 40), rnd(-15, 15), rnd(20, 60));
    sonar("herido", 0.08);
    vibrar(40);
    if (j.vida <= 0) {
      this.ragdollJugador(desde);
      j.muerto = 0.0001;
      j.recarga = 0;
      sonar("muerte");
      vibrar([80, 60, 160]);
    }
  }

  // El jugador se desploma con los brazos y el arma; el golpe viene del zombi que lo mata.
  ragdollJugador(desde) {
    const j = this.jugador, spr = S.jugador, i = this.cuadroJugador();
    const br = this.brazos(j.arma), geo = this.geometriaArma(), fb = br.frames[primero(br, "apuntar")];
    // Los brazos con el arma, tal como se veían (volteados si apuntaba a la izquierda)
    const c = document.createElement("canvas"); c.width = fb.w; c.height = fb.h;
    const gc = c.getContext("2d");
    if (geo.izq) { gc.translate(0, fb.h); gc.scale(1, -1); }
    gc.drawImage(br.img, fb.x, fb.y, fb.w, fb.h, 0, 0, fb.w, fb.h);
    const boca = punto(br, "boca", 0, { x: 30, y: 9 }), vy = (p) => (geo.izq ? fb.h - 1 - p.y : p.y);
    const dir = desde ? { x: j.x - desde.x, y: j.y - desde.y } : { x: rnd(-1, 1), y: 1 };
    const r = crearRagdoll({
      img: spr.img, frame: spr.frames[i], pies: punto(spr, "pies", i, PIES), voltear: j.voltear,
      x: j.x, y: j.y, dir, fuerza: 1.4, arrancar: 0.35,
      extra: (pts) => {
        pts.ARMA = { x: geo.boca.x, y: j.y, z: j.y - geo.boca.y, vx: pts.N.vx + rnd(-30, 30), vy: pts.N.vy, vz: pts.N.vz + rnd(20, 60) };
        return { nombre: "arma", lienzo: c, x0: 0, y0: 0, a: "N", b: "ARMA", ra: { x: geo.hb.x, y: vy(geo.hb) }, rb: { x: boca.x, y: vy(boca) } };
      },
    });
    if (r) { this.ragdolls.push(r); this.cuerpoJugador = r; }
    this.salpicar(j.x, j.y, 30);
    j.ragdoll = true;
  }

  // Estallido de sangre en todas direcciones desde el cuerpo.
  salpicar(x, y, n) {
    for (let i = 0; i < n; i++) {
      const a = rnd(0, Math.PI * 2), v = rnd(20, 110);
      this.gota(x + rnd(-4, 4), y, rnd(8, 30), Math.cos(a) * v, Math.sin(a) * v * 0.6, rnd(20, 130));
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
      if (b.vida <= 0) { if (b.flecha) this.soltarFlecha(b.x, b.y + b.alto, b.vx); continue; }
      let mejor = null, mt = 2, mq = null;
      for (const z of this.zombis) {
        if (z.muerto || z.aparece > 0.2 || b.tocados?.has(z)) continue;
        const cx = z.x, cy = z.y - PECHO;
        const sx = b.x - b.px, sy = b.y - b.py, l2 = sx * sx + sy * sy || 1;
        const t = Math.max(0, Math.min(1, ((cx - b.px) * sx + (cy - b.py) * sy) / l2));
        const qx = b.px + sx * t, qy = b.py + sy * t;
        if ((qx - cx) ** 2 + (qy - cy) ** 2 < RADIO_CUERPO * RADIO_CUERPO && t < mt) { mejor = z; mt = t; mq = { x: qx, y: qy }; }
      }
      if (mejor) {
        this.impacto(mejor, b, mq.x, mq.y);
        (b.tocados ??= new Set()).add(mejor);
        if (--b.atraviesa <= 0) {
          b.vida = 0;
          if (b.flecha) this.soltarFlecha(mejor.x + rnd(-6, 6), mejor.y + rnd(-3, 4), b.vx);
        }
      }
    }
    this.balas = this.balas.filter((b) => b.vida > 0);
  }

  // El virote de la ballesta se queda en el suelo; pasando por encima lo recoges.
  soltarFlecha(x, y, vx) {
    this.botin.push({ tipo: "flecha", x, y, z: 0, vz: 0, vx: 0, vy: 0, t: 0, anim: 0, voltear: vx < 0 });
    const flechas = this.botin.filter((o) => o.tipo === "flecha");
    if (flechas.length > 40) flechas[0].recogido = true;
  }

  impacto(z, b, x, y) {
    const a = this.arma(b.arma);
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
    if (z.vida <= 0) this.matarZombi(z, { x: b.vx, y: b.vy }, a.empuje / 4.5, critico);
  }

  // Muere: el cuerpo se convierte en ragdoll. Cuanto más fuerte el golpe (escopeta), más trozos arranca;
  // un crítico vuela la cabeza.
  matarZombi(z, dir = { x: 0, y: -1 }, fuerza = 1, critico = false) {
    const { i, pies } = this.cuadroZombi(z), spr = z.spr;
    const v = spr.variantes[z.variante] || spr.variantes[0];
    const r = crearRagdoll({
      img: v.img, frame: spr.frames[i], pies, voltear: z.voltear, x: z.x, y: z.y, dir,
      fuerza, arrancar: Math.min(0.8, 0.25 + 0.2 * fuerza), cabeza: critico,
    });
    if (r) this.ragdolls.push(r);
    this.salpicar(z.x, z.y, 18 + Math.round(10 * fuerza));
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
      // Con la vida llena el botiquín se queda en el suelo: ni se atrae ni se recoge.
      if (o.tipo === "botiquin" && j.vida >= JUGADOR.vida) continue;
      if (o.tipo === "flecha" && (!j.armas.ballesta || j.reserva.ballesta >= MUNICION.ballesta.maximo)) continue;
      const dx = j.x - o.x, dy = j.y - 8 - o.y, d = Math.hypot(dx, dy) || 1;
      const iman = o.iman ? 1e6 : o.tipo === "moneda" ? JUGADOR.recogerMonedas : 15;
      if (o.iman && o.t > 0.35) {                    // al acabar la ronda vuelan hasta ti
        const v = 260 + o.t * 40;
        o.x += (dx / d) * Math.min(d, v * dt); o.y += (dy / d) * Math.min(d, v * dt);
      } else if (d < iman && o.t > 0.35) {
        const v = 240 * (1 - d / (iman + 1)) + 60;
        o.x += (dx / d) * v * dt; o.y += (dy / d) * v * dt;
      }
      if (d < 9 && o.t > 0.35) {
        if (o.tipo === "moneda") { this.stats.monedas++; this.monedas++; sonar("moneda", 0.03); }
        else if (o.tipo === "flecha") { j.reserva.ballesta++; sonar("recargado", 0.05); }
        else if (o.tipo === "botiquin") {
          const antes = j.vida;
          j.vida = Math.min(JUGADOR.vida, j.vida + BOTIN.curaBotiquin);
          this.flotantes.push({ x: j.x, y: j.y - 48, t: 0, txt: "+" + Math.round(j.vida - antes), color: "#7ee07e" });
          sonar("curar");
        }
        o.recogido = true;
      }
    }
    // Las monedas no caducan (se recogen al acabar la ronda); los botiquines sí
    this.botin = this.botin.filter((o) => !o.recogido && (o.tipo === "moneda" || o.tipo === "flecha" || o.t < BOTIN.duracionEnSuelo));
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
    // Ragdolls: cuando quedan quietos se pintan en el suelo (con su charco) y dejan de calcularse.
    const sangrar = (x, y, z, vx, vy, vz) => this.gota(x, y, z, vx, vy, vz);
    for (const r of this.ragdolls) {
      moverRagdoll(r, dt, sangrar);
      if (asentado(r)) {
        const g = this.mapa.sueloCtx;
        manchar(g, r.pts.P.x, r.pts.P.y, rndInt(0, 3), 0.85);
        dibujarRagdoll(g, r);
        r.fuera = true;
      }
    }
    this.ragdolls = this.ragdolls.filter((r) => !r.fuera);
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
    if (o.esperando) return;               // descanso entre rondas: hasta que pulse LISTO
    if (o.n === 0 && !o.salio) {           // la ronda 1 empieza cuando sales de la base por primera vez
      if (dentro(this.base, this.jugador.y)) return;
      o.salio = true;
    }
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
      // Ronda superada: se paran los zombis, las monedas que queden vuelan hacia ti
      o.esperando = true;
      o.descanso = 0;
      o.superada = 2.5;
      for (const b of this.botin) if (b.tipo === "moneda" || (b.tipo === "flecha" && this.jugador.armas.ballesta)) b.iman = true;
    }
  }

  // ------------------------------------------------------------------ cámara
  moverCamara(dt) {
    const c = this.camara, m = this.mapa;
    const j = this.cuerpoJugador ? this.cuerpoJugador.pts.P : this.jugador;
    const ox = j.x - this.ancho / 2;
    let oy = j.y - this.alto * ALTURA_JUGADOR;    // se ve más por delante (arriba), de donde vienen
    // Dentro de la base, el muro va hacia la mitad de la pantalla para ver llegar a los zombis
    if (this.base && j.y > this.base.y - 20) oy = Math.min(oy, Math.max(this.base.y - this.alto * 0.42, j.y - this.alto + 10));
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

    // Alambre de espino en el suelo, por fuera del muro
    dibujarAlambre(g, this.base);

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
    for (const o of this.lanzados) sombra(o.x, o.y, 3, 1.2);

    // Todo lo que está de pie, ordenado por la y de los pies
    const cosas = [];
    for (const o of this.mapa.objetos) if (this.enPantalla(o.x, o.y, 70)) cosas.push({ y: o.y, f: () => this.dibujarObjeto(g, o) });
    for (const tr of this.base.tramos) if (this.enPantalla(tr.x, tr.y, 40)) cosas.push({ y: tr.y, f: () => dibujarTramo(g, this.base, tr) });
    if (this.enPantalla(this.base.tienda.x, this.base.tienda.y, 60)) cosas.push({ y: this.base.tienda.y, f: () => dibujarTienda(g, this.base, this.t) });
    for (const z of this.zombis) if (!z.muerto && this.enPantalla(z.x, z.y)) cosas.push({ y: z.y, f: () => this.dibujarZombi(g, z) });
    for (const o of this.botin) cosas.push({ y: o.y - 0.5, f: () => this.dibujarBotin(g, o) });
    for (const o of this.lanzados) cosas.push({ y: o.y, f: () => this.dibujarLanzado(g, o) });
    for (const f of this.fuegos) cosas.push({ y: f.y - f.r * 0.6, f: () => this.dibujarFuego(g, f) });
    if (!j.ragdoll) cosas.push({ y: j.y, f: () => this.dibujarJugador(g) });
    for (const r of this.ragdolls) if (this.enPantalla(r.pts.P.x, r.y, 60)) cosas.push({ y: r.y, f: () => dibujarRagdoll(g, r) });
    cosas.sort((a, b) => a.y - b.y);
    for (const k of cosas) k.f();

    // Balas (trazas), fogonazos, partículas
    g.lineWidth = 1;
    for (const b of this.balas) {
      if (b.flecha) {
        const s = S.proyectiles;
        if (s) {
          const f = s.frames[2];
          g.save(); g.translate(Math.round(b.x) + 0.5, Math.round(b.y) + 0.5); g.rotate(Math.atan2(b.vy, b.vx));
          g.drawImage(s.img, f.x, f.y, f.w, f.h, -f.w + 1.5, -f.h / 2 - 0.5, f.w, f.h);
          g.restore();
          continue;
        }
      }
      const v = Math.hypot(b.vx, b.vy), l = b.arma === "francotirador" ? 16 : 7;
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
    // Llamas del lanzallamas: de blanco amarillento a rojo y a humo según se apagan
    for (const f of this.llamas) {
      const k = f.t / f.vida, r = Math.round(1 + 4 * k);
      const col = k < 0.18 ? "#fff1a8" : k < 0.42 ? "#ffc93a" : k < 0.66 ? "#f08a1c" : k < 0.86 ? "#c2410c" : "rgba(65,68,76,0.6)";
      const x = Math.round(f.x), y = Math.round(f.y);
      g.fillStyle = col;
      g.fillRect(x - r, y - r + 1, 2 * r + 1, 2 * r - 1);
      g.fillRect(x - r + 1, y - r, 2 * r - 1, 2 * r + 1);
    }
    // Explosiones
    const ex = S.explosion;
    for (const e of this.explosiones) {
      if (!ex) { g.fillStyle = `rgba(255,201,58,${1 - e.t / 0.6})`; g.beginPath(); g.arc(e.x, e.y - 10, 30 * (0.4 + e.t), 0, 7); g.fill(); continue; }
      if (e.t >= duracion(ex, "estallar")) continue;
      const c = punto(ex, "centro", 0, { x: 24, y: 32 });
      dibujar(g, ex, fotograma(ex, "estallar", e.t, false), Math.round(e.x) - c.x, Math.round(e.y) - c.y);
    }
    g.restore();

    // Oscuridad del atardecer: las farolas, el fuego y los disparos iluminan
    this.dibujarLuces(g, cx, cy);

    // Barras de vida de zombis heridos y números de daño (encima de la oscuridad, para que se lean)
    g.save();
    g.translate(-cx, -cy);
    this.dibujarOjos(g);
    // Vida de los tramos del muro que están recibiendo golpes
    for (const tr of this.base.tramos) {
      tr.barra = Math.max(0, tr.barra - 1 / 60);
      if (tr.vida <= 0 || tr.vida >= tr.vidaMax || (tr.barra <= 0 && !this.oleada.esperando)) continue;
      const w = 30, x = Math.round(tr.x - w / 2), y = Math.round(tr.y - 40);
      g.fillStyle = "#0e0d12"; g.fillRect(x - 1, y - 1, w + 2, 5);
      g.fillStyle = "#3a2c23"; g.fillRect(x, y, w, 3);
      g.fillStyle = "#d9a233"; g.fillRect(x, y, Math.max(1, Math.round(w * tr.vida / tr.vidaMax)), 3);
    }
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
    // El fuego también ilumina
    for (const f of this.fuegos) foco(f.x, f.y - 6, (f.r + 34) * (1 + 0.08 * Math.sin(this.t * 13 + f.x)) * Math.min(1, (f.dur - f.t) / 1.2 + 0.3), 1, "255,150,60");
    for (const z of this.zombis) if (z.arde > 0 && !z.muerto) foco(z.x, z.y - 14, 42, 0.9, "255,150,60");
    this.llamas.forEach((f, i) => { if (i % 3 === 0) foco(f.x, f.y, 34, 0.8, "255,170,70"); });
    for (const o of this.lanzados) if (o.tipo === "molotov") foco(o.x, o.y - o.z, 22, 0.8, "255,150,60");
    for (const e of this.explosiones) foco(e.x, e.y - 10, 150 * (1 - e.t / 0.6), 1, "255,190,90");
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
    const j = this.jugador, a = this.arma(j.arma), br = this.brazos(j.arma);
    const geo = this.geometriaArma();
    let fi = primero(br, "apuntar"), ang = j.angulo;
    if (a.cuerpo) ang += this.giroGolpe() * (geo.izq ? -1 : 1);
    else if (j.recarga > 0) fi = fotogramaPorAvance(br, "recargar", 1 - j.recarga / (j.recargaPaso || a.recarga));
    else if (j.tDisparo < duracion(br, "disparar")) fi = fotograma(br, "disparar", j.tDisparo, false);
    if (!br[destello]) destello = "img";
    const f = br.frames[fi];
    if (a.cuerpo) this.dibujarEstela(g, geo, br);
    g.save();
    g.translate(geo.hombro.x + 0.5, geo.hombro.y + 0.5);
    g.rotate(ang);
    if (geo.izq) g.scale(1, -1);
    g.drawImage(br[destello], f.x, f.y, f.w, f.h, -geo.hb.x - 0.5, -geo.hb.y - 0.5, f.w, f.h);
    g.restore();
  }

  // Giro de los brazos con el bate o el machete respecto a donde mira (radianes): en reposo, el arma
  // levantada; al golpear, coge impulso hacia atrás, barre rápido y vuelve despacio.
  giroGolpe() {
    const j = this.jugador, reposo = -1.0;
    if (j.golpeT <= 0) return reposo;
    const p = 1 - j.golpeT / j.golpeDur;
    if (p < 0.2) return reposo - 0.9 * (p / 0.2);
    if (p < 0.55) { const k = (p - 0.2) / 0.35; return -1.9 + 3.0 * (1 - (1 - k) * (1 - k)); }
    return 1.1 - 2.1 * ((p - 0.55) / 0.45);
  }

  // Estela del barrido: un arco de píxeles claros por donde ha pasado la punta.
  dibujarEstela(g, geo, br) {
    const j = this.jugador;
    if (j.golpeT <= 0) return;
    const p = 1 - j.golpeT / j.golpeDur;
    if (p < 0.22 || p > 0.75) return;
    const lado = geo.izq ? -1 : 1, punta = punto(br, "boca", 0, { x: 34, y: 9 });
    const r = punta.x - geo.hb.x, a1 = j.angulo + this.giroGolpe() * lado, a0 = j.angulo - 1.9 * lado;
    const pasos = 18, alfa = p < 0.55 ? 0.55 : 0.55 * (1 - (p - 0.55) / 0.2);
    for (let k = 0; k <= pasos; k++) {
      const a = a0 + (a1 - a0) * (k / pasos);
      g.fillStyle = `rgba(255,255,255,${alfa * (k / pasos)})`;
      g.fillRect(Math.round(geo.hombro.x + Math.cos(a) * r), Math.round(geo.hombro.y + Math.sin(a) * r), 1, 1);
      g.fillStyle = `rgba(255,255,255,${alfa * 0.5 * (k / pasos)})`;
      g.fillRect(Math.round(geo.hombro.x + Math.cos(a) * (r - 3)), Math.round(geo.hombro.y + Math.sin(a) * (r - 3)), 1, 1);
    }
  }

  // Fotograma que toca ahora a un zombi vivo (también lo usa el ragdoll al morir).
  cuadroZombi(z) {
    const spr = z.spr;
    const o = orientar(spr, z.ataque > 0 ? "atacar" : "andar", z.ang ?? 0);
    z.voltear = o.voltear;
    const i = z.ataque > 0 ? fotograma(spr, o.tag, duracion(spr, o.tag) - z.ataque, false)
      : fotograma(spr, o.tag, z.anim * (z.vel / z.def.velocidad));
    return { i, pies: punto(spr, "pies", i, PIES) };
  }

  dibujarZombi(g, z) {
    const spr = z.spr;
    if (z.muerto) return;
    const { i, pies } = this.cuadroZombi(z);
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
    const v = spr.variantes[z.variante] || spr.variantes[0];
    dibujarAnclado(g, spr, i, z.x, z.y, pies, z.voltear, z.golpe > 0 ? spr.blanca : v.img);
    z.ojos = { i, pies };          // para pintar los ojos brillando encima de la oscuridad
    if (z.arde > 0) {              // en llamas
      this.dibujarLlama(g, z.x - 2, z.y - 8, z.anim * 1.3);
      this.dibujarLlama(g, z.x + 3, z.y - 15, z.anim * 1.3 + 0.37);
    }
  }

  // Ojos amarillos de los zombis vivos, por encima de la capa de oscuridad (brillan en el atardecer).
  dibujarOjos(g) {
    for (const z of this.zombis) {
      if (z.muerto || z.aparece > 0 || !z.ojos || !this.enPantalla(z.x, z.y)) continue;
      const v = z.spr.variantes[z.variante] || z.spr.variantes[0];
      dibujarAnclado(g, z.spr, z.ojos.i, z.x, z.y, z.ojos.pies, z.voltear, v.ojos);
    }
    // Un halo suave: la misma capa sumada encima, desplazada medio píxel en cada sentido
    g.globalCompositeOperation = "lighter";
    g.globalAlpha = 0.35;
    for (const z of this.zombis) {
      if (z.muerto || z.aparece > 0 || !z.ojos || !this.enPantalla(z.x, z.y)) continue;
      const v = z.spr.variantes[z.variante] || z.spr.variantes[0];
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, -1]]) dibujarAnclado(g, z.spr, z.ojos.i, z.x + dx, z.y + dy, z.ojos.pies, z.voltear, v.ojos);
    }
    g.globalAlpha = 1;
    g.globalCompositeOperation = "source-over";
  }

  // Una llama del sprite «fuego» con la base en (x, y).
  dibujarLlama(g, x, y, t) {
    const s = S.fuego;
    if (!s) { g.fillStyle = "#f08a1c"; g.fillRect(Math.round(x) - 2, Math.round(y) - 6, 4, 6); return; }
    const b = punto(s, "base", 0, { x: 7, y: 17 });
    dibujar(g, s, fotograma(s, "arder", t), Math.round(x) - b.x, Math.round(y) - b.y);
  }

  dibujarLanzado(g, o) {
    const s = S.proyectiles, i = o.tipo === "granada" ? 0 : 1;
    if (!s) { g.fillStyle = "#4a6a34"; g.fillRect(Math.round(o.x) - 2, Math.round(o.y - o.z) - 4, 4, 4); return; }
    const f = s.frames[i];
    g.save();
    g.translate(Math.round(o.x) + 0.5, Math.round(o.y - o.z) - f.h / 2 + 0.5);
    if (!o.quieto) g.rotate(Math.round(o.giro / (Math.PI / 4)) * (Math.PI / 4));    // gira a saltos de 45°
    g.drawImage(s.img, f.x, f.y, f.w, f.h, -f.w / 2 - 0.5, -f.h / 2 - 0.5, f.w, f.h);
    g.restore();
    // La granada en el suelo parpadea en rojo antes de estallar
    if (o.tipo === "granada" && o.quieto && Math.floor(o.t * 10) % 2) { g.fillStyle = "#ff4a3a"; g.fillRect(Math.round(o.x), Math.round(o.y) - 5, 1, 1); }
  }

  dibujarFuego(g, f) {
    const queda = f.dur - f.t, n = queda < 1.5 ? Math.ceil(f.llamas.length * queda / 1.5) : f.llamas.length;
    for (let i = 0; i < n; i++) { const l = f.llamas[i]; this.dibujarLlama(g, l.x, l.y, this.t + l.t0); }
  }

  dibujarObjeto(g, o) {
    const spr = S[o.tipo];
    const i = o.tipo === "hoguera" ? fotograma(spr, "arder", this.t + o.t0) : o.f;
    dibujar(g, spr, i, o.x - o.base.x, o.y - o.base.y);
  }

  dibujarBotin(g, o) {
    if (o.tipo === "flecha") {           // virote clavado en el suelo
      const s = S.proyectiles;
      if (s) dibujar(g, s, 3, Math.round(o.x) - 6, Math.round(o.y - o.z) - 10, o.voltear);
      else { g.fillStyle = "#7b5631"; g.fillRect(Math.round(o.x), Math.round(o.y) - 6, 1, 6); }
      return;
    }
    const spr = S[o.tipo];
    if (o.tipo !== "moneda" && o.t > BOTIN.duracionEnSuelo - 3 && Math.floor(o.t * 8) % 2) return;   // parpadea antes de irse
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
    // Chaleco: barra azul fina debajo de la vida
    if (j.chaleco > 0) {
      g.fillStyle = "#0e0d12"; g.fillRect(20, 15, bw + 2, 4);
      g.fillStyle = "#6d93a8"; g.fillRect(21, 16, Math.round(bw * j.chaleco / BASE.chaleco), 2);
    }
    // Botiquines que llevas encima: se usan tocándolos
    if (j.botiquines > 0 && this.estado === "jugando" && !j.muerto) {
      const bx0 = 21 + bw + 5 + anchoTexto("100") + 8;
      g.fillStyle = "#0e0d12"; g.fillRect(bx0, 2, 34, 20);
      g.fillStyle = j.vida < JUGADOR.vida ? "#3b526b" : "#26252e"; g.fillRect(bx0 + 1, 3, 32, 18);
      dibujar(g, S.botiquin, 0, bx0 + 3, 4);
      texto(g, "×" + j.botiquines, bx0 + 31, 7, "#ffffff", "der");
      this.boton(bx0 - 4, 0, 42, 26, () => this.usarBotiquin());
    }

    // Ronda pintada con sangre, debajo de la vida (las bajas están en Estadísticas, en la pausa)
    const o = this.oleada;
    this.dibujarRonda(g, 0, 20);
    // Pausa: botón grande arriba a la derecha y zona tocable aún más grande alrededor
    const pw = 30, ph = 28, bx = W - pw - 4, by = 3;
    g.fillStyle = "#0e0d12"; g.fillRect(bx, by, pw, ph);
    g.fillStyle = "#34363d"; g.fillRect(bx + 1, by + 1, pw - 2, ph - 2);
    g.fillStyle = "rgba(255,255,255,0.18)"; g.fillRect(bx + 1, by + 1, pw - 2, 2);
    g.fillStyle = "#d1cec0"; g.fillRect(bx + 9, by + 7, 4, 14); g.fillRect(bx + 17, by + 7, 4, 14);
    this.boton(bx - 14, 0, pw + 18, ph + 16, () => { sonar("boton"); this.pausar(); });

    // Monedas, a la izquierda del botón de pausa
    const txtM = String(this.monedas);
    texto(g, txtM, bx - 8, by + 9, "#f2c84a", "der");
    dibujar(g, S.moneda, 0, bx - 8 - anchoTexto(txtM) - 13, by + 9);

    // Armas (abajo a la derecha; en disparo manual, abajo en el centro porque ahí va el joystick de apuntar).
    // Las que no has comprado salen con candado.
    // La primera casilla es la del cuerpo a cuerpo (bate o machete).
    const manual = this.disparo === "manual";
    const slotW = 38, slotH = 24, gap = 3, totalW = (slotW + gap) * CASILLAS.length - gap;
    const x0 = manual ? Math.round(W / 2 - totalW / 2) : W - totalW - 5, y0 = H - slotH - 8;
    const xDer = x0 + totalW;                         // borde derecho de las armas (para la munición)
    CASILLAS.forEach((casilla, k) => {
      const nombre = casilla === "cuerpo" ? j.cuerpo : casilla;
      const x = x0 + k * (slotW + gap), sel = nombre === j.arma;
      g.fillStyle = "#0e0d12"; g.fillRect(x, y0, slotW, slotH);
      g.fillStyle = sel ? "#3b526b" : "#26252e"; g.fillRect(x + 1, y0 + 1, slotW - 2, slotH - 2);
      if (sel) { g.fillStyle = "#f2c84a"; g.fillRect(x + 1, y0 + 1, slotW - 2, 2); }
      const spr = this.iconoArma(nombre), tiene = j.armas[nombre];
      g.globalAlpha = sel ? 1 : tiene ? 0.7 : 0.25;
      dibujar(g, spr, 0, x + Math.floor((slotW - spr.w) / 2), y0 + 1 + Math.floor((slotH - spr.h) / 2));
      g.globalAlpha = 1;
      if (!tiene) this.icono(g, 13, x + slotW / 2 - 8, y0 + 4, 16);
      else if (!this.conBalas(nombre)) texto(g, "0", x + slotW - 3, y0 + slotH - 11, "#ff5a5a", "der");
      // Con el bate y el machete, un puntito: tocando otra vez se cambia de uno a otro
      if (casilla === "cuerpo" && j.armas.bate && j.armas.machete) { g.fillStyle = "#f2c84a"; g.fillRect(x + slotW - 5, y0 + slotH - 5, 2, 2); }
      this.boton(x - 1, y0 - 6, slotW + 2, slotH + 14, () => this.cambiarArma(casilla));
    });
    // Granadas y molotov: un botón por cada uno que lleves, encima de la munición a la derecha
    if (this.estado === "jugando" && !j.muerto) {
      let yL = H - 112;
      for (const tipo of ["molotov", "granada"]) {
        const n = j.lanzables[tipo];
        if (n <= 0) continue;
        const bw2 = 34, bh = 28, bx2 = W - bw2 - 5;
        g.fillStyle = "#0e0d12"; g.fillRect(bx2, yL, bw2, bh);
        g.fillStyle = j.tLanzar > 0 ? "#26252e" : "#4a3a2a"; g.fillRect(bx2 + 1, yL + 1, bw2 - 2, bh - 2);
        g.fillStyle = "rgba(255,255,255,0.18)"; g.fillRect(bx2 + 1, yL + 1, bw2 - 2, 2);
        this.icono(g, tipo === "granada" ? 17 : 18, bx2 + 1, yL + 2, 24);
        texto(g, String(n), bx2 + bw2 - 3, yL + bh - 11, "#ffffff", "der");
        this.boton(bx2 - 4, yL - 3, bw2 + 8, bh + 6, () => this.lanzar(tipo));
        yL -= bh + 6;
      }
    }
    // Munición y recarga encima de las armas
    const a = this.arma(j.arma);
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
    } else if (a.cuerpo) {
      texto(g, t(j.arma), xDer, yMun, "#ffffff", "der");
    } else {
      const quedan = j.cargador[j.arma];
      const res = j.reserva[j.arma];
      const wr = texto(g, String(res), xDer, yMun, res === 0 ? "#ff5a5a" : "#d1cec0", "der");
      texto(g, t(j.arma) + "  " + quedan + " / ", xDer - wr, yMun, quedan === 0 ? "#ff5a5a" : "#ffffff", "der");
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

    // Carteles (el cambio de ronda lo anuncia el propio indicador parpadeando)
    if (this.estado !== "jugando") { /* sin carteles detrás de los menús */ }
    else if (o.superada > 0) {
      texto(g, t("oleadaSuperada"), W / 2, H * 0.46, "#7ee07e", "centro", 2);
    }

    // Descanso entre rondas: LISTO para seguir y TIENDA si estás dentro de la base
    if (this.estado === "jugando" && o.esperando && !j.muerto) {
      const dentroBase = dentro(this.base, j.y);
      const bw2 = Math.max(anchoTexto(t("listo"), 2), anchoTexto(t("tienda"), 2)) + 24, gap2 = 8;
      const ancho = dentroBase ? bw2 * 2 + gap2 : bw2, xb = Math.round(W / 2 - ancho / 2), yb = 36;
      if (dentroBase) this.botonGrande(g, t("tienda"), yb, () => this.abrirTienda(), "#8a6a24", xb, bw2);
      this.botonGrande(g, t("listo"), yb, () => this.listo(), "#4a6a34", dentroBase ? xb + bw2 + gap2 : xb, bw2);
      texto(g, t(dentroBase ? "ayudaDescanso" : "vuelveBase"), W / 2, yb + 36, "#d1cec0", "centro");
    } else if (this.estado === "jugando" && !j.muerto && o.n === 0 && !o.salio) {
      const aw = anchoTexto(t("salBase")) + 16;
      g.fillStyle = "rgba(14,13,18,0.75)"; g.fillRect(Math.round(W / 2 - aw / 2), 36, aw, 17);
      texto(g, t("salBase"), W / 2, 41, "#f2c84a", "centro");
    } else if (this.estado === "jugando" && !j.muerto && o.n > 0) {
      // En mitad de la ronda: TIENDA dentro de la base; fuera, si no te quedan balas, aviso de volver.
      const bw2 = anchoTexto(t("tienda"), 2) + 24, yb = 36;
      if (dentro(this.base, j.y)) this.botonGrande(g, t("tienda"), yb, () => this.abrirTienda(), "#8a6a24", W - bw2 - 8, bw2);   // a un lado: no tapa el portón
      else if (!ORDEN_ARMAS.some((n) => this.conBalas(n)) && Math.floor(this.t * 2) % 2 === 0)
        texto(g, t("vuelveBase"), W / 2, yb + 6, "#ff5a5a", "centro");
    }

    if (this.estado === "tienda") pantallaTienda(this, g);
    if (this.estado === "pausa") this.pantallaPausa(g);
    if (this.estado === "fin") this.pantallaFin(g);
  }

  // Ronda 1 a 9: palotes (el quinto tacha a los cuatro primeros); de la 10 en adelante, número.
  // Entre rondas parpadea en blanco; al empezar la nueva, parpadea rápido un momento.
  dibujarRonda(g, x, y) {
    const o = this.oleada, n = o.n;
    if (!n) return;
    let blanca = false;
    if (o.descanso > 0) blanca = Math.floor(this.t * 3.4) % 2 === 0;
    else if (o.cartel > 1.1) blanca = Math.floor(o.cartel * 7) % 2 === 0;
    // A doble tamaño: tiene que leerse de un vistazo, como una marca pintada en la pared.
    g.save();
    g.translate(x, y); g.scale(2, 2);
    if (n <= 9) {
      const p = S.palotes;
      dibujar(g, p, n - 1, 0, 0, false, blanca ? p.blanca : p.img);
    } else {
      const c = S.cifras_sangre;
      [...String(n)].forEach((d, i) => dibujar(g, c, +d, i * 12, 0, false, blanca ? c.blanca : c.img));
    }
    g.restore();
  }

  // Icono de la tienda (fotograma i de iconos_tienda) en (x, y), escalado a «tam» px.
  icono(g, i, x, y, tam = 24) {
    const s = S.iconos_tienda;
    if (s && s.frames[i]) {
      const f = s.frames[i];
      g.drawImage(s.img, f.x, f.y, f.w, f.h, Math.round(x), Math.round(y), tam, tam);
      return;
    }
    g.fillStyle = "#85837a"; g.fillRect(Math.round(x + tam * 0.2), Math.round(y + tam * 0.2), Math.round(tam * 0.6), Math.round(tam * 0.6));
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
    if (this.verEstadisticas) return this.pantallaEstadisticas(g);
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
    // Estadísticas y reiniciar, uno al lado del otro
    const ew = Math.max(anchoTexto(t("estadisticas"), 2), anchoTexto(t("reiniciar"), 2)) + 24, x2 = Math.round(W / 2 - ew - gap / 2);
    this.botonGrande(g, t("estadisticas"), H * 0.24 + 122, () => { this.verEstadisticas = true; sonar("boton"); }, "#3b526b", x2, ew);
    this.botonGrande(g, t("reiniciar"), H * 0.24 + 122, () => this.empezar(), "#872a26", x2 + ew + gap, ew);
  }

  // Estadísticas de la partida actual (más adelante, también de partidas anteriores).
  pantallaEstadisticas(g) {
    const W = this.uiW, H = this.uiH, s = this.stats;
    texto(g, t("estadisticas"), W / 2, H * 0.07, "#ffffff", "centro", 3);
    texto(g, t("partidaActual"), W / 2, H * 0.07 + 34, "#85837a", "centro");
    const y0 = H * 0.07 + 52;
    texto(g, t("bajas"), W / 2 - 84, y0, "#d1cec0", "izq", 2);
    texto(g, s.bajas, W / 2 + 84, y0, "#e0403a", "der", 2);
    const filas = [
      [t("oleada"), Math.max(1, this.oleada.n)],
      [t("monedas"), s.monedas],
      [t("tiempo"), Math.floor(s.tiempo / 60) + ":" + String(Math.floor(s.tiempo % 60)).padStart(2, "0")],
      [t("punteria"), (s.disparos ? Math.round(100 * s.impactos / s.disparos) : 0) + "%"],
    ];
    filas.forEach(([k, v], i) => {
      const y = y0 + 28 + i * 14;
      texto(g, k, W / 2 - 84, y, "#d1cec0");
      texto(g, v, W / 2 + 84, y, "#f2c84a", "der");
    });
    this.botonGrande(g, t("volver"), y0 + 28 + filas.length * 14 + 8, () => { this.verEstadisticas = false; sonar("boton"); });
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
