// Sonidos sintetizados con Web Audio: no hacen falta archivos.
// El navegador del móvil solo deja sonar después del primer toque (desbloquear()).

let ctx = null;
let maestro = null;
let ruido = null;
let silencio = false;
const ultimo = {};   // evita que 20 zombis gruñan en el mismo instante

export function desbloquear() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    ctx = new AC();
    maestro = ctx.createGain();
    maestro.gain.value = 0.55;
    const comp = ctx.createDynamicsCompressor();
    maestro.connect(comp).connect(ctx.destination);
    ruido = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
    const d = ruido.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  }
  if (ctx.state === "suspended") ctx.resume();
}

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

const SONIDOS = {
  pistola() {
    golpeDeRuido(0.7, 0.11, "lowpass", 2600);
    tono("triangle", 180, 50, 0.5, 0.09);
  },
  subfusil() {
    golpeDeRuido(0.45, 0.06, "bandpass", 1900, 0.7);
    tono("square", 140, 60, 0.15, 0.05);
  },
  escopeta() {
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
  if (!ctx || silencio || ctx.state !== "running") return;
  const ahora = ctx.currentTime;
  if (minimo && ultimo[nombre] && ahora - ultimo[nombre] < minimo) return;
  ultimo[nombre] = ahora;
  SONIDOS[nombre]?.();
}
