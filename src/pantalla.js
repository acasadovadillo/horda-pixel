// En el móvil, al tocar para jugar: pantalla completa y bloqueo en horizontal (donde el navegador lo permite).
export function pantallaCompletaHorizontal() {
  if (!matchMedia("(pointer: coarse)").matches) return;
  const el = document.documentElement;
  const pedir = el.requestFullscreen?.bind(el) || el.webkitRequestFullscreen?.bind(el);
  Promise.resolve(document.fullscreenElement || !pedir ? null : pedir({ navigationUI: "hide" }))
    .then(() => screen.orientation?.lock?.("landscape"))
    .catch(() => {});
}
