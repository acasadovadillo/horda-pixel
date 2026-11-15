// Todos los números del juego en un solo sitio. Distancias en píxeles del juego
// (una loseta = 16 px; el personaje mide 16x20), tiempos en segundos.

export const PANTALLA = {
  anchoMinimo: 180,      // píxeles de juego que caben a lo ancho como mínimo (móvil en vertical)
};

export const JUGADOR = {
  vida: 100,
  velocidad: 58,         // px/s
  radio: 4,              // para chocar con cosas
  recogerMonedas: 30,    // radio del imán de monedas
};

// dano por bala, disparos por segundo, balas por cargador, recarga en s,
// alcance (px) para apuntar solo, dispersion en grados, perdigones por disparo,
// empuje (px que retrocede el zombi por impacto), critico = probabilidad de doble daño.
export const ARMAS = {
  pistola: {
    nombre: "PISTOLA", dano: 12, cadencia: 2.6, cargador: 12, recarga: 1.1,
    alcance: 110, velocidadBala: 280, dispersion: 3, perdigones: 1, empuje: 3,
    critico: 0.1, sacudida: 0.6, sonido: "pistola",
    mano: { x: 2, y: 2 },          // punto del sprite que agarra la mano
  },
  subfusil: {
    nombre: "SUBFUSIL", dano: 7, cadencia: 9, cargador: 30, recarga: 1.7,
    alcance: 95, velocidadBala: 300, dispersion: 9, perdigones: 1, empuje: 1.5,
    critico: 0.08, sacudida: 0.5, sonido: "subfusil",
    mano: { x: 3, y: 2 },
  },
  escopeta: {
    nombre: "ESCOPETA", dano: 8, cadencia: 1.1, cargador: 6, recarga: 2.1,
    alcance: 72, velocidadBala: 260, dispersion: 24, perdigones: 6, empuje: 6,
    critico: 0.05, sacudida: 2.2, sonido: "escopeta",
    mano: { x: 5, y: 2 },
  },
};

export const ZOMBIS = {
  normal: {
    sprite: "zombi", vida: 36, velocidad: 20, dano: 10, cadencia: 1.0,
    alcance: 10, radio: 4.5, monedas: [1, 2],
  },
  corredor: {
    sprite: "corredor", vida: 22, velocidad: 38, dano: 6, cadencia: 0.7,
    alcance: 9, radio: 4, monedas: [1, 3],
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
  distanciaAparicion: 200,       // px máximos por encima del jugador a los que sale un zombi
};

export const BOTIN = {
  botiquin: 0.05,                 // probabilidad por zombi
  curaBotiquin: 30,
  duracionEnSuelo: 14,            // s antes de desaparecer
};
