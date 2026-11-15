// Todos los números del juego en un solo sitio. Distancias en píxeles del juego
// (20 px = 1 m; una persona mide 35 px y una loseta 24 px), tiempos en segundos.

export const PANTALLA = {
  anchoMinimo: 460,      // píxeles de juego que caben como mínimo (móvil en horizontal)
  altoMinimo: 260,       // (la interfaz: botones, textos y joystick)
  // Zoom del mundo (se elige en la pausa): alto aproximado que se ve, en píxeles de juego (una persona mide 35).
  // Para probar otro valor: ?vista=150 en la dirección (?vista=0 = sin zoom, como antes).
  vistas: { cerca: 100, media: 130, lejos: 180 },
  vista: "media",
  joystick: { x: 46, y: 46 }, // centro del joystick, medido desde la esquina inferior izquierda
  oscuridad: 0.34,       // 0 = de día; cuanto más alto, más de noche (las farolas y el fuego iluminan)
};

export const JUGADOR = {
  vida: 100,
  velocidad: 87,         // px/s
  radio: 6,              // para chocar con cosas
  recogerMonedas: 45,    // radio del imán de monedas
};

// dano por bala, cadencia en disparos por segundo, balas por cargador (capacidad real del arma), recarga en s,
// alcance (px) para apuntar solo, dispersion en grados, perdigones por disparo,
// empuje (px que retrocede el zombi por impacto), critico = probabilidad de doble daño.
// Cuerpo a cuerpo (cuerpo: true): sin munición. alcance = px desde los pies, arco = grados del barrido,
// golpe = s que dura el barrido (el golpe llega a mitad), cadencia = golpes por segundo.
// atraviesa = zombis que cruza una bala; flecha = la bala es una flecha que se queda en el suelo y se recoge;
// llama = lanza llamas que prenden fuego (quema = s ardiendo).
export const ARMAS = {
  bate: {
    cuerpo: true, dano: 22, cadencia: 1.5, alcance: 27, arco: 110, golpe: 0.3, empuje: 16,
    critico: 0.06, sacudida: 1.4, sonido: "bate",
  },
  machete: {
    cuerpo: true, dano: 34, cadencia: 2.0, alcance: 25, arco: 95, golpe: 0.24, empuje: 6,
    critico: 0.22, sacudida: 0.9, sonido: "machete",
  },
  pistola: {
    dano: 12, cadencia: 2.6, cargador: 17, recarga: 1.4,   // Glock 17: cargador de 17
    alcance: 165, velocidadBala: 420, dispersion: 3, perdigones: 1, empuje: 4.5,
    critico: 0.1, sacudida: 0.9, sonido: "pistola",
  },
  subfusil: {
    dano: 7, cadencia: 9, cargador: 30, recarga: 1.7,      // MP5: cargador de 30
    alcance: 142, velocidadBala: 450, dispersion: 9, perdigones: 1, empuje: 2.2,
    critico: 0.08, sacudida: 0.7, sonido: "subfusil",
  },
  escopeta: {
    dano: 8, cadencia: 1.1, cargador: 5, recarga: 0.5,     // Remington 870: 4 en el tubo + 1 en la recámara
    porCartucho: true,     // se recarga de uno en uno (recarga = s por cartucho) y se puede interrumpir para disparar
    preparar: 0.3,         // s para girar el arma antes del primer cartucho
    corredera: 0.45,       // s para montar la corredera si la recámara quedó vacía
    alcance: 108, velocidadBala: 390, dispersion: 24, perdigones: 6, empuje: 9,
    critico: 0.05, sacudida: 3.2, sonido: "escopeta",
  },
  francotirador: {
    dano: 95, cadencia: 0.75, cargador: 5, recarga: 2.4,   // fusil de cerrojo: 5 balas
    alcance: 250, velocidadBala: 760, dispersion: 0.6, perdigones: 1, empuje: 12,
    critico: 0.2, sacudida: 2.8, sonido: "francotirador", atraviesa: 3,
  },
  ballesta: {
    dano: 50, cadencia: 1.1, cargador: 1, recarga: 0.85,   // un virote cada vez
    alcance: 175, velocidadBala: 300, dispersion: 1.5, perdigones: 1, empuje: 8,
    critico: 0.15, sacudida: 0.4, sonido: "ballesta", atraviesa: 2, flecha: true,
  },
  lanzallamas: {
    dano: 3, cadencia: 22, cargador: 100, recarga: 2.6,    // cargador = gasolina del depósito (1 por llama)
    alcance: 70, velocidadBala: 135, dispersion: 18, perdigones: 1, empuje: 0.4,
    critico: 0, sacudida: 0.25, sonido: "lanzallamas", llama: true, quema: 3.5,
  },
};

// Armas de fuego, en el orden de la barra (el cuerpo a cuerpo va delante, en una sola casilla).
export const ARMAS_FUEGO = ["pistola", "subfusil", "escopeta", "francotirador", "ballesta", "lanzallamas"];
export const CUERPO = ["bate", "machete"];

// Granadas y cócteles molotov: se llevan aparte y se lanzan con su botón.
export const LANZABLES = {
  granada: { max: 4, precio: 12, dano: 120, radio: 46, mecha: 1.25, alcance: 125 },
  molotov: { max: 4, precio: 10, radio: 30, duracion: 6, alcance: 115 },
};
// Zombis ardiendo (lanzallamas y molotov): vida que pierden por segundo.
export const FUEGO = { dano: 11, danoSuelo: 4 };

export const ZOMBIS = {
  normal: {
    sprites: ["zombi", "zombi_b", "zombi_c"], vida: 36, velocidad: 30, dano: 10, cadencia: 1.0,
    alcance: 15, radio: 7, monedas: [1, 2],
  },
  corredor: {
    sprites: ["corredor"], vida: 22, velocidad: 57, dano: 6, cadencia: 0.7,
    alcance: 14, radio: 6, monedas: [1, 3],
  },
};

export const OLEADAS = {
  descanso: 4,                    // s entre oleadas
  zombisBase: 6,                  // zombis en la oleada 1
  zombisPorOleada: 4,             // zombis extra por oleada
  intervaloBase: 1.3,             // s entre apariciones en la oleada 1
  intervaloMinimo: 0.35,
  corredoresDesde: 2,             // oleada en la que empiezan a salir corredores
  corredoresPorOleada: 0.1,       // proporción extra de corredores por oleada (máximo 0.45)
  vidaExtraPorOleada: 0.08,       // +8 % de vida por oleada
  maximoVivos: 40,
  distanciaAparicion: 300,        // px máximos por encima del jugador a los que sale un zombi
};

export const BOTIN = {
  botiquin: 0.05,                 // probabilidad por zombi
  curaBotiquin: 30,
  duracionEnSuelo: 14,            // s antes de desaparecer
};

// ------------------------------------------------------------------ base fortificada y tienda
// Tras cada ronda los zombis paran: vuelves a la base, compras, y la siguiente empieza al pulsar LISTO.
export const BASE = {
  vida: [150, 300, 500],          // vida de cada tramo de muro: madera, chapa, hormigón
  tramo: 48,                      // ancho de un tramo (px)
  alambre: { lentitud: 0.45, dano: 5 },   // el alambre deja a los zombis al 45 % de velocidad y quita 5 de vida por segundo
  chaleco: 50,                    // puntos de chaleco: se gastan antes que la vida
  botiquinesMax: 2,               // botiquines que puedes llevar encima
  curaBotiquin: 40,
};

// Munición: lo que llevas al empezar (o al comprar el arma), el máximo de reserva y cuánto trae cada compra.
export const MUNICION = {
  pistola: { inicial: 68, maximo: 170, lote: 34, precio: 5 },
  subfusil: { inicial: 60, maximo: 270, lote: 60, precio: 9 },
  escopeta: { inicial: 10, maximo: 45, lote: 10, precio: 9 },
  francotirador: { inicial: 10, maximo: 40, lote: 10, precio: 10 },
  ballesta: { inicial: 12, maximo: 40, lote: 10, precio: 6 },
  lanzallamas: { inicial: 100, maximo: 400, lote: 100, precio: 12 },
};

// Mejoras por arma (nivel 0 = de serie). cargador: balas por cargador en cada nivel.
// En el cuerpo a cuerpo, «recarga» es la velocidad del golpe (y no hay cargador).
export const MEJORAS = {
  dano: { factor: [1, 1.2, 1.42, 1.7], precio: [30, 65, 120] },
  recarga: { factor: [1, 0.85, 0.72, 0.6], precio: [25, 55, 100] },
  cargador: {
    pistola: [17, 22, 27, 33], subfusil: [30, 40, 50, 60], escopeta: [5, 6, 7, 8],
    francotirador: [5, 7, 9, 12], ballesta: [1, 2, 3, 4], lanzallamas: [100, 140, 180, 240],
    precio: [25, 55, 100],
  },
};

export const PRECIOS = {
  subfusil: 80, escopeta: 120,    // la Glock y el bate se tienen desde el principio
  machete: 60, francotirador: 160, ballesta: 90, lanzallamas: 200,
  curar: 6,                       // +25 de vida
  curarTodoPor25: 5,              // curar del todo: 5 monedas por cada 25 que falten
  botiquin: 15,
  chaleco: 40, rellenarChaleco: 20,
  repararPor20: 1,                // reparar muros: 1 moneda por cada 20 de vida que falte
  reforzar: [90, 180],            // pasar a chapa, pasar a hormigón
  alambre: 70,
};

// ------------------------------------------------------------------ defensas de la base (tanda 2)
// Torretas montadas sobre el muro: disparan solas a los zombis de fuera. Se compran de una en una
// (cada una más cara) y van en estos tramos (0 = portón). Si su tramo cae, dejan de disparar hasta repararlo.
export const TORRETAS = {
  precios: [120, 160, 200, 240], tramos: [-3, 3, -6, 6],
  municion: 150,                  // balas de cada una; se rellenan en la tienda (1 moneda por cada 10)
  dano: 7, cadencia: 4, alcance: 170, velocidadBala: 430, dispersion: 4, empuje: 2.5, critico: 0.05,
};
// Focos en el muro: alumbran lo de delante y deslumbran a los zombis (van más despacio).
export const FOCOS = { precio: 80, tramos: [-5, -1, 1, 5], lentitud: 0.72, fondo: 120, ancho: 46 };
// Trampas que llevas encima y dejas a tus pies con su botón (a la izquierda).
export const TRAMPAS = {
  mina: { max: 5, precio: 15, radio: 36, dano: 95, activa: 1, toque: 9 },
  barril: { max: 3, precio: 20, radio: 54, dano: 130 },       // estalla al dispararle o al quemarse
  cepo: { max: 3, precio: 25, dano: 25, sujeta: 3.5, rearme: 3, usos: 4, toque: 8 },
};
// Supervivientes: alguno aparece atrapado fuera; si llegas hasta él te sigue, y dentro de la base
// sube al muro a disparar.
export const SUPERVIVIENTES = {
  max: 4, probabilidad: 0.45, desdeRonda: 2, vida: 60, velocidad: 92,
  dano: 9, cadencia: 1.6, alcance: 165, velocidadBala: 420, puestos: [-2, 2, -5, 5],
};
// Zonas de la base: se construyen una vez.
export const ZONAS = {
  enfermeria: { precio: 120, cura: 1.5 },                         // vida por segundo mientras estás dentro de la base
  taller: { precio: 120, repara: 0.3, municionTorretas: 50 },     // al acabar cada ronda: repara el 30 % de cada tramo
  armeria: { precio: 150 },                                       // al acabar cada ronda: un lote de munición de cada arma
};
