#!/usr/bin/env python3
import os, time, json, threading, sys, io
from http.server import HTTPServer, BaseHTTPRequestHandler
import requests
from duckduckgo_search import DDGS
from bs4 import BeautifulSoup

HF_TOKEN = os.environ.get("HF_TOKEN")
API_URL = "https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct/v1/chat/completions"
HEADERS = {"Authorization": f"Bearer {HF_TOKEN}"}

INBOX = "/tmp/opencode_in.txt"
OUTBOX = "/tmp/opencode_out.txt"
STATUS = "/tmp/opencode_status.txt"

def web_search(q):
    with DDGS() as ddgs:
        r = list(ddgs.text(q, max_results=3))
        return json.dumps([{"title": x["title"], "snippet": x["body"]} for x in r])

def read_webpage(url):
    r = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
    s = BeautifulSoup(r.text, "html.parser")
    return " ".join(s.stripped_strings)[:3000]

def calc(expr):
    allowed = "0123456789+-*/(). "
    if not all(c in allowed for c in expr):
        return "Invalid expression"
    return str(eval(expr, {"__builtins__": {}}, {}))

def py_exec(code):
    old = sys.stdout
    sys.stdout = io.StringIO()
    try:
        exec(code, {"__builtins__": __builtins__}, {})
        out = sys.stdout.getvalue() or "Done."
        sys.stdout = old
        return out
    except Exception as e:
        sys.stdout = old
        return f"Error: {e}"

TOOLS = [
    {"type": "function", "function": {"name": "web_search", "description": "Search internet", "parameters": {"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]}}},
    {"type": "function", "function": {"name": "read_webpage", "description": "Read URL content", "parameters": {"type": "object", "properties": {"url": {"type": "string"}}, "required": ["url"]}}},
    {"type": "function", "function": {"name": "calculator", "description": "Do math", "parameters": {"type": "object", "properties": {"expression": {"type": "string"}}, "required": ["expression"]}}},
    {"type": "function", "function": {"name": "python_interpreter", "description": "Run Python code", "parameters": {"type": "object", "properties": {"code": {"type": "string"}}, "required": ["code"]}}}
]

TOOL_LABELS = {
    "web_search": "Searching web...",
    "read_webpage": "Reading webpage...",
    "calculator": "Calculating...",
    "python_interpreter": "Running Python..."
}

def process_message(msg):
    messages = [{"role": "system", "content": "You are a helpful AI assistant. Use tools when needed. Be concise."}, {"role": "user", "content": msg}]
    with open(STATUS, "w") as f: f.write("thinking...")

    payload = {"model": "Qwen/Qwen2.5-72B-Instruct", "messages": messages, "tools": TOOLS, "tool_choice": "auto"}
    try:
        resp = requests.post(API_URL, headers=HEADERS, json=payload, timeout=120).json()
        choice = resp["choices"][0]["message"]

        if choice.get("tool_calls"):
            tc = choice["tool_calls"][0]
            fn = tc["function"]["name"]
            args = json.loads(tc["function"]["arguments"])
            label = TOOL_LABELS.get(fn, f"Using {fn}...")
            with open(STATUS, "w") as f: f.write(label)

            if fn == "web_search": tool_out = web_search(args.get("query"))
            elif fn == "read_webpage": tool_out = read_webpage(args.get("url"))
            elif fn == "calculator": tool_out = calc(args.get("expression"))
            elif fn == "python_interpreter": tool_out = py_exec(args.get("code"))
            else: tool_out = "Unknown tool"

            with open(STATUS, "w") as f: f.write("processing...")
            messages.append(choice)
            messages.append({"role": "tool", "name": fn, "content": tool_out, "tool_call_id": tc.get("id", "c1")})
            final = requests.post(API_URL, headers=HEADERS, json={"model": "Qwen/Qwen2.5-72B-Instruct", "messages": messages}, timeout=60).json()
            reply = final["choices"][0]["message"]["content"]
        else:
            reply = choice["content"]

        with open(OUTBOX, "w") as f: f.write(reply)
        with open(STATUS, "w") as f: f.write("done")
        print(f"\n📩 App: {msg}\n✅ Reply: {reply}\n")

    except Exception as e:
        with open(OUTBOX, "w") as f: f.write(f"Error: {e}")
        with open(STATUS, "w") as f: f.write("done")
        print(f"\n❌ Error processing message: {e}\n")

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
                if os.path.exists(STATUS): os.remove(STATUS)
            elif os.path.exists(STATUS):
                with open(STATUS) as f:
                    status = f.read().strip()
            self.send_json({"status": status, "reply": reply})

    def do_POST(self):
        if self.path in ("/chat", "/api/chat"):
            length = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(length).decode())
            msg = data.get("msg", "")
            with open(INBOX, "w") as f: f.write(msg)
            threading.Thread(target=process_message, args=(msg,), daemon=True).start()
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
print(f"Relay on :{port}, HF_TOKEN set: {bool(HF_TOKEN)}")
HTTPServer(("0.0.0.0", port), Handler).serve_forever()
