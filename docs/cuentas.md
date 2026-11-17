# Cuentas de Horda Pixel (Firebase)

El código de las cuentas ya está en el juego (`src/nube.js`, `src/cuenta.js`, perfil en `src/perfil.js`).
Mientras `src/nube-config.js` tenga `FIREBASE = null`, no sale el botón CUENTA y todo se guarda solo en el móvil.
Para probar el panel sin Firebase: `?cuenta=prueba` en la dirección.

## Qué se guarda

Un documento `perfiles/{uid}` en Firestore con el perfil en texto (partidas, totales, mejores marcas, traje y mascota) y la hora del último cambio.
Al entrar se mezcla con el del móvil, quedándose con lo mejor de cada lado:
- las partidas de los dos, sin repetir;
- el mayor de cada total y de cada marca;
- el traje y la mascota del que se cambió más tarde.

Después, cada cambio del perfil se sube solo.
Al cerrar sesión o borrar la cuenta, el progreso sigue en el móvil.

## Pasos para crear el servicio (los hace el dueño del juego)

1. Entra en https://console.firebase.google.com con tu cuenta de Google y pulsa **Crear un proyecto**. Llámalo, por ejemplo, `horda-pixel`. Google Analytics no hace falta.
2. **Authentication**:
   1. Entra en **Authentication > Comenzar**.
   2. En **Método de inicio de sesión**, activa **Correo electrónico/contraseña** y **Google**. Para Google te pide un correo de asistencia: elige el tuyo.
   3. En **Configuración > Dominios autorizados**, añade `acasadovadillo.github.io`.
3. **Firestore Database**:
   1. Pulsa **Crear base de datos**.
   2. Elige una ubicación en Europa (por ejemplo `eur3`) y empieza en **modo de producción**.
   3. En **Reglas**, pega esto y pulsa **Publicar**:

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /perfiles/{uid} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```

4. **Configuración del proyecto** (rueda dentada) **> General > Tus apps**:
   1. Pulsa el icono **</>** (Web) y registra la app con el nombre `Horda Pixel`. Firebase Hosting no hace falta.
   2. Copia el objeto `firebaseConfig` que aparece (`apiKey`, `authDomain`, `projectId`, `appId`…). No es secreto: va en la página.
5. Pásale ese objeto a Claude, que lo pone en `src/nube-config.js` y publica.

El plan gratuito (Spark) sobra para este juego: no hace falta poner una tarjeta.

## Avisos

- **Google en el iPhone:**
  - Con el juego instalado en la pantalla de inicio, Safari puede no dejar abrir la ventana de Google. Entonces el juego prueba por redirección.
  - Si aun así falla, se puede entrar con correo y contraseña.
  - Desde Safari normal funciona.
- **Borrar la cuenta:** Firebase pide haber entrado hace poco. Si lo rechaza, el panel dice que cierres sesión, vuelvas a entrar y repitas.
