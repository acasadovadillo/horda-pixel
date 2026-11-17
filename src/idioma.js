// Textos del juego en español y en inglés (EE. UU.). t("clave") devuelve el del idioma actual.
// El idioma elegido se guarda en este navegador; la primera vez se toma el del sistema.

const TEXTOS = {
  es: {
    bajas: "BAJAS", oleada: "RONDA", oleadaSuperada: "RONDA SUPERADA",
    listo: "LISTO", tienda: "TIENDA", ayudaDescanso: "COMPRA LO QUE NECESITES Y PULSA LISTO", vuelveBase: "VUELVE A LA BASE PARA COMPRAR", salBase: "SAL DE LA BASE PARA EMPEZAR LA RONDA",
    cuenta: "CUENTA", cuenta_titulo: "CUENTA", cuenta_explica: "Con una cuenta tu progreso (partidas, marcas, logros, traje y mascota) se guarda en la nube y no lo pierdes al cambiar de móvil. Sin cuenta se juega igual.",
    cuenta_sinConfigurar: "Las cuentas todavía no están activadas en este juego.", cuenta_conectando: "Conectando…",
    cuenta_correo: "Correo", cuenta_clave: "Contraseña", cuenta_entrar: "Entrar", cuenta_crear: "Crear cuenta", cuenta_google: "Entrar con Google",
    cuenta_olvido: "¿Has olvidado la contraseña?", cuenta_cerrar: "Cerrar", cuenta_espera: "Un momento…",
    cuenta_conectado: "Has entrado como", cuenta_guardado: "Progreso guardado en la nube a las {h}.", cuenta_sincronizando: "Guardando en la nube…",
    cuenta_sincronizar: "Guardar ahora", cuenta_salir: "Cerrar sesión", cuenta_borrar: "Borrar la cuenta", cuenta_borrarSeguro: "¿Seguro? Pulsa otra vez para borrarla",
    cuenta_creada: "Cuenta creada. Tu progreso ya se guarda en la nube.", cuenta_correoEnviado: "Te hemos enviado un correo para cambiar la contraseña.",
    cuenta_saliste: "Has cerrado la sesión. Tu progreso sigue en este móvil.", cuenta_borrada: "Cuenta borrada. Tu progreso sigue en este móvil.",
    err_correo: "Escribe un correo válido.", err_clave: "Escribe la contraseña.", err_datos: "El correo o la contraseña no son correctos.",
    err_yaExiste: "Ya hay una cuenta con ese correo. Pulsa Entrar.", err_debil: "La contraseña debe tener al menos 6 caracteres.",
    err_muchos: "Demasiados intentos. Espera un poco.", err_red: "No hay conexión. Prueba otra vez.", err_cancelado: "Has cancelado la entrada con Google.",
    err_reciente: "Por seguridad, cierra sesión, vuelve a entrar y repite.", err_dominio: "Este sitio no está autorizado en Firebase.",
    err_noActivado: "Esa forma de entrar no está activada en Firebase.", err_otro: "Algo ha fallado. Prueba otra vez.",
    armero: "ARMERO", intendente: "INTENDENTE", medico: "MÉDICO", mecanico: "MECÁNICO", constructor: "CONSTRUCTOR", acercateComercio: "ACÉRCATE A UN MOSTRADOR PARA COMPRAR",
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
    bate: "BATE", machete: "MACHETE", francotirador: "FUSIL DE CERROJO", ballesta: "BALLESTA", lanzallamas: "LANZALLAMAS",
    granada: "GRANADA", molotov: "MOLOTOV", tab_explosivos: "EXPLOSIVOS",
    detalle_machete: "RÁPIDO, CORTA MIEMBROS", detalle_francotirador: "ATRAVIESA 3 ZOMBIS", detalle_ballesta: "VIROTES QUE SE RECOGEN",
    detalle_lanzallamas: "QUEMA LO QUE TIENES DELANTE", detalle_granada: "ESTALLA AL SEGUNDO", detalle_molotov: "DEJA UN CHARCO DE FUEGO",
    virotes: "VIROTES", gasolina: "GASOLINA", mejora_velocidad: "VELOCIDAD", detalle_velocidad: "GOLPES", llevas: "LLEVAS",
    cuerpoACuerpo: "CUERPO A CUERPO",
    personaje: "PERSONAJE", trajes: "TRAJES", mascotas: "MASCOTAS", partidas: "PARTIDAS", rondaMax: "RONDA MÁXIMA",
    anteriores: "ANTERIORES", mejoresMarcas: "MEJORES MARCAS", partidasAnteriores: "ÚLTIMAS PARTIDAS", fecha: "FECHA",
    sinPartidas: "AÚN NO HAS ACABADO NINGUNA PARTIDA", nuevaMarca: "NUEVA MARCA", desbloqueado: "DESBLOQUEADO",
    traje_original: "ORIGINAL", traje_militar: "MILITAR", traje_motero: "MOTERO", traje_medico: "MÉDICO", traje_lenador: "LEÑADOR",
    traje_piromano: "PIRÓMANO", traje_veterano: "VETERANO",
    mascota_ninguna: "SIN MASCOTA", mascota_perro: "PERRO", mascota_gato: "GATO", mascota_cuervo: "CUERVO",
    detalle_mascota_perro: "MUERDE Y FRENA ZOMBIS", detalle_mascota_gato: "RECOGE MONEDAS Y VIROTES", detalle_mascota_cuervo: "PICA ZOMBIS Y TRAE MONEDAS",
    logro_rondaMax: "LLEGA A LA RONDA {n}", logro_bajas: "MATA {n} ZOMBIS EN TOTAL", logro_rescatados: "RESCATA {n} SUPERVIVIENTES",
    logro_bajasCuerpo: "{n} BAJAS CUERPO A CUERPO", logro_bajasFuego: "{n} BAJAS CON FUEGO O EXPLOSIONES", logro_partidas: "JUEGA {n} PARTIDAS",
    tab_equipo: "EQUIPO", tab_base: "ZONAS",
    torreta: "TORRETA", detalle_torreta: "DISPARA SOLA DESDE EL MURO", municionTorretas: "MUNICIÓN TORRETAS", detalle_municionTorretas: "LLENA TODAS",
    focos: "FOCOS", detalle_focos: "DESLUMBRAN A LOS ZOMBIS", sinTorretas: "SIN TORRETAS",
    mina: "MINA", detalle_mina: "ESTALLA AL PISARLA", barril: "BARRIL EXPLOSIVO", detalle_barril: "DISPÁRALE O QUÉMALO",
    cepo: "CEPO", detalle_cepo: "ATRAPA Y HIERE", fueraDeLaBase: "PONLA FUERA DE LA BASE",
    enfermeria: "ENFERMERÍA", detalle_enfermeria: "TE CURA DENTRO DE LA BASE", taller: "TALLER", detalle_taller: "REPARA MUROS TRAS CADA RONDA",
    armeria: "ARMERÍA", detalle_armeria: "MUNICIÓN TRAS CADA RONDA", construida: "HECHA", municionArmeria: "+MUNICIÓN",
    ayuda: "¡AYUDA!", gracias: "¡GRACIAS!", aSalvo: "¡A SALVO!", superviviente: "SUPERVIVIENTE MUERTO",
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
    listo: "READY", tienda: "SHOP", ayudaDescanso: "BUY WHAT YOU NEED AND TAP READY", vuelveBase: "GO BACK TO THE BASE TO SHOP", salBase: "LEAVE THE BASE TO START THE ROUND",
    cuenta: "ACCOUNT", cuenta_titulo: "ACCOUNT", cuenta_explica: "With an account your progress (games, records, achievements, outfit and pet) is saved in the cloud, so you keep it when you change phones. You can play without one.",
    cuenta_sinConfigurar: "Accounts are not enabled in this game yet.", cuenta_conectando: "Connecting…",
    cuenta_correo: "Email", cuenta_clave: "Password", cuenta_entrar: "Sign in", cuenta_crear: "Create account", cuenta_google: "Sign in with Google",
    cuenta_olvido: "Forgot your password?", cuenta_cerrar: "Close", cuenta_espera: "One moment…",
    cuenta_conectado: "Signed in as", cuenta_guardado: "Progress saved to the cloud at {h}.", cuenta_sincronizando: "Saving to the cloud…",
    cuenta_sincronizar: "Save now", cuenta_salir: "Sign out", cuenta_borrar: "Delete account", cuenta_borrarSeguro: "Sure? Tap again to delete it",
    cuenta_creada: "Account created. Your progress is now saved in the cloud.", cuenta_correoEnviado: "We sent you an email to reset your password.",
    cuenta_saliste: "Signed out. Your progress stays on this phone.", cuenta_borrada: "Account deleted. Your progress stays on this phone.",
    err_correo: "Enter a valid email.", err_clave: "Enter your password.", err_datos: "Wrong email or password.",
    err_yaExiste: "There is already an account with that email. Tap Sign in.", err_debil: "The password needs at least 6 characters.",
    err_muchos: "Too many attempts. Wait a bit.", err_red: "No connection. Try again.", err_cancelado: "Google sign-in was cancelled.",
    err_reciente: "For security, sign out, sign in again and retry.", err_dominio: "This site is not authorized in Firebase.",
    err_noActivado: "That sign-in method is not enabled in Firebase.", err_otro: "Something went wrong. Try again.",
    armero: "GUNSMITH", intendente: "QUARTERMASTER", medico: "MEDIC", mecanico: "MECHANIC", constructor: "BUILDER", acercateComercio: "WALK UP TO A COUNTER TO SHOP",
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
    bate: "BAT", machete: "MACHETE", francotirador: "BOLT-ACTION RIFLE", ballesta: "CROSSBOW", lanzallamas: "FLAMETHROWER",
    granada: "GRENADE", molotov: "MOLOTOV", tab_explosivos: "EXPLOSIVES",
    detalle_machete: "FAST, CUTS OFF LIMBS", detalle_francotirador: "PIERCES 3 ZOMBIES", detalle_ballesta: "BOLTS YOU CAN PICK UP",
    detalle_lanzallamas: "BURNS WHATEVER IS IN FRONT", detalle_granada: "BLOWS UP AFTER A SECOND", detalle_molotov: "LEAVES A POOL OF FIRE",
    virotes: "BOLTS", gasolina: "FUEL", mejora_velocidad: "SPEED", detalle_velocidad: "HITS", llevas: "CARRYING",
    cuerpoACuerpo: "MELEE",
    personaje: "CHARACTER", trajes: "OUTFITS", mascotas: "PETS", partidas: "GAMES", rondaMax: "BEST ROUND",
    anteriores: "PAST GAMES", mejoresMarcas: "PERSONAL BESTS", partidasAnteriores: "LAST GAMES", fecha: "DATE",
    sinPartidas: "YOU HAVEN'T FINISHED A GAME YET", nuevaMarca: "NEW BEST", desbloqueado: "UNLOCKED",
    traje_original: "ORIGINAL", traje_militar: "MILITARY", traje_motero: "BIKER", traje_medico: "MEDIC", traje_lenador: "LUMBERJACK",
    traje_piromano: "PYRO", traje_veterano: "VETERAN",
    mascota_ninguna: "NO PET", mascota_perro: "DOG", mascota_gato: "CAT", mascota_cuervo: "CROW",
    detalle_mascota_perro: "BITES AND SLOWS ZOMBIES", detalle_mascota_gato: "PICKS UP COINS AND BOLTS", detalle_mascota_cuervo: "PECKS ZOMBIES, FETCHES COINS",
    logro_rondaMax: "REACH ROUND {n}", logro_bajas: "KILL {n} ZOMBIES IN TOTAL", logro_rescatados: "RESCUE {n} SURVIVORS",
    logro_bajasCuerpo: "{n} MELEE KILLS", logro_bajasFuego: "{n} FIRE OR EXPLOSION KILLS", logro_partidas: "PLAY {n} GAMES",
    tab_equipo: "GEAR", tab_base: "BUILD",
    torreta: "TURRET", detalle_torreta: "SHOOTS FROM THE WALL", municionTorretas: "TURRET AMMO", detalle_municionTorretas: "FILLS THEM ALL",
    focos: "FLOODLIGHTS", detalle_focos: "BLIND THE ZOMBIES", sinTorretas: "NO TURRETS",
    mina: "LANDMINE", detalle_mina: "BLOWS UP WHEN STEPPED ON", barril: "EXPLOSIVE BARREL", detalle_barril: "SHOOT IT OR BURN IT",
    cepo: "BEAR TRAP", detalle_cepo: "CATCHES AND HURTS", fueraDeLaBase: "PLACE IT OUTSIDE THE BASE",
    enfermeria: "INFIRMARY", detalle_enfermeria: "HEALS YOU INSIDE THE BASE", taller: "WORKSHOP", detalle_taller: "REPAIRS WALLS AFTER EACH ROUND",
    armeria: "ARMORY", detalle_armeria: "AMMO AFTER EACH ROUND", construida: "BUILT", municionArmeria: "+AMMO",
    ayuda: "HELP!", gracias: "THANKS!", aSalvo: "SAFE!", superviviente: "SURVIVOR DOWN",
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
