// Partida: jugador, zombis, balas, botín, oleadas, cámara, interfaz.
import { JUGADOR, ARMAS, ZOMBIS, OLEADAS, BOTIN } from "./config.js";
import { S, fotograma, duracion, dibujar, texto, anchoTexto } from "./sprites.js";
import { crearMapa, manchar, resolverChoques, chocaCon } from "./mapa.js";
import { entrada, leerMovimiento, RADIO_STICK } from "./entrada.js";
import { sonar, desbloquear, silenciar, silenciado } from "./audio.js";

const ORDEN_ARMAS = ["pistola", "subfusil", "escopeta"];
const rnd = (a, b) => a + Math.random() * (b - a);
const rndInt = (a, b) => Math.floor(rnd(a, b + 1));

export class Juego {
  constructor() {
    this.mapa = crearMapa();
    this.estado = "inicio";
    this.ancho = 200; this.alto = 350;
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
      golpe: 0, muerto: 0, sinBlanco: 0, retroceso: 0,
    };
    this.zombis = []; this.balas = []; this.botin = []; this.flotantes = [];
    this.particulas = []; this.fogonazos = [];
    this.oleada = { n: 0, porSalir: 0, t: 0, descanso: 2.5, cartel: 0 };
    this.stats = { bajas: 0, monedas: 0, tiempo: 0, disparos: 0, impactos: 0, dano: 0, recibido: 0 };
    this.camara = { x: s.x - this.ancho / 2, y: s.y - this.alto * 0.6 };
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
    j.arma = a; j.recarga = 0; j.espera = 0.15;
    sonar("recargado");
  }

  empezarRecarga() {
    const j = this.jugador, a = ARMAS[j.arma];
    if (j.recarga > 0 || j.cargador[j.arma] >= a.cargador || j.muerto) return;
    j.recarga = a.recarga;
    sonar("recargar");
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
      if (j.muerto > 2.2 && this.estado === "jugando") this.estado = "fin";
      return;
    }
    leerMovimiento();
    const mx = entrada.mx, my = entrada.my;
    j.andando = Math.hypot(mx, my) > 0.1;
    j.x += mx * JUGADOR.velocidad * dt;
    j.y += my * JUGADOR.velocidad * dt;
    resolverChoques(this.mapa, j, JUGADOR.radio);
    j.anim += dt * (j.andando ? 0.6 + 0.6 * Math.hypot(mx, my) : 1);
    if (j.andando && !this.blanco) j.angulo = Math.atan2(my, mx);
  }

  zombiMasCercano(alcance) {
    const j = this.jugador;
    let mejor = null, md = alcance * alcance;
    for (const z of this.zombis) {
      if (z.muerto || z.aparece > 0.2) continue;
      const d = (z.x - j.x) ** 2 + (z.y - 7 - (j.y - 8)) ** 2;
      if (d < md) { md = d; mejor = z; }
    }
    return mejor;
  }

  // Punto de la mano y de la boca del cañón según el ángulo de apuntado.
  geometriaArma() {
    const j = this.jugador, a = ARMAS[j.arma], spr = S[j.arma];
    const izq = Math.cos(j.angulo) < 0;
    const mano = { x: j.x + (izq ? -2 : 2), y: j.y - 8 };
    const largo = spr.w - a.mano.x - j.retroceso;
    const boca = { x: mano.x + Math.cos(j.angulo) * largo, y: mano.y + Math.sin(j.angulo) * largo };
    return { mano, boca, izq };
  }

  disparar(dt) {
    const j = this.jugador, a = ARMAS[j.arma];
    if (j.muerto) return;
    j.espera = Math.max(0, j.espera - dt);
    j.retroceso = Math.max(0, j.retroceso - dt * 20);
    if (j.recarga > 0) {
      j.recarga -= dt;
      if (j.recarga <= 0) { j.recarga = 0; j.cargador[j.arma] = a.cargador; sonar("recargado"); }
    }
    const z = this.zombiMasCercano(a.alcance);
    this.blanco = z;
    if (z) {
      j.sinBlanco = 0;
      const objetivo = Math.atan2(z.y - 7 - (j.y - 8), z.x - j.x);
      j.angulo = objetivo;
    } else {
      j.sinBlanco += dt;
      if (j.sinBlanco > 1.2 && j.cargador[j.arma] < a.cargador) this.empezarRecarga();
    }
    j.voltear = Math.cos(j.angulo) < 0;
    if (!z || j.recarga > 0 || j.espera > 0) return;
    if (j.cargador[j.arma] <= 0) { this.empezarRecarga(); return; }

    // ¡Fuego!
    j.cargador[j.arma]--;
    j.espera = 1 / a.cadencia;
    j.retroceso = a.perdigones > 1 ? 3 : 1.5;
    const { boca } = this.geometriaArma();
    for (let i = 0; i < a.perdigones; i++) {
      const ang = j.angulo + (Math.random() - 0.5) * (a.dispersion * Math.PI / 180);
      const v = a.velocidadBala * rnd(0.9, 1.1);
      this.balas.push({
        x: boca.x, y: boca.y, px: boca.x, py: boca.y, vx: Math.cos(ang) * v, vy: Math.sin(ang) * v,
        vida: (a.alcance * 1.25) / v, arma: j.arma,
      });
    }
    this.stats.disparos += a.perdigones;
    this.fogonazos.push({ x: boca.x, y: boca.y, ang: j.angulo, t: 0.06 });
    // Casquillo que sale volando
    const lado = j.voltear ? 1 : -1;
    this.particulas.push({
      x: j.x, y: j.y - 9, z: 0, vx: lado * rnd(20, 40), vy: rnd(-10, 10), vz: rnd(40, 70),
      color: a.perdigones > 1 ? "#c0392b" : "#ffe066", vida: 2.5, tam: 1, suelo: j.y - rnd(0, 4),
      casquillo: true,
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
      const lado = Math.random();
      if (lado < 0.7 || c.y > m.alto - this.alto - 40) {        // por arriba, fuera de la pantalla
        x = rnd(10, m.ancho - 10);
        y = c.y - rnd(14, 50);
      } else {                                                  // por un lado
        x = Math.random() < 0.5 ? c.x - 14 : c.x + this.ancho + 14;
        y = c.y + rnd(10, this.alto * 0.5);
      }
      y = Math.max(y, this.jugador.y - OLEADAS.distanciaAparicion - rnd(0, 30));
      if (y < 20) y = rnd(20, 60);
      x = Math.max(8, Math.min(m.ancho - 8, x));
      if (!chocaCon(m, x, y, def.radio + 1)) break;
    }
    const fuerza = 1 + OLEADAS.vidaExtraPorOleada * (this.oleada.n - 1);
    this.zombis.push({
      tipo, def, x, y, vida: def.vida * fuerza, vidaMax: def.vida * fuerza,
      vel: def.velocidad * rnd(0.85, 1.15), anim: rnd(0, 2), voltear: false,
      ataque: 0, espera: rnd(0, 0.5), golpe: 0, muerto: 0, barra: 0,
      atasco: 0, desvio: 0, aparece: 0.6, lado: Math.random() < 0.5 ? 1 : -1, gruñe: rnd(2, 8),
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
        if (!z.charco && z.muerto > 0.55) {
          z.charco = true;
          manchar(m.sueloCtx, z.x + 1, z.y - 1, rndInt(0, 2), 0.85);
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
      z.voltear = dx < 0;

      // Atacar
      if (z.ataque > 0) {
        const antes = z.ataque;
        z.ataque -= dt;
        const golpeEn = duracion(S[z.def.sprite], "atacar") * 0.45;
        if (antes > golpeEn && z.ataque <= golpeEn && d <= z.def.alcance + 6 && !j.muerto) this.herirJugador(z.def.dano);
        if (z.ataque <= 0) z.espera = Math.max(0, z.def.cadencia - duracion(S[z.def.sprite], "atacar"));
        continue;
      }
      z.espera = Math.max(0, z.espera - dt);
      if (d <= z.def.alcance && !j.muerto) {
        if (z.espera <= 0) { z.ataque = duracion(S[z.def.sprite], "atacar"); sonar("zarpazo", 0.05); }
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
    this.sacudida = Math.max(this.sacudida, 2.5);
    this.flotantes.push({ x: j.x, y: j.y - 22, t: 0, txt: "-" + dano, color: "#ff5a5a" });
    sonar("herido", 0.08);
    navigator.vibrate?.(40);
    if (j.vida <= 0) {
      j.muerto = 0.0001;
      j.recarga = 0;
      sonar("muerte");
      navigator.vibrate?.([80, 60, 160]);
      manchar(this.mapa.sueloCtx, j.x, j.y - 1, 0, 0.9);
    }
  }

  // ------------------------------------------------------------------ balas
  moverBalas(dt) {
    for (const b of this.balas) {
      b.px = b.x; b.py = b.y;
      b.x += b.vx * dt; b.y += b.vy * dt;
      b.vida -= dt;
      if (b.vida <= 0) continue;
      // ¿Ha cruzado a algún zombi? (el cuerpo es un círculo de 6 px a media altura)
      for (const z of this.zombis) {
        if (z.muerto || z.aparece > 0.2) continue;
        const cx = z.x, cy = z.y - 8;
        const sx = b.x - b.px, sy = b.y - b.py, l2 = sx * sx + sy * sy || 1;
        const t = Math.max(0, Math.min(1, ((cx - b.px) * sx + (cy - b.py) * sy) / l2));
        const qx = b.px + sx * t, qy = b.py + sy * t;
        if ((qx - cx) ** 2 + (qy - cy) ** 2 < 36) {
          this.impacto(z, b, qx, qy);
          b.vida = 0;
          break;
        }
      }
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
      x: x + rnd(-3, 3), y: y - 6, t: 0, txt: String(Math.round(dano)) + (critico ? "!" : ""),
      color: critico ? "#ffe066" : "#ffffff",
    });
    for (let i = 0; i < (critico ? 6 : 3); i++) {
      this.particulas.push({
        x, y: z.y, z: 8, vx: (b.vx / v) * rnd(15, 45) + rnd(-12, 12), vy: rnd(-8, 8), vz: rnd(10, 45),
        color: Math.random() < 0.5 ? "#b0202c" : "#6e1119", vida: 6, tam: 1, suelo: z.y + rnd(-3, 3), mancha: true,
      });
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
      this.botin.push({ tipo: "moneda", x: z.x + rnd(-4, 4), y: z.y + rnd(-3, 3), z: 6, vz: rnd(30, 60), vx: rnd(-25, 25), vy: rnd(-15, 15), t: 0, anim: rnd(0, 1) });
    }
    if (Math.random() < BOTIN.botiquin) {
      this.botin.push({ tipo: "botiquin", x: z.x, y: z.y, z: 6, vz: 50, vx: 0, vy: 0, t: 0, anim: 0 });
    }
  }

  moverBotin(dt) {
    const j = this.jugador;
    for (const o of this.botin) {
      o.t += dt; o.anim += dt;
      if (o.z > 0 || o.vz > 0) {                     // cae rebotando
        o.vz -= 220 * dt; o.z += o.vz * dt;
        o.x += o.vx * dt; o.y += o.vy * dt;
        if (o.z <= 0) { o.z = 0; o.vz = o.vz < -30 ? -o.vz * 0.35 : 0; o.vx *= 0.5; o.vy *= 0.5; }
      }
      if (j.muerto) continue;
      const dx = j.x - o.x, dy = j.y - 6 - o.y, d = Math.hypot(dx, dy);
      const iman = o.tipo === "moneda" ? JUGADOR.recogerMonedas : 10;
      if (d < iman && o.t > 0.35) {
        const v = 160 * (1 - d / (iman + 1)) + 40;
        o.x += (dx / d) * v * dt; o.y += (dy / d) * v * dt;
      }
      if (d < 6 && o.t > 0.35) {
        if (o.tipo === "moneda") { this.stats.monedas++; sonar("moneda", 0.03); }
        else if (o.tipo === "botiquin") {
          if (j.vida >= JUGADOR.vida) continue;
          const antes = j.vida;
          j.vida = Math.min(JUGADOR.vida, j.vida + BOTIN.curaBotiquin);
          this.flotantes.push({ x: j.x, y: j.y - 24, t: 0, txt: "+" + Math.round(j.vida - antes), color: "#7ee07e" });
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
        p.vz -= 260 * dt; p.z += p.vz * dt;
        p.x += p.vx * dt; p.y += p.vy * dt;
        if (p.z <= 0) {
          p.z = 0; p.vz = 0;
          if (p.mancha) {                              // la gota se queda pintada en el suelo
            const g = this.mapa.sueloCtx;
            g.fillStyle = p.color; g.fillRect(Math.round(p.x), Math.round(p.y), 1, 1);
            p.vida = 0;
          }
        }
      }
    }
    this.particulas = this.particulas.filter((p) => p.vida > 0);
    for (const f of this.fogonazos) f.t -= dt;
    this.fogonazos = this.fogonazos.filter((f) => f.t > 0);
    for (const f of this.flotantes) f.t += dt;
    this.flotantes = this.flotantes.filter((f) => f.t < 0.8);
    this.sacudida = Math.max(0, this.sacudida - dt * 12);
  }

  // ------------------------------------------------------------------ oleadas
  oleadas(dt) {
    const o = this.oleada;
    o.cartel = Math.max(0, o.cartel - dt);
    if (this.jugador.muerto) return;
    if (o.descanso > 0) {
      o.descanso -= dt;
      if (o.descanso <= 0) {
        o.n++;
        o.porSalir = OLEADAS.zombisBase + OLEADAS.zombisPorOleada * (o.n - 1);
        o.t = 0.5;
        o.cartel = 2.2;
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
    if (o.superada) o.superada = Math.max(0, o.superada - dt);
  }

  // ------------------------------------------------------------------ cámara
  moverCamara(dt) {
    const j = this.jugador, c = this.camara, m = this.mapa;
    const ox = j.x - this.ancho / 2;
    const oy = j.y - this.alto * 0.6;          // se ve más por delante (arriba), de donde vienen
    const k = 1 - Math.exp(-dt * 6);
    c.x += (ox - c.x) * k; c.y += (oy - c.y) * k;
    c.x = Math.max(0, Math.min(m.ancho - this.ancho, c.x));
    c.y = Math.max(0, Math.min(m.alto - this.alto, c.y));
    if (m.ancho < this.ancho) c.x = (m.ancho - this.ancho) / 2;
  }

  enPantalla(x, y, margen = 20) {
    const c = this.camara;
    return x > c.x - margen && x < c.x + this.ancho + margen && y > c.y - margen && y < c.y + this.alto + margen + 30;
  }

  // ------------------------------------------------------------------ dibujar
  dibujar(g) {
    const c = this.camara;
    g.fillStyle = "#1a1423";
    g.fillRect(0, 0, this.ancho, this.alto);
    const sx = this.sacudida > 0 ? Math.round(rnd(-1, 1) * this.sacudida) : 0;
    const sy = this.sacudida > 0 ? Math.round(rnd(-1, 1) * this.sacudida) : 0;
    const cx = Math.round(c.x) - sx, cy = Math.round(c.y) - sy;
    g.save();
    g.translate(-cx, -cy);

    // Suelo
    g.drawImage(this.mapa.suelo, cx, cy, this.ancho, this.alto, cx, cy, this.ancho, this.alto);

    // Cadáveres debajo de todo
    for (const z of this.zombis) if (z.muerto) this.dibujarZombi(g, z);

    // Sombras
    g.fillStyle = "rgba(20,14,30,0.35)";
    const sombra = (x, y, rx) => { g.beginPath(); g.ellipse(Math.round(x), Math.round(y), rx, rx * 0.4, 0, 0, Math.PI * 2); g.fill(); };
    const j = this.jugador;
    if (!j.muerto) sombra(j.x, j.y - 0.5, 5);
    for (const z of this.zombis) if (!z.muerto && this.enPantalla(z.x, z.y)) sombra(z.x, z.y - 0.5, 5);
    for (const o of this.mapa.objetos) {
      if (!this.enPantalla(o.x, o.y, 40)) continue;
      if (o.tipo === "arbol") sombra(o.x + 2, o.y - 1, 11);
      else if (o.tipo === "barril" || o.tipo === "hoguera") sombra(o.x, o.y - 1, 6);
    }

    // Todo lo que está de pie, ordenado por la y de los pies
    const cosas = [];
    for (const o of this.mapa.objetos) if (this.enPantalla(o.x, o.y, 40)) cosas.push({ y: o.y, f: () => this.dibujarObjeto(g, o) });
    for (const z of this.zombis) if (!z.muerto && this.enPantalla(z.x, z.y)) cosas.push({ y: z.y, f: () => this.dibujarZombi(g, z) });
    for (const o of this.botin) cosas.push({ y: o.y - 0.5, f: () => this.dibujarBotin(g, o) });
    cosas.push({ y: j.y, f: () => this.dibujarJugador(g) });
    cosas.sort((a, b) => a.y - b.y);
    for (const k of cosas) k.f();

    // Balas, fogonazos, partículas
    for (const b of this.balas) {
      g.strokeStyle = b.arma === "escopeta" ? "#ffd27a" : "#fff3b0";
      g.lineWidth = 1;
      g.beginPath();
      const v = Math.hypot(b.vx, b.vy), l = 4;
      g.moveTo(Math.round(b.x) + 0.5, Math.round(b.y) + 0.5);
      g.lineTo(Math.round(b.x - (b.vx / v) * l) + 0.5, Math.round(b.y - (b.vy / v) * l) + 0.5);
      g.stroke();
    }
    for (const f of this.fogonazos) {
      const spr = S.fogonazo;
      g.save();
      g.translate(Math.round(f.x), Math.round(f.y));
      g.rotate(f.ang);
      dibujar(g, spr, f.t > 0.03 ? 0 : 1, -2, -3);
      g.restore();
    }
    for (const p of this.particulas) {
      g.globalAlpha = p.casquillo && p.vida < 0.5 ? p.vida * 2 : 1;
      g.fillStyle = p.color;
      g.fillRect(Math.round(p.x), Math.round(p.y - p.z), p.casquillo ? 2 : 1, 1);
    }
    g.globalAlpha = 1;

    // Barras de vida de zombis heridos y números de daño
    for (const z of this.zombis) {
      if (z.muerto || z.barra <= 0 || z.vida >= z.vidaMax) continue;
      const w = 12, x = Math.round(z.x - w / 2), y = Math.round(z.y - 22);
      g.fillStyle = "#1a1423"; g.fillRect(x - 1, y - 1, w + 2, 4);
      g.fillStyle = "#6e1119"; g.fillRect(x, y, w, 2);
      g.fillStyle = "#e0402f"; g.fillRect(x, y, Math.max(1, Math.round(w * z.vida / z.vidaMax)), 2);
    }
    for (const f of this.flotantes) {
      g.globalAlpha = f.t > 0.55 ? 1 - (f.t - 0.55) / 0.25 : 1;
      texto(g, f.txt, f.x, f.y - f.t * 18, f.color, "centro");
    }
    g.globalAlpha = 1;
    g.restore();

    // Pantalla roja al recibir daño y viñeta cuando queda poca vida
    if (j.golpe > 0) {
      g.fillStyle = `rgba(200,20,30,${j.golpe * 1.4})`;
      g.fillRect(0, 0, this.ancho, this.alto);
    }
    if (!j.muerto && j.vida <= 30) {
      const a = 0.18 + 0.12 * Math.sin(this.t * 6);
      g.strokeStyle = `rgba(176,32,44,${a})`;
      g.lineWidth = 6;
      g.strokeRect(0, 0, this.ancho, this.alto);
    }
    this.dibujarInterfaz(g);
  }

  dibujarJugador(g) {
    const j = this.jugador, spr = S.jugador;
    const x = j.x - 8, y = j.y - 20;
    if (j.muerto) {
      dibujar(g, spr, fotograma(spr, "morir", j.muerto, false), x, y, j.voltear);
      return;
    }
    const i = fotograma(spr, j.andando ? "correr" : "quieto", j.anim);
    const img = j.golpe > 0 ? (Math.floor(j.golpe * 30) % 2 ? spr.roja : spr.blanca) : spr.img;
    dibujar(g, spr, i, x, y, j.voltear, img);
    // Arma girada hacia donde apunta
    const a = ARMAS[j.arma], arma = S[j.arma];
    const { mano, izq } = this.geometriaArma();
    g.save();
    g.translate(Math.round(mano.x), Math.round(mano.y + (i === 1 || i === 2 || i === 4 ? 1 : 0)));
    g.rotate(j.angulo);
    if (izq) g.scale(1, -1);
    // durante la recarga el arma baja un poco
    if (j.recarga > 0) g.rotate(0.6 * Math.sin(Math.PI * (1 - j.recarga / a.recarga)));
    dibujar(g, arma, 0, -a.mano.x - Math.round(j.retroceso), -a.mano.y);
    g.restore();
  }

  dibujarZombi(g, z) {
    const spr = S[z.def.sprite];
    const x = z.x - 8, y = z.y - 20;
    if (z.muerto) {
      if (z.muerto > 7) g.globalAlpha = Math.max(0, 1 - (z.muerto - 7) / 2);
      dibujar(g, spr, fotograma(spr, "morir", z.muerto, false), x, y, z.voltear);
      g.globalAlpha = 1;
      return;
    }
    let i;
    if (z.ataque > 0) i = fotograma(spr, "atacar", duracion(spr, "atacar") - z.ataque, false);
    else i = fotograma(spr, "andar", z.anim * (z.vel / z.def.velocidad));
    if (z.aparece > 0) {                 // sale de la tierra
      const k = 1 - z.aparece / 0.6, alto = Math.round(20 * k);
      const f = spr.frames[i];
      g.save();
      g.beginPath(); g.rect(Math.round(x) - 2, Math.round(z.y) - alto, 20, alto); g.clip();
      dibujar(g, spr, i, x, y + (20 - alto) * 0.4, z.voltear);
      g.restore();
      g.fillStyle = "#6b5033";
      g.fillRect(Math.round(z.x) - 5, Math.round(z.y) - 1, 10, 2);
      return;
    }
    dibujar(g, spr, i, x, y, z.voltear, z.golpe > 0 ? spr.blanca : spr.img);
  }

  dibujarObjeto(g, o) {
    const spr = S[o.tipo];
    const i = o.tipo === "hoguera" ? fotograma(spr, "arder", this.t + o.t0) : 0;
    dibujar(g, spr, i, o.x - spr.w / 2, o.y - spr.h);
    if (o.tipo === "hoguera") {          // resplandor
      g.globalAlpha = 0.10 + 0.04 * Math.sin((this.t + o.t0) * 9);
      g.fillStyle = "#ffb03a";
      g.beginPath(); g.arc(o.x, o.y - 12, 22, 0, Math.PI * 2); g.fill();
      g.globalAlpha = 1;
    }
  }

  dibujarBotin(g, o) {
    const spr = S[o.tipo];
    if (o.t > BOTIN.duracionEnSuelo - 3 && Math.floor(o.t * 8) % 2) return;   // parpadea antes de irse
    const i = o.tipo === "moneda" ? fotograma(spr, "girar", o.anim) : 0;
    const flota = o.tipo === "botiquin" && o.z === 0 ? Math.round(Math.sin(o.t * 4)) : 0;
    dibujar(g, spr, i, o.x - spr.w / 2, o.y - spr.h - o.z + flota);
  }

  // ------------------------------------------------------------------ interfaz
  boton(x, y, w, h, accion) { entrada.botones.push({ x, y, w, h, accion }); }

  dibujarInterfaz(g) {
    const W = this.ancho, H = this.alto, j = this.jugador;

    if (this.estado === "inicio") return this.pantallaInicio(g);

    // Vida
    const corazon = S.corazon;
    dibujar(g, corazon, 0, 4, 4);
    const bw = 56;
    g.fillStyle = "#1a1423"; g.fillRect(15, 5, bw + 2, 7);
    g.fillStyle = "#4a1018"; g.fillRect(16, 6, bw, 5);
    const pv = j.vida / JUGADOR.vida;
    g.fillStyle = pv > 0.5 ? "#5fbf4a" : pv > 0.25 ? "#e6b13a" : "#e0402f";
    g.fillRect(16, 6, Math.round(bw * pv), 5);
    g.fillStyle = "rgba(255,255,255,0.35)"; g.fillRect(16, 6, Math.round(bw * pv), 1);
    texto(g, Math.ceil(j.vida), 16 + bw + 4, 6);

    // Oleada, bajas y monedas
    const o = this.oleada;
    texto(g, "OLEADA " + Math.max(1, o.n), W / 2, 18, "#ffe066", "centro");
    texto(g, "BAJAS " + this.stats.bajas, 4, 18, "#c9d3dd");
    const mon = S.moneda;
    const txtM = String(this.stats.monedas);
    const xm = W - 4 - anchoTexto(txtM);
    dibujar(g, mon, 0, xm - 9, 17);
    texto(g, txtM, W - 4, 18, "#ffe066", "der");

    // Pausa y sonido
    const bx = W - 13;
    g.fillStyle = "#1a1423"; g.fillRect(bx, 3, 10, 10);
    g.fillStyle = "#3b3450"; g.fillRect(bx + 1, 4, 8, 8);
    g.fillStyle = "#ffffff"; g.fillRect(bx + 3, 6, 1, 4); g.fillRect(bx + 6, 6, 1, 4);
    this.boton(bx - 3, 0, 16, 16, () => { sonar("boton"); this.pausar(); });

    // Armas (abajo a la derecha). De momento se pueden elegir todas para probarlas.
    const slotW = 26, slotH = 18, gap = 2;
    const x0 = W - (slotW + gap) * ORDEN_ARMAS.length - 2, y0 = H - slotH - 6;
    ORDEN_ARMAS.forEach((nombre, k) => {
      const x = x0 + k * (slotW + gap), sel = nombre === j.arma;
      g.fillStyle = "#1a1423"; g.fillRect(x, y0, slotW, slotH);
      g.fillStyle = sel ? "#4b6fa8" : "#2a2438"; g.fillRect(x + 1, y0 + 1, slotW - 2, slotH - 2);
      if (sel) { g.fillStyle = "#ffe066"; g.fillRect(x + 1, y0 + 1, slotW - 2, 1); }
      const spr = S[nombre];
      dibujar(g, spr, 0, x + Math.floor((slotW - spr.w) / 2), y0 + 3 + Math.floor((8 - spr.h) / 2));
      texto(g, String(k + 1), x + 2, y0 + slotH - 7, sel ? "#ffe066" : "#7d7d88", "izq", 1, null);
      this.boton(x, y0 - 4, slotW, slotH + 8, () => this.cambiarArma(nombre));
    });
    // Munición y recarga encima de las armas
    const a = ARMAS[j.arma];
    const yMun = y0 - 9;
    if (j.recarga > 0) {
      const w = 40, x = W - 4 - w;
      g.fillStyle = "#1a1423"; g.fillRect(x - 1, yMun, w + 2, 6);
      g.fillStyle = "#e6b13a"; g.fillRect(x, yMun + 1, Math.round(w * (1 - j.recarga / a.recarga)), 4);
      texto(g, "RECARGANDO", x - 3, yMun, "#ffffff", "der");
    } else {
      const quedan = j.cargador[j.arma];
      texto(g, a.nombre + "  " + quedan + "/" + a.cargador, W - 4, yMun, quedan === 0 ? "#ff5a5a" : "#ffffff", "der");
    }

    // Joystick
    const st = entrada.stick, js = S.joystick;
    if (st && !j.muerto) {
      g.globalAlpha = 0.55;
      dibujar(g, js, 0, st.ox - 17, st.oy - 17);
      g.globalAlpha = 0.9;
      let dx = st.x - st.ox, dy = st.y - st.oy;
      const l = Math.hypot(dx, dy);
      if (l > RADIO_STICK) { dx = dx / l * RADIO_STICK; dy = dy / l * RADIO_STICK; }
      dibujar(g, js, 1, st.ox + dx - 17, st.oy + dy - 17);
      g.globalAlpha = 1;
    } else if (this.estado === "jugando" && this.t < 8) {
      g.globalAlpha = 0.25 + 0.15 * Math.sin(this.t * 4);
      dibujar(g, js, 0, 18, H - 52);
      dibujar(g, js, 1, 18, H - 52);
      g.globalAlpha = 1;
      texto(g, "ARRASTRA PARA MOVERTE", 35, H - 60, "#ffffff", "centro");
    }

    // Carteles
    if (o.cartel > 0) {
      const a2 = Math.min(1, o.cartel * 2);
      g.globalAlpha = a2;
      texto(g, "OLEADA " + o.n, W / 2, H * 0.32, "#ffe066", "centro", 3);
      g.globalAlpha = 1;
    } else if (o.superada > 0) {
      texto(g, "OLEADA SUPERADA", W / 2, H * 0.32, "#7ee07e", "centro", 2);
    }

    if (this.estado === "pausa") this.pantallaPausa(g);
    if (this.estado === "fin") this.pantallaFin(g);
  }

  velo(g, a = 0.65) {
    g.fillStyle = `rgba(16,10,24,${a})`;
    g.fillRect(0, 0, this.ancho, this.alto);
  }

  botonGrande(g, txt, y, accion, color = "#4b6fa8") {
    const w = anchoTexto(txt, 2) + 16, h = 20, x = Math.round(this.ancho / 2 - w / 2);
    g.fillStyle = "#1a1423"; g.fillRect(x, y, w, h);
    g.fillStyle = color; g.fillRect(x + 1, y + 1, w - 2, h - 2);
    g.fillStyle = "rgba(255,255,255,0.25)"; g.fillRect(x + 1, y + 1, w - 2, 1);
    texto(g, txt, this.ancho / 2, y + 5, "#ffffff", "centro", 2);
    this.boton(x, y, w, h, accion);
  }

  pantallaInicio(g) {
    const W = this.ancho, H = this.alto;
    this.velo(g, 0.55);
    texto(g, "HORDA", W / 2, H * 0.2, "#e0402f", "centro", 5);
    texto(g, "PIXEL", W / 2, H * 0.2 + 30, "#ffe066", "centro", 3);
    // Personaje y zombis de adorno
    const t = performance.now() / 1000;
    const spr = S.jugador, z = S.zombi;
    g.save(); g.translate(W / 2 - 16, H * 0.47); g.scale(2, 2);
    dibujar(g, spr, fotograma(spr, "quieto", t), 0, 0);
    g.restore();
    g.save(); g.translate(W / 2 + 22, H * 0.47); g.scale(2, 2);
    dibujar(g, z, fotograma(z, "andar", t), 0, 0, true);
    g.restore();
    if (Math.floor(t * 2) % 2 === 0) texto(g, "TOCA PARA EMPEZAR", W / 2, H * 0.68, "#ffffff", "centro");
    texto(g, "ARRASTRA EL DEDO PARA MOVERTE", W / 2, H * 0.78, "#c9d3dd", "centro");
    texto(g, "DISPARAS SOLO AL ZOMBI MÁS CERCANO", W / 2, H * 0.78 + 9, "#c9d3dd", "centro");
    texto(g, "PROTOTIPO 0.1", W / 2, H - 10, "#7d7d88", "centro");
    this.boton(0, 0, W, H, () => this.empezar());
  }

  pantallaPausa(g) {
    const W = this.ancho, H = this.alto;
    this.velo(g);
    texto(g, "PAUSA", W / 2, H * 0.25, "#ffffff", "centro", 3);
    this.botonGrande(g, "SEGUIR", H * 0.42, () => { sonar("boton"); this.pausar(); });
    this.botonGrande(g, silenciado() ? "SONIDO: NO" : "SONIDO: SÍ", H * 0.42 + 28, () => { silenciar(!silenciado()); sonar("boton"); }, "#3b3450");
    this.botonGrande(g, "REINICIAR", H * 0.42 + 56, () => this.empezar(), "#8a3a3a");
  }

  pantallaFin(g) {
    const W = this.ancho, H = this.alto, s = this.stats;
    this.velo(g, 0.72);
    texto(g, "HAS MUERTO", W / 2, H * 0.16, "#e0402f", "centro", 3);
    const filas = [
      ["OLEADA", this.oleada.n],
      ["BAJAS", s.bajas],
      ["MONEDAS", s.monedas],
      ["TIEMPO", Math.floor(s.tiempo / 60) + ":" + String(Math.floor(s.tiempo % 60)).padStart(2, "0")],
      ["PUNTERÍA", (s.disparos ? Math.round(100 * s.impactos / s.disparos) : 0) + "%"],
      ["DAÑO HECHO", Math.round(s.dano)],
      ["DAÑO RECIBIDO", Math.round(s.recibido)],
    ];
    filas.forEach(([k, v], i) => {
      const y = H * 0.3 + i * 11;
      texto(g, k, W / 2 - 60, y, "#c9d3dd");
      texto(g, v, W / 2 + 60, y, "#ffe066", "der");
    });
    this.botonGrande(g, "OTRA VEZ", H * 0.3 + filas.length * 11 + 14, () => this.empezar(), "#4b8a3a");
  }
}
