// Todos los números del juego en un solo sitio. Distancias en píxeles del juego
// (20 px = 1 m; una persona mide 35 px y una loseta 24 px), tiempos en segundos.

export const PANTALLA = {
  anchoMinimo: 460,      // píxeles de juego que caben como mínimo (móvil en horizontal)
  altoMinimo: 260,
  joystick: { x: 46, y: 46 }, // centro del joystick, medido desde la esquina inferior izquierda
  oscuridad: 0.34,       // 0 = de día; cuanto más alto, más de noche (las farolas y el fuego iluminan)
};

export const JUGADOR = {
  vida: 100,
  velocidad: 87,         // px/s
  radio: 6,              // para chocar con cosas
  recogerMonedas: 45,    // radio del imán de monedas
};

// dano por bala, cadencia en disparos por segundo, balas por cargador, recarga en s,
// alcance (px) para apuntar solo, dispersion en grados, perdigones por disparo,
// empuje (px que retrocede el zombi por impacto), critico = probabilidad de doble daño.
export const ARMAS = {
  pistola: {
    dano: 12, cadencia: 2.6, cargador: 12, recarga: 1.1,
    alcance: 165, velocidadBala: 420, dispersion: 3, perdigones: 1, empuje: 4.5,
    critico: 0.1, sacudida: 0.9, sonido: "pistola",
  },
  subfusil: {
    dano: 7, cadencia: 9, cargador: 30, recarga: 1.7,
    alcance: 142, velocidadBala: 450, dispersion: 9, perdigones: 1, empuje: 2.2,
    critico: 0.08, sacudida: 0.7, sonido: "subfusil",
  },
  escopeta: {
    dano: 8, cadencia: 1.1, cargador: 6, recarga: 2.1,
    alcance: 108, velocidadBala: 390, dispersion: 24, perdigones: 6, empuje: 9,
    critico: 0.05, sacudida: 3.2, sonido: "escopeta",
  },
};

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
