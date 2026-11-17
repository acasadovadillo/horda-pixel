// Panel de la cuenta (HTML encima del lienzo, porque hacen falta casillas para escribir el correo y la clave).
// Se abre con el botón CUENTA de la pantalla de inicio. Textos en idioma.js (claves cuenta_* y err_*).
import { t } from "./idioma.js";
import { estado, alCambiar, configurada, iniciarNube, entrar, crearCuenta, recuperarClave, entrarGoogle, salir, borrarCuenta, sincronizar } from "./nube.js";
import { sonar } from "./audio.js";

let panel = null, quitarOyente = null, mensaje = "", aviso = false, borrar = false, ocupado = false;

const ERRORES = {
  "auth/invalid-email": "err_correo", "auth/missing-email": "err_correo",
  "auth/user-not-found": "err_datos", "auth/wrong-password": "err_datos", "auth/invalid-credential": "err_datos",
  "auth/invalid-login-credentials": "err_datos", "auth/missing-password": "err_clave",
  "auth/email-already-in-use": "err_yaExiste", "auth/weak-password": "err_debil",
  "auth/too-many-requests": "err_muchos", "auth/network-request-failed": "err_red", sinConexion: "err_red",
  "auth/popup-closed-by-user": "err_cancelado", "auth/cancelled-popup-request": "err_cancelado",
  "auth/requires-recent-login": "err_reciente", "auth/unauthorized-domain": "err_dominio",
  "auth/operation-not-allowed": "err_noActivado",
};
const textoError = (c) => t(ERRORES[c] || "err_otro");

const ESTILO = `
#cuenta { position: fixed; inset: 0; z-index: 4; background: rgba(14,13,18,0.86); display: flex; align-items: center; justify-content: center;
  overflow: auto; -webkit-user-select: text; user-select: text; touch-action: auto; font: bold 14px/1.35 ui-monospace, Menlo, monospace; color: #d1cec0; }
#cuenta .caja { width: min(560px, calc(100% - 32px)); max-height: calc(100% - 16px); overflow: auto; box-sizing: border-box; margin: 8px auto;
  background: #1a1920; border: 2px solid #0e0d12; box-shadow: 0 0 0 2px #3b526b; padding: 14px 16px; }
#cuenta h2 { margin: 0 0 8px; color: #f2c84a; font-size: 20px; letter-spacing: 1px; }
#cuenta p { margin: 6px 0; }
#cuenta .fila { display: flex; gap: 8px; flex-wrap: wrap; margin: 8px 0; }
#cuenta input { flex: 1 1 180px; min-width: 0; font: inherit; font-size: 16px; color: #ffffff; background: #0e0d12; border: 2px solid #34363d;
  padding: 7px 8px; border-radius: 0; -webkit-appearance: none; }
#cuenta input:focus { outline: none; border-color: #f2c84a; }
#cuenta button { flex: 1 1 auto; font: inherit; color: #ffffff; background: #3b526b; border: 2px solid #0e0d12; padding: 8px 10px;
  text-transform: uppercase; cursor: pointer; border-radius: 0; box-shadow: inset 0 -3px 0 rgba(0,0,0,0.25); }
#cuenta button:disabled { opacity: 0.5; }
#cuenta button.ok { background: #4a6a34; } #cuenta button.gris { background: #34363d; } #cuenta button.rojo { background: #872a26; }
#cuenta button.google { background: #d1cec0; color: #1a1920; }
#cuenta .enlace { background: none; border: none; box-shadow: none; color: #a8a59a; text-decoration: underline; padding: 2px 0; flex: 0 0 auto; text-transform: none; }
#cuenta .msg { min-height: 1.35em; color: #7ee07e; } #cuenta .msg.mal { color: #ff7a6b; }
#cuenta .nota { color: #85837a; font-size: 12px; }
`;

export function abrirCuenta() {
  if (panel) return;
  if (!document.getElementById("estilo-cuenta")) {
    const st = document.createElement("style"); st.id = "estilo-cuenta"; st.textContent = ESTILO; document.head.appendChild(st);
  }
  panel = document.createElement("div");
  panel.id = "cuenta";
  // Que los toques y las teclas no lleguen al juego
  for (const ev of ["pointerdown", "touchstart", "keydown"]) panel.addEventListener(ev, (e) => e.stopPropagation());
  panel.addEventListener("pointerdown", (e) => { if (e.target === panel) cerrarCuenta(); });
  document.body.appendChild(panel);
  mensaje = ""; aviso = false; borrar = false;
  quitarOyente = alCambiar(pintar);
  iniciarNube();
  pintar();
}

export function cerrarCuenta() {
  if (!panel) return;
  quitarOyente?.();
  panel.remove(); panel = null;
  sonar("boton");
}
export const cuentaAbierta = () => !!panel;

function decir(txt, mal = false) { mensaje = txt; aviso = mal; pintar(); }

async function hacer(f, exito) {
  if (ocupado) return;
  ocupado = true; decir(t("cuenta_espera"));
  try { await f(); ocupado = false; decir(exito ? t(exito) : ""); }
  catch (e) { ocupado = false; decir(textoError(e?.code), true); }
}

function pintar() {
  if (!panel) return;
  const u = estado.usuario;
  const correoAntes = panel.querySelector("#c-correo")?.value || "";
  const claveAntes = panel.querySelector("#c-clave")?.value || "";
  let html = `<div class="caja"><h2>${t("cuenta_titulo")}</h2>`;
  if (!configurada()) {
    html += `<p>${t("cuenta_sinConfigurar")}</p>`;
  } else if (!estado.listo) {
    html += `<p>${t("cuenta_conectando")}</p>`;
  } else if (u) {
    const cuando = estado.ultima ? new Date(estado.ultima).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : "";
    html += `<p>${t("cuenta_conectado")} <span style="color:#fff">${esc(u.correo)}</span></p>
      <p class="nota">${estado.sincronizando ? t("cuenta_sincronizando") : estado.error ? textoError(estado.error) : cuando ? t("cuenta_guardado").replace("{h}", cuando) : t("cuenta_explica")}</p>
      <div class="fila"><button class="gris" data-a="sinc">${t("cuenta_sincronizar")}</button><button data-a="salir">${t("cuenta_salir")}</button></div>
      <div class="fila"><button class="rojo" data-a="borrar">${borrar ? t("cuenta_borrarSeguro") : t("cuenta_borrar")}</button></div>`;
  } else {
    html += `<p class="nota">${t("cuenta_explica")}</p>
      <div class="fila"><input id="c-correo" type="email" autocomplete="email" autocapitalize="off" spellcheck="false" placeholder="${t("cuenta_correo")}">
      <input id="c-clave" type="password" autocomplete="current-password" placeholder="${t("cuenta_clave")}"></div>
      <div class="fila"><button class="ok" data-a="entrar">${t("cuenta_entrar")}</button><button data-a="crear">${t("cuenta_crear")}</button>
      <button class="google" data-a="google">${t("cuenta_google")}</button></div>
      <div class="fila"><button class="enlace" data-a="olvido">${t("cuenta_olvido")}</button></div>`;
  }
  html += `<p class="msg${aviso ? " mal" : ""}">${esc(mensaje)}</p><div class="fila"><button class="gris" data-a="cerrar">${t("cuenta_cerrar")}</button></div></div>`;
  panel.innerHTML = html;
  const ci = panel.querySelector("#c-correo"), cl = panel.querySelector("#c-clave");
  if (ci) { ci.value = correoAntes; cl.value = claveAntes; cl.addEventListener("keydown", (e) => { if (e.key === "Enter") accion("entrar"); }); }
  for (const b of panel.querySelectorAll("button")) {
    b.disabled = ocupado && b.dataset.a !== "cerrar";
    b.addEventListener("click", () => accion(b.dataset.a));
  }
}

function accion(a) {
  const correo = (panel.querySelector("#c-correo")?.value || "").trim(), clave = panel.querySelector("#c-clave")?.value || "";
  if (a !== "cerrar") sonar("boton");
  if (a === "cerrar") return cerrarCuenta();
  if (a === "entrar") return hacer(() => entrar(correo, clave));
  if (a === "crear") return hacer(() => crearCuenta(correo, clave), "cuenta_creada");
  if (a === "google") return hacer(() => entrarGoogle());
  if (a === "olvido") {
    if (!correo) return decir(t("err_correo"), true);
    return hacer(() => recuperarClave(correo), "cuenta_correoEnviado");
  }
  if (a === "sinc") return hacer(() => sincronizar());
  if (a === "salir") return hacer(() => salir(), "cuenta_saliste");
  if (a === "borrar") {
    if (!borrar) { borrar = true; return pintar(); }
    borrar = false;
    return hacer(() => borrarCuenta(), "cuenta_borrada");
  }
}

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
