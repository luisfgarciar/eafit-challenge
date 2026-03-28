# Builds the hologram-generic-ai-agent-vs chatbot from the upstream source.
# Your customizations live in agent-packs/ and docs/ — mounted as volumes at runtime.

# Stage 1: clone & build upstream source
FROM node:23-alpine AS builder
RUN apk add --no-cache git
WORKDIR /upstream
RUN git clone --depth 1 https://github.com/2060-io/hologram-generic-ai-agent-vs.git .
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
