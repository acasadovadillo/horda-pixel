# Plan de mejoras de Horda Pixel

Tres mejoras pedidas el 2026-11-17. Orden recomendado: 1, 2, 3. Las cuentas van al final porque antes hay que elegir y crear el servicio externo.

## 1. Todo destruible (estilo Streets of Rogue)

Objetivo: casi todo lo que hay en el mapa se puede romper con balas, explosiones, fuego o el cuerpo a cuerpo.

- **Objetos con vida**: coches, cajas, barriles, contenedores, neumáticos, farolas, conos, árboles, arbustos y vallas.
  - Cada uno tiene vida según su material (madera, metal, plástico, vegetación).
  - Al recibir daño se ve dañado (otro fotograma) y al romperse deja restos en el suelo y suelta trozos (astillas, chispas, cristales).
  - Al romperse deja de chocar: se puede pasar por donde estaba.
- **Botín dentro**: las cajas, los contenedores y los coches pueden soltar monedas, munición, botiquines o granadas.
- **Fuego que se extiende**: la madera, la hierba seca y los coches se prenden con el lanzallamas, los molotov y las explosiones, y el fuego pasa a lo que tienen al lado. Los coches que arden acaban estallando.
- **Edificios abandonados** por el mapa (casas, una gasolinera, una tienda) con paredes y puertas que se pueden reventar para entrar a saquear.
- **Técnica**:
  - El mapa pasa a una cuadrícula de casillas con material y vida.
  - El suelo y las paredes se redibujan por trozos cuando algo se rompe.
  - Los choques y el camino de los zombis se recalculan al abrirse huecos.
- **Dibujos**: estados dañado y roto de cada objeto, restos, paredes y puertas de edificios con sus estados, y trozos.

## 2. Todos los comercios en la base

Objetivo: en vez de un único puesto con pestañas, varios comercios dentro de la base, cada uno con su caseta y su vendedor.

- **Armero**: armas y mejoras de armas.
- **Intendente**: munición, granadas, molotov y trampas.
- **Médico**: curación, botiquines y chaleco.
- **Mecánico**: reparar y reforzar el muro, alambre, torretas y focos.
- **Constructor**: enfermería, taller y armería.
- **Cómo se compra**: al acercarte a un comercio aparece su botón y se abre solo su parte de la tienda, con el juego parado como ahora.
- **Dibujos**: una caseta por comercio y un vendedor por caseta (personas recoloreadas, como los supervivientes, o dibujos nuevos).
- **Pendiente de confirmar**: si «todos disponibles» significa esto (varios comercios) o que todo se pueda comprar desde el principio sin desbloquear.

## 3. Cuenta y login

Objetivo: una cuenta para no perder el progreso al cambiar de móvil.

- **Servicio**: Firebase (Authentication + Firestore) o Supabase; los dos tienen plan gratuito y funcionan con un juego sin servidor propio como este. La cuenta del servicio la crea el usuario.
- **Formas de entrar**: correo y contraseña, y Google.
  - Entrar con Apple exige una cuenta de desarrollador de Apple (de pago).
- **Qué se guarda en la nube**: el perfil que hoy está en `horda-pixel:perfil` (partidas, totales, mejores marcas, logros, traje y mascota).
  - Al entrar se mezcla con lo que haya en el móvil, quedándose con lo mejor de cada lado.
- **Sin cuenta se sigue pudiendo jugar** como ahora (todo en el móvil).
- **Pantallas**: entrar, crear cuenta, recuperar contraseña y cerrar sesión, desde la pantalla de inicio.
- **Privacidad**: se guarda lo mínimo (correo y progreso del juego) y la cuenta se puede borrar.
