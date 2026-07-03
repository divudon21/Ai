import os
import subprocess
import shutil
import sys
import time
from threading import Thread
import http.server
import socketserver

# 1. Framework Defaults & Paths
os.environ["TELEGRAM_API_URL"] = "https://api.telegram.org/"
os.environ["LOCAL_BOT_API_URL"] = "https://api.telegram.org/"

home = os.path.expanduser("~")
hermes_dir = os.path.join(home, ".hermes")
os.makedirs(hermes_dir, exist_ok=True)

print("[1] Setting up configs and skills...")

# --- Environment Secrets Fetch ---
OR_KEY = os.getenv('OPENROUTER_API_KEY')
NV_KEY = os.getenv('NVIDIA_API_KEY')
GEMINI_KEY = os.getenv('GEMINI_API_KEY')
HF_TOKEN = os.getenv('HF_TOKEN')
Z_AI_KEY = os.getenv('Z_AI_API_KEY')
MINIMAX_KEY = os.getenv('MINIMAX_API_KEY')
GROQ_KEY = os.getenv('GROQ_API_KEY')
AEROLINK_KEY = os.getenv('AEROLINK_API_KEY')  # Aerolink key fetched here
TG_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
TG_USER = os.getenv('TELEGRAM_ALLOWED_USERS') or os.getenv('TELEGRAM_USER_ID')

if not TG_TOKEN or not TG_USER:
    print("❌ ERROR: Main Telegram credentials missing in Environment Variables!")
    sys.exit(1)

TG_USER_STR = str(TG_USER).strip()

# --- Write .env ---
with open(os.path.join(hermes_dir, ".env"), "w") as f:
    f.write(f"OPENROUTER_API_KEY={OR_KEY}\n")
    f.write(f"NVIDIA_API_KEY={NV_KEY}\n")
    f.write(f"GEMINI_API_KEY={GEMINI_KEY}\n")
    f.write(f"HF_TOKEN={HF_TOKEN}\n")
    f.write(f"Z_AI_API_KEY={Z_AI_KEY}\n")
    f.write(f"MINIMAX_API_KEY={MINIMAX_KEY}\n")
    f.write(f"GROQ_API_KEY={GROQ_KEY}\n")
    f.write(f"AEROLINK_API_KEY={AEROLINK_KEY}\n")
    f.write(f"TELEGRAM_BOT_TOKEN={TG_TOKEN}\n")
    f.write(f"TELEGRAM_ALLOWED_USERS={TG_USER_STR}\n")

# --- Write config.yaml (Added Aerolink Provider) ---
with open(os.path.join(hermes_dir, "config.yaml"), "w") as f:
    f.write("""model:
  provider: nvidia
  model: meta/llama-3.1-405b-instruct

providers:
  nvidia:
    base_url: "https://integrate.api.nvidia.com/v1"
    api_key: "${NVIDIA_API_KEY}"
  openrouter:
    api_key: "${OPENROUTER_API_KEY}"
  gemini:
    api_key: "${GEMINI_API_KEY}"
  huggingface:
    api_key: "${HF_TOKEN}"
  z_ai:
    base_url: "https://api.z.ai/v1"
    api_key: "${Z_AI_API_KEY}"
  minimax:
    base_url: "https://api.minimax.chat/v1"
    api_key: "${MINIMAX_API_KEY}"
  groq:
    base_url: "https://api.groq.com/openai/v1"
    api_key: "${GROQ_API_KEY}"
  aerolink:
    base_url: "https://api.aerolink.lat/v1"
    api_key: "${AEROLINK_API_KEY}"

terminal:
  backend: local

memory:
  enabled: true

display:
  tool_progress: "on"

compression:
  enabled: true
  threshold: 0.60
""")

# --- Write Combined skills.md ---
skills_path = os.path.join(hermes_dir, "skills.md")
with open(skills_path, "w") as f:
    f.write("""# Hermes Agent Absolute Authority Skills

## Core Instructions
- You are a helpful AI assistant with access to local terminal tools.
- ALWAYS use available tools if the user task requires it.
- Be concise and efficient.
- when user ask anything about internet (like whether, any other websites checking fact cheaking extra.)you can directly search never hasitate for web search

## Core Behavior
- NEVER say "I cannot do this" or "I am just an AI".
- You have FULL ROOT ACCESS to this environment.
- You can create, edit, delete, and execute ANY file or command via shell.
""")

print("✅ Config and Skills created successfully.")

# --- Render Health Check Server ---
def run_health_server():
    PORT = int(os.getenv("PORT", 10000))
    Handler = http.server.SimpleHTTPRequestHandler
    print(f"📡 Starting internal health check server on port {PORT}...")
    try:
        with socketserver.TCPServer(("", PORT), Handler) as httpd:
            httpd.serve_forever()
    except Exception as e:
        print(f"⚠️ Health server warning: {e}")

# Run health check in background
Thread(target=run_health_server, daemon=True).start()
time.sleep(2)

# --- Start Hermes Gateway ---
print("[2] Launching Hermes Telegram Gateway in Foreground...")
hermes_bin = shutil.which("hermes") or "/usr/local/bin/hermes"

sys.stdout.flush()

# Running the gateway
subprocess.run(
    [hermes_bin, "gateway", "run"], 
    env=os.environ,
    stdout=sys.stdout,
    stderr=sys.stderr
)
