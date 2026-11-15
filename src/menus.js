// Pantallas de PERSONAJE (trajes y mascotas, que se desbloquean con logros) y de partidas anteriores
// (mejores marcas e historial). Se abren desde la pantalla de inicio y desde la pausa.
import { S, punto, fotograma, primero, dibujar, texto, anchoTexto, vestido } from "./sprites.js";
import { TRAJES, MASCOTAS, leerPerfil, progreso, desbloqueado, elegir } from "./perfil.js";
import { crearMascota } from "./mascotas.js";
import { sonar } from "./audio.js";
import { t } from "./idioma.js";

const HOMBRO = { x: 20, y: 13 };

// Texto del logro que desbloquea algo: «LLEGA A LA RONDA 5 (3/5)».
export function textoLogro(item) {
  if (!item.logro) return "";
  const p = progreso(item);
  return t("logro_" + item.logro.total).replace("{n}", item.logro.meta) + " (" + p.valor + "/" + p.meta + ")";
}

function tarjeta(g, x, y, w, h, sel, bloqueada) {
  g.fillStyle = sel ? "#f2c84a" : "#0e0d12"; g.fillRect(x, y, w, h);
  g.fillStyle = sel ? "#3b526b" : bloqueada ? "#1a1920" : "#26252e"; g.fillRect(x + 1, y + 1, w - 2, h - 2);
}

export function pantallaPersonaje(J, g) {
  const W = J.uiW, H = J.uiH, perfil = leerPerfil();
  J.velo(g, 0.9);
  texto(g, t("personaje"), 8, 6, "#f2c84a", "izq", 2);
  J.botonGrande(g, "X", 3, () => { J.verPersonaje = false; sonar("boton"); }, "#872a26", W - 44, 40);

  // Trajes
  texto(g, t("trajes"), 8, 30, "#a8a59a");
  const tw = 58, th = 56, tg = 4, x0 = Math.round(W / 2 - (TRAJES.length * (tw + tg) - tg) / 2), y0 = 40;
  const jug = S.jugador, br = S.brazos_pistola;
  const ij = fotograma(jug, jug.tags.quieto_e ? "quieto_e" : "quieto", performance.now() / 1000);
  const h = punto(jug, "hombro", ij, HOMBRO), hb = punto(br, "hombro", 0, { x: 8, y: 10 });
  TRAJES.forEach((tr, k) => {
    const x = x0 + k * (tw + tg), libre = desbloqueado(tr), sel = perfil.traje === tr.id;
    tarjeta(g, x, y0, tw, th, sel, !libre);
    g.globalAlpha = libre ? 1 : 0.22;
    dibujar(g, jug, ij, x + 6, y0 + 4, false, vestido("jugador", tr.id));
    dibujar(g, br, primero(br, "apuntar"), x + 6 + h.x - hb.x, y0 + 4 + h.y - hb.y, false, vestido("brazos_pistola", tr.id));
    g.globalAlpha = 1;
    if (!libre) J.icono(g, 13, x + tw / 2 - 8, y0 + 14, 16);
    J.boton(x, y0, tw, th, () => {
      J.infoTraje = tr;
      if (libre && elegir("traje", tr.id)) sonar("boton"); else sonar("herido", 0.2);
    });
  });
  const it = J.infoTraje || TRAJES.find((x) => x.id === perfil.traje);
  texto(g, t("traje_" + it.id) + (desbloqueado(it) ? "" : ": " + textoLogro(it)), W / 2, y0 + th + 5, desbloqueado(it) ? "#ffffff" : "#d9a233", "centro");

  // Mascotas
  const ym = y0 + th + 22;
  texto(g, t("mascotas"), 8, ym, "#a8a59a");
  const mw = 78, mh = 40, mg = 6, mx0 = Math.round(W / 2 - (MASCOTAS.length * (mw + mg) - mg) / 2), my0 = ym + 10;
  MASCOTAS.forEach((ma, k) => {
    const x = mx0 + k * (mw + mg), libre = desbloqueado(ma), sel = perfil.mascota === ma.id;
    tarjeta(g, x, my0, mw, mh, sel, !libre);
    const s = S[ma.id];
    g.globalAlpha = libre ? 1 : 0.22;
    if (s) {
      const tag = s.tags.quieto ? "quieto" : Object.keys(s.tags)[0];
      dibujar(g, s, fotograma(s, tag, performance.now() / 1000), x + Math.floor((mw - s.w) / 2), my0 + Math.floor((mh - s.h) / 2));
    } else texto(g, t("mascota_" + ma.id), x + mw / 2, my0 + 15, "#d1cec0", "centro");
    g.globalAlpha = 1;
    if (!libre) J.icono(g, 13, x + mw / 2 - 8, my0 + 12, 16);
    J.boton(x, my0, mw, mh, () => {
      J.infoMascota = ma;
      if (libre && elegir("mascota", ma.id)) { sonar("boton"); if (J.estado !== "inicio") crearMascota(J, ma.id); }
      else sonar("herido", 0.2);
    });
  });
  const im = J.infoMascota || MASCOTAS.find((x) => x.id === perfil.mascota);
  const detalle = desbloqueado(im) ? (im.id === "ninguna" ? "" : ": " + t("detalle_mascota_" + im.id)) : ": " + textoLogro(im);
  texto(g, t("mascota_" + im.id) + detalle, W / 2, my0 + mh + 5, desbloqueado(im) ? "#ffffff" : "#d9a233", "centro");

  // Totales
  const T = perfil.totales;
  texto(g, t("partidas") + " " + T.partidas + "   " + t("bajas") + " " + T.bajas + "   " + t("rondaMax") + " " + T.rondaMax,
    W / 2, Math.min(H - 14, my0 + mh + 24), "#85837a", "centro");
}

const dosCifras = (n) => String(n).padStart(2, "0");
const reloj = (s) => Math.floor(s / 60) + ":" + dosCifras(Math.floor(s % 60));

export function pantallaHistorial(J, g) {
  const W = J.uiW, H = J.uiH, perfil = leerPerfil(), m = perfil.mejores;
  texto(g, t("estadisticas"), W / 2, 6, "#ffffff", "centro", 2);
  texto(g, t("mejoresMarcas"), W / 2, 30, "#f2c84a", "centro");
  // Mejores marcas en cuatro columnas
  const cols = [[t("oleada"), m.ronda], [t("bajas"), m.bajas], [t("monedas"), m.monedas], [t("tiempo"), reloj(m.tiempo)]];
  const cw = Math.min(110, Math.floor((W - 16) / 4)), cx0 = Math.round(W / 2 - cw * 2);
  cols.forEach(([k, v], i) => {
    texto(g, k, cx0 + cw * i + cw / 2, 44, "#a8a59a", "centro");
    texto(g, v, cx0 + cw * i + cw / 2, 56, "#ffffff", "centro", 2);
  });
  // Últimas partidas
  texto(g, t("partidasAnteriores"), W / 2, 84, "#f2c84a", "centro");
  const filas = perfil.partidas.slice(0, Math.max(3, Math.floor((H - 150) / 12)));
  const xs = [0.1, 0.3, 0.45, 0.6, 0.75, 0.9].map((f) => Math.round(W * f));
  const cab = [t("fecha"), t("oleada"), t("bajas"), t("monedas"), t("tiempo"), t("punteria")];
  cab.forEach((c, i) => texto(g, c, xs[i], 98, "#85837a", "centro"));
  if (!filas.length) texto(g, t("sinPartidas"), W / 2, 116, "#d1cec0", "centro");
  filas.forEach((p, k) => {
    const d = new Date(p.fecha), y = 112 + k * 12;
    const v = [dosCifras(d.getDate()) + "/" + dosCifras(d.getMonth() + 1), p.ronda, p.bajas, p.monedas, reloj(p.tiempo), p.punteria + "%"];
    v.forEach((c, i) => texto(g, c, xs[i], y, p.ronda === m.ronda && i === 1 ? "#f2c84a" : "#d1cec0", "centro"));
  });
  J.botonGrande(g, t("volver"), Math.min(H - 34, 116 + Math.max(1, filas.length) * 12 + 8), () => { J.verHistorial = false; sonar("boton"); });
}
