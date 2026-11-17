// Cuenta en la nube (Firebase): entrar con correo y contraseña o con Google, y guardar el perfil
// (partidas, totales, marcas, traje y mascota) para no perderlo al cambiar de móvil.
// Sin cuenta se juega igual: todo se queda en el móvil. Solo se guarda el correo y el progreso.
// La librería de Firebase Authentication se descarga solo si hay configuración (src/nube-config.js).
// El perfil se lee y se escribe con la API REST de Firestore (sin cargar su librería, que pesa mucho):
// un documento perfiles/{uid} con el perfil en texto. Las reglas de Firestore solo dejan a cada uno el suyo.
import { FIREBASE } from "./nube-config.js";
import { leerPerfil, mezclarPerfil, avisarAlGuardar } from "./perfil.js";

const VERSION = "10.12.2";
export const estado = { listo: false, usuario: null, sincronizando: false, ultima: 0, error: "" };
const oyentes = new Set();
export function alCambiar(f) { oyentes.add(f); return () => oyentes.delete(f); }
const avisar = () => { for (const f of oyentes) f(estado); };

let fb = null;             // { au, auth }
let subida = null;         // temporizador de la subida pendiente

export const configurada = () => !!FIREBASE;

export async function iniciarNube() {
  if (!FIREBASE || fb) return;
  try {
    const base = `https://www.gstatic.com/firebasejs/${VERSION}/`;
    const [ap, au] = await Promise.all([import(base + "firebase-app.js"), import(base + "firebase-auth.js")]);
    const app = ap.initializeApp(FIREBASE);
    const auth = au.getAuth(app);
    au.useDeviceLanguage(auth);
    fb = { au, auth };
    // Vuelta de «entrar con Google» por redirección (si la ventana emergente no se pudo abrir)
    au.getRedirectResult(auth).catch((e) => { estado.error = e.code || "error"; avisar(); });
    au.onAuthStateChanged(auth, (u) => {
      estado.usuario = u ? { uid: u.uid, correo: u.email || "", google: u.providerData.some((p) => p.providerId === "google.com") } : null;
      estado.listo = true;
      avisar();
      if (u) sincronizar();
    });
    avisarAlGuardar(() => { if (estado.usuario) { clearTimeout(subida); subida = setTimeout(subir, 1500); } });
  } catch (e) {
    estado.error = "sinConexion"; estado.listo = true; avisar();
  }
}

// ------------------------------------------------------------------ entrar y salir
async function conAuth(f) {
  if (!fb) await iniciarNube();
  if (!fb) throw { code: "sinConexion" };
  return f(fb.au, fb.auth);
}
export const entrar = (correo, clave) => conAuth((au, auth) => au.signInWithEmailAndPassword(auth, correo, clave));
export const crearCuenta = (correo, clave) => conAuth((au, auth) => au.createUserWithEmailAndPassword(auth, correo, clave));
export const recuperarClave = (correo) => conAuth((au, auth) => au.sendPasswordResetEmail(auth, correo));
export const salir = () => conAuth((au, auth) => au.signOut(auth));
export function entrarGoogle() {
  return conAuth(async (au, auth) => {
    const prov = new au.GoogleAuthProvider();
    prov.setCustomParameters({ prompt: "select_account" });
    try { return await au.signInWithPopup(auth, prov); }
    catch (e) {
      // Sin ventanas emergentes (por ejemplo, la app instalada en el iPhone): por redirección
      if (e.code === "auth/popup-blocked" || e.code === "auth/operation-not-supported-in-this-environment") return au.signInWithRedirect(auth, prov);
      throw e;
    }
  });
}
// Borra el perfil de la nube y la cuenta. El progreso de este móvil se queda.
export function borrarCuenta() {
  return conAuth(async (au, auth) => {
    const u = auth.currentUser;
    if (!u) return;
    await documento(u, "DELETE");
    await au.deleteUser(u);
  });
}

// ------------------------------------------------------------------ perfil en Firestore (REST)
async function documento(u, metodo, cuerpo) {
  const token = await u.getIdToken();
  const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE.projectId}/databases/(default)/documents/perfiles/${u.uid}`;
  const r = await fetch(url, {
    method: metodo, headers: { Authorization: "Bearer " + token, "Content-Type": "application/json" },
    body: cuerpo ? JSON.stringify(cuerpo) : undefined,
  });
  if (r.status === 404) return null;
  if (!r.ok) throw { code: "firestore/" + r.status };
  return r.json();
}

// Baja el perfil de la nube, lo mezcla con el de aquí y sube el resultado.
export async function sincronizar() {
  const u = fb?.auth.currentUser;
  if (!u || estado.sincronizando) return;
  estado.sincronizando = true; estado.error = ""; avisar();
  try {
    const doc = await documento(u, "GET");
    const texto = doc?.fields?.datos?.stringValue;
    if (texto) mezclarPerfil(JSON.parse(texto));
    await subir();
  } catch (e) {
    estado.error = e.code || "error";
  }
  estado.sincronizando = false; avisar();
}

async function subir() {
  const u = fb?.auth.currentUser;
  if (!u) return;
  try {
    await documento(u, "PATCH", { fields: {
      datos: { stringValue: JSON.stringify(leerPerfil()) },
      actualizado: { integerValue: String(Date.now()) },
    } });
    estado.ultima = Date.now(); estado.error = "";
  } catch (e) { estado.error = e.code || "error"; }
  avisar();
}
