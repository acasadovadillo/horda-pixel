// Textos del juego en español y en inglés (EE. UU.). t("clave") devuelve el del idioma actual.
// El idioma elegido se guarda en este navegador; la primera vez se toma el del sistema.

const TEXTOS = {
  es: {
    bajas: "BAJAS", oleada: "RONDA", oleadaSuperada: "RONDA SUPERADA",
    listo: "LISTO", tienda: "TIENDA", ayudaDescanso: "COMPRA LO QUE NECESITES Y PULSA LISTO", vuelveBase: "VUELVE A LA BASE PARA COMPRAR",
    seCompra: "SE COMPRA EN LA TIENDA", sinBalas: "SIN BALAS", a: "A",
    tab_armas: "ARMAS", tab_municion: "MUNICIÓN", tab_curacion: "CURACIÓN", tab_mejoras: "MEJORAS", tab_defensas: "DEFENSAS",
    tuya: "TUYA", lleno: "LLENO", maximo: "MÁXIMO", sinArma: "SIN ARMA", intacto: "INTACTO", puesto: "PUESTO",
    detalle_subfusil: "AUTOMÁTICA, 30 BALAS", detalle_escopeta: "6 PERDIGONES, DE CERCA",
    balas: "BALAS", cartuchos: "CARTUCHOS",
    curar: "CURAR 25", detalle_curar: "VENDAS: +25 DE VIDA", curarTodo: "CURAR TODO", detalle_curarTodo: "VIDA AL MÁXIMO",
    botiquin: "BOTIQUÍN", detalle_botiquin: "LLEVAR ENCIMA: +40",
    mejora_dano: "DAÑO", mejora_cargador: "CARGADOR", mejora_recarga: "RECARGA",
    detalle_dano: "DAÑO", detalle_cargador: "BALAS", detalle_recarga: "TIEMPO",
    reparar: "REPARAR MUROS", detalle_reparar: "TODOS LOS TRAMOS",
    reforzar: "REFORZAR", detalle_reforzar: "VIDA POR TRAMO:", madera: "MADERA", chapa: "CHAPA", hormigon: "HORMIGÓN",
    alambre: "ALAMBRE DE ESPINO", detalle_alambre: "FRENA Y HIERE",
    chaleco: "CHALECO", detalle_chaleco: "PARA LOS GOLPES",
    estadisticas: "ESTADÍSTICAS", partidaActual: "PARTIDA ACTUAL", volver: "VOLVER",
    recargando: "RECARGANDO", muevete: "MUÉVETE AQUÍ",
    pistola: "GLOCK 17", subfusil: "MP5", escopeta: "REMINGTON 870",
    tocaEmpezar: "TOCA PARA EMPEZAR",
    ayudaMover: "MUÉVETE CON EL JOYSTICK DE ABAJO A LA IZQUIERDA",
    ayudaDisparo: "DISPARAS SOLO AL ZOMBI MÁS CERCANO",
    prototipo: "PROTOTIPO",
    disparo: "DISPARO", disparo_auto: "AUTO", disparo_manual: "MANUAL", apunta: "APUNTA AQUÍ",
    ayudaManual: "APUNTA Y DISPARA CON EL JOYSTICK DE LA DERECHA",
    camara: "CÁMARA", zoom_cerca: "CERCA", zoom_media: "MEDIA", zoom_lejos: "LEJOS",
    pausa: "PAUSA", seguir: "SEGUIR", sonidoSi: "SONIDO: SÍ", sonidoNo: "SONIDO: NO", reiniciar: "REINICIAR",
    hasMuerto: "HAS MUERTO", otraVez: "OTRA VEZ",
    monedas: "MONEDAS", tiempo: "TIEMPO", punteria: "PUNTERÍA", danoHecho: "DAÑO HECHO", danoRecibido: "DAÑO RECIBIDO",
    girar: "Gira el móvil<br>para jugar en horizontal", cargando: "Cargando…",
  },
  en: {
    bajas: "KILLS", oleada: "ROUND", oleadaSuperada: "ROUND CLEARED",
    listo: "READY", tienda: "SHOP", ayudaDescanso: "BUY WHAT YOU NEED AND TAP READY", vuelveBase: "GO BACK TO THE BASE TO SHOP",
    seCompra: "BUY IT AT THE SHOP", sinBalas: "OUT OF AMMO", a: "TO",
    tab_armas: "WEAPONS", tab_municion: "AMMO", tab_curacion: "HEALING", tab_mejoras: "UPGRADES", tab_defensas: "DEFENSE",
    tuya: "OWNED", lleno: "FULL", maximo: "MAX", sinArma: "NO WEAPON", intacto: "INTACT", puesto: "BUILT",
    detalle_subfusil: "AUTOMATIC, 30 ROUNDS", detalle_escopeta: "6 PELLETS, CLOSE RANGE",
    balas: "ROUNDS", cartuchos: "SHELLS",
    curar: "HEAL 25", detalle_curar: "BANDAGES: +25 HEALTH", curarTodo: "FULL HEAL", detalle_curarTodo: "HEALTH TO MAX",
    botiquin: "MEDKIT", detalle_botiquin: "CARRY IT: +40",
    mejora_dano: "DAMAGE", mejora_cargador: "MAGAZINE", mejora_recarga: "RELOAD",
    detalle_dano: "DAMAGE", detalle_cargador: "ROUNDS", detalle_recarga: "TIME",
    reparar: "REPAIR WALLS", detalle_reparar: "EVERY SECTION",
    reforzar: "REINFORCE", detalle_reforzar: "HEALTH PER SECTION:", madera: "WOOD", chapa: "SHEET METAL", hormigon: "CONCRETE",
    alambre: "RAZOR WIRE", detalle_alambre: "SLOWS AND HURTS",
    chaleco: "VEST", detalle_chaleco: "SOAKS UP HITS",
    estadisticas: "STATS", partidaActual: "CURRENT GAME", volver: "BACK",
    recargando: "RELOADING", muevete: "MOVE HERE",
    pistola: "GLOCK 17", subfusil: "MP5", escopeta: "REMINGTON 870",
    tocaEmpezar: "TAP TO START",
    ayudaMover: "MOVE WITH THE JOYSTICK AT THE BOTTOM LEFT",
    ayudaDisparo: "YOU SHOOT THE CLOSEST ZOMBIE AUTOMATICALLY",
    prototipo: "PROTOTYPE",
    disparo: "AIM", disparo_auto: "AUTO", disparo_manual: "MANUAL", apunta: "AIM HERE",
    ayudaManual: "AIM AND SHOOT WITH THE RIGHT JOYSTICK",
    camara: "CAMERA", zoom_cerca: "CLOSE", zoom_media: "MEDIUM", zoom_lejos: "FAR",
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
