// Service worker: primero la red (siempre la última versión) y, sin conexión, la copia guardada.
const CACHE = "horda-pixel-v3";

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (e) => {
  e.waitUntil((async () => {
    for (const k of await caches.keys()) {
      if (k.startsWith("horda-pixel-") && k !== CACHE) await caches.delete(k);
    }
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.origin !== location.origin) return;
  e.respondWith((async () => {
    try {
      const r = await fetch(e.request.url, { cache: "no-cache" });
      if (r.ok) (await caches.open(CACHE)).put(e.request.url, r.clone());
      return r;
    } catch (err) {
      const guardada = await caches.match(e.request.url, { ignoreSearch: true });
      if (guardada) return guardada;
      throw err;
    }
  })());
});
