// Tienda de la base: se abre entre rondas, dentro de la base. El juego queda parado mientras compras.
// Pestañas: armas, munición, curación, mejoras y defensas. Todo se paga con las monedas de los zombis.
import { S, texto, anchoTexto, dibujar } from "./sprites.js";
import { ARMAS, ARMAS_FUEGO, CUERPO, LANZABLES, JUGADOR, BASE, MUNICION, MEJORAS, PRECIOS } from "./config.js";
import { faltaMuro, repararMuro, reforzarMuro } from "./base.js";
import { sonar } from "./audio.js";
import { t } from "./idioma.js";

const PESTANAS = ["armas", "municion", "explosivos", "curacion", "mejoras", "defensas"];
const ARMAS_ORDEN = ARMAS_FUEGO;
const EN_VENTA = ["machete", "subfusil", "escopeta", "francotirador", "ballesta", "lanzallamas"];

// Iconos de iconos_tienda
const IC = {
  municion: { pistola: 0, subfusil: 1, escopeta: 2, francotirador: 14, ballesta: 15, lanzallamas: 16 },
  curar: 3, curarTodo: 4, botiquin: 5, chaleco: 6, dano: 7, cargador: 8, recarga: 9, reparar: 10, reforzar: 11, alambre: 12,
  granada: 17, molotov: 18,
};
const UNIDAD = { escopeta: "cartuchos", ballesta: "virotes", lanzallamas: "gasolina" };

// Cada artículo: icono, nombre, detalle, precio (null = no se puede ahora) y nota (TUYA, MÁX...).
function articulos(juego) {
  const j = juego.jugador, b = juego.base;
  const p = juego.pestana;
  if (p === "armas") {
    return EN_VENTA.map((n) => ({
      arma: n, nombre: t(n), detalle: t("detalle_" + n),
      precio: j.armas[n] ? null : PRECIOS[n], nota: j.armas[n] ? t("tuya") : null,
      comprar: () => {
        j.armas[n] = true;
        if (!ARMAS[n].cuerpo) {
          j.cargador[n] = ARMAS[n].cargador;
          j.reserva[n] = MUNICION[n].inicial;
        }
        juego.cambiarArma(n);
      },
    }));
  }
  if (p === "municion") {
    // Solo la de las armas que tienes
    return ARMAS_ORDEN.filter((n) => j.armas[n]).map((n) => {
      const m = MUNICION[n], lleno = j.reserva[n] >= m.maximo;
      return {
        icono: IC.municion[n], nombre: t(n), detalle: "+" + m.lote + " " + t(UNIDAD[n] || "balas") + ", " + j.reserva[n] + "/" + m.maximo,
        precio: lleno ? null : m.precio, nota: lleno ? t("lleno") : null,
        comprar: () => { j.reserva[n] = Math.min(m.maximo, j.reserva[n] + m.lote); },
      };
    });
  }
  if (p === "explosivos") {
    return ["granada", "molotov"].map((n) => {
      const L = LANZABLES[n], lleno = j.lanzables[n] >= L.max;
      return {
        icono: IC[n], nombre: t(n), detalle: t("detalle_" + n) + ", " + j.lanzables[n] + "/" + L.max,
        precio: lleno ? null : L.precio, nota: lleno ? t("lleno") : null,
        comprar: () => { j.lanzables[n]++; },
      };
    });
  }
  if (p === "curacion") {
    const falta = JUGADOR.vida - j.vida;
    const todo = Math.ceil(falta / 25) * PRECIOS.curarTodoPor25;
    return [
      { icono: IC.curar, nombre: t("curar"), detalle: t("detalle_curar"), precio: falta > 0 ? PRECIOS.curar : null, nota: falta > 0 ? null : t("lleno"),
        comprar: () => { j.vida = Math.min(JUGADOR.vida, j.vida + 25); sonar("curar"); } },
      { icono: IC.curarTodo, nombre: t("curarTodo"), detalle: t("detalle_curarTodo"), precio: falta > 0 ? todo : null, nota: falta > 0 ? null : t("lleno"),
        comprar: () => { j.vida = JUGADOR.vida; sonar("curar"); } },
      { icono: IC.botiquin, nombre: t("botiquin"), detalle: t("detalle_botiquin") + ", " + j.botiquines + "/" + BASE.botiquinesMax,
        precio: j.botiquines < BASE.botiquinesMax ? PRECIOS.botiquin : null, nota: j.botiquines < BASE.botiquinesMax ? null : t("lleno"),
        comprar: () => { j.botiquines++; } },
    ];
  }
  if (p === "mejoras") {
    const n = juego.armaMejora && j.armas[juego.armaMejora] ? juego.armaMejora : j.arma;
    const m = j.mejoras[n];
    if (ARMAS[n].cuerpo) {
      // Cuerpo a cuerpo: daño y velocidad del golpe
      const pct2 = (f) => Math.round(Math.abs(f - 1) * 100) + "%";
      const linea2 = (tipo, nombre, detalle) => {
        const nivel = m[tipo], max = nivel >= 3;
        return {
          icono: IC[tipo], nombre: t(nombre) + " " + "I".repeat(nivel + (max ? 0 : 1)), detalle: detalle(nivel, max),
          precio: max ? null : MEJORAS[tipo].precio[nivel], nota: max ? t("maximo") : null,
          comprar: () => { m[tipo]++; },
        };
      };
      return [
        linea2("dano", "mejora_dano", (k, max) => t("detalle_dano") + " " + (max ? pct2(MEJORAS.dano.factor[k]) : "+" + pct2(MEJORAS.dano.factor[k + 1]))),
        linea2("recarga", "mejora_velocidad", (k, max) => t("detalle_velocidad") + " +" + pct2(1 / MEJORAS.recarga.factor[max ? k : k + 1])),
      ];
    }
    const linea = (tipo, valor) => {
      const nivel = m[tipo], max = nivel >= 3;
      return {
        icono: IC[tipo], nombre: t("mejora_" + tipo) + " " + "I".repeat(nivel + (max ? 0 : 1)), detalle: valor(nivel, max),
        precio: max ? null : (tipo === "cargador" ? MEJORAS.cargador.precio : MEJORAS[tipo].precio)[nivel], nota: max ? t("maximo") : null,
        comprar: () => { m[tipo]++; if (tipo === "cargador") j.cargador[n] = Math.min(j.cargador[n], MEJORAS.cargador[n][m.cargador]); },
      };
    };
    const pct = (f) => Math.round(Math.abs(f - 1) * 100) + "%";
    return [
      linea("dano", (k, max) => t("detalle_dano") + " " + (max ? pct(MEJORAS.dano.factor[k]) : "+" + pct(MEJORAS.dano.factor[k + 1]))),
      linea("cargador", (k, max) => t("detalle_cargador") + " " + (max ? MEJORAS.cargador[n][k] : MEJORAS.cargador[n][k] + " " + t("a") + " " + MEJORAS.cargador[n][k + 1])),
      linea("recarga", (k, max) => t("detalle_recarga") + " " + (max ? "-" + pct(MEJORAS.recarga.factor[k]) : "-" + pct(MEJORAS.recarga.factor[k + 1]))),
    ];
  }
  // defensas
  const falta = faltaMuro(b);
  const material = ["madera", "chapa", "hormigon"];
  return [
    { icono: IC.reparar, nombre: t("reparar"), detalle: t("detalle_reparar"),
      precio: falta > 0 ? Math.max(1, Math.ceil(falta / 20) * PRECIOS.repararPor20) : null, nota: falta > 0 ? null : t("intacto"),
      comprar: () => repararMuro(b) },
    { icono: IC.reforzar, nombre: t("reforzar") + (b.nivel < 2 ? ": " + t(material[b.nivel + 1]) : ""),
      detalle: t("detalle_reforzar") + " " + BASE.vida[Math.min(2, b.nivel + 1)],
      precio: b.nivel < 2 ? PRECIOS.reforzar[b.nivel] : null, nota: b.nivel < 2 ? null : t("maximo"),
      comprar: () => reforzarMuro(b) },
    { icono: IC.alambre, nombre: t("alambre"), detalle: t("detalle_alambre"), precio: b.alambre ? null : PRECIOS.alambre, nota: b.alambre ? t("puesto") : null,
      comprar: () => { b.alambre = true; } },
    { icono: IC.chaleco, nombre: t("chaleco"), detalle: t("detalle_chaleco") + ", " + Math.round(j.chaleco) + "/" + BASE.chaleco,
      precio: j.chaleco >= BASE.chaleco ? null : j.tuvoChaleco ? PRECIOS.rellenarChaleco : PRECIOS.chaleco, nota: j.chaleco >= BASE.chaleco ? t("lleno") : null,
      comprar: () => { j.chaleco = BASE.chaleco; j.tuvoChaleco = true; } },
  ];
}

function moneda(g, x, y) { dibujar(g, S.moneda, 0, x, y); }

export function pantallaTienda(juego, g) {
  const W = juego.uiW, H = juego.uiH;
  juego.velo(g, 0.82);
  // Cabecera: título, monedas y cerrar
  texto(g, t("tienda"), 8, 6, "#f2c84a", "izq", 2);
  const txtM = String(juego.monedas);
  const xM = W - 54;
  texto(g, txtM, xM - 6, 10, "#f2c84a", "der");
  moneda(g, xM - 6 - anchoTexto(txtM) - 13, 10);
  juego.botonGrande(g, "X", 3, () => juego.cerrarTienda(), "#872a26", W - 44, 40);

  // Pestañas
  const pw = Math.floor((W - 16) / PESTANAS.length), py = 34, ph = 20;
  PESTANAS.forEach((p, i) => {
    const x = 8 + i * pw, sel = juego.pestana === p;
    g.fillStyle = "#0e0d12"; g.fillRect(x, py, pw - 3, ph);
    g.fillStyle = sel ? "#3b526b" : "#26252e"; g.fillRect(x + 1, py + 1, pw - 5, ph - 2);
    if (sel) { g.fillStyle = "#f2c84a"; g.fillRect(x + 1, py + 1, pw - 5, 2); }
    texto(g, t("tab_" + p), x + (pw - 3) / 2, py + 6, sel ? "#ffffff" : "#a8a59a", "centro");
    juego.boton(x, py - 4, pw - 3, ph + 6, () => { juego.pestana = p; sonar("boton"); });
  });

  let y0 = py + ph + 8;
  // En mejoras: elegir arma
  if (juego.pestana === "mejoras") {
    const j = juego.jugador, actual = juego.armaMejora && j.armas[juego.armaMejora] ? juego.armaMejora : j.arma;
    let x = 8;
    for (const n of [...CUERPO, ...ARMAS_ORDEN]) {
      if (!j.armas[n]) continue;
      const sel = n === actual, w = 42;
      g.fillStyle = "#0e0d12"; g.fillRect(x, y0, w, 22);
      g.fillStyle = sel ? "#3b526b" : "#26252e"; g.fillRect(x + 1, y0 + 1, w - 2, 20);
      const s = juego.iconoArma(n);
      dibujar(g, s, 0, x + Math.floor((w - s.w) / 2), y0 + 2);
      juego.boton(x, y0 - 2, w, 26, () => { juego.armaMejora = n; sonar("boton"); });
      x += w + 4;
    }
    if (x + 4 + anchoTexto(t(actual)) < W - 8) texto(g, t(actual), x + 4, y0 + 6, "#d1cec0");
    y0 += 28;
  }

  // Tarjetas en dos columnas
  const lista = articulos(juego);
  const cw = Math.floor((W - 16 - 6) / 2), chh = 44;
  lista.forEach((a, i) => {
    const x = 8 + (i % 2) * (cw + 6), y = y0 + Math.floor(i / 2) * (chh + 6);
    g.fillStyle = "#0e0d12"; g.fillRect(x, y, cw, chh);
    g.fillStyle = "#26252e"; g.fillRect(x + 1, y + 1, cw - 2, chh - 2);
    if (a.arma) {
      const s = juego.iconoArma(a.arma);
      dibujar(g, s, 0, x + 4, y + Math.floor((chh - s.h) / 2));
    } else juego.icono(g, a.icono, x + 6, y + 10, 24);
    const tx = a.arma ? x + 44 : x + 36;
    texto(g, a.nombre, tx, y + 5, "#ffffff");
    texto(g, a.detalle, tx, y + 18, "#a8a59a");
    // Precio o nota
    const bwp = 52, bx = x + cw - bwp - 4, by = y + chh - 17;
    if (a.precio == null) {
      texto(g, a.nota || "", x + cw - 6, by + 3, "#7ee07e", "der");
    } else {
      const puede = juego.monedas >= a.precio;
      g.fillStyle = "#0e0d12"; g.fillRect(bx, by, bwp, 14);
      g.fillStyle = puede ? "#4a6a34" : "#34363d"; g.fillRect(bx + 1, by + 1, bwp - 2, 12);
      texto(g, String(a.precio), bx + bwp - 15, by + 2, puede ? "#ffffff" : "#85837a", "der");
      moneda(g, bx + bwp - 13, by + 1);
      juego.boton(x, y, cw, chh, () => {
        if (juego.monedas < a.precio) { sonar("herido", 0.2); return; }
        juego.monedas -= a.precio;
        a.comprar();
        sonar("moneda");
      });
    }
  });
}
