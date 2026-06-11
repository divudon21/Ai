#!/usr/bin/env python3
import os, time, json, threading
from http.server import HTTPServer, BaseHTTPRequestHandler

INBOX = "/tmp/opencode_in.txt"
OUTBOX = "/tmp/opencode_out.txt"
STATUS = "/tmp/opencode_status.txt"

class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_cors(200)
        self.end_headers()

    def do_GET(self):
        if self.path in ("/status", "/api/status"):
            reply = None
            status = "waiting"
            if os.path.exists(OUTBOX):
                with open(OUTBOX) as f:
                    reply = f.read().strip()
                os.remove(OUTBOX)
                status = "done"
                if os.path.exists(STATUS):
                    os.remove(STATUS)
            elif os.path.exists(STATUS):
                with open(STATUS) as f:
                    status = f.read().strip()
            self.send_json({"status": status, "reply": reply})

    def do_POST(self):
        if self.path in ("/chat", "/api/chat"):
            length = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(length).decode())
            msg = data.get("msg", "")
            with open(INBOX, "w") as f:
                f.write(msg)
            with open(STATUS, "w") as f:
                f.write("thinking")
            print(f"\n{'='*50}")
            print(f"📩 APP: {msg}")
            print(f"{'='*50}")
            print(f"Reply: echo 'your reply' > {OUTBOX}")
            self.send_json({"status": "ok"})

    def send_json(self, d):
        self.send_cors(200)
        self.end_headers()
        self.wfile.write(json.dumps(d).encode())

    def send_cors(self, code):
        self.send_response(code)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Content-Type", "application/json")

port = int(os.environ.get("RELAY_PORT", 9090))
print(f"Relay on :{port} (accessible via /api/ on port 7860)")
HTTPServer(("0.0.0.0", port), Handler).serve_forever()
