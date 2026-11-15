"""Servidor local sin caché: python3 servidor.py [puerto] [--red]
Con --red escucha en toda la red de casa para abrir el juego desde el móvil (misma wifi)."""
import functools, http.server, os, socket, sys

class SinCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()
    def log_message(self, *a):
        pass

args = [a for a in sys.argv[1:] if not a.startswith("--")]
puerto = int(args[0]) if args else 8140
red = "--red" in sys.argv
carpeta = os.path.dirname(os.path.abspath(__file__))
h = functools.partial(SinCache, directory=carpeta)
if red:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1)); ip = s.getsockname()[0]
    except OSError:
        ip = "IP-del-ordenador"
    finally:
        s.close()
    print(f"Horda Pixel en el móvil: http://{ip}:{puerto}")
print(f"Horda Pixel en http://localhost:{puerto}", flush=True)
http.server.ThreadingHTTPServer(("0.0.0.0" if red else "127.0.0.1", puerto), h).serve_forever()
