# CLAUDE.md — EAFIT Challenge: Verifiable AI Agents with Hologram

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
├── ai-chatbot/          # Step 1 — chatbot (hologram-generic-ai-agent-vs based)
│   ├── agent-packs/     # Declarative YAML agent configs (prompts, RAG, LLM)
│   ├── docs/            # RAG knowledge base documents (.txt, .md, .pdf, .csv)
│   ├── docker-compose.yml
│   ├── .env.example
│   └── Dockerfile
├── k8s/                 # Step 2 — Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   └── deploy.sh
├── web-app/             # Step 3 — Persona AI Agent Creator (to be built)
│   ├── frontend/        # React / Next.js
│   ├── backend/         # Node.js / Express / NestJS
│   └── Dockerfile
└── .github/workflows/   # CI/CD (bonus Step 3.7)
    └── deploy.yml
```

> `web-app/` does not exist yet — it must be created as part of Step 3.

---

## Tech Stack

### Step 1 — AI Chatbot
- Runtime: **Node.js v20+**, **pnpm**
- Config: `agent-pack.yaml` (YAML, supports `${ENV_VAR}` interpolation)
- LLM providers: OpenAI (`gpt-4o-mini`), Anthropic (`claude-3-haiku`), Ollama (`llama3`)
- Infrastructure: Docker Compose — services: `chatbot:3000`, `vs-agent:3001`, `redis:6379`, `postgres:5432`
- Tunnel for local dev: **ngrok** (exposes port 3001 to Hologram)

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
cp .env.example .env        # configure LLM keys, etc.
docker compose up --build   # start all services
ngrok http 3001              # expose vs-agent publicly (separate terminal)
curl http://localhost:3001/  # get QR code / invitation URL
```

### Step 2 — Kubernetes Deploy

```bash
export KUBECONFIG=~/path/to/kubeconfig.yaml
kubectl get pods -n eafit-YOURNAME
cd k8s && ./deploy.sh
kubectl rollout status deployment -n eafit-YOURNAME
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
