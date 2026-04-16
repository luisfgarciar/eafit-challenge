#!/usr/bin/env bash
# =============================================================================
# EAFIT AI Chatbot — Verana Setup Script
# =============================================================================
#
# This script registers the chatbot on the Verana blockchain by:
#   1. Verifying the VS Agent is running (already started by docker-compose)
#   2. Starting (or reusing) an ngrok tunnel on port 3001
#   3. Setting up the veranad CLI account (creates it and waits for funding)
#   4. Obtaining a Service credential from the eafit-challenge organization
#      and linking it on the VS Agent's DID document
#
# The VS Agent admin API is exposed at localhost:3002 (mapped from container port 3000).
#
# Prerequisites:
#   - Docker Compose stack is running: docker compose up -d
#   - ngrok is installed and authenticated
#   - curl, jq installed
#   - Organization admin API reachable (ORG_VS_ADMIN_URL)
#
# Usage:
#   cd ai-chatbot
#   cp .env.example .env && nano .env   # configure your values
#   docker compose up -d               # start the stack first
#   ./scripts/setup.sh
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load and export environment variables from .env
if [ -f "${REPO_ROOT}/.env" ]; then
  set -a
  # shellcheck source=../.env
  source "${REPO_ROOT}/.env"
  set +a
else
  echo "ERROR: .env file not found at ${REPO_ROOT}/.env"
  echo "       Copy .env.example to .env and fill in your values."
  exit 1
fi

# shellcheck source=../common/common.sh
source "${REPO_ROOT}/common/common.sh"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

NETWORK="${NETWORK:-testnet}"
USER_ACC="${USER_ACC:-eafit-chatbot-admin}"
OUTPUT_FILE="${OUTPUT_FILE:-${REPO_ROOT}/ids.env}"

# The VS Agent admin API is exposed at localhost:3002 (docker-compose maps 3002→3000)
VS_AGENT_PUBLIC_PORT="${VS_AGENT_PUBLIC_PORT:-3001}"
ADMIN_API="http://localhost:3002"

# Organization admin API (to request Service credential)
ORG_VS_ADMIN_URL="${ORG_VS_ADMIN_URL:-https://admin.organization.eafit.testnet.verana.network}"
ORG_VS_PUBLIC_URL="${ORG_VS_PUBLIC_URL:-https://organization.eafit.testnet.verana.network}"

# Service metadata
SERVICE_NAME="${SERVICE_NAME:-EAFIT AI Assistant}"
SERVICE_TYPE="${SERVICE_TYPE:-AIAgent}"
SERVICE_DESCRIPTION="${SERVICE_DESCRIPTION:-EAFIT AI chatbot with Verana blockchain verification}"
SERVICE_LOGO_URL="${SERVICE_LOGO_URL:-https://hologram.zone/images/github.svg}"
SERVICE_MIN_AGE="${SERVICE_MIN_AGE:-0}"
SERVICE_TERMS="${SERVICE_TERMS:-https://verana.io/terms}"
SERVICE_PRIVACY="${SERVICE_PRIVACY:-https://verana.io/privacy}"

echo "============================================="
echo " EAFIT AI Chatbot — Verana Setup"
echo "============================================="
echo "  Network         : $NETWORK"
echo "  Admin API       : $ADMIN_API"
echo "  Org Admin URL   : $ORG_VS_ADMIN_URL"
echo "  Service Name    : $SERVICE_NAME"
echo ""

# ---------------------------------------------------------------------------
# Ensure veranad is available
# ---------------------------------------------------------------------------

if ! command -v veranad &> /dev/null; then
  log "veranad not found — downloading..."
  VERANAD_VERSION="${VERANAD_VERSION:-v0.9.4}"
  PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
  esac
  mkdir -p "${HOME}/.local/bin"
  curl -sfL "https://github.com/verana-labs/verana/releases/download/${VERANAD_VERSION}/veranad-${PLATFORM}-${ARCH}" \
    -o "${HOME}/.local/bin/veranad"
  chmod +x "${HOME}/.local/bin/veranad"
  export PATH="${HOME}/.local/bin:$PATH"
  ok "veranad installed: $(veranad version)"
fi

# ---------------------------------------------------------------------------
# Set network-specific variables
# ---------------------------------------------------------------------------

set_network_vars "$NETWORK"
log "Network: $NETWORK (chain: $CHAIN_ID, faucet: $FAUCET_URL)"

# =============================================================================
# STEP 1: Verify VS Agent is running
# =============================================================================

log "Step 1: Verify VS Agent is running"

if ! docker compose -f "${REPO_ROOT}/docker-compose.yml" ps vs-agent 2>/dev/null | grep -q "running\|Up"; then
  err "VS Agent container is not running."
  err "Start the stack first: cd ai-chatbot && docker compose up -d"
  exit 1
fi
ok "VS Agent container is running"

log "Waiting for VS Agent admin API to become ready (up to 60s)..."
if wait_for_agent "$ADMIN_API" 30; then
  ok "VS Agent admin API is ready at $ADMIN_API"
else
  err "VS Agent admin API did not respond at $ADMIN_API"
  err "Check logs: docker compose logs vs-agent"
  exit 1
fi

# Get agent DID
AGENT_DID=$(curl -sf "${ADMIN_API}/v1/agent" | jq -r '.publicDid // empty')
if [ -z "$AGENT_DID" ] || [ "$AGENT_DID" = "null" ]; then
  err "Could not retrieve agent DID from ${ADMIN_API}/v1/agent"
  exit 1
fi
ok "Agent DID: $AGENT_DID"

# =============================================================================
# STEP 2: Start or reuse ngrok tunnel
# =============================================================================

log "Step 2: Start or reuse ngrok tunnel on port ${VS_AGENT_PUBLIC_PORT}"

NGROK_URL=$(curl -sf http://localhost:4040/api/tunnels 2>/dev/null \
  | jq -r --arg port "$VS_AGENT_PUBLIC_PORT" \
    '.tunnels[] | select(.config.addr | endswith(":"+$port) or (. == "http://localhost:"+$port)) | .public_url' \
  2>/dev/null | head -1 || true)

if [ -n "$NGROK_URL" ]; then
  ok "Reusing existing ngrok tunnel: $NGROK_URL"
  NGROK_PID=""
else
  log "Starting new ngrok tunnel on port ${VS_AGENT_PUBLIC_PORT}..."
  pkill -f "ngrok http ${VS_AGENT_PUBLIC_PORT}" 2>/dev/null || true
  sleep 1
  ngrok http "$VS_AGENT_PUBLIC_PORT" --log=stdout > /tmp/ngrok-eafit-chatbot.log 2>&1 &
  NGROK_PID=$!
  sleep 5

  NGROK_URL=$(curl -sf http://localhost:4040/api/tunnels 2>/dev/null \
    | jq -r '.tunnels[0].public_url // empty' || true)
  if [ -z "$NGROK_URL" ]; then
    err "Failed to get ngrok URL. Is ngrok installed and authenticated?"
    err "Install: https://ngrok.com/download   Authenticate: ngrok config add-authtoken <token>"
    exit 1
  fi
fi

NGROK_DOMAIN=$(echo "$NGROK_URL" | sed 's|https://||')
ok "ngrok tunnel: $NGROK_URL (domain: $NGROK_DOMAIN)"

echo ""
warn "ACTION REQUIRED: Update your .env with the new ngrok URL:"
echo "   AGENT_ENDPOINT=${NGROK_URL}"
echo "   AGENT_ENDPOINTS=${NGROK_URL}"
echo ""
warn "Then restart the stack so VS Agent picks up the new endpoint:"
echo "   docker compose down && docker compose up -d"
echo ""
read -rp "Press Enter to continue once you have updated .env and restarted..."

# =============================================================================
# STEP 3: Set up veranad CLI account
# =============================================================================

log "Step 3: Set up veranad CLI account"
setup_veranad_account "$USER_ACC" "$FAUCET_URL"

# =============================================================================
# STEP 4: Obtain Service credential from organization
# =============================================================================

log "Step 4: Obtain Service credential from organization"

# Verify organization admin API is reachable
if ! curl -sf "${ORG_VS_ADMIN_URL}/api" > /dev/null 2>&1; then
  err "Organization admin API not reachable at ${ORG_VS_ADMIN_URL}"
  err "The eafit-challenge organization must be deployed and its admin API publicly accessible."
  exit 1
fi
ok "Organization admin API reachable: $ORG_VS_ADMIN_URL"

# Skip if Service credential is already linked
if has_linked_vp "$NGROK_URL" "service"; then
  ok "Service credential already linked on agent DID document — skipping"
else
  # Discover Service VTJSC from ECS TR
  SERVICE_VTJSC_OUTPUT=$(discover_ecs_vtjsc "$ECS_TR_PUBLIC_URL" "service")
  SERVICE_JSC_URL=$(echo "$SERVICE_VTJSC_OUTPUT" | sed -n '1p')

  # Download logo as data URI
  SERVICE_LOGO_DATA_URI=$(download_logo_data_uri "$SERVICE_LOGO_URL")

  # Build Service credential claims
  SERVICE_CLAIMS=$(jq -n \
    --arg id "$AGENT_DID" \
    --arg name "$SERVICE_NAME" \
    --arg type "$SERVICE_TYPE" \
    --arg desc "$SERVICE_DESCRIPTION" \
    --arg logo "$SERVICE_LOGO_DATA_URI" \
    --argjson age "$SERVICE_MIN_AGE" \
    --arg terms "$SERVICE_TERMS" \
    --arg privacy "$SERVICE_PRIVACY" \
    '{id: $id, name: $name, type: $type, description: $desc, logo: $logo, minimumAgeRequired: $age, termsAndConditions: $terms, privacyPolicy: $privacy}')

  # Issue Service credential from organization and link on local VS Agent
  issue_remote_and_link "$ORG_VS_ADMIN_URL" "$ADMIN_API" "service" "$SERVICE_JSC_URL" "$AGENT_DID" "$SERVICE_CLAIMS"
fi

# =============================================================================
# Save IDs
# =============================================================================

log "Saving resource IDs to ${OUTPUT_FILE}"

cat > "$OUTPUT_FILE" <<EOF
# EAFIT AI Chatbot — Verana Resource IDs
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Network: ${NETWORK}

AGENT_DID=${AGENT_DID}
NGROK_URL=${NGROK_URL}
NGROK_DOMAIN=${NGROK_DOMAIN}
USER_ACC=${USER_ACC}
USER_ACC_ADDR=${USER_ACC_ADDR:-}
EOF

ok "IDs saved to ${OUTPUT_FILE}"

# =============================================================================
# Summary
# =============================================================================

log "Verana setup complete!"
echo ""
echo "  Agent DID         : $AGENT_DID"
echo "  Public URL        : $NGROK_URL"
echo "  Admin API         : $ADMIN_API"
echo ""
echo "  Next steps:"
echo "    1. Make sure your .env has AGENT_ENDPOINT=${NGROK_URL}"
echo "    2. Restart the stack if you changed .env:"
echo "       docker compose down && docker compose up -d"
echo "    3. Scan the QR code to connect via Hologram:"
echo "       curl http://localhost:3002/v1/qr"
echo ""
echo "  The agent now supports:"
echo "    - Verana blockchain-verified identity (Service credential linked)"
echo "    - User authentication via Avatar credentials"
echo "    - GitHub MCP integration (users configure their token in chat)"
echo ""
if [ -n "${NGROK_PID:-}" ]; then
  echo "  To stop ngrok: kill $NGROK_PID"
fi
