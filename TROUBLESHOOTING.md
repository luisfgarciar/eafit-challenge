# Troubleshooting — Local AI Chatbot Deployment

> **Note:** This guide was written based on a deployment on a **MacBook (Apple Silicon / arm64)**. Some issues below are specific to running amd64 Docker images on arm64 hardware via Rosetta emulation.

---

## Issue 1 — Chatbot crash-loops on startup: `StatProducerService not available in CoreModule`

**Error:**
```
UnknownDependenciesException: Nest can't resolve dependencies of the CoreService
(..., ?, ...). StatProducerService at index [4] is not available in the CoreModule context.
```

**Root cause:**  
The upstream repository's `HEAD` (and tags `v1.9.1`, `v1.10.0`) contain a bug where `StatProducerService` is injected into `CoreService` but not registered in `CoreModule`. The service is only registered when `VS_AGENT_STATS_ENABLED=true` via `EventsModule.register()` in `AppModule`.

**Fix:**  
1. Pin the Dockerfile to `v1.9.0`:
   ```dockerfile
   RUN git clone --depth 1 --branch v1.9.0 https://github.com/2060-io/hologram-generic-ai-agent-vs.git .
   ```
2. Add the following environment variables to `.env` and `docker-compose.yml`:
   ```env
   VS_AGENT_STATS_ENABLED=true
   VS_AGENT_STATS_HOST=artemis
   VS_AGENT_STATS_PORT=61616
   VS_AGENT_STATS_QUEUE=stats-queue
   VS_AGENT_STATS_USER=artemis
   VS_AGENT_STATS_PASSWORD=artemis
   ```

---

## Issue 2 — RAG indexing fails with 401: `You didn't provide an API key`

**Error:**
```
[LangchainRagService] [RAG] Error indexing chunk "eafit-university-en.txt":
401 You didn't provide an API key...
```

**Root cause:**  
`langchain-rag.service.ts` in v1.9.0 hardcodes `OpenAIEmbeddings` regardless of `LLM_PROVIDER`. There is no built-in switch for Ollama embeddings.

**Fix:**  
Patch `src/rag/langchain-rag.service.ts` at build time in the Dockerfile to make embeddings provider-aware. The patch:
- Adds `import { OllamaEmbeddings } from '@langchain/ollama'`
- Reads `process.env.LLM_PROVIDER` at runtime
- Uses `OllamaEmbeddings` when `LLM_PROVIDER=ollama`, falls back to `OpenAIEmbeddings` otherwise

Add to `.env`:
```env
OLLAMA_EMBEDDING_MODEL=nomic-embed-text
```

Add to `docker-compose.yml` under chatbot environment:
```yaml
OLLAMA_EMBEDDING_MODEL: ${OLLAMA_EMBEDDING_MODEL:-nomic-embed-text}
```

---

## Issue 3 — Ollama 404 on `/api/embed`: `model "nomic-embed-text" not found`

**Error (in Ollama logs):**
```
404 | POST /api/embed
[LangchainRagService] model "nomic-embed-text" not found, try pulling it first
```

**Root cause:**  
The Ollama container starts without any pre-downloaded models. Models must be pulled manually after first startup.

**Fix:**  
After `docker compose up`, pull the required models:
```bash
docker exec ollama-docker ollama pull nomic-embed-text
docker exec ollama-docker ollama pull llama3
```

Models are stored in the `ollama_data` Docker volume and persist across restarts. This only needs to be done once.

---

## Issue 4 — Platform mismatch warning on Apple Silicon

**Warning:**
```
The requested image's platform (linux/amd64) does not match the detected host platform
(linux/arm64/v8) and no specific platform was requested
```

**Affected images:** `io2060/vs-agent:v1.5.5`, `apache/activemq-artemis:2.31.2`

**Root cause:**  
These images are only published for `linux/amd64`. On Apple Silicon Macs, Docker Desktop runs them via Rosetta 2 emulation automatically.

**Impact:**  
None in practice — Docker Desktop handles the emulation transparently. The services start and run correctly.

**Optional fix:**  
Add `platform: linux/amd64` explicitly to the affected services in `docker-compose.yml` to suppress the warning:
```yaml
vs-agent:
  image: io2060/vs-agent:v1.5.5
  platform: linux/amd64

artemis:
  image: apache/activemq-artemis:2.31.2
  platform: linux/amd64
```

---

## Issue 5 — Ollama service name conflict with host Ollama

**Problem:**  
If Ollama is already running locally on port `11434`, mapping the Docker Ollama service to the same port causes a conflict.

**Fix:**  
In `docker-compose.yml`, map the Docker Ollama to an external port that doesn't conflict:
```yaml
ollama-svr:
  image: ollama/ollama:latest
  container_name: ollama-docker
  ports:
    - "11435:11434"   # external 11435 → internal 11434
```

The chatbot references the service via Docker's internal network (`http://ollama-svr:11434`), so it is unaffected by the external port change.

---

## Issue 6 — Docker build uses stale cached layers after Dockerfile change

**Problem:**  
After changing the Dockerfile (e.g., switching the upstream git tag), `docker compose up --build` may reuse cached intermediate layers and run the old code.

**Fix:**  
Force a full cache-free rebuild:
```bash
docker compose build --no-cache chatbot
docker compose up -d
```

---

## Issue 7 — `http://localhost:3000/` returns 404

**Error:**
```json
{"message":"Cannot GET /","error":"Not Found","statusCode":404}
```

**Root cause:**  
The chatbot API (port 3000) has no root route. The correct URLs are:

| URL | Purpose |
|-----|---------|
| `http://localhost:3000/api` | Swagger UI — REST API documentation |
| `http://localhost:3002/v1/qr` | QR code image to scan with Hologram |
| `http://localhost:3002/v1/invitation` | Raw Hologram deep link (JSON) |
| `http://localhost:3002/v1/agent` | vs-agent status |

Port `3001` is the DIDComm inbound transport used exclusively by Hologram via the ngrok tunnel — it is not meant for browser access.

---

## Issue 8 — `AGENT_ENDPOINT` deprecated warning, vs-agent not initializing

**Warning:**
```
[Server] AGENT_ENDPOINT variable is defined and it is deprecated. Please use AGENT_ENDPOINTS instead.
```

**Root cause:**  
vs-agent v1.5.5 renamed the variable from `AGENT_ENDPOINT` to `AGENT_ENDPOINTS` (plural). Using only the old name causes the agent to not register its public endpoint correctly.

**Fix:**  
Set both variables in `.env` to the ngrok URL:
```env
AGENT_ENDPOINT=https://abc123.ngrok-free.app
AGENT_ENDPOINTS=https://abc123.ngrok-free.app
```

Also expose the vs-agent admin port in `docker-compose.yml` (it runs internally on port 3000, separate from the chatbot):
```yaml
vs-agent:
  ports:
    - "3001:3001"   # DIDComm inbound
    - "3002:3000"   # Admin API (QR, invitation, agent status)
```

Verify the agent initialized correctly:
```bash
curl http://localhost:3002/v1/agent
# Expected: {"isInitialized":true, "endpoints":["https://abc123.ngrok-free.app"], ...}
```
