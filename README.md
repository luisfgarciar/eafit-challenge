# Generative AI Challenge: Verifiable AI Agents with Hologram

**Verana Foundation × NODO EAFIT — Beca IA Ser ANDI**

[Visual presentation](./Generative-AIAI-Verificable-Agents-with-MCP-and-Hologram-Messaging.pdf) | [Versión en español](./README-es.md)

---

## Table of Contents

- [1. Challenge Overview](#1-challenge-overview)
- [2. Software and Tools](#2-software-and-tools)
- [3. Development Environment Setup](#3-development-environment-setup)
- [4. Getting Help](#4-getting-help)
- [Step 1 — Getting Started with AI Chatbots and Hologram](#step-1--getting-started-with-ai-chatbots-and-hologram)
- [Step 2 — Deploy Your Bot to Kubernetes](#step-2--deploy-your-bot-to-kubernetes)
- [Step 3 — The Challenge: Online Service for Creating Persona AI Agents](#step-3--the-challenge-online-service-for-creating-persona-ai-agents)
- [Grading and Evaluation](#grading-and-evaluation)

---

## 1. Challenge Overview

### Purpose

Today's chatbots and AI agents live on centralized platforms. There is no way to verify who operates them, what policies they follow, or whether they are legitimate. Users trust them blindly.

**Verana** is an open trust layer for the internet, built on decentralized identity (DIDs) and verifiable credentials (W3C). **Hologram** is a messaging app that works as a browser for verifiable AI agents: before interacting with a bot, users can confirm who operates it.

In this challenge, you will build a web platform that allows **anyone** — without technical knowledge — to create, configure, and publish their own personal AI agent (Persona AI Agent), accessible through Hologram.

### What You Will Learn

- Building chatbots with generative AI (LLMs, RAG, prompts, MCP)
- Integration with decentralized identity protocols (DIDs, Verifiable Credentials)
- Deploying services with Docker and Kubernetes
- Full-stack web application development
- Working with open-source repositories and GitHub collaboration
- Cutting-edge technologies: W3C, DIF, ToIP standards

### What You Will Deliver

1. **Custom test chatbot** — an AI bot running on Hologram (Step 1)
2. **Bot deployed on Kubernetes** — your chatbot publicly accessible (Step 2)
3. **"Persona AI Agent Creator" web platform** — a complete web application that allows non-technical users to create and manage their own personal AI agents (Step 3)
4. **Code published on GitHub** — in your fork of the `verana-labs/eafit-challenge` repository, under an open-source license
5. **Documentation** — README with installation and usage instructions

---

## 2. Software and Tools

Below is a list of all the tools you will need. **Install them before you begin.**

### Code Editor (IDE)

Use one of the following editors. All are free and support TypeScript/JavaScript:

| IDE | Description | Download |
|-----|-------------|----------|
| **VS Code** | Most popular, extensions for everything | https://code.visualstudio.com |
| **Windsurf** | IDE with built-in AI (based on VS Code) | https://windsurf.com |
| **Cursor** | IDE with built-in AI (based on VS Code) | https://cursor.sh |

> Any of the three will work. If you have never used any of them, start with **VS Code**.

### Git and GitHub

- **Git**: version control system. Download: https://git-scm.com/downloads
- **GitHub**: code hosting platform. **Create a free account** at https://github.com if you don't have one.

Verify that Git is installed:

```bash
git --version
# Should show something like: git version 2.x.x
```

### Node.js and pnpm

The project uses **Node.js** (JavaScript runtime) and **pnpm** (package manager).

1. Install Node.js **v20 or higher**: https://nodejs.org (download the LTS version)
2. Install pnpm:

```bash
npm install -g pnpm
```

Verify:

```bash
node --version
# Should show v20.x.x or higher

pnpm --version
# Should show 8.x.x or higher
```

### Docker

Docker lets you run applications in isolated containers. You will use it to run the chatbot and its associated services (Redis, PostgreSQL, etc.).

- **Docker Desktop**: https://www.docker.com/products/docker-desktop/
- After installing, verify:

```bash
docker --version
# Should show: Docker version 2x.x.x

docker compose version
# Should show: Docker Compose version v2.x.x
```

### ngrok

ngrok creates a public tunnel to your local machine. This allows Hologram to connect to your chatbot during development.

1. Create a free account at https://ngrok.com
2. Download and install: https://ngrok.com/download
3. Authenticate with your token:

```bash
ngrok config add-authtoken YOUR_TOKEN_HERE
```

4. Verify:

```bash
ngrok version
```

### Hologram Messaging

Hologram is the messaging app where users interact with verifiable AI agents. You will need it to test your chatbot.

- **iOS**: Search for "Hologram Messaging" on the App Store
- **Android**: Search for "Hologram Messaging" on Google Play
- **Web**: https://hologram.zone

> Install the app on your phone. You will use it to scan QR codes and chat with your bot.

### kubectl (for Step 2)

`kubectl` is the command-line tool for interacting with Kubernetes.

- Installation: https://kubernetes.io/docs/tasks/tools/

```bash
kubectl version --client
```

### Key Repositories

| Repository | Description |
|------------|-------------|
| [verana-labs/eafit-challenge](https://github.com/verana-labs/eafit-challenge) | **Your working repository** — contains the chatbot base code, k8s deployment scripts, and templates |
| [2060-io/hologram-generic-ai-agent-vs](https://github.com/2060-io/hologram-generic-ai-agent-vs) | Generic AI agent for Hologram (chatbot upstream) |
| [verana-labs/vs-agent](https://github.com/verana-labs/vs-agent) | VS Agent — framework for building Verifiable Services with Hologram |
| [verana-labs/verana-demos](https://github.com/verana-labs/verana-demos) | Demos and scripts for the Verana ecosystem |

### Reference Documentation

- Verana Documentation: https://docs.verana.io
- Verifiable Trust Specification: https://verana-labs.github.io/verifiable-trust-spec/
- VPR Specification: https://verana-labs.github.io/verifiable-trust-vpr-spec/
- Hologram: https://hologram.zone

---

## 3. Development Environment Setup

Follow these steps **in order** to get your environment ready.

### 3.1. Install the tools

Make sure you have everything listed in the previous section installed:

- [ ] Code editor (VS Code, Windsurf, or Cursor)
- [ ] Git
- [ ] GitHub account
- [ ] Node.js v20+
- [ ] pnpm
- [ ] Docker Desktop
- [ ] ngrok (with account and token configured)
- [ ] Hologram Messaging on your phone
- [ ] kubectl

### 3.2. Configure Git

If this is your first time using Git, set up your name and email:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3.3. Set up your SSH key on GitHub (recommended)

This allows you to push/pull without entering your password every time.

1. Generate an SSH key:

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

2. Press Enter to accept the default location. Optionally add a passphrase.

3. Copy your public key:

```bash
# macOS
cat ~/.ssh/id_ed25519.pub | pbcopy

# Linux
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard

# Windows (Git Bash)
cat ~/.ssh/id_ed25519.pub | clip
```

4. Go to **GitHub → Settings → SSH and GPG keys → New SSH key** and paste your key.

5. Verify the connection:

```bash
ssh -T git@github.com
# Should respond: Hi your-username! You've successfully authenticated...
```

### 3.4. Get an API key from an LLM provider

Your chatbot needs to connect to a language model. You have several options:

| Provider | Recommended model | How to get API key |
|----------|-------------------|-------------------|
| **OpenAI** | `gpt-4o-mini` | https://platform.openai.com/api-keys |
| **Anthropic** | `claude-3-haiku` | https://console.anthropic.com |
| **Ollama** (local, free) | `llama3` | https://ollama.ai — no API key required |

> **Recommendation for students**: If you don't want to spend money, use **Ollama** with the `llama3` model. It runs locally on your machine. You need at least 8 GB of RAM.

To install Ollama:

```bash
# macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Download the llama3 model
ollama pull llama3
```

### 3.5. Request Kubernetes credentials

For Step 2, you will need a `kubeconfig` file that gives you access to a namespace on the Verana Kubernetes cluster.

**Request your credentials on the Discord channel** (see next section). You will be assigned a namespace in the format: `eafit-YOURNAME`.

---

## 4. Getting Help

### Verana Discord

Join the Verana Discord server and use the **#eafit-challenge** channel to:

- Ask technical questions
- Report issues
- Share your progress
- Request your kubeconfig for k8s

**Invitation link**: https://discord.com/invite/edjaFn252q

> Your Verana technical mentor will be available on this channel. Don't hesitate to ask.

### Additional resources

- Check the documentation at https://docs.verana.io
- Review the READMEs in each repository directory

---

## Step 1 — Getting Started with AI Chatbots and Hologram

**Goal**: Learn how to configure, customize, and run an AI chatbot that connects with Hologram Messaging.

**What you will learn**:
- How an LLM-based AI chatbot works
- Configuration of prompts, RAG, and agent packs
- How communication with Hologram works through VS Agent
- Docker Compose for orchestrating multiple services

**What you will deliver**:
- A custom chatbot running locally, accessible from Hologram

---

### 1.1. Fork the repository

1. Go to https://github.com/verana-labs/eafit-challenge
2. Click the **"Fork"** button (top-right corner)
3. Select your personal account as the destination
4. This will create a copy of the repository at `https://github.com/YOUR-USERNAME/eafit-challenge`

### 1.2. Clone the repository to your machine

Open your terminal and run:

```bash
# Replace YOUR-USERNAME with your GitHub username
git clone git@github.com:YOUR-USERNAME/eafit-challenge.git

# Enter the directory
cd eafit-challenge
```

> If you didn't set up SSH, you can use HTTPS instead:
> ```bash
> git clone https://github.com/YOUR-USERNAME/eafit-challenge.git
> ```

### 1.3. Explore the project structure

Open the project in your editor:

```bash
code .      # for VS Code
# or
windsurf .  # for Windsurf
# or
cursor .    # for Cursor
```

Navigate to the `ai-chatbot/` directory. This directory contains the chatbot code based on [hologram-generic-ai-agent-vs](https://github.com/2060-io/hologram-generic-ai-agent-vs). You will find:

```
ai-chatbot/
├── agent-packs/           # Declarative agent configurations
│   └── my-agent/          # Your custom configuration
│       └── agent-pack.yaml
├── docs/                  # Documents for RAG (knowledge base)
├── docker-compose.yml     # Orchestration of all services
├── .env.example           # Environment variables template
├── Dockerfile             # To build the chatbot image
└── README.md              # Chatbot-specific instructions
```

### 1.4. Configure environment variables

Copy the example file and edit it:

```bash
cd ai-chatbot
cp .env.example .env
```

Open `.env` in your editor and configure at least the following variables:

```env
# === LLM Provider ===
# Option A: OpenAI (requires API key)
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-api-key-here
OPENAI_MODEL=gpt-4o-mini

# Option B: Ollama (local, free)
# LLM_PROVIDER=ollama
# OLLAMA_ENDPOINT=http://ollama:11435
# OLLAMA_MODEL=llama3

# === Agent Pack ===
AGENT_PACK_PATH=./agent-packs/my-agent

# === Redis (for chatbot memory) ===
REDIS_URL=redis://redis:6379
AGENT_MEMORY_BACKEND=redis
AGENT_MEMORY_WINDOW=8

# === Vector Store (for RAG) ===
VECTOR_STORE=redis
VECTOR_INDEX_NAME=eafit-chatbot
RAG_PROVIDER=vectorstore
RAG_DOCS_PATH=/app/rag/docs

# === VS Agent (communication with Hologram) ===
VS_AGENT_ADMIN_URL=http://vs-agent:3001
EVENTS_BASE_URL=http://chatbot:3000

# === PostgreSQL ===
POSTGRES_HOST=postgres
POSTGRES_USER=eafit
POSTGRES_PASSWORD=eafit2025
POSTGRES_DB_NAME=chatbot-agent

# === Application ===
APP_PORT=3000
LOG_LEVEL=3
```

### 1.5. Customize your Agent Pack

The `agent-pack.yaml` file defines the personality, languages, prompt, and behavior of your chatbot. Edit `ai-chatbot/agent-packs/my-agent/agent-pack.yaml`:

```yaml
metadata:
  id: eafit-my-agent
  displayName: My EAFIT Agent
  description: >-
    Custom AI agent created by [YOUR NAME] for the EAFIT challenge.
  defaultLanguage: en
  tags:
    - eafit
    - challenge

languages:
  en:
    greetingMessage: >-
      Hi! 👋 I'm your EAFIT AI assistant. How can I help you today?
    systemPrompt: >-
      You are a friendly and professional AI assistant. You answer questions
      clearly and concisely.
    strings:
      ROOT_TITLE: 'Welcome!'
      ERROR_MESSAGES: 'Service unavailable. Please try again later.'
  es:
    greetingMessage: >-
      ¡Hola! 👋 Soy tu asistente IA de EAFIT. ¿En qué puedo ayudarte hoy?
    systemPrompt: >-
      Eres un asistente IA amigable y profesional. Respondes preguntas de
      manera clara y concisa.
    strings:
      ROOT_TITLE: '¡Bienvenido!'
      ERROR_MESSAGES: 'El servicio no está disponible. Intenta más tarde.'

llm:
  provider: ${LLM_PROVIDER}
  model: ${OPENAI_MODEL}
  temperature: 0.3
  maxTokens: 1000

rag:
  provider: vectorstore
  docsPath: ./docs
  chunkSize: 1000
  chunkOverlap: 200
  vectorStore:
    type: redis
    indexName: eafit-chatbot

memory:
  backend: redis
  window: 8
  redisUrl: ${REDIS_URL}

flows:
  welcome:
    enabled: true
    sendOnProfile: true
    templateKey: greetingMessage

integrations:
  vsAgent:
    adminUrl: ${VS_AGENT_ADMIN_URL}
  postgres:
    host: ${POSTGRES_HOST}
    user: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
    dbName: ${POSTGRES_DB_NAME}
```

> **Customize it**: Change the agent name, greeting messages, system prompt, languages, etc. Make it yours!

### 1.6. Add documents for RAG (knowledge base)

If you want your chatbot to answer questions about specific topics, place files in the `ai-chatbot/docs/` directory. Supported formats:

- `.txt` — plain text
- `.md` — markdown
- `.pdf` — PDF documents
- `.csv` — tabular data

Example: you can add information about EAFIT, your major, or any topic of interest.

### 1.7. Start the chatbot with Docker Compose

Make sure Docker Desktop is running, then:

```bash
cd ai-chatbot
docker compose up --build
```

This will start several services:

| Service | Port | Description |
|---------|------|-------------|
| **chatbot** | 3000 | Your AI agent (API) |
| **vs-agent** | 3001 | Communication service with Hologram (DIDComm) |
| **redis** | 6379 | Memory and vector storage |
| **postgres** | 5432 | Session database |

> The first time will take a few minutes while Docker images are downloaded.

Verify everything is running:

```bash
docker compose ps
```

All services should show status `Up` or `running`.

### 1.8. Expose your service with ngrok

For Hologram to connect to your local chatbot, you need to expose the VS Agent port:

```bash
# In a new terminal
ngrok http 3001
```

ngrok will display a public URL like:

```
Forwarding  https://abc123.ngrok-free.app -> http://localhost:3001
```

**Copy that URL** (the one starting with `https://`). You will need it to configure the VS Agent endpoint.

Now update your `.env` with the ngrok URL:

```env
AGENT_ENDPOINT=https://abc123.ngrok-free.app
```

And restart the services:

```bash
docker compose down
docker compose up --build
```

### 1.9. Get the invitation credentials

Once the VS Agent is running and exposed via ngrok, you need to get the invitation URL to connect with Hologram.

Access the VS Agent API to get the invitation:

```bash
curl http://localhost:3001/
```

This displays a QR code that you can scan with Hologram.

### 1.10. Connect with Hologram and test

1. Open the **Hologram Messaging** app on your phone
2. Scan the invitation QR code (or use the URL)
3. The chatbot will send you its greeting message
4. Start chatting and verify it responds correctly!

**Experiment**:
- Change the prompt in `agent-pack.yaml` and restart
- Add more documents to `docs/` to enrich the RAG
- Try different LLM models
- Change the default language

### 1.11. Commit your changes

Once your chatbot is working, save your changes:

```bash
git add .
git commit -m "feat: configure my custom AI agent"
git push origin main
```

---

## Step 2 — Deploy Your Bot to Kubernetes

**Goal**: Learn how to deploy your chatbot to a Kubernetes cluster so it is publicly accessible without relying on ngrok or your local machine.

**What you will learn**:
- Basic Kubernetes concepts (pods, deployments, services, ingress)
- Configuration with YAML manifests
- Deployment to a real cluster with kubectl

**What you will deliver**:
- Your chatbot deployed and publicly accessible at `yourname.eafit.testnet.verana.network`

---

### 2.1. Verify your Kubernetes credentials

You should have received a `kubeconfig` file from the Verana team (requested in Step 3.5 of the setup). This file gives you access to your namespace on the cluster.

Configure kubectl to use your kubeconfig:

```bash
# Option A: environment variable (recommended)
export KUBECONFIG=~/path/to/your/kubeconfig.yaml

# Option B: copy to the default directory
cp ~/path/to/your/kubeconfig.yaml ~/.kube/config
```

Verify the connection:

```bash
kubectl get pods
# Should show a list (possibly empty) with no errors
```

### 2.2. Analyze the deployment scripts

In your repository, navigate to the `k8s/` directory. You will find Kubernetes YAML manifests:

```
k8s/
├── deployment.yaml      # Defines the pods (containers) for your chatbot
├── service.yaml         # Exposes pods within the cluster
├── ingress.yaml         # Configures public access (domain)
├── configmap.yaml       # Configuration variables
├── secrets.yaml         # Sensitive data (API keys)
└── deploy.sh            # Script to deploy everything at once
```

### 2.3. Customize the configuration

Edit the YAML files to customize your deployment:

**`configmap.yaml`** — Environment variables for your chatbot:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: chatbot-config
  namespace: eafit-YOURNAME
data:
  LLM_PROVIDER: "openai"
  OPENAI_MODEL: "gpt-4o-mini"
  AGENT_PACK_PATH: "./agent-packs/my-agent"
  # ... more variables as needed
```

**`secrets.yaml`** — API keys and passwords (base64-encoded):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: chatbot-secrets
  namespace: eafit-YOURNAME
type: Opaque
data:
  OPENAI_API_KEY: c2stdHUtYXBpLWtleQ==  # echo -n "your-api-key" | base64
```

**`ingress.yaml`** — Your public domain:

```yaml
# Make sure the host points to your subdomain
spec:
  rules:
    - host: myagent.yourname.eafit.testnet.verana.network
```

### 2.4. Deploy

Run the deployment script or apply the manifests manually:

```bash
# Option A: use the script
cd k8s
chmod +x deploy.sh
./deploy.sh

# Option B: apply manually
kubectl apply -f k8s/
```

Verify that pods are running:

```bash
kubectl get pods -n eafit-YOURNAME
# Should show STATUS: Running

kubectl get ingress -n eafit-YOURNAME
# Should show your configured domain
```

### 2.5. Test the deployment

Once the pods are in `Running` status:

1. Open Hologram Messaging
2. Scan the QR or access the invitation URL of your deployed bot (you no longer need ngrok)
3. Verify the chatbot responds correctly

### 2.6. Commit and push

```bash
git add .
git commit -m "feat: add k8s deployment configuration"
git push origin main
```

---

## Step 3 — The Challenge: Online Service for Creating Persona AI Agents

**Goal**: Build a complete web application that allows users without technical knowledge to create, configure, and deploy their own personal AI agents through an intuitive interface.

**What you will learn**:
- Full-stack web application development
- Programmatic deployment management on Kubernetes
- User interface design (UI/UX)
- Integration of multiple services (LLMs, MCP, RAG, k8s)
- User authentication

**What you will deliver**:
- A functional web application for creating and managing Persona AI Agents
- At least 2 functional MCP integrations
- User and technical documentation

---

### What is a Persona AI Agent?

A **Persona AI Agent** is an AI agent that **represents a person** and can execute actions on their behalf.

**Example**: A plumber can have an AI Agent that manages their calendar. Clients connect to the agent through Hologram and have a conversation to schedule an appointment.

### 3.1. Web Application Requirements

Your application must provide:

#### Web Interface

- A modern web application with an intuitive interface
- Responsive (works on desktop and mobile)
- Suggested technology: React, Next.js, Vue.js, or your preference

#### Global Configuration

A configuration file (`.env` or similar) that defines:

- **kubeconfig**: path to the k8s credentials file for deploying bots to the cluster
- **Base domain**: suffix for user chatbot URLs, in the format: `name.eafit.testnet.verana.network`

#### User Authentication

- User login / registration
- Optional: Google authentication (OAuth)
- Logout

#### Bot Management ("My AI Bots")

- **List** my bots: view all AI agents I have created
- **Create** new bot: step-by-step form to configure a new agent
- **View** bot: detail page with the bot's configuration
  - **Edit**: modify the configuration
  - **Save**: persist changes
  - **Publish**: deploy the bot to k8s and make it accessible on Hologram
  - **Unpublish**: remove the bot from the cluster
  - **Link to bot**: button that opens the bot's public URL for scanning with Hologram

### 3.2. Bot Configuration Options

Each bot must be configurable with:

| Option | Description |
|--------|-------------|
| **Persona Attributes** | Name, profession, description, photo — define the agent's identity (Persona Credential) |
| **Service Attributes** | Service name, description, category — define the service offered (Service Credential) |
| **Prompt** | Personality and behavior instructions for the AI agent |
| **MCP Services** | External tools the agent can use (calendar, social media, etc.) |
| **RAG** | Knowledge base: documents the agent uses to answer questions |

### 3.3. MCP Services (Model Context Protocol)

MCP allows the AI agent to access external tools and data during a conversation. You must implement at least **2 functional MCP servers**.

Examples of useful MCP servers:

| MCP Service | Description | Use Case |
|-------------|-------------|----------|
| **Google Calendar** | Read/create events on Google Calendar | Schedule appointments with the professional |
| **X (Twitter)** | Post tweets, read timeline | Promote services, share updates |
| **Gmail** | Send/read emails | Confirm appointments, send information |
| **Google Sheets** | Read/write spreadsheets | Manage inventory, pricing |
| **Weather API** | Check weather | Plan outdoor services |
| **Wikipedia** | Search for information | Answer general questions |

> When creating a bot, the user must be able to select one or more of the available MCP servers on your platform.

### 3.4. Bot Creation Flow

```
[User] → Login → "New Bot" → Configure:
  1. Persona data (name, profession, photo)
  2. Service data (name, description)
  3. Write personality prompt
  4. Select MCP servers
  5. Upload documents for RAG (optional)
→ "Save" → "Publish"
→ Bot deployed to k8s
→ URL available for Hologram ✅
```

### 3.5. Suggested Architecture

```
┌────────────────────────────────────────────┐
│              Web Frontend                  │
│  (React/Next.js/Vue)                       │
│  - Login, Dashboard, Bot Creator           │
└─────────────────┬──────────────────────────┘
                  │ REST API
┌─────────────────▼──────────────────────────┐
│              Backend API                   │
│  (Node.js / Express / NestJS)              │
│  - Auth, Bot CRUD, k8s deploy              │
└──┬──────────────┬──────────────────────────┘
   │              │
   ▼              ▼
┌──────┐  ┌──────────────────────────────────┐
│  DB  │  │  Kubernetes Cluster              │
│(SQLite│  │  - Bot Pod 1 (chatbot + vs-agent)│
│ /PG) │  │  - Bot Pod 2 (chatbot + vs-agent)│
└──────┘  │  - ...                           │
          └──────────────────────────────────┘
```

### 3.6. Final commit and documentation

```bash
git add .
git commit -m "feat: persona AI agent creator web app"
git push origin main
```

Make sure to include:

- `README.md` with installation and usage instructions
- Screenshots of the interface
- Description of the implemented MCP integrations

### 3.7 Bonus: App Containerization and Automatic Deployment with GitHub Actions

This bonus step consists of **containerizing** your web application (Step 3) and setting up a **CI/CD pipeline** with GitHub Actions so that every time you push to `main`, your app is built, published as a Docker image to Docker Hub, and automatically deployed to Kubernetes.

#### 3.7.1. Create a Dockerfile for your web application

In the root of your web project (e.g., `web-app/`), create a `Dockerfile`:

```dockerfile
# Stage 1: build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# Stage 2: production
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

> Adapt paths and commands according to the framework you use (Next.js, Express, NestJS, etc.).

#### 3.7.2. Test the container locally

```bash
cd web-app

# Build the image
docker build -t my-persona-agent-creator .

# Run locally
docker run -p 3000:3000 --env-file .env my-persona-agent-creator

# Verify at http://localhost:3000
```

#### 3.7.3. Create a Docker Hub account

1. Sign up at https://hub.docker.com (free)
2. Create a repository, for example: `your-username/eafit-persona-agent-creator`

#### 3.7.4. Configure secrets in GitHub

In your GitHub fork, go to **Settings → Secrets and variables → Actions** and add the following secrets:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | A Docker Hub Access Token (Settings → Security → New Access Token) |
| `KUBE_CONFIG` | The contents of your `kubeconfig` file encoded in base64: `cat kubeconfig.yaml \| base64` |

#### 3.7.5. Create the GitHub Actions workflow

Create the file `.github/workflows/deploy.yml` in your repository:

```yaml
name: Build, Push & Deploy

on:
  push:
    branches: [main]
    paths:
      - 'web-app/**'

env:
  IMAGE_NAME: ${{ secrets.DOCKERHUB_USERNAME }}/eafit-persona-agent-creator

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      # 1. Checkout code
      - name: Checkout
        uses: actions/checkout@v4

      # 2. Login to Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # 3. Build and push image
      - name: Build and push Docker image
        uses: docker/build-push-action@v6
        with:
          context: ./web-app
          push: true
          tags: |
            ${{ env.IMAGE_NAME }}:latest
            ${{ env.IMAGE_NAME }}:${{ github.sha }}

      # 4. Set up kubectl
      - name: Set up kubectl
        uses: azure/setup-kubectl@v4

      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config

      # 5. Deploy to Kubernetes
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/persona-agent-creator \
            app=${{ env.IMAGE_NAME }}:${{ github.sha }} \
            -n eafit-YOURNAME
          kubectl rollout status deployment/persona-agent-creator \
            -n eafit-YOURNAME --timeout=120s
```

> **Important**: Replace `eafit-YOURNAME` with your actual namespace and `web-app` with your application directory.

#### 3.7.6. Complete flow

```
git push origin main
    │
    ▼
GitHub Actions triggers
    │
    ├─ Build Docker image
    ├─ Push to Docker Hub (tags: latest + commit SHA)
    ├─ Configure kubectl with your kubeconfig
    └─ Update the Kubernetes deployment with the new image
    │
    ▼
Your app updates automatically on the cluster ✅
```

Every push to `main` will deploy the new version without manual intervention. You can check the deployment status in the **Actions** tab of your GitHub repository.

---

## Grading and Evaluation

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Step 1 — Working chatbot** | 20% | Custom bot running locally and accessible from Hologram |
| **Step 2 — k8s deployment** | 15% | Bot correctly deployed on the Kubernetes cluster |
| **Step 3 — Web application** | 40% | Full functionality of the bot creation platform |
| **MCP Integrations** | 10% | At least 2 functional and integrated MCP servers |
| **Code quality** | 5% | Clean, organized code with best practices |
| **Documentation** | 5% | Clear README, usage guide, screenshots |
| **Creativity and innovation** | 5% | Original ideas, polished UX, extra features |

### Bonus Points

- Integrate more than 2 MCP servers (+5%)
- Implement RAG with useful real-world documents (+5%)
- Exceptional UI/UX with responsive design (+5%)
- Automated tests (+5%)
- Video demo showing the complete flow (+5%)
- App containerization + CI/CD with GitHub Actions for auto-deploy to k8s (+10%)

---

**Good luck!** Remember: ask on the Verana Discord (#eafit-challenge) if you have questions. Your Verana technical mentor is there to help you. 🚀
