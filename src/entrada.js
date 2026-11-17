// Controles: joystick táctil fijo abajo a la izquierda y teclado para probar en el ordenador.
// Solo mueve al personaje un toque que empieza encima del joystick (luego el dedo puede salirse de él).
// En disparo manual, la mitad derecha maneja el joystick de apuntar (abajo a la derecha).

export const entrada = {
  mx: 0, my: 0,                 // dirección de movimiento, longitud 0..1
  stick: null,                  // { id, ox, oy, x, y } en píxeles del juego mientras se toca
  base: { x: 50, y: 250 },      // centro fijo del joystick (lo coloca la interfaz)
  manual: false,                // disparo manual: hay joystick de apuntar
  apunta: null,                 // { id, x, y } mientras se toca el joystick de apuntar
  baseApunta: { x: 550, y: 250 },
  zonaStick: 0.5,               // fracción izquierda de la pantalla (el joystick de apuntar usa la derecha)
  ancho: 600,                   // ancho de la pantalla en píxeles de juego
  botones: [],                  // zonas tocables que dibuja la interfaz cada fotograma
  teclas: new Set(),
  alPulsar: [],                 // funciones (tecla) para atajos
  tocado: false,                // algún toque o clic desde el último fotograma
};

export const RADIO_STICK = 20;  // px de juego que hay que arrastrar para ir a tope
const RADIO_TOQUE = 30;         // px de juego desde el centro del joystick en los que un toque lo coge (el dibujo mide 52)

export function iniciarEntrada(canvas, aJuego) {
  const punto = (e) => aJuego(e.clientX, e.clientY);

  canvas.addEventListener("pointerdown", (e) => {
    e.preventDefault();
    entrada.tocado = true;
    const p = punto(e);
    for (let i = entrada.botones.length - 1; i >= 0; i--) {
      const b = entrada.botones[i];
      if (p.x >= b.x && p.x < b.x + b.w && p.y >= b.y && p.y < b.y + b.h) { b.accion(); return; }
    }
    const sobreStick = Math.hypot(p.x - entrada.base.x, p.y - entrada.base.y) <= RADIO_TOQUE;
    if (!entrada.stick && sobreStick) {
      entrada.stick = { id: e.pointerId, ox: entrada.base.x, oy: entrada.base.y, x: p.x, y: p.y };
      try { canvas.setPointerCapture?.(e.pointerId); } catch (err) { /* puntero simulado */ }
    } else if (!sobreStick && entrada.manual && !entrada.apunta && p.x >= entrada.ancho * entrada.zonaStick) {
      entrada.apunta = { id: e.pointerId, x: p.x, y: p.y };
      try { canvas.setPointerCapture?.(e.pointerId); } catch (err) { /* puntero simulado */ }
    }
  }, { passive: false });

  canvas.addEventListener("pointermove", (e) => {
    for (const s of [entrada.stick, entrada.apunta]) {
      if (!s || s.id !== e.pointerId) continue;
      const p = punto(e);
      s.x = p.x; s.y = p.y;
    }
  });

  const soltar = (e) => {
    if (entrada.stick && entrada.stick.id === e.pointerId) entrada.stick = null;
    if (entrada.apunta && entrada.apunta.id === e.pointerId) entrada.apunta = null;
  };
  canvas.addEventListener("pointerup", soltar);
  canvas.addEventListener("pointercancel", soltar);

  window.addEventListener("keydown", (e) => {
    entrada.teclas.add(e.code);
    entrada.tocado = true;
    for (const f of entrada.alPulsar) f(e.code);
  });
  window.addEventListener("keyup", (e) => entrada.teclas.delete(e.code));
  window.addEventListener("blur", () => { entrada.teclas.clear(); entrada.stick = null; entrada.apunta = null; });
  // Evita el menú de mantener pulsado y el zoom con dos dedos.
  canvas.addEventListener("contextmenu", (e) => e.preventDefault());
  document.addEventListener("gesturestart", (e) => e.preventDefault());
}

// Calcula la dirección de movimiento a partir del joystick o del teclado.
export function leerMovimiento() {
  let x = 0, y = 0;
  const t = entrada.teclas;
  if (t.has("KeyA") || t.has("ArrowLeft")) x -= 1;
  if (t.has("KeyD") || t.has("ArrowRight")) x += 1;
  if (t.has("KeyW") || t.has("ArrowUp")) y -= 1;
  if (t.has("KeyS") || t.has("ArrowDown")) y += 1;
  if (x || y) {
    const l = Math.hypot(x, y);
    x /= l; y /= l;
  }
  const s = entrada.stick;
  if (s) {
    s.ox = entrada.base.x; s.oy = entrada.base.y;   // el joystick no se mueve de su sitio
    const dx = s.x - s.ox, dy = s.y - s.oy;
    const l = Math.hypot(dx, dy);
    const k = Math.min(1, l / RADIO_STICK);
    if (l > 3) { x = (dx / l) * k; y = (dy / l) * k; }
  }
  entrada.mx = x; entrada.my = y;
}

// Disparo manual: ángulo hacia el que se apunta (radianes) o null si no se apunta.
// En el ordenador también vale con I J K L.
export function leerApuntado() {
  const a = entrada.apunta;
  if (a) {
    const dx = a.x - entrada.baseApunta.x, dy = a.y - entrada.baseApunta.y;
    return Math.hypot(dx, dy) > 5 ? Math.atan2(dy, dx) : null;
  }
  const t = entrada.teclas;
  const x = (t.has("KeyL") ? 1 : 0) - (t.has("KeyJ") ? 1 : 0), y = (t.has("KeyK") ? 1 : 0) - (t.has("KeyI") ? 1 : 0);
  return x || y ? Math.atan2(y, x) : null;
}
