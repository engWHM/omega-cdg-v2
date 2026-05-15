#!/bin/bash
set -e

echo "🚀 Deploying OMEGA CYBER DEFENSE GRID v2.0 ..."

mkdir -p api collector brain correlation soar dashboard

# docker-compose
cat > docker-compose.yml << 'EOF'
version: "3.9"
services:
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  api:
    build: ./api
    ports: ["8000:8000"]
    depends_on: [redis]

  collector:
    build: ./collector
    depends_on: [api]

  brain:
    build: ./brain
    depends_on: [redis]

  correlation:
    build: ./correlation
    depends_on: [brain]

  soar:
    build: ./soar
    depends_on: [correlation]

  dashboard:
    build: ./dashboard
    ports: ["3000:3000"]
EOF

# باقي الملفات (مبسطة)
cat > api/Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
RUN pip install fastapi uvicorn redis pydantic
COPY main.py .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

cat > api/main.py << 'EOF'
from fastapi import FastAPI
from pydantic import BaseModel
from redis import Redis
import json, uuid
from datetime import datetime
app = FastAPI(title="OMEGA XDR")
r = Redis(host="redis", port=6379, decode_responses=True)

class Event(BaseModel):
    source: str
    event_type: str
    hostname: str
    data: dict

@app.post("/ingest")
async def ingest(event: Event):
    print(f"[API] Event received from {event.hostname}")
    return {"status": "ok"}
EOF

cat > collector/Dockerfile << 'EOF'
FROM python:3.12-slim
RUN pip install psutil requests
COPY agent.py .
CMD ["python", "agent.py"]
EOF

cat > collector/agent.py << 'EOF'
import psutil, requests, time, random
while True:
    event = {"source": "agent", "event_type": "telemetry", "hostname": f"endpoint-{random.randint(100,999)}", "data": {"cpu": psutil.cpu_percent()}}
    try:
        requests.post("http://api:8000/ingest", json=event)
        print(f"[Agent] Sent from {event['hostname']}")
    except: pass
    time.sleep(3)
EOF

# Dashboard
cat > dashboard/Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 3000
EOF

cat > dashboard/index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>OMEGA CDG v2</title>
<style>body{background:#000;color:#0f0;font-family:monospace;text-align:center;padding:50px;}</style>
</head><body>
<h1>🛡️ OMEGA CYBER DEFENSE GRID v2.0</h1>
<p>✅ System is Running</p>
</body></html>
EOF

echo "🚀 Building OMEGA..."
docker compose up -d --build
echo "✅ Done! Open port 3000"
