// Lo que se guarda entre partidas en este navegador: las últimas partidas, las mejores marcas, los totales,
// los logros conseguidos (que desbloquean trajes y mascotas) y el traje y la mascota elegidos.
const CLAVE = "horda-pixel:perfil";
const MAX_PARTIDAS = 20;

// Trajes: el jugador con otra ropa (colores en sprites.js). Cada uno, con el logro que lo desbloquea.
export const TRAJES = [
  { id: "original" },
  { id: "militar", logro: { total: "rondaMax", meta: 5 } },
  { id: "motero", logro: { total: "bajas", meta: 500 } },
  { id: "medico", logro: { total: "rescatados", meta: 3 } },
  { id: "lenador", logro: { total: "bajasCuerpo", meta: 100 } },
  { id: "piromano", logro: { total: "bajasFuego", meta: 60 } },
  { id: "veterano", logro: { total: "rondaMax", meta: 10 } },
];
// Mascotas: el perro muerde, el gato recoge monedas y virotes, el cuervo pica a los zombis y trae monedas.
export const MASCOTAS = [
  { id: "ninguna" },
  { id: "perro", logro: { total: "rondaMax", meta: 3 } },
  { id: "gato", logro: { total: "bajas", meta: 200 } },
  { id: "cuervo", logro: { total: "partidas", meta: 10 } },
];

function vacio() {
  return {
    partidas: [],
    totales: { partidas: 0, bajas: 0, monedas: 0, tiempo: 0, rescatados: 0, bajasCuerpo: 0, bajasFuego: 0, rondaMax: 0 },
    mejores: { ronda: 0, bajas: 0, monedas: 0, tiempo: 0 },
    traje: "original", mascota: "ninguna",
  };
}

let perfil = cargar();

function cargar() {
  try {
    const p = JSON.parse(localStorage.getItem(CLAVE));
    if (p && p.totales) { const v = vacio(); return { ...v, ...p, totales: { ...v.totales, ...p.totales }, mejores: { ...v.mejores, ...p.mejores } }; }
  } catch (e) { /* sin almacenamiento o dañado: se empieza de cero */ }
  return vacio();
}
function guardar() {
  try { localStorage.setItem(CLAVE, JSON.stringify(perfil)); } catch (e) { /* no pasa nada si no se guarda */ }
}

export const leerPerfil = () => perfil;

export function progreso(item) {
  if (!item.logro) return { hecho: true, valor: 0, meta: 0 };
  const v = perfil.totales[item.logro.total] || 0;
  return { hecho: v >= item.logro.meta, valor: Math.min(v, item.logro.meta), meta: item.logro.meta };
}
export const desbloqueado = (item) => progreso(item).hecho;

export function elegir(tipo, id) {
  const lista = tipo === "traje" ? TRAJES : MASCOTAS;
  const item = lista.find((x) => x.id === id);
  if (!item || !desbloqueado(item)) return false;
  perfil[tipo] = id;
  guardar();
  return true;
}

// Al acabar una partida: se apunta, se suman los totales y se ven las marcas y los logros nuevos.
// Devuelve { marcas: ["ronda", ...], logros: [item, ...] }.
export function apuntarPartida(s, ronda) {
  const antes = [...TRAJES, ...MASCOTAS].filter((x) => x.logro && desbloqueado(x));
  const partida = {
    fecha: Date.now(), ronda, bajas: s.bajas, monedas: s.monedas, tiempo: Math.round(s.tiempo),
    punteria: s.disparos ? Math.round(100 * s.impactos / s.disparos) : 0, rescatados: s.rescatados || 0,
  };
  perfil.partidas.unshift(partida);
  perfil.partidas.length = Math.min(perfil.partidas.length, MAX_PARTIDAS);
  const T = perfil.totales;
  T.partidas++; T.bajas += s.bajas; T.monedas += s.monedas; T.tiempo += partida.tiempo;
  T.rescatados += partida.rescatados; T.bajasCuerpo += s.bajasCuerpo || 0; T.bajasFuego += s.bajasFuego || 0;
  T.rondaMax = Math.max(T.rondaMax, ronda);
  const marcas = [];
  for (const [k, v] of [["ronda", ronda], ["bajas", s.bajas], ["monedas", s.monedas], ["tiempo", partida.tiempo]]) {
    if (v > perfil.mejores[k]) { if (perfil.mejores[k] > 0 || k === "ronda") marcas.push(k); perfil.mejores[k] = v; }
  }
  guardar();
  const logros = [...TRAJES, ...MASCOTAS].filter((x) => x.logro && desbloqueado(x) && !antes.includes(x));
  return { marcas, logros };
}
