// Arranque: lienzo a resolución baja escalado por un número entero para que los píxeles salgan nítidos.
import { cargarSprites } from "./sprites.js";
import { iniciarEntrada, entrada } from "./entrada.js";
import { Juego } from "./juego.js";
import { PANTALLA } from "./config.js";
import { ANCHO, T } from "./mapa.js";

const lienzo = document.getElementById("juego");
const g = lienzo.getContext("2d");
const bajo = document.createElement("canvas");      // aquí se dibuja el juego a 1x
const gb = bajo.getContext("2d");
let escala = 1, juego = null;

function ajustar() {
  const dpr = window.devicePixelRatio || 1;
  const marco = document.getElementById("marco");
  const devW = Math.floor(marco.clientWidth * dpr), devH = Math.floor(marco.clientHeight * dpr);
  // Escala entera: con escalas como 2,5 los píxeles salen desiguales y la letra pequeña se deforma.
  const k = Math.min(devW / PANTALLA.anchoMinimo, devH / PANTALLA.altoMinimo);
  escala = Math.max(1, Math.floor(k));
  // En un móvil en vertical se pide girarlo.
  const tactil = matchMedia("(pointer: coarse)").matches;
  document.body.classList.toggle("girar", tactil && marco.clientHeight > marco.clientWidth);
  const w = Math.min(Math.floor(devW / escala), ANCHO * T);   // nunca más ancho que el mapa
  const h = Math.floor(devH / escala);
  bajo.width = w; bajo.height = h;
  lienzo.width = w * escala; lienzo.height = h * escala;
  lienzo.style.width = (w * escala) / dpr + "px";
  lienzo.style.height = (h * escala) / dpr + "px";
  if (juego) {
    juego.ancho = w; juego.alto = h;
    // Márgenes seguros (muesca, esquinas redondeadas, barra de inicio) en píxeles de juego
    const cs = getComputedStyle(document.getElementById("seguro"));
    const enJuego = (v) => Math.ceil((parseFloat(v) || 0) * dpr / escala);
    juego.seguro = { izq: enJuego(cs.paddingLeft), der: enJuego(cs.paddingRight), arr: enJuego(cs.paddingTop), aba: enJuego(cs.paddingBottom) };
  }
}

function aJuego(cx, cy) {
  const r = lienzo.getBoundingClientRect();
  return { x: ((cx - r.left) / r.width) * bajo.width, y: ((cy - r.top) / r.height) * bajo.height };
}

function pintar() {
  gb.imageSmoothingEnabled = false;
  juego.dibujar(gb);
  g.imageSmoothingEnabled = false;
  g.drawImage(bajo, 0, 0, lienzo.width, lienzo.height);
}

async function arrancar() {
  // ?assets=carpeta permite probar con otro juego de sprites (por ejemplo los maniquíes de arte/maniquies.py)
  const carpeta = new URLSearchParams(location.search).get("assets");
  await cargarSprites(/^[a-z0-9_-]+$/i.test(carpeta || "") ? carpeta + "/" : "assets/");
  juego = new Juego();
  ajustar();
  window.addEventListener("resize", ajustar);
  window.addEventListener("orientationchange", () => setTimeout(ajustar, 300));
  iniciarEntrada(lienzo, aJuego);
  document.getElementById("cargando")?.remove();

  let antes = performance.now();
  const bucle = (ahora) => {
    const dt = Math.min(0.05, (ahora - antes) / 1000);
    antes = ahora;
    juego.actualizar(dt);
    pintar();
    entrada.tocado = false;
    requestAnimationFrame(bucle);
  };
  requestAnimationFrame(bucle);

  // Para pruebas automáticas (el panel oculto del navegador frena requestAnimationFrame).
  window.__juego = juego;
  window.__avanzar = (seg, paso = 1 / 60) => {
    for (let t = 0; t < seg; t += paso) juego.actualizar(paso);
    pintar();
  };
}

// Como app instalada: guarda una copia para abrir sin conexión (no en el servidor local de pruebas).
if ("serviceWorker" in navigator && !/^(localhost|127\.0\.0\.1)$/.test(location.hostname)) {
  navigator.serviceWorker.register("sw.js").catch(() => {});
}

arrancar().catch((e) => {
  document.body.insertAdjacentHTML("beforeend", `<pre style="color:#f66">${e.stack || e}</pre>`);
});
