# Chatbot Deployment Guide

Local deployment of the EAFIT AI Chatbot using Docker Compose, with Verana blockchain verification and GitHub MCP integration.

---

## Prerequisites

- Docker Desktop
- ngrok account with authtoken configured (`ngrok config add-authtoken YOUR_TOKEN`)
- Hologram Messaging app installed on your phone
- `curl` and `jq` installed (for the Verana setup script)

---

## Step 1 — Configure environment variables

```bash
cd ai-chatbot
cp .env.example .env
```

Edit `.env` and set at minimum:

```env
# LLM provider — choose one
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-haiku-4-5-20251001

# ngrok domain (fill in after step 4)
NGROK_DOMAIN=your-subdomain.ngrok-free.app
AGENT_ENDPOINT=https://your-subdomain.ngrok-free.app
AGENT_ENDPOINTS=https://your-subdomain.ngrok-free.app
```

> For OpenAI, uncomment the corresponding block. For Ollama (local/free), uncomment the Ollama block — no API key required.

---

## Step 2 — Start ngrok

In a separate terminal, start the tunnel **before** bringing up the stack — the VS Agent needs the public URL at startup to configure its `did:webvh` DID:

```bash
ngrok http 3001
```

Copy the `https://` URL (e.g. `https://abc123.ngrok-free.app`).

Update `.env` with the three ngrok variables:

```env
NGROK_DOMAIN=abc123.ngrok-free.app
AGENT_ENDPOINT=https://abc123.ngrok-free.app
AGENT_ENDPOINTS=https://abc123.ngrok-free.app
```

---

## Step 3 — Build and start services

```bash
./scripts/start.sh --build -d
```

Or directly:

```bash
docker compose up --build -d
```

This starts 7 services:

| Service | External port | Description |
|---------|--------------|-------------|
| `hologram-generic-ai-agent` | 3000 | AI chatbot API (Swagger UI at `/api`) |
| `vs-agent` | 3001 | DIDComm inbound — exposed via ngrok |
| `vs-agent` admin | 3002 | QR code / invitation / Verana admin API |
| `redis` | 6379 | Memory + vector store |
| `postgres` | 5432 | Session storage |
| `artemis` | 8161 | JMS message broker web console |
| `ollama-docker` | 11435 | Local LLM (maps to internal 11434) |

Verify all are running:

```bash
docker compose ps
```

---

## Step 4 — (Ollama only) Pull models

Skip this step if using Anthropic or OpenAI. On first run with Ollama, pull the models:

```bash
docker exec ollama-docker ollama pull llama3
docker exec ollama-docker ollama pull nomic-embed-text
```

> Models are persisted in the `ollama_data` volume — this only needs to be done once.

---

## Step 5 — Register on the Verana blockchain

This step links a **Service credential** to the agent's `did:webvh` DID document, proving the agent is a legitimate service in the Verana ecosystem. Only needs to be done once (or when the ngrok URL changes).

```bash
./scripts/setup.sh
```

The script will:
1. Verify the VS Agent is running and retrieve its `did:webvh` DID
2. Reuse (or start) the ngrok tunnel
3. Create a `veranad` CLI account and wait for you to fund it via the testnet faucet
4. Request a **Service credential** from the EAFIT organization and link it on the DID document

**Funding the account:** The script will print a blockchain address and faucet URL. Open the faucet URL in Hologram and send tokens to the displayed address, then press Enter to continue.

```
  ┌─────────────────────────────────────────────────────────────┐
  │  Fund this account via the faucet:                          │
  │  Address: vna1abc...                                        │
  │  Faucet:  https://faucet-vs.testnet.verana.network/invitation│
  └─────────────────────────────────────────────────────────────┘
  Press Enter once the account is funded...
```

After completion, resource IDs are saved to `ids.env`.

---

## Step 6 — Verify the agent

```bash
curl http://localhost:3002/v1/agent
```

Expected response (with `did:webvh` — confirms Verana mode is active):
```json
{
  "label": "EAFIT AI Assistant",
  "publicDid": "did:webvh:Qm...:your-domain.ngrok-free.app",
  "isInitialized": true
}
```

---

## Step 7 — Connect via Hologram

Get the QR code:

```
http://localhost:3002/v1/qr
```

Or the raw invitation URL:

```bash
curl http://localhost:3002/v1/invitation
```

1. Open **Hologram Messaging** on your phone
2. Scan the QR code at `http://localhost:3002/v1/qr`
3. The bot sends its greeting — start chatting

**In-chat features available after Verana setup:**
- **Authenticate** menu item — users present their Avatar credential
- **MCP Server Config** — users enter their GitHub Personal Access Token to enable GitHub integration

---

## Port reference

| URL | What it is |
|-----|-----------|
| `http://localhost:3000/api` | Chatbot Swagger UI |
| `http://localhost:3001/` | DIDComm inbound (used by Hologram via ngrok — not for browser) |
| `http://localhost:3002/v1/agent` | VS Agent status + DID |
| `http://localhost:3002/v1/invitation` | Hologram deep link (JSON) |
| `http://localhost:3002/v1/qr` | QR code image (PNG) |
| `http://localhost:8161` | Artemis broker web console |

---

## When to rebuild vs. restart

| What changed | Command |
|---|---|
| `Dockerfile` or Node dependencies | `docker compose up --build -d` |
| `.env` variables | `docker compose down && docker compose up -d` |
| `agent-pack.yaml` (prompt, persona, flows) | `docker compose restart chatbot` |
| `docs/` (RAG knowledge base) | `docker compose restart chatbot` |
| ngrok URL changed | Update `.env` → `docker compose down && docker compose up -d` → re-run `./scripts/setup.sh` |

> `agent-packs/` and `docs/` are bind-mounted — changes take effect on restart without a rebuild.

---

## Customization

| File | What to change |
|------|---------------|
| `agent-packs/my-agent/agent-pack.yaml` | Bot name, greeting, system prompt, auth flow, MCP servers |
| `docs/` | Add `.txt`, `.md`, or `.pdf` files for the RAG knowledge base |
| `.env` | LLM provider, model, Verana service metadata, MCP keys |

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

# Stop and wipe volumes (full reset)
docker compose down -v

# Re-run Verana setup (e.g. after ngrok URL change)
./scripts/setup.sh
```
