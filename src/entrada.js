// Controles: joystick táctil flotante (toca en cualquier sitio y arrastra) y teclado para probar en el ordenador.

export const entrada = {
  mx: 0, my: 0,                 // dirección de movimiento, longitud 0..1
  stick: null,                  // { id, ox, oy, x, y } en píxeles del juego mientras se toca
  botones: [],                  // zonas tocables que dibuja la interfaz cada fotograma
  teclas: new Set(),
  alPulsar: [],                 // funciones (tecla) para atajos
  tocado: false,                // algún toque o clic desde el último fotograma
};

export const RADIO_STICK = 16;  // px de juego que hay que arrastrar para ir a tope

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
    if (!entrada.stick) {
      entrada.stick = { id: e.pointerId, ox: p.x, oy: p.y, x: p.x, y: p.y };
      canvas.setPointerCapture?.(e.pointerId);
    }
  }, { passive: false });

  canvas.addEventListener("pointermove", (e) => {
    const s = entrada.stick;
    if (!s || s.id !== e.pointerId) return;
    const p = punto(e);
    s.x = p.x; s.y = p.y;
  });

  const soltar = (e) => {
    if (entrada.stick && entrada.stick.id === e.pointerId) entrada.stick = null;
  };
  canvas.addEventListener("pointerup", soltar);
  canvas.addEventListener("pointercancel", soltar);

  window.addEventListener("keydown", (e) => {
    entrada.teclas.add(e.code);
    entrada.tocado = true;
    for (const f of entrada.alPulsar) f(e.code);
  });
  window.addEventListener("keyup", (e) => entrada.teclas.delete(e.code));
  window.addEventListener("blur", () => { entrada.teclas.clear(); entrada.stick = null; });
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
    let dx = s.x - s.ox, dy = s.y - s.oy;
    const l = Math.hypot(dx, dy);
    if (l > RADIO_STICK) {               // el joystick sigue al dedo si se pasa del borde
      s.ox = s.x - (dx / l) * RADIO_STICK;
      s.oy = s.y - (dy / l) * RADIO_STICK;
      dx = s.x - s.ox; dy = s.y - s.oy;
    }
    const k = Math.min(1, l / RADIO_STICK);
    if (l > 2) { x = (dx / l) * k; y = (dy / l) * k; }
  }
  entrada.mx = x; entrada.my = y;
}
