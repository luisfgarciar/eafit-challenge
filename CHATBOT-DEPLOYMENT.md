# Chatbot Deployment Guide

Local deployment of the EAFIT AI Chatbot using Docker Compose, based on [hologram-generic-ai-agent-vs v1.9.0](https://github.com/2060-io/hologram-generic-ai-agent-vs).

---

## Prerequisites

- Docker Desktop (with Kubernetes disabled is fine)
- ngrok account with authtoken configured (`ngrok config add-authtoken YOUR_TOKEN`)
- Hologram Messaging app installed on your phone

---

## Step 1 — Configure environment variables

```bash
cd ai-chatbot
cp .env.example .env
```

Edit `.env` and set at minimum:

```env
# LLM provider — choose one
LLM_PROVIDER=ollama
OLLAMA_ENDPOINT=http://ollama-svr:11434
OLLAMA_MODEL=llama3
OLLAMA_EMBEDDING_MODEL=nomic-embed-text

# Stats broker (required — Artemis runs in Docker)
VS_AGENT_STATS_ENABLED=true
VS_AGENT_STATS_HOST=artemis
VS_AGENT_STATS_PORT=61616
VS_AGENT_STATS_QUEUE=stats-queue
VS_AGENT_STATS_USER=artemis
VS_AGENT_STATS_PASSWORD=artemis

# Leave AGENT_ENDPOINT blank for now — fill in after ngrok is running
AGENT_ENDPOINT=https://your-subdomain.ngrok-free.app
AGENT_ENDPOINTS=https://your-subdomain.ngrok-free.app
```

> For OpenAI or Anthropic instead of Ollama, uncomment the corresponding block in `.env` and provide the API key.

---

## Step 2 — Build and start services

```bash
docker compose up --build -d
```

This starts 6 services:

| Service | External port | Description |
|---------|--------------|-------------|
| `hologram-generic-ai-agent` | 3000 | AI chatbot API (Swagger UI at `/api`) |
| `vs-agent` | 3001 | DIDComm inbound — expose via ngrok |
| `vs-agent` admin | 3002 | QR code / invitation API |
| `redis` | 6379 | Memory + vector store |
| `postgres` | 5432 | Session storage |
| `artemis` | 8161 | JMS message broker web console |
| `ollama-docker` | 11435 | Local LLM (maps to internal 11434) |

Verify all are running:

```bash
docker compose ps
```

---

## Step 3 — Pull Ollama models

On first run the models are not yet downloaded. Pull them while the stack is running:

```bash
docker exec ollama-docker ollama pull llama3
docker exec ollama-docker ollama pull nomic-embed-text
```

> `llama3` is used for chat. `nomic-embed-text` is used for RAG document embeddings.  
> Models are persisted in the `ollama_data` Docker volume and survive restarts. This only needs to be done once.

---

## Step 4 — Expose vs-agent with ngrok

In a separate terminal:

```bash
ngrok http 3001
```

Copy the `https://` URL shown (e.g. `https://abc123.ngrok-free.app`).

---

## Step 5 — Update AGENT_ENDPOINT and restart

Edit `ai-chatbot/.env` and set both variables to the ngrok URL:

```env
AGENT_ENDPOINT=https://abc123.ngrok-free.app
AGENT_ENDPOINTS=https://abc123.ngrok-free.app
```

> `AGENT_ENDPOINTS` (plural) is required by vs-agent v1.5.5+. `AGENT_ENDPOINT` is kept for backwards compatibility but is deprecated.

Restart only the affected services (no rebuild needed):

```bash
docker compose restart vs-agent chatbot
```

---

## Step 6 — Verify the agent is initialized

```bash
curl http://localhost:3002/v1/agent
```

Expected response:
```json
{"label":"Test VS Agent","endpoints":["https://abc123.ngrok-free.app"],"isInitialized":true}
```

---

## Step 7 — Get the QR code / invitation URL

Open your browser and navigate to:

```
http://localhost:3002/v1/qr
```

This renders the QR code PNG image directly — scan it with Hologram.

> **Do not use `http://localhost:3001/`** — that port is the DIDComm inbound transport used only by Hologram internally via the ngrok tunnel. It has no browser-accessible routes and will return `Cannot GET /`.

Alternatively, get the raw invitation URL as JSON:

```bash
curl http://localhost:3002/v1/invitation
```

---

## Step 8 — Connect via Hologram

1. Open **Hologram Messaging** on your phone
2. Open `http://localhost:3002/v1/qr` in your browser and scan the QR code
3. The bot sends its greeting message — start chatting

---

## Port reference

| URL | What it is |
|-----|-----------|
| `http://localhost:3000/api` | Chatbot Swagger UI (REST API docs) |
| `http://localhost:3001/` | DIDComm inbound (used by Hologram via ngrok — not for browser) |
| `http://localhost:3002/v1/agent` | vs-agent status + endpoints |
| `http://localhost:3002/v1/invitation` | Hologram deep link (JSON) |
| `http://localhost:3002/v1/qr` | QR code image (PNG) |
| `http://localhost:8161` | Artemis broker web console |

---

## Customization

| File | What to change |
|------|---------------|
| `agent-packs/my-agent/agent-pack.yaml` | Bot name, greeting, system prompt, languages |
| `docs/` | Add `.txt`, `.md`, or `.pdf` files for the RAG knowledge base |
| `.env` | LLM provider, model, ports |

After changing `agent-pack.yaml` or `docs/`, restart without rebuild:

```bash
docker compose restart chatbot
```

After changing `Dockerfile` or `.env` LLM settings, rebuild:

```bash
docker compose up --build -d
```

---

## Useful commands

```bash
# View chatbot logs live
docker compose logs chatbot -f

# View vs-agent logs
docker compose logs vs-agent -f

# Check all service statuses
docker compose ps

# Stop everything
docker compose down

# Stop and wipe volumes (full reset — re-pull Ollama models after this)
docker compose down -v
```
