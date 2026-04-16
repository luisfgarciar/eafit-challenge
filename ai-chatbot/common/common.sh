#!/usr/bin/env bash
# =============================================================================
# common.sh — Shared helpers for EAFIT AI Chatbot Verana setup scripts
# =============================================================================
#
# Ported from verana-labs/eafit-challenge-agent-example.
# Provides:
#   - Colored logging functions
#   - Network configuration (set_network_vars)
#   - Transaction helpers (extract_tx_event, submit_tx)
#   - VS Agent API helpers (wait_for_agent, cleanup_all_vtjscs)
#   - ECS discovery helpers (discover_ecs_vtjsc, discover_active_root_perm)
#   - Credential helpers (issue_and_link, issue_remote_and_link, has_linked_vp)
#   - Permission helpers (find_active_perm, find_active_issuer_perm)
#   - Trust Registry duplicate detection (has_trust_registry_for_schema)
#   - CLI account setup (setup_veranad_account)
#   - Schema / logo download helpers
#
# =============================================================================

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

log()  { echo -e "\n\033[1;34m▶ $1\033[0m" >&2; }
ok()   { echo -e "  \033[1;32m✔ $1\033[0m" >&2; }
err()  { echo -e "  \033[1;31m✘ $1\033[0m" >&2; }
warn() { echo -e "  \033[1;33m⚠ $1\033[0m" >&2; }

# ---------------------------------------------------------------------------
# Network configuration
# ---------------------------------------------------------------------------

set_network_vars() {
  local network="${1:-testnet}"

  case "$network" in
    devnet)
      CHAIN_ID="${CHAIN_ID:-vna-devnet-1}"
      NODE_RPC="${NODE_RPC:-https://rpc.devnet.verana.network}"
      FEES="${FEES:-600000uvna}"
      FAUCET_URL="https://faucet-vs.devnet.verana.network/invitation"
      RESOLVER_URL="${RESOLVER_URL:-https://resolver.devnet.verana.network}"
      ECS_TR_ADMIN_API="${ECS_TR_ADMIN_API:-https://admin-ecs-trust-registry.devnet.verana.network}"
      ECS_TR_PUBLIC_URL="${ECS_TR_PUBLIC_URL:-https://ecs-trust-registry.devnet.verana.network}"
      INDEXER_URL="${INDEXER_URL:-https://idx.devnet.verana.network}"
      ;;
    testnet)
      CHAIN_ID="${CHAIN_ID:-vna-testnet-1}"
      NODE_RPC="${NODE_RPC:-https://rpc.testnet.verana.network}"
      FEES="${FEES:-600000uvna}"
      FAUCET_URL="https://faucet-vs.testnet.verana.network/invitation"
      RESOLVER_URL="${RESOLVER_URL:-https://resolver.testnet.verana.network}"
      ECS_TR_ADMIN_API="${ECS_TR_ADMIN_API:-https://admin-ecs-trust-registry.testnet.verana.network}"
      ECS_TR_PUBLIC_URL="${ECS_TR_PUBLIC_URL:-https://ecs-trust-registry.testnet.verana.network}"
      INDEXER_URL="${INDEXER_URL:-https://idx.testnet.verana.network}"
      ;;
    *)
      err "Unknown network: $network. Use 'devnet' or 'testnet'."
      exit 1
      ;;
  esac

  export CHAIN_ID NODE_RPC FEES FAUCET_URL RESOLVER_URL ECS_TR_ADMIN_API ECS_TR_PUBLIC_URL INDEXER_URL
}

# ---------------------------------------------------------------------------
# Transaction helpers
# ---------------------------------------------------------------------------

# Extract a value from tx events JSON
extract_tx_event() {
  local tx_hash=$1
  local event_type=$2
  local attr_key=$3
  veranad q tx "$tx_hash" --node "$NODE_RPC" --output json 2>/dev/null \
    | jq -r ".events[] | select(.type == \"$event_type\") | .attributes[] | select(.key == \"$attr_key\") | .value" \
    | head -1
}

# Extract JSON from veranad tx output (strips "gas estimate:" prefix line)
extract_tx_json() {
  grep -E '^\{' | head -1
}

# Check that the veranad account has sufficient balance for on-chain transactions.
check_balance() {
  local user_acc=$1
  local addr
  addr=$(veranad keys show "$user_acc" -a --keyring-backend test 2>/dev/null)
  if [ -z "$addr" ]; then
    err "Account '$user_acc' not found in keyring"
    return 1
  fi

  local balance
  balance=$(veranad q bank balances "$addr" --node "$NODE_RPC" --output json 2>/dev/null \
    | jq -r '.balances[]? | select(.denom == "uvna") | .amount // "0"' 2>/dev/null || echo "0")

  if [ -z "$balance" ] || [ "$balance" = "0" ]; then
    err "Account '$user_acc' ($addr) has no uvna balance."
    err "On-chain transactions require funds. Top up using the faucet:"
    err ""
    err "  ${FAUCET_URL}"
    err ""
    return 1
  fi

  ok "Account balance: ${balance} uvna"
}

# Submit a veranad tx command, wait for confirmation, and extract an event value.
# Usage: submit_tx <event_type> <attr_key> <veranad tx ...args>
submit_tx() {
  local event_type=$1; shift
  local attr_key=$1; shift

  local raw_output
  raw_output=$("$@" \
    --from "$USER_ACC" --chain-id "$CHAIN_ID" --keyring-backend test \
    --fees "$FEES" --gas auto --node "$NODE_RPC" \
    --output json -y 2>&1) || true

  local result
  result=$(echo "$raw_output" | extract_tx_json)

  local tx_hash
  tx_hash=$(echo "$result" | jq -r '.txhash // empty')
  if [ -z "$tx_hash" ]; then
    err "TX failed. Raw output:"
    echo "$raw_output" >&2
    return 1
  fi
  ok "TX submitted: $tx_hash"

  sleep 8

  local value
  value=$(extract_tx_event "$tx_hash" "$event_type" "$attr_key")
  if [ -z "$value" ]; then
    sleep 6
    value=$(extract_tx_event "$tx_hash" "$event_type" "$attr_key")
  fi
  if [ -z "$value" ]; then
    err "Could not extract '$attr_key' from event '$event_type' (tx: $tx_hash)"
    return 1
  fi

  echo "$value"
}

# ---------------------------------------------------------------------------
# VS Agent API helpers
# ---------------------------------------------------------------------------

# Wait for the VS Agent admin API to become ready
# Usage: wait_for_agent <admin_api_url> [max_retries]
wait_for_agent() {
  local admin_api=$1
  local max_retries=${2:-30}
  local i=0
  while [ $i -lt "$max_retries" ]; do
    if curl -sf "${admin_api}/v1/agent" > /dev/null 2>&1; then
      return 0
    fi
    sleep 2
    i=$((i + 1))
  done
  return 1
}

# Remove ALL local VTJSCs and their linked credentials
cleanup_all_vtjscs() {
  local admin_api=$1

  local all_jscs
  all_jscs=$(curl -sf "${admin_api}/v1/vt/json-schema-credentials" \
    | jq -r '.data[].credential.id' 2>/dev/null)

  for jsc_id in $all_jscs; do
    curl -s -X DELETE "${admin_api}/v1/vt/linked-credentials" \
      -H 'Content-Type: application/json' \
      -d "{\"credentialSchemaId\": \"$jsc_id\"}" > /dev/null 2>&1 || true
    curl -s -X DELETE "${admin_api}/v1/vt/json-schema-credentials" \
      -H 'Content-Type: application/json' \
      -d "{\"id\": \"$jsc_id\"}" > /dev/null 2>&1 || true
  done
}

# Remove ECS-linked credentials (Organization + Service) and their VTJSCs
cleanup_ecs_credentials() {
  local admin_api=$1
  local org_jsc_url=$2
  local service_jsc_url=$3

  log "Cleaning up previous ECS credentials..."
  for jsc_url in "$org_jsc_url" "$service_jsc_url"; do
    curl -s -X DELETE "${admin_api}/v1/vt/linked-credentials" \
      -H 'Content-Type: application/json' \
      -d "{\"credentialSchemaId\": \"$jsc_url\"}" > /dev/null 2>&1 || true
    curl -s -X DELETE "${admin_api}/v1/vt/json-schema-credentials" \
      -H 'Content-Type: application/json' \
      -d "{\"id\": \"$jsc_url\"}" > /dev/null 2>&1 || true
  done
  local self_jscs
  self_jscs=$(curl -sf "${admin_api}/v1/vt/json-schema-credentials" \
    | jq -r '.data[] | select(.schemaId | startswith("vpr:") | not) | .credential.id' 2>/dev/null)
  for jsc_id in $self_jscs; do
    curl -s -X DELETE "${admin_api}/v1/vt/linked-credentials" \
      -H 'Content-Type: application/json' \
      -d "{\"credentialSchemaId\": \"$jsc_id\"}" > /dev/null 2>&1 || true
    curl -s -X DELETE "${admin_api}/v1/vt/json-schema-credentials" \
      -H 'Content-Type: application/json' \
      -d "{\"id\": \"$jsc_id\"}" > /dev/null 2>&1 || true
  done
  ok "Previous ECS credentials cleaned up"
}

# ---------------------------------------------------------------------------
# Schema helpers
# ---------------------------------------------------------------------------

download_schema() {
  curl -sf "$1" | jq -c '.'
}

# Compute SHA-384 SRI digest of a URL's content
compute_sri_digest() {
  local url=$1
  local hash
  hash=$(curl -sfL "$url" | openssl dgst -sha384 -binary | openssl base64 -A)
  if [ -z "$hash" ]; then
    err "Failed to compute SRI digest for $url"
    return 1
  fi
  echo "sha384-${hash}"
}

# Download an image from a URL and return it as a data URI.
download_logo_data_uri() {
  local url=$1
  local tmp_body="/tmp/logo_body_$$"
  local tmp_headers="/tmp/logo_headers_$$"

  local http_code
  http_code=$(curl -sfL -D "$tmp_headers" -o "$tmp_body" -w '%{http_code}' "$url")

  if [ "$http_code" != "200" ] || [ ! -s "$tmp_body" ]; then
    err "Failed to download logo from $url (HTTP $http_code)"
    rm -f "$tmp_body" "$tmp_headers"
    return 1
  fi

  local content_type
  content_type=$(grep -i '^content-type:' "$tmp_headers" | tail -1 | tr -d '\r' | sed 's/^[^:]*:[[:space:]]*//' | cut -d';' -f1 | xargs)

  case "$content_type" in
    image/png|image/jpeg|image/svg+xml) ;;
    *)
      case "$url" in
        *.png)          content_type="image/png" ;;
        *.jpg|*.jpeg)   content_type="image/jpeg" ;;
        *.svg)          content_type="image/svg+xml" ;;
        *)
          err "Could not determine image content type for $url (got: ${content_type:-empty})"
          rm -f "$tmp_body" "$tmp_headers"
          return 1
          ;;
      esac
      warn "Content-Type header not image/*; using $content_type (from URL extension)"
      ;;
  esac

  local b64
  b64=$(base64 < "$tmp_body" | tr -d '\n')
  rm -f "$tmp_body" "$tmp_headers"

  if [ -z "$b64" ]; then
    err "Failed to base64-encode logo from $url"
    return 1
  fi

  echo "data:${content_type};base64,${b64}"
}

# ---------------------------------------------------------------------------
# ECS Trust Registry discovery helpers
# ---------------------------------------------------------------------------

# Discover a VTJSC from the ECS Trust Registry by resolving its DID document.
# Usage: discover_ecs_vtjsc <ecs_public_url> <schema_name>
# Outputs two lines: VTJSC credential URL, numeric VPR schema ID
discover_ecs_vtjsc() {
  local ecs_public_url=$1
  local schema_name=$2

  log "Resolving ECS TR DID document for '$schema_name' VTJSC..."

  local did_doc
  did_doc=$(curl -sf "${ecs_public_url}/.well-known/did.json")
  if [ -z "$did_doc" ]; then
    err "Failed to fetch DID document from ${ecs_public_url}/.well-known/did.json"
    return 1
  fi

  local vp_url
  vp_url=$(echo "$did_doc" | jq -r --arg pat "${schema_name}-jsc-vp" '
    .service[] | select(.type == "LinkedVerifiablePresentation") |
    select(.id | test($pat)) | .serviceEndpoint' | head -1)

  if [ -z "$vp_url" ]; then
    err "No LinkedVerifiablePresentation matching '${schema_name}-jsc-vp' in DID document"
    return 1
  fi
  ok "VTJSC VP endpoint: $vp_url"

  local vp
  vp=$(curl -sf "$vp_url")
  if [ -z "$vp" ]; then
    err "Failed to fetch VTJSC VP from $vp_url"
    return 1
  fi

  local vtjsc_url
  vtjsc_url=$(echo "$vp" | jq -r '.verifiableCredential[0].id // empty')
  if [ -z "$vtjsc_url" ]; then
    err "Could not extract VTJSC URL from VP"
    return 1
  fi

  local schema_ref
  schema_ref=$(echo "$vp" | jq -r '.verifiableCredential[0].credentialSubject.jsonSchema."$ref" // empty')
  if [ -z "$schema_ref" ]; then
    err "Could not extract jsonSchema.\$ref from VTJSC"
    return 1
  fi

  local schema_id
  schema_id=$(echo "$schema_ref" | grep -oE '[0-9]+$')
  if [ -z "$schema_id" ]; then
    err "Could not parse schema ID from ref: $schema_ref"
    return 1
  fi

  ok "VTJSC '$schema_name' → URL: $vtjsc_url, schema ID: $schema_id"
  echo "$vtjsc_url"
  echo "$schema_id"
}

# Discover the active root permission (ECOSYSTEM type) for a given schema.
# Usage: discover_active_root_perm <schema_id>
discover_active_root_perm() {
  local schema_id=$1
  local url="${INDEXER_URL}/verana/perm/v1/list?schema_id=${schema_id}"

  log "Discovering active root permission for schema $schema_id via indexer..."

  local perms http_code
  local max_retries=3
  local attempt=0

  while [ $attempt -lt $max_retries ]; do
    attempt=$((attempt + 1))
    http_code=$(curl -s -o /tmp/indexer_response.json -w '%{http_code}' "$url")

    if [ "$http_code" = "200" ]; then
      perms=$(cat /tmp/indexer_response.json)
      break
    fi
    log "Indexer request attempt $attempt/$max_retries returned HTTP $http_code, retrying in 5s..."
    sleep 5
  done

  if [ "$http_code" != "200" ] || [ -z "$perms" ]; then
    err "Failed to query indexer (HTTP $http_code) at $url"
    [ -f /tmp/indexer_response.json ] && err "Response: $(cat /tmp/indexer_response.json)"
    return 1
  fi

  local root_perm_id
  root_perm_id=$(echo "$perms" | jq -r '
    .permissions[] |
    select(.type == "ECOSYSTEM" and .perm_state == "ACTIVE") |
    .id' | head -1)

  if [ -z "$root_perm_id" ]; then
    err "No active ECOSYSTEM permission found for schema $schema_id"
    return 1
  fi

  ok "Active root permission: $root_perm_id"
  echo "$root_perm_id"
}

# ---------------------------------------------------------------------------
# Credential helpers
# ---------------------------------------------------------------------------

# Issue a credential via the VS Agent admin API and link it as a VP
# Usage: issue_and_link <admin_api> <schema_base_id> <chain_id> <schema_id> <agent_did> <claims_json>
issue_and_link() {
  local admin_api=$1
  local schema_base_id=$2
  local chain_id=$3
  local schema_id=$4
  local agent_did=$5
  local claims_json=$6

  local vpr_ref="vpr:verana:${chain_id}/cs/v1/js/${schema_id}"
  log "Looking up VTJSC for schema $schema_id (ref: $vpr_ref)..."

  local jsc_list_code jsc_list
  jsc_list_code=$(curl -s -o /tmp/jsc_list.json -w '%{http_code}' "${admin_api}/v1/vt/json-schema-credentials")
  jsc_list=$(cat /tmp/jsc_list.json)

  if [ "$jsc_list_code" != "200" ]; then
    err "Failed to list VTJSCs (HTTP $jsc_list_code)"
    return 1
  fi

  local jsc_url
  jsc_url=$(echo "$jsc_list" | jq -r --arg sid "$vpr_ref" '.data[] | select(.schemaId == $sid) | .credential.id')
  if [ -z "$jsc_url" ]; then
    err "VTJSC not found for schema $schema_id (ref: $vpr_ref)"
    return 1
  fi
  ok "VTJSC URL: $jsc_url"

  echo "$claims_json" > /tmp/claims_ial.json
  local request_body
  request_body=$(jq -n \
    --arg fmt "jsonld" \
    --arg did "$agent_did" \
    --arg jsc "$jsc_url" \
    --slurpfile claims /tmp/claims_ial.json \
    '{format: $fmt, did: $did, jsonSchemaCredentialId: $jsc, claims: $claims[0]}')

  local issue_url="${admin_api}/v1/vt/issue-credential"
  echo "$request_body" > /tmp/request_ial.json
  local issue_code credential
  issue_code=$(curl -s -o /tmp/issue_self.json -w '%{http_code}' \
    -X POST "$issue_url" \
    -H 'Content-Type: application/json' \
    -d @/tmp/request_ial.json)
  credential=$(cat /tmp/issue_self.json)

  if [ "$issue_code" != "200" ] && [ "$issue_code" != "201" ]; then
    err "Failed to issue credential (HTTP $issue_code). Response: $credential"
    return 1
  fi
  ok "Credential issued (HTTP $issue_code)"

  local signed_cred
  signed_cred=$(echo "$credential" | jq '.credential')
  if [ "$signed_cred" = "null" ] || [ -z "$signed_cred" ]; then
    signed_cred="$credential"
  fi

  local link_url="${admin_api}/v1/vt/linked-credentials"
  curl -s -X DELETE "${link_url}" \
    -H 'Content-Type: application/json' \
    -d "{\"credentialSchemaId\": \"$jsc_url\"}" > /dev/null 2>&1 || true

  echo "$signed_cred" > /tmp/cred_ial.json
  local link_body
  link_body=$(jq -n \
    --arg sbi "$schema_base_id" \
    --slurpfile cred /tmp/cred_ial.json \
    '{schemaBaseId: $sbi, credential: $cred[0]}')

  echo "$link_body" > /tmp/link_ial.json
  local link_code link_result
  link_code=$(curl -s -o /tmp/link_self.json -w '%{http_code}' \
    -X POST "$link_url" \
    -H 'Content-Type: application/json' \
    -d @/tmp/link_ial.json)
  link_result=$(cat /tmp/link_self.json)

  if [ "$link_code" != "200" ] && [ "$link_code" != "201" ]; then
    err "Failed to link credential (HTTP $link_code). Response: $link_result"
    return 1
  fi
  ok "Credential linked as VP (schemaBaseId: $schema_base_id)"
}

# Issue a credential from a REMOTE admin API and link it on the LOCAL agent
# Usage: issue_remote_and_link <remote_admin_api> <local_admin_api> <schema_base_id> <jsc_url> <target_did> <claims_json>
issue_remote_and_link() {
  local remote_api=$1
  local local_api=$2
  local schema_base_id=$3
  local jsc_url=$4
  local target_did=$5
  local claims_json=$6

  echo "$claims_json" > /tmp/claims_iral.json
  local request_body
  request_body=$(jq -n \
    --arg fmt "jsonld" \
    --arg did "$target_did" \
    --arg jsc "$jsc_url" \
    --slurpfile claims /tmp/claims_iral.json \
    '{format: $fmt, did: $did, jsonSchemaCredentialId: $jsc, claims: $claims[0]}')

  local issue_url="${remote_api}/v1/vt/issue-credential"
  log "Requesting credential from remote API: $issue_url"

  echo "$request_body" > /tmp/request_iral.json
  local http_code credential
  http_code=$(curl -s -o /tmp/issue_response.json -w '%{http_code}' \
    -X POST "$issue_url" \
    -H 'Content-Type: application/json' \
    -d @/tmp/request_iral.json)
  credential=$(cat /tmp/issue_response.json)

  if [ "$http_code" != "200" ] && [ "$http_code" != "201" ]; then
    err "Remote API returned HTTP $http_code"
    err "Response: $credential"
    return 1
  fi

  if [ -z "$credential" ] || echo "$credential" | jq -e '.statusCode' > /dev/null 2>&1; then
    err "Remote API failed to issue credential. Response: $credential"
    return 1
  fi
  ok "Credential received from remote API (HTTP $http_code)"

  local signed_cred
  signed_cred=$(echo "$credential" | jq '.credential')
  if [ "$signed_cred" = "null" ] || [ -z "$signed_cred" ]; then
    signed_cred="$credential"
  fi

  local link_url="${local_api}/v1/vt/linked-credentials"
  curl -s -X DELETE "${link_url}" \
    -H 'Content-Type: application/json' \
    -d "{\"credentialSchemaId\": \"$jsc_url\"}" > /dev/null 2>&1 || true

  echo "$signed_cred" > /tmp/cred_iral.json
  local link_body
  link_body=$(jq -n \
    --arg sbi "$schema_base_id" \
    --slurpfile cred /tmp/cred_iral.json \
    '{schemaBaseId: $sbi, credential: $cred[0]}')

  echo "$link_body" > /tmp/link_iral.json
  local link_code link_result
  link_code=$(curl -s -o /tmp/link_response.json -w '%{http_code}' \
    -X POST "$link_url" \
    -H 'Content-Type: application/json' \
    -d @/tmp/link_iral.json)
  link_result=$(cat /tmp/link_response.json)

  if [ "$link_code" != "200" ] && [ "$link_code" != "201" ]; then
    err "Failed to link credential (HTTP $link_code). Response: $link_result"
    return 1
  fi
  ok "Credential linked as VP on local agent (schemaBaseId: $schema_base_id)"
}

# Check if a LinkedVerifiablePresentation already exists in the agent's public DID document
# Usage: has_linked_vp <public_url> <schema_base_id>
has_linked_vp() {
  local public_url=$1
  local schema_base_id=$2

  local did_doc
  did_doc=$(curl -sf "${public_url}/.well-known/did.json" 2>/dev/null) || return 1

  local match
  match=$(echo "$did_doc" | jq -r \
    --arg sbi "$schema_base_id" \
    '.service[] |
     select(.type == "LinkedVerifiablePresentation") |
     select(.id | test($sbi + "-jsc-vp")) |
     .id' 2>/dev/null | head -1)

  [ -n "$match" ]
}

# ---------------------------------------------------------------------------
# CLI setup helpers
# ---------------------------------------------------------------------------

# Ensure veranad account exists and is funded
# Usage: setup_veranad_account <user_acc> <faucet_url>
setup_veranad_account() {
  local user_acc=$1
  local faucet_url=$2

  if ! veranad keys show "$user_acc" --keyring-backend test > /dev/null 2>&1; then
    log "Creating new account '$user_acc'..."
    veranad keys add "$user_acc" --keyring-backend test 2>&1
    ok "Account created"
  else
    ok "Account '$user_acc' already exists"
  fi

  USER_ACC_ADDR=$(veranad keys show "$user_acc" -a --keyring-backend test)
  ok "Account address: $USER_ACC_ADDR"

  local balance
  balance=$(veranad q bank balances "$USER_ACC_ADDR" --node "$NODE_RPC" --output json 2>/dev/null \
    | jq -r '.balances[] | select(.denom == "uvna") | .amount // "0"' 2>/dev/null || echo "0")

  if [ "$balance" = "0" ] || [ -z "$balance" ]; then
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  Fund this account via the faucet:                          │"
    echo "  │                                                             │"
    echo "  │  Address: $USER_ACC_ADDR"
    echo "  │                                                             │"
    echo "  │  Faucet:  $faucet_url"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    read -rp "  Press Enter once the account is funded (or Ctrl+C to abort)... "

    balance=$(veranad q bank balances "$USER_ACC_ADDR" --node "$NODE_RPC" --output json 2>/dev/null \
      | jq -r '.balances[] | select(.denom == "uvna") | .amount // "0"' 2>/dev/null || echo "0")
    if [ "$balance" = "0" ] || [ -z "$balance" ]; then
      err "Account still has no uvna balance. Please fund it before continuing."
      exit 1
    fi
  fi

  ok "Account balance: ${balance} uvna"
  export USER_ACC_ADDR
}

# ---------------------------------------------------------------------------
# Permission helpers
# ---------------------------------------------------------------------------

# Check if a DID has an active permission of a given type for a schema.
# Usage: find_active_perm <schema_id> <perm_type> <did>
find_active_perm() {
  local schema_id=$1
  local perm_type=$2
  local did=$3
  local url="${INDEXER_URL}/verana/perm/v1/list?schema_id=${schema_id}"

  local perms http_code
  http_code=$(curl -s -o /tmp/perm_check.json -w '%{http_code}' "$url")
  if [ "$http_code" != "200" ]; then
    return 1
  fi
  perms=$(cat /tmp/perm_check.json)

  local perm_id
  perm_id=$(echo "$perms" | jq -r --arg did "$did" --arg pt "$perm_type" '
    .permissions[]? |
    select(.type == $pt and .perm_state == "ACTIVE" and .did == $did) |
    .id' | head -1)

  if [ -n "$perm_id" ]; then
    echo "$perm_id"
    return 0
  fi
  return 1
}

find_active_issuer_perm()   { find_active_perm "$1" "ISSUER"   "$2"; }
find_active_verifier_perm() { find_active_perm "$1" "VERIFIER" "$2"; }

# ---------------------------------------------------------------------------
# Trust Registry duplicate detection
# ---------------------------------------------------------------------------

# Check if the DID already owns a trust registry with an identical schema.
# Usage: has_trust_registry_for_schema <did> <local_schema_json>
has_trust_registry_for_schema() {
  local did=$1
  local local_schema=$2

  local local_canon
  local_canon=$(echo "$local_schema" | jq -Sc 'del(."$id")')

  local url="${INDEXER_URL}/verana/tr/v1/list?did=${did}"
  local http_code
  http_code=$(curl -s -o /tmp/tr_list.json -w '%{http_code}' "$url")
  if [ "$http_code" != "200" ]; then
    return 1
  fi

  local tr_ids
  tr_ids=$(jq -r '.trust_registries[]?.id // empty' /tmp/tr_list.json)
  if [ -z "$tr_ids" ]; then
    return 1
  fi

  for tr_id in $tr_ids; do
    local cs_url="${INDEXER_URL}/verana/cs/v1/list?trust_registry_id=${tr_id}"
    local cs_code
    cs_code=$(curl -s -o /tmp/cs_list.json -w '%{http_code}' "$cs_url")
    if [ "$cs_code" != "200" ]; then
      continue
    fi

    local schema_entries
    schema_entries=$(jq -c '.credential_schemas[]?' /tmp/cs_list.json)
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      local cs_id on_chain_schema on_chain_canon
      cs_id=$(echo "$entry" | jq -r '.id')
      on_chain_schema=$(echo "$entry" | jq -r '.json_schema // empty')
      if [ -z "$on_chain_schema" ]; then
        continue
      fi
      on_chain_canon=$(echo "$on_chain_schema" | jq -Sc 'del(."$id")')
      if [ "$local_canon" = "$on_chain_canon" ]; then
        echo "$tr_id $cs_id"
        return 0
      fi
    done <<< "$schema_entries"
  done

  return 1
}

# ---------------------------------------------------------------------------
# Date helper (macOS + Linux compatible)
# ---------------------------------------------------------------------------

future_timestamp() {
  local seconds=${1:-15}
  date -u -v+"${seconds}"S +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
    || date -u -d "+${seconds} seconds" +"%Y-%m-%dT%H:%M:%SZ"
}
