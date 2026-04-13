#!/bin/bash
set -euo pipefail

NAMESPACE="eafit-luisgarcia"
IMAGE="${IMAGE:-eafit-chatbot:latest}"
ENV_FILE="../ai-chatbot/.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Deploying EAFIT AI Chatbot to namespace: $NAMESPACE"

# ── 1. Build chatbot image ────────────────────────────────────────────────────
echo "==> Building chatbot Docker image: $IMAGE"
docker build -t "$IMAGE" "$SCRIPT_DIR/../ai-chatbot"

# ── 2. Create namespace ───────────────────────────────────────────────────────
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# ── 3. Load secrets from .env ─────────────────────────────────────────────────
echo "==> Creating secrets from $ENV_FILE"
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found. Copy ai-chatbot/.env.example to ai-chatbot/.env and fill in values."
  exit 1
fi

# Source the .env file (skip comments and empty lines)
set -a
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +a

kubectl create secret generic chatbot-secrets \
  --namespace="$NAMESPACE" \
  --from-literal=ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
  --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-eafit2025}" \
  --from-literal=VS_AGENT_STATS_PASSWORD="${VS_AGENT_STATS_PASSWORD:-artemis}" \
  --dry-run=client -o yaml | kubectl apply -f -

# ── 4. Create ConfigMaps for agent-packs and docs ─────────────────────────────
echo "==> Creating ConfigMaps for agent-packs and RAG docs"

kubectl create configmap agent-packs-cm \
  --namespace="$NAMESPACE" \
  --from-file="$SCRIPT_DIR/../ai-chatbot/agent-packs/my-agent/agent-pack.yaml" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap rag-docs-cm \
  --namespace="$NAMESPACE" \
  --from-file="$SCRIPT_DIR/../ai-chatbot/docs/" \
  --dry-run=client -o yaml | kubectl apply -f -

# ── 5. Apply manifests ────────────────────────────────────────────────────────
echo "==> Applying Kubernetes manifests"
kubectl apply -f "$SCRIPT_DIR/configmap.yaml"
kubectl apply -f "$SCRIPT_DIR/deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/service.yaml"
kubectl apply -f "$SCRIPT_DIR/ingress.yaml"

# ── 6. Wait for rollout ───────────────────────────────────────────────────────
echo "==> Waiting for deployments to be ready..."
kubectl rollout status deployment/chatbot  -n "$NAMESPACE" --timeout=120s
kubectl rollout status deployment/vs-agent -n "$NAMESPACE" --timeout=120s

# ── 7. Summary ────────────────────────────────────────────────────────────────
echo ""
echo "✓ Deployment complete!"
echo ""
kubectl get pods -n "$NAMESPACE"
echo ""
echo "  VS Agent public URL : https://myagent.luisgarcia.eafit.testnet.verana.network"
echo "  QR / invitation     : kubectl port-forward svc/vs-agent 3002:3000 -n $NAMESPACE"
echo "                        then open http://localhost:3002/v1/qr"
