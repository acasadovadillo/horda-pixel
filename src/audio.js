// Sonidos sintetizados con Web Audio: no hacen falta archivos.
// El navegador del móvil solo deja sonar después del primer toque (desbloquear()).

let ctx = null;
let maestro = null;
let ruido = null;
let silencio = false;
const ultimo = {};   // evita que 20 zombis gruñan en el mismo instante

export function desbloquear() {
  // iPhone: sin esto, Web Audio se calla cuando el interruptor de silencio está puesto
  // (iOS lo trata como sonido «ambiente»). Con "playback" suena como un juego o un vídeo.
  try { if (navigator.audioSession) navigator.audioSession.type = "playback"; } catch (e) { /* no disponible */ }
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    ctx = new AC();
    maestro = ctx.createGain();
    maestro.gain.value = silencio ? 0 : 0.55;
    const comp = ctx.createDynamicsCompressor();
    maestro.connect(comp).connect(ctx.destination);
    ruido = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
    const d = ruido.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    cargarGrabaciones();
  }
  if (ctx.state !== "running") {
    ctx.resume().catch(() => {});
    // Safari solo arranca el audio si suena algo dentro del propio toque: un instante de silencio.
    try {
      const b = ctx.createBuffer(1, 1, ctx.sampleRate);
      const src = ctx.createBufferSource();
      src.buffer = b;
      src.connect(ctx.destination);
      src.start(0);
    } catch (e) { /* nada */ }
  }
}

// En iPhone el permiso de sonido llega con el toque al levantar el dedo (touchend / click),
// no al apoyarlo; por eso se intenta en todos esos momentos, no solo al empezar la partida.
for (const ev of ["touchend", "pointerup", "click", "keydown"]) {
  window.addEventListener(ev, desbloquear, { capture: true, passive: true });
}
// Al volver a la app (después de una llamada o de bloquear el móvil) el audio queda parado.
document.addEventListener("visibilitychange", () => {
  if (!document.hidden && ctx && ctx.state !== "running") ctx.resume().catch(() => {});
});

export function silenciar(s) { silencio = s; if (maestro) maestro.gain.value = s ? 0 : 0.55; }
export function silenciado() { return silencio; }

function env(g, t, ataque, vol, caida) {
  g.gain.setValueAtTime(0.0001, t);
  g.gain.exponentialRampToValueAtTime(vol, t + ataque);
  g.gain.exponentialRampToValueAtTime(0.0001, t + ataque + caida);
}

function golpeDeRuido(vol, dur, filtro, freq, q = 0.8, retraso = 0) {
  const t = ctx.currentTime + retraso;
  const src = ctx.createBufferSource();
  src.buffer = ruido;
  src.playbackRate.value = 0.8 + Math.random() * 0.4;
  const f = ctx.createBiquadFilter();
  f.type = filtro; f.frequency.value = freq; f.Q.value = q;
  const g = ctx.createGain();
  env(g, t, 0.002, vol, dur);
  src.connect(f).connect(g).connect(maestro);
  src.start(t, Math.random() * 0.5);
  src.stop(t + dur + 0.05);
}

function tono(tipo, f0, f1, vol, dur, retraso = 0) {
  const t = ctx.currentTime + retraso;
  const o = ctx.createOscillator();
  o.type = tipo;
  o.frequency.setValueAtTime(f0, t);
  o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur);
  const g = ctx.createGain();
  env(g, t, 0.004, vol, dur);
  o.connect(g).connect(maestro);
  o.start(t);
  o.stop(t + dur + 0.05);
}

// ---------------------------------------------------------------- grabaciones reales
// Recortes de grabaciones de Freesound con licencia CC0 (ver sonido/CREDITOS.md y sonido/recortar.py).
const GRABACIONES = [
  "glock_disparo", "glock_cargador_fuera", "glock_cargador_dentro", "glock_corredera",
  "mp5_disparo_1", "mp5_disparo_2", "mp5_disparo_3", "mp5_recarga",
  "remington_disparo", "remington_corredera", "remington_corredera_rapida",
  "remington_cartucho_1", "remington_cartucho_2", "remington_cartucho_3",
];
const buffers = {};

function decodificar(datos) {
  // Safari antiguo solo acepta la versión con funciones de vuelta.
  return new Promise((ok, mal) => {
    const p = ctx.decodeAudioData(datos, ok, mal);
    if (p && p.then) p.then(ok, mal);
  });
}

function cargarGrabaciones() {
  for (const n of GRABACIONES) {
    fetch("assets/sonido/" + n + ".m4a")
      .then((r) => (r.ok ? r.arrayBuffer() : Promise.reject(new Error(r.status))))
      .then(decodificar)
      .then((b) => { buffers[n] = b; })
      .catch(() => { /* si falla, se usa el sonido sintetizado */ });
  }
}

// Reproduce una grabación. Devuelve el nodo (para poder pararlo) o null si no está cargada.
function grabacion(nombre, vol = 1, retraso = 0, velocidad = 1) {
  const b = buffers[nombre];
  if (!b) return null;
  const src = ctx.createBufferSource();
  src.buffer = b;
  src.playbackRate.value = velocidad;
  const g = ctx.createGain();
  g.gain.value = vol;
  src.connect(g).connect(maestro);
  src.start(ctx.currentTime + retraso);
  return src;
}

const variacion = () => 0.96 + Math.random() * 0.08;

// Sonidos de recarga que siguen sonando: se cortan si cambias de arma a mitad.
let recargaSonando = [];

export function cancelarRecarga() {
  for (const s of recargaSonando) { try { s.stop(); } catch (e) { /* ya había acabado */ } }
  recargaSonando = [];
}

// Recarga completa de cada arma, repartida a lo largo de su tiempo de recarga (s).
export function sonarRecarga(arma, dur) {
  if (!ctx || silencio || ctx.state !== "running") return;
  cancelarRecarga();
  const pasos = {
    pistola: [["glock_cargador_fuera", 0.02, 0.9], ["glock_cargador_dentro", dur * 0.5, 1], ["glock_corredera", dur * 0.74, 0.9]],
    subfusil: [["mp5_recarga", Math.max(0, dur - 1.55), 1]],
    escopeta: [],      // la escopeta suena cartucho a cartucho: sonarCartucho() y sonarCorredera()
  }[arma] || [];
  let alguna = false;
  for (const [n, t, v] of pasos) {
    const s = grabacion(n, v, t);
    if (s) { recargaSonando.push(s); alguna = true; }
  }
  if (!alguna && arma !== "escopeta") SONIDOS.recargar();
}

// Un cartucho entrando en el tubo de la escopeta.
export function sonarCartucho() {
  if (!ctx || silencio || ctx.state !== "running") return;
  const n = 1 + Math.floor(Math.random() * 3);
  if (grabacion("remington_cartucho_" + n, 0.95, 0, variacion())) return;
  // Respaldo sintetizado: roce del cartucho y clic del retén.
  golpeDeRuido(0.18, 0.06, "bandpass", 1200, 1.2);
  golpeDeRuido(0.35, 0.03, "bandpass", 2600, 3, 0.07);
}

// Corredera de la escopeta (al acabar de recargar con la recámara vacía).
export function sonarCorredera() {
  if (!ctx || silencio || ctx.state !== "running") return;
  if (grabacion("remington_corredera_rapida", 0.95)) return;
  golpeDeRuido(0.3, 0.05, "highpass", 3000, 0.7);
  golpeDeRuido(0.3, 0.05, "highpass", 2500, 0.7, 0.12);
}

const SONIDOS = {
  pistola() {
    if (grabacion("glock_disparo", 0.95, 0, variacion())) return;
    golpeDeRuido(0.7, 0.11, "lowpass", 2600);
    tono("triangle", 180, 50, 0.5, 0.09);
  },
  subfusil() {
    if (grabacion("mp5_disparo_" + (1 + Math.floor(Math.random() * 3)), 0.85, 0, variacion())) return;
    golpeDeRuido(0.45, 0.06, "bandpass", 1900, 0.7);
    tono("square", 140, 60, 0.15, 0.05);
  },
  escopeta() {
    if (grabacion("remington_disparo", 1, 0, variacion())) {
      grabacion("remington_corredera_rapida", 0.8, 0.32);   // corredera tras cada disparo
      return;
    }
    golpeDeRuido(1.0, 0.32, "lowpass", 1500);
    tono("triangle", 120, 35, 0.8, 0.22);
    golpeDeRuido(0.25, 0.05, "highpass", 3000, 0.7, 0.42);       // bombeo
    golpeDeRuido(0.25, 0.05, "highpass", 2500, 0.7, 0.52);
  },
  recargar() {
    golpeDeRuido(0.3, 0.03, "highpass", 3500, 1);
    golpeDeRuido(0.35, 0.04, "highpass", 2200, 1, 0.16);
  },
  recargado() { golpeDeRuido(0.4, 0.05, "bandpass", 1500, 2); },
  impacto() { golpeDeRuido(0.35, 0.05, "lowpass", 900); },
  gruñido() {
    const t = ctx.currentTime;
    const o = ctx.createOscillator();
    o.type = "sawtooth";
    const base = 70 + Math.random() * 40;
    o.frequency.setValueAtTime(base, t);
    o.frequency.linearRampToValueAtTime(base * 0.7, t + 0.6);
    const lfo = ctx.createOscillator(); lfo.frequency.value = 9 + Math.random() * 6;
    const lg = ctx.createGain(); lg.gain.value = 12;
    lfo.connect(lg).connect(o.frequency);
    const f = ctx.createBiquadFilter(); f.type = "lowpass"; f.frequency.value = 600;
    const g = ctx.createGain(); env(g, t, 0.08, 0.18, 0.55);
    o.connect(f).connect(g).connect(maestro);
    o.start(t); lfo.start(t); o.stop(t + 0.7); lfo.stop(t + 0.7);
  },
  muereZombi() {
    tono("sawtooth", 120, 40, 0.25, 0.35);
    golpeDeRuido(0.4, 0.15, "lowpass", 500, 0.8, 0.05);
  },
  zarpazo() { golpeDeRuido(0.4, 0.08, "bandpass", 1200, 1.5); },
  herido() {
    tono("square", 300, 120, 0.25, 0.14);
    golpeDeRuido(0.4, 0.1, "lowpass", 700);
  },
  moneda() {
    tono("square", 990, 990, 0.12, 0.06);
    tono("square", 1480, 1480, 0.12, 0.12, 0.06);
  },
  curar() {
    tono("triangle", 520, 520, 0.25, 0.1);
    tono("triangle", 780, 780, 0.25, 0.18, 0.1);
  },
  oleada() {
    tono("sawtooth", 110, 110, 0.25, 0.5);
    tono("sawtooth", 165, 165, 0.2, 0.5);
    tono("sawtooth", 110, 82, 0.25, 0.6, 0.5);
  },
  muerte() {
    tono("sawtooth", 220, 55, 0.4, 1.1);
    tono("square", 110, 40, 0.3, 1.2, 0.1);
  },
  boton() { tono("square", 660, 660, 0.1, 0.04); },
};

// Reproduce un sonido; minimo = segundos mínimos entre dos iguales.
export function sonar(nombre, minimo = 0) {
  if (!ctx || silencio) return;
  if (ctx.state !== "running") { ctx.resume().catch(() => {}); return; }
  const ahora = ctx.currentTime;
  if (minimo && ultimo[nombre] && ahora - ultimo[nombre] < minimo) return;
  ultimo[nombre] = ahora;
  SONIDOS[nombre]?.();
}

// Para comprobar en pruebas: "running" si el audio está activo.
export function estadoAudio() { return (ctx ? ctx.state : "sin crear") + ", grabaciones " + Object.keys(buffers).length + "/" + GRABACIONES.length; }
