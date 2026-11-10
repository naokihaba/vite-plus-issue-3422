# Mock Node.js dist mirror: 403 for versions not yet synced, 302 to nodejs.org otherwise.
import http.server, os, sys
BLOCK = os.environ.get("BLOCK_VERSIONS", "24.22.2").split(",")
class H(http.server.BaseHTTPRequestHandler):
    def handle_one(self):
        if any(self.path.startswith(f"/v{v}/") for v in BLOCK):
            self.send_response(403); self.end_headers(); return
        self.send_response(302); self.send_header("Location", "https://nodejs.org/dist" + self.path); self.end_headers()
    do_GET = do_HEAD = handle_one
    def log_message(self, fmt, *a): sys.stderr.write("[mirror] " + (fmt % a) + "\n")
http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
