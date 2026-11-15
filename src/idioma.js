// Textos del juego en español y en inglés (EE. UU.). t("clave") devuelve el del idioma actual.
// El idioma elegido se guarda en este navegador; la primera vez se toma el del sistema.

const TEXTOS = {
  es: {
    bajas: "BAJAS", oleada: "OLEADA", oleadaSuperada: "OLEADA SUPERADA",
    recargando: "RECARGANDO", muevete: "MUÉVETE AQUÍ",
    pistola: "PISTOLA", subfusil: "SUBFUSIL", escopeta: "ESCOPETA",
    tocaEmpezar: "TOCA PARA EMPEZAR",
    ayudaMover: "MUÉVETE CON EL JOYSTICK DE ABAJO A LA IZQUIERDA",
    ayudaDisparo: "DISPARAS SOLO AL ZOMBI MÁS CERCANO",
    prototipo: "PROTOTIPO",
    pausa: "PAUSA", seguir: "SEGUIR", sonidoSi: "SONIDO: SÍ", sonidoNo: "SONIDO: NO", reiniciar: "REINICIAR",
    hasMuerto: "HAS MUERTO", otraVez: "OTRA VEZ",
    monedas: "MONEDAS", tiempo: "TIEMPO", punteria: "PUNTERÍA", danoHecho: "DAÑO HECHO", danoRecibido: "DAÑO RECIBIDO",
    girar: "Gira el móvil<br>para jugar en horizontal", cargando: "Cargando…",
  },
  en: {
    bajas: "KILLS", oleada: "WAVE", oleadaSuperada: "WAVE CLEARED",
    recargando: "RELOADING", muevete: "MOVE HERE",
    pistola: "PISTOL", subfusil: "SMG", escopeta: "SHOTGUN",
    tocaEmpezar: "TAP TO START",
    ayudaMover: "MOVE WITH THE JOYSTICK AT THE BOTTOM LEFT",
    ayudaDisparo: "YOU SHOOT THE CLOSEST ZOMBIE AUTOMATICALLY",
    prototipo: "PROTOTYPE",
    pausa: "PAUSED", seguir: "RESUME", sonidoSi: "SOUND: ON", sonidoNo: "SOUND: OFF", reiniciar: "RESTART",
    hasMuerto: "YOU DIED", otraVez: "PLAY AGAIN",
    monedas: "COINS", tiempo: "TIME", punteria: "ACCURACY", danoHecho: "DAMAGE DEALT", danoRecibido: "DAMAGE TAKEN",
    girar: "Rotate your phone<br>to play in landscape", cargando: "Loading…",
  },
};

export const IDIOMAS = ["es", "en"];
const CLAVE = "horda-pixel:idioma";

function inicial() {
  try {
    const g = localStorage.getItem(CLAVE);
    if (IDIOMAS.includes(g)) return g;
  } catch (e) { /* sin almacenamiento: se usa el del sistema */ }
  return (navigator.language || "es").toLowerCase().startsWith("es") ? "es" : "en";
}

let actual = inicial();

export function idioma() { return actual; }

export function t(clave) { return TEXTOS[actual][clave] ?? TEXTOS.es[clave] ?? clave; }

export function cambiarIdioma(nuevo = actual === "es" ? "en" : "es") {
  actual = nuevo;
  try { localStorage.setItem(CLAVE, actual); } catch (e) { /* no pasa nada si no se guarda */ }
  aplicarAPagina();
}

// Textos que están en la página HTML (fuera del lienzo del juego).
export function aplicarAPagina() {
  document.documentElement.lang = actual === "es" ? "es" : "en-US";
  const girar = document.querySelector("#girar div");
  if (girar) girar.innerHTML = t("girar");
  const cargando = document.getElementById("cargando");
  if (cargando) cargando.textContent = t("cargando");
}
