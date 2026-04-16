# CLAUDE.md — EAFIT Challenge: Verifiable AI Agents with Hologram

## Progress

### Step 1 — AI Chatbot
- [x] 1.1. Fork the repository
- [x] 1.2. Clone the repository
- [x] 1.3. Explore the project structure
- [x] 1.4. Configure environment variables (`.env` created, Anthropic configured)
- [x] 1.5. Customize Agent Pack (auth flow, MCP GitHub, bilingual menu strings)
- [x] 1.6. Add documents for RAG (bilingual docs in `docs/`)
- [x] 1.7. Start the chatbot with Docker Compose (`veranalabs/vs-agent:latest`, did:webvh)
- [x] 1.8. Expose with ngrok (`https://queasier-jaimie-gravimetrically.ngrok-free.dev` → port 3001)
- [x] 1.9. Get invitation credentials (`http://localhost:3002/v1/invitation` and `http://localhost:3002/v1/qr`)
- [x] 1.10. Connect with Hologram and test (QR at `http://localhost:3002/v1/qr`)
- [x] 1.11. Add Verana blockchain verification (`common/common.sh`, `scripts/setup.sh`, Service credential)
- [x] 1.12. Add GitHub MCP integration (user-controlled token via in-chat config)
- [x] 1.13. Commit changes

### Step 2 — Kubernetes
- [ ] Not started

### Step 3 — Web Application
- [ ] Not started

---

## Project Overview

This is the **Verana Foundation × NODO EAFIT** challenge repository. The goal is to build a platform for creating **Persona AI Agents** — verifiable AI bots accessible through [Hologram Messaging](https://hologram.zone), backed by decentralized identity (DIDs + W3C Verifiable Credentials).

The challenge has 3 deliverables:

| Step | Deliverable | Weight |
|------|------------|--------|
| Step 1 | Custom AI chatbot running locally via Docker Compose, accessible from Hologram | 20% |
| Step 2 | Chatbot deployed to Kubernetes cluster | 15% |
| Step 3 | Full-stack web app ("Persona AI Agent Creator") | 40% + 10% MCP |

---

## Repository Structure

```
eafit-challenge/
├── ai-chatbot/                          # Step 1 — chatbot with Verana blockchain verification
│   ├── agent-packs/
│   │   └── my-agent/
│   │       └── agent-pack.yaml          # Bot personality, prompts, RAG, auth flow, MCP config
│   ├── common/
│   │   └── common.sh                    # Verana helpers: Trust Registry, VT, veranad CLI, credentials
│   ├── docs/                            # RAG knowledge base documents
│   │   ├── eafit-university-en.txt      # EAFIT info in English
│   │   └── eafit-universidad-es.txt     # EAFIT info in Spanish
│   ├── scripts/
│   │   ├── setup.sh                     # Verana blockchain setup (veranad account + Service credential)
│   │   └── start.sh                     # Docker Compose wrapper with env validation
│   ├── docker-compose.yml               # 7 services: chatbot, vs-agent, redis, postgres, artemis, ollama, adminer
│   ├── .env.example                     # All env vars documented (LLM + Verana + MCP)
│   ├── .gitignore                       # Ignores .env, ids.env, and data/
│   └── Dockerfile                       # Multi-stage: clones upstream at build time
├── k8s/                                 # Step 2 — Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   └── deploy.sh
├── web-app/                             # Step 3 — Persona AI Agent Creator (to be built)
│   ├── frontend/                        # React / Next.js
│   ├── backend/                         # Node.js / Express / NestJS
│   └── Dockerfile
└── .github/workflows/                   # CI/CD (bonus Step 3.7)
    └── deploy.yml
```

> `web-app/` does not exist yet — to be created in Step 3.

---

## Tech Stack

### Step 1 — AI Chatbot
- Runtime: **Node.js v23-alpine** (upstream), **pnpm**
- Config: `agent-pack.yaml` (YAML, supports `${ENV_VAR}` interpolation at runtime)
- LLM providers: OpenAI (`gpt-4o-mini`), Anthropic (`claude-haiku-4-5-20251001`), Ollama (`llama3`)
- Infrastructure: Docker Compose (7 services):
  - `chatbot:3000` — AI agent API (built from local Dockerfile)
  - `vs-agent:3001/3002` — DIDComm ↔ Hologram + Verana VT endpoints (`veranalabs/vs-agent:latest`)
  - `redis` — memory + vector store (`redis/redis-stack-server:latest`)
  - `postgres:5432` — session storage (`postgres:alpine3.19`)
  - `artemis` — message broker (`apache/activemq-artemis:2.31.2`)
  - `ollama-svr:11435` — local LLM (`ollama/ollama:latest`)
  - `adminer:8080` — DB UI, dev-only (start with `--profile dev`)
- Verana integration:
  - `veranalabs/vs-agent:latest` with `did:webvh` DID (requires `NGROK_DOMAIN`)
  - `common/common.sh` — Verana Trust Registry, veranad CLI, credential issuance/linking helpers
  - `scripts/setup.sh` — registers agent on testnet, funds account via faucet, links Service credential
  - `CREDENTIAL_DEFINITION_ID` — AnonCreds credDef for Avatar-based user authentication
- MCP: GitHub integration (`https://api.githubcopilot.com/mcp/`) with per-user token config
- Dockerfile: multi-stage, clones upstream at build time
- Volumes: `./agent-packs` and `./docs` bind-mounted into container
- Tunnel for local dev: **ngrok** (exposes port 3001; domain set in `NGROK_DOMAIN`)
- RAG docs: `docs/eafit-university-en.txt` and `docs/eafit-universidad-es.txt` (bilingual knowledge base)

### Step 2 — Kubernetes
- Tool: `kubectl`
- Namespace format: `eafit-YOURNAME`
- Public domain: `myagent.yourname.eafit.testnet.verana.network`
- Manifests: standard k8s YAML (Deployment, Service, Ingress, ConfigMap, Secret)

### Step 3 — Web Application
- Frontend: React / Next.js (or Vue.js)
- Backend: Node.js / Express / NestJS
- Database: SQLite or PostgreSQL
- Auth: username/password + optional Google OAuth
- Deployment: Docker + Kubernetes + GitHub Actions CI/CD
- MCP: at least 2 functional MCP servers integrated into agent config

---

## Key Concepts

### VS Agent
The `vs-agent` service handles DIDComm communication between the chatbot and Hologram. It runs on port 3001 and must be publicly accessible (via ngrok in dev, or Ingress in k8s).

### Agent Pack
A declarative YAML configuration that defines a bot's personality, prompts, RAG settings, memory, and integrations. Located at `ai-chatbot/agent-packs/my-agent/agent-pack.yaml`.

### MCP (Model Context Protocol)
Allows the LLM to call external tools during a conversation. Implement ≥2 servers. Useful examples:
- Google Calendar — appointment scheduling
- X (Twitter) — social media posting
- Gmail — email sending
- Google Sheets — data management
- Wikipedia — general knowledge lookup
- Weather API — outdoor service planning

### Persona AI Agent
An agent that represents a person and acts on their behalf (e.g., a plumber's bot that schedules appointments). Configured via:
- **Persona Attributes**: name, profession, description, photo
- **Service Attributes**: service name, description, category
- **Prompt**: personality and behavior instructions
- **MCP Services**: external tool connections
- **RAG**: knowledge base documents

---

## Development Commands

### Step 1 — Local Chatbot

```bash
cd ai-chatbot
cp .env.example .env              # configure LLM provider and API key
# edit .env: set LLM_PROVIDER, OPENAI_API_KEY (or ANTHROPIC/OLLAMA)
docker compose up --build         # first run takes a few minutes (clones upstream)
# in a separate terminal:
ngrok http 3001                   # copy the https URL
# update .env: AGENT_ENDPOINT=https://xxx.ngrok-free.app
docker compose down && docker compose up --build
curl http://localhost:3001/       # get QR code / invitation URL for Hologram

# dev extras:
docker compose --profile dev up   # also starts adminer at localhost:8080
docker compose ps                 # verify all services are Running
docker compose logs chatbot -f    # tail chatbot logs
```

### Step 2 — Kubernetes Deploy (local with Docker Desktop)

```bash
# Enable Kubernetes in Docker Desktop → Settings → Kubernetes
kubectl get nodes                          # verify local cluster
kubectl apply -f k8s/
kubectl get pods -n eafit-YOURNAME
kubectl rollout status deployment -n eafit-YOURNAME

# On Verana cluster (when credentials arrive):
export KUBECONFIG=~/path/to/kubeconfig.yaml
cd k8s && ./deploy.sh
```

### Step 3 — Web App (to be implemented)

```bash
cd web-app
pnpm install
pnpm dev          # frontend + backend in dev mode
pnpm build
docker build -t my-persona-agent-creator .
```

---

## Environment Variables

Copy `ai-chatbot/.env.example` to `ai-chatbot/.env`. Critical variables:

```env
LLM_PROVIDER=openai          # or: ollama, anthropic
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
AGENT_ENDPOINT=https://xxx.ngrok-free.app   # set after running ngrok
AGENT_PACK_PATH=./agent-packs/my-agent
REDIS_URL=redis://redis:6379
POSTGRES_HOST=postgres
POSTGRES_USER=eafit
POSTGRES_PASSWORD=eafit2025
POSTGRES_DB_NAME=chatbot-agent
```

---

## Coding Conventions

- Language: **TypeScript** (strict mode preferred)
- Package manager: **pnpm**
- Node version: **v20+**
- Secrets: never commit `.env` files or API keys; use `.env.example` templates
- k8s secrets: base64-encode values (`echo -n "value" | base64`)
- Docker: multi-stage builds to minimize image size
- Commit messages: use conventional commits (`feat:`, `fix:`, `doc:`, `chore:`)

---

## External Resources

- Upstream chatbot repo: [2060-io/hologram-generic-ai-agent-vs](https://github.com/2060-io/hologram-generic-ai-agent-vs)
- VS Agent framework: [verana-labs/vs-agent](https://github.com/verana-labs/vs-agent)
- Verana demos: [verana-labs/verana-demos](https://github.com/verana-labs/verana-demos)
- Verana docs: https://docs.verana.io
- Hologram app: https://hologram.zone
- Support: Verana Discord `#eafit-challenge` — https://discord.com/invite/edjaFn252q

---

## Grading Summary

| Criterion | Weight |
|-----------|--------|
| Step 1 — Working chatbot | 20% |
| Step 2 — k8s deployment | 15% |
| Step 3 — Web application | 40% |
| MCP Integrations (≥2) | 10% |
| Code quality | 5% |
| Documentation | 5% |
| Creativity / UX | 5% |

**Bonus**: +5% per extra MCP, +5% RAG with real docs, +5% UI/UX, +5% tests, +5% video demo, **+10% CI/CD auto-deploy**.
