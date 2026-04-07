# Builds the hologram-generic-ai-agent-vs chatbot from the upstream source.
# Your customizations live in agent-packs/ and docs/ — mounted as volumes at runtime.

# Stage 1: clone & build upstream source
FROM node:23-alpine AS builder
RUN apk add --no-cache git
WORKDIR /upstream
RUN git clone --depth 1 --branch v1.9.0 https://github.com/2060-io/hologram-generic-ai-agent-vs.git .

# No CoreModule patch needed — AppModule handles StatProducerService via
# EventsModule.register({ modules: { stats: true } }) when VS_AGENT_STATS_ENABLED=true

# Patch: make RAG embeddings provider-aware (Ollama or OpenAI based on LLM_PROVIDER)
RUN apk add --no-cache python3 && python3 - <<'EOF'
path = 'src/rag/langchain-rag.service.ts'
src = open(path).read()

# 1. Add OllamaEmbeddings import alongside the existing OpenAI import
src = src.replace(
    "import { OpenAIEmbeddings, OpenAI } from '@langchain/openai'",
    "import { OpenAIEmbeddings, OpenAI } from '@langchain/openai'\nimport { OllamaEmbeddings } from '@langchain/ollama'"
)

# 2. Change the embeddings variable type to accept both providers
src = src.replace(
    "    let embeddings: OpenAIEmbeddings",
    "    let embeddings: OpenAIEmbeddings | OllamaEmbeddings"
)

# 3. Replace the hardcoded OpenAI embeddings init with a provider-conditional block
old_block = """    try {
      embeddings = new OpenAIEmbeddings({ openAIApiKey: openaiApiKey! })
      this.logger.debug('OpenAI embeddings initialized successfully.')
    } catch (error) {
      this.logger.error(`Failed to initialize OpenAI embeddings: ${error.message}`)
      return
    }"""

new_block = """    const llmProvider = process.env.LLM_PROVIDER || 'openai'
    try {
      if (llmProvider === 'ollama') {
        const ollamaBaseUrl = process.env.OLLAMA_ENDPOINT || 'http://localhost:11434'
        const ollamaEmbeddingModel = process.env.OLLAMA_EMBEDDING_MODEL || 'nomic-embed-text'
        embeddings = new OllamaEmbeddings({ model: ollamaEmbeddingModel, baseUrl: ollamaBaseUrl })
        this.logger.debug(`Ollama embeddings initialized (model=${ollamaEmbeddingModel}, url=${ollamaBaseUrl}).`)
      } else {
        embeddings = new OpenAIEmbeddings({ openAIApiKey: openaiApiKey! })
        this.logger.debug('OpenAI embeddings initialized successfully.')
      }
    } catch (error) {
      this.logger.error(`Failed to initialize embeddings: ${error.message}`)
      return
    }"""

src = src.replace(old_block, new_block)

# 4. Update private method signatures to accept both embedding types
src = src.replace(
    "private async initPinecone(embeddings: OpenAIEmbeddings)",
    "private async initPinecone(embeddings: OpenAIEmbeddings | OllamaEmbeddings)"
)
src = src.replace(
    "private async initRedis(embeddings: OpenAIEmbeddings)",
    "private async initRedis(embeddings: OpenAIEmbeddings | OllamaEmbeddings)"
)

open(path, 'w').write(src)
print('RAG embedding patch applied successfully')
EOF

RUN npm install -g pnpm && pnpm install --frozen-lockfile && pnpm run build

# Stage 2: lean runtime image
FROM node:23-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /upstream/dist ./dist
COPY --from=builder /upstream/node_modules ./node_modules
COPY --from=builder /upstream/package.json ./

EXPOSE 3000
CMD ["node", "dist/main.js"]
