#!/usr/bin/env bash
# =============================================================================
# EAFIT AI Chatbot — Start Script
# =============================================================================
#
# Starts the full Docker Compose stack (chatbot + vs-agent + redis + postgres +
# artemis + ollama). Run setup.sh first to register on the Verana blockchain.
#
# Usage:
#   ./scripts/start.sh           # foreground (shows all logs)
#   ./scripts/start.sh -d        # detached (background)
#   ./scripts/start.sh --build   # rebuild chatbot image first
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment
if [ -f "${REPO_ROOT}/.env" ]; then
  set -a
  # shellcheck source=../.env
  source "${REPO_ROOT}/.env"
  set +a
else
  echo "WARNING: .env not found. Copy .env.example to .env and configure it."
fi

echo "============================================="
echo " EAFIT AI Chatbot — Starting Stack"
echo "============================================="
echo "  Agent label  : ${AGENT_LABEL:-EAFIT AI Assistant}"
echo "  Endpoint     : ${AGENT_ENDPOINT:-<not set — run setup.sh first>}"
echo "  LLM provider : ${LLM_PROVIDER:-not set}"
echo ""

if [ -z "${AGENT_ENDPOINT:-}" ]; then
  echo "WARNING: AGENT_ENDPOINT is not set. VS Agent will not have a public DIDComm URL."
  echo "         Run ngrok http 3001, then set AGENT_ENDPOINT in .env and restart."
fi

if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ "${LLM_PROVIDER:-}" = "anthropic" ]; then
  echo "WARNING: ANTHROPIC_API_KEY is not set but LLM_PROVIDER=anthropic."
fi

if [ -z "${CREDENTIAL_DEFINITION_ID:-}" ]; then
  echo "WARNING: CREDENTIAL_DEFINITION_ID is not set."
  echo "         User authentication will not work. Run setup.sh to configure."
fi

echo ""
echo "Starting Docker Compose stack..."
docker compose -f "${REPO_ROOT}/docker-compose.yml" up "$@"
