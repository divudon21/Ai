import os
import json
import io
import sys
import requests
import gradio as gr
from duckduckgo_search import DDGS
from bs4 import BeautifulSoup

# Hugging Face Token Space Settings -> Secrets mein 'HF_TOKEN' naam se save karein
HF_TOKEN = os.environ.get("HF_TOKEN")
API_URL = "https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct/v1/chat/completions"
HEADERS = {"Authorization": f"Bearer {HF_TOKEN}"}

# ==========================================
# 1. CORE TOOLS DEFINITIONS (LobeHub style)
# ==========================================

def web_search(query: str) -> str:
    """Internet par live search karne ke liye."""
    try:
        with DDGS() as ddgs:
            results = list(ddgs.text(query, max_results=3))
            return json.dumps([{"title": r['title'], "snippet": r['body'], "link": r['href']} for r in results])
    except Exception as e:
        return f"Search failed: {str(e)}"

def read_webpage(url: str) -> str:
    """Kisi bhi URL ka text content padhne ke liye."""
    try:
        resp = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
        soup = BeautifulSoup(resp.text, 'html.parser')
        text = ' '.join(soup.stripped_strings)[:3000] # Token limit ke liye truncate
        return text
    except Exception as e:
        return f"Could not read webpage: {str(e)}"

def calculator(expression: str) -> str:
    """Complex maths calculations solve karne ke liye."""
    try:
        # Sanitize input for basic security
        allowed_chars = "0123456789+-*/(). "
        if all(c in allowed_chars for c in expression):
            return str(eval(expression, {"__builtins__": {}}, {}))
        return "Error: Invalid characters in math expression."
    except Exception as e:
        return f"Math error: {str(e)}"

def python_interpreter(code: str) -> str:
    """Python code run karke logic execute karne ke liye (Sandbox)."""
    old_stdout = sys.stdout
    redirected_output = sys.stdout = io.StringIO()
    try:
        # Docker container ke andar safe execution environment
        exec(code, {"__builtins__": __builtins__}, {})
        sys.stdout = old_stdout
        return redirected_output.getvalue() or "Code executed successfully with no output."
    except Exception as e:
        sys.stdout = old_stdout
        return f"Execution Error: {str(e)}"

# ==========================================
# 2. LLM TOOL SCHEMA (JSON Format)
# ==========================================

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "web_search",
            "description": "Use this tool to search the internet for current events, news, or general info.",
            "parameters": {
                "type": "object",
                "properties": {"query": {"type": "string", "description": "The search query"}},
                "required": ["query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "read_webpage",
            "description": "Extract raw text content from a given website URL.",
            "parameters": {
                "type": "object",
                "properties": {"url": {"type": "string", "description": "The full web URL"}},
                "required": ["url"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "calculator",
            "description": "Evaluate mathematical expressions. Input should only contain numbers and basic operators.",
            "parameters": {
                "type": "object",
                "properties": {"expression": {"type": "string", "description": "The math expression, e.g. (55 * 4) + 12"}},
                "required": ["expression"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "python_interpreter",
            "description": "Execute Python code to solve complex logical problems, data manipulation, or algorithms.",
            "parameters": {
                "type": "object",
                "properties": {"code": {"type": "string", "description": "Clean Python code block"}},
                "required": ["code"]
            }
        }
    }
]

def execute_tool(name, args):
    if name == "web_search": return web_search(args.get("query"))
    if name == "read_webpage": return read_webpage(args.get("url"))
    if name == "calculator": return calculator(args.get("expression"))
    if name == "python_interpreter": return python_interpreter(args.get("code"))
    return "Unknown tool"

# ==========================================
# 3. AGENT CORE LOOP
# ==========================================

def run_agent(message, history):
    # Chat history formatting
    messages = [{"role": "system", "content": "You are a helpful AI Agent equipped with advanced tools. Use them whenever necessary to give accurate answers."}]
    for user, bot in history:
        messages.append({"role": "user", "content": user})
        if bot: messages.append({"role": "assistant", "content": bot})
    messages.append({"role": "user", "content": message})

    payload = {
        "model": "Qwen/Qwen2.5-72B-Instruct",
        "messages": messages,
        "tools": TOOLS,
        "tool_choice": "auto"
    }
    
    try:
        response = requests.post(API_URL, headers=HEADERS, json=payload).json()
        choice = response["choices"][0]["message"]
        
        # Check if LLM wants to use a tool
        if choice.get("tool_calls"):
            tool_call = choice["tool_calls"][0]
            func_name = tool_call["function"]["name"]
            func_args = json.loads(tool_call["function"]["arguments"])
            
            # Execute selected tool
            tool_output = execute_tool(func_name, func_args)
            
            # Feed tool result back to LLM
            messages.append(choice)
            messages.append({
                "role": "tool",
                "name": func_name,
                "content": tool_output,
                "tool_call_id": tool_call.get("id", "call_1")
            })
            
            # Final LLM call to generate user response
            final_payload = {"model": "Qwen/Qwen2.5-72B-Instruct", "messages": messages}
            final_response = requests.post(API_URL, headers=HEADERS, json=final_payload).json()
            return final_response["choices"][0]["message"]["content"]
            
        return choice["content"]
    except Exception as e:
        return f"API Error: Kripya check karein ki HF_TOKEN correctly set hai ya nahi. Details: {str(e)}"

# ==========================================
# 4. GRADIO INTERFACE
# ==========================================

demo = gr.ChatInterface(
    fn=run_agent,
    title="\U0001f4e6 LobeHub-Style Docker Agent",
    description="Docker container backend ke sath chalne wala Agent: Search, Browser, Math aur Python Interpreter sab free!",
    theme="soft"
)

if __name__ == "__main__":
    demo.launch()
