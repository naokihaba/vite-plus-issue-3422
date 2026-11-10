# Local stand-in for mirrors.aliyun.com/nodejs-release:
# return 403 when the request has no User-Agent header, else redirect to nodejs.org.
import http.server, sys

class Handler(http.server.BaseHTTPRequestHandler):
    def handle_request(self):
        ua = self.headers.get("User-Agent")
        if not ua:
            self.send_response(403)
            self.end_headers()
            return
        self.send_response(302)
        self.send_header("Location", "https://nodejs.org/dist" + self.path)
        self.end_headers()

    do_GET = do_HEAD = handle_request

    def log_message(self, fmt, *args):
        ua = self.headers.get("User-Agent") or "(none)"
        sys.stderr.write(f"[mirror] {fmt % args} user-agent={ua}\n")

http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
