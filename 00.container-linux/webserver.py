# 컨테이너 안에서 도는 아주 작은 웹서버.  FastAPI + uvicorn, 8080 포트.
from datetime import datetime
import os, socket
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import uvicorn

app = FastAPI()

PAGE = """<!doctype html><html><head><meta charset="utf-8"><title>Welcome Page</title>
<style>
 body {{ font-family: sans-serif; background:#f5f6f8; margin:0; padding:80px 0; }}
 .card {{ background:#fff; width:460px; margin:0 auto; padding:48px 32px;
          border-radius:8px; text-align:center; box-shadow:0 1px 4px rgba(0,0,0,.08); }}
 h1 {{ color:#1a73e8; margin:0 0 24px; }}
 p  {{ color:#444; margin:8px 0; }}
 .btn {{ display:inline-block; margin-top:24px; padding:12px 28px; border-radius:6px;
         background:#1a73e8; color:#fff; text-decoration:none; }}
 .host {{ color:#888; font-size:13px; margin-top:20px; }}
</style></head><body>
<div class="card">
  <h1>Welcome to Our Service</h1>
  <p>Thank you for visiting our website!</p>
  <p>Request received at: {now}</p>
  <a class="btn" href="/logout">Logout</a>
  <p class="host">served by {host}</p>
</div></body></html>"""


@app.get("/", response_class=HTMLResponse)
@app.get("/login", response_class=HTMLResponse)
def login():
    return PAGE.format(now=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                       host=socket.gethostname())


@app.get("/healthz")
def healthz():
    return {"status": "ok", "host": socket.gethostname(), "pid": os.getpid()}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
