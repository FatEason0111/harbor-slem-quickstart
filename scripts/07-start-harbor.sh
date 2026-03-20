#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 7] Start Harbor"

cd "${HARBOR_LINK}"
docker compose down -v || true
docker compose up -d
docker compose ps

echo
echo "[NEXT] Open in browser: https://${HARBOR_HOSTNAME}"
echo "[LOGIN] admin / ${HARBOR_ADMIN_PASSWORD}"
