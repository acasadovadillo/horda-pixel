// Ragdoll de pixel art. Al morir, el fotograma que se estaba viendo se trocea en cabeza, tronco,
// brazos y piernas, y cada trozo cuelga de un esqueleto de palos (física por posiciones):
// el cuerpo se desploma con el golpe, y los miembros que se arrancan salen volando soltando sangre.
// Sirve para cualquier sprite de persona de pie (jugador, zombis y lo que venga).
//
// Coordenadas del mundo: x, y = posición en el suelo; z = altura. En pantalla se ve en (x, y - z).

const GRAVEDAD = 330;       // px/s², la misma que las monedas y las gotas
const VUELTAS = 5;          // pasadas para que los palos mantengan su largo

const datos = new WeakMap();  // hoja -> ImageData (se lee una sola vez)
function pixeles(img) {
  let d = img.pixeles || datos.get(img);
  if (!d) {
    const c = document.createElement("canvas");
    c.width = img.width; c.height = img.height;
    const g = c.getContext("2d");
    g.drawImage(img, 0, 0);
    d = g.getImageData(0, 0, img.width, img.height);
    datos.set(img, d);
  }
  return d;
}

const rnd = (a, b) => a + Math.random() * (b - a);

// Trocea el fotograma. Devuelve los trozos (lienzo + origen en el sprite) y los puntos del esqueleto
// en coordenadas del sprite (ya volteado si hace falta).
function trocear(img, f, pies, voltear) {
  const d = pixeles(img), W = d.width, p = d.data;
  const col = (sx, sy) => {
    const ix = f.x + (voltear ? f.w - 1 - sx : sx), i = ((f.y + sy) * W + ix) * 4;
    return p[i + 3] ? i : -1;
  };
  const opacos = [];
  for (let sy = 0; sy < f.h; sy++) for (let sx = 0; sx < f.w; sx++) if (col(sx, sy) >= 0) opacos.push([sx, sy]);
  if (!opacos.length) return null;
  const pie = voltear ? { x: f.w - 1 - pies.x, y: pies.y } : pies;
  const T = Math.min(...opacos.map((o) => o[1]));
  const h = Math.max(8, pie.y - T);
  const finCabeza = T + Math.round(h * 0.2), finTronco = T + Math.round(h * 0.55);
  const media = (lista) => lista.length ? lista.reduce((s, v) => s + v, 0) / lista.length : pie.x;
  const hx = Math.round(media(opacos.filter((o) => o[1] <= T + 2).map((o) => o[0])));
  const cx = Math.round(media(opacos.filter((o) => o[1] >= finCabeza && o[1] < finTronco).map((o) => o[0])));

  const grupos = { cabeza: [], tronco: [], brazoI: [], brazoD: [], piernaI: [], piernaD: [] };
  for (const [sx, sy] of opacos) {
    let g;
    if (sy < finCabeza) g = Math.abs(sx - hx) <= 4 ? "cabeza" : sx < hx ? "brazoI" : "brazoD";
    else if (sy < finTronco) g = Math.abs(sx - cx) <= 4 ? "tronco" : sx < cx ? "brazoI" : "brazoD";
    else if (Math.abs(sx - cx) > 7 && sy < T + h * 0.78) g = sx < cx ? "brazoI" : "brazoD";   // manos que cuelgan
    else g = sx < cx ? "piernaI" : "piernaD";
    grupos[g].push([sx, sy]);
  }
  // Trozos con muy pocos píxeles: al tronco.
  for (const k of ["brazoI", "brazoD", "cabeza"]) {
    if (grupos[k].length < 4) { grupos.tronco.push(...grupos[k]); grupos[k] = []; }
  }

  const N = { x: cx, y: finCabeza }, P = { x: cx, y: finTronco };
  const lejos = (lista, desde) => lista.reduce((m, o) => {
    const dd = (o[0] - desde.x) ** 2 + (o[1] - desde.y) ** 2;
    return dd > m.d ? { d: dd, x: o[0], y: o[1] } : m;
  }, { d: -1, x: desde.x, y: desde.y + 1 });
  const abajo = (lista) => {
    if (!lista.length) return { x: P.x, y: pie.y };
    const y = Math.max(...lista.map((o) => o[1]));
    return { x: Math.round(media(lista.filter((o) => o[1] >= y - 1).map((o) => o[0]))), y };
  };
  const puntos = { N, P, H: { x: hx, y: T }, MI: lejos(grupos.brazoI, N), MD: lejos(grupos.brazoD, N), PI: abajo(grupos.piernaI), PD: abajo(grupos.piernaD) };

  // Cada trozo: de qué punto cuelga (a) y hacia cuál apunta (b).
  const PALOS = { cabeza: ["N", "H"], tronco: ["N", "P"], brazoI: ["N", "MI"], brazoD: ["N", "MD"], piernaI: ["P", "PI"], piernaD: ["P", "PD"] };
  const trozos = [];
  for (const [nombre, lista] of Object.entries(grupos)) {
    if (!lista.length) continue;
    const x0 = Math.min(...lista.map((o) => o[0])), y0 = Math.min(...lista.map((o) => o[1]));
    const x1 = Math.max(...lista.map((o) => o[0])), y1 = Math.max(...lista.map((o) => o[1]));
    const c = document.createElement("canvas");
    c.width = x1 - x0 + 1; c.height = y1 - y0 + 1;
    const g = c.getContext("2d"), im = g.createImageData(c.width, c.height);
    for (const [sx, sy] of lista) {
      const i = col(sx, sy), j = ((sy - y0) * c.width + (sx - x0)) * 4;
      im.data[j] = p[i]; im.data[j + 1] = p[i + 1]; im.data[j + 2] = p[i + 2]; im.data[j + 3] = 255;
    }
    g.putImageData(im, 0, 0);
    trozos.push({ nombre, lienzo: c, x0, y0, a: PALOS[nombre][0], b: PALOS[nombre][1] });
  }
  return { trozos, puntos, pie };
}

// Crea un ragdoll.
//  img, frame, pies, voltear: el fotograma que se estaba viendo (frame = {x, y, w, h} en la hoja).
//  x, y: pies en el mundo.  dir: {x, y} dirección del golpe en el suelo.  fuerza: 1 = disparo normal.
//  arrancar: probabilidad de arrancar cada miembro (al menos uno sale siempre si es > 0).
//  cabeza: true = la cabeza sale seguro.  extra: otro trozo colgado del cuello (los brazos con el arma).
export function crearRagdoll({ img, frame, pies, voltear, x, y, dir, fuerza = 1, arrancar = 0.5, cabeza = false, extra = null }) {
  const t = trocear(img, frame, pies, voltear);
  if (!t) return null;
  const pts = {};
  const largo = Math.hypot(dir.x, dir.y) || 1, ux = dir.x / largo, uy = dir.y / largo;
  for (const [k, q] of Object.entries(t.puntos)) {
    const alto = t.pie.y - q.y;                 // cuanto más alto el punto, más empuje
    const k2 = 0.35 + alto / 30;
    pts[k] = {
      x: x + (q.x - t.pie.x), y: y + rnd(-0.5, 0.5), z: Math.max(0, alto),
      vx: (ux * 48 * fuerza + rnd(-10, 10)) * k2, vy: (uy * 32 * fuerza + rnd(-8, 8)) * k2,
      vz: rnd(20, 45) * Math.min(1.6, fuerza) * k2,
    };
  }
  const trozos = t.trozos.map((tr) => ({ ...tr, ra: t.puntos[tr.a], rb: t.puntos[tr.b] }));
  if (extra) trozos.push(extra(pts, t.pie));

  // Arrancar miembros: el trozo pasa a colgar de un punto propio, que sale disparado.
  const miembros = trozos.filter((tr) => tr.nombre !== "tronco" && tr.nombre !== "arma");
  const sueltos = new Set();
  for (const tr of miembros) if (Math.random() < arrancar || (cabeza && tr.nombre === "cabeza")) sueltos.add(tr);
  if (arrancar > 0 && !sueltos.size && miembros.length) sueltos.add(miembros[Math.floor(Math.random() * miembros.length)]);
  const chorros = [];
  for (const tr of sueltos) {
    const viejo = pts[tr.a], nuevo = tr.a + "_" + tr.nombre;
    const lanza = 1 + fuerza * 0.3;                      // vuela un metro o dos; con escopeta, algo más
    pts[nuevo] = {
      ...viejo,
      vx: viejo.vx + rnd(-38, 38) * lanza, vy: viejo.vy + rnd(-22, 22) * lanza, vz: Math.max(0, viejo.vz) + rnd(40, 85) * lanza,
    };
    // El extremo del miembro también sale con él
    const punta = pts[tr.b];
    if (tr.b !== "N" && tr.b !== "P" && !trozos.some((o) => o !== tr && (o.a === tr.b || o.b === tr.b))) {
      punta.vx = pts[nuevo].vx * rnd(0.6, 1.3); punta.vy = pts[nuevo].vy * rnd(0.6, 1.3); punta.vz = pts[nuevo].vz * rnd(0.5, 1.2);
    }
    tr.a = nuevo;
    chorros.push({ desde: nuevo, hacia: tr.b, t: rnd(0.5, 0.9) }, { desde: viejo === pts.N ? "N" : "P", hacia: null, t: rnd(0.6, 1.1) });
  }
  // Palos con su largo de reposo (en el plano del sprite: x y altura)
  const palos = trozos.map((tr) => {
    const pa = pts[tr.a], pb = pts[tr.b];
    return { a: tr.a, b: tr.b, largo: Math.max(1, Math.hypot(pa.x - pb.x, pa.z - pb.z)) };
  });
  return { pts, trozos, palos, chorros, t: 0, y: y, quieto: 0 };
}

// Avanza la física. sangrar(x, y, z, vx, vy, vz) suelta una gota.
export function moverRagdoll(r, dt, sangrar) {
  r.t += dt;
  const pts = Object.values(r.pts);
  const viejos = pts.map((p) => [p.x, p.y, p.z]);
  for (const p of pts) {
    p.vz -= GRAVEDAD * dt;
    p.x += p.vx * dt; p.y += p.vy * dt; p.z += p.vz * dt;
  }
  for (let v = 0; v < VUELTAS; v++) {
    for (const s of r.palos) {
      const a = r.pts[s.a], b = r.pts[s.b];
      const dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z;
      const d = Math.hypot(dx, dy, dz) || 0.001, k = (d - s.largo) / d / 2;
      a.x += dx * k; a.y += dy * k; a.z += dz * k;
      b.x -= dx * k; b.y -= dy * k; b.z -= dz * k;
    }
    for (const p of pts) if (p.z < 0) p.z = 0;
  }
  let movimiento = 0;
  pts.forEach((p, i) => {
    const [x0, y0, z0] = viejos[i];
    const vzAntes = p.vz;
    p.vx = (p.x - x0) / dt; p.vy = (p.y - y0) / dt; p.vz = (p.z - z0) / dt;
    if (p.z <= 0.01) {                                   // en el suelo: rebota poco y se arrastra
      if (vzAntes < -90) p.vz = -vzAntes * 0.22;
      const roce = Math.max(0, 1 - 12 * dt);
      p.vx *= roce; p.vy *= roce;
      if (Math.abs(p.vx) + Math.abs(p.vy) < 4) { p.vx = 0; p.vy = 0; }
    }
    movimiento = Math.max(movimiento, Math.abs(p.vx) + Math.abs(p.vy) + Math.abs(p.vz));
  });
  r.quieto = movimiento < 6 ? r.quieto + dt : 0;
  r.y = r.pts.P.y;
  // Chorros de sangre de los muñones
  for (const c of r.chorros) {
    if (c.t <= 0) continue;
    c.t -= dt;
    if (Math.random() > dt * 40) continue;
    const p = r.pts[c.desde], q = c.hacia ? r.pts[c.hacia] : null;
    let ux = rnd(-1, 1), uz = rnd(0.2, 1);
    if (q) { const l = Math.hypot(p.x - q.x, p.z - q.z) || 1; ux = (p.x - q.x) / l; uz = Math.max(0.3, (p.z - q.z) / l); }
    sangrar(p.x, p.y, p.z, ux * rnd(30, 90) + p.vx * 0.5, rnd(-25, 25) + p.vy * 0.5, uz * rnd(40, 110));
  }
}

// ¿Ya está en el suelo y quieto? Entonces se puede pintar en el suelo para siempre.
export function asentado(r) { return (r.quieto > 0.6 && r.t > 1.2) || r.t > 5; }

export function dibujarRagdoll(g, r) {
  g.imageSmoothingEnabled = false;            // el suelo también: píxeles nítidos al girar
  for (const tr of r.trozos) {
    const a = r.pts[tr.a], b = r.pts[tr.b];
    const ax = a.x, ay = a.y - a.z, bx = b.x, by = b.y - b.z;
    const reposo = Math.atan2(tr.rb.y - tr.ra.y, tr.rb.x - tr.ra.x);
    let ang = Math.atan2(by - ay, bx - ax);
    if (Math.hypot(bx - ax, by - ay) < 0.5) ang = tr.ang ?? reposo;
    tr.ang = ang;
    g.save();
    g.translate(Math.round(ax), Math.round(ay));
    g.rotate(ang - reposo);
    g.drawImage(tr.lienzo, tr.x0 - tr.ra.x, tr.y0 - tr.ra.y);
    g.restore();
  }
}
