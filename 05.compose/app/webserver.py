# 3 장의 webserver.py 에 DB 조회를 하나 더 붙인 것.
from datetime import datetime
import os, socket
import pymysql
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import uvicorn

app = FastAPI()
DB = dict(host=os.getenv("DB_HOST", "db"), user=os.getenv("DB_USER", "user"),
          password=os.getenv("DB_PASSWORD", "password123"),
          database=os.getenv("DB_NAME", "skala"))


@app.get("/healthz")
def healthz():
    return {"status": "ok", "host": socket.gethostname()}


@app.get("/", response_class=HTMLResponse)
def index():
    with pymysql.connect(**DB) as conn, conn.cursor() as cur:
        cur.execute("SELECT id, username FROM users")
        rows = cur.fetchall()
    items = "".join(f"<li>{i} · {u}</li>" for i, u in rows)
    return f"""<!doctype html><meta charset="utf-8">
<body style="font-family:sans-serif;text-align:center;padding-top:60px">
  <h1>SKALA 컨테이너 과정</h1>
  <ul style="display:inline-block;text-align:left">{items}</ul>
  <p>{datetime.now():%Y-%m-%d %H:%M:%S} · served by {socket.gethostname()}</p>
</body>"""


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
